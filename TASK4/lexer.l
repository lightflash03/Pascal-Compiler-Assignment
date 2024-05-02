%{
#include "y.tab.h"
%}

%%

[0-9]+ {yylval.ival= atoi(yytext); return NUM;}
"+" return PL;
"*" return ML;
"-" return ST;
"/" return DIV;
\n return NL;

%%