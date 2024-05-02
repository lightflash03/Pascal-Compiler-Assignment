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
    # input(f"REALLY?{name}")
    for symbol in symbolTable:
        if symbol.name == name:
            return symbol
    # print(name)
    # input()
    return None

int_matcher = r'^[-+]?\d+$'
float_matcher = r'^[-+]?\d+\.\d*$'

def evaluate_expression(tree, assignment=False):
    label = tree.label()
    if label in keywords:
        if label == 'DECLARATION-STATEMENT':
            for child in tree:
                childlabel = child.label()
                if childlabel.endswith(']'):
                    datatyp = childlabel.split('[')[0]
                    sv, ev = childlabel.split('[')[1].split(']')[0].split('..')
                    sv = int(sv)
                    ev = int(ev)
                    for grandchild in child:
                        grandchild_label = grandchild.label()
                        for var in grandchild_label.split(','):
                            for i in range(sv, ev+1):
                                symbolTable.append(Symbol(name=f"{var}[{i}]",datatype=datatyp,value=None))
                else:
                    datatyp = childlabel
                    for grandchild in child:
                        grandchild_label = grandchild.label()
                        for var in grandchild_label.split(','):
                            symbolTable.append(Symbol(name=var,datatype=datatyp,value=None))

        elif label == 'ASSIGNMENT':
            varname = tree[0].label()
            if varname == 'INDEX-AT':
                var = lookup(f"{tree[0][0].label()}[{evaluate_expression(tree[0][1],assignment=True)}]")
            else:
                var = lookup(varname)

            val = evaluate_expression(tree[1])
            var.value = val

        elif label == 'READ':
            varname = tree[0].label()
            if varname == 'INDEX-AT':
                var = lookup(f"{tree[0][0].label()}[{evaluate_expression(tree[0][1])}]", assignment=True)
            else:
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
            for child in tree:
                print(evaluate_expression(child))

        elif label == 'ADD':
            return evaluate_expression(tree[0]) + evaluate_expression(tree[1])
        elif label == 'SUBTRACT':
            # print('before')
            # print(evaluate_expression(tree[0]))
            # print('after')
            # input()
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

        elif label == 'INDEX-AT':
            # input(tree[0].label())
            # input(tree[1].label())
            varname = tree[0].label()
            # print("BEFORE")
            index = int(evaluate_expression(tree[1]))
            # input("hitler?")
            var = lookup(f"{varname}[{index}]")
            # print(f"{varname}[{index}]")
            return var.value

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
            start = int(evaluate_expression(tree[0][0][0][0]))
            end = int(evaluate_expression(tree[0][0][0][1]))
            if (tree[0][0][0].label() == 'DOWN-TO'):
                for i in reversed(list(range(end, start+1))):
                    var.value = i
                    for child in tree[1]:
                        evaluate_expression(child)
            else:
                for i in range(start, end+1):
                    var.value = i
                    for child in tree[1]:
                        evaluate_expression(child)
        elif label == 'STATEMENTS':
            for child in tree:
                evaluate_expression(child)
        else:
            for child in tree:
                evaluate_expression(child)
    elif label == "":
        # print('inside')
        # print(tree[0].label())
        return evaluate_expression(tree[0])
    else:

        if re.match(int_matcher, label):
            return int(label)
        elif re.match(float_matcher, label):
            return float(label)
        else:
            var = lookup(label)
            if var == None:
                return str(label).replace('~',' ')
            else:
                # print("THIS?")
                # input(var.value)
                return var.value

evaluate_expression(main_tree)

# try:
#     evaluate_expression(main_tree)
# except:
#     print("Runtime Error")
#     exit()

print(f"┌────────────────┬────────────┬─────────────────────┐")
print(f"│    Variable    │    Type    │        Value        │")
print(f"├────────────────┼────────────┼─────────────────────┤")
for symbol in symbolTable:
    if symbol.datatype == 'int':
        if symbol.value != None:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{symbol.value:^21d}│")
        else:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{'-':^21s}│")
    elif symbol.datatype == 'real':
        if symbol.value != None:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{symbol.value:^21f}│")
        else:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{'-':^21s}│")
    elif symbol.datatype == 'bool':
        if symbol.value != None:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{'true' if symbol.value else 'false':^21s}│")
        else:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{'-':^21s}│")
    elif symbol.datatype == 'char':
        if symbol.value != None:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{symbol.value:^21s}│")
        else:
            print(f"│{symbol.name:^16s}│{symbol.datatype:^12s}│{'-':^21s}│")

print(f"└────────────────┴────────────┴─────────────────────┘")
