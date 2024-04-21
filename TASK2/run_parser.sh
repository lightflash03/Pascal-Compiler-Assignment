#!/bin/bash

# Generate y.tab.c from parser.y
yacc -d parser.y

# Generate lex.yy.c from lexer.l
flex lexer.l

# Compile y.tab.c and lex.yy.c
cc y.tab.c lex.yy.c -ll -o parser

# Run the parser
./parser

# Clean up
rm -f y.tab.c lex.yy.c parser