#the following script auto evaluates the .cpp programs
import subprocess
import os
import os.path
import glob

filelist = ['program.txt']
# filelist = glob.glob("*.txt")
# filelist = ["input0.txt", "input1.txt", "input2.txt", "input3.txt", "input4.txt", "input5.txt"]

for task in ["TASK3", "TASK4", "TASK5"]:
    lex_file = glob.glob(f"{task}/*.l")[0]
    yacc_file = glob.glob(f"{task}/*.y")[0]
    yacc = ["yacc", "-d", yacc_file]
    subprocess.call(yacc)
    lex = ["flex", lex_file]
    subprocess.call(lex)
    compile = ["gcc", "y.tab.c", "lex.yy.c", "-w", "-ll", "-o", "parser.out"]
    subprocess.call(compile)
    if os.path.isfile('./parser.out'):
        print(f"\n\n{task} Compiled successfully !!!!")
        for file in filelist:
            print(f"\n\nTASK: {task} FILE: {file}")
            run=["./parser.out", file]
            tmp = subprocess.call(run)
            if (tmp == 0 and task != "TASK4"):
                pprint = ["python3", f"{task}/.tree.py"]
                subprocess.call(pprint)
        delete = ["rm", "y.tab.c", "y.tab.h", "lex.yy.c", ".smallCase.txt", "syntaxTree.txt", "parser.out"] if not task == "TASK4" else ["rm", "y.tab.c", "y.tab.h", "lex.yy.c", ".smallCase.txt", "parser.out"]
        subprocess.call(delete)
