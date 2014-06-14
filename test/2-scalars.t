# This test modified from YAML::Syck suite
use strict;
use Test::More;

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

my $Data = {
    Test => '
    Test Drive D:\\',
};

is_deeply(Load(Dump($Data)), $Data);

if ($^V ge v5.9.0) {
# Large data tests. See also https://bugzilla.redhat.com/show_bug.cgi?id=192400.
    $Data = ' äø<> " \' " \'' x 40_000;
    is(Load(Dump($Data)), $Data);
}

done_testing;
