%{
#include <stdio.h>
#include <string.h>
#include <ctype.h>

FILE *fptRead = NULL, *fptWrite = NULL;
extern FILE *yyin;
extern FILE *yyout;

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
} stk[25];

void addQuadruple(char op1[], char op[], char op2[], char result[]) {
    strcpy (quad[qind].operator, op);
    strcpy (quad[qind].operand1, op1);
    strcpy (quad[qind].operand2, op2);
    strcpy (quad[qind].result, result);
    qind++;
}

void display_Quad() {
    printf ("%s ", quad[qind-1].result);
    printf("=");
    printf ("%s " , quad[qind-1].operand1);
    printf ("%s ", quad[qind-1].operator);
    printf ("%s \n", quad[qind-1].operand2);
}

void push(char *c){
    strcpy(stk[++tos].c, c);
}

char* pop() {
    char* c=stk[tos].c;
    tos=tos-1;
    return c;
}

%}

%union{
    char cval[5];
    int ival;
}

%token CHARACTER_CONSTANT SQUARE_OPEN SQUARE_CLOSE COMMA SEMICOLON FULLSTOP COLON ASSIGN OPEN_BRACE CLOSED_BRACE ADD SUBTRACT MULTIPLY DIVIDE MODULO RELATIONAL_OPERATOR UNARY_BOOL_OPERATOR BINARY_BOOL_OPERATOR PROGRAM DATA_TYPE VAR TO DOWNTO IF THEN ELSE WHILE FOR DO TOKEN_BEGIN END READ WRITE STRING_CONSTANT REAL_CONST IDENTIFIER PUNCTUATOR
%token <ival> INTEGER_CONST;
%type <cval> expression primary_expression arithmetic_expression relational_expression boolean_expression identifier statements statement program declarations multiple_lines declaration_line assignment conditional loop output output_list multiple_identifiers;

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

arithmetic_expression: arithmetic_expression ADD arithmetic_expression {
                        char str[5], str1[5]="t"; 
                        sprintf(str,"%d", temp_char++);
                        strcat(str1, str); 
                        addQuadruple(pop(), "+", pop(), str1);
                        display_Quad(); 
                        push(str1);
                    }
                     | arithmetic_expression SUBTRACT arithmetic_expression {
                        char str[5], str1[5]="t"; 
                        sprintf(str, "%d", temp_char++);
                        strcat(str1, str); 
                        addQuadruple(pop(), "-", pop(), str1); 
                        display_Quad();
                        push(str1);
                     }
                     | arithmetic_expression MULTIPLY arithmetic_expression {
                        char str[5], str1[5]="t"; 
                        sprintf(str, "%d", temp_char++);
                        strcat(str1, str); 
                        addQuadruple(pop(), "*", pop(), str1);
                        display_Quad(); 
                        push(str1);
                     }
                     | arithmetic_expression DIVIDE arithmetic_expression {
                        char str[5], str1[5]="t"; 
                        sprintf(str, "%d", temp_char++);
                        strcat(str1, str); 
                        addQuadruple(pop(), "/", pop(), str1); 
                        display_Quad();
                        push(str1);
                     }
                     | arithmetic_expression MODULO arithmetic_expression
                     | OPEN_BRACE arithmetic_expression CLOSED_BRACE
                     | primary_expression {
                        char c[5]; 
                        sprintf(c,"%d",$1); 
                        push(c);
                     }
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
