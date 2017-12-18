%{
#define __USE_MINGW_ANSI_STDIO 0

#include <stdio.h>
#include <iostream>
#include <vector>
#include <string.h>
#include <sstream>
#include <map>
#include <algorithm>

#define YYSTYPE atributos

using namespace std;

int lines = 1;

FILE *out_file;

string cabecalho = "/*Compilador GambiArt*/\n#include <iostream>\n#include <stdio.h>\n#include <stdlib.h>\n#include <string.h>\nusing namespace std;\n\n";
string main_cabecalho = "int main(void)\n{\n";
string fim_cabecalho = "\treturn 0;\n}";

map<string, string> traducao_tipos = {{"int", "int"},
									{"float", "float"},
									{"char", "char"},
									{"string", "char*"},
									{"bool", "int"},
									{"int*", "int*"},
									{"float*", "float*"},
									{"char*", "char*"}};

string tipos_ponteiros[] = {"int*", "float*", "char*"};


/////////////////////////
struct atributos{
	string label;
	string nomeVariavel;
	string traducao;
	string tipo;
	string tamanho;
	string vetor_indices;
};

struct temporaria{
	string label;
	string tipo;
};

struct mapaDeVariaveis{
	vector<atributos> mapa;
	bool bloco_quebravel;
	string rotulo_inicio;
	string rotulo_fim;
};

struct parametroFuncao{
	string nome;
	string tipo;
	string traducao;
};

struct funcao{
	string nome;
	string tipo;
	string bloco;
	vector<parametroFuncao> parametros;
};

////////////////////////////////


int yylex(void);
void yyerror(string mensagem);


vector<mapaDeVariaveis> pilhaDeMapas;
vector<temporaria> variaveisTemporarias;
vector<funcao> listaDeFuncoes;
vector<parametroFuncao> auxParametros;

vector<string> pilha_indice;
vector<parametroFuncao> pilha_parametros;
string tipo_declaracao;


string traducao_tipo(string tipo){
	return traducao_tipos.find(tipo)->second;
}

string freeMallocs(){
	string retorno;
	for(int i=0;i<variaveisTemporarias.size();i++)
		if(find(begin(tipos_ponteiros), end(tipos_ponteiros), variaveisTemporarias[i].tipo) != end(tipos_ponteiros))
			retorno += "\tfree(" + variaveisTemporarias[i].label + ");\n";
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
		retorno += traducao_tipo(variaveisTemporarias[i].tipo) + " " + variaveisTemporarias[i].label + ";\n";
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
	for(int i=pilhaDeMapas.size() - 1;i>=0;i--){
		for(int j=0;j<pilhaDeMapas[i].mapa.size();j++){
			if(pilhaDeMapas[i].mapa[j].nomeVariavel == alvo.nomeVariavel){
				retorno = pilhaDeMapas[i].mapa[j];
				retorno.traducao = "";
				return retorno;
			}else if((i == 0) && (j == pilhaDeMapas[i].mapa.size() - 1)){
				retorno.label = "null";
				return retorno;
			}
		}
	}
	retorno.label = "null";
	return retorno;
}

funcao buscaFuncao(funcao alvo){
	funcao retorno;
	for(int i=0;i<listaDeFuncoes.size();i++){
		if(listaDeFuncoes[i].nome == alvo.nome){
			retorno = listaDeFuncoes[i];
		}else if(i == listaDeFuncoes.size() - 1){
			retorno.nome = "null";
		}
	}
	return retorno;
}

string declararFuncoes(){
	string retorno;
	for(int i=0;i<listaDeFuncoes.size();i++){
		retorno += listaDeFuncoes[i].tipo + " " + listaDeFuncoes[i].nome + "(";
		for(int j=0;j<listaDeFuncoes[i].parametros.size();j++){
			retorno += listaDeFuncoes[i].parametros[j].tipo + " " + listaDeFuncoes[i].parametros[j].nome;
			if(j < listaDeFuncoes[i].parametros.size() - 1){
				retorno += ", ";
			}
		}
		retorno += "){\n" + listaDeFuncoes[i].bloco + "}\n";
	}
	return retorno;
}

%}

%token TK_SWITCH 
%token TK_CASE 
%token TK_DEFAULT
%token TK_ARITMETICO
%token TK_OPR TK_OPL
%token TK_CAST
%token TK_TIPO
%token TK_ID
%token TK_BOOL
%token TK_NUM
%token TK_CHAR
%token TK_STRING
%token TK_MAIN TK_TIPO_INT
%token TK_FIM TK_ERROR
%token TK_PRINT
%token TK_SCAN
%token TK_IF
%token TK_ELSE
%token TK_WHILE
%token TK_FOR
%token TK_DO
%token TK_INCREMENTO
%token TK_INCREM_ATRIB_ABREV
%token TK_BREAK TK_CONTINUE
%token TK_INIT_COMMENT TK_END_COMMENT
%token TK_EXP TK_PORCENTAGEM
%token TK_RETURN

%nonassoc TK_IF
%nonassoc TK_ELSE

%start S

%left '='
%left TK_OPR
%left TK_OPL
%left TK_EXP TK_PORCENTAGEM
%left '+' '-'
%left '*' '/'

%%
S 			: GLOBAL COMANDOS FIM_GLOBAL
			{
				string out = cabecalho + declararTemporarias() + declararFuncoes() + main_cabecalho + $2.traducao + freeMallocs() + fim_cabecalho;
				out_file = fopen("out.cpp", "w");
				cout << out;
				fprintf(out_file, "%s",out.c_str());
				fclose(out_file);
			}
			;

GLOBAL		:
			{
				mapaDeVariaveis mapa;
				pilhaDeMapas.push_back(mapa);
			}
			;

FIM_GLOBAL	:
			{
				pilhaDeMapas.pop_back();
			}
			;

EMPILHA		: 
			{
				mapaDeVariaveis mapa;
				mapa.rotulo_inicio = gerarRotulo();
				mapa.rotulo_fim = gerarRotulo();
				mapa.bloco_quebravel = false;

				pilhaDeMapas.push_back(mapa);
			}
			;

EMPILHA_QUEBRAVEL :
			{
				mapaDeVariaveis mapa;
				mapa.rotulo_inicio = gerarRotulo();
				mapa.rotulo_fim = gerarRotulo();
				mapa.bloco_quebravel = true;

				pilhaDeMapas.push_back(mapa);
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
			| DECLARACAO ';'
			| ATRIBUICAO ';'
			| PRINT ';'
			| SCAN ';'
			| IF
			| L ';'
			| WHILE
			| DO
			| FOR
			| SWITCH
			| BREAK ';'
			| CONTINUE ';'
			| FUNCAO_DECLARACAO
			| FUNCAO_CHAMADA ';'
			| RETORNO ';'
			| COMENTARIOS
			;


FUNCAO_DECLARACAO		: TK_TIPO TK_ID EMPILHA '(' PARAMETROS_DECLARACAO ')' BLOCO
						{
							funcao novaFuncao;
							novaFuncao = {.nome = $2.label, .tipo = $1.label};
							for(int i=0;i<pilha_parametros.size();i++){
								novaFuncao.parametros.push_back(pilha_parametros[i]);
							}
							novaFuncao.bloco = $7.traducao;
							listaDeFuncoes.push_back(novaFuncao);
							pilha_parametros.clear();
							$$.traducao = "";
							tipo_declaracao = "";
							pilhaDeMapas.pop_back();
						}
						;


PARAMETROS_DECLARACAO	: TK_TIPO TK_ID PARAMETRO_DECLARACAO
						{
							atributos parametro = {.label = gerarNome(), .nomeVariavel = $2.label, .traducao = "", .tipo = $1.label};
							pilha_parametros.push_back({.nome = parametro.label, .tipo = parametro.tipo});
							pilhaDeMapas.back().mapa.push_back(parametro);
						}
						|
						{
							$$.traducao = "";
						}
						;


PARAMETRO_DECLARACAO	: ',' TK_TIPO TK_ID PARAMETRO_DECLARACAO
						{
							atributos parametro = {.label = gerarNome(), .nomeVariavel = $3.label, .traducao = "", .tipo = $2.label};
							pilha_parametros.push_back({.nome = parametro.label, .tipo = parametro.tipo});
							pilhaDeMapas.back().mapa.push_back(parametro);
						}
						|
						{
							$$.traducao = "";
						}
						;

FUNCAO_CHAMADA			: TK_ID '(' PARAMETROS_CHAMADA ')'
						{
							funcao busca = buscaFuncao({.nome = $1.label});

							if(busca.nome != "null"){
								$$.label = gerarNome();
								$$.tipo = busca.tipo;
								$$.traducao = "";
								for(int i=0;i<auxParametros.size();i++){
									$$.traducao += auxParametros[i].traducao;
								}
								$$.traducao += "\t" + $$.label + " = " + $1.label + "(";
								for(int i=0;i<auxParametros.size();i++){	
									if(i == auxParametros.size() - 1)
										$$.traducao += auxParametros[i].nome;
									else
										$$.traducao += auxParametros[i].nome + ", ";
								}
								$$.traducao += ");\n";

								variaveisTemporarias.push_back({.label = $$.label, .tipo = busca.tipo});
								auxParametros.clear();
							}else{
								yyerror("Funcao nao declarada");
							}
							
						}
						;

PARAMETROS_CHAMADA		: E PARAMETRO_CHAMADA
						{
							auxParametros.push_back({.nome = $1.label, .tipo = $1.tipo, .traducao = $1.traducao});
							$$.traducao = "";
						}
						|
						{
							$$.traducao = "";
						}
						;

PARAMETRO_CHAMADA		: ',' E PARAMETRO_CHAMADA
						{
							auxParametros.push_back({.nome = $2.label, .tipo = $2.tipo, .traducao = $2.traducao});
							$$.traducao = "";
						}
						|
						{
							$$.traducao = "";
						}
						;



RETORNO		: TK_RETURN E
			{
				$$.traducao = $2.traducao + "\treturn " + $2.label + ";\n";
			}
			;


COMENTARIOS : TK_INIT_COMMENT COMANDOS TK_END_COMMENT
			{
				$$.traducao = "";
			}
			| "//" COMANDO '\n'
			{
				$$.traducao = "";
			}
			;


BREAK		: TK_BREAK
			{
				for(int i=pilhaDeMapas.size() - 1; i >= 0; i--){
					if(pilhaDeMapas[i].bloco_quebravel == true){
						$$.traducao = "\tgoto " + pilhaDeMapas[i].rotulo_fim + ";\n";
						break;
					}
				}
			}
			;

CONTINUE	: TK_CONTINUE
			{
				for(int i=pilhaDeMapas.size() - 1; i >= 0; i--){
					if(pilhaDeMapas[i].bloco_quebravel){
						$$.traducao = "\tgoto " + pilhaDeMapas[i].rotulo_inicio + ";\n";
						break;
					}
				}
			}
			;


IF			: TK_IF '(' L ')' EMPILHA BLOCO ELSE
			{
				string rotulo_else = pilhaDeMapas.back().rotulo_inicio;
				string rotulo_fim = pilhaDeMapas.back().rotulo_fim;
				$$.traducao = $3.traducao + "\tif(!" + $3.label + ")\n\t\tgoto " + rotulo_else + ";\n" + $6.traducao + "\tgoto " + rotulo_fim + ";\n\t"  + rotulo_else + ":\n" + $7.traducao + "\t" + rotulo_fim + ":\n";
				
				pilhaDeMapas.pop_back();
			}
			| TK_IF '(' L ')' EMPILHA COMANDO ELSE
			{
				string rotulo_else = pilhaDeMapas.back().rotulo_inicio;
				string rotulo_fim = pilhaDeMapas.back().rotulo_fim;
				$$.traducao = $3.traducao + "\tif(!" + $3.label + ")\n\t\tgoto " + rotulo_else + ";\n" + $6.traducao + "\tgoto " + rotulo_fim + ";\n\t" + rotulo_else + ":\n" + $7.traducao + "\t" + rotulo_fim + ":\n";
				
				pilhaDeMapas.pop_back();
			}
			;
ELSE		: TK_ELSE EMPILHA BLOCO
			{
				$$ = $3;
				pilhaDeMapas.pop_back();
			}
			| TK_ELSE EMPILHA COMANDO
			{
				$$ = $3;
				pilhaDeMapas.pop_back();
			}
			|
			{
				$$.traducao = "";
			}
			;

WHILE		: TK_WHILE '(' L ')' EMPILHA_QUEBRAVEL BLOCO
			{
				string rotulo_condicao = pilhaDeMapas.back().rotulo_inicio;
				string rotulo_fim = pilhaDeMapas.back().rotulo_fim;

				$$.traducao = "\t" + rotulo_condicao + ":\n" + $3.traducao + "\tif(!" + $3.label + ")\n\t\tgoto " + rotulo_fim + ";\n" + $6.traducao + "\tgoto " + rotulo_condicao + ";\n\t" + rotulo_fim + ":\n";
				pilhaDeMapas.pop_back();
			}
			| TK_WHILE '(' L ')' EMPILHA_QUEBRAVEL COMANDO
			{
				string rotulo_condicao = pilhaDeMapas.back().rotulo_inicio;
				string rotulo_fim = pilhaDeMapas.back().rotulo_fim;

				$$.traducao = "\t" + rotulo_condicao + ":\n" + $3.traducao + "\tif(!" + $3.label + ")\n\t\tgoto " + rotulo_fim + ";\n" + $6.traducao + "\tgoto " + rotulo_condicao + ";\n\t" + rotulo_fim + ":\n";
				pilhaDeMapas.pop_back();
			}
			;

DO			: TK_DO EMPILHA_QUEBRAVEL BLOCO TK_WHILE '(' L ')' ';'
			{
				string rotulo_bloco = pilhaDeMapas.back().rotulo_inicio;
				string rotulo_fim = pilhaDeMapas.back().rotulo_fim;

				$$.traducao = "\t" + rotulo_bloco + ":\n" + $3.traducao + $6.traducao + "\tif(" + $6.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\t" + rotulo_fim + ":\n";
				pilhaDeMapas.pop_back();
			}
			| TK_DO EMPILHA_QUEBRAVEL COMANDO TK_WHILE '(' L ')' ';'
			{
				string rotulo_bloco = pilhaDeMapas.back().rotulo_inicio;
				string rotulo_fim = pilhaDeMapas.back().rotulo_fim;

				$$.traducao = "\t" + rotulo_bloco + ":\n" + $3.traducao + $6.traducao + "\tif(" + $6.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\t" + rotulo_fim + ":\n";
				pilhaDeMapas.pop_back();
			}
			;

FOR			: TK_FOR '(' EMPILHA_QUEBRAVEL ATRIBUICAO ';' L ';' ATRIBUICAO ')' BLOCO
			{
				string rotulo_incremento = pilhaDeMapas.back().rotulo_inicio;
				string rotulo_fim = pilhaDeMapas.back().rotulo_fim;
				string rotulo_condicao = gerarRotulo();

				
				$$.traducao = $4.traducao + "\t" + rotulo_condicao + ":\n" + $6.traducao + "\tif(!" + $6.label + ")\n\t\tgoto " + rotulo_fim + ";\n" + $10.traducao + "\t" + rotulo_incremento + ":\n" + $8.traducao + "\tgoto " + rotulo_condicao + ";\n\t" + rotulo_fim + ":\n";
				pilhaDeMapas.pop_back();
			}
			| TK_FOR '(' EMPILHA_QUEBRAVEL ATRIBUICAO ';' L ';' ATRIBUICAO ')' COMANDO
			{
				string rotulo_condicao = pilhaDeMapas.back().rotulo_inicio;
				string rotulo_fim = pilhaDeMapas.back().rotulo_fim;
				string rotulo_incremento = gerarRotulo();
				
				$$.traducao = $4.traducao + "\t" + rotulo_condicao + ":\n" + $6.traducao + "\tif(!" + $6.label + ")\n\t\tgoto " + rotulo_fim + ";\n" + $10.traducao + "\n\tgoto " + rotulo_incremento + "\n\t" + $8.traducao + "\tgoto " + rotulo_condicao + ";\n\t" + rotulo_fim + ":\n";
				pilhaDeMapas.pop_back();
			}
			;


SWITCH		: TK_SWITCH EMPILHA_QUEBRAVEL '(' SWITCH_COND ')' '{' SWITCH_CASES '}'
			{
				$$.traducao = $4.traducao + $7.traducao + "\t" + pilhaDeMapas.back().rotulo_fim + ":\n";
				pilhaDeMapas.pop_back();
			}
			;

SWITCH_COND : TK_ID
			{
				$1 = buscaVariavel($1);
				if($1.label == "null"){
					yyerror("Variavel nao declarada");
				}
				pilhaDeMapas.back().mapa.push_back($1);
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
				string rotulo_bloco = pilhaDeMapas.back().rotulo_inicio;
				string rotulo_fim = pilhaDeMapas.back().rotulo_fim;

				$$.traducao = $2.traducao + "\tif(" + pilhaDeMapas[pilhaDeMapas.size() - 2].mapa[0].label + " == " + $2.label + ")\n\t\tgoto " + rotulo_bloco + ";\n\tgoto " + rotulo_fim + ";\n\t" + rotulo_bloco + ":\n" + $5.traducao + "\t" + rotulo_fim + ":\n";
				pilhaDeMapas.pop_back();
			}
			;

CASE_VALOR	: TK_NUM
			{
				$$ = $1;
				$$.label = gerarNome();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			| TK_ID
			{
				$$ = buscaVariavel($1);
				if($$.label == "null"){
					yyerror("Variavel nao declarada");
				}
			}
			| TK_CHAR
			{
				$$ = $1;
				$$.label = gerarNome();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			;

L 			: L TK_OPL L
			{
				$$.label = gerarNome();
				$$.tipo = "bool";
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			| '(' L ')'
			{
				$$.label = gerarNome();
				$$.tipo = "bool";
				$$.traducao = $2.traducao + "\t" + $$.label + " = " + $2.label + ";\n";
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			|
			R
			;

R			: E TK_OPR E
			{
				if($1.tipo == $3.tipo){
					$$.label = gerarNome();
					$$.tipo = "bool";
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
				}else{
					$$.label = gerarNome();
					if($1.tipo == $3.tipo){
						$$.tipo = $1.tipo;
						$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					}else{
						$$.tipo = "bool";
						atributos tempCastVar;
						tempCastVar.label = gerarNome();
						tempCastVar.tipo = "float";
						if($1.tipo == "int"){
							$$.traducao = $1.traducao + $3.traducao + "\t" + tempCastVar.label + " = (float)" + $1.label + ";\n\t" + $$.label + " = " + tempCastVar.label + " " + $2.traducao + " " + $3.label + ";\n";
						}else{
							$$.traducao = $1.traducao + $3.traducao + "\t" + tempCastVar.label + " = (float)" + $3.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + tempCastVar.label + ";\n";
						}
						variaveisTemporarias.push_back({.label = tempCastVar.label, .tipo = tempCastVar.tipo});
					}
				}
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			;

INDICE 		: '[' E ']'
			{
				$$.label = gerarNome();
				$$.tipo = $2.tipo;
				$$.traducao = $2.traducao + "\t" + $$.label + " = " + $2.label + ";\n";
				pilha_indice.push_back($$.label);
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			;

INDICE_REC	: INDICE INDICE_REC
			{
				$$.label = gerarNome();
				$$.tipo = "int";
				if($2.label != ""){
					$$.traducao = $1.traducao + $2.traducao + "\t" + $$.label + " = " + $1.label + " * " + $2.label + ";\n";
				}else{
					$$.traducao = $1.traducao + "\t" + $$.label + " = " + $1.label + ";\n";
				}	
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			|
			{
				$$.label = "";
				$$.traducao = "";
				$$.tipo = "";
			}
			;

INDICES		: INDICE INDICE_REC
			{
				$$.label = gerarNome();
				$$.tipo = "int";
				if($2.label != ""){
					$$.traducao = $1.traducao + $2.traducao + "\t" + $$.label + " = " + $1.label + " * " + $2.label + ";\n";
				}else{
					$$.traducao = $1.traducao + "\t" + $$.label + " = " + $1.label + ";\n";
				}	
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			;

ATRIB_DECLARACAO	: '=' E
					{
						$$ = $2;
					}
					|
					{
						$$.traducao = "";
					}
					;



ATRIB_ARRAY			: '=' '{' ATRIB_MATRIX '}'
					{

					}
					|
					{
						$$.traducao = "";
					}
					;



ATRIB_MATRIX		: TERM REC_MATRIX
					{
						
					}
					| '{' ATRIB_MATRIX '}'
					{

					}
					;

REC_MATRIX			: ',' ATRIB_MATRIX
					{

					}
					|
					{
						$$.traducao = "";
					}
					;


TERM				: E
					{

					}
					|
					{
						$$.traducao = "";
					}
					;


DECLARACAO	: TK_TIPO TK_ID ATRIB_DECLARACAO MULTIPLAS_DECLARACOES
			{
				$$.label = gerarNome();
				$$.nomeVariavel = $2.nomeVariavel;
				$$.tipo = tipo_declaracao;
				
				if($3.traducao != ""){
					$$.tamanho = $3.tamanho;
					$$.traducao = $3.traducao +
					"\t" + $$.label + " = " + $3.label + ";\n" +
					$4.traducao;

					pilhaDeMapas.back().mapa.push_back($$);
					variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
					tipo_declaracao = "";
				}else{
					$$.traducao = $4.traducao;
					pilhaDeMapas.back().mapa.push_back($$);
					variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
				}
			}
			| TK_TIPO TK_ID INDICES ATRIB_ARRAY MULTIPLAS_DECLARACOES
			{
				$$ = buscaVariavel($2);
				
				if($$.label == "null"){
					if($3.label != ""){
						$$.label = gerarNome();
						$$.nomeVariavel = $2.nomeVariavel;
						$$.tipo = tipo_declaracao;

						atributos temp_vetor;
						temp_vetor.label = gerarNome();
						temp_vetor.tipo = "int*";

						//TRADUCAO
						$$.traducao = $3.traducao + "\t" + $$.label + " = (" + $$.tipo + "*)malloc(" + $3.label + " * sizeof(" + $$.tipo + "));\n";
						$$.traducao += "\t" + temp_vetor.label + " = (int*)malloc(" + to_string(pilha_indice.size()) + " * sizeof(int));\n";
						for(int i=0;i<pilha_indice.size();i++){
							$$.vetor_indices = temp_vetor.label;
							$$.traducao += "\t" + temp_vetor.label + "[" + to_string(i) + "]" + " = " + pilha_indice[i] + ";\n";
						}
						$$.traducao += $5.traducao;
						//

						$$.tipo += "*";
						$$.tamanho = to_string(pilha_indice.size());

						pilhaDeMapas.back().mapa.push_back($$);
						variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
						variaveisTemporarias.push_back({.label = temp_vetor.label, .tipo = temp_vetor.tipo});
						tipo_declaracao = "";
						pilha_indice.clear();
					}
				}
				else{

				}
			}
			;

MULTIPLAS_DECLARACOES	: ',' TK_ID ATRIB_DECLARACAO MULTIPLAS_DECLARACOES
						{
							$$ = buscaVariavel($2);
							if($$.label == "null"){
								$$.label = gerarNome();
								$$.nomeVariavel = $2.nomeVariavel;
								$$.tipo = tipo_declaracao;
								
								if($3.traducao != ""){
									$$.tamanho = $3.tamanho;
									$$.traducao = $3.traducao +
									"\t" + $$.label + " = " + $3.label + ";\n" +
									$4.traducao;

									pilhaDeMapas.back().mapa.push_back($$);
									variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});

								}else{
									$$.traducao = $4.traducao;
									variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
								}
								
							}else{

							}
						}
						| ',' TK_ID INDICES ATRIB_ARRAY MULTIPLAS_DECLARACOES
						{
							$$ = buscaVariavel($2);
							if($$.label == "null"){
								if($3.label != ""){
									$$.label = gerarNome();
									$$.nomeVariavel = $2.nomeVariavel;
									$$.tipo = tipo_declaracao;

									atributos temp_vetor;
									temp_vetor.label = gerarNome();
									temp_vetor.tipo = "int*";

									$$.traducao = $3.traducao + "\t" + $$.label + " = (" + $$.tipo + "*)malloc(" + $3.label + " * sizeof(" + $$.tipo + "));\n";
									$$.traducao += "\t" + temp_vetor.label + " = (int*)malloc(" + to_string(pilha_indice.size()) + " * sizeof(int));\n";
									for(int i=0;i<pilha_indice.size();i++){
										$$.vetor_indices = temp_vetor.label;
										$$.traducao += "\t" + temp_vetor.label + "[" + to_string(i) + "]" + " = " + pilha_indice[i] + ";\n";
									}
									$$.traducao += $5.traducao;


									$$.tipo += "*";
									$$.tamanho = to_string(pilha_indice.size());

									pilhaDeMapas.back().mapa.push_back($$);
									variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
									variaveisTemporarias.push_back({.label = temp_vetor.label, .tipo = temp_vetor.tipo});
									pilha_indice.clear();
								}
							}
							else{

							}
						}
						|
						{
							$$.traducao = "";
						}
						;



ATRIBUICAO	: TK_ID INDICES '=' E
			{
				$$ = buscaVariavel($1);
				if($$.label == "null"){
					if($2.label != ""){
						$$.label = gerarNome();
						$$.nomeVariavel = $1.nomeVariavel;
						$$.tipo = $4.tipo;
						$$.vetor_indices = $4.vetor_indices;
						$$.traducao = $4.traducao + "\t" + $$.label + " = " + $4.label + ";\n";
						pilhaDeMapas.back().mapa.push_back($$);
						variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
					}else{
						
					}
				}else{
					if($2.label != ""){
						atributos contador1 = {.label = gerarNome()};
						atributos contador2 = {.label = gerarNome()};
						atributos tempIndice = {.label = gerarNome()};
						atributos indiceFinal = {.label = gerarNome()};
						atributos reqIndice = {.label = gerarNome()};

						string rotulo_condicao = gerarRotulo();
						string rotulo_condicao2 = gerarRotulo();
						string rotulo_fim = gerarRotulo();
						string rotulo_fim2 = gerarRotulo();

						$$.traducao = $4.traducao + $2.traducao +
						"\t" + reqIndice.label + " = (int*)malloc(" + to_string(pilha_indice.size()) + " * sizeof(int));\n";

						for(int i=0;i<pilha_indice.size();i++)
							$$.traducao += "\t" + reqIndice.label + "[" + to_string(i) + "] = " + pilha_indice[i] + ";\n";

						$$.traducao += "\t" + contador1.label + " = 0;\n" +
						"\t" + tempIndice.label + " = 0;\n" +
						"\t" + indiceFinal.label + " = 0;\n" +
						"\t" + rotulo_condicao + ":\n" +
						"\tif(!(" + contador1.label + " < " + $$.tamanho + "))\n\t\tgoto " + rotulo_fim + ";\n" +
						"\t" + contador2.label + " = " + contador1.label + " + 1;\n" +
						"\t" + tempIndice.label + " = " + reqIndice.label + "[" + contador1.label + "];\n" +
						"\t" + rotulo_condicao2 + ":\n" +
						"\tif(!(" + contador2.label + " < " + $$.tamanho + "))\n\t\tgoto " + rotulo_fim2 + ";\n" +
						"\t" + tempIndice.label + " = " + tempIndice.label + " * " + $$.vetor_indices + "[" + contador2.label + "]" + ";\n" +
						"\t" + contador2.label + "++;\n" +
						"\tgoto " + rotulo_condicao2 + ";\n" +
						"\t" + rotulo_fim2 + ":\n" +
						"\t" + indiceFinal.label + " = " + indiceFinal.label + " + " + tempIndice.label + ";\n" +
						"\t" + contador1.label + "++;\n" +
						"\tgoto " + rotulo_condicao + ";\n\t" +
						rotulo_fim + ":\n" +
						"\t" + $$.label + "[" + indiceFinal.label + "] = " + $4.label + ";\n";

						variaveisTemporarias.push_back({.label = contador1.label, .tipo = "int"});
						variaveisTemporarias.push_back({.label = contador2.label, .tipo = "int"});
						variaveisTemporarias.push_back({.label = tempIndice.label, .tipo = "int"});
						variaveisTemporarias.push_back({.label = indiceFinal.label, .tipo = "int"});
						variaveisTemporarias.push_back({.label = reqIndice.label, .tipo = "int*"});
					}else{
						$$.traducao = $4.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
					}
				}
				pilha_indice.clear();
			}
			| TK_ID '=' E
			{
				$$ = buscaVariavel($1);
				if($$.label == "null"){
					if($2.label != ""){
						$$.label = gerarNome();
						$$.nomeVariavel = $1.nomeVariavel;
						$$.tipo = $3.tipo;
						$$.tamanho = $3.tamanho;
						$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
						pilhaDeMapas.back().mapa.push_back($$);
						variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
					}else{

					}
				}else{
					$$.traducao = $3.traducao +
					+ "\t" + $$.label + " = " + $3.label + ";\n";
				}
			}
			| TK_ID '=' TK_BOOL
			{
				$$ = buscaVariavel($1);
				if($$.label == "null"){
					$$.label = gerarNome();
					$$.nomeVariavel = $1.nomeVariavel;
					$$.tipo = $3.tipo;
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
					pilhaDeMapas.back().mapa.push_back($$);
					variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
				}else{
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
				}
			}
			| TK_ID '=' TK_CHAR
			{
				$$ = buscaVariavel($1);
				if($$.label == "null"){
					$$.label = gerarNome();
					$$.nomeVariavel = $1.nomeVariavel;
					$$.tipo = $3.tipo;
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
					pilhaDeMapas.back().mapa.push_back($$);
					variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
				}else{
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
				}
			}
			| TK_TIPO TK_ID '=' E
			{
				$$ = buscaVariavel($2);
				if($$.label == "null"){
					$$.label = gerarNome();
					$$.nomeVariavel = $2.nomeVariavel;
					$$.tipo = $1.label;
					$$.traducao = $4.traducao + "\t" + $$.label + " = " + $4.label + ";\n";

					pilhaDeMapas.back().mapa.push_back($$);
					variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
				}else{
					$$.traducao = $4.traducao + "\t" + $$.label + " = " + $4.label + ";\n";
				}
			}
			| TK_ID '=' L
			{
				$$ = buscaVariavel($1);
				if($$.label == "null"){
					$$.label = gerarNome();
					$$.nomeVariavel = $1.nomeVariavel;
					$$.tipo = $3.tipo;
					
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
					pilhaDeMapas.back().mapa.push_back($$);
					variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
				}else{
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
				}
			}
			| TK_ID TK_INCREMENTO
			{
				$$ = buscaVariavel($1);				
				if($$.label == "null"){
					yyerror("Variavel nao declarada");
				}else{
					$$.traducao = "\t" + $$.label + " = " + $$.label + " " + $2.traducao[0] + " 1;\n";
				}
			}
			| TK_ID TK_INCREM_ATRIB_ABREV E
			{
				$$ = buscaVariavel($1);				
				if($$.label == "null"){
					yyerror("Variavel nao declarada");
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
				if($1.tipo == "string" && $3.tipo == "string"){
					$$.label = gerarNome();
					$$.tamanho = gerarNome();
					$$.tipo = "string";
					$$.traducao = $1.traducao + $3.traducao + "\t" + $$.tamanho + " = " + $1.tamanho + " + " + $3.tamanho + ";\n" +
					"\t" + $$.label + " = (char*)malloc(" + $$.tamanho + " * sizeof(char)" + ");\n\t" + 
					$$.label + "[0] = \'\\0\';\n" + 
					"\tstrcat(" + $$.label + "," + $1.label + ");\n" + 
					"\tstrcat(" + $$.label + "," + $3.label + ");\n";
					variaveisTemporarias.push_back({.label = $$.tamanho, .tipo = "int"});
				}
				else{
					$$.label = gerarNome();
					if($1.tipo == $3.tipo){
						$$.tipo = $1.tipo;
						$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + $3.label + ";\n";
					}else{
						$$.tipo = "float";
						atributos tempCastVar;
						tempCastVar.label = gerarNome();
						tempCastVar.tipo = "float";
						if($1.tipo == "int"){
							$$.traducao = $1.traducao + $3.traducao + "\t" + tempCastVar.label + " = (float)" + $1.label + ";\n\t" + $$.label + " = " + tempCastVar.label + " " + $2.traducao + " " + $3.label + ";\n";
						}else{
							$$.traducao = $1.traducao + $3.traducao + "\t" + tempCastVar.label + " = (float)" + $3.label + ";\n\t" + $$.label + " = " + $1.label + " " + $2.traducao + " " + tempCastVar.label + ";\n";
						}
						variaveisTemporarias.push_back({.label = tempCastVar.label, .tipo = tempCastVar.tipo});
					}
				}
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			| E TK_EXP E
			{
				$$.label = gerarNome();
				$$.tipo = "float";

				atributos tempVarInic;
				tempVarInic.label = gerarNome();
				tempVarInic.tipo = "int";
				tempVarInic.traducao = "\t" + tempVarInic.label + " = 0;\n"; 

				string rotulo_condicao = gerarRotulo();
				string rotulo_fim = gerarRotulo();
				
				$$.traducao = $1.traducao + $3.traducao +
				"\t" + $$.label + " = 1;\n" +
				"\tif(" + $3.label + " == 0)\n\t\t" + "goto " + rotulo_fim + ";\n" +
				"\t" + tempVarInic.label + " = 0;\n" +
				"\t" + rotulo_condicao + ":\n" +
				"\tif(!(" + tempVarInic.label + " < " + "abs(" + $3.label + ")))\n\t\tgoto " + rotulo_fim + ";\n" +
				"\t" + $$.label + " = " + $$.label + " * " + $1.label + ";\n" +
				"\t" + tempVarInic.label + "++;\n" +
				"\tgoto " + rotulo_condicao + ";\n\t" +
				rotulo_fim + ":\n" +
				"\tif(" + $3.label + " < 0)\n\t" +
				"\t" + $$.label + " = 1 / " + $$.label + ";\n";

				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
				variaveisTemporarias.push_back({.label = tempVarInic.label, .tipo = tempVarInic.tipo});
			}
			| E TK_PORCENTAGEM E
			{
				$$.label = gerarNome();
				$$.tipo = "float";
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label + " = " + $1.label + " * " + $3.label + ";\n\t" + $$.label + " = " + $$.label + " / 100;\n";
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			| FUNCAO_CHAMADA
			{
				$$ = $1;
			}
			| TK_CAST E
			{
				$$.label = gerarNome();				
				if($1.label == "(float)"){
					$$.tipo = "float";
					$$.traducao = $2.traducao + "\t" + $$.label + " = (float)" + $2.label + ";\n";
				}else if($1.label == "(int)"){
					$$.tipo = "int";
					$$.traducao = $2.traducao + "\t" + $$.label + " = (int)" + $2.label + ";\n";
				}
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			| TK_NUM
			{
				$$.label = gerarNome();
				$$.tipo = $1.tipo;
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
			}
			| TK_ARITMETICO E
			{
				if($1.traducao != "*" || $1.traducao != "/"){
					$$ = $2;
					$$.label = gerarNome();
					$$.traducao = $2.traducao + "\t" + $$.label + " = -" + $2.label + ";\n";
					variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
				}else{
					yyerror("Sinal incorreto");
				}
			}
			| TK_ID
			{
				$$ = buscaVariavel($1);
				if($$.label == "null"){
					yyerror("Variavel nao declarada");
				}
			}
			| TK_ID INDICES
			{
				$$ = buscaVariavel($1);
				if($$.label == "null"){
					yyerror("Variavel nao declarada");
				}else{
						atributos contador1 = {.label = gerarNome()};
						atributos contador2 = {.label = gerarNome()};
						atributos tempIndice = {.label = gerarNome()};
						atributos indiceFinal = {.label = gerarNome()};
						atributos reqIndice = {.label = gerarNome()};

						string rotulo_condicao = gerarRotulo();
						string rotulo_condicao2 = gerarRotulo();
						string rotulo_fim = gerarRotulo();
						string rotulo_fim2 = gerarRotulo();

						$$.traducao = $2.traducao +
						"\t" + reqIndice.label + " = (int*)malloc(" + to_string(pilha_indice.size()) + " * sizeof(int));\n";

						for(int i=0;i<pilha_indice.size();i++)
							$$.traducao += "\t" + reqIndice.label + "[" + to_string(i) + "] = " + pilha_indice[i] + ";\n";

						$$.traducao += "\t" + contador1.label + " = 0;\n" +
						"\t" + tempIndice.label + " = 0;\n" +
						"\t" + indiceFinal.label + " = 0;\n" +
						"\t" + rotulo_condicao + ":\n" +
						"\tif(!(" + contador1.label + " < " + $$.tamanho + "))\n\t\tgoto " + rotulo_fim + ";\n" +
						"\t" + contador2.label + " = " + contador1.label + " + 1;\n" +
						"\t" + tempIndice.label + " = " + reqIndice.label + "[" + contador1.label + "];\n" +
						"\t" + rotulo_condicao2 + ":\n" +
						"\tif(!(" + contador2.label + " < " + $$.tamanho + "))\n\t\tgoto " + rotulo_fim2 + ";\n" +
						"\t" + tempIndice.label + " = " + tempIndice.label + " * " + $$.vetor_indices + "[" + contador2.label + "]" + ";\n" +
						"\t" + contador2.label + "++;\n" +
						"\tgoto " + rotulo_condicao2 + ";\n" +
						"\t" + rotulo_fim2 + ":\n" +
						"\t" + indiceFinal.label + " = " + indiceFinal.label + " + " + tempIndice.label + ";\n" +
						"\t" + contador1.label + "++;\n" +
						"\tgoto " + rotulo_condicao + ";\n\t" +
						rotulo_fim + ":\n";
						
						$$.label += "[" + indiceFinal.label + "]";

						variaveisTemporarias.push_back({.label = contador1.label, .tipo = "int"});
						variaveisTemporarias.push_back({.label = contador2.label, .tipo = "int"});
						variaveisTemporarias.push_back({.label = tempIndice.label, .tipo = "int"});
						variaveisTemporarias.push_back({.label = indiceFinal.label, .tipo = "int"});
						variaveisTemporarias.push_back({.label = reqIndice.label, .tipo = "int*"});
				}
			}
			| TK_STRING
			{
				$$.label = gerarNome();
				$$.tamanho = gerarNome();
				$$.tipo = $1.tipo;
				$$.traducao = "\t" + $$.tamanho + " = " + to_string($1.label.size() - 1) + ";\n\t" + $$.label + " = (char*)malloc(" + $$.tamanho + " * sizeof(char));\n\tstrcpy(" + $$.label + ", " + $1.label + ");\n";
				variaveisTemporarias.push_back({.label = $$.label, .tipo = $$.tipo});
				variaveisTemporarias.push_back({.label = $$.tamanho, .tipo = "int"});
			}
			;



PRINT		: TK_PRINT '(' REC_PRINT ')'
			{
				$$.traducao = $3.traducao;
			}
			;

REC_PRINT	: E PRINT_ARG
			{
				$$.traducao = "\tcout << " + $1.label + ";\n" + $2.traducao +
				"\tcout << endl;\n";
			}
			;

PRINT_ARG	: ',' E PRINT_ARG
			{
				$$.traducao = $3.traducao + "\tcout << " + $2.label + ";\n";
			}
			|
			{
				$$.traducao = "";
			}
			;



SCAN		: EMPILHA TK_SCAN '(' TK_ID ')'
			{
				atributos temp = buscaVariavel($4);

				if(temp.tipo == "string"){
					string rotulo_bloco = pilhaDeMapas.back().rotulo_inicio;

					temporaria stringRead = {.label = gerarNome(), .tipo = "string"};
					temporaria tempChar = {.label = gerarNome(), .tipo = "char"};
					temporaria contador = {.label = gerarNome(), .tipo = "int"};
					
					$$.traducao = "\t" + contador.label + " = 0;\n" +
					"\t" + stringRead.label + " = (char*)malloc(sizeof(char));\n" +
					"\t" + rotulo_bloco + ":\n" +
					"\t" + tempChar.label + " = getchar();\n" +
					"\t" + stringRead.label + " = (char*)realloc(" + stringRead.label + ", " + contador.label + " + 1);\n" +
					"\t" + stringRead.label + "[" + contador.label + "]" + " = " + tempChar.label + ";\n" +
					"\t" + contador.label + "++;\n" +
					"\tif(" + tempChar.label + " != \'\\n\')\n\t\tgoto " + rotulo_bloco + ";\n" +
					"\t" + stringRead.label + "[" + contador.label + "] = \'\\0\';\n" +
					"\tfree(" + temp.label + ");\n" +
					"\t" + temp.label + " = " + stringRead.label + ";\n" +
					"\t" + temp.tamanho + " = " + contador.label + ";\n";
					
					variaveisTemporarias.push_back({.label = stringRead.label, .tipo = stringRead.tipo});
					variaveisTemporarias.push_back({.label = tempChar.label, .tipo = tempChar.tipo});
					variaveisTemporarias.push_back({.label = contador.label, .tipo = contador.tipo});

				}else if(temp.tipo == "int" || temp.tipo == "float" || temp.tipo == "char"){
					$$.traducao = "\tcin >> " + temp.label + ";\n";
				}
			}
			;


%%
#include "lex.yy.c"
#include <string>

int yyparse();

int main( int argc, char* argv[] )
{
	yyparse();
	return 0;
}
void yyerror(string mensagem)
{
	cout << "Erro: " << mensagem << " Linha: " << lines << endl;
	exit (0);
}

/*
Consertar:
- free antes de sobrepor ponteiro string
- remover "nomeVariavel" criando outra struct
- problema de ter diversos acessos a indices no mesmo comando
*/