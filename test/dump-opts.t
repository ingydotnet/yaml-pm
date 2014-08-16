use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 19;

run_roundtrip_nyn();

__DATA__
===
+++ config
local $YAML::UseHeader = 0
+++ perl
(['34', '45'], ['56', '67'])
+++ yaml
- 34
- 45
---
- 56
- 67
===
+++ no_round_trip
+++ config
local $YAML::UseAliases = 0
+++ perl
my $ref = {foo => 'bar'};
[$ref, $ref]
+++ yaml
---
- foo: bar
- foo: bar
===
+++ config
local $YAML::CompressSeries = 1
+++ perl
[
    {foo => 'bar'},
    {lips => 'red', crown => 'head'},
    {trix => [ 'foo', {silly => 'rabbit', bratty => 'kids', } ] },
]
+++ yaml
---
- foo: bar
- crown: head
  lips: red
- trix:
    - foo
    - bratty: kids
      silly: rabbit
===
+++ config
local $YAML::CompressSeries = 0;
local $YAML::Indent = 5
+++ perl
[
    {one => 'fun', pun => 'none'},
    two => 'foo',
    {three => [ {free => 'willy', dally => 'dilly'} ]},
]
+++ yaml
---
-
     one: fun
     pun: none
- two
- foo
-
     three:
          -
               dally: dilly
               free: willy
===
+++ config
local $YAML::CompressSeries = 1;
local $YAML::Indent = 5
+++ perl
[
    {one => 'fun', pun => 'none'},
    two => {foo => {true => 'blue'}},
    {three => [ {free => 'willy', dally => 'dilly'} ]},
]
+++ yaml
---
- one: fun
  pun: none
- two
- foo:
       true: blue
- three:
       - dally: dilly
         free: willy
===
+++ config
local $YAML::Indent = 3
+++ perl
[{ one => 'two', three => 'four' }, { foo => 'bar' }, ]
+++ yaml
---
- one: two
  three: four
- foo: bar
===
+++ config
local $YAML::CompressSeries = 1
+++ perl
[
    'The',
    {speed => 'quick', color => 'brown', &YAML::VALUE => 'fox'},
    'jumped over the',
    {speed => 'lazy', &YAML::VALUE, 'dog'},
]
+++ yaml
---
- The
- color: brown
  speed: quick
  =: fox
- jumped over the
- speed: lazy
  =: dog
===
+++ config
local $YAML::InlineSeries = 3
+++ perl
[
    ['10', '20', '30'],
    ['foo', 'bar'],
    ['thank', 'god', "it's", 'friday'],
]
+++ yaml
---
- [10, 20, 30]
- [foo, bar]
-
  - thank
  - god
  - it's
  - friday
===
+++ config
local $YAML::SortKeys = [qw(foo bar baz)]
+++ perl
{foo=>'42',bar=>'99',baz=>'4'}
+++ yaml
---
foo: 42
bar: 99
baz: 4
===
+++ perl
{foo => '42', bar => 'baz'}
+++ yaml
---
bar: baz
foo: 42
