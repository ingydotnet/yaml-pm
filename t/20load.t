use lib 't';
use TestYAML;
test_load(<DATA>);

__DATA__
---
load: |
    ---
    date: Sun Oct 28 20:41:17 2001
    error msg: Premature end of script headers
    ---
    date: Sun Oct 28 20:41:44 2001
    error msg: malformed header from script. Bad header=</UL>
    ---
    date: Sun Oct 28 20:42:19 2001
    error msg: malformed header from script. Bad header=</UL>
expect: |
    my $a = { map {split /:\s*/, $_, 2} split /\n/, <<END };
    date: Sun Oct 28 20:41:17 2001
    error msg: Premature end of script headers
    END
    my $b = { map {split /:\s*/, $_, 2} split /\n/, <<END };
    date: Sun Oct 28 20:41:44 2001
    error msg: malformed header from script. Bad header=</UL>
    END
    my $c = { map {split /:\s*/, $_, 2} split /\n/, <<END };
    date: Sun Oct 28 20:42:19 2001
    error msg: malformed header from script. Bad header=</UL>
    END
    ($a, $b, $c)
---
load: |
    # Top level documents
    #
    # Note that inline (single line) values
    # are not allowed at the top level. This
    # includes implicit values, quoted values
    # and inline collections.
    ---
    a: map
    ---
    - a
    - sequence
    --- >
    plain scalar
    --- |
    This
     is
      a
       block.
        It's
        kinda
       like
      a
     here
    document.
    --- |-
    A
     chomped
      block.
expect: |
    my $a = {a => 'map'};
    my $b = ['a', 'sequence'];
    my $c = "plain scalar\n";
    my $d = <<END;
    This
     is
      a
       block.
        It's
        kinda
       like
      a
     here
    document.
    END
    my $e = <<END;
    A
     chomped
      block.
    END
    chomp($e);
    ($a, $b, $c, $d, $e)
---
load: |
    # Inline collections
    #
    # sequence
    ---
    - [1,2,3]
    # trailing comma is ignored
    # still 3 elements
    - [1,2,3,]
    # four empty strings
    - [,,,,]
    # a pair of commas
    - [",",","]
    # a map
    - {foo: bar,baz: too}
    # empty sequence
    - []
    # empty map
    - {}
    # times for keys (key/value separator is ': ')
    - {09:00:00: Breakfast, 12:00:00: lunch time,}
    # a private Perl XYZ object
    - !perl/XYZ {small: object}
    # an object containing objects
    - !perl/ABC [!perl/@DEF [a,b,c],!perl/GHI {do: re, mi: fa, so: la,ti: do}]
    # sequences of self referential elements
    # (inline form not working yet) :(
    # - &FOO [*FOO,*FOO,*FOO]
    - &FOO
     - *FOO
     - *FOO
     - *FOO
    #
    # sequence of maps
    - [{name: Ingy},{name: Clark},{name: Oren},]
expect: |
    my $a = [1,2,3];
    my $b = [1,2,3,];
    my $c = ["","","","",];
    my $d = [",",","];
    my $e = {foo => 'bar', baz => 'too'};
    my $f = [];
    my $g = {};
    my $h = {'09:00:00' => 'Breakfast', '12:00:00' => 'lunch time'};
    my $i = bless {small => 'object'}, 'XYZ';
    my $j = bless [bless([qw(a b c)], 'DEF'), 
                bless({do => 're', mi => 'fa', so => 'la', ti => 'do'}, 'GHI'),
              ], 'ABC';
    my $k = [];
    push @$k, $k, $k, $k;
    my $l = [{name => 'Ingy'}, {name => 'Clark'}, {name => 'Oren'}, ];
    [$a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k, $l]
---
load: |
    --- 42
    --- foo
    --- " bar "
    --- []
    --- #YAML:1.0 {}
    --- '#YAML:9.9'
    --- {foo: [1, 2, 3], 12:34:56: bar}
expect: |
    my $a = 42;
    my $b = "foo";
    my $c = " bar ";
    my $d = [];
    my $e = {};
    my $f = "#YAML:9.9";
    my $g = {foo => [1, 2, 3], '12:34:56' => 'bar'};
    ($a, $b, $c, $d, $e, $f, $g)
---
load: |
    - 2
    - 3
    - 4
    --- #YAML:1.0
    foo: bar
expect: |
    ([2,3,4], {foo => 'bar'})
---
load: |4
         # A pre header comment
    ---
    # comment
     # comment
                                              #comment
    - 2
    # comment
    # comment
    - 3
    - 4
       # comment
    - 5
    # last comment
    --- #YAML:1.0
    boo:                          far
      # a comment
    foo                  :        bar  
    ---
    - >
     # Not a comment;
    # Is a comment
     #Not a comment
    --- 42
              #Final
             #Comment
expect: |
    ([2,3,4,5], 
     {foo => 'bar', boo => 'far'}, 
     ["# Not a comment; #Not a comment\n"],
     42)
---
load: |
    ---
    - foo
    - bar
    ---
    ---
    - foo
    - foo
    ---
    # comment

    ---
    - bar
    - bar
expect: |
    (['foo', 'bar'],'',['foo', 'foo'],'',['bar', 'bar'])
---
load: |
    --- !perl/ref:
      =: 42
expect: |
    (\42);
---
load: |
    ---
    - 1964-03-25
    - ! "1975-04-17"
    - !date '2001-09-11'
    - 12:34:00
    - ! "12:00:00"
    - !time '01:23:45'
expect: |
    ['1964-03-25', 
     '1975-04-17',
     '2001-09-11',
     '12:34:00',
     '12:00:00',
     '01:23:45',
    ];
---
load: |
    ---
    - fee
    - fie
    - foe
    # no num defined
expect: |
    [qw(fee fie foe)]
---
load: |+
    ---
    - |
      foo
      bar

expect: |
    ["foo\nbar\n"]
---
load: |+
    ---
    - |+
      foo
      bar

expect: |
    ["foo\nbar\n\n"]
---
load: |+
    ---
    - |-
      foo
      bar

expect: |
    ["foo\nbar"]
---
load: |
    ---
    #- -
    #- +
    - 44
    - -45
    - 4.6
    - -4.7
    - 3e+2
    - [-4e+3, 5e-4]
    - -6e-10
    - 2001-12-15
    - 2001-12-15T02:59:43.1Z
    - 2001-12-14T21:59:43.25-05:00
expect: |
    [44, -45, 4.6, -4.7, 300, [-4000, .0005], -.0000000006, 
     '2001-12-15', '2001-12-15T02:59:43.1Z', '2001-12-14T21:59:43.25-05:00',
    ]
---
load: |
    ---
expect: |
    ''
---
load: |
    ---
expect: |
    ''
---
load: |
    ---
expect: |
    ''
