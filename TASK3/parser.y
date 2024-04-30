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

int current_size = 0;

bool error = false;

%}

%union {
    struct attributes {
        int datatype;
        bool bval;
        int ival;
        float dval;
        char cval;
        char *sval;
        bool declared;
        bool assigned;
    };
    struct attributes attr;
}

%token <attr> INTEGER_CONST REAL_CONST CHARACTER_CONSTANT IDENTIFIER DATA_TYPE

%type <attr> expression primary_expression arithmetic_expression relational_expression boolean_expression identifier

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
            if(symbolTable[i].datatype == 0)
                symbolTable[i].datatype = $3.datatype;
        }
    }
    ;

multiple_identifiers
    : IDENTIFIER COMMA multiple_identifiers {
        for (int i=0; i<current_size; i++) {
            if (strcmp(symbolTable[i].name, $1.sval) == 0) {
                printf("[ERROR] multiple declarations of a variable: %s\n", $1.sval);
                error = true;
            }
        }
        strcpy(symbolTable[current_size].name, $1.sval);
        symbolTable[current_size++].datatype = 0;
    }
    | IDENTIFIER {
        for (int i=0; i<current_size; i++) {
            if (strcmp(symbolTable[i].name, $1.sval) == 0) {
                printf("[ERROR] multiple declarations of a variable: %s\n", $1.sval);
                error = true;
            }
        }
        strcpy(symbolTable[current_size].name, $1.sval);
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
    : identifier ASSIGN expression {
        if (!($1.datatype == $3.datatype || ($1.datatype == 2 && $3.datatype == 1))) {
            printf("122: $1: %d $3: %d\n", $1.datatype, $3.datatype);
            printf("[ERROR] type error \n");
            error = true;
        }
    }
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

expression: arithmetic_expression {
            $$.datatype = $1.datatype;
            printf("Exprssn -> Arith: $1: %d $$: %d\n", $1.datatype, $$.datatype);
        }
          | relational_expression
          | boolean_expression
          | OPEN_BRACE boolean_expression CLOSED_BRACE
          | OPEN_BRACE relational_expression CLOSED_BRACE
          ;

arithmetic_expression: arithmetic_expression ADD arithmetic_expression {
                        if ($1.datatype == $3.datatype) {
                            printf("Arith ADD: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = $1.datatype;
                        } else if (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2)){
                            printf("Arith ADD: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = 2;
                        } else {
                            printf("155: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                    }
                     | arithmetic_expression SUBTRACT arithmetic_expression {
                        if ($1.datatype == $3.datatype) {
                            printf("Arith SUB: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = $1.datatype;
                        } else if (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2)){
                            printf("Arith SUB: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = 2;
                        } else {
                            printf("166: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                    }
                     | arithmetic_expression MULTIPLY arithmetic_expression {
                        if ($1.datatype == $3.datatype) {
                            printf("Arith MULT: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = $1.datatype;
                        } else if (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2)){
                            printf("Arith MULT: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = 2;
                        } else {
                            printf("177: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                    }
                     | arithmetic_expression DIVIDE arithmetic_expression {
                        if (($1.datatype == $3.datatype) || (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2))) {
                            printf("Arith DIV: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = 2;
                        } else {
                            printf("186: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                    }
                     | arithmetic_expression MODULO arithmetic_expression {
                        if ($1.datatype == 1 && $3.datatype == 1) {
                            printf("Arith MOD: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = 1;
                        } else {
                            printf("195: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                    }
                     | OPEN_BRACE arithmetic_expression CLOSED_BRACE {
                        $$.datatype = $2.datatype;
                     }
                     | primary_expression {
                        $$.datatype = $1.datatype;
                     }
                     ;

relational_expression: arithmetic_expression RELATIONAL_OPERATOR arithmetic_expression
                     ;

boolean_expression: expression BINARY_BOOL_OPERATOR expression
                  | UNARY_BOOL_OPERATOR expression
                  ;

primary_expression: identifier
                  | INTEGER_CONST {
                    $$.datatype = 1;
                    $$.ival = (int)$1.ival;
                  }
                  | REAL_CONST {
                    $$.datatype = 2;
                    $$.dval = (float)$1.dval;
                  }
                  | CHARACTER_CONSTANT {
                    $$.datatype = 4;
                    $$.cval = (char)$1.cval;
                  }
                  ;

identifier: IDENTIFIER {
        bool flag = true;
        for (int i=0; i<current_size; i++) {
            if (strcmp(symbolTable[i].name, $1.sval) == 0) {
                $1.datatype = symbolTable[i].datatype;
                flag = false;
                break;
            }
        }
        if (flag) {
            error = true;
            printf("[ERROR] undeclared variable: %s\n", $1);
        }
        $$.datatype = $1.datatype;
    }
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

    if (error) {
        printf("Exiting because of semantic errors\n");
        return 1;
    }

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
