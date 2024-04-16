%{
// #include "y.tab.h"
#include <stdio.h>
#include <stdlib.h>
%}

%%

\n {yylineno++;}

[ \t\n]+                ; // Ignore whitespace

"//".*                  ; // Ignore comments

":=" {
    printf("%d %s ASSIGN\n", yylineno, yytext);
}

"(" {
    printf("%d %s OPEN_BRACE\n", yylineno, yytext);
}

")" {
    printf("%d %s CLOSE_BRACE\n", yylineno, yytext);
}

"+"|"-"|"*"|"/"|"%" {
    printf("%d %s ARITHMETIC_OPERATOR\n", yylineno, yytext);
}

"="|"<"|">"|"<="|">="|"<>" {
    printf("%d %s RELATIONAL_OPERATOR\n", yylineno, yytext);
}

"not" {
    printf("%d %s UNARY_BOOL_OPERATOR\n", yylineno, yytext);
}

"and"|"or" {
    printf("%d %s BINARY_BOOL_OPERATOR\n", yylineno, yytext);
}

"program" {
    printf("%d %s KEYWORD\n", yylineno, yytext);
}

"integer"|"real"|"boolean"|"char" {
    printf("%d %s DATA_TYPE\n", yylineno, yytext);
}

"var" {
    printf("%d %s KEYWORD\n", yylineno, yytext);
}

"to" {
    printf("%d %s KEYWORD\n", yylineno, yytext);
}

"downto" {
    printf("DOWNTO\n");
}

"if" {
    printf("%d %s CONDITIONAL\n", yylineno, yytext);
}

"then" {
    printf("%d %s CONDITIONAL\n", yylineno, yytext);
}

"else" {
    printf("%d %s CONDITIONAL\n", yylineno, yytext);
}

"while" {
    printf("%d %s LOOP\n", yylineno, yytext);
}

"for" {
    printf("%d %s LOOP\n", yylineno, yytext);
}

"do" {
    printf("%d %s LOOP\n", yylineno, yytext);
}

"array" {
    // printf("ARRAY\n");
}

"begin" {
    // printf("BEGIN\n");
}

"end" {
    // printf("END\n");
}

"read" {
    // printf("READ\n");
}

"write" {
    // printf("WRITE\n");
}

[0-9]+ { 
    // printf("INTEGER_CONST\n");
}

[0-9]+"."[0-9]+ { 
    // printf("REAL_CONST\n");
}

[a-zA-Z][a-zA-Z0-9_]*   {
    // printf("IDENTIFIER\n");
}

"."|";"|","|":"|"("|")" {
    // printf("PUNCTUATOR\n");
}

\"([^\"\n]|\\.)*\" { 
}

%%

int yywrap() { 
    return 1;
}

int main()
{
    yyin = fopen("../program.txt", "r");
    // yyout = fopen("output.txt", "w");
    yylex();
}
