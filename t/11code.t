use lib 't';
use TestYAML;
test_round_trip(<DATA>);

__DATA__
---
no-round-trip: XXX probably a test-driver bug
config: |
    local $YAML::DumpCode = 1
perl: |
    return sub { 42 }
yaml: |
    --- #YAML:1.0 !perl/code: |
    {
        42;
    }
---
no-round-trip: XXX probably a test-driver bug
config: |
    local $YAML::DumpCode = 1
perl: |
    $joe_random_global = sub { 42 };
    [$joe_random_global, $joe_random_global, $joe_random_global]
yaml: |
    --- #YAML:1.0
    - &1 !perl/code: |
      {
          42;
      }
    - *1
    - *1
# XXX Known TODO, right?
#---
#perl: |
#    bless sub { 42 }, 'Foo::Bar'
#yaml: |
#    --- #YAML:1.0 !perl/code:Foo::Bar '{ "DUMMY" }'
---
perl: |
    sub { 42 }
yaml: |
    --- #YAML:1.0 !perl/code: '{ "DUMMY" }'
---
no-round-trip: XXX probably a YAML TODO
config: |
    local $YAML::DumpCode = 1
perl: |
    bless sub { 42 }, "Foo::Bar"
yaml: |
    --- #YAML:1.0 !perl/code:Foo::Bar |
    {
        42;
    }
