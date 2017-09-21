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
ID {LETRA}({LETRA}|{NUM})*


%%

"\n"		{}

{DELIM} 	{}

"main"		{return TK_MAIN;}

"int"		{return TK_TIPO_INT;}

"true"|"false"		{yylval.label = yytext; yylval.tipo = "BOOLEAN"; return TK_ID;}

[(){}[\];,]	{ return *yytext; }

[+\-*/]		{ return *yytext; }

[&|]	{return *yytext; }

[<>!=]	{return *yytext; }

{NUM}		{ yylval.label = yytext; yylval.tipo = "INTEIRO"; return TK_NUM; }
{ID}		{ yylval.label = yytext; return TK_ID; }
{REAL}		{ yylval.label = yytext; yylval.tipo = "FLOAT"; return TK_NUM; }
{CHAR}      { yylval.label = yytext; yylval.tipo = "CHAR"; return TK_NUM; }

.			{ *yytext; }

%%

int yywrap(void){
    return 1;
}