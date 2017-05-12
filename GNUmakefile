# This is the developer Makefile for YAML.pm

dist distclean distdir disttest manifest realclean test veryclean: Makefile
	make -f Makefile $@

README: lib/YAML.pm
	pod2text $< > $@

# XXX Finish release target. See by-hand commands below for starters.
release: release-check dist upload git-steps realclean
## Check git status
## Check version correctness
# make README
# make MANIFEST
# make test
# make disttest
# make manifest
# make dist
# cpan-upload YAML-1.23_001.tar.gz
# make veryclean
# rm YAML-1.23_001.tar.gz
# git commit -a -m 'v1.23_001'
# git tag -a -m "`head -5 Changes`" v1.23_001
# git tag -l -n9 v1.23_001

release-check: test disttest
	@echo Got to the place we do checks (soon)
	exit 1

Makefile:
	perl Makefile.PL
