use lib 't';
use TestYAML;
test_errors(<DATA>);

__DATA__
---
error: YAML_PARSE_ERR_BAD_CHARS
load: |
    # Test msg_bad_chars
    ---
    - foo
    # The next line contains an escape character
    - bell -><%CNTL-G%><-
---
error: YAML_PARSE_ERR_NO_FINAL_NEWLINE
load: |-
    # Test msg_no_newline
    ---
    - one
    - two
    - three
---
error: YAML_PARSE_ERR_BAD_MAJOR_VERSION
load: |
    # Test msg_bad_major_version
    ---
    - one
    - two
    --- #YAML:2.0
    - foo
    - bar
---
error: YAML_PARSE_WARN_BAD_MINOR_VERSION
load: |
    # Test msg_bad_minor_version
    ---
    - one
    - two
    --- #YAML:1.5
    - foo
    - bar
---
error: YAML_PARSE_WARN_MULTIPLE_DIRECTIVES
load: |
    # Test msg_multiple_directives
    --- #YAML:1.0 #YAML:1.0
    - foo
    --- #FOO:2 #FOO:3
    - bar
---
error: YAML_PARSE_ERR_TEXT_AFTER_INDICATOR
load: |
    # Test msg_text_after_indicator
    ---
    - >
     This is OK.
    - > But this is not
    - This is OK
---
error: YAML_PARSE_ERR_NO_ANCHOR
load: |
    # Test msg_no_anchor
    ---
    - &moo foo
    - bar
    - *star
    - &star far
---
error: YAML_PARSE_ERR_INCONSISTENT_INDENTATION
load: |
    --- {foo: bar}
    - foo
    - bar
---
error: YAML_PARSE_ERR_SINGLE_LINE
load: |
    ---
    - "foo" bar
---
error: YAML_PARSE_ERR_BAD_ANCHOR
load: |
    ---
    - &X=y 42
---
error: YAML_DUMP_ERR_INVALID_INDENT
code: |
    local $YAML::Indent = '4 monkees';
    YAML::Dump(42);
---
error: YAML_LOAD_USAGE
code: |
    Load('foo', 'bar');
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
#    YAML::Dump(sub { $foo + 42 });
---
error: YAML_LOAD_ERR_FILE_INPUT
code: |
    YAML::LoadFile('fooxxx');
# XXX - Causing bus error!?!?
#---
#error: YAML_DUMP_ERR_FILE_CONCATENATE
#code: |
#    YAML::DumpFile(">> YAML.pod", 42);
---
error: YAML_DUMP_ERR_FILE_OUTPUT
code: |
    YAML::DumpFile("x/y/z.yaml", 42);
---
error: YAML_DUMP_ERR_NO_HEADER
code: |
    local $YAML::UseHeader = 0;
    YAML::Dump(42);
---
error: YAML_DUMP_ERR_NO_HEADER
code: |
    local $YAML::UseHeader = 0;
    YAML::Dump([]);
---
error: YAML_DUMP_ERR_NO_HEADER
code: |
    local $YAML::UseHeader = 0;
    YAML::Dump({});
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
#     YAML::Dump(sub{ 42 });
--- 
error: YAML_PARSE_ERR_MANY_EXPLICIT
load: |
    ---
    - !foo !bar 42
---
error: YAML_PARSE_ERR_MANY_IMPLICIT
load: |
    ---
    - ! ! "42"
---
error: YAML_PARSE_ERR_MANY_ANCHOR
load: |
    ---
    - &foo &bar 42
---
error: YAML_PARSE_ERR_ANCHOR_ALIAS
load: |
    ---
    - &bar *foo
---
error: YAML_PARSE_ERR_BAD_ALIAS
load: |
    ---
    - *foo=bar
---
error: YAML_PARSE_ERR_MANY_ALIAS
load: |
    ---
    - *foo *bar
---
error: YAML_LOAD_ERR_NO_CONVERT
load: |
    ---
    - !foo shoe
---
error: YAML_LOAD_ERR_NO_DEFAULT_VALUE
load: |
    ---
    - !perl/ref:
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
---
error: YAML_LOAD_ERR_BAD_STR_TO_INT
load: |
    ---
    - !int foo
---
error: YAML_LOAD_ERR_BAD_STR_TO_DATE
load: |
    ---
    - !date hot
---
error: YAML_LOAD_ERR_BAD_STR_TO_TIME
load: |
    ---
    - !time to get ill
---
error: YAML_LOAD_ERR_BAD_MAP_ELEMENT
load: |
    ---
    foo: bar
    bar
---
error: YAML_LOAD_WARN_DUPLICATE_KEY
load: |
    ---
    foo: bar
    bar: boo
    foo: baz
    boo: bah
---
error: YAML_LOAD_ERR_BAD_SEQ_ELEMENT
load: |
    ---
    - 42
    foo
---
error: YAML_PARSE_ERR_INLINE_MAP
load: |
    ---
    - {foo:bar}
---
error: YAML_PARSE_ERR_INLINE_SEQUENCE
load: |
    ---
    - [foo bar, baz
---
error: YAML_PARSE_ERR_BAD_DOUBLE
load: |
    ---
    - "foo baz
---
error: YAML_PARSE_ERR_BAD_SINGLE
load: |
    ---
    - 'foo bar
---
error: YAML_PARSE_ERR_BAD_INLINE_IMPLICIT
load: |
    ---
    - [^gold]
---
error: YAML_PARSE_ERR_BAD_IMPLICIT
load: |
    --- ! >
    - 4 foo bar
#---
#error: xYAML_PARSE_ERR_INDENTATION
#load: |
#    ---
---
error: YAML_PARSE_ERR_INCONSISTENT_INDENTATION
load: |
    ---
    foo: bar
     bar: baz
#---
#error: xYAML_LOAD_WARN_UNRESOLVED_ALIAS
#load: |
#    ---
#    foo: *bar
---
error: YAML_LOAD_WARN_NO_REGEXP_IN_REGEXP 
load: |
    ---
    - !perl/regexp:
      foo: bar
---
error: YAML_LOAD_WARN_BAD_REGEXP_ELEM 
load: |
    ---
    - !perl/regexp:
      REGEXP: foo
      foo: bar
---
error: YAML_LOAD_WARN_REGEXP_CREATE 
load: |
    ---
    - !perl/regexp:
      REGEXP: "(foo"
---
error: YAML_LOAD_WARN_GLOB_NAME 
load: |
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
#    - !perl/code: |
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
---
error: YAML_LOAD_WARN_BAD_GLOB_ELEM 
load: |
    ---
    - !perl/glob:
      NAME: foo
      bar: SHAME
---
error: YAML_PARSE_ERR_ZERO_INDENT 
load: |
    ---
    - |0
     foo
