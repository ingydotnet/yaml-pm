use lib 't';
use TestYAML;
test_round_trip(<DATA>);

__DATA__
perl: |
    {name => 'Brian Ingerson',
     rank => 'JAPH',
     'serial number' => 8675309,
    };
yaml: |
    --- #YAML:1.0
    name: Brian Ingerson
    rank: JAPH
    serial number: 8675309
---
perl: |
     {fruits => [qw(apples oranges pears)],
      meats => [qw(beef pork chicken)],
      vegetables => [qw(carrots peas corn)],
     }
yaml: |
    --- #YAML:1.0
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
---
perl: |
    [42, '43', '-44', 45]
yaml: |
    --- #YAML:1.0
    - 42
    - 43
    - -44
    - 45
---
perl: |
    [
     'foo bar',
     'http://www.yaml.org',
     '12:34'
    ]
yaml: |
    --- #YAML:1.0
    - foo bar
    - http://www.yaml.org
    - 12:34
---
perl: |
    (1, " foo ", "bar\n", [], {})
yaml: |
    --- #YAML:1.0 1
    --- #YAML:1.0 ' foo '
    --- #YAML:1.0 "bar\n"
    --- #YAML:1.0 []
    --- #YAML:1.0 {}
---
perl: |
    '8\'-0" x 24" Lightweight'
yaml: |
    --- #YAML:1.0 8'-0" x 24" Lightweight
---
perl: |
    bless {}, 'Foo::Bar'
yaml: |    
    --- #YAML:1.0 !perl/Foo::Bar {}
---
perl: |
    bless {qw(foo 42 bar 43)}, 'Foo::Bar'
yaml: |    
    --- #YAML:1.0 !perl/Foo::Bar
    bar: 43
    foo: 42
---
perl: |
    bless [], 'Foo::Bar'
yaml: |    
    --- #YAML:1.0 !perl/@Foo::Bar []
---
perl: |
    bless [42..45], 'Foo::Bar'
yaml: |    
    --- #YAML:1.0 !perl/@Foo::Bar
    - 42
    - 43
    - 44
    - 45
---
no-round-trip: AutoBless will make this rt
perl: |
    return bless {}, 'Foo::Bark';
    package Foo::Bark;
    use YAML::Node;
    sub yaml_dump {
        my $yn = YAML::Node->new({}, 'foo.com/bar');
        $yn->{foo} = 'bar';
        $yn->{bar} = 'baz';
        $yn->{baz} = 'foo';
        $yn
    }
yaml: |    
    --- #YAML:1.0 !foo.com/bar
    foo: bar
    bar: baz
    baz: foo
---
no-round-trip: AutoBless will make this rt
perl: |
    return bless \$a, 'Foo::Bark';
yaml: |    
    --- #YAML:1.0 !foo.com/bar
    foo: bar
    bar: baz
    baz: foo
---
perl: |
    "foo\0bar"
yaml: |
    --- #YAML:1.0 "foo\zbar"
---
no-round-trip: XXX: probably a YAML.pm bug
perl: |
    &YAML::VALUE
yaml: |
    --- #YAML:1.0 =
---
perl: |
    my $ref = {foo => 'bar'};
    [$ref, $ref]
yaml: |
    --- #YAML:1.0
    - &1
      foo: bar
    - *1
---
perl: |
    $joe_random_global = 42;
    @joe_random_global = (43, 44);
    *joe_random_global
yaml: |
    --- #YAML:1.0 !perl/glob:
    PACKAGE: main
    NAME: joe_random_global
    SCALAR: 42
    ARRAY:
      - 43
      - 44
---
perl: |
    $joe_random_global = 42;
    \*joe_random_global
yaml: |
    --- #YAML:1.0 !perl/ref:
    =: !perl/glob:
      PACKAGE: main
      NAME: joe_random_global
      SCALAR: 42
---
no-round-trip: XXX: probably a test driver bug
perl: |
    my $foo = {qw(apple 1 banana 2 carrot 3 date 4)};
    YAML::Bless($foo)->keys([qw(banana apple date)]);
    $foo
yaml: |
    --- #YAML:1.0
    banana: 2
    apple: 1
    date: 4
---
perl: |
    use YAML::Node;
    my $foo = {qw(apple 1 banana 2 carrot 3 date 4)};
    my $yn = YAML::Node->new($foo);
    YAML::Bless($foo, $yn)->keys([qw(apple)]); # red herring
    ynode($yn)->keys([qw(banana date)]);
    $foo
yaml: |
    --- #YAML:1.0
    banana: 2
    date: 4
---
no-round-trip: XXX: probably a test driver bug
perl: |
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
yaml: |
    --- #YAML:1.0
    - &1
      apple: 1
      pear: *1
      carrot: 3
    - *1
---
perl: |
    use YAML::Node;
    my $joe_random_global = {qw(apple 1 banana 2 carrot 3 date 4)};
    YAML::Bless($joe_random_global);
    my $yn = YAML::Blessed($joe_random_global);
    delete $yn->{banana};
    $joe_random_global
yaml: |
    --- #YAML:1.0
    apple: 1
    carrot: 3
    date: 4
---
perl: |
    $joe_random_global = \\\\\\\42;
    [
        $joe_random_global,
        $$$$joe_random_global,
        $joe_random_global,
        $$$$$$$joe_random_global,
        $$$$$$$$joe_random_global
    ]
yaml: | 
    --- #YAML:1.0
    - &1 !perl/ref:
      =: !perl/ref:
        =: !perl/ref:
          =: &2 !perl/ref:
            =: !perl/ref:
              =: !perl/ref:
                =: &3 !perl/ref:
                  =: 42
    - *2
    - *1
    - *3
    - 42
---
perl: |
    local $YAML::Indent = 1;
    [{qw(foo 42 bar 44)}]
yaml: |
    --- #YAML:1.0
    - bar: 44
      foo: 42
---
perl: |
    local $YAML::Indent = 4;
    [{qw(foo 42 bar 44)}]
yaml: |
    --- #YAML:1.0
    - bar: 44
      foo: 42
---
perl: |
    [qr{bozo$}i]
yaml: |
    --- #YAML:1.0
    - !perl/regexp:
      REGEXP: bozo$
      MODIFIERS: i
---
perl: |
    [undef, undef]
yaml: |
    --- #YAML:1.0
    - ~
    - ~
---
perl: |
    $joe_random_global = [];
    push @$joe_random_global, $joe_random_global;
    bless $joe_random_global, 'XYZ';
    $joe_random_global
yaml: |
    --- #YAML:1.0 &1 !perl/@XYZ
    - *1
---
perl: |
    ['']
yaml: |
    --- #YAML:1.0
    - ''
#---
#perl: |
#    [
#        1/100000000,
#        10**20,
#        -10**20,
#    ]
#yaml: |
#    --- #YAML:1.0
#    - 1e-08
#    - 1e+20
#    - -1e+20
---
perl: |
    [
        23, 
        3.45, 
        123456789012345, 
    ]
yaml: |
    --- #YAML:1.0
    - 23
    - 3.45
    - 123456789012345
#---
#perl: |
#    $joe_random_global = "monkey";
#    [bless \$joe_random_global, "Banana"]
#yaml: |
#    --- #YAML:1.0 
#    - !perl/$Bananas monkey
---
perl: |
    {'foo: bar' => 'baz # boo', 'foo ' => '  monkey', }
yaml: |
    --- #YAML:1.0
    'foo ': '  monkey'
    'foo: bar': 'baz # boo'
---
perl: |
    $a = \\\\\\\\"foo"; $b = $$$$$a;
    ([$a, $b], [$b, $a])
yaml: |
    --- #YAML:1.0
    - !perl/ref:
      =: !perl/ref:
        =: !perl/ref:
          =: !perl/ref:
            =: &1 !perl/ref:
              =: !perl/ref:
                =: !perl/ref:
                  =: !perl/ref:
                    =: foo
    - *1
    --- #YAML:1.0
    - &1 !perl/ref:
      =: !perl/ref:
        =: !perl/ref:
          =: !perl/ref:
            =: foo
    - !perl/ref:
      =: !perl/ref:
        =: !perl/ref:
          =: !perl/ref:
            =: *1
---
no-round-trip: XXX an AutoBless feature could make this rt
perl: |
    $a = YAML::Node->new({qw(a 1 b 2 c 3 d 4)}, 'ingy.com/foo');
    YAML::Node::ynode($a)->keys([qw(d b a)]);
    $a;
yaml: |
    --- #YAML:1.0 !ingy.com/foo
    d: 4
    b: 2
    a: 1
---
no-round-trip: 1
perl: |
    $a = 'bitter buffalo';
    bless \$a, 'Heart';
yaml: |
    --- #YAML:1.0 !perl/$Heart bitter buffalo
