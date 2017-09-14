%{
#include <iostream>
#include <string>
#include <sstream>

#define YYSTYPE atributos

using namespace std;

struct atributos
{
	string label;
	string traducao;
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
%}

%token TK_NUM
%token TK_MAIN TK_ID TK_TIPO_INT
%token TK_FIM TK_ERROR

%start S

%left '+'

%%

S 			: TK_TIPO_INT TK_MAIN '(' ')' BLOCO
			{
				cout << "/*Compilador FOCA*/\n" << "#include <iostream>\n#include<string.h>\n#include<stdio.h>\nint main(void)\n{\n" << $5.traducao << "\treturn 0;\n}" << endl; 
			}
			;

BLOCO		: '{' COMANDOS '}'
			{
				$$.traducao = $2.traducao;
			}
			;

COMANDOS	: COMANDO COMANDOS
			|
			;

COMANDO 	: E ';'
			;

E 			: E '+' E
			{
				string tempNome = gerarNome();
				$$.label = tempNome;
				$$.traducao = $1.traducao + $3.traducao + "\t" + tempNome + " = " + $1.label + " + " + $3.label + ";\n";
			}
			| TK_NUM
			{
				string tempNome = gerarNome();
				$$.label = tempNome;
				$$.traducao = "\t" + tempNome + " = " + $1.label + ";\n";
			}
			| TK_ID
			{

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

/*

flex lexica.l
bison -d sintatica.y
g++ -o glf sintatica.tab.c

*/
