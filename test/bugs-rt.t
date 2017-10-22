use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 42;

run_yaml_tests;

__DATA__

=== Ticket #105-A YAML doesn't serialize odd objects very well
+++ skip_this_for_now
+++ skip_unless_modules: FileHandle
+++ perl: FileHandle->new( ">/tmp/yaml_bugs_rt_$$" );
+++ yaml
--- !!perl/io:FileHandle
- xxx

=== Ticket #105-B YAML doesn't serialize odd objects very well
+++ skip_unless_modules: URI
+++ no_round_trip
+++ perl: URI->new( "http://localhost/" )
+++ yaml
--- !!perl/scalar:URI::http http://localhost/

=== Ticket #105-C YAML doesn't serialize odd objects very well
+++ skip_unless_modules: URI
+++ perl: +{ names => ['james','alexander','duncan'], }
+++ yaml
---
names:
  - james
  - alexander
  - duncan

=== Ticket #105-D YAML doesn't serialize odd objects very well
+++ perl
# CGI->new()
bless {
    '.charset' => 'ISO-8859-1',
    '.fieldnames' => {},
    '.parameters' => [],
    escape => 1,
}, 'CGI';
+++ yaml
--- !!perl/hash:CGI
.charset: ISO-8859-1
.fieldnames: {}
.parameters: []
escape: 1

=== Ticket #105-E YAML doesn't serialize odd objects very well
+++ perl
package MyObj::Class;
sub new { return bless ['one','two','three'], $_[0]; }
package main;
MyObj::Class->new();
+++ yaml
--- !!perl/array:MyObj::Class
- one
- two
- three



=== Ticket #2957 Serializing array-elements with dashes
[github #36] The problem is quoted map keys in array elements
+++ perl: [ { "test - " => 23 } ];
+++ yaml
---
- 'test - ': 23


=== Ticket #3015 wish: folding length option for YAML
+++ skip_this_for_now
> YAML.pm, line 557, currently has a folding value of 50 hard-coded.
> It would be great if this value became an option... for those who
> prefer not to fold, or fold less.

I wanted that too.  The attached patch adds in the $YAML::FoldLimit
config variable to achieve this.  I've also got a doc patch which
describes this, but 'RT' only has one file-upload field so that'll be in
the next comment ...

Smylers


=== Ticket #4066 Number vs. string heuristics for dump
+++ perl: { 'version' => '1.10' };
+++ yaml
---
version: 1.10



=== Ticket #4784 Can't create YAML::Node from 'REF'
+++ skip_this_for_now
+++ perl: my $bar = 1; my $foo = \\\$bar; bless $foo, "bar"
+++ yaml



=== Ticket #4866 Text with embedded newlines
+++ perl
{'text' => 'Bla:

- Foo
- Bar
'};
+++ yaml
---
text: "Bla:\n\n- Foo\n- Bar\n"



=== Ticket #5299 Load(Dump({"hi, world" => 1})) fails
+++ perl: {"hi, world" => 1}
+++ yaml
---
'hi, world': 1



=== Ticket #5691 Minor doc error in YAML.pod
+++ perl: "YAML:1.0"
+++ yaml
--- YAML:1.0



=== Ticket #6095 Hash keys are not always escaped
+++ perl: { 'AVE,' => { '??' => { '??' => 1 } } }
+++ yaml
---
'AVE,':
  '??':
    '??': 1



=== Ticket #6139 0.35 can't deserialize blessed scalars
+++ perl: my $x = "abc"; bless \ $x, "ABCD";
+++ yaml
--- !!perl/scalar:ABCD abc



=== Ticket #7146 scalar with many spaces doesn't round trip
+++ skip_this_for_now
Can't get this to work yet.
+++ perl: "A".(" "x200)."B"
+++ yaml
--- 'A                                                                                                                                                                                                        B'




=== Ticket #8795 !!perl/code blocks are evaluated in package main
+++ skip_this_for_now
This test passes but not sure if this totally represents what was being
reported. Check back later.
+++ perl: $YAML::UseCode = 1; package Food; sub { 42; }
+++ no_round_trip
+++ yaml
--- !!perl/code |
sub {
    package Food;
    use warnings;
    use strict 'refs';
    42;
}


=== Ticket #8818 YAML::Load fails if the last value in the stream ends with '|'
+++ perl: ['o|']
+++ yaml
---
- 'o|'



=== Ticket #12729 < and > need to be quoted ?
+++ perl: { a => q(>a), b => q(<b), c => q(<c>)}
+++ yaml
---
a: '>a'
b: <b
c: '<c>'



=== Ticket #12770 YAML crashes when tab used for indenting
+++ skip_this_for_now
Even in the latest version, 0.39, YAML fails when tabulator characters are used for
indenting. This is expected since the YAML spec forbids this use of tab characters.
However, there is no error message; YAML.pm just dies. Here's an example:

    perl -MYAML -e "Load(\"Testing:\n\t- Item1\n\")"

fails with

Died at U:\perl-lib\lib/YAML.pm line 1417.

It should at least fail with a message like it does when there's no newline at the
end:
+++ perl



=== Ticket #12959-a bug - nested inline collections with extra blanks
+++ function: load_passes
+++ yaml
--- { a: {k: v} }

=== Ticket #12959-b bug - nested inline collections with extra blanks
+++ function: load_passes
+++ yaml
--- { a: [1] }

=== Ticket #12959-c bug - nested inline collections with extra blanks
+++ function: load_passes
+++ yaml
--- [ {k: v} ]

=== Ticket #12959-d bug - nested inline collections with extra blanks
+++ function: load_passes
+++ yaml
--- [ [1] ]



=== Ticket #13016 Plain Multiline Support
+++ skip_this_for_now
Fix in upcoming release
+++ function: load_passes
+++ yaml
quoted: "So does this
  quoted scalar.\n"



=== #13500 Load(Dump("|foo")) fails
+++ perl: "|foo"
+++ yaml
--- '|foo'



=== Ticket #13510 Another roundtrip fails
[github #48] The problem is quoted map keys in array elements
+++ perl
[{'RR1 (Schloﬂplatz - Wannsee)'=> 1,
'm‰ﬂiges Kopfsteinpflaster (Teilstrecke)' => 1},
undef,
]
+++ yaml
---
- 'RR1 (Schloﬂplatz - Wannsee)': 1
  m‰ﬂiges Kopfsteinpflaster (Teilstrecke): 1
- ~



=== Ticket #14938 Load(Dump(">=")) fails
+++ perl: ">="
+++ yaml
--- '>='
