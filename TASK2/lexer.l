%{
#include "y.tab.h"
%}

%%

[ \t\n]+                ; // Ignore whitespace

"//".*                  ; // Ignore comments

":=" {
    return ASSIGN;
}

"(" {
    return OPEN_BRACE;
}

")" {
    return CLOSED_BRACE;
}

"+"|"-"|"*"|"/"|"%" {
    return ARITHMETIC_OPERATOR;
}

"="|"<"|">"|"<="|">="|"<>" {
    return RELATIONAL_OPERATOR;
}

"not" {
    return UNARY_BOOL_OPERATOR
}

"and"|"or" {
    return BINARY_BOOL_OPERATOR;
}

"program" {
    return PROGRAM;
}

"integer"|"real"|"boolean"|"char" {
    return DATA_TYPE;
}

"var" {
    return VAR;
}

"to" {
    return TO;
}

"downto" {
    return DOWNTO
}

"if" {
    return IF;
}

"then" {
    return THEN;
}

"else" {
    return ELSE;
}

"while" {
    return WHILE;
}

"for" {
    return FOR;
}

"do" {
    return DO;
}

"array" {
    return ARRAY;
}

"begin" {
    return BEGIN;
}

"end" {
    return END;
}

"read" {
    return READ;
}

"write" {
    return WRITE;
}

[0-9]+ { 
    return INTEGER_CONST; 
}

[0-9]+"."[0-9]+ { 
    return REAL_CONST; 
}

[a-zA-Z][a-zA-Z0-9_]*   {
    yylval.str = strdup(yytext);
    return IDENTIFIER;
}

"."|";"|","|":"|"("|")" {
    return PUNCTUATOR;
}

\"([^\"\n]|\\.)*\" { 
    yylval.str = strdup(yytext);
    return STRING_CONSTANT; 
}

%%

int yywrap() { 
    return 1;
}
