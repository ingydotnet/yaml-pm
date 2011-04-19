use inc::Module::Install 1.00;

name     'YAML';
author   'Ingy dot Net <ingy@cpan.org>';
all_from 'lib/YAML.pm';
readme_from;
manifest_skip;
version_check;
ack_xxx;

use_test_base;

WriteAll;
