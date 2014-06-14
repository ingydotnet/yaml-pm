use strict;
use File::Basename;
use lib dirname(__FILE__);

use TestYAML;

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
