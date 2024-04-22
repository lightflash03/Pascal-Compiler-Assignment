#!/bin/bash

# Generate lex.yy.c from lexer.l
flex lexer.l

# Compile y.tab.c and lex.yy.c
gcc lex.yy.c -ly -o parser

# Run the parser
./parser program.txt

# Clean up
rm -f lex.yy.c parser
