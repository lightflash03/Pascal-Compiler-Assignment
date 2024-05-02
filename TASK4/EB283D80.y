%{
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <stdlib.h>
#include <math.h>

bool if_flag = false; 
bool intoArray = false;
bool compute = false;

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

bool if_condition = false;

int loop_Variable = 0;

int count=0;
int qind=0;
int tos=-1;
int temp_char=0;
struct quadruple{
    char operator[5];
    char operand1[10];
    char operand2[10];
    char result[10];
} quad[25];

struct stack{
    char c[10]; 
} stk[50];

void addQuadruple(char op1[], char op[], char op2[], char result[]) {
    strcpy (quad[qind].operator, op);
    strcpy (quad[qind].operand1, op1);
    strcpy (quad[qind].operand2, op2);
    strcpy (quad[qind].result, result);
    qind++;
}

void display_Quad() {
    printf ("%s ", quad[qind-1].result);
    printf("= ");
    printf ("%s " , quad[qind-1].operand1);
    printf ("%s ", quad[qind-1].operator);
    printf ("%s \n", quad[qind-1].operand2);
}

void push(char *c) {
    strcpy(stk[++tos].c, c);
}

char* pop() {
    char* c=stk[tos].c;
    tos=tos-1;
    return c;
}

%}

%union {
    struct attributes {
        int datatype;
        bool bval;
        int ival;
        float dval;
        char cval;
        char sval[500];
        bool declared;
        bool assigned;
        int relop;
        int bool_op;
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
    };
    struct arr_attributes arr_attr;

    char string_const[100];
}

%token <attr> INTEGER_CONST REAL_CONST CHARACTER_CONSTANT IDENTIFIER DATA_TYPE RELATIONAL_OPERATOR UNARY_BOOL_OPERATOR BINARY_BOOL_OPERATOR
%token <arr_attr> ARRAY_DATA_TYPE TO
%token <string_const> STRING_CONSTANT

%type <string_const> output output_list

%type <attr> expression primary_expression arithmetic_expression relational_expression boolean_expression identifier

%token SQUARE_OPEN SQUARE_CLOSE COMMA SEMICOLON FULLSTOP COLON ASSIGN OPEN_BRACE CLOSED_BRACE ADD SUBTRACT MULTIPLY DIVIDE MODULO PROGRAM VAR IF THEN ELSE WHILE FOR DO TOKEN_BEGIN END READ WRITE PUNCTUATOR

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
        // printf("%s\n", $3);
    }
    ;

assignment
    : identifier ASSIGN expression {
        // printf("Assignment: %s\n", $1.sval);
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
                // printf("Symbol Table name: %s. Identifier name: %s\n", symbolTable[i].name, $1.sval);
                if (strcmp(symbolTable[i].name, $1.sval) == 0) {
                    // printf("Symbol Table name: %s. Identifier name: %s\n", symbolTable[i].name, $1.sval);
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
    : IF expression THEN TOKEN_BEGIN {
        printf("if not(%s) goto L%d \n", $2.sval, loop_Variable);
    } statements {
        // printf("Inside statements of if\n");
    } post_if {
        // printf("Inside postif\n");
        printf("L%d: \n", loop_Variable++);
    }
    ;

post_if
    : END {
    }
    | END ELSE TOKEN_BEGIN {
        // printf("Inside Else\n");
        printf("L%d: \n", loop_Variable++);
        // printf("Inside else after printing loop variale\n");
    } statements {

    } END
    ;

loop
    : WHILE expression DO TOKEN_BEGIN {
        if (!($2.datatype == 3)) {
            printf("[ERROR] wrong type of condition in a while loop \n");
            error = true;
        }
        printf("L%d: if not(%s) goto L%d\n", loop_Variable, $2.sval, loop_Variable+1);
    } statements {

    } END {

        printf("goto L%d\n", loop_Variable++);
        printf("L%d: \n", loop_Variable);
        // Write code to execute the loop statments
        
    }
    | FOR identifier ASSIGN expression TO expression DO TOKEN_BEGIN {
        // printf("In for: %s\n", $5.sval);
        if (strcmp($5.sval, "to") == 0) {
            printf("L%d: if not %s < %s goto L%d\n", loop_Variable, $2.sval, $6.sval, loop_Variable+1);
        } else {
            // printf("Executing else in the for loop\n");
            printf("L%d: if not %s < %s goto L%d\n", loop_Variable, $2.sval, $6.sval, loop_Variable+1);
        }
    } statements {
        
    } END {
        printf("goto L%d\n", loop_Variable++);
        printf("L%d:\n", loop_Variable);
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

            strcpy($$.sval, $1.sval);

          }
          | relational_expression {
            $$.datatype = $1.datatype;

            // Returns only bool
            $$.bval = $1.bval;
            strcpy($$.sval, $1.sval);
            // printf("$$: %s, $1: %s\n", $$.sval, $1.sval);
          }
          | boolean_expression {
            $$.datatype = $1.datatype;
            // Returns only bool
            $$.bval = $1.bval;
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

                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "+", pop(), str1);
                            display_Quad(); 
                            push(str1);

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

                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "+", pop(), str1);
                            display_Quad(); 
                            push(str1);

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
                            
                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "-", pop(), str1);
                            display_Quad(); 
                            push(str1);

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
                            
                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "-", pop(), str1);
                            display_Quad(); 
                            push(str1);

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

                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "*", pop(), str1);
                            display_Quad(); 
                            push(str1);

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

                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "*", pop(), str1);
                            display_Quad(); 
                            push(str1);

                        } else {
                            printf("[ERROR] type error \n");
                            error = true;
                        }
                    }
                     | arithmetic_expression DIVIDE arithmetic_expression {
                        if ($1.datatype == 1 && $3.datatype == 1) {
                            $$.datatype = 2;
                            $$.dval = $1.ival / (double)$3.ival;
                            
                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "/", pop(), str1);
                            display_Quad(); 
                            push(str1);
                        } 
                        else if ($1.datatype == 2 && $3.datatype == 2) {
                            $$.datatype = 2;
                            $$.dval = $1.dval / $3.dval;

                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "/", pop(), str1);
                            display_Quad(); 
                            push(str1);
                        }
                        else if ($1.datatype == 1 && $3.datatype == 2) {
                            $$.datatype = 2;
                            $$.dval = (double)$1.ival / $3.dval;

                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "/", pop(), str1);
                            display_Quad(); 
                            push(str1);
                        }
                        else if ($1.datatype == 2 && $3.datatype == 1) {
                            $$.datatype = 2;
                            $$.dval = $1.dval / (double)$3.ival;

                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "/", pop(), str1);
                            display_Quad(); 
                            push(str1);
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
                            
                            compute = true;
                            char str[5], str1[5]="t"; 
                            sprintf(str,"%d", temp_char++);
                            strcat(str1, str); 
                            addQuadruple(pop(), "%", pop(), str1);
                            display_Quad(); 
                            push(str1);
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
                        strcpy($$.sval, $1.sval);

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

                        char c[50]; 
                        strcpy(c, $1.sval);

                        // printf("Array Value: %s\n", c); 

                        // printf("intoArray: %d --- to be pushed: %s\n", intoArray, c);
                        // if(!intoArray && compute)
                        push(c);

                        intoArray = false;
                     }
                     ;

relational_expression: arithmetic_expression RELATIONAL_OPERATOR arithmetic_expression {
                        $$.datatype = 3;

                        if (!(($1.datatype == 1 || $1.datatype == 2) && ($3.datatype == 1 || $3.datatype == 2))) {
                            printf("[ERROR] wrong type of operand(s) in a relational expression \n");
                            error = true;
                        }
                        // have only bool
                        switch($2.relop) {
                            // relop: 1 = '=', 2 = '<=', 3 = '<', 4 = '>=', 5 = '>', 6 = '<>'
                            case 1:
                                $$.bval = $1.ival == $3.ival;
                                sprintf($$.sval, "%s == %s", $1.sval, $3.sval);
                                // printf("$3: %s, $1: %s\n", $3.sval, $1.sval);
                                break;
                            case 2:
                                $$.bval = $1.ival <= $3.ival;
                                sprintf($$.sval, "%s <= %s", $1.sval, $3.sval);
                                break; 
                            case 3:
                                $$.bval = $1.ival < $3.ival;
                                sprintf($$.sval, "%s < %s", $1.sval, $3.sval);
                                break;
                            case 4:
                                $$.bval = $1.ival >= $3.ival;
                                sprintf($$.sval, "%s >= %s", $1.sval, $3.sval);
                                break;
                            case 5:
                                $$.bval = $1.ival > $3.ival;
                                sprintf($$.sval, "%s > %s", $1.sval, $3.sval);
                                break;
                            case 6:
                                $$.bval = $1.ival != $3.ival;
                                sprintf($$.sval, "%s != %s", $1.sval, $3.sval);
                                break;
                        }


                    }
                     | OPEN_BRACE relational_expression CLOSED_BRACE {
                        $$.datatype = $2.datatype;
                        // have only bool
                        $$.bval = $2.bval;
                     }
                     ;

boolean_expression: expression BINARY_BOOL_OPERATOR expression {
                        $$.datatype = 3;

                        if (!(($1.datatype == 3) && ($3.datatype == 3))) {
                            printf("[ERROR] wrong type of operand(s) in a boolean expression \n");
                            error = true;
                        }

                        switch($2.bool_op) {
                            // bool_op: 1 = 'and', 2 = 'or'
                            case 1:
                                $$.bval = $1.bval && $3.bval;
                                break;
                            case 2:
                                $$.bval = $1.bval || $3.bval;
                                break;
                        }
                    }
                  | UNARY_BOOL_OPERATOR expression {
                        $$.datatype = 3;
                        if (!($2.datatype == 3)) {
                            printf("[ERROR] wrong type of operand in a boolean expression \n");
                            error = true;
                        }

                        $$.bval = !$2.bval;
                    }
                  | OPEN_BRACE boolean_expression CLOSED_BRACE {
                        $$.datatype = $2.datatype;
                        $$.bval = $2.bval;
                     }
                  ;

primary_expression: identifier {
                    
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

                    strcpy($$.sval, $1.sval);

                  }
                  | INTEGER_CONST {
                    $$.datatype = 1;
                    // $$.ival = (int)$1.ival;
                    sprintf($$.sval, "%d", $1.ival);
                  }
                  | REAL_CONST {
                    $$.datatype = 2;
                    // $$.dval = (float)$1.dval;
                    sprintf($$.sval, "%f", $1.dval);
                  }
                  | CHARACTER_CONSTANT {
                    $$.datatype = 4;
                    // $$.cval = (char)$1.cval;
                    sprintf($$.sval, "%c", $1.cval);
                  }
                  ;

identifier: IDENTIFIER {
                bool flag = true;
                for (int i=0; i<current_size; i++) {
                    if (strcmp(symbolTable[i].name, $1.sval) == 0) {
                        $1.datatype = symbolTable[i].datatype;
                        strcpy($1.sval, symbolTable[i].name);

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

                /*Changed @ 1:15PM May 2, remove if code breaks*/
                // printf("Identifier: %s\n", $$.sval);
                strcpy($$.sval, $1.sval);

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

                intoArray = true;

                char temp[100];
                sprintf(temp, "%s[", $1.sval);
                bool flag = true;
                for (int i=0; i<current_size; i++) {
                    // printf("%s\n", temp);
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

                // char onlyName[100];
                // strncpy(onlyName, temp, strlen(temp)-1);
                // printf("onlyName: %s\n", onlyName);

                sprintf(temp, "%s[%d]", $1.sval, $3.ival);
                for (int i=0; i<current_size; i++) {
                    if (strcmp(symbolTable[i].name, temp) == 0) {
                        switch(symbolTable[i].datatype) {
                            case 1:
                                $$.ival = symbolTable[i].val.ival;
                                break;
                            case 2:
                                $$.dval = symbolTable[i].val.dval;
                                break;
                            case 3:
                                $$.bval = symbolTable[i].val.bval;
                                break;
                            case 4:
                                $$.cval = symbolTable[i].val.cval;
                                break;
                        }
                    }
                }
                
                strcpy($$.sval, temp);
                // printf("%s\n", $$.sval);

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

    // printf("Symbol Table\n");
    // printf("+-----------------------------------------+\n|     Variable     |   Type   |   Value   |\n|-----------------------------------------|\n");

    // for (int i=0; i<current_size; i++) {
    //     if (symbolTable[i].datatype == 1) {
    //         if (symbolTable[i].assigned)
    //             printf("| %16s |   %4s   | %9d |\n", symbolTable[i].name, "int", symbolTable[i].val.ival);
    //         else 
    //             printf("| %16s |   %4s   |     %1s     |\n", symbolTable[i].name, "int", "-");
    //     }
    //     else if (symbolTable[i].datatype == 2) {
    //         if (symbolTable[i].assigned)
    //             printf("| %16s |   %4s   | %9.4f |\n", symbolTable[i].name, "real", symbolTable[i].val.dval);
    //         else 
    //             printf("| %16s |   %4s   |     %1s     |\n", symbolTable[i].name, "real", "-");
    //     }
    //     else if (symbolTable[i].datatype == 3) {
    //         if (symbolTable[i].assigned)
    //             printf("| %16s |   %4s   | %9d |\n", symbolTable[i].name, "bool", symbolTable[i].val.ival);
    //         else 
    //             printf("| %16s |   %4s   |     %1s     |\n", symbolTable[i].name, "bool", "-");
    //     }
    //     else if (symbolTable[i].datatype == 4) {
    //         if (symbolTable[i].assigned)
    //             printf("| %16s |   %4s   | %9s |\n", symbolTable[i].name, "char", symbolTable[i].val.cval);
    //         else 
    //             printf("| %16s |   %4s   |     %1s     |\n", symbolTable[i].name, "char", "-");
    //     }
    // };

    // printf("+-----------------------------------------+\n");

}