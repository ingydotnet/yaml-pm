use t::TestYAML tests => 7;

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
--- !!perl/code: |
{
    use warnings;
    use strict 'refs';
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
- &1 !!perl/code: |
  {
      use warnings;
      use strict 'refs';
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
--- !!perl/code: '{ "DUMMY" }'

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
    use strict 'refs';
    'Something at least 30 chars';
}
