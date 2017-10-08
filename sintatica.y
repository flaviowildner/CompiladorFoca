%{
#include <stdio.h>
#include <iostream>
#include <vector>
#include <string>
#include <sstream>

#define YYSTYPE atributos

using namespace std;

struct atributos
{
	string label;
	string nomeVariavel;
	string traducao;
	string tipo;
	string valor;
};


int yylex(void);
void yyerror(string);


static class mapaDeVariaveis{
	public:
		vector<atributos> mapa;
		void addVariavel(struct atributos E1, struct atributos E2);

} mapaDeVariaveis;

void mapaDeVariaveis::addVariavel(struct atributos E1, struct atributos E2){
	atributos temp;
	temp = E2;
	temp.nomeVariavel = E1.nomeVariavel;
	mapa.push_back(temp);
}

string gerarNome(){
	static int numeroVariaveis = 0;
	numeroVariaveis++;

	ostringstream stringNumeroVariaveis;
	stringNumeroVariaveis << numeroVariaveis;

	return "var_" + stringNumeroVariaveis.str();
}

string conversaoImplicita(atributos E1, atributos E2, string operador, atributos *$$){
	if(E1.tipo == "bool" || E2.tipo == "bool"){
		yyerror("Error: Operação com tipo boolean é invalida.");
	}

	if(E1.tipo == "id" || E2.tipo == "id"){
		if(E1.tipo == "id"){
			for(int i=0;i<mapaDeVariaveis.mapa.size();i++){
				if(mapaDeVariaveis.mapa[i].nomeVariavel == E1.nomeVariavel){
					E1 = mapaDeVariaveis.mapa[i];
					E1.traducao = "";
					break;
				}
				if(i >= mapaDeVariaveis.mapa.size() - 1)
					yyerror("Error: Variavel nao existe.");
			}
		}
		if(E2.tipo == "id"){
			for(int i=0;i<mapaDeVariaveis.mapa.size();i++){
				if(mapaDeVariaveis.mapa[i].nomeVariavel == E2.nomeVariavel){
					E2 = mapaDeVariaveis.mapa[i];
					E2.traducao = "";
					break;
				}
				if(i >= mapaDeVariaveis.mapa.size() - 1)
					yyerror("Error: Variavel nao existe.");
			}
		}
	}
	
	if(operador == "<" || operador == ">" || operador == ">=" || operador == "<=" || operador == "==" || operador == "!=" || operador == "&&" || operador == "||"){
		if(E1.tipo == E2.tipo){
				$$->label = gerarNome();
				$$->tipo = "bool";
				$$->traducao = E1.traducao + E2.traducao + "\t" + $$->tipo + " " + $$->label + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
		}else{
			if(E1.tipo == "int"){
				string tempCastVarLabel = gerarNome();
				string builder = "\t" + E2.tipo + " " + tempCastVarLabel + " = " + "(" + E2.tipo + ")" + E1.label + ";\n";
				E1.label = tempCastVarLabel;
				$$->label = gerarNome();
				$$->tipo = "bool";
				$$->traducao = E1.traducao + E2.traducao + builder + "\t" + $$->tipo + " " + $$->label + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
			}else{
				string tempCastVarLabel = gerarNome();
				string builder = "\t" + E1.tipo + " " + tempCastVarLabel + " = " + "(" + E1.tipo + ")" + E2.label + ";\n";
				E2.label = tempCastVarLabel;
				$$->label = gerarNome();
				$$->tipo = "bool";
				$$->traducao = E1.traducao + E2.traducao + builder + "\t" + $$->tipo + " " + $$->label + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
			}
		}
	}

	if(operador == "+" || operador == "-" || operador == "*" || operador == "/"){
		if(E1.tipo == E2.tipo){
				$$->label = gerarNome();
				$$->traducao = E1.traducao + E2.traducao + "\t" + E1.tipo + " " + $$->label + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
				$$->tipo = E1.tipo;
		}else{
			if(E1.tipo == "int"){
				string tempCastVarLabel = gerarNome();
				string builder = "\t" + E2.tipo + " " + tempCastVarLabel + " = " + "(" + E2.tipo + ")" + E1.label + ";\n";
				E1.label = tempCastVarLabel;
				$$->label = gerarNome();
				$$->tipo = E2.tipo;
				$$->traducao = E1.traducao + E2.traducao + builder + "\t" + $$->tipo + " " + $$->label + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
			}else{
				string tempCastVarLabel = gerarNome();
				string builder = "\t" + E1.tipo + " " + tempCastVarLabel + " = " + "(" + E1.tipo + ")" + E2.label + ";\n";
				E2.label = tempCastVarLabel;
				$$->label = gerarNome();
				$$->tipo = E1.tipo;
				$$->traducao = E1.traducao + E2.traducao + builder + "\t" + $$->tipo + " " + $$->label + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
			}
		}
	}
}

%}

%token TK_CAST
%token TK_ID
%token TK_BOOL
%token TK_NUM
%token TK_CHAR
%token TK_MAIN TK_TIPO_INT
%token TK_FIM TK_ERROR

%start S


%right '='
%left "||" "&&"
%left "==" "!="
%left '<' '>' ">=" "<="
%left '+' '-'
%left '*' '/' "%%"


%%

S 			: TK_TIPO_INT TK_MAIN '(' ')' BLOCO
			{
				cout << "/*Compilador FOCA*/\n" << "#include <iostream>\n#include<string.h>\n#include<stdio.h>\nint main(void)\n{\n" << $5.traducao << "\treturn 0;\n}" << endl;
			}
			|
			;

BLOCO		: '{' COMANDOS '}'
			{
				$$.traducao = $2.traducao;
			}
			;

COMANDOS	: COMANDO COMANDOS
			{ 
				$$.traducao = $1.traducao + $2.traducao;
			}
			|
			;

COMANDO 	: E ';'{ }
			;


E 			: '(' E ')'
			{
				$$ = $2;
			} 
			| E '+' E
			{
				conversaoImplicita($1, $3, "+", &$$);
			}
			| E '-' E
			{
				conversaoImplicita($1, $3, "-", &$$);
			}
			| E '*' E
			{
				conversaoImplicita($1, $3, "*", &$$);
			}
			| E '/' E
			{
				conversaoImplicita($1, $3, "/", &$$);
			}
			| E '>' E
			{
				conversaoImplicita($1, $3, ">", &$$);
			}
			| E '<' E
			{
				conversaoImplicita($1, $3, "<", &$$);
			}
			| E '>' '=' E
			{
				conversaoImplicita($1, $4, ">=", &$$);
			}
			| E '<' '=' E
			{
				conversaoImplicita($1, $4, "<=", &$$);
			}
			| E '=' '=' E
			{
				conversaoImplicita($1, $4, "==", &$$);
			}
			| E '!' '=' E
			{
				conversaoImplicita($1, $4, "!=", &$$);
			}
			| E '&' '&' E
			{
				conversaoImplicita($1, $4, "&&", &$$);
			}
			| E '|' '|' E
			{
				conversaoImplicita($1, $4, "||", &$$);
			}
			| E '%' '%' E
			{
				string tempNome = gerarNome();
				string tempNome2 = gerarNome();
				$$.traducao = $1.traducao + $4.traducao + "\t" + tempNome + " = " + $1.label + " * " + $4.label + ";\n" + "\t" + tempNome2 + " = " + tempNome + " / 100;\n";
				$$.label = tempNome2;
			}
			| TK_ID '=' E
			{
				if($3.tipo == "id"){
					for(int i=0;i<mapaDeVariaveis.mapa.size();i++){
						if(mapaDeVariaveis.mapa[i].nomeVariavel == $3.nomeVariavel){
							$3 = mapaDeVariaveis.mapa[i];
							$$.traducao = "\t" + mapaDeVariaveis.mapa[i].tipo + " " + $1.nomeVariavel + " = " + mapaDeVariaveis.mapa[i].nomeVariavel + ";\n";
							mapaDeVariaveis.addVariavel($1, $3);					
						}
						if(i >= mapaDeVariaveis.mapa.size() - 1)
							yyerror("Error-> Variavel nao declarada");
					}
				}else{
					mapaDeVariaveis.addVariavel($1, $3);
					$$.traducao = $3.traducao + "\t" + $3.tipo + " " + $1.nomeVariavel + " = " + $3.label + ";\n";
				}				
			}
			| T
			{
				$$ = $1;
			}
			| TK_ID
			{
				$$ = $1;
			}
			|
			;

T 			: C F
			{
				$$ = $2;
				$$.label = gerarNome();
				
				if($1.label == "(float)"){
					$$.traducao = "\tfloat " + $$.label + " = " + $2.label + ";\n";
					$$.tipo = "float";
				}else if($1.label == "(int)"){
					$$.traducao = "\tint " + $$.label + " = " + $2.label + ";\n";
					$$.tipo = "int";
				}else{
					$$.traducao = "\t" + $2.tipo + " " + $$.label + " = " + $2.label + ";\n";
				}
			}
			| C '-' F
			{
				$$ = $3;
				$$.label = gerarNome();			

				if($1.label == "(float)"){
					$$.traducao = "\tfloat " + $$.label + " = -" + $3.label + ";\n";
					$$.tipo = "float";
				}else if($1.label == "(int)"){
					$$.traducao = "\tint " + $$.label + " = -" + $3.label + ";\n";
					$$.tipo = "int";
				}else{
					$$.traducao = "\t" + $3.tipo + " " + $$.label + " = -" + $3.label + ";\n";
				}
			}
			| C '+' T
			{
				$$ = $3;
				$$.label = gerarNome();

				if($1.label == "(float)"){
					$$.traducao = "\tfloat " + $$.label + " = " + $3.label + ";\n";
					$$.tipo = "float";
				}else if($1.label == "(int)"){
					$$.traducao = "\tint " + $$.label + " = " + $3.label + ";\n";
					$$.tipo = "int";
				}else{
					$$.traducao = "\t" + $3.tipo + " " + $$.label + " = " + $3.label + ";\n";
				}
			}
			;

F   		: TK_NUM
			{
				$$ = $1;
			}
			| TK_ID
			{
				$$ = $1;
				$$.label = gerarNome();
			}
			| TK_CHAR
			{
				$$ = $1;
			}
			|
			;

C 			: TK_CAST
			{
				$$ = $1;
			}
			|
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