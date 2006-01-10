use t::TestYAML;

filters {
    perl => 'eval',
    yaml => 'yaml_load',
};

run_is_deeply;

__DATA__
=== A one key hash
+++ perl
+{foo => 'bar'}
+++ yaml
---
foo: bar
