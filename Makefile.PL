use inc::Module::Install;

name        'YAML';
all_from    'lib/YAML.pm';
license     'perl';

requires    'perl' => '5.6.0';
requires    'Spiffy' => '0.24';
requires    'Test::Base' => '0.44';

&WriteAll;
