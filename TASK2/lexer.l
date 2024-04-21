%{
#include <stdio.h>
#include "y.tab.h"
%}

%x START_QUOTE 
%x ANY_STRING

%%

[ \t\n]+                ; // Ignore whitespace

"//".*                  ; // Ignore comments

":=" {
    return ASSIGN;
}

"+" {
    return ADD;
}

"-" {
    return SUBTRACT;
}

"*" {
    return MULTIPLY;
}

"/" {
    return DIVIDE;
}

"%" {
    return MODULO;
}

"="|"<"|">"|"<="|">="|"<>" {
    return RELATIONAL_OPERATOR;
}

"not" {
    return UNARY_BOOL_OPERATOR;
}

"and"|"or" {
    return BINARY_BOOL_OPERATOR;
}

"program" {
    printf("Program\n");
    return PROGRAM;
}

"integer"|"real"|"boolean"|"char" {
    printf("data_type\n");
    return DATA_TYPE;
}

"var" {
    printf("Var\n");
    return VAR;
}

"to" {
    printf("To\n");
    return TO;
}

"downto" {
    printf("Down to\n");
    return DOWNTO;
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
    printf("Begin\n");
    return TOKEN_BEGIN;
}

"end" {
    printf("End\n");
    return END;
}

"read" {
    printf("Read\n");
    return READ;
}

"write" {
    printf("Write\n");
    return WRITE;
}

[0-9]+ { 
    return INTEGER_CONST; 
}

[0-9]+"."[0-9]+ { 
    return REAL_CONST; 
}

[a-zA-Z][a-zA-Z0-9_]*   {
    printf("Identifier\n");
    return IDENTIFIER;
}

"." {
    return FULLSTOP;
}

";" {
    return SEMICOLON;
}

"," {
    return COMMA;
}

":" {
    return COLON;
}

"(" {
    printf("Open Bracket\n");
    return OPEN_BRACE;
}

")" {
    return CLOSED_BRACE;
}

\" { // Check this 
    // yylval.str = strdup(yytext);
    BEGIN START_QUOTE;
}

<START_QUOTE>[^\"]* {
    BEGIN ANY_STRING;
}

<ANY_STRING>\" {
    BEGIN INITIAL;
    return STRING_CONSTANT; 
}

%%

int yywrap() { 
    return 1;
}
