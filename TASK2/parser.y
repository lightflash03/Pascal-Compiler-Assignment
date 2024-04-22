%{
#include <stdio.h>
#include <string.h>
#include <ctype.h>

FILE *fptRead = NULL, *fptWrite = NULL;
extern FILE *yyin;
extern FILE *yyout;
%}

%token CHARACTER_CONSTANT SQUARE_OPEN SQUARE_CLOSE COMMA SEMICOLON FULLSTOP COLON ASSIGN OPEN_BRACE CLOSED_BRACE ADD SUBTRACT MULTIPLY DIVIDE MODULO RELATIONAL_OPERATOR UNARY_BOOL_OPERATOR BINARY_BOOL_OPERATOR PROGRAM DATA_TYPE VAR TO DOWNTO IF THEN ELSE WHILE FOR DO TOKEN_BEGIN END READ WRITE INTEGER_CONST STRING_CONSTANT REAL_CONST IDENTIFIER PUNCTUATOR

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
    |
    ;

multiple_identifiers
    : IDENTIFIER COMMA multiple_identifiers
    | IDENTIFIER
    ;

statements
    : 
    | statement SEMICOLON statements
    | TOKEN_BEGIN statements END statements
    ;

statement
    : assignment
    | conditional
    | loop
    | READ OPEN_BRACE identifier CLOSED_BRACE
    | WRITE OPEN_BRACE output CLOSED_BRACE
    ;

assignment
    : identifier ASSIGN expression
    ;

conditional
    : IF expression THEN TOKEN_BEGIN statements END 
    | IF expression THEN TOKEN_BEGIN statements END ELSE TOKEN_BEGIN statements END 
    ;

loop
    : WHILE expression DO TOKEN_BEGIN statements END 
    | FOR identifier ASSIGN expression DOWNTO expression DO TOKEN_BEGIN statements END
    | FOR identifier ASSIGN expression TO expression DO TOKEN_BEGIN statements END 
    ;

expression: arithmetic_expression
          | relational_expression
          | boolean_expression
          | OPEN_BRACE expression CLOSED_BRACE
          ;

arithmetic_expression: arithmetic_expression ADD expression
                     | arithmetic_expression SUBTRACT expression
                     | arithmetic_expression MULTIPLY expression
                     | arithmetic_expression DIVIDE expression
                     | arithmetic_expression MODULO expression
                     | primary_expression
                     ;

relational_expression: arithmetic_expression RELATIONAL_OPERATOR arithmetic_expression
                     ;

boolean_expression: expression BINARY_BOOL_OPERATOR expression
                  | UNARY_BOOL_OPERATOR expression
                  ;

primary_expression: identifier
                  | INTEGER_CONST
                  | REAL_CONST
                  | CHARACTER_CONSTANT
                  ;

identifier: IDENTIFIER
          | IDENTIFIER SQUARE_OPEN expression SQUARE_CLOSE
          ;

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
    printf("syntax error\n");
    exit(1);
}

void toLower(FILE* fptRead, FILE* fptWrite) {
    char ch;
    while ((ch = fgetc(fptRead)) != EOF) {    
        fputc(tolower(ch), fptWrite);
    }
    return;
}

int main(int argc, char *argv[]) {
	fptRead = fopen(argv[1],"r+");
    fptWrite = fopen(".smallCase.txt", "w");
	toLower(fptRead, fptWrite);
    fclose(fptRead);
    fclose(fptWrite);

    yyin = fopen(".smallCase.txt", "r");

    yyparse();

    // No error encountered
    printf("valid input\n");
}
