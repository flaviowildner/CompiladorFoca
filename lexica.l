%{
#include <string>

%}

ESPACO [ \t]
DIGITO [0-9]
LETRA [A-Za-z_]
BOOL [true|false]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}+("."{NUM}+)?
CHAR \'({LETRA}|{NUM})\'
STRING \"({LETRA}|{NUM})+\"
ID {LETRA}({LETRA}|{NUM})*



%%

"\n"		{}

{DELIM} 	{}

"(float)"|"(int)"   {yylval.label = yytext; return TK_CAST;}

"main"		{return TK_MAIN;}

"int"		{return TK_TIPO_INT;}

"if"    {return TK_IF;}

"else"  {return TK_ELSE;}

"while" {return TK_WHILE;}

"true"|"false"		{yylval.label = yytext; yylval.tipo = "bool"; return TK_BOOL;}

"print" {yylval.label = yytext; return TK_PRINT; }

"+"|"-"|"*"|"/"  {yylval.traducao = yytext; return TK_ARITMETICO;}

"<"|">"|"<="|">="|"!="|"=="|"||"|"&&" {yylval.traducao = yytext; return TK_LR;}

[(){}[\];,]	{ return *yytext; }

[&|%]	{return *yytext; }

[<>!=]	{return *yytext; }

{NUM}		{ yylval.label = yytext; yylval.tipo = "int"; return TK_NUM; }
{ID}		{ yylval.label = yytext; yylval.nomeVariavel = yytext; yylval.tipo = "id"; return TK_ID; }
{REAL}		{ yylval.label = yytext; yylval.tipo = "float"; return TK_NUM; }
{CHAR}      { yylval.label = yytext; yylval.tipo = "char"; return TK_CHAR; }
{STRING}	{ yylval.label =  yytext; yylval.tipo = "char*"; return TK_STRING;}
.			{ *yytext; }

%%

int yywrap(void){
    return 1;
}