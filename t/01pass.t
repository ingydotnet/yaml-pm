# This simply tests that a given piece of YAML parses
use lib 't';
use TestYAML;
test_pass(<DATA>);

__DATA__
---
foo:
    bar:
          baz:
                  poo: bah
...
--- 42
...
# comment
--- 42
# comment
...
--- [1, 2, 3]
...
--- {foo: bar, bar: 42}
...
--- !foo.com/bar
- 2
...
--- &1 !foo.com/bar
- 42
...
---
  - 40
  - 41
  - foof
#...
#--- #TAB:8
#	- 42
#	- 43
