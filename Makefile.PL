use inc::Module::Install;

name('YAML');
version_from('lib/YAML.pm');
license('perl');

requires('perl' => '5.6.0');
requires('Spiffy' => '0.10');

&WriteAll;
