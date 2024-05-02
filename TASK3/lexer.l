%{
#include <stdio.h>
#include <stdbool.h>
#include "y.tab.h"

int start_array = 0, end_array = 0;
%}

%x START_QUOTE 
%x ANY_STRING
%x ARRAY_BRACKET_OPEN
%x FIRST_NUMBER
%x ELIPSIS
%x SECOND_NUMBER
%x ARRAY_BRACKET_CLOSE
%x AFTER_BRACKET_CLOSE
%x ARRAY_TYPE

%%

[ \t\n]+ {

}

"//".* {

}

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

"[" {
    return SQUARE_OPEN;
}

"]" {
    return SQUARE_CLOSE;
}

"="|"<"|">"|"<="|">="|"<>" {
    switch (yytext[0]) {
        case '=':
            strcpy(yylval.attr.sval,"EQUALS");
            break;
        case '<':
            if (yytext[1] == '=') {
                strcpy(yylval.attr.sval,"LESS-THAN-OR-EQUAL-TO");
            } else if (yytext[1] == '>') {
                strcpy(yylval.attr.sval,"NOT-EQUALS");
            } else {
                strcpy(yylval.attr.sval,"LESS-THAN");
            }
            break;
        case '>':
            if (yytext[1] == '=') {
                strcpy(yylval.attr.sval,"GREATER-THAN-OR-EQUAL-TO");
            } else {
                strcpy(yylval.attr.sval,"GREATER-THAN");
            }
            break;
    }
    return RELATIONAL_OPERATOR;
}

"not" {
    return UNARY_BOOL_OPERATOR;
}

"and"|"or" {
    if (strcmp(strdup(yytext), "and") == 0) {
        strcpy(yylval.attr.sval, "AND");
    } else if (strcmp(strdup(yytext), "or") == 0) {
        strcpy(yylval.attr.sval, "OR");
    }
    return BINARY_BOOL_OPERATOR;
}

"program" {
    return PROGRAM;
}

"integer"|"real"|"boolean"|"char" {
    if (strcmp(strdup(yytext), "integer") == 0) {
        yylval.attr.datatype = 1;
    } else if (strcmp(strdup(yytext), "real") == 0) {
        yylval.attr.datatype = 2;
    } else if (strcmp(strdup(yytext), "boolean") == 0) {
        yylval.attr.datatype = 3;
    } else if (strcmp(strdup(yytext), "char") == 0) {
        yylval.attr.datatype = 4;
    }
    return DATA_TYPE;
}

"array" {
    BEGIN ARRAY_BRACKET_OPEN;
}

<ARRAY_BRACKET_OPEN>"[" {
    BEGIN FIRST_NUMBER;
}

<FIRST_NUMBER>[0-9]+ {
    BEGIN ELIPSIS;
    start_array = atoi(yytext);
    // return FIRST_NUMBER;
}

<ELIPSIS>".." {
    BEGIN SECOND_NUMBER;
}

<SECOND_NUMBER>[0-9]+ {
    BEGIN ARRAY_BRACKET_CLOSE;
    end_array = atoi(yytext);
    // return SECOND_NUMBER;
}

<ARRAY_BRACKET_CLOSE>"]" {
    BEGIN AFTER_BRACKET_CLOSE;
}

<AFTER_BRACKET_CLOSE>[" "]+"of"[" "]+ {
    BEGIN ARRAY_TYPE;
}

<ARRAY_TYPE>"integer"|"real"|"boolean"|"char" {
    BEGIN INITIAL;
    if (strcmp(strdup(yytext), "integer") == 0) {
        yylval.arr_attr.datatype = 1;
    } else if (strcmp(strdup(yytext), "real") == 0) {
        yylval.arr_attr.datatype = 2;
    } else if (strcmp(strdup(yytext), "boolean") == 0) {
        yylval.arr_attr.datatype = 3;
    } else if (strcmp(strdup(yytext), "char") == 0) {
        yylval.arr_attr.datatype = 4;
    }
    yylval.arr_attr.first_ival = start_array;
    yylval.arr_attr.second_ival = end_array;
    return ARRAY_DATA_TYPE;
}

"var" {
    return VAR;
}

"to" {
    strcpy(yylval.attr.sval,"TO");
    return TO;
}

"downto" {
    strcpy(yylval.attr.sval,"DOWNTO");
    return TO;
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

"begin" {
    return TOKEN_BEGIN;
}

"end" {
    return END;
}

"read" {
    return READ;
}

"write"("ln")? {
    return WRITE;
}

[0-9]+ {
    yylval.attr.ival = atoi(yytext);
    return INTEGER_CONST;
}

[0-9]+"."[0-9]+ {
    yylval.attr.dval = atof(yytext);
    return REAL_CONST; 
}

[a-zA-Z][a-zA-Z0-9_]*   {
    strcpy(yylval.attr.sval,strdup(yytext));
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
    return OPEN_BRACE;
}

")" {
    return CLOSED_BRACE;
}

\" {
    BEGIN START_QUOTE;
}

<START_QUOTE>[^\"]* {
    BEGIN ANY_STRING;
}

<ANY_STRING>\" {
    BEGIN INITIAL;
    return STRING_CONSTANT; 
}

\'.\' {
    yylval.attr.cval = yytext[1];
    return CHARACTER_CONSTANT;
}

%%

int yywrap() { 
    return 1;
}
