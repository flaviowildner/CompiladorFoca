all:
	flex lexica.l
	bison -d sintatica.y
	g++ sintatica.tab.c -o GeradorIntermediario -std=gnu++11
	./GeradorIntermediario < exemplo.gambiart
	g++ out.cpp -o GambiArtLanguageCompilado
	./GambiArtLanguageCompilado