use inc::Module::Install;

name            'YAML';
all_from        'lib/YAML.pm';

requires        'perl' => '5.6.1';

use_test_base;

install_script  'ysh';

WriteAll;
