%{
#include <stdio.h>
#include <iostream>
#include <vector>
#include <string.h>
#include <sstream>

#define YYSTYPE atributos

using namespace std;

FILE *out_file;

string cabecalho = "/*Compilador GambiArt*/\n#include <iostream>\n#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\nusing namespace std;\nint main(void)\n{\n";
string fim_cabecalho = "\treturn 0;\n}";

struct atributos
{
	string label;
	string nomeVariavel;
	string traducao;
	string tipo;
	int tamanho;
};

  
int yylex(void);
void yyerror(string);

class mapaDeVariaveis{
	public:
		vector<atributos> mapa;
		bool bloco_quebravel;
		string rotulo_condicao;
		string rotulo_bloco;
		string rotulo_fim;
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
%token TK_DO
%token TK_SWITCH
%token TK_INCREMENTO
%token TK_INCREM_ATRIB_ABREV
%token TK_BREAK TK_CONTINUE

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
				cout << cabecalho << $2.traducao << fim_cabecalho << endl;
				out_file = fopen("out.cpp", "w");
				fprintf(out_file, "%s%s%s", cabecalho.c_str(), $2.traducao.c_str(), fim_cabecalho.c_str());
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
			;

EMPILHA		: 
			{
				mapaDeVariaveis mapa;
				mapa.rotulo_condicao = gerarRotulo();
				mapa.rotulo_bloco = gerarRotulo();
				mapa.rotulo_fim = gerarRotulo();
				mapa.bloco_quebravel = false;

				mapaDeMapas.push_back(mapa);
			}
			;

EMPILHA_LOOP :
			{
				mapaDeVariaveis mapa;
				mapa.rotulo_condicao = gerarRotulo();
				mapa.rotulo_bloco = gerarRotulo();
				mapa.rotulo_fim = gerarRotulo();
				mapa.bloco_quebravel = true;

				mapaDeMapas.push_back(mapa);
			}
			;
			
BLOCO		: '{' COMANDOS '}'
			{
				$$.traducao = $2.traducao;
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
			| DO
			| FOR
			| BREAK ';'
			| CONTINUE ';'
			| STRING ';'
			;

BREAK		: TK_BREAK
			{
				for(int i=mapaDeMapas.size() - 1; i >= 0; i--){
					if(mapaDeMapas[i].bloco_quebravel == true){
						$$.traducao = "\tgoto " + mapaDeMapas[i].rotulo_fim + ";\n";
						break;
					}
				}
			}
			;

CONTINUE	: TK_CONTINUE
			{
				for(int i=mapaDeMapas.size() - 1; i >= 0; i--){
					if(mapaDeMapas[i].bloco_quebravel == true){
						$$.traducao = "\tgoto " + mapaDeMapas[i].rotulo_condicao + ";\n";
						break;
					}
				}
			}
			;


IF			:  TK_IF '(' LR ')' EMPILHA BLOCO
			{
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;
				$$.traducao = $3.traducao + "\tif(" + $3.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\telse\n\t\tgoto " + rotulo_fim + ";\n\t" + rotulo_bloco + ":\n" + $6.traducao + "\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
			}
			| TK_IF '(' LR ')' EMPILHA BLOCO TK_ELSE EMPILHA BLOCO
			{
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_condicao;
				string rotulo_else = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;
				$$.traducao = $3.traducao + "\tif(" + $3.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\telse\n\t\tgoto " + rotulo_else + ";\n\t" + rotulo_bloco + ":\n" + $6.traducao + "\tgoto " + rotulo_fim + ";\n\t" + rotulo_else + ":\n" + $9.traducao + "\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
				mapaDeMapas.pop_back();
			}
			;
			
WHILE		: TK_WHILE '(' LR ')' EMPILHA_LOOP BLOCO
			{
				string rotulo_condicao = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_condicao;
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;

				$$.traducao = "\t" + rotulo_condicao + ":\n" + $3.traducao + "\tif(" + $3.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\telse\n\t\tgoto " + rotulo_fim + ";\n\t" + rotulo_bloco + ":\n" + $6.traducao + "\tgoto " + rotulo_condicao + ";\n\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
			}
			;

DO			: TK_DO EMPILHA_LOOP BLOCO TK_WHILE '(' LR ')' ';'
			{
				string rotulo_condicao = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_condicao;
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;

				$$.traducao = "\t" + rotulo_bloco + ":\n" + $3.traducao + "\t" + rotulo_condicao + ":\n" + $6.traducao + "\tif(" + $6.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
			}
			;

FOR			: TK_FOR '(' EMPILHA_LOOP ATRIBUICAO ';' LR ';' ATRIBUICAO ')' BLOCO
			{
				string rotulo_condicao = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_condicao;
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;

				
				$$.traducao = $4.traducao + "\t" + rotulo_condicao + ":\n" + $6.traducao + "\tif(" + $6.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\telse\n\t\tgoto " + rotulo_fim + ";\n\t" + rotulo_bloco + ":\n" + $10.traducao + $8.traducao + "\tgoto " + rotulo_condicao + ";\n\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
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
			| TK_ID '=' STRING
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
			| TK_ID TK_INCREMENTO
			{
				$$ = buscaVariavel($1);				
				if($$.label == "null"){
					yyerror("Error-> Variavel nao declarada");
				}else{
					$$.traducao = "\t" + $$.label + " = " + $$.label + " " + $2.traducao[0] + " 1;\n";
				}
			}
			| TK_ID TK_INCREM_ATRIB_ABREV E
			{
				$$ = buscaVariavel($1);				
				if($$.label == "null"){
					yyerror("Error-> Variavel nao declarada");
				}else{
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $$.label + " " + $2.traducao[0] + " " + $3.label + ";\n";
				}
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
				$$.label = gerarNome();
				$$.traducao = "\t" + $1.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_CHAR
			{
				$$ = $1;
				$$.label = gerarNome();
				$$.traducao = "\t" + $1.tipo + " " + $$.label + ";\n\t" + $$.label + " = " + $1.label + ";\n";
			}
			;

STRING		: STRING TK_ARITMETICO STRING
			{
				$$.label = $1.label;
				$$.tamanho = $1.tamanho + $3.tamanho - 1;
				ostringstream convert;
				convert << $$.tamanho;
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = (char*)realloc(" + $$.label + ", " + convert.str() + ");\n\tstrcat(" + $1.label + "," + $3.label + ");\n\tfree(" + $3.label + ");\n";
				$$.tipo = $1.tipo;
			}
			| TK_STRING
			{
				$$ = $1;
				$$.label = $1.label.substr(1, $1.label.size() - 1);
				ostringstream convert;
				convert << $$.label.size();
				$$.tamanho = $$.label.size();
				$$.label = gerarNome();
				$$.traducao = "\tchar* " + $$.label + ";\n\t" + $$.label + " = (char*)malloc(" + convert.str() + " * sizeof(char));\n\tstrcpy(" + $$.label + ", " + $1.label + ");\n";
			}
			;


PRINT		: TK_PRINT '(' TK_ID ')'
			{
				atributos retorno = buscaVariavel($3);
				if(retorno.label != "null")
					$$.traducao = "\tcout << " + retorno.label + " << endl;\n";
				else
					yyerror("Error-> Variavel nao declarada");
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