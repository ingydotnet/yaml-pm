use strict;
use warnings;
use lib 't', 'lib';
use TestChunks;
plan tests => 1 * number_of_tests;
test_load();

__DATA__
=== Bug#298704: libyaml-perl
+++ yaml
---
'a,v': c
+++ perl
{'a,v' => 'c'}

=== Paths as keys
+++ yaml
---
/etc/passwd: /foo/bar
+++ perl
{'/etc/passwd' => '/foo/bar'}

