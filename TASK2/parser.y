%{
#include <stdio.h>
#include <string.h>
#include <ctype.h>

FILE *fptRead = NULL, *fptWrite = NULL;
extern FILE *yyin;
extern FILE *yyout;
%}

%token ASSIGN OPEN_BRACE CLOSED_BRACE ARITHMETIC_OPERATOR RELATIONAL_OPERATOR UNARY_BOOL_OPERATOR BINARY_BOOL_OPERATOR PROGRAM DATA_TYPE VAR TO DOWNTO IF THEN ELSE WHILE FOR DO ARRAY TOKEN_BEGIN END READ WRITE INTEGER_CONST STRING_CONSTANT REAL_CONST IDENTIFIER PUNCTUATOR

%left BINARY_BOOL_OPERATOR
%left RELATIONAL_OPERATOR
%left '+' '-'
%left '*' '/' '%'
%right UNARY_BOOL_OPERATOR

%start program

%%

program
    : PROGRAM IDENTIFIER ';' declarations TOKEN_BEGIN statements END '.'
    ;

declarations
    : VAR declaration_list 
    ;

declaration_list
    : multiple_lines
    ;

// Doesn't support the case of no declarations
multiple_lines
    : multiple_identifiers ':' DATA_TYPE ';' multiple_lines
    | multiple_identifiers ':' DATA_TYPE ';'
    ;

multiple_identifiers
    : IDENTIFIER ',' multiple_identifiers
    | IDENTIFIER
    ;

// multiple_identifiers
//     : IDENTIFIER
//     | multiple_identifiers ',' IDENTIFIER
//     ;

statements
    : /* empty */
    | statement ';' statements
    ;

statement
    : assignment
    | conditional
    | loop
    | READ '(' IDENTIFIER ')'
    | WRITE '(' output ')'
    ;

assignment
    : IDENTIFIER ASSIGN expression
    ;

conditional
    : IF expression THEN statements
    | IF expression THEN statements ELSE statements
    ;

loop
    : WHILE expression DO statements
    | FOR IDENTIFIER ASSIGN expression TO expression DO statement
    ;

// expression
//     : arithmetic_addition
//     | arithmetic_multiplication
//     | expression RELATIONAL_OPERATOR expression
//     | '!' expression
//     | expression BINARY_BOOL_OPERATOR expression
//     | '(' expression ')'
//     | IDENTIFIER
//     | INTEGER_CONST
//     | REAL_CONST
//     ;

// arithmetic_addition
//     : expression '+' expression
// 	| expression '-' expression
//     ;

// arithmetic_multiplication
//     : expression '*' expression 
// 	| expression '/' expression 
// 	| expression '%' expression 
//     ;

expression: arithmetic_expression
          | relational_expression
          | boolean_expression
          | '(' expression ')'
          ;

arithmetic_expression: arithmetic_expression '+' arithmetic_expression
                     | arithmetic_expression '-' arithmetic_expression
                     | arithmetic_expression '*' arithmetic_expression
                     | arithmetic_expression '/' arithmetic_expression
                     | arithmetic_expression '%' arithmetic_expression
                     | primary_expression;

relational_expression: arithmetic_expression RELATIONAL_OPERATOR arithmetic_expression;

boolean_expression: arithmetic_expression BINARY_BOOL_OPERATOR arithmetic_expression
                  | UNARY_BOOL_OPERATOR expression
                  ;

primary_expression: IDENTIFIER
                  | INTEGER_CONST
                  | REAL_CONST;

output
    : output_list
    | STRING_CONSTANT
    ;

output_list
    : expression
    | output_list ',' expression
    ;


%%

void yyerror(char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

void toLower(FILE* fptRead, FILE* fptWrite) {
    char ch;
    while ((ch = fgetc(fptRead)) != EOF) {    
        fputc(tolower(ch), fptWrite);
    }
    return;
}

int main() {
	fptRead = fopen("program.txt","r+");
    fptWrite = fopen("smallCase.txt", "w");
	toLower(fptRead, fptWrite);
    fclose(fptRead);
    fclose(fptWrite);

    yyin = fopen("smallCase.txt", "r");
    yyout = fopen("output.txt", "w");

    yyparse();
}