use strict;
use lib 't/old';
use TestYAML;

run_is;

sub yaml_dump {
    return Dump(@_);
}

__DATA__
=== A one key hash
+++ perl eval yaml_dump
+{foo => 'bar'}
+++ yaml
---
foo: bar
