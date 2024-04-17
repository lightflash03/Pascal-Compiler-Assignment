%{
// #include "y.tab.h"
#include <stdio.h>
#include <stdlib.h>
%}

%%
[\s\S]*program { // Match any characters (including newlines) before "program"
    fprintf(yyout, "%d PROGRAM KEYWORD\n", yylineno);
}

\n { 
    yylineno++;
}

[ \t]+                ; // Ignore whitespace

"//".*                  ; // Ignore comments

":=" {
    fprintf(yyout, "%d %s ASSIGN\n", yylineno, yytext);
}

"(" {
    fprintf(yyout, "%d %s OPEN_BRACE\n", yylineno, yytext);
}

")" {
    fprintf(yyout, "%d %s CLOSE_BRACE\n", yylineno, yytext);
}

"+"|"-"|"*"|"/"|"%" {
    fprintf(yyout, "%d %s ARITHMETIC_OPERATOR\n", yylineno, yytext);
}

"="|"<"|">"|"<="|">="|"<>" {
    fprintf(yyout, "%d %s RELATIONAL_OPERATOR\n", yylineno, yytext);
}

"not" {
    fprintf(yyout, "%d %s UNARY_BOOL_OPERATOR\n", yylineno, yytext);
}

"and"|"or" {
    fprintf(yyout, "%d %s BINARY_BOOL_OPERATOR\n", yylineno, yytext);
}

[Ii][Nn][Tt][Ee][Gg][Ee][Rr]|[Rr][Ee][Aa][Ll]|[Bb][Oo][Oo][Ll][Ee][Aa][Nn]|[Cc][Hh][Aa][Rr] {
    fprintf(yyout, "%d %s DATA_TYPE\n", yylineno, yytext);
}

"var" {
    fprintf(yyout, "%d %s KEYWORD\n", yylineno, yytext);
}

"to" {
    fprintf(yyout, "%d %s KEYWORD\n", yylineno, yytext);
}

"downto" {
    fprintf(yyout, "DOWNTO\n");
}

"if" {
    fprintf(yyout, "%d %s CONDITIONAL\n", yylineno, yytext);
}

"then" {
    fprintf(yyout, "%d %s CONDITIONAL\n", yylineno, yytext);
}

"else" {
    fprintf(yyout, "%d %s CONDITIONAL\n", yylineno, yytext);
}

"while" {
    fprintf(yyout, "%d %s LOOP\n", yylineno, yytext);
}

"for" {
    fprintf(yyout, "%d %s LOOP\n", yylineno, yytext);
}

"do" {
    fprintf(yyout, "%d %s LOOP\n", yylineno, yytext);
}

"array" {
    // fprintf(yyout, "ARRAY\n");
}

"begin" {
    // fprintf(yyout, "BEGIN\n");
}

"end" {
    // fprintf(yyout, "END\n");
}

"read" {
    // fprintf(yyout, "READ\n");
}

"write" {
    // fprintf(yyout, "WRITE\n");
}

[0-9]+ { 
    // fprintf(yyout, "INTEGER_CONST\n");
}

[0-9]+"."[0-9]+ { 
    // fprintf(yyout, "REAL_CONST\n");
}

[a-zA-Z][a-zA-Z0-9_]*   {
    // fprintf(yyout, "IDENTIFIER\n");
}

"."|";"|","|":"|"("|")" {
    // fprintf(yyout, "PUNCTUATOR\n");
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
    yyout = fopen("output.txt", "w");
    yylex();
}
