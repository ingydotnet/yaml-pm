# This test modified from YAML::Syck suite
use strict;
use Test::More tests => 11;

require YAML;
ok(YAML->VERSION);
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

# Large data tests. See also https://bugzilla.redhat.com/show_bug.cgi?id=192400.
my $Data = 'äø<>"\'' x 40_000;
is(Load(Dump($Data)), $Data);

$Data ='a' x 50_000;
is(Load("--- \"$Data\"\n"), $Data);