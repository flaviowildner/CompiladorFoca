flex lexica.l
bison -d sintatica.y
g++ -std=gnu++11 sintatica.tab.c -o GeradorIntermediario
GeradorIntermediario < exemplo.gambiart
g++ out.cpp -o GambiArtLanguageCompilado
GambiArtLanguageCompilado