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

program { // Match any characters (including newlines) before "program"
    fprintf(yyout, "%d %s KEYWORD\n", lineNo, yytext);
    BEGIN(INPROGRAM);
}

<INPROGRAM>\n { 
    lineNo++;
}

<INPROGRAM,DATA_TYPE_SEARCH,INARRAY,READINGC1,READDOTS,READCLOSE,READINGC2>[ \t]+                ; // Ignore whitespace

<INPROGRAM>"//".*                  ; // Ignore comments

<INPROGRAM>\".*\" {
    fprintf(yyout, "%d %s STRING_CONSTANT\n", lineNo, yytext);
}

<INPROGRAM>":=" {
    fprintf(yyout, "%d %s ASSIGN\n", lineNo, yytext);
}

<INPROGRAM>"(" {
    fprintf(yyout, "%d %s OPEN_BRACE\n", lineNo, yytext);
}

<INPROGRAM>")" {
    fprintf(yyout, "%d %s CLOSE_BRACE\n", lineNo, yytext);
}

<INPROGRAM>"+"|"-"|"*"|"/"|"%" {
    fprintf(yyout, "%d %s ARITHMETIC_OPERATOR\n", lineNo, yytext);
}

<INPROGRAM>"="|"<"|">"|"<="|">="|"<>" {
    fprintf(yyout, "%d %s RELATIONAL_OPERATOR\n", lineNo, yytext);
}

<INPROGRAM>"not" {
    fprintf(yyout, "%d %s UNARY_BOOL_OPERATOR\n", lineNo, yytext);
}

<INPROGRAM>"and"|"or" {
    fprintf(yyout, "%d %s BINARY_BOOL_OPERATOR\n", lineNo, yytext);
}

<INPROGRAM,DATA_TYPE_SEARCH>[Ii][Nn][Tt][Ee][Gg][Ee][Rr]|[Rr][Ee][Aa][Ll]|[Bb][Oo][Oo][Ll][Ee][Aa][Nn]|[Cc][Hh][Aa][Rr] {
    fprintf(yyout, "%d %s DATA_TYPE\n", lineNo, yytext);
    BEGIN INPROGRAM;
}

<INPROGRAM>"var" {
    fprintf(yyout, "%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>"to" {
    fprintf(yyout, "%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>"downto" {
    fprintf(yyout, "%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>"if" {
    fprintf(yyout, "%d %s CONDITIONAL\n", lineNo, yytext);
}

<INPROGRAM>"then" {
    fprintf(yyout, "%d %s CONDITIONAL\n", lineNo, yytext);
}

<INPROGRAM>"else" {
    fprintf(yyout, "%d %s CONDITIONAL\n", lineNo, yytext);
}

<INPROGRAM>"while" {
    fprintf(yyout, "%d %s LOOP\n", lineNo, yytext);
}

<INPROGRAM>"for" {
    fprintf(yyout, "%d %s LOOP\n", lineNo, yytext);
}

<INPROGRAM>"do" {
    fprintf(yyout, "%d %s LOOP\n", lineNo, yytext);
}

<DATA_TYPE_SEARCH>"array" {
    fprintf(yyout, "%d %s KEYWORD\n", lineNo, yytext);
    BEGIN INARRAY;
}

<INARRAY>"[" {
    BEGIN READINGC1;
}

<READINGC1>[0-9]+ {
    fprintf(yyout, "%d %s INTEGER_CONSTANT\n", lineNo, yytext);
    BEGIN READDOTS;
}

<READDOTS>\.\. {
    // fprintf(yyout, "%d %s INTEGER_CONSTANT\n", lineNo, yytext);
    BEGIN READINGC2;
}

<READINGC2>[0-9]+ {
    fprintf(yyout, "%d %s INTEGER_CONSTANT\n", lineNo, yytext);
    BEGIN READCLOSE;
}

<READCLOSE>"]" {
    // fprintf(yyout, "%d %s INTEGER_CONSTANT\n", lineNo, yytext);
    BEGIN INPROGRAM;
}

<INPROGRAM>[a-zA-Z][a-zA-Z0-9_]*"[".*"]" {
    fprintf(yyout, "%d %s IDENTIFIER\n", lineNo, yytext);
}

<INPROGRAM>"of" {
    fprintf(yyout, "%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>"begin" {
    fprintf(yyout, "%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>"end" {
    fprintf(yyout, "%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>"read" {
    fprintf(yyout, "%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>"write" {
    fprintf(yyout, "%d %s KEYWORD\n", lineNo, yytext);
}

<INPROGRAM>[0-9]+ { 
    fprintf(yyout, "%d %s INTEGER\n", lineNo, yytext);
}

<INPROGRAM>[0-9]+"."[0-9]+ { 
    fprintf(yyout, "%d %s REAL_CONSTANT\n", lineNo, yytext);
}

<INPROGRAM>[a-zA-Z][a-zA-Z0-9_]*   {
    fprintf(yyout, "%d %s IDENTIFIER\n", lineNo, yytext);
}

<INPROGRAM>"."|";"|","|"("|")" {
    fprintf(yyout, "%d %s PUNCTUATOR\n", lineNo, yytext);
}

<INPROGRAM>":" {
    fprintf(yyout, "%d %s PUNCTUATOR\n", lineNo, yytext);
    BEGIN DATA_TYPE_SEARCH;
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
