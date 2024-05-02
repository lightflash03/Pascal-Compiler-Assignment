%{
#include<string.h>
#include<stdio.h>
#include<math.h>
#include<stdlib.h>

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


%token NL PL ML ST DIV
%token <ival> NUM
%left PL ST
%left ML DIV
%union{char cval[5];int ival;}
%type <cval> E


%%


s   : E NL {printf("\n....................DONE.........................\n"); return 1; }
E   : E PL E {
        char str[5], str1[5]="t"; 
        sprintf(str,"%d", temp_char++);
        strcat(str1, str); 
        addQuadruple(pop(), "+", pop(), str1);
        display_Quad(); 
        push(str1);
    }
    | E ML E { 
        char str[5], str1[5]="t"; 
        sprintf(str, "%d", temp_char++);
        strcat(str1, str); 
        addQuadruple(pop(), "*", pop(), str1);
        display_Quad(); 
        push(str1);
    }
    | E ST E { 
        char str[5], str1[5]="t"; 
        sprintf(str, "%d", temp_char++);
        strcat(str1, str); 
        addQuadruple(pop(), "-", pop(), str1); 
        display_Quad();
        push(str1);
    }
    | E DIV E { 
        char str[5], str1[5]="t"; 
        sprintf(str, "%d", temp_char++);
        strcat(str1, str); 
        addQuadruple(pop(), "/", pop(), str1); 
        display_Quad();
        push(str1);
    }
    | NUM {
        char c[5]; sprintf(c,"%d",$1); 
        push(c);
    }
    ;


%%


void main()
{
    printf ("Enter the expression:\n");
    yyparse();
}
void yyerror()
{
    printf("Invalid Expression:\n");
    exit(0);
}