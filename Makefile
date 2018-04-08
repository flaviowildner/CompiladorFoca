all:
	flex lexica.l
	bison -d sintatica.y
	g++ sintatica.tab.c -o GeradorIntermediario -std=gnu++11
	./GeradorIntermediario < exemplo.gambiart
	g++ intermediario.cpp -o GambiArtCompilado
	./GambiArtCompilado

clean:
	rm -f *.yy.c
	rm -f *.cpp
	rm -f *.tab.h
	rm -f *.tab.c
	rm -f GambiArtCompilado
	rm -f GeradorIntermediario
