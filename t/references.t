use lib 'inc';
use Test::YAML tests => 10;

no_diff;

run_yaml_tests;

__DATA__
=== A scalar ref
+++ perl: \ 42
+++ yaml
--- !!perl/ref
=: 42

=== A ref to a scalar ref
+++ perl: \\ "yellow"
+++ yaml
--- !!perl/ref
=: !!perl/ref
  =: yellow

=== A ref to a ref to a scalar ref
+++ perl: \\\ 123
+++ yaml
--- !!perl/ref
=: !!perl/ref
  =: !!perl/ref
    =: 123

=== A blessed container reference
+++ perl
my $array_ref = [ 1, 3, 5];
my $container_ref = \ $array_ref;
bless $container_ref, 'Wax';
+++ yaml
--- !!perl/ref:Wax
=:
  - 1
  - 3
  - 5

=== A blessed scalar reference
+++ perl
my $scalar = "omg";
my $scalar_ref = \ $scalar;
bless $scalar_ref, 'Wax';
+++ yaml
--- !!perl/scalar:Wax omg
