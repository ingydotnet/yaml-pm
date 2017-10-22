use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 6;

run_roundtrip_nyn('dumper');

__DATA__

=== Actually test LoadCode functionality, block
+++ perl: $YAML::UseCode = 1; package main; sub { 42 }
+++ yaml
--- !!perl/code |
{
    use warnings;
    use strict;
    42;
}

=== Actually test LoadCode functionality, block
+++ perl: $YAML::UseCode = 1; package main; no warnings; sub { 42 }
+++ yaml
--- !!perl/code |
{
    no warnings;
    use strict;
    42;
}

=== Actually test LoadCode functionality, line
+++ perl: $YAML::UseCode = 1; package main; no strict; sub { 42 }
+++ yaml
--- !!perl/code "{\n    use warnings;\n    42;\n}\n"
