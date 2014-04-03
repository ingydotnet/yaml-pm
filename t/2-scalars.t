# This test modified from YAML::Syck suite
use strict;
use Test::More tests => 11;

require YAML;
YAML->import;

is(Dump(42),    "--- 42\n");
is(Load("--- 42\n"), 42);

is(Dump(undef), "--- ~\n");
is(Load("--- ~\n"), undef);
is(Load("---\n"), undef);
is(Load("--- ''\n"), '');

is(Load("--- true\n"), "true");
is(Load("--- false\n"), "false");

# $YAML::Syck::ImplicitTyping = $YAML::Syck::ImplicitTyping = 1;
#
# is(Load("--- true\n"), 1);
# is(Load("--- false\n"), '');

my $Data = '"Test Drive D:\\" Example';
is(Load(Dump($Data)), $Data);

$Data = '"Test Drive D:\\"';
is(Load(Dump($Data)), $Data);

$Data = '"'. ( 'TEST' x 1_000_000 ) .'"';
is(Load(Dump($Data)), $Data);