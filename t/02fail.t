# This simply tests that a given piece of invalid YAML fails to parse
use lib 't';
use TestYAML;
test_fail(<DATA>);

__DATA__
--- |\
foo\zbar
...
--- @ 42
...
---
 - 1
  -2
...
--- #TAB:MOBY
- foo
