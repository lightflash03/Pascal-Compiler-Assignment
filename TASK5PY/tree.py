from nltk.tree import *
from dataclasses import dataclass

# assign your output (generalied list of the syntax tree) to varaible text
f = open('./syntaxTree.txt', 'r')

text = f.readlines()[0]
f.close()

text = text.replace("(", "ob")    #in the syntax tree, 'ob' will display in place of '('
text = text.replace(")", "cb")    #in the syntax tree, 'cb' will display in place of ')'
text = text.replace("{", "(")
text = text.replace("}", ")")

main_tree = Tree.fromstring(text)
# tree.pretty_print(unicodelines=True, nodedist=10)

# from nltk import Tree

def evaluate_expression(tree):
    if isinstance(tree, str):
        # Base case: Numeric literal
        return float(tree)

    operator = tree.label()
    if operator == '+':
        return evaluate_expression(tree[0]) + evaluate_expression(tree[1])
    elif operator == '-':
        return evaluate_expression(tree[0]) - evaluate_expression(tree[1])
    elif operator == '*':
        return evaluate_expression(tree[0]) * evaluate_expression(tree[1])
    elif operator == '/':
        return evaluate_expression(tree[0]) / evaluate_expression(tree[1])
    # Add more cases for other operators or node types as needed

@dataclass
class Symbol:
    name: str
    datatype: str
    value: any

symbolTable = []

evaluate_expression(main_tree)
