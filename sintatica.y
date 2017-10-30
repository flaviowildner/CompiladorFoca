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
			}else if((i == 0) && (j == mapaDeMapas[i].mapa.size() - 1)){
				retorno.label = "null";
				return retorno;
				//yyerror("Error-> Variavel nao declarada");
			}
		}
	}
	retorno.label = "null";
	return retorno;
}


%}



%token TK_ARITMETICO
%token TK_LR
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
%token TK_ELSE
%token TK_WHILE
%token TK_FOR

%nonassoc TK_IF
%nonassoc TK_ELSE

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
			| IF
			| LR ';'
			| WHILE
			;


IF			: TK_IF '(' LR ')' BLOCO
			{
				string rotulo_inicio = gerarRotulo();
				string rotulo_fim = gerarRotulo();
				$$.traducao = $3.traducao + "\tif(" + $3.label + ")\n\t\tgoto " + rotulo_inicio + ";\n\telse\n\t\tgoto " + rotulo_fim + ";\n\t" + rotulo_inicio + ":\n" + $5.traducao + "\t" + rotulo_fim + ":\n";
			}
			| TK_IF '(' LR ')' BLOCO TK_ELSE BLOCO
			{
				string rotulo_if = gerarRotulo();
				string rotulo_else = gerarRotulo();
				string rotulo_fim = gerarRotulo();
				$$.traducao = $3.traducao + "\tif(" + $3.label + ")\n\t\tgoto " + rotulo_if + ";\n\telse\n\t\tgoto " + rotulo_else + ";\n\t" + rotulo_if + ":\n" + $5.traducao + "\tgoto " + rotulo_fim + ";\n\t" + rotulo_else + ":\n" + $7.traducao + "\t" + rotulo_fim + ":\n";
			}
			;
			
WHILE		: TK_WHILE '(' LR ')' BLOCO
			{
				string rotulo_while = gerarRotulo();
				string rotulo_bloco = gerarRotulo();
				string rotulo_fim = gerarRotulo();
				$$.traducao = "\t" + rotulo_while + ":\n" + $3.traducao + "\tif(" + $3.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\telse\n\t\tgoto " + rotulo_fim + ";\n\t" + rotulo_bloco + ":\n" + $5.traducao + "\tgoto " + rotulo_while + ";\n\t" + rotulo_fim + ":\n";
			}
			;


LR			: E TK_LR E
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
			;


ATRIBUICAO	: TK_ID '=' E
			{
				$$ = buscaVariavel($1);				
				if($$.label == "null"){
					$$.label = gerarNome();
					$$.nomeVariavel = $1.nomeVariavel;
					$$.tipo = $3.tipo;
					$$.traducao = $3.traducao + "\t" + $$.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $3.label + ";\n";
					atributos temp = $$;
					mapaDeMapas[mapaDeMapas.size() - 1].mapa.push_back(temp);
				}else{
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
				}
				
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
				if($$.label == "null"){
					yyerror("Error-> Variavel nao declarada");
				}
			}
			| TK_BOOL
			{
				$$ = $1;
				$$.traducao = "\t" + $1.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + ";\n";
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