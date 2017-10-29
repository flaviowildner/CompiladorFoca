%{
#include <stdio.h>
#include <iostream>
#include <vector>
#include <string>
#include <sstream>

#define YYSTYPE atributos

using namespace std;

FILE *out_file;

struct atributos
{
	string label;
	string nomeVariavel;
	string traducao;
	string tipo;
};

  
int yylex(void);
void yyerror(string);

class mapaDeVariaveis{
	public:
		vector<atributos> mapa;
};

vector<mapaDeVariaveis> mapaDeMapas;

string gerarNome(){
	static int numeroVariaveis = 0;
	numeroVariaveis++;
	ostringstream stringNumeroVariaveis;
	stringNumeroVariaveis << numeroVariaveis;
	return "var_" + stringNumeroVariaveis.str();
}

string gerarRotulo(){
	static int numeroRotulos = 0;
	numeroRotulos++;
	ostringstream stringNumeroVariaveis;
	stringNumeroVariaveis << numeroRotulos;
	return "rotulo_" + stringNumeroVariaveis.str();
}


atributos buscaVariavel(atributos alvo){
	atributos retorno;
	for(int i=mapaDeMapas.size() - 1;i>=0;i--){
		for(int j=0;j<mapaDeMapas[i].mapa.size();j++){
			if(mapaDeMapas[i].mapa[j].nomeVariavel == alvo.nomeVariavel){
				retorno = mapaDeMapas[i].mapa[j];
				retorno.traducao = "";
				return retorno;
			}else if(i == 0 && j == mapaDeMapas[i].mapa.size() - 1){
				yyerror("Error-> Variavel nao declarada");
			}
		}
	}
	return retorno;
}


%}




%token TK_ARITMETICO
%token TK_RELACIONAL
%token TK_LOGICO
%token TK_CAST
%token TK_ID
%token TK_BOOL
%token TK_NUM
%token TK_CHAR
%token TK_STRING
%token TK_MAIN TK_TIPO_INT
%token TK_FIM TK_ERROR
%token TK_PRINT
%token TK_IF

%start S


%left '='
%left "||" "&&"
%left "==" "!="
%left '<' '>' ">=" "<="
%left '+' '-'
%left '*' '/' "%%"


%%
S 			: GLOBAL COMANDOS FIM_GLOBAL
			{
				cout << "/*Compilador GambiArt*/\n" << "#include <iostream>\n#include<string.h>\n#include<stdio.h>\nint main(void)\n{\n" << $2.traducao << "\treturn 0;\n}" << endl;
				out_file = fopen("out.cpp", "w");
				fprintf(out_file, "/*Compilador GambiArt*/\n#include <iostream>\n#include <string.h>\n#include <stdio.h>\nusing namespace std;\nint main(void)\n{\n%s\treturn 0;\n}", $2.traducao.c_str());
				fclose(out_file);
			}
			|
			;

GLOBAL		:
			{
				mapaDeVariaveis mapa;
				mapaDeMapas.push_back(mapa);
			}
			;

FIM_GLOBAL	:
			{
				mapaDeMapas.pop_back();
			}

BLOCO		: EMPILHA COMANDOS EMPILHA
			{
				$$.traducao = $2.traducao;
			}
			;


EMPILHA		: '{'
			{
				mapaDeVariaveis mapa;
				mapaDeMapas.push_back(mapa);
			}
			| '}'
			{
				mapaDeMapas.pop_back();
			}
			;

COMANDOS	: COMANDOS COMANDO
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			| 
			{
				$$.traducao = "";
			}
			;


COMANDO 	: E ';'
			| ATRIBUICAO ';'
			| PRINT ';'
			| BLOCO
			| IF
			;


IF			: TK_IF '(' E ')' BLOCO
			{
				string rotulo_inicio = gerarRotulo();
				string rotulo_fim = gerarRotulo();
				$$.traducao = "\tif(" + $3.label + ")\n\t\tgoto " + rotulo_inicio + ";\n\telse\n\t\tgoto " + rotulo_fim + ";\n\t" + rotulo_inicio + ":\n" + $5.traducao + "\t" + rotulo_fim + ":\n";
			}
			;


ATRIBUICAO	: TK_ID '=' E
			{
				$$.label = gerarNome();
				$$.tipo = $3.tipo;
				$$.traducao = $3.traducao + "\t" + $$.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $3.label + ";\n";
				atributos temp = $$;
				mapaDeMapas[mapaDeMapas.size() - 1].mapa.push_back(temp);
			}
			| TK_ID '=' TK_CHAR
			{
				$$ = $3;
				$$.label = gerarNome();
				$$.traducao = $3.traducao + "\t" + $$.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $3.label + ";\n";
				atributos temp = $$;
				mapaDeMapas[mapaDeMapas.size() - 1].mapa.push_back(temp);
			}
			;
			
E 			: '(' E ')'
			{
				$$ = $2;
			}
			| E TK_ARITMETICO E
			{
				if($1.tipo == $3.tipo){
					$$.label = gerarNome();
					$$.traducao = $1.traducao + $3.traducao + "\t" + $1.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					$$.tipo = $1.tipo;
				}else{
					if($1.tipo == "int"){
						string tempCastVarLabel = gerarNome();
						string builder = "\t" + $3.tipo + " " + tempCastVarLabel + ";\n\t" + tempCastVarLabel + " = " + "(" + $3.tipo + ")" + $1.label + ";\n";
						$1.label = tempCastVarLabel;
						$$.label = gerarNome();
						$$.tipo = $3.tipo;
						$$.traducao = $1.traducao + $3.traducao + builder + "\t" + $$.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					}else{
						string tempCastVarLabel = gerarNome();
						string builder = "\t" + $1.tipo + " " + tempCastVarLabel + ";\n\t" + tempCastVarLabel + " = " + "(" + $1.tipo + ")" + $3.label + ";\n";
						$3.label = tempCastVarLabel;
						$$.label = gerarNome();
						$$.tipo = $1.tipo;
						$$.traducao = $1.traducao + $3.traducao + builder + "\t" + $$.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					}
				}
			}
			| E TK_RELACIONAL E
			{
				if($1.tipo == $3.tipo){
					$$.label = gerarNome();
					$$.traducao = $1.traducao + $3.traducao + "\tbool" + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					$$.tipo = "bool";
				}else{
					if($1.tipo == "int"){
						string tempCastVarLabel = gerarNome();
						string builder = "\t" + $3.tipo + " " + tempCastVarLabel + ";\n\t" + tempCastVarLabel + " = " + "(" + $3.tipo + ")" + $1.label + ";\n";
						$1.label = tempCastVarLabel;
						$$.label = gerarNome();
						$$.tipo = "bool";
						$$.traducao = $1.traducao + $3.traducao + builder + "\t" + $$.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					}else{
						string tempCastVarLabel = gerarNome();
						string builder = "\t" + $1.tipo + " " + tempCastVarLabel + ";\n\t" + tempCastVarLabel + " = " + "(" + $1.tipo + ")" + $3.label + ";\n";
						$1.label = tempCastVarLabel;
						$$.label = gerarNome();
						$$.tipo = "bool";
						$$.traducao = $1.traducao + $3.traducao + builder + "\t" + $$.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					}
				}
			}
			| E TK_LOGICO E
			{
				if($1.tipo == $3.tipo){
					$$.label = gerarNome();
					$$.traducao = $1.traducao + $3.traducao + "\tbool" + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					$$.tipo = "bool";
				}else{
					if($1.tipo == "int"){
						string tempCastVarLabel = gerarNome();
						string builder = "\t" + $3.tipo + " " + tempCastVarLabel + ";\n\t" + tempCastVarLabel + " = " + "(" + $3.tipo + ")" + $1.label + ";\n";
						$1.label = tempCastVarLabel;
						$$.label = gerarNome();
						$$.tipo = "bool";
						$$.traducao = $1.traducao + $3.traducao + builder + "\t" + $$.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					}else{
						string tempCastVarLabel = gerarNome();
						string builder = "\t" + $1.tipo + " " + tempCastVarLabel + ";\n\t" + tempCastVarLabel + " = " + "(" + $1.tipo + ")" + $3.label + ";\n";
						$1.label = tempCastVarLabel;
						$$.label = gerarNome();
						$$.tipo = "bool";
						$$.traducao = $1.traducao + $3.traducao + builder + "\t" + $$.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					}
				}
			}
			| TK_CAST E
			{
				$$ = $2;
				$$.label = gerarNome();
				
				if($1.label == "(float)"){
					$$.traducao = $2.traducao + "\tfloat " + $$.label + ";\n\t" + $$.label + " = (float)" + $2.label + ";\n";
					$$.tipo = "float";
				}else if($1.label == "(int)"){
					$$.traducao = "\tint " + $$.label + " = " + $2.label + ";\n";
					$$.tipo = "int";
				}
			}
			| TK_NUM
			{
				$$ = $1;
				$$.label = gerarNome();
				$$.traducao = "\t" + $1.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_ARITMETICO E
			{
				if($1.traducao != "*" || $1.traducao != "/"){
					$$ = $2;
					$$.label = gerarNome();
					$$.traducao = $2.traducao + "\t" + $2.tipo + " " + $$.label + ";\n\t" + $$.label + " = -" + $2.label + ";\n";
				}
			}
			| TK_ID
			{
				$$ = buscaVariavel($1);
			}
			;


PRINT		: TK_PRINT '(' TK_ID ')'
			{
				$$.traducao = "\tcout << " + buscaVariavel($3).label + " << endl;\n"
			}
			;

%%
#include "lex.yy.c"
int yyparse();
int main( int argc, char* argv[] )
{
	yyparse();
	return 0;
}
void yyerror( string MSG )
{
	cout << MSG << endl;
	exit (0);
}