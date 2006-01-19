use inc::Module::Install;

name            'YAML';
all_from        'lib/YAML.pm';
license         'perl';

requires        'perl' => '5.6.1';
requires        'Class::Spiffy' => '0.12';
requires        'Test::Base' => '0.47';

install_script  'ysh';

WriteAll;
