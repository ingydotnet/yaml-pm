# This tests the slides I used for YAPC 2002
use lib 't';
use TestYAML;
test_pass(<DATA>);

__DATA__
YAML design goals:
 - YAML documents are very readable by humans.
 - YAML interacts well with scripting languages.
 - YAML uses host languages native data structures.
 - YAML has a consistent information model.
 - YAML enables stream-based processing.
 - YAML is expressive and extensible.
 - YAML is easy to implement.
...
---
scripting languages:
  - Perl
  - Python
  - C
  - Java
standards:
  - RFC0822 (MAIL)
  - RFC1866 (HTML)
  - RFC2045 (MIME) 
  - RFC2396 (URI)
others:
  - SOAP
  - XML
  - SAX
...
---
name: Benjamin
rank: Private
serial number: 1234567890
12:34 PM: My favorite time
...
---
- red
- white
- blue
- pinko
...
---
Fruits:
  - Apples
  - Tomatoes
Veggies:
  - Spinach
  - Broccoli
Meats:
  - Burgers
  - Shrimp
Household:
  - Candles
  - Incense
  - Toilet Duck
...
---
-
  - 3
  - 5
  - 7
-
  - 0
  - 0 
  - 7
-
  - 9
  - 1
  - 1
...
- Intro
-
  Part 1:
    - Up
    - Down
    - Side to Side
- Part 2:
    - Here
    - There
    - Underwear
- Part 3:
    - The Good
    - The Bad
    - The Ingy
...
## comment before document
#--- #DIRECTIVE # comment
#foo: bar # inline comment
#
#phone: number #555-1234
#   ### Comment
#fact: fiction
#---
#blue: bird
## Comment
...
---
simple: look ma, no quotes
quoted:
  - 'Single quoted. Like Perl, no escapes'              
  - "Double quotes.\nLike Perl, has escapes"
  - |
    A YAML block scalar.
    Much like Perl's
    here-document.
...
#---
#simple key: simple value
#this value: can span multiple lines
#  but the key cannot. it would need quotes
#stuff:
#  - foo
#  - 42
#  - 3.14
#  - 192.168.2.98
#  - m/^(.*)\//
...
#---
#'contains: colon': '$19.99'
#or: ' value has leading/trailing whitespace '
#'key spans
#lines': 'double ticks \ for ''escaping'''
...
#---
#The spec says: "The double quoted style variant adds escaping to the 'single quoted' style variant."
#
#like this: "null->\z newline->\n bell->\a
#smiley->\u263a"
#
#self escape: "Brian \"Ingy\" Ingerson"
...
---
what is this: |
    is it: a YAML mapping
    or just: a string

chomp me: |-
    sub foo {
        print "Love me do!";
    }
...
--- #YAML:1.0
old doc: |
  --- #YAML:1.0
  tools:
     - XML
     - XSLT
new doc: |
  --- #YAML:1.0
  tools:
     - YAML
     - cYATL
...
---
- >
    Copyright © 2001 Brian Ingerson, Clark
    Evans & Oren Ben-Kiki, all rights
    reserved. This document may be freely
    copied provided that it is not modified.

    Next paragraph.

- foo
...
---
The YAML Specification starts out by saying: >
  YAML(tm) (rhymes with "camel") is a straightforward
  machine parsable data serialization format designed
  for human readability and interaction with
  scripting languages such as Perl and Python.

     YAML documents are very readable by humans.
     YAML interacts well with scripting languages.
     YAML uses host languages' native data structures. 

  Please join us, the mailing list is at SourceForge.
...
---
? >+
  Even a key can:
    1) Be Folded
    2) Have Wiki

: cool, eh?
...
---
Hey Jude: &chorus
  - na, na, na,
  - &4 na, na, na, na,
  - *4
  - Hey Jude.
  - *chorus
...
headerless: first document
--- #YAML:1.0 #TAB:NONE
--- >
folded top level scalar
--- &1
recurse: *1
---
- simple header
...
#---
#seq: [ 14, 34, 55 ]
#map: {purple: rain, blue: skies}
#mixed: {sizes: [9, 11], shapes: [round]}
#span: {players: [who, what, I don't know],
#       positions: [first, second, third]}
...
## Inline sequences make data more compact
#---
#- [3, 5, 7]
#- [0, 0, 7]
#- [9, 1, 1]
#
## Above is equal to below
#--- [[3, 5, 7], [0, 0, 7], [9, 1, 1]] 
#
## A 3D Matrix
#--- 
#- [[3, 5, 7], [0, 0, 7], [9, 1, 1]] 
#- [[0, 0, 7], [9, 1, 1], [3, 5, 7]] 
#- [[9, 1, 1], [3, 5, 7], [0, 0, 7]] 
...
---
?
 - Kane
 - Kudra
: engaged
[Damian, Dominus]: engaging
...
#same:
#    - 42
#    - !int 42
#    - !yaml.org/int 42
#    - !http://yaml.org/int 42
#perl:
#    - !perl/Foo::Bar {}
#    - !perl.yaml.org/Foo::Bar {}
#    - !http://perl.yaml.org/Foo::Bar {}
...
#---
#- 42           # integer
#- -3.14        # floating point
#- 6.02e+23     # scientific notation
#- 0xCAFEBABE   # hexadecimal int
#- 2001-09-11   # ISO8601 time
#- '2001-09-11' # string
#- +            # boolean true
#- (false)      # alternate boolean
#- ~            # null (undef in Perl)
#- 123 Main St  # string
...
#---
#- !str YAML, YAML, YAML!
#- !int 42
#- !float 0.707
#- !time 2001-12-14T21:59:43.10-05:00
#- !bool 1
#- !null 0
#- !binary MWYNG84BwwEeECcgggoBADs=
...
#---
#- !perl/Foo::Bar {}     # hash-based class
#- !perl/@Foo::Bar []    # array-based class
#- !perl/$Foo::Bar ''    # scalar-based class
#- !perl/glob:           # typeglob
#- !perl/code:           # code reference
#- !perl/ref:            # hard reference
#- !perl/regexp:         # regular expression
#- !perl/regexp:Foo::Bar # blessed regexp
...
--- #YAML:1.0
NAME: AddressEntry
HASH:
  - NAME: Name
    HASH:
      - NAME: First
      - NAME: Last
        OPTIONAL: yes
  - NAME: EmailAddresses
    ARRAY: yes
  - NAME: Phone
    ARRAY: yes
    HASH:
      - NAME: Type
        OPTIONAL: yes
      - NAME: Number
...
--- #YAML:1.0
AddressEntry:
  Name:
    First: Brian
  EmailAddresses:
    - ingy@CPAN.org
    - ingy@ttul.org
  Phone:
   - Type: Work
     Number: 604-333-4567
   - Number: 843-444-5678
