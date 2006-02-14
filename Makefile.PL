use inc::Module::Install;

name            'YAML';
all_from        'lib/YAML.pm';

use_test_base;

install_script  'ysh';

WriteAll;
