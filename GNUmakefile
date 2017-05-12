# This is the developer Makefile for YAML.pm

ifneq ($(wildcard Makefile),)
$(error Please 'rm Makefile')
endif

dist distdir disttest manifest readme test: Makefile
	make -f Makefile $@
	make -f Makefile realclean

# XXX fix this later:
realclean:
	make -f Makefile $@

release: test disttest dist check

check:
	exit 1

Makefile:
	perl Makefile.PL
