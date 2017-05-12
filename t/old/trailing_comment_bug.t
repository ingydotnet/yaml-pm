use strict;
use warnings;

# todo test for github issue:
# Trailing comments aren't ignored #143

# https://github.com/ingydotnet/yaml-pm/issues/143

use Test::More tests => 1;

use YAML;

TODO: {

	local $TODO = 'This bug only happens when using YAML (YAML::Old) dist.';

	is( Load ("--- 123 # comment\n"), '123', 'Ignore trailing comment');

}
