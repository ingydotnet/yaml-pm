use t::TestYAML;

delimiters('===', '+++');

run_is;

sub yaml_dump {
    return YAML::Dump(@_);
}

__DATA__
=== A one key hash
+++ perl eval yaml_dump
+{foo => 'bar'}
+++ yaml
---
foo: bar
