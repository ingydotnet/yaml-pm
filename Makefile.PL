use inc::Module::Install;

name            'YAML';
all_from        'lib/YAML.pm';
license         'perl';

requires        'perl' => '5.6.1';
build_requires  'Test::Base' => '0.47';
include         'Test::Base';
include         'Test::Base::Filter';

install_script  'ysh';

WriteAll;
