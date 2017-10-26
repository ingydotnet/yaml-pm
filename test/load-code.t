use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 4;

run_roundtrip_nyn('dumper');

__DATA__

=== Actually test LoadCode functionality, block
+++ perl: $YAML::UseCode = 1; package main; no strict; sub { "really long test string that's longer than 30" }
+++ yaml
--- !!perl/code |
{
    use warnings;
    q[really long test string that's longer than 30];
}

=== Actually test LoadCode functionality, line
+++ perl: $YAML::UseCode = 1; package main; no strict; sub { 42 }
+++ yaml
--- !!perl/code "{\n    use warnings;\n    42;\n}\n"
