%{
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <stdlib.h>
#include <math.h>


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
    bool declared, assigned;
} Symbol;

Symbol symbolTable[100];

char mainSyntaxTree[10000] = "";

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
        char sval[100];
        bool declared;
        bool assigned;
        char syntaxTree[10000];
    };
    struct attributes attr;

    struct arr_attributes {
        int datatype;
        bool bval;
        int first_ival;
        int second_ival;
        float dval;
        char cval;
        char sval[100];
        bool declared;
        bool assigned;
        char syntaxTree[10000];
    };
    struct arr_attributes arr_attr;

}

%token <attr> INTEGER_CONST REAL_CONST CHARACTER_CONSTANT IDENTIFIER DATA_TYPE RELATIONAL_OPERATOR BINARY_BOOL_OPERATOR UNARY_BOOL_OPERATOR
%token <arr_attr> ARRAY_DATA_TYPE TO

%type <attr> expression primary_expression arithmetic_expression relational_expression boolean_expression identifier statements statement program declarations multiple_lines declaration_line assignment conditional loop output output_list multiple_identifiers

%token SQUARE_OPEN SQUARE_CLOSE COMMA SEMICOLON FULLSTOP COLON ASSIGN OPEN_BRACE CLOSED_BRACE ADD SUBTRACT MULTIPLY DIVIDE MODULO PROGRAM VAR IF THEN ELSE WHILE FOR DO TOKEN_BEGIN END READ WRITE STRING_CONSTANT PUNCTUATOR

%left BINARY_BOOL_OPERATOR
%left RELATIONAL_OPERATOR
%left ADD SUBTRACT
%left MULTIPLY DIVIDE MODULO
%right UNARY_BOOL_OPERATOR

%start program

%%

program
    : PROGRAM IDENTIFIER SEMICOLON declarations TOKEN_BEGIN statements END FULLSTOP {
        // char temp[10000];
        sprintf($$.syntaxTree, "{PROGRAM%s{STATEMENTS%s}}", $4.syntaxTree, $6.syntaxTree);
        strcpy(mainSyntaxTree, $$.syntaxTree);
    }
    ;

declarations
    : VAR multiple_lines {
        sprintf($$.syntaxTree, "{DECLARATIONS%s}", $2.syntaxTree);
    }
    ;

multiple_lines
    : declaration_line multiple_lines {
        sprintf($$.syntaxTree, "%s%s", $1.syntaxTree, $2.syntaxTree);
    }
    | declaration_line {
        sprintf($$.syntaxTree, "%s", $1.syntaxTree);
    }
    ;

// Doesn't support the case of no declarations
declaration_line
    : multiple_identifiers COLON DATA_TYPE SEMICOLON {
        for (int i=0; i<current_size; i++) {
            if (!(symbolTable[i].declared)) {
                symbolTable[i].declared = true;
                symbolTable[i].assigned = false;
                symbolTable[i].datatype = $3.datatype;
            }
        }
        if ($3.datatype == 1)
            sprintf($3.syntaxTree, "int");
        else if ($3.datatype == 2)
            sprintf($3.syntaxTree, "real");
        else if ($3.datatype == 3)
            sprintf($3.syntaxTree, "bool");
        else if ($3.datatype == 4)
            sprintf($3.syntaxTree, "char");
        sprintf($$.syntaxTree, "{DECLARATION-STATEMENT{%s{%s}}}", $3.syntaxTree, $1.syntaxTree);
    }
    | multiple_identifiers COLON ARRAY_DATA_TYPE SEMICOLON {
        char vars[100][100];
        int st = 0, fr;
        bool flag = false;
        for (int i=0; i<current_size; i++) {
            if (!(symbolTable[i].declared)) {
                symbolTable[i].declared = true;
                symbolTable[i].assigned = false;
                symbolTable[i].datatype = $3.datatype;
                strcpy(vars[st++], symbolTable[i].name);
                if (!flag) {
                    flag = true;
                    fr = i;
                }
            }
        }
        int before_size = current_size;
        current_size = fr;
        int j = 0;
        for (;fr<before_size; fr++) {
            for (int i=$3.first_ival; i<=$3.second_ival; i++) {
                char temp[100];
                sprintf(temp, "%s[%d]", vars[j], i);
                strcpy(symbolTable[current_size].name, temp);
                symbolTable[current_size].declared = true;
                symbolTable[current_size].assigned = false;
                symbolTable[current_size].datatype = $3.datatype;
                current_size++;
            }
            j++;
        }
        if ($3.datatype == 1)
            sprintf($3.syntaxTree, "int[%d..%d]", $3.first_ival, $3.second_ival);
        else if ($3.datatype == 2)
            sprintf($3.syntaxTree, "real[%d..%d]", $3.first_ival, $3.second_ival);
        else if ($3.datatype == 3)
            sprintf($3.syntaxTree, "bool{%d..%d}", $3.first_ival, $3.second_ival);
        else if ($3.datatype == 4)
            sprintf($3.syntaxTree, "char{%d..%d}", $3.first_ival, $3.second_ival);
        sprintf($$.syntaxTree, "{DECLARATION-STATEMENT{%s{%s}}}", $3.syntaxTree, $1.syntaxTree);
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
        symbolTable[current_size++].declared = false;
        $1.assigned = false;
        sprintf($$.syntaxTree, "%s,%s", $1.sval, $3.syntaxTree);
    }
    | IDENTIFIER {
        for (int i=0; i<current_size; i++) {
            if (strcmp(symbolTable[i].name, $1.sval) == 0) {
                printf("[ERROR] multiple declarations of a variable: %s\n", $1.sval);
                error = true;
            }
        }
        strcpy(symbolTable[current_size].name, $1.sval);
        symbolTable[current_size++].declared = false;
        $1.assigned = false;
        sprintf($$.syntaxTree, "%s", $1.sval);
    }
    ;

statements
    : {
        sprintf($$.syntaxTree, "");
    }
    | statement SEMICOLON statements {
        sprintf($$.syntaxTree, "%s%s", $1.syntaxTree, $3.syntaxTree);
    }
    | TOKEN_BEGIN statements END statements {
        sprintf($$.syntaxTree, "%s%s", $2.syntaxTree, $4.syntaxTree);
    }
    ;

statement
    : assignment {
        sprintf($$.syntaxTree, "%s", $1.syntaxTree);
    }
    | conditional {
        sprintf($$.syntaxTree, "%s", $1.syntaxTree);
    }
    | loop {
        sprintf($$.syntaxTree, "%s", $1.syntaxTree);
    }
    | READ OPEN_BRACE identifier CLOSED_BRACE {
        for (int i=0; i<current_size; i++) {
            if (strcmp(symbolTable[i].name, $3.sval) == 0) {
                symbolTable[i].assigned = true;
                break;
            }
        }
        sprintf($$.syntaxTree, "{READ{%s}}", $3.sval);
    }
    | WRITE OPEN_BRACE output CLOSED_BRACE {
        sprintf($$.syntaxTree, "{WRITE{%s}}", $3.syntaxTree);
    }
    ;

assignment
    : identifier ASSIGN expression {
        if (!($1.datatype == $3.datatype || ($1.datatype == 2 && $3.datatype == 1))) {
            // printf("122: $1: %d $3: %d\n", $1.datatype, $3.datatype);
            bool flag = true;
            for (int i=0; i<current_size; i++) {
                if (strcmp(symbolTable[i].name, $1.sval) == 0) {
                    flag = false;
                    break;
                }
            }
            if (!flag) {
                printf("[ERROR] type error \n");
                error = true;
            }
        } else {
            for (int i=0; i<current_size; i++) {
                if (strcmp(symbolTable[i].name, $1.sval) == 0) {
                    symbolTable[i].assigned = true;
                    break;
                }
            }
            // printf("Assigned %s\n", $1.sval);
        }
        if (strlen($1.syntaxTree) == 0)
            sprintf($$.syntaxTree, "{ASSIGNMENT{%s{%s}}}", $1.sval, $3.syntaxTree);
        else
            sprintf($$.syntaxTree, "{ASSIGNMENT{%s{%s}}}", $1.syntaxTree, $3.syntaxTree);
    }
    ;

conditional
    : IF expression THEN TOKEN_BEGIN statements END {
        if (!($2.datatype == 3)) {
            printf("[ERROR] wrong type of condition in a conditional expression \n");
            error = true;
        }
        sprintf($$.syntaxTree, "{IF{CONDITION{%s}}{TRUE%s}}", $2.syntaxTree, $5.syntaxTree);
    }
    | IF expression THEN TOKEN_BEGIN statements END ELSE TOKEN_BEGIN statements END {
        if (!($2.datatype == 3)) {
            printf("[ERROR] wrong type of condition in a conditional expression \n");
            error = true;
        }
        sprintf($$.syntaxTree, "{IF-ELSE{CONDITION{%s}}{TRUE%s}{FALSE%s}}", $2.syntaxTree, $5.syntaxTree, $9.syntaxTree);
    }
    ;

loop
    : WHILE expression DO TOKEN_BEGIN statements END {
        if (!($2.datatype == 3)) {
            printf("[ERROR] wrong type of condition in a while loop \n");
            error = true;
        }
        sprintf($$.syntaxTree, "{WHILE{CONDITION{%s}}{STATEMENTS%s}}", $2.syntaxTree, $5.syntaxTree);
    }
    | FOR identifier {
        bool flag = true;
        for (int i=0; i<current_size; i++) {
            if (strcmp(symbolTable[i].name, $2.sval) == 0) {
                flag = false;
                symbolTable[i].assigned = true;
                break;
            }
        }
        if (flag) {
            error = true;
            printf("[ERROR] undeclared variable: %s\n", $2.sval);
        }
    } ASSIGN expression TO expression DO TOKEN_BEGIN statements END {
        if (!($5.datatype == 1 && $7.datatype == 1)) {
            printf("[ERROR] wrong type of expression in a for loop \n");
            error = true;
        } else if (!($2.datatype == 1)) {
            printf("[ERROR] wrong type of variable in a for loop \n");
            error = true;
        }
        if (strcmp($7.sval,"TO") == 0)
            sprintf($$.syntaxTree, "{FOR{CONDITION{%s{TO{%s}{%s}}}}{STATEMENTS%s}}", $2.syntaxTree, $5.syntaxTree, $7.syntaxTree, $10.syntaxTree);
        else if (strcmp($7.sval,"DOWNTO") == 0)
            sprintf($$.syntaxTree, "{FOR{CONDITION{%s{DOWN-TO{%s}{%s}}}}{STATEMENTS%s}}", $2.syntaxTree, $5.syntaxTree, $7.syntaxTree, $10.syntaxTree);
    }
    ;

expression: arithmetic_expression {
            $$.datatype = $1.datatype;
            sprintf($$.syntaxTree, "%s", $1.syntaxTree);
          }
          | relational_expression {
            $$.datatype = $1.datatype;
            sprintf($$.syntaxTree, "%s", $1.syntaxTree);
          }
          | boolean_expression {
            $$.datatype = $1.datatype;
            sprintf($$.syntaxTree, "%s", $1.syntaxTree);
          }
          ;

arithmetic_expression: arithmetic_expression ADD arithmetic_expression {
                        if ($1.datatype == $3.datatype) {
                            // printf("Arith ADD: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = $1.datatype;
                        } else if (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2)){
                            // printf("Arith ADD: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = 2;
                        } else {
                            // printf("155: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                        sprintf($$.syntaxTree, "ADD{%s}{%s}", $1.syntaxTree, $3.syntaxTree);
                    }
                     | arithmetic_expression SUBTRACT arithmetic_expression {
                        if ($1.datatype == $3.datatype) {
                            // printf("Arith SUB: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = $1.datatype;
                        } else if (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2)){
                            // printf("Arith SUB: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = 2;
                        } else {
                            // printf("166: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                        sprintf($$.syntaxTree, "SUBTRACT{%s}{%s}", $1.syntaxTree, $3.syntaxTree);
                    }
                     | arithmetic_expression MULTIPLY arithmetic_expression {
                        if ($1.datatype == $3.datatype) {
                            // printf("Arith MULT: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = $1.datatype;
                        } else if (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2)){
                            // printf("Arith MULT: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = 2;
                        } else {
                            // printf("177: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                        sprintf($$.syntaxTree, "MULTIPLY{%s}{%s}", $1.syntaxTree, $3.syntaxTree);
                    }
                     | arithmetic_expression DIVIDE arithmetic_expression {
                        if (($1.datatype == $3.datatype) || (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2))) {
                            // printf("Arith DIV: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = 2;
                        } else {
                            // printf("186: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                        sprintf($$.syntaxTree, "DIVIDE{%s}{%s}", $1.syntaxTree, $3.syntaxTree);
                    }
                     | arithmetic_expression MODULO arithmetic_expression {
                        if ($1.datatype == 1 && $3.datatype == 1) {
                            // printf("Arith MOD: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            $$.datatype = 1;
                        } else {
                            // printf("195: $1: %d $3: %d\n", $1.datatype, $3.datatype);
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                        sprintf($$.syntaxTree, "MODULO{%s}{%s}", $1.syntaxTree, $3.syntaxTree);
                    }
                     | OPEN_BRACE arithmetic_expression CLOSED_BRACE {
                        $$.datatype = $2.datatype;
                        sprintf($$.syntaxTree, "%s", $2.syntaxTree);
                     }
                     | primary_expression {
                        $$.datatype = $1.datatype;
                        sprintf($$.syntaxTree, "%s", $1.syntaxTree);
                     }
                     ;

relational_expression: arithmetic_expression RELATIONAL_OPERATOR arithmetic_expression {
                        $$.datatype = 3;
                        if (!(($1.datatype == 1 || $1.datatype == 2) && ($3.datatype == 1 || $3.datatype == 2))) {
                            printf("[ERROR] wrong type of operand(s) in a relational expression \n");
                            error = true;
                        }
                        sprintf($$.syntaxTree, "%s{%s}{%s}", $2.sval,  $1.syntaxTree, $3.syntaxTree);
                    }
                     | OPEN_BRACE relational_expression CLOSED_BRACE {
                        $$.datatype = $2.datatype;
                        sprintf($$.syntaxTree, "%s", $2.syntaxTree);
                     }
                     ;

boolean_expression: expression BINARY_BOOL_OPERATOR expression {
                        $$.datatype = 3;
                        if (!(($1.datatype == 3) && ($3.datatype == 3))) {
                            printf("[ERROR] wrong type of operand(s) in a boolean expression \n");
                            error = true;
                        }
                        sprintf($$.syntaxTree, "%s{%s}{%s}", $2.sval, $1.syntaxTree, $3.syntaxTree);
                    }
                  | UNARY_BOOL_OPERATOR expression {
                        $$.datatype = 3;
                        if (!($2.datatype == 3)) {
                            printf("[ERROR] wrong type of operand in a boolean expression \n");
                            error = true;
                        }
                        sprintf($$.syntaxTree, "NOT{%s}", $2.syntaxTree);
                    }
                  | OPEN_BRACE boolean_expression CLOSED_BRACE {
                        $$.datatype = $2.datatype;
                        sprintf($$.syntaxTree, "%s", $2.syntaxTree);
                     }
                  ;

primary_expression: identifier {
                    for (int i=0; i<current_size; i++) {
                        if (strcmp(symbolTable[i].name, $1.sval) == 0) {
                            if (!(symbolTable[i].assigned)) {
                                printf("[ERROR] variable not assigned: %s\n", $1.sval);
                                error = true;
                            }
                            break;
                        }
                    }
                    if (strlen($1.syntaxTree) == 0)
                        sprintf($$.syntaxTree, "%s", $1.sval);
                    else
                        sprintf($$.syntaxTree, "%s", $1.syntaxTree);
                    // sprintf($$.syntaxTree, "%s", $1.sval);
                  }
                  | INTEGER_CONST {
                    $$.datatype = 1;
                    $$.ival = (int)$1.ival;
                    sprintf($$.syntaxTree, "%d", $1.ival);
                  }
                  | REAL_CONST {
                    $$.datatype = 2;
                    $$.dval = (float)$1.dval;
                    sprintf($$.syntaxTree, "%f", $1.dval);
                  }
                  | CHARACTER_CONSTANT {
                    $$.datatype = 4;
                    $$.cval = (char)$1.cval;
                    sprintf($$.syntaxTree, "%c", $1.cval);
                  }
                  ;

identifier: IDENTIFIER {
                bool flag = true;
                char tempname[100];
                for (int i=0; i<current_size; i++) {
                    if (strcmp(symbolTable[i].name, $1.sval) == 0) {
                        $1.datatype = symbolTable[i].datatype;
                        flag = false;
                        if ($$.assigned) {
                            symbolTable[i].assigned = true;
                        }
                        strcpy(tempname,symbolTable[i].name);
                        break;
                    }
                }
                if (flag) {
                    error = true;
                    printf("[ERROR] undeclared variable: %s\n", $1.sval);
                }
                $$.datatype = $1.datatype;
                sprintf($$.syntaxTree, "%s", tempname);
                sprintf($1.syntaxTree, "%s", tempname);
          }
          | IDENTIFIER SQUARE_OPEN expression SQUARE_CLOSE {
                char temp[100], tempname[100];
                sprintf(temp, "%s[", $1.sval);
                bool flag = true;
                for (int i=0; i<current_size; i++) {
                    if (strncmp(symbolTable[i].name, temp, strlen(temp)) == 0) {
                        $1.datatype = symbolTable[i].datatype;
                        flag = false;
                        strcpy(tempname,symbolTable[i].name);
                        break;
                    }
                }
                if (flag) {
                    error = true;
                    printf("[ERROR] undeclared variable: %s\n", $1.sval);
                }
                if (!($3.datatype == 1)) {
                    printf("[ERROR] wrong type of array index \n");
                    error = true;
                }
                $$.datatype = $1.datatype;
                sprintf($$.syntaxTree, "%s{INDEX-AT{%s}}", $1.sval, $3.syntaxTree);
                sprintf($1.syntaxTree, "{%s{INDEX-AT{%s}}}", $1.sval, $3.syntaxTree);
          }
          ;

output
    : output_list {
        sprintf($$.syntaxTree, "%s", $1.syntaxTree);
    }
    | STRING_CONSTANT {
        
    }
    ;

output_list
    : expression {
        sprintf($$.syntaxTree, "%s", $1.syntaxTree);
    }
    | output_list COMMA expression {
        sprintf($$.syntaxTree, "%s}{%s", $1.syntaxTree, $3.syntaxTree);
    }
    ;


%%

void yyerror(char *s) {
    printf("syntax error\n");
    exit(1);
}

FILE* toLower(FILE* fptRead) {
    fptWrite = fopen(".smallCase.txt", "w");
    char ch;
    while ((ch = fgetc(fptRead)) != EOF) {
        fputc(tolower(ch), fptWrite);
    }
    fclose(fptWrite);
    return fopen(".smallCase.txt", "r");

}

int main(int argc, char *argv[]) {
    fptRead = fopen(argv[1],"r+");
    yyin = toLower(fptRead);
    fclose(fptRead);

    yyparse();

    if (error)
        printf("No syntax errors found\nOne or more semantic errors found\n");

    FILE *fpt = fopen("syntaxTree.txt", "w");
    fprintf(fpt, "%s", mainSyntaxTree);
    fclose(fpt);

    return 0;
}
