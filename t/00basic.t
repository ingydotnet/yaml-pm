# The YAML test suite uses YAML itself to package the tests. Since this might
# cause a chicken/egg situation it is best to test the YAML primitives first.

use Test;
use YAML;
use lib 't';
use TestYAML;

# Who needs Test::More anyway ;)
open ME, $0 or die;
my $total_tests = grep { /^test_basic\(/ } <ME>;
close ME;
plan(tests => $total_tests);

#==============================================================================
test_basic("A simple map", <<'...', <<'...');
---
one: foo
two: bar
three: baz
...
TestDump({qw(one foo two bar three baz)});
...

#==============================================================================
test_basic("Common String Types", <<'...', <<'...');
---
one: simple string
two: 42
three: '1 Single Quoted String'
four: "YAML's Double Quoted String"
five: |
  A block
    with several
      lines.
six: |-
  A "chomped" block
seven: >
  A
  folded
   string
...
TestDump({
    one => "simple string",
    two => 42,
    three => "1 Single Quoted String",
    four => "YAML's Double Quoted String",
    five => "A block\n  with several\n    lines.\n",
    six => 'A "chomped" block',
    seven => "A folded\n string\n",
   });
...

#==============================================================================
test_basic("Multiple documents", <<'...', <<'...');
---
foo: bar
---
bar: two
...
TestDump({qw(foo bar)}, {qw(bar two)});
...

#==============================================================================
test_basic("Comments", <<'...', <<'...');
# Leading Comment
---
# Preceding Comment
foo: bar
# Two
# Comments
---
    # Indented comment
bar: two
bee: three
# Intermediate comment
bore: four
...
TestDump({qw(foo bar)}, {qw(bar two bee three bore four)});
...

#==============================================================================
