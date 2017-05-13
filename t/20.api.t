use strict;
use warnings;
use Test::More;

use YAML 'yaml';
use XXX -with => 'Data::Dumper';

ok defined &yaml, "&yaml function was exported";

isa_ok yaml(), 'YAML::API', 'yaml() function returns a YAML::API object';

ok yaml()->can('load'), 'YAML::API has a ->load() method';

my $yaml = <<'...';
foo: 42
bar:
- abc
- 123
...

isa_ok yaml->load($yaml), 'HASH';

done_testing;
