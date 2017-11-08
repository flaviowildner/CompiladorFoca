flex lexica.l
bison -d sintatica.y
g++ sintatica.tab.c -o main
main < exemplo6.gambiart
g++ out.cpp -o out
out