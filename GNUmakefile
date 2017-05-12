# This is the developer Makefile for YAML.pm

dist distclean distdir disttest manifest realclean test veryclean: Makefile
	make -f Makefile $@

README: lib/YAML.pm
	pod2text $< > $@

release: test disttest dist check upload git-steps realclean

check:
	@echo Got to the place we do checks (soon)
	exit 1

Makefile:
	perl Makefile.PL
