use lib 't';
use TestYAML;
test_round_trip(<DATA>);

__DATA__
---
perl: |
    ['foo ' x 20]
yaml: |
    --- #YAML:1.0
    - >-
      foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo foo
      foo 
---
perl: |
    [q{YAML(tm) (rhymes with "camel") is a straightforward machine parsable data serialization format designed for human readability and interaction with scripting languages such as Perl and Python. YAML is optimized for data serialization, configuration settings, log files, Internet messaging and filtering. YAML(tm) is a balance of the following design goals:}]
yaml: |
    --- #YAML:1.0
    - >-
      YAML(tm) (rhymes with "camel") is a straightforward machine parsable data
      serialization format designed for human readability and interaction with
      scripting languages such as Perl and Python. YAML is optimized for data
      serialization, configuration settings, log files, Internet messaging and
      filtering. YAML(tm) is a balance of the following design goals:
---
perl: |
    [q{It reads one character at a time, with the ability to push back any number of characters up to a maximum, and with nested mark() / reset() / unmark() functions. The input of the stream reader is any java.io.Reader. The output are characters.
    The parser (and event generator)
    The input of the parser are characters. These characters are directly fed into the functions that implement the different productions. The output of the parser are events, a well defined and small set of events.}]
yaml: |
    --- #YAML:1.0
    - ! >-
      It reads one character at a time, with the ability to push back any number
      of characters up to a maximum, and with nested mark() / reset() / unmark()
      functions. The input of the stream reader is any java.io.Reader. The output
      are characters.
      
      The parser (and event generator)
      
      The input of the parser are characters. These characters are directly fed
      into the functions that implement the different productions. The output of
      the parser are events, a well defined and small set of events.
---
perl: |
    <<END;
    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
      1) xxx xxx xxx xxx 
      2) xxx xxx xxx xxx 
    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
    END
yaml: |
    --- #YAML:1.0 >
    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
    xxx xxx xxx xxx xxx xxx xxx xxx xxx

    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
    xxx xxx xxx xxx xxx xxx xxx xxx xxx
      1) xxx xxx xxx xxx 
      2) xxx xxx xxx xxx 
    xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx xxx
    xxx xxx xxx xxx xxx xxx xxx xxx xxx
---
config: |
    local $YAML::UseFold = 1
perl: |
    <<END;
    xxx xxx xxx xxx
    xxx xxx xxx xxx

      1) xxx xxx xxx xxx 
      2) xxx xxx xxx xxx 

    xxx xxx xxx xxx
    END
yaml: |
    --- #YAML:1.0 >
    xxx xxx xxx xxx

    xxx xxx xxx xxx

      1) xxx xxx xxx xxx 
      2) xxx xxx xxx xxx 

    xxx xxx xxx xxx
---
config: |
    local $YAML::UseFold = 1
perl: |
    <<END;
    xxx xxx xxx xxx
      1) xxx xxx xxx xxx 

      2) xxx xxx xxx xxx 
    xxx xxx xxx xxx
    END
yaml: |
    --- #YAML:1.0 >
    xxx xxx xxx xxx
      1) xxx xxx xxx xxx 

      2) xxx xxx xxx xxx 
    xxx xxx xxx xxx
---
perl: |
    "xxx xxx xxx xxx xxx xxx xxx xxx xxx xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx xxx xxx xxx xxx xxx xxx xxx xxx\n"
yaml: |
    --- #YAML:1.0 >
    xxx xxx xxx xxx xxx xxx xxx xxx xxx
    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx xxx xxx xxx xxx xxx xxx
    xxx xxx
---
perl: |
    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx xxx xxx xxx xxx xxx xxx xxx xxx\n"
yaml: |
    --- #YAML:1.0 >
    xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    xxx xxx xxx xxx xxx xxx xxx xxx
---
config: |
    local $YAML::UseFold = 1
perl: |
    "xxx xxx xxx xxx\n\n"
yaml: |+
    --- #YAML:1.0 >+
    xxx xxx xxx xxx

---
config: |
    local $YAML::ForceBlock = 1
perl: |
    "xxx xxx xxx xxx\n\n"
yaml: |+
    --- #YAML:1.0 |+
    xxx xxx xxx xxx

