%{
#include <stdio.h>
#include <iostream>
#include <vector>
#include <string.h>
#include <sstream>

#define YYSTYPE atributos

using namespace std;

FILE *out_file;

string cabecalho = "/*Compilador GambiArt*/\n#include <iostream>\n#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\nusing namespace std;\n\nint main(void)\n{\n";
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
vector<atributos> variaveisTemporarias;

string freeMallocs(){
	string retorno;
	for(int i=0;i<variaveisTemporarias.size();i++){
		if(variaveisTemporarias[i].tipo == "char*"){
			retorno += "\tfree(" + variaveisTemporarias[i].label + ");\n";
		}
	}
	return retorno;
}

string gerarNome(){
	static int numeroVariaveis = 0;
	numeroVariaveis++;
	ostringstream stringNumeroVariaveis;
	stringNumeroVariaveis << numeroVariaveis;
	return "var_" + stringNumeroVariaveis.str();
}

string declararTemporarias(){
	string retorno;
	for(int i=0;i<variaveisTemporarias.size();i++){
		retorno += "\t" + variaveisTemporarias[i].tipo + " " + variaveisTemporarias[i].label + ";\n";
	}
	return retorno;
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



%token TK_SWITCH 
%token TK_CASE 
%token TK_DEFAULT
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
%token TK_INCREMENTO
%token TK_INCREM_ATRIB_ABREV
%token TK_BREAK TK_CONTINUE
%token TK_INIT_COMMENT TK_END_COMMENT

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
				string out = cabecalho + declararTemporarias() + $2.traducao + freeMallocs() + fim_cabecalho;
				out_file = fopen("out.cpp", "w");
				cout << out;
				fprintf(out_file, "%s",out.c_str());
				fclose(out_file);
			}
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

EMPILHA_QUEBRAVEL :
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
			| SWITCH
			| BREAK ';'
			| CONTINUE ';'
			| COMENTARIOS
			;

COMENTARIOS : TK_INIT_COMMENT COMANDOS TK_END_COMMENT
			{
				$$.traducao = "";
			}
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


SWITCH		: TK_SWITCH EMPILHA_QUEBRAVEL '(' SWITCH_COND ')' '{' SWITCH_CASES '}'
			{
				$$.traducao = $4.traducao + $7.traducao + "\t" + mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
			}
			;


SWITCH_COND : TK_ID
			{
				$1 = buscaVariavel($1);
				if($1.label == "null"){
					yyerror("Error-> Variavel nao declarada");
				}
				mapaDeMapas[mapaDeMapas.size() - 1].mapa.push_back($1);
			}
			;


SWITCH_CASES : CASE SWITCH_CASES
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			| CASE
			{
				$$.traducao = $1.traducao;
			}
			;


CASE		: TK_CASE CASE_VALOR ':' EMPILHA COMANDOS
			{
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;
				$$.traducao = $2.traducao + "\tif(" + mapaDeMapas[mapaDeMapas.size() - 2].mapa[0].label + " == " + $2.label + ")\n\t\tgoto " + rotulo_bloco + ";\ntgoto " + rotulo_fim + ";\n\t" + rotulo_bloco + ":\n" + $5.traducao + "\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
			}
			;


CASE_VALOR	: TK_NUM
			{
				$$ = $1;
				$$.label = gerarNome();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				variaveisTemporarias.push_back($$);
			}
			| TK_ID
			{
				$$ = buscaVariavel($1);
				if($$.label == "null"){
					yyerror("Error-> Variavel nao declarada");
				}
			}
			| TK_CHAR
			{
				$$ = $1;
				$$.label = gerarNome();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				variaveisTemporarias.push_back($$);
			}
			;

IF			:  TK_IF '(' LR ')' EMPILHA BLOCO
			{
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;
				$$.traducao = $3.traducao + "\tif(" + $3.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\tgoto " + rotulo_fim + ";\n\t" + rotulo_bloco + ":\n" + $6.traducao + "\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
			}
			| TK_IF '(' LR ')' EMPILHA BLOCO TK_ELSE EMPILHA BLOCO
			{
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_condicao;
				string rotulo_else = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;
				$$.traducao = $3.traducao + "\tif(" + $3.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\tgoto " + rotulo_else + ";\n\t" + rotulo_bloco + ":\n" + $6.traducao + "\tgoto " + rotulo_fim + ";\n\t" + rotulo_else + ":\n" + $9.traducao + "\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
				mapaDeMapas.pop_back();
			}
			;

WHILE		: TK_WHILE '(' LR ')' EMPILHA_QUEBRAVEL BLOCO
			{
				string rotulo_condicao = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_condicao;
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;

				$$.traducao = "\t" + rotulo_condicao + ":\n" + $3.traducao + "\tif(" + $3.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\tgoto " + rotulo_fim + ";\n\t" + rotulo_bloco + ":\n" + $6.traducao + "\tgoto " + rotulo_condicao + ";\n\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
			}
			;

DO			: TK_DO EMPILHA_QUEBRAVEL BLOCO TK_WHILE '(' LR ')' ';'
			{
				string rotulo_condicao = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_condicao;
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;

				$$.traducao = "\t" + rotulo_bloco + ":\n" + $3.traducao + $6.traducao + "\tif(" + $6.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
			}
			;

FOR			: TK_FOR '(' EMPILHA_QUEBRAVEL ATRIBUICAO ';' LR ';' ATRIBUICAO ')' BLOCO
			{
				string rotulo_condicao = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_condicao;
				string rotulo_bloco = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_bloco;
				string rotulo_fim = mapaDeMapas[mapaDeMapas.size() - 1].rotulo_fim;

				
				$$.traducao = $4.traducao + "\t" + rotulo_condicao + ":\n" + $6.traducao + "\tif(" + $6.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\tgoto " + rotulo_fim + ";\n\t" + rotulo_bloco + ":\n" + $10.traducao + $8.traducao + "\tgoto " + rotulo_condicao + ";\n\t" + rotulo_fim + ":\n";
				mapaDeMapas.pop_back();
			}
			;


LR			: E TK_LR E
			{
				if($1.tipo == $3.tipo){
					$$.label = gerarNome();
					$$.tipo = "bool";
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
				}else{
					if($1.tipo == "int"){
						string tempCastVarLabel = gerarNome();
						string builder = "\t" + tempCastVarLabel + " = " + "(" + $3.tipo + ")" + $1.label + ";\n";
						$1.label = tempCastVarLabel;
						$$.label = gerarNome();
						$$.tipo = "bool";
						$$.traducao = $1.traducao + $3.traducao + builder + "\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
						variaveisTemporarias.push_back($1);
					}else{
						string tempCastVarLabel = gerarNome();
						string builder = "\t" + tempCastVarLabel + " = " + "(" + $1.tipo + ")" + $3.label + ";\n";
						$3.label = tempCastVarLabel;
						$$.label = gerarNome();
						$$.tipo = "bool";
						$$.traducao = $1.traducao + $3.traducao + builder + "\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
						variaveisTemporarias.push_back($3);
					}
					
				}
				variaveisTemporarias.push_back($$);
			}
			;

ATRIBUICAO	: TK_ID '=' E
			{
				$$ = buscaVariavel($1);				
				if($$.label == "null"){
					$$.label = gerarNome();
					$$.nomeVariavel = $1.nomeVariavel;
					$$.tipo = $3.tipo;
					$$.tamanho = $3.tamanho;
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
					atributos temp = $$;
					mapaDeMapas[mapaDeMapas.size() - 1].mapa.push_back(temp);
					variaveisTemporarias.push_back($$);
				}else{
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
				}
			}
			| 
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
				if($1.tipo == "char*" || $3.tipo == "char*"){
					$$.tamanho = $1.tamanho + $3.tamanho - 1;
					$$.tipo = "char*";
					$$.label = gerarNome();
					ostringstream convert;
					convert << $$.tamanho;
					$$.tipo = $1.tipo;	
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = (char*)malloc(" + convert.str() + " * sizeof(char)" + ");\n\t" + $$.label + "[0] = \'\\0\';\n" + "\tstrcat(" + $$.label + "," + $1.label + ");\n\tstrcat(" + $$.label + "," + $3.label + ");\n";
				}
				else{
					if($1.tipo == $3.tipo){
						$$.label = gerarNome();
						$$.tipo = $1.tipo;
						$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					}else{
						if($1.tipo == "int"){
							string tempCastVarLabel = gerarNome();
							string builder = "\t" + $3.tipo + " " + tempCastVarLabel + ";\n\t" + tempCastVarLabel + " = " + "(" + $3.tipo + ")" + $1.label + ";\n";
							$1.label = tempCastVarLabel;
							$$.label = gerarNome();
							$$.tipo = $3.tipo;
							$$.traducao = $1.traducao + $3.traducao + builder + "\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
						}else{
							string tempCastVarLabel = gerarNome();
							string builder = "\t" + $1.tipo + " " + tempCastVarLabel + ";\n\t" + tempCastVarLabel + " = " + "(" + $1.tipo + ")" + $3.label + ";\n";
							$3.label = tempCastVarLabel;
							$$.label = gerarNome();
							$$.tipo = $1.tipo;
							$$.traducao = $1.traducao + $3.traducao + builder + "\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
						}
					}
				}
				variaveisTemporarias.push_back($$);
			}
			| TK_CAST E
			{
				$$ = $2;
				$$.label = gerarNome();
				
				if($1.label == "(float)"){
					$$.tipo = "float";
					$$.traducao = $2.traducao + "\t" + $$.label + " = (float)" + $2.label + ";\n";
				}else if($1.label == "(int)"){
					$$.tipo = "int";
					$$.traducao = $2.traducao + "\t" + $$.label + " = (int)" + $2.label + ";\n";
				}
				variaveisTemporarias.push_back($$);
			}
			| TK_NUM
			{
				$$ = $1;
				$$.label = gerarNome();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				variaveisTemporarias.push_back($$);
			}
			| TK_ARITMETICO E
			{
				if($1.traducao != "*" || $1.traducao != "/"){
					$$ = $2;
					$$.label = gerarNome();
					$$.traducao = $2.traducao + "\t" + $$.label + " = -" + $2.label + ";\n";
					variaveisTemporarias.push_back($$);
				}else{
					yyerror("Sinal incorreto");
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
				variaveisTemporarias.push_back($$);
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_CHAR
			{
				$$ = $1;
				$$.label = gerarNome();
				variaveisTemporarias.push_back($$);
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_STRING
			{
				$$ = $1;
				$$.label = $1.label.substr(1, $1.label.size() - 1);
				ostringstream convert;
				convert << $$.label.size();
				$$.tamanho = $$.label.size();
				$$.label = gerarNome();
				variaveisTemporarias.push_back($$);
				$$.traducao = "\t" + $$.label + " = (char*)malloc(" + convert.str() + " * sizeof(char));\n\tstrcpy(" + $$.label + ", " + $1.label + ");\n";
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
