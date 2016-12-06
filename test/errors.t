use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 38;
$^W = 1;

use YAML::Error;

filters {
    error => 'regexp',
    yaml => [mutate_yaml => 'yaml_load_error_or_warning' => 'check_yaml'],
    perl => 'perl_eval_error_or_warning',
};

run_like('yaml' => 'error');
run_like('perl' => 'error');

sub mutate_yaml {
    s/\Q<%CNTL-G%>\E/\007/;
    chomp if /msg_no_newline/;
}

sub check_yaml {
    my $yaml = shift;
    return $yaml unless ref($yaml);
    print "YAML actually loaded:\n" . Data::Dumper::Dumper($yaml);
    return '';
}

__DATA__
=== YAML_PARSE_ERR_BAD_CHARS
+++ error: YAML_PARSE_ERR_BAD_CHARS
+++ yaml
# Test msg_bad_chars
---
- foo
# The next line contains an escape character
- bell -><%CNTL-G%><-

=== YAML_PARSE_ERR_BAD_MAJOR_VERSION
+++ error: YAML_PARSE_ERR_BAD_MAJOR_VERSION
+++ yaml
# Test msg_bad_major_version
---
- one
- two
--- #YAML:2.0
- foo
- bar

=== YAML_PARSE_WARN_BAD_MINOR_VERSION
+++ error: YAML_PARSE_WARN_BAD_MINOR_VERSION
+++ yaml
# Test msg_bad_minor_version
---
- one
- two
--- #YAML:1.5
- foo
- bar

=== YAML_PARSE_WARN_MULTIPLE_DIRECTIVES
+++ error: YAML_PARSE_WARN_MULTIPLE_DIRECTIVES
+++ yaml
# Test msg_multiple_directives
--- #YAML:1.0 #YAML:1.0
- foo
--- #FOO:2 #FOO:3
- bar

=== YAML_PARSE_ERR_TEXT_AFTER_INDICATOR
+++ error: YAML_PARSE_ERR_TEXT_AFTER_INDICATOR
+++ yaml
# Test msg_text_after_indicator
---
- >
 This is OK.
- > But this is not
- This is OK

=== YAML_PARSE_ERR_NO_ANCHOR
+++ error: YAML_PARSE_ERR_NO_ANCHOR
+++ yaml
# Test msg_no_anchor
---
- &moo foo
- bar
- *star
- &star far

=== YAML_PARSE_ERR_INCONSISTENT_INDENTATION
+++ error: YAML_PARSE_ERR_INCONSISTENT_INDENTATION
+++ yaml
--- {foo: bar}
- foo
- bar

=== YAML_PARSE_ERR_SINGLE_LINE
+++ error: YAML_PARSE_ERR_SINGLE_LINE
+++ yaml
---
- "foo" bar

=== YAML_PARSE_ERR_BAD_ANCHOR
+++ error: YAML_PARSE_ERR_BAD_ANCHOR
+++ yaml
---
- &X=y 42

=== YAML_PARSE_ERR_BAD_ANCHOR
+++ error: YAML_PARSE_ERR_BAD_ANCHOR
+++ yaml
---
- &

#---
#error: YAML_PARSE_ERR_BAD_NODEX
#load: |
#---
#error: YAML_PARSE_ERR_BAD_EXPLICITX
#load: |
#    I don't think this one can ever happen (yet)
#---
#error: YAML_DUMP_USAGE_DUMPCODE
#code: |
#    local $YAML::DumpCode = [0];
#    Dump(sub { $foo + 42 });

=== YAML_LOAD_ERR_FILE_INPUT
+++ error: YAML_LOAD_ERR_FILE_INPUT
+++ perl
LoadFile('fooxxx');
# XXX - Causing bus error!?!?
#---
#error: YAML_DUMP_ERR_FILE_CONCATENATE
#code: |
#    DumpFile(">> YAML.pod", 42);

=== YAML_DUMP_ERR_FILE_OUTPUT
+++ error: YAML_DUMP_ERR_FILE_OUTPUT
+++ perl
Test::YAML::DumpFile("x/y/z.yaml", 42);

=== YAML_DUMP_ERR_NO_HEADER
+++ error: YAML_DUMP_ERR_NO_HEADER
+++ perl
local $YAML::UseHeader = 0;
Test::YAML::Dump(42);

=== YAML_DUMP_ERR_NO_HEADER
+++ error: YAML_DUMP_ERR_NO_HEADER
+++ perl
local $YAML::UseHeader = 0;
Test::YAML::Dump([]);

=== YAML_DUMP_ERR_NO_HEADER
+++ error: YAML_DUMP_ERR_NO_HEADER
+++ perl
local $YAML::UseHeader = 0;
Test::YAML::Dump({});
#---
#error: xYAML_DUMP_WARN_BAD_NODE_TYPE
#code: |
#    #
#---
#error: YAML_EMIT_WARN_KEYS
#code: |
#    #
#---
#error: YAML_DUMP_WARN_DEPARSE_FAILED
#code: |
#    #
#---
#error: YAML_DUMP_WARN_CODE_DUMMY
#code: |
#     Dump(sub{ 42 });

===  YAML_PARSE_ERR_MANY_EXPLICIT
+++ error: YAML_PARSE_ERR_MANY_EXPLICIT
+++ yaml
---
- !foo !bar 42

=== YAML_PARSE_ERR_MANY_IMPLICIT
+++ error: YAML_PARSE_ERR_MANY_IMPLICIT
+++ yaml
---
- ! ! "42"

=== YAML_PARSE_ERR_MANY_ANCHOR
+++ error: YAML_PARSE_ERR_MANY_ANCHOR
+++ yaml
---
- &foo &bar 42

=== YAML_PARSE_ERR_ANCHOR_ALIAS
+++ error: YAML_PARSE_ERR_ANCHOR_ALIAS
+++ yaml
---
- &bar *foo

=== YAML_PARSE_ERR_BAD_ALIAS
+++ error: YAML_PARSE_ERR_BAD_ALIAS
+++ yaml
---
- *foo=bar

=== YAML_PARSE_ERR_BAD_ALIAS
+++ error: YAML_PARSE_ERR_BAD_ALIAS
+++ yaml
---
- *

=== YAML_PARSE_ERR_MANY_ALIAS
+++ error: YAML_PARSE_ERR_MANY_ALIAS
+++ yaml
---
- *foo *bar

=== YAML_LOAD_ERR_NO_CONVERT
+++ SKIP
Actually this should load into a ynode...
+++ error: YAML_LOAD_ERR_NO_CONVERT
+++ yaml
---
- !foo shoe

=== YAML_LOAD_ERR_NO_DEFAULT_VALUE
+++ error: YAML_LOAD_ERR_NO_DEFAULT_VALUE
+++ yaml
---
- !perl/ref
  foo: bar
#---
#error: YAML_LOAD_ERR_NON_EMPTY_STRING
#load: |
#    ---
#    - !map foo
#---
#error: YAML_LOAD_ERR_NON_EMPTY_STRING
#load: |
#    ---
#    - !seq foo
#---
#error: YAML_LOAD_ERR_BAD_MAP_TO_SEQ
#load: |
#    --- !seq
#    0: zero
#    won: one
#    2: two
#    3: three
#---
#error: YAML_LOAD_ERR_BAD_GLOB
#load: |
#    #
#---
#error: YAML_LOAD_ERR_BAD_REGEXP
#load: |
#    #

=== YAML_LOAD_ERR_BAD_MAP_ELEMENT
+++ error: YAML_LOAD_ERR_BAD_MAP_ELEMENT
+++ yaml
---
foo: bar
bar

=== YAML_LOAD_WARN_DUPLICATE_KEY
+++ error: YAML_LOAD_WARN_DUPLICATE_KEY
+++ yaml
---
foo: bar
bar: boo
foo: baz
boo: bah

=== Test duplicate key message
+++ error: YAML Warning: Duplicate map key 'foo' found. Ignoring.
+++ yaml
---
foo: bar
bar: boo
foo: baz
boo: bah

=== YAML_LOAD_ERR_BAD_SEQ_ELEMENT
+++ error: YAML_LOAD_ERR_BAD_SEQ_ELEMENT
+++ yaml
---
- 42
foo

=== YAML_PARSE_ERR_INLINE_MAP
+++ error: YAML_PARSE_ERR_INLINE_MAP
+++ yaml
---
- {foo:bar}

=== YAML_PARSE_ERR_INLINE_SEQUENCE
+++ error: YAML_PARSE_ERR_INLINE_SEQUENCE
+++ yaml
---
- [foo bar, baz

=== YAML_PARSE_ERR_BAD_DOUBLE
+++ error: YAML_PARSE_ERR_BAD_DOUBLE
+++ yaml
---
- "foo baz

=== YAML_PARSE_ERR_BAD_SINGLE
+++ error: YAML_PARSE_ERR_BAD_SINGLE
+++ yaml
---
- 'foo bar

=== YAML_PARSE_ERR_BAD_INLINE_IMPLICIT
+++ error: YAML_PARSE_ERR_BAD_INLINE_IMPLICIT
+++ yaml
---
- [^gold]

=== YAML_PARSE_ERR_BAD_IMPLICIT
+++ error: YAML_PARSE_ERR_BAD_IMPLICIT
+++ yaml
--- ! >
- 4 foo bar
#---
#error: xYAML_PARSE_ERR_INDENTATION
#load: |
#    ---

=== YAML_PARSE_ERR_INCONSISTENT_INDENTATION
+++ error: YAML_PARSE_ERR_INCONSISTENT_INDENTATION
+++ yaml
---
foo: bar
 bar: baz
#---
#error: xYAML_LOAD_WARN_UNRESOLVED_ALIAS
#load: |
#    ---
#    foo: *bar

# === YAML_LOAD_WARN_NO_REGEXP_IN_REGEXP
# +++ error: YAML_LOAD_WARN_NO_REGEXP_IN_REGEXP
# +++ yaml
# ---
# - !perl/regexp:
#   foo: bar
#
# === YAML_LOAD_WARN_BAD_REGEXP_ELEM
# +++ error: YAML_LOAD_WARN_BAD_REGEXP_ELEM
# +++ yaml
# ---
# - !perl/regexp:
#   REGEXP: foo
#   foo: bar

=== YAML_LOAD_WARN_GLOB_NAME
+++ error: YAML_LOAD_WARN_GLOB_NAME
+++ yaml
---
- !perl/glob:
  foo: bar
#---
#error: xYAML_LOAD_WARN_PARSE_CODE
#load: |
#    ---
#---
#error: YAML_LOAD_WARN_CODE_DEPARSE
#load: |
#    ---
#    - !perl/code |
#      sub { "foo" }
#---
#error: xYAML_EMIT_ERR_BAD_LEVEL
#code:
#    #
#---
#error: YAML_PARSE_WARN_AMBIGUOUS_TAB
#load: |
#    ---
#    - |
#     foo
#    	bar

=== YAML_LOAD_WARN_BAD_GLOB_ELEM
+++ error: YAML_LOAD_WARN_BAD_GLOB_ELEM
+++ yaml
---
- !perl/glob:
  NAME: foo
  bar: SHAME

=== YAML_PARSE_ERR_ZERO_INDENT
+++ error: YAML_PARSE_ERR_ZERO_INDENT
+++ yaml
---
- |0
 foo

=== YAML_PARSE_ERR_NONSPACE_INDENTATION
+++ error: YAML_PARSE_ERR_NONSPACE_INDENTATION
+++ yaml
---
some:
  	data-preceded-with-tab: abc

