use strict;
use lib -e 't' ? 't' : 'test';
use Test::More;
BEGIN {
  if ( qr/x/ =~ /\(\?\^/ ){
    plan skip_all => "test only for perls before v5.13.5-11-gfb85c04";
  }
}
use TestYAML tests => 2;

filters { perl => ['eval', 'yaml_dump'] };

no_diff;
run_is ( perl => 'yaml' );

__DATA__
=== Regular Expression
+++ perl: qr{perfect match};
+++ yaml
--- !!perl/regexp (?-xism:perfect match)

=== Regular Expression with newline
+++ perl
qr{perfect
match}x;
+++ yaml
--- !!perl/regexp "(?x-ism:perfect\nmatch)"

