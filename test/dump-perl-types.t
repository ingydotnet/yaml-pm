use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 14;

filters { perl => ['eval', 'yaml_dump'] };

use YAML ();   # [CPAN #74687] must load before B::Deparse for B::Deparse < 0.71
use B::Deparse;
if (new B::Deparse -> coderef2text ( sub { no strict; 1; use strict; 1; })
    =~ 'refs') {
 local $/;
 (my $data = <DATA>) =~ s/use strict/use strict 'refs'/g;
 if ($B::Deparse::VERSION > 0.67 and $B::Deparse::VERSION < 0.71) { # [CPAN #73702]
   $data =~ s/use warnings;/BEGIN {\${^WARNING_BITS} = "UUUUUUUUUUUU\\001"}/g;
 }
 open DATA, '<', \$data;
}

no_diff;
run_is perl => 'yaml';

__DATA__

=== Scalar
+++ perl: 'Hello'
+++ yaml
--- Hello

=== Hash
+++ perl: +{bar => 'foo', foo => 'bar'}
+++ yaml
---
bar: foo
foo: bar

=== Array
+++ perl: [qw(W O W)]
+++ yaml
---
- W
- O
- W

=== Code
+++ perl
$YAML::DumpCode = 1;
package main;
sub { print "Hello, world\n"; }
+++ yaml
--- !!perl/code |
{
    use warnings;
    use strict;
    print "Hello, world\n";
}

=== Scalar Reference
+++ perl: \ 'Goodbye'
+++ yaml
--- !!perl/ref
=: Goodbye

=== Scalar Glob
+++ perl
$::var = 'Hola';
*::var;
+++ yaml
--- !!perl/glob:
PACKAGE: main
NAME: var
SCALAR: Hola

=== Array Glob
+++ perl
@::var2 = (qw(xxx yyy zzz));
*::var2;
+++ yaml
--- !!perl/glob:
PACKAGE: main
NAME: var2
ARRAY:
  - xxx
  - yyy
  - zzz

=== Code Glob
+++ perl
$YAML::DumpCode = 1;
package main;
sub main::var3 { print "Hello, world\n"; }
*var3;
+++ yaml
--- !!perl/glob:
PACKAGE: main
NAME: var3
CODE: !!perl/code |
  {
      use warnings;
      use strict;
      print "Hello, world\n";
  }

=== Blessed Empty Hash
+++ perl: bless {}, 'A::B::C';
+++ yaml
--- !!perl/hash:A::B::C {}

=== Blessed Populated Hash
+++ perl: bless {qw(foo bar bar foo)}, 'A::B::C';
+++ yaml
--- !!perl/hash:A::B::C
bar: foo
foo: bar

=== Blessed Empty Array
+++ perl: bless [], 'A::B::C';
+++ yaml
--- !!perl/array:A::B::C []

=== Blessed Populated Array
+++ perl: bless [qw(foo bar bar foo)], 'A::B::C';
+++ yaml
--- !!perl/array:A::B::C
- foo
- bar
- bar
- foo

=== Blessed Empty String
+++ perl: my $e = ''; bless \ $e, 'A::B::C';
+++ yaml
--- !!perl/scalar:A::B::C ''

=== Blessed Populated String
+++ perl: my $fbbf = 'foo bar bar foo'; bless \ $fbbf, 'A::B::C';
+++ yaml
--- !!perl/scalar:A::B::C foo bar bar foo

=== Blessed Regular Expression
+++ SKIP
+++ perl: bless qr{perfect match}, 'A::B::C';
+++ yaml
--- !!perl/regexp:A::B::C perfect match

=== Blessed Glob
+++ SKIP
+++ perl: $::x = 42; bless \ *::x, 'A::B::C';
+++ yaml
--- !!perl/glob:A::B::C
PACKAGE: main
NAME: x
SCALAR: 42

