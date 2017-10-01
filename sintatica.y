%{
#include <stdio.h>
#include <iostream>
#include <string>
#include <sstream>

#define YYSTYPE atributos

using namespace std;

struct atributos
{
	string label;
	string traducao;
	string tipo;
};

int yylex(void);
void yyerror(string);

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

	if(operador == "+" || operador == "-" || operador == "*" || operador == "/"){
		if(E1.tipo == E2.tipo){
				string tempLabelResultado = gerarNome();
				$$->label = tempLabelResultado;
				return "\t" + E1.tipo + " " + tempLabelResultado + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
		}else if(E1.tipo != E2.tipo){
			if(E1.tipo == "int"){
				string tempCastVarLabel = gerarNome();
				string builder = "\t" + E2.tipo + " " + tempCastVarLabel + " = " + "(" + E2.tipo + ")" + E1.label + ";\n";
				E1.label = tempCastVarLabel;
				string tempLabelResultado = gerarNome();
				$$->label = tempLabelResultado;
				return builder + "\t" + E2.tipo + " " + tempLabelResultado + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
			}else{
				string tempCastVarLabel = gerarNome();
				string builder = "\t" + E1.tipo + " " + tempCastVarLabel + " = " + "(" + E1.tipo + ")" + E2.label + ";\n";
				E2.label = tempCastVarLabel;
				string tempLabelResultado = gerarNome();
				$$->label = tempLabelResultado;
				return builder + "\t" + E1.tipo + " " + tempLabelResultado + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
			}
		}
	}else if(operador == "<" || operador == ">" || operador == ">=" || operador == "<=" || operador "==" || operador == "!=" || operador == "&&" || operador == "||"){
		if(E1.tipo == E2.tipo){
				string tempLabelResultado = gerarNome();
				$$->label = tempLabelResultado;
				return "\tbool " + tempLabelResultado + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
		}else if(E1.tipo != E2.tipo){
			if(E1.tipo == "int"){
				string tempCastVarLabel = gerarNome();
				string builder = "\t" + E2.tipo + " " + tempCastVarLabel + " = " + "(" + E2.tipo + ")" + E1.label + ";\n";
				E1.label = tempCastVarLabel;
				string tempLabelResultado = gerarNome();
				$$->label = tempLabelResultado;
				return builder + "\tbool " + tempLabelResultado + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
			}else{
				string tempCastVarLabel = gerarNome();
				string builder = "\t" + E1.tipo + " " + tempCastVarLabel + " = " + "(" + E1.tipo + ")" + E2.label + ";\n";
				E2.label = tempCastVarLabel;
				string tempLabelResultado = gerarNome();
				$$->label = tempLabelResultado;
				return builder + "\tbool " + tempLabelResultado + " = " + E1.label + " " + operador + " " + E2.label + ";\n";
			}
		}
	}
}



%}

%token TK_CAST
%token TK_BOOL
%token TK_NUM
%token TK_CHAR
%token TK_MAIN TK_ID TK_TIPO_INT
%token TK_FIM TK_ERROR

%start S

%left "||" "&&"
%left "==" "!="
%left '<' '>' ">=" "<="
%left '+' '-'
%left '*' '/'



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
				$$.traducao = $1.traducao + $3.traducao + conversaoImplicita($1, $3, "+", &$$);
			}
			| E '-' E
			{
				$$.traducao = $1.traducao + $3.traducao + conversaoImplicita($1, $3, "-", &$$);
			}
			| E '*' E
			{
				$$.traducao = $1.traducao + $3.traducao + conversaoImplicita($1, $3, "*", &$$);
			}
			| E '/' E
			{
				$$.traducao = $1.traducao + $3.traducao + conversaoImplicita($1, $3, "/", &$$);
			}
			| E '>' E
			{
				$$.traducao = $1.traducao + $3.traducao + conversaoImplicita($1, $3, ">", &$$);
			}
			| E '<' E
			{
				$$.traducao = $1.traducao + $3.traducao + conversaoImplicita($1, $3, "<", &$$);
			}
			| E '>' '=' E
			{
				$$.traducao = $1.traducao + $4.traducao + conversaoImplicita($1, $4, ">=", &$$);
			}
			| E '<' '=' E
			{
				$$.traducao = $1.traducao + $4.traducao + conversaoImplicita($1, $4, "<=", &$$);
			}
			| E '=' '=' E
			{
				$$.traducao = $1.traducao + $4.traducao + conversaoImplicita($1, $4, "==", &$$);
			}
			| E '!' '=' E
			{
				$$.traducao = $1.traducao + $4.traducao + conversaoImplicita($1, $4, "!=", &$$);
			}
			| E '&' '&' E
			{
				$$.traducao = $1.traducao + $4.traducao + conversaoImplicita($1, $4, "&&", &$$);
			}
			| E '|' '|' E
			{
				$$.traducao = $1.traducao + $4.traducao + conversaoImplicita($1, $4, "||", &$$);
			}
			| E '%' '%' E
			{
				string tempNome = gerarNome();
				string tempNome2 = gerarNome();
				$$.traducao = $1.traducao + $4.traducao + "\t" + tempNome + " = " + $1.label + " * " + $4.label + ";\n" + "\t" + tempNome2 + " = " + tempNome + " / 100;\n";
				$$.label = tempNome2;
			}
			| T
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
			| '-' F
			{
				$$ = $2;
				$$.label = gerarNome();
				$$.traducao = $2.traducao + "\t" + $2.tipo + " " + $$.label + " = -" + $2.label + ";\n";
				
			}
			| '+' F
			{
				$$ = $2;
				$$.label = gerarNome();
				$$.traducao = "\t" + $2.tipo + " " + $$.label + " = " + $2.label + ";\n";
			}
			;



F   		: TK_NUM
			{
				$$ = $1;
			}
			| TK_ID
			{
				$$ = $1;
			}
			| TK_CHAR
			{
				$$ = $1;
			}
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
