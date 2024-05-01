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
        bool bval;
        char cval;
    } val;
    bool declared, assigned;
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

    struct arr_attributes {
        int datatype;
        bool bval;
        int first_ival;
        int second_ival;
        float dval;
        char cval;
        char *sval;
        bool declared;
        bool assigned;
    };
    struct arr_attributes arr_attr;

    char string_const[100];
}

%token <attr> INTEGER_CONST REAL_CONST CHARACTER_CONSTANT IDENTIFIER DATA_TYPE 
%token <arr_attr> ARRAY_DATA_TYPE
%token <string_const> STRING_CONSTANT

%type <string_const> output output_list

%type <attr> expression primary_expression arithmetic_expression relational_expression boolean_expression identifier

%token SQUARE_OPEN SQUARE_CLOSE COMMA SEMICOLON FULLSTOP COLON ASSIGN OPEN_BRACE CLOSED_BRACE ADD SUBTRACT MULTIPLY DIVIDE MODULO RELATIONAL_OPERATOR UNARY_BOOL_OPERATOR BINARY_BOOL_OPERATOR PROGRAM VAR TO DOWNTO IF THEN ELSE WHILE FOR DO TOKEN_BEGIN END READ WRITE PUNCTUATOR

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
            if (!(symbolTable[i].declared)) {
                symbolTable[i].declared = true;
                symbolTable[i].assigned = false;
                symbolTable[i].datatype = $3.datatype;
            }
        }
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
    | READ OPEN_BRACE identifier CLOSED_BRACE {
        for (int i=0; i<current_size; i++) {
            if (strcmp(symbolTable[i].name, $3.sval) == 0) {
                symbolTable[i].assigned = true;
                
                switch(symbolTable[i].datatype) {
                    case 1:
                        scanf("%d", &symbolTable[i].val.ival);
                        $3.datatype = 1;
                        $3.ival = symbolTable[i].val.ival;
                        break;
                    case 2:
                        scanf("%f", &symbolTable[i].val.dval);
                        $3.datatype = 2;
                        $3.dval = symbolTable[i].val.dval;
                        break;
                    case 3:
                        scanf("%d", &symbolTable[i].val.bval);
                        $3.datatype = 3;
                        $3.bval = symbolTable[i].val.bval;
                        break;
                    case 4:
                        scanf("%c", &symbolTable[i].val.cval);
                        $3.datatype = 4;
                        $3.cval = symbolTable[i].val.cval;
                        break;
                }

                break;
            }
        }
    }
    | WRITE OPEN_BRACE output CLOSED_BRACE {
        // printf("In write statement\n");
        printf("%s\n", $3);
    }
    ;

assignment
    : identifier ASSIGN expression {
        if (!($1.datatype == $3.datatype || ($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2))) {
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

                    switch($1.datatype) {
                            case 1:
                                if ($1.datatype == $3.datatype) {
                                    symbolTable[i].val.ival = $3.ival;
                                    $1.datatype = $3.datatype;
                                    $1.ival = $3.ival;
                                }
                                else if ($1.datatype == 2 && $3.datatype == 1) {
                                    symbolTable[i].val.dval = (float)$3.ival;
                                    $1.datatype = 2;
                                    $1.dval = (int)$3.dval;
                                }
                                else {
                                    symbolTable[i].val.dval = $3.dval;
                                    $1.datatype = 2;
                                    $1.dval = (int)$3.dval;
                                }
                                break;
                            case 2:
                                if ($3.datatype == 1) {
                                    symbolTable[i].val.dval = (float)$3.ival;
                                    $1.datatype = 2;
                                    $1.dval = (int)$3.ival;
                                } else {
                                    symbolTable[i].val.dval = $3.dval;
                                    $1.datatype = 2;
                                    $1.dval = $3.dval;
                                }
                                break;
                            case 3:
                                symbolTable[i].val.bval = $3.bval;
                                $1.bval = $3.bval;
                                break;
                            case 4:
                                symbolTable[i].val.cval = $3.cval;
                                $1.cval = $3.cval;
                                break;
                        }

                    break;
                }
            }
        }
    }
    ;

conditional
    : IF expression THEN TOKEN_BEGIN statements END {
        if (!($2.datatype == 3)) {
            printf("[ERROR] wrong type of condition in a conditional expression \n");
            error = true;
        }
    }
    | IF expression THEN TOKEN_BEGIN statements END ELSE TOKEN_BEGIN statements END {
        if (!($2.datatype == 3)) {
            printf("[ERROR] wrong type of condition in a conditional expression \n");
            error = true;
        }
    }
    ;

loop
    : WHILE expression DO TOKEN_BEGIN statements END {
        if (!($2.datatype == 3)) {
            printf("[ERROR] wrong type of condition in a while loop \n");
            error = true;
        }
        // Write code to execute the loop statments
        
    }
    | FOR identifier ASSIGN expression DOWNTO expression DO TOKEN_BEGIN statements END {
        if (!($4.datatype == 1 && $6.datatype == 1)) {
            printf("[ERROR] wrong type of expression in a for loop \n");
            error = true;
        } else if (!($2.datatype == 1)) {
            printf("[ERROR] wrong type of variable in a for loop \n");
            error = true;
        }
    }
    | FOR identifier ASSIGN expression TO expression DO TOKEN_BEGIN statements END {
        if (!($4.datatype == 1 && $6.datatype == 1)) {
            printf("[ERROR] wrong type of expression in a for loop \n");
            error = true;
        } else if (!($2.datatype == 1)) {
            printf("[ERROR] wrong type of variable in a for loop \n");
            error = true;
        }
    }
    ;

expression: arithmetic_expression {

            $$.datatype = $1.datatype;

            switch($1.datatype) {
                case 1:
                    $$.ival = $1.ival;
                    break;
                case 2:
                    $$.dval = $1.dval;
                    break;
                case 3:
                    $$.bval = $1.bval;
                    break;
                case 4:
                    $$.cval = $1.cval;
                    break;
            }

          }
          | relational_expression {
            $$.datatype = $1.datatype;
          }
          | boolean_expression {
            $$.datatype = $1.datatype;
          }
          ;

arithmetic_expression: arithmetic_expression ADD arithmetic_expression {
                        if ($1.datatype == $3.datatype && ($1.datatype == 1 || $1.datatype == 2)) {
                            $$.datatype = $1.datatype;

                            switch($1.datatype) {
                                case 1:
                                    $$.ival = $1.ival + $3.ival;
                                    break;
                                case 2:
                                    $$.dval = $1.dval + $3.dval;
                                    break;
                            }

                        } else if (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2)){
                            $$.datatype = 2;

                            switch($1.datatype) {
                                case 1: // means $3 is double
                                    $$.dval = (double)$1.ival + $3.dval;
                                    break;
                                case 2: // means $1 is double
                                    $$.dval = $1.dval + (double)$3.ival;
                                    break;
                            }

                        } else {
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                    }
                     | arithmetic_expression SUBTRACT arithmetic_expression {
                        if ($1.datatype == $3.datatype && ($1.datatype == 1 || $1.datatype == 2)) {
                            $$.datatype = $1.datatype;

                            switch($1.datatype) {
                                case 1:
                                    $$.ival = $1.ival - $3.ival;
                                    break;
                                case 2:
                                    $$.dval = $1.dval - $3.dval;
                                    break;
                            }

                        } else if (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2)){
                            $$.datatype = 2;

                            switch($1.datatype) {
                                case 1: // means $3 is double
                                    $$.dval = (double)$1.ival - $3.dval;
                                    break;
                                case 2: // means $1 is double
                                    $$.dval = $1.dval - (double)$3.ival;
                                    break;
                            }

                        } else {
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                    }
                     | arithmetic_expression MULTIPLY arithmetic_expression {

                        if ($1.datatype == $3.datatype && ($1.datatype == 1 || $1.datatype == 2)) {
                            $$.datatype = $1.datatype;

                            switch($1.datatype) {
                                case 1:
                                    $$.ival = $1.ival * $3.ival;
                                    break;
                                case 2:
                                    $$.dval = $1.dval * $3.dval;
                                    break;
                            }

                        } else if (($1.datatype == 2 && $3.datatype == 1) || ($1.datatype == 1 && $3.datatype == 2)){
                            $$.datatype = 2;
        
                            switch($1.datatype) {
                                case 1: // means $3 is double
                                    $$.dval = (double)$1.ival * $3.dval;
                                    break;
                                case 2: // means $1 is double
                                    $$.dval = $1.dval * (double)$3.ival;
                                    break;
                            }

                        } else {
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                    }
                     | arithmetic_expression DIVIDE arithmetic_expression {
                        if ($1.datatype == 1 && $3.datatype == 1) {
                            $$.datatype = 2;
                            $$.dval = $1.ival / (double)$3.ival;
                        } 
                        else if ($1.datatype == 2 && $3.datatype == 2) {
                            $$.datatype = 2;
                            $$.dval = $1.dval / $3.dval;
                        }
                        else if ($1.datatype == 1 && $3.datatype == 2) {
                            $$.datatype = 2;
                            $$.dval = (double)$1.ival / $3.dval;
                        }
                        else if ($1.datatype == 2 && $3.datatype == 1) {
                            $$.datatype = 2;
                            $$.dval = $1.dval / (double)$3.ival;
                        }
                        else {
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                    }
                     | arithmetic_expression MODULO arithmetic_expression {
                        if ($1.datatype == 1 && $3.datatype == 1) {
                            $$.datatype = 1;
                            $$.ival = $1.ival % $3.ival;
                        } else {
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

relational_expression: arithmetic_expression RELATIONAL_OPERATOR arithmetic_expression {
                        $$.datatype = 3;

                        if (!(($1.datatype == 1 || $1.datatype == 2) && ($3.datatype == 1 || $3.datatype == 2))) {
                            printf("[ERROR] wrong type of operand(s) in a relational expression \n");
                            error = true;
                        }
                    }
                     | OPEN_BRACE relational_expression CLOSED_BRACE {
                        $$.datatype = $2.datatype;
                     }
                     ;

boolean_expression: expression BINARY_BOOL_OPERATOR expression {
                        $$.datatype = 3;

                        if (!(($1.datatype == 3) && ($3.datatype == 3))) {
                            printf("[ERROR] wrong type of operand(s) in a boolean expression \n");
                            error = true;
                        }
                    }
                  | UNARY_BOOL_OPERATOR expression {
                        $$.datatype = 3;
                        if (!($2.datatype == 3)) {
                            printf("[ERROR] wrong type of operand in a boolean expression \n");
                            error = true;
                        }
                    }
                  | OPEN_BRACE boolean_expression CLOSED_BRACE {
                        $$.datatype = $2.datatype;
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
                    
                    if(!error) {
                        switch($1.datatype) {
                            case 1:
                                $$.ival = $1.ival;
                                break;
                            case 2:
                                $$.dval = $1.dval;
                                break;
                            case 3:
                                $$.bval = $1.bval;
                                break;
                            case 4:
                                $$.cval = $1.cval;
                                break;
                        }
                    }

                  }
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

                        switch($1.datatype) {
                            case 1:
                                // symbolTable[i].val.ival = $1.ival;
                                $$.ival = symbolTable[i].val.ival;
                                break;
                            case 2:
                                // symbolTable[i].val.dval = $1.dval;
                                $$.dval = symbolTable[i].val.dval;
                                break;
                            case 3:
                                // symbolTable[i].val.bval = $1.bval;
                                $$.bval = symbolTable[i].val.bval;
                                break;
                            case 4:
                                // symbolTable[i].val.cval = $1.cval;
                                $$.cval = symbolTable[i].val.cval;
                                break;
                        }

                        flag = false;
                        if ($$.assigned) {
                            symbolTable[i].assigned = true;
                        }
                        break;
                    }
                }
                if (flag) {
                    error = true;
                    printf("[ERROR] undeclared variable: %s\n", $1.sval);
                }
                $$.datatype = $1.datatype;

                /* Assign Check Data Type */
                
                // switch($1.datatype) {
                //     case 1:
                //         $$.ival = $1.ival;
                //         break;
                //     case 2:
                //         $$.dval = $1.dval;
                //         break;
                //     case 3:
                //         $$.bval = $1.bval;
                //         break;
                //     case 4:
                //         $$.cval = $1.cval;
                //         break;
                // }

                /* Assign Check Data Type code ends here */
          }
          | IDENTIFIER SQUARE_OPEN expression SQUARE_CLOSE {
                char temp[100];
                sprintf(temp, "%s[", $1.sval);
                bool flag = true;
                for (int i=0; i<current_size; i++) {
                    if (strncmp(symbolTable[i].name, temp, strlen(temp)) == 0) {
                        $1.datatype = symbolTable[i].datatype;
                        flag = false;
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

                 /* Assign Check Data Type */
                
                // switch($1.datatype) {
                //     case 1:
                //         $$.ival = $1.ival;
                //         break;
                //     case 2:
                //         $$.dval = $1.dval;
                //         break;
                //     case 3:
                //         $$.bval = $1.bval;
                //         break;
                //     case 4:
                //         $$.cval = $1.cval;
                //         break;
                // }

                /* Assign Check Data Type code ends here */
          }
          ;

output
    : output_list {
        strcpy($$, $1);
    }
    | STRING_CONSTANT {
        strcpy($$, $1);
    }
    ;

output_list
    : expression {
         switch($1.datatype) {
            case 1:
                sprintf($$, "%d", $1.ival);
                break;
            case 2:
                sprintf($$, "%f", $1.dval);
                break;
            case 3:
                sprintf($$, "%d", $1.bval);
                break;
            case 4:
                sprintf($$, "%c", $1.cval);
                break;
        }
    }
    | output_list COMMA expression  {
        char total_output[200];
        char output_temp[100];
        // printf("output_list: %s --- output_list: %s\n", $$, $1);
        strcpy(total_output, $1);
        switch($3.datatype) {
            case 1:
                sprintf(output_temp, ", %d", $3.ival);
                break;
            case 2:
                sprintf(output_temp, ", %f", $3.dval);
                break;
            case 3:
                sprintf(output_temp, ", %d", $3.bval);
                break;
            case 4:
                sprintf(output_temp, ", %c", $3.cval);
                break;
        }
        strcat(total_output, output_temp);
        strcpy($$, total_output);
    }
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
    printf("+-----------------------------------------+\n|     Variable     |   Type   |   Value   |\n|-----------------------------------------|\n");

    for (int i=0; i<current_size; i++) {
        if (symbolTable[i].datatype == 1) {
            if (symbolTable[i].assigned)
                printf("| %16s |   %4s   | %9d |\n", symbolTable[i].name, "int", symbolTable[i].val.ival);
            else 
                printf("| %16s |   %4s   |     %1s     |\n", symbolTable[i].name, "int", "-");
        }
        else if (symbolTable[i].datatype == 2) {
            if (symbolTable[i].assigned)
                printf("| %16s |   %4s   | %9.4f |\n", symbolTable[i].name, "real", symbolTable[i].val.dval);
            else 
                printf("| %16s |   %4s   |     %1s     |\n", symbolTable[i].name, "real", "-");
        }
        else if (symbolTable[i].datatype == 3) {
            if (symbolTable[i].assigned)
                printf("| %16s |   %4s   | %9d |\n", symbolTable[i].name, "bool", symbolTable[i].val.ival);
            else 
                printf("| %16s |   %4s   |     %1s     |\n", symbolTable[i].name, "bool", "-");
        }
        else if (symbolTable[i].datatype == 4) {
            if (symbolTable[i].assigned)
                printf("| %16s |   %4s   | %9s |\n", symbolTable[i].name, "char", symbolTable[i].val.cval);
            else 
                printf("| %16s |   %4s   |     %1s     |\n", symbolTable[i].name, "char", "-");
        }
    };

    printf("+-----------------------------------------+\n");

}
