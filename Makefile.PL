use inc::Module::Install;

name            'YAML';
all_from        'lib/YAML.pm';
license         'perl';

requires        'perl' => '5.6.1';
requires        'Spiffy' => '0.26';
requires        'Test::Base' => '0.46';
requires        'Test::More' => '0.62';

install_script  'ysh';

&WriteAll;
