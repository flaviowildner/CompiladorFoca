flex lexica.l
bison -d sintatica.y
g++ sintatica.tab.c -o GeradorIntermediario
GeradorIntermediario < exemplo.gambiart
g++ out.cpp -o GambiArtLanguageCompilado
GambiArtLanguageCompilado