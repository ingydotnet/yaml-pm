use strict;
use warnings;
use Test::More;

use YAML 'yaml';

ok defined &yaml, "&yaml function was exported";

isa_ok yaml(), 'YAML::API', 'yaml() function returns a YAML::API object';

ok yaml()->can('load'), 'YAML::API has a ->load() method';

ok yaml()->can('loader'), 'YAML::API has a ->loader() method';

isa_ok yaml()->loader(), 'YAML::Perl::Loader',
    'yaml() function returns a YAML::API object';

done_testing;
