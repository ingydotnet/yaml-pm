use strict;
use warnings;
use Test::More tests => 1;

use YAML ();
use YAML::Any ();

cmp_ok(YAML->VERSION, 'eq', YAML::Any->VERSION, "YAML::Any version equals YAML version");
