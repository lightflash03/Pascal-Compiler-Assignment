%{
#include <stdio.h>
%}

%token KEYWORD IDENTIFIER INTEGER_CONST REAL_CONST OPERATOR PUNCTUATOR

%%

program
    : 'program' IDENTIFIER ';' declarations 'begin' statements 'end' '.'
    ;

declarations
    : /* empty */
    | declarations 'var' declaration_list ';'
    ;

declaration_list
    : IDENTIFIER ':' type
    | declaration_list ',' IDENTIFIER ':' type
    ;

type
    : 'integer'
    | 'real'
    | 'boolean'
    | 'char'
    ;

statements
    : /* empty */
    | statements statement ';'
    ;

statement
    : assignment
    | conditional
    | loop
    | 'read' '(' IDENTIFIER ')'
    | 'write' '(' output_list ')'
    ;

assignment
    : IDENTIFIER ':=' expression
    ;

conditional
    : 'if' expression 'then' statement
    | 'if' expression 'then' statement 'else' statement
    ;

loop
    : 'while' expression 'do' statement
    | 'for' IDENTIFIER ':=' expression 'to' expression 'do' statement
    ;

expression
    : /* Define expressions based on your operators and operands */
    ;

output_list
    : /* Define output list for write statement */
    ;

%%

int main() {
    return yyparse();
}

void yyerror(char *s) {
    fprintf(stderr, "Error: %s\n", s);
}
