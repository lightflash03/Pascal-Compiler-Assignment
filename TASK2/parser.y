%{
#include <stdio.h>
#include <string.h>
#include <ctype.h>

FILE *fptRead = NULL, *fptWrite = NULL;
extern FILE *yyin;
extern FILE *yyout;
%}

%token COMMA SEMICOLON FULLSTOP COLON ASSIGN OPEN_BRACE CLOSED_BRACE ADD SUBTRACT MULTIPLY DIVIDE MODULO RELATIONAL_OPERATOR UNARY_BOOL_OPERATOR BINARY_BOOL_OPERATOR PROGRAM DATA_TYPE VAR TO DOWNTO IF THEN ELSE WHILE FOR DO ARRAY TOKEN_BEGIN END READ WRITE INTEGER_CONST STRING_CONSTANT REAL_CONST IDENTIFIER PUNCTUATOR

%left BINARY_BOOL_OPERATOR
%left RELATIONAL_OPERATOR
%left ADD SUBTRACT
%left MULTIPLY DIVIDE MODULO
%right UNARY_BOOL_OPERATOR

%start program

%%

program
    : PROGRAM IDENTIFIER SEMICOLON declarations TOKEN_BEGIN statements END FULLSTOP
    ;

declarations
    : VAR declaration_list 
    ;

declaration_list
    : multiple_lines
    ;

// Doesn't support the case of no declarations
multiple_lines
    : multiple_identifiers COLON DATA_TYPE SEMICOLON multiple_lines
    | multiple_identifiers COLON DATA_TYPE SEMICOLON
    ;

multiple_identifiers
    : IDENTIFIER COMMA multiple_identifiers
    | IDENTIFIER
    ;

// multiple_identifiers
//     : IDENTIFIER
//     | multiple_identifiers COMMA IDENTIFIER
//     ;

statements
    : /* empty */
    | statement SEMICOLON statements
    ;

statement
    : assignment
    | conditional
    | loop
    | READ OPEN_BRACE IDENTIFIER CLOSED_BRACE
    | WRITE OPEN_BRACE output CLOSED_BRACE
    ;

assignment
    : IDENTIFIER ASSIGN expression
    ;

conditional
    : IF expression THEN statements
    | IF expression THEN statements ELSE statements
    ;

loop
    : WHILE expression DO TOKEN_BEGIN statements END SEMICOLON
    | FOR IDENTIFIER ASSIGN expression TO expression DO statement
    ;

// expression
//     : arithmetic_addition
//     | arithmetic_multiplication
//     | expression RELATIONAL_OPERATOR expression
//     | '!' expression
//     | expression BINARY_BOOL_OPERATOR expression
//     | OPEN_BRACE expression CLOSED_BRACE
//     | IDENTIFIER
//     | INTEGER_CONST
//     | REAL_CONST
//     ;

// arithmetic_addition
//     : expression ADD expression
// 	| expression SUBTRACT expression
//     ;

// arithmetic_multiplication
//     : expression MULTIPLY expression 
// 	| expression DIVIDE expression 
// 	| expression MODULO expression 
//     ;

expression: arithmetic_expression
          | relational_expression
          | boolean_expression
          | OPEN_BRACE expression CLOSED_BRACE
          ;

arithmetic_expression: arithmetic_expression ADD arithmetic_expression
                     | arithmetic_expression SUBTRACT arithmetic_expression
                     | arithmetic_expression MULTIPLY arithmetic_expression
                     | arithmetic_expression DIVIDE arithmetic_expression
                     | arithmetic_expression MODULO arithmetic_expression
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
    | output_list COMMA expression
    ;


%%

void yyerror(char *s) {
    fprintf(yyout, "Error: %s\n", s);
    exit(1);
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

    // No error encountered
    fprintf(yyout, "No error");
}