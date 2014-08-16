use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 7;
use YAML ();   # [CPAN #74687] must load before B::Deparse for B::Deparse < 0.71

use B::Deparse;
if (new B::Deparse -> coderef2text ( sub { no strict; 1; use strict; 1; })
    =~ 'refs') {
 local $/;
 (my $data = <DATA>) =~ s/use strict/use strict 'refs'/g if $] < 5.015;
 if ($B::Deparse::VERSION > 0.67 and $B::Deparse::VERSION < 0.71) { # [CPAN #73702]
   $data =~ s/use warnings;/BEGIN {\${^WARNING_BITS} = "UUUUUUUUUUUU\\001"}/g;
 }
 open DATA, '<', \$data;
}

no_diff;
run_roundtrip_nyn('dumper');

__DATA__

=== a code ref
+++ config
local $YAML::DumpCode = 1;
+++ perl
package main;
return sub { 'Something at least 30 chars' };
+++ yaml
--- !!perl/code |
{
    use warnings;
    use strict;
    'Something at least 30 chars';
}

=== an array of the same code ref
+++ config
local $YAML::DumpCode = 1;
+++ perl
package main;
my $joe_random_global = sub { 'Something at least 30 chars' };
[$joe_random_global, $joe_random_global, $joe_random_global];
+++ yaml
---
- &1 !!perl/code |
  {
      use warnings;
      use strict;
      'Something at least 30 chars';
  }
- *1
- *1

=== dummy code ref
+++ config
local $YAML::DumpCode = 0;
+++ perl
sub { 'Something at least 30 chars' }
+++ yaml
--- !!perl/code '{ "DUMMY" }'

=== blessed code ref
+++ config
local $YAML::DumpCode = 1;
+++ perl
package main;
bless sub { 'Something at least 30 chars' }, "Foo::Bar";
+++ no_round_trip
+++ yaml
--- !!perl/code:Foo::Bar |
{
    use warnings;
    use strict;
    'Something at least 30 chars';
}
