%{
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "prj.h"

int error_num=0;  /* Number of erros */
extern int linenumber;

int strnumber=0; /* number of strings in the table*/
int varnumber=0; /* Variables for generating temporary variables ... */
int labelnumber=0; /* ... and labels */
int repeat=-1;/* shows how many inside repeat loops were created */
int iflb=-1;/* shows how many inside if statements were created */
int thenlb=-1;/* shows how many inside then statements were created */
int addlab=0;/*shows which construction added last label 
0 - nobody, 1 - repeat, 2 - while , 3 - if*/
char* lastlabel;

FILE *out;

FILE* fptRead = NULL;
%}

%union { argumentnode arg; labelnode lbl; }

%start program

%token T_PROGRAM T_VAR T_BEGIN T_END 
%token T_INTEGER
%token <arg> T_INTEGER_NUM 
%token T_IF T_THEN
%token <lbl> T_WHILE 
%token T_DO T_REPEAT T_UNTIL
%token T_WRITE T_WRITELN
%token <arg> T_STRING
%token <arg> T_VARIABLE
%token T_DIV T_GE T_LE T_NE
%token T_ASSIGN

%type  <arg> expression
%type  <lbl> afterif

%nonassoc IFX
%nonassoc T_ELSE

%left T_GE T_LE T_EQ '=' '>' '<'
%left '+' '-'
%left '*' T_DIV

%%
program : head_block ';' var_block main_block '.'
	| error {		
		error_num++;
		printf("error #%d line %d:Bad program syntax\n",error_num,linenumber);
	} 
	;
 
head_block : T_PROGRAM T_VARIABLE '(' parameter_list ')'
	| T_PROGRAM T_VARIABLE
	; 

parameter_list : variable_list;

variable_list : T_VARIABLE
	| variable_list ',' T_VARIABLE
	;

var_block : T_VAR var_list ';'
	|
	;

var_list: var_list ';' variable_list ':' T_INTEGER
	| variable_list ':' T_INTEGER
	;

main_block : compound_statement
	;


compound_statement : T_BEGIN statement_list T_END
	;
	
optsemicolon: ';'
|
;
	
statement_list : statement_list1
	;

statement_list1 : statement_list1 ';' statement
	| statement	
	| error {
		error_num++;
		printf("error #%d line %d:Bad statement syntax\n",error_num,linenumber);
	}
	;
	


statement :T_VARIABLE T_ASSIGN expression	{
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($3)); 
		fprintf(out, "\tmovl\t%%eax, %s\n", $1.argument.symbol);

		 /*makequad(TAC_ASS, $3, -1, $1);*/}
	| repeat_st 
	| while_st 
	| if_st 
	| write_st 
	| writeln_st
	| compound_statement
	| optsemicolon
	;		 

repeat_st : T_REPEAT {
		addlab=1;
		repeat++;
		repeatlabels[repeat]=newlabel();
		fprintf(out, "%s:\n", repeatlabels[repeat]);
		
		/*$1 = add_label();
		makequad(TAC_LBL, add_label(), -1, -1);*/
	}
	statement_list T_UNTIL comparison
	;

while_st : T_WHILE {
		addlab=2;
		$1.beginlabel=newlabel();
		$1.endlabel=newlabel();
		fprintf(out, "%s:\n", $1.beginlabel);

		/*$1 = add_label();  Start label 
		add_label(); 	 End label 
		makequad(TAC_LBL, $1, -1, -1);*/
	} 
	comparison T_DO statement {
		fprintf(out, "\tjmp\t%s\n", $1.beginlabel);	
		fprintf(out, "%s:\n", $1.endlabel);
	
		/*makequad(TAC_JMP, $1, -1, -1);
		makequad(TAC_LBL, $1+1, -1, -1);*/
	}
	;

if_st: T_IF afterif comparison T_THEN statement afterthen %prec IFX afterthen1
	| T_IF afterif comparison  T_THEN statement afterthen T_ELSE statement afterelse
	; 

afterif:	{
			addlab=3;
			iflb++;
			iflabels[iflb]=newlabel();
			
			/*add_label();*/}
afterthen:	{
			thenlb++;
			thenlabels[thenlb]=newlabel();
			fprintf(out, "\tjmp\t%s\n", thenlabels[thenlb]);
			fprintf(out, "%s:\n", iflabels[iflb]);
			iflb--;
			
			/*makequad(TAC_JMP, add_label(), -1, -1);
			makequad(TAC_LBL, gettoplabel(2), -1, -1);*/}
afterthen1:	{ 
			fprintf(out, "%s:\n", thenlabels[thenlb]);
			thenlb--;
			/*makequad(TAC_LBL, gettoplabel(1), -1, -1);*/}
afterelse:	{ 
			fprintf(out, "%s:\n", thenlabels[thenlb]);
			thenlb--;
			/*makequad(TAC_LBL, gettoplabel(1), -1, -1);*/}

 
write_st:T_WRITE '(' T_INTEGER_NUM ')'	{
		fprintf(out, "\tpushl\t%s\n", getstrarg($3));
		fprintf(out, "\tpushl\t$param1\n");
		fprintf(out, "\tcall\tprintf\n");
		fprintf(out, "\taddl\t$8, %%esp\n");

		/* makequad(TAC_PRI, $3, -1, -1); */}
	|T_WRITE '(' T_VARIABLE ')'	{ 
		fprintf(out, "\tpushl\t%s\n", $3.argument.symbol);
		fprintf(out, "\tpushl\t$param1\n");
		fprintf(out, "\tcall\tprintf\n");
		fprintf(out, "\taddl\t$8, %%esp\n");
	
		/*makequad(TAC_PRI, $3, -1, -1); */}
	|T_WRITE '(' T_STRING ')'	{ 
		fprintf(out, "\tpushl\t%s\n", $3.argument.symbol);
		fprintf(out, "\tpushl\t$param3\n");
		fprintf(out, "\tcall\tprintf\n");
		fprintf(out, "\taddl\t$8, %%esp\n");
	
		/*makequad(TAC_PRI, $3, -1, -1); */}
	;
		
writeln_st:T_WRITELN '(' T_INTEGER_NUM ')'	{
		fprintf(out, "\tpushl\t%s\n", getstrarg($3));
		fprintf(out, "\tpushl\t$param2\n");
		fprintf(out, "\tcall\tprintf\n");
		fprintf(out, "\taddl\t$8, %%esp\n");

		/* makequad(TAC_PRI, $3, -1, -1); */}
	|T_WRITELN '(' T_VARIABLE ')'	{ 
		fprintf(out, "\tpushl\t%s\n", $3.argument.symbol);
		fprintf(out, "\tpushl\t$param2\n");
		fprintf(out, "\tcall\tprintf\n");
		fprintf(out, "\taddl\t$8, %%esp\n");
	
		/*makequad(TAC_PRI, $3, -1, -1); */}
	|T_WRITELN '(' T_STRING ')'	{ 
		fprintf(out, "\tpushl\t%s\n", $3.argument.symbol);
		fprintf(out, "\tpushl\t$param4\n");
		fprintf(out, "\tcall\tprintf\n");
		fprintf(out, "\taddl\t$8, %%esp\n");
	
		/*makequad(TAC_PRI, $3, -1, -1); */}
	;

expression : T_INTEGER_NUM
	| T_VARIABLE
	| expression '+' expression	{ 
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($1));
		fprintf(out, "\taddl\t%s, %%eax\n", getstrarg($3));	
		$$.argument.symbol=newtemp();
		$$.type=0;
		fprintf(out, "\tmovl\t%%eax, %s\n", $$.argument.symbol);
	
		/*$$ = gettemp(); makequad(TAC_ADD, $1, $3, $$); */
	}
	| expression '-' expression { 
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($1));
                fprintf(out, "\tsubl\t%s, %%eax\n", getstrarg($3));
                $$.argument.symbol=newtemp();
		$$.type=0;
                fprintf(out, "\tmovl\t%%eax, %s\n", $$.argument.symbol);
	
		/*$$ = gettemp(); makequad(TAC_SUB, $1, $3, $$);*/ }
	| expression '*' expression	{ 
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($1));
		fprintf(out, "\timull\t%s, %%eax\n", getstrarg($3));	
		$$.argument.symbol=newtemp();
		$$.type=0;
		fprintf(out, "\tmovl\t%%eax, %s\n", $$.argument.symbol);

		/*$$ = gettemp(); makequad(TAC_MUL, $1, $3, $$); */}
	| expression T_DIV expression	{ 
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($1));
		fprintf(out, "\tcdq\n");
	        fprintf(out, "\tmovl\t%s, %%ebx\n", getstrarg($3));
	        fprintf(out, "\tidiv\t%%ebx\n");
		$$.argument.symbol=newtemp();
		$$.type=0;
		fprintf(out, "\tmovl\t%%eax, %s\n", $$.argument.symbol);
	
		/*$$ = gettemp(); makequad(TAC_DIV, $1, $3, $$); */}
	| '('expression ')' 	{ $$ = $2; }
	;

comparison : expression '=' expression	{ 
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($3));
		fprintf(out, "\tcmp \t%s, %%eax\n", getstrarg($1));
		fprintf(out, "\tjne \t%s\n", getlastlabel());
	
		/*$$ = gettoplabel(1); makequad(TAC_JNE, $1, $3, $$);*/}
	| expression '>' expression	{		
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($3));
		fprintf(out, "\tcmp \t%s, %%eax\n", getstrarg($1));
		fprintf(out, "\tjge \t%s\n", getlastlabel());
	
		/*$$ = gettoplabel(1); makequad(TAC_JGE, $1, $3, $$); */}
	| expression '<' expression	{
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($3));
		fprintf(out, "\tcmp \t%s, %%eax\n", getstrarg($1));
		fprintf(out, "\tjle \t%s\n", getlastlabel());
	
		/*$$ = gettoplabel(1); makequad(TAC_JLE, $1, $3, $$); */}
	| expression T_GE expression	{
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($3));
		fprintf(out, "\tcmp \t%s, %%eax\n", getstrarg($1));
		fprintf(out, "\tjg \t%s\n", getlastlabel());
	
		/* $$ = gettoplabel(1); makequad(TAC_JG, $1, $3, $$); */}
	| expression T_LE expression	{ 
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($3));
		fprintf(out, "\tcmp \t%s, %%eax\n", getstrarg($1));
		fprintf(out, "\tjl \t%s\n", getlastlabel());
	
		/*$$ = gettoplabel(1); makequad(TAC_JL, $1, $3, $$); */}
	| expression T_NE expression	{ 
		fprintf(out, "\tmovl\t%s, %%eax\n", getstrarg($3));
		fprintf(out, "\tcmp \t%s, %%eax\n", getstrarg($1));
		fprintf(out, "\tje \t%s\n", getlastlabel());
		
		/*$$ = gettoplabel(1); makequad(TAC_JE, $1, $3, $$); */}
	;

%%

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
	
    yylex();
}