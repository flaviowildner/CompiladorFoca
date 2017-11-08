flex lexica.l
bison -d sintatica.y
g++ sintatica.tab.c -o main
main < exemplo7.gambiart
g++ out.cpp -o out
out