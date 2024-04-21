#!/bin/bash

# Generate y.tab.c from parser.y
yacc -d --warnings=none parser.y

# Generate lex.yy.c from lexer.l
flex lexer.l

# Compile y.tab.c and lex.yy.c
gcc y.tab.c lex.yy.c -w -ll -o parser

# Run the parser
./parser

# Clean up
rm -f y.tab.c y.tab.h lex.yy.c parser