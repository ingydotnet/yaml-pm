use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 57;

no_diff();
run_roundtrip_nyn('dumper');

__DATA__

===
+++ perl
[ "foo\nbar", "I like pie\nYou like pie\nWe all like pie" ]
+++ yaml
---
- "foo\nbar"
- |-
  I like pie
  You like pie
  We all like pie

===
+++ perl
{name => 'Ingy dot Net',
 rank => 'JAPH',
 'serial number' => '8675309',
};
+++ yaml
---
name: Ingy dot Net
rank: JAPH
serial number: 8675309

===
+++ perl
 {fruits => [qw(apples oranges pears)],
  meats => [qw(beef pork chicken)],
  vegetables => [qw(carrots peas corn)],
 }
+++ yaml
---
fruits:
  - apples
  - oranges
  - pears
meats:
  - beef
  - pork
  - chicken
vegetables:
  - carrots
  - peas
  - corn

===
+++ perl
['42', '43', '-44', '45']
+++ yaml
---
- 42
- 43
- -44
- 45

===
+++ perl
[
 'foo bar',
 'http://www.yaml.org',
 '12:34'
]
+++ yaml
---
- foo bar
- http://www.yaml.org
- 12:34

===
+++ perl
('1', " foo ", "bar\n", [], {})
+++ yaml
--- 1
--- ' foo '
--- "bar\n"
--- []
--- {}

===
+++ perl
'8\'-0" x 24" Lightweight'
+++ yaml
--- 8'-0" x 24" Lightweight

===
+++ perl
bless {}, 'Foo::Bar'
+++ yaml
--- !!perl/hash:Foo::Bar {}

===
+++ perl
bless {qw(foo 42 bar 43)}, 'Foo::Bar'
+++ yaml
--- !!perl/hash:Foo::Bar
bar: 43
foo: 42

===
+++ perl
bless [], 'Foo::Bar'
+++ yaml
--- !!perl/array:Foo::Bar []

===
+++ perl
bless [map "$_",42..45], 'Foo::Bar'
+++ yaml
--- !!perl/array:Foo::Bar
- 42
- 43
- 44
- 45

===
+++ perl
my $yn = YAML::Node->new({}, 'foo.com/bar');
$yn->{foo} = 'bar';
$yn->{bar} = 'baz';
$yn->{baz} = 'foo';
$yn
+++ yaml
--- !foo.com/bar
foo: bar
bar: baz
baz: foo

===
+++ perl
use YAML::Node;
+++ no_round_trip
+++ perl
my $a = '';
bless \$a, 'Foo::Bark';
+++ yaml
--- !!perl/scalar:Foo::Bark ''

=== Strings with nulls
+++ perl
"foo\0bar"
+++ yaml
--- "foo\0bar"

===
+++ no_round_trip
XXX: probably a YAML.pm bug
+++ perl
&YAML::VALUE
+++ yaml
--- =

===
+++ perl
my $ref = {foo => 'bar'};
[$ref, $ref]
+++ yaml
---
- &1
  foo: bar
- *1

===
+++ perl
no strict;
package main;
$joe_random_global = 42;
@joe_random_global = (43, 44);
*joe_random_global
+++ yaml
--- !!perl/glob:
PACKAGE: main
NAME: joe_random_global
SCALAR: 42
ARRAY:
  - 43
  - 44

===
+++ perl
no strict;
package main;
\*joe_random_global
+++ yaml
--- !!perl/ref
=: !!perl/glob:
  PACKAGE: main
  NAME: joe_random_global
  SCALAR: 42
  ARRAY:
    - 43
    - 44

===
+++ no_round_trip
+++ perl
my $foo = {qw(apple 1 banana 2 carrot 3 date 4)};
YAML::Bless($foo)->keys([qw(banana apple date)]);
$foo
+++ yaml
---
banana: 2
apple: 1
date: 4

===
+++ no_round_trip
+++ perl
use YAML::Node;
my $foo = {qw(apple 1 banana 2 carrot 3 date 4)};
my $yn = YAML::Node->new($foo);
YAML::Bless($foo, $yn)->keys([qw(apple)]); # red herring
ynode($yn)->keys([qw(banana date)]);
$foo
+++ yaml
---
banana: 2
date: 4

===
+++ no_round_trip
XXX: probably a test driver bug
+++ perl
my $joe_random_global = {qw(apple 1 banana 2 carrot 3 date 4)};
YAML::Bless($joe_random_global, 'TestBless');
return [$joe_random_global, $joe_random_global];
package TestBless;
use YAML::Node;
sub yaml_dump {
    my $yn = YAML::Node->new($_[0]);
    ynode($yn)->keys([qw(apple pear carrot)]);
    $yn->{pear} = $yn;
    return $yn;
}
+++ yaml
---
- &1
  apple: 1
  pear: *1
  carrot: 3
- *1

===
+++ no_round_trip
+++ perl
use YAML::Node;
my $joe_random_global = {qw(apple 1 banana 2 carrot 3 date 4)};
YAML::Bless($joe_random_global);
my $yn = YAML::Blessed($joe_random_global);
delete $yn->{banana};
$joe_random_global
+++ yaml
---
apple: 1
carrot: 3
date: 4

===
+++ perl
my $joe_random_global = \\\\\\\'42';
[
    $joe_random_global,
    $$$$joe_random_global,
    $joe_random_global,
    $$$$$$$joe_random_global,
    $$$$$$$$joe_random_global
]
+++ yaml
---
- &1 !!perl/ref
  =: !!perl/ref
    =: !!perl/ref
      =: &2 !!perl/ref
        =: !!perl/ref
          =: !!perl/ref
            =: &3 !!perl/ref
              =: 42
- *2
- *1
- *3
- 42

===
+++ perl
local $YAML::Indent = 1;
[{qw(foo 42 bar 44)}]
+++ yaml
---
- bar: 44
  foo: 42

===
+++ perl
local $YAML::Indent = 4;
[{qw(foo 42 bar 44)}]
+++ yaml
---
- bar: 44
  foo: 42

===
+++ perl
[undef, undef]
+++ yaml
---
- ~
- ~

===
+++ perl
my $joe_random_global = [];
push @$joe_random_global, $joe_random_global;
bless $joe_random_global, 'XYZ';
$joe_random_global
+++ yaml
--- &1 !!perl/array:XYZ
- *1

===
+++ perl
[
    '23',
    '3.45',
    '123456789012345',
]
+++ yaml
---
- 23
- 3.45
- 123456789012345

===
+++ perl
{'foo: bar' => 'baz # boo', 'foo ' => '  monkey', }
+++ yaml
---
'foo ': '  monkey'
'foo: bar': 'baz # boo'

===
+++ no_round_trip
+++ perl
$a = \\\\\\\\"foo"; $b = $$$$$a;
([$a, $b], [$b, $a])
+++ yaml
---
- !!perl/ref
  =: !!perl/ref
    =: !!perl/ref
      =: !!perl/ref
        =: &1 !!perl/ref
          =: !!perl/ref
            =: !!perl/ref
              =: !!perl/ref
                =: foo
- *1
---
- &1 !!perl/ref
  =: !!perl/ref
    =: !!perl/ref
      =: !!perl/ref
        =: foo
- !!perl/ref
  =: !!perl/ref
    =: !!perl/ref
      =: !!perl/ref
        =: *1

===
+++ no_round_trip
XXX an AutoBless feature could make this rt
+++ perl
$a = YAML::Node->new({qw(a 1 b 2 c 3 d 4)}, 'ingy.com/foo');
YAML::Node::ynode($a)->keys([qw(d b a)]);
$a;
+++ yaml
--- !ingy.com/foo
d: 4
b: 2
a: 1

===
+++ no_round_trip
+++ perl
$a = 'bitter buffalo';
bless \$a, 'Heart';
+++ yaml
--- !!perl/scalar:Heart bitter buffalo

===
+++ perl
{ 'foo[bar]' => 'baz' }
+++ yaml
---
'foo[bar]': baz
