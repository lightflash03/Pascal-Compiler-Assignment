from nltk.tree import *
from dataclasses import dataclass
import re

# assign your output (generalied list of the syntax tree) to varaible text
f = open('./syntaxTree.txt', 'r')

text = f.readlines()[0]
f.close()

text = text.replace("(", "ob")    #in the syntax tree, 'ob' will display in place of '('
text = text.replace(")", "cb")    #in the syntax tree, 'cb' will display in place of ')'
text = text.replace("{", "(")
text = text.replace("}", ")")
text = text.replace(" ", "~")

main_tree = Tree.fromstring(text)

@dataclass
class Symbol:
    name: str
    datatype: str
    value: any

symbolTable = []

keywords = [
    'PROGRAM',
    'STATEMENTS',
    'DECLARATIONS',
    'DECLARATION-STATEMENT',
    'READ',
    'WRITE',
    'ASSIGNMENT',
    'IF',
    'CONDITION',
    'TRUE',
    'IF-ELSE',
    'FALSE',
    'WHILE',
    'FOR',
    'TO',
    'DOWN-TO',
    'ADD',
    'SUBTRACT',
    'MULTIPLY',
    'DIVIDE',
    'MODULO',
    'INDEX-AT',
    'NOT',
    'EQUALS',
    'LESS-THAN-OR-EQUAL-TO',
    'NOT-EQUALS',
    'LESS-THAN',
    'GREATER-THAN-OR-EQUAL-TO',
    'GREATER-THAN',
]

def lookup(name):
    for symbol in symbolTable:
        if symbol.name == name:
            return symbol
    return None

def evaluate_expression(tree):
    label = tree.label()
    if label in keywords:
        if label == 'DECLARATION-STATEMENT':
            for child in tree:
                childlabel = child.label()
                if childlabel.endswith(']'):
                    pass
                else:
                    datatyp = childlabel
                    for grandchild in child:
                        grandchild_label = grandchild.label()
                        for var in grandchild_label.split(','):
                            symbolTable.append(Symbol(name=var,datatype=datatyp,value=None))

        elif label == 'ASSIGNMENT':
            varname = tree[0].label()
            val = evaluate_expression(tree[0][0])
            var = lookup(varname)
            var.value = val

        elif label == 'READ':
            varname = tree[0].label()
            var = lookup(varname)
            if var.datatype == 'int':
                var.value = int(input())
            elif var.datatype == 'real':
                var.value = float(input())
            elif var.datatype == 'bool':
                var.value = bool(input())
            elif var.datatype == 'char':
                var.value = str(input())[0]
        elif label == 'WRITE':
            print(evaluate_expression(tree[0]))

        elif label == 'ADD':
            return evaluate_expression(tree[0]) + evaluate_expression(tree[1])
        elif label == 'SUBTRACT':
            return evaluate_expression(tree[0]) - evaluate_expression(tree[1])
        elif label == 'MULTIPLY':
            return evaluate_expression(tree[0]) * evaluate_expression(tree[1])
        elif label == 'DIVIDE':
            return evaluate_expression(tree[0]) / evaluate_expression(tree[1])
        elif label == 'MODULO':
            return evaluate_expression(tree[0]) % evaluate_expression(tree[1])
        
        elif label == 'NOT':
            return not evaluate_expression(tree[0])
        elif label == 'EQUALS':
            return evaluate_expression(tree[0]) == evaluate_expression(tree[1])
        elif label == 'LESS-THAN-OR-EQUAL-TO':
            return evaluate_expression(tree[0]) <= evaluate_expression(tree[1])
        elif label == 'NOT-EQUALS':
            return evaluate_expression(tree[0]) != evaluate_expression(tree[1])
        elif label == 'LESS-THAN':
            return evaluate_expression(tree[0]) < evaluate_expression(tree[1])
        elif label == 'GREATER-THAN-OR-EQUAL-TO':
            return evaluate_expression(tree[0]) >= evaluate_expression(tree[1])
        elif label == 'GREATER-THAN':
            return evaluate_expression(tree[0]) > evaluate_expression(tree[1])
        
        elif label == 'IF':
            if evaluate_expression(tree[0][0]):
                evaluate_expression(tree[1])
        elif label == 'IF-ELSE':
            if evaluate_expression(tree[0][0]):
                evaluate_expression(tree[1][0])
            else:
                evaluate_expression(tree[2][0])
        elif label == 'WHILE':
            while evaluate_expression(tree[0][0]):
                evaluate_expression(tree[1])
        elif label == 'FOR':
            varname = tree[0][0].label()
            var = lookup(varname)
            start = evaluate_expression(tree[0][0][0][0])
            end = evaluate_expression(tree[0][0][0][1])
            if (tree[0][0][0].label() == 'DOWN-TO'):
                for var.value in reversed(list(range(end, start+1))):
                    evaluate_expression(tree[1][0])
            else:
                for var.value in range(start, end+1):
                    evaluate_expression(tree[1][0])
        else:
            for child in tree:
                evaluate_expression(child)
    else:
        if bool(re.search(r'\d', label)):
            if '.' in label:
                return float(label)
            else:
                return int(label)
        else:
            var = lookup(label)
            if not var:
                return str(label).replace('~',' ')
            else:
                return var.value

evaluate_expression(main_tree)

print(f"┌────────────────┬────────────┬─────────────────────┐")
print(f"│    Variable    │    Type    │        Value        │")
print(f"├────────────────┼────────────┼─────────────────────┤")
for symbol in symbolTable:
    if symbol.datatype == 'int':
        if symbol.value:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{symbol.value:^21d}│")
        else:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{'-':^21s}│")
    elif symbol.datatype == 'real':
        print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{symbol.value if symbol.value else 0.:^21f}│")
    elif symbol.datatype == 'bool':
        if symbol.value == None:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{'true' if symbol.value else 'false':^21s}│")
        else:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{'-':^21s}│")
    elif symbol.datatype == 'char':
        print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{str(symbol.value) if symbol.value else '-':^21s}│")
print(f"└────────────────┴────────────┴─────────────────────┘")
