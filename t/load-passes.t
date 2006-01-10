use t::TestYAML tests => 8;

run_load_passes();

__DATA__
===
+++ yaml
---
foo:
    bar:
          baz:
                  poo: bah


===
+++ yaml
--- 42


===
+++ yaml
# comment
--- 42
# comment


===
+++ yaml
--- [1, 2, 3]


===
+++ yaml
--- {foo: bar, bar: 42}


===
+++ yaml
--- !foo.com/bar
- 2


===
+++ yaml
--- &1 !foo.com/bar
- 42


===
+++ yaml
---
  - 40
  - 41
  - foof
