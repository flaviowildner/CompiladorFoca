flex lexica.l
bison -d sintatica.y
g++ sintatica.tab.c -o main
main < exemplo.foca