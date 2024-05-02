#!/bin/bash

# Generate y.tab.c from parser.y
yacc -d check.y

# Generate lex.yy.c from lexer.l
flex check.l

# Compile y.tab.c and lex.yy.c
gcc y.tab.c lex.yy.c -w -ll -o parser

# Run the parser
./parser ../program.txt

# Clean up
rm -f y.tab.c y.tab.h lex.yy.c .smallCase.txt parser