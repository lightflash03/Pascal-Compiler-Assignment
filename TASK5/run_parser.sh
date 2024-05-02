#!/bin/bash

# Generate y.tab.c from parser.y
yacc -d parser.y

# Generate lex.yy.c from lexer.l
flex lexer.l

# Compile y.tab.c and lex.yy.c
gcc y.tab.c lex.yy.c -w -ly -o parser

# Run the parser
./parser ../program.txt

return_value=$?

if [ $return_value -eq 0 ]; then
    python3 tree.py
fi

# Clean up
rm -f y.tab.c y.tab.h lex.yy.c .smallCase.txt syntaxTree.txt parser
