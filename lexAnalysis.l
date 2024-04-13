%{
#include "y.tab.h"
%}

%%

[ \t\n]+                ; // Ignore whitespace

"//".*                  ; // Ignore comments

[Pp][Rr][Oo][Gg][Rr][Aa][Mm]|[Ii][Nn][Tt][Ee][Gg][Ee][Rr]|[Rr][Ee][Aa][Ll]|[Bb][Oo][Oo][Ll][Ee][Aa][Nn]|[Cc][Hh][Aa][Rr]|[Vv][Aa][Rr]|[Tt][Oo]|[Dd][Oo][Ww][Nn][Tt][Oo]|[Ii][Ff]|[Ee][Ll][Ss][Ee]|[Ww][Hh][Ii][Ll][Ee]|[Ff][Oo][Rr]|[Dd][Oo]|[Aa][Rr][Rr][Aa][Yy]|[Aa][Nn][Dd]|[Oo][Rr]|[Nn][Oo][Tt]|[Bb][Ee][Gg][Ii][Nn]|[Ee][Nn][Dd]|[Rr][Ee][Aa][Dd]|[Ww][Rr][Ii][Tt][Ee] {
    return KEYWORD;
}

[0-9]+                  { return INTEGER_CONST; }
[0-9]+"."[0-9]+         { return REAL_CONST; }

"="|"+"|"-"|"*"|"/"|"%"|"<"|">"|"<="|">="|"<>"|"and"|"or"|"not" {
    return OPERATOR;
}

[a-zA-Z][a-zA-Z0-9_]*   {
    yylval.str = strdup(yytext);
    return IDENTIFIER;
}

"."|";"|","|":"|"("|")" {
    return PUNCTUATOR;
}

%%

int yywrap() { 
    return 1;
}
