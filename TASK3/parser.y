%{
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>

FILE *fptRead = NULL, *fptWrite = NULL;
extern FILE *yyin;
extern FILE *yyout;

typedef struct {
    char name[100];
    int datatype;
    union value {
        int ival;
        float dval;
        char sval;
    } val;
} Symbol;

Symbol symbolTable[100];

int current_type = 0 ;
int current_size = 0;

%}

%union {
    // datatype, value, declared
    bool bval;
    int ival;
    float dval;
    char cval;
    char *sval;
    int datatype;
}

%token <ival> INTEGER_CONST
%token <dval> REAL_CONST
%token <cval> CHARACTER_CONSTANT
%token <sval> IDENTIFIER
%token <datatype> DATA_TYPE

%type <dval> primary_expression

%token SQUARE_OPEN SQUARE_CLOSE COMMA SEMICOLON FULLSTOP COLON ASSIGN OPEN_BRACE CLOSED_BRACE ADD SUBTRACT MULTIPLY DIVIDE MODULO RELATIONAL_OPERATOR UNARY_BOOL_OPERATOR BINARY_BOOL_OPERATOR PROGRAM VAR TO DOWNTO IF THEN ELSE WHILE FOR DO TOKEN_BEGIN END READ WRITE STRING_CONSTANT PUNCTUATOR

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
    : VAR multiple_lines
    ;

multiple_lines
    : declaration_line multiple_lines
    | declaration_line
    ;

// Doesn't support the case of no declarations
declaration_line
    : multiple_identifiers COLON DATA_TYPE SEMICOLON {
        for (int i=0; i<current_size; i++) {
            // printf("%s\n", symbolTable[i].name);
            if(symbolTable[i].datatype == 0)
                symbolTable[i].datatype = $3;
        }
    }
    ;

multiple_identifiers
    : IDENTIFIER COMMA multiple_identifiers {
        for (int i=0; i<current_size; i++) {
            if (strcmp(symbolTable[i].name, $1) == 0) {
                printf("[ERROR] multiple declarations of a variable: %s\n", $1);
                exit(1);
            }
        }
        strcpy(symbolTable[current_size].name, $1);
        symbolTable[current_size++].datatype = 0;
    }
    | IDENTIFIER {
        for (int i=0; i<current_size; i++) {
            if (strcmp(symbolTable[i].name, $1) == 0) {
                printf("[ERROR] multiple declarations of a variable: %s\n", $1);
                exit(1);
            }
        }
        strcpy(symbolTable[current_size].name, $1);
        symbolTable[current_size++].datatype = 0;
    }
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
          | OPEN_BRACE boolean_expression CLOSED_BRACE
          | OPEN_BRACE relational_expression CLOSED_BRACE
          ;

arithmetic_expression: arithmetic_expression ADD arithmetic_expression
                     | arithmetic_expression SUBTRACT arithmetic_expression
                     | arithmetic_expression MULTIPLY arithmetic_expression
                     | arithmetic_expression DIVIDE arithmetic_expression
                     | arithmetic_expression MODULO arithmetic_expression
                     | OPEN_BRACE arithmetic_expression CLOSED_BRACE
                     | primary_expression
                     ;

relational_expression: arithmetic_expression RELATIONAL_OPERATOR arithmetic_expression
                     ;

boolean_expression: expression BINARY_BOOL_OPERATOR expression
                  | UNARY_BOOL_OPERATOR expression
                  ;

primary_expression: identifier
                  | INTEGER_CONST {
                    $$ = (int)$1;
                  }
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

    printf("Symbol Table\n");
    printf("+---------------------------------+\n| Variable |   Type   |   Value   |\n|---------------------------------|\n");

    for (int i=0; i<current_size; i++) {
        if (symbolTable[i].datatype == 1)
            printf("| %8s |   %4s   | %9d |\n", symbolTable[i].name, "int", symbolTable[i].val.ival);
        else if (symbolTable[i].datatype == 2)
            printf("| %8s |   %4s   | %9.4f |\n", symbolTable[i].name, "real", symbolTable[i].val.dval);
        else if (symbolTable[i].datatype == 3)
            printf("| %8s |   %4s   | %9d |\n", symbolTable[i].name, "bool", symbolTable[i].val.ival);
        else if (symbolTable[i].datatype == 4)
            printf("| %8s |   %4s   | %9s |\n", symbolTable[i].name, "char", symbolTable[i].val.sval);
    };

    printf("+---------------------------------+\n");

}
