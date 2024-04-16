%{
#include <stdio.h>
#include <string.h>

FILE* fptRead = NULL;
%}

%token ASSIGN OPEN_BRACE CLOSED_BRACE ARITHMETIC_OPERATOR RELATIONAL_OPERATOR UNARY_BOOL_OPERATOR BINARY_BOOL_OPERATOR PROGRAM DATA_TYPE VAR TO DOWNTO IF THEN ELSE WHILE FOR DO ARRAY BEGIN END READ WRITE INTEGER_CONST STRING_CONSTANT REAL_CONST IDENTIFIER PUNCTUATOR

%%

program
    : PROGRAM IDENTIFIER ';' declarations BEGIN statements END '.'
    ;

declarations
    : /* empty */
    | VAR declaration_list ';'
    ;

declaration_list
    : IDENTIFIER ':' DATA_TYPE
    | declaration_list ',' IDENTIFIER ':' DATA_TYPE
    ;

statements
    : /* empty */
    | statements statement ';'
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

expression
    : expression ARITHMETIC_OPERATOR expression
    | expression RELATIONAL_OPERATOR expression
    | UNARY_BOOL_OPERATOR expression
    | expression BINARY_BOOL_OPERATOR expression
    | '(' expression ')'
    | IDENTIFIER
    | INTEGER_CONST
    | REAL_CONST
    ;

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

void toLower(FILE* fptRead) {
	int c;
    char ch;
    while ((ch = fgetc(fptRead))! = EOF) {    
        fputc(tolower(ch), fptRead);
    }
    return 0;
}

int main() {
	fptRead = fopen("program.txt","r+");
	toLower(fptRead);
    yyparse();
}