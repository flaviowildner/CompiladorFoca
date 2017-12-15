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
STRING \"([^\"\n]|\\\")*\"
ID {LETRA}({LETRA}|{NUM})*



%%

"\n"   { lines++; }

{DELIM} 	{}

"(float)"|"(int)"   {yylval.label = yytext; return TK_CAST;}

"int"|"float"|"char"|"string"    {yylval.label = yytext; tipo_declaracao = yylval.label; return TK_TIPO;}

"if"    {return TK_IF;}

"else"  {return TK_ELSE;}

"while" {return TK_WHILE;}

"for"   {return TK_FOR;}

"do"    {return TK_DO;}

"switch"    {return TK_SWITCH;}

"case"    {return TK_CASE;}

"default" {return TK_DEFAULT;}

"break" {return TK_BREAK;}

"continue"  {return TK_CONTINUE;}

"true"|"false"		{ if(strcmp(yytext, "false")) yylval.label = "1"; else yylval.label = "0"; yylval.tipo = "bool"; return TK_BOOL;}

"print" {yylval.label = yytext; return TK_PRINT;}

"scan"  {yylval.label = yytext; return TK_SCAN;}

"+"|"-"|"*"|"/"  {yylval.traducao = yytext; return TK_ARITMETICO;}

"++"|"--"   {yylval.traducao = yytext; return TK_INCREMENTO;}

"+="|"-="|"*="|"/=" {yylval.traducao = yytext; return TK_INCREM_ATRIB_ABREV;}

"<"|">"|"<="|">="|"!="|"==" {yylval.traducao = yytext; return TK_OPR;}

"||"|"&&"|"!"  {yylval.traducao = yytext; return TK_OPL;}

"/*" {return TK_INIT_COMMENT;}

"*/" {return TK_END_COMMENT;}

"**"	{return TK_EXP;}

"%%"	{return TK_PORCENTAGEM;}

[(){}[\];,:]	{ return *yytext; }

[&|%]	{return *yytext; }

[<>!=]	{return *yytext; }

{NUM}		{ yylval.label = yytext; yylval.tipo = "int"; return TK_NUM; }
{ID}		{ yylval.label = yytext; yylval.nomeVariavel = yytext; yylval.tipo = "id"; return TK_ID; }
{REAL}		{ yylval.label = yytext; yylval.tipo = "float"; return TK_NUM; }
{CHAR}      { yylval.label = yytext; yylval.tipo = "char"; return TK_CHAR; }
{STRING}	{ yylval.label = yytext; yylval.tipo = "string"; return TK_STRING; }
.			{ *yytext; }

%%

int yywrap(void){
    return 1;
}