%{
// #include "y.tab.h"
#include <stdio.h>
#include <stdlib.h>
int lineNo=1;
%}

%s INPROGRAM
%s INARRAY
%s READINGC1
%s READDOTS
%s READCLOSE
%s READINGC2
%s DATA_TYPE_SEARCH

%%

[Pp][Rr][Oo][Gg][Rr][Aa][Mm] { // Match any characters (including newlines) before "program"
    printf("%d %s KEYWORD\n", lineNo, yytext);
    BEGIN(INPROGRAM);
}

<INPROGRAM>\n { 
    lineNo++;
}

<INPROGRAM,DATA_TYPE_SEARCH,INARRAY,READINGC1,READDOTS,READCLOSE,READINGC2>[ \t]+                ; // Ignore whitespace

<INPROGRAM>"//".*                  ; // Ignore comments

<INPROGRAM>\".*\" {
    printf("%d %s STRING_CONSTANT\n", lineNo, yytext);
}

<INPROGRAM>":=" {
    printf("%d %s ASSIGN\n", lineNo, yytext);
}

<INPROGRAM>"(" {
    printf("%d %s OPEN_BRACE\n", lineNo, yytext);
}

<INPROGRAM>")" {
    printf("%d %s CLOSE_BRACE\n", lineNo, yytext);
}

<INPROGRAM>"+"|"-"|"*"|"/"|"%" {
    printf("%d %s ARITHMETIC_OPERATOR\n", lineNo, yytext);
}

<INPROGRAM>"="|"<"|">"|"<="|">="|"<>" {
    printf("%d %s RELATIONAL_OPERATOR\n", lineNo, yytext);
}

<INPROGRAM>[Nn][Oo][Tt] {
    printf("%d %s UNARY_BOOL_OPERATOR\n", lineNo, yytext);
}

<INPROGRAM>[Aa][Nn][Dd]|[Oo][Rr] {
    printf("%d %s BINARY_BOOL_OPERATOR\n", lineNo, yytext);
}

<INPROGRAM,DATA_TYPE_SEARCH>[Ii][Nn][Tt][Ee][Gg][Ee][Rr]|[Rr][Ee][Aa][Ll]|[Bb][Oo][Oo][Ll][Ee][Aa][Nn]|[Cc][Hh][Aa][Rr] {
    printf("%d %s DATA_TYPE\n", lineNo, yytext);
    BEGIN INPROGRAM;
}

<INPROGRAM>[Vv][Aa][Rr] {
    printf("%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>[Tt][Oo] {
    printf("%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>[Dd][Oo][Ww][Nn][Tt][Oo] {
    printf("%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>[Ii][Ff] {
    printf("%d %s CONDITIONAL\n", lineNo, yytext);
}

<INPROGRAM>[Tt][Hh][Ee][Nn] {
    printf("%d %s CONDITIONAL\n", lineNo, yytext);
}

<INPROGRAM>[Ee][Ll][Ss][Ee] {
    printf("%d %s CONDITIONAL\n", lineNo, yytext);
}

<INPROGRAM>[Ww][Hh][Ii][Ll][Ee] {
    printf("%d %s LOOP\n", lineNo, yytext);
}

<INPROGRAM>[Ff][Oo][Rr] {
    printf("%d %s LOOP\n", lineNo, yytext);
}

<INPROGRAM>[Dd][Oo] {
    printf("%d %s LOOP\n", lineNo, yytext);
}

<DATA_TYPE_SEARCH>[Aa][Rr][Rr][Aa][Yy] {
    printf("%d %s KEYWORD\n", lineNo, yytext);
    BEGIN INARRAY;
}

<INARRAY>"[" {
    BEGIN READINGC1;
}

<READINGC1>[0-9]+ {
    printf("%d %s INTEGER_CONSTANT\n", lineNo, yytext);
    BEGIN READDOTS;
}

<READDOTS>\.\. {
    // printf("%d %s INTEGER_CONSTANT\n", lineNo, yytext);
    BEGIN READINGC2;
}

<READINGC2>[0-9]+ {
    printf("%d %s INTEGER_CONSTANT\n", lineNo, yytext);
    BEGIN READCLOSE;
}

<READCLOSE>"]" {
    // printf("%d %s INTEGER_CONSTANT\n", lineNo, yytext);
    BEGIN INPROGRAM;
}

<INPROGRAM>[a-zA-Z][a-zA-Z0-9_]*"[".*"]" {
    printf("%d %s IDENTIFIER\n", lineNo, yytext);
}

<INPROGRAM>[Oo][Ff] {
    printf("%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>[Bb][Ee][Gg][Ii][Nn] {
    printf("%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>[Ee][Nn][Dd] {
    printf("%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>[Rr][Ee][Aa][Dd] {
    printf("%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>[Ww][Rr][Ii][Tt][Ee] {
    printf("%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>[0-9]+ { 
    printf("%d %s INTEGER\n", lineNo, yytext);
}

<INPROGRAM>[0-9]+"."[0-9]+ { 
    printf("%d %s REAL_CONSTANT\n", lineNo, yytext);
}

<INPROGRAM>[a-zA-Z][a-zA-Z0-9_]*   {
    printf("%d %s IDENTIFIER\n", lineNo, yytext);
}

<INPROGRAM>"."|";"|","|"("|")" {
    printf("%d %s PUNCTUATOR\n", lineNo, yytext);
}

<INPROGRAM>":" {
    printf("%d %s PUNCTUATOR\n", lineNo, yytext);
    BEGIN DATA_TYPE_SEARCH;
}

%%

int yywrap() { 
    return 1;
}

int main(int args, char* argv[])
{
    yyin = fopen(argv[1], "r");
    yylex();
}
