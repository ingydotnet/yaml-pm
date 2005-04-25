use inc::Module::Install;

name('YAML');
author('Brian Ingerson <ingy@cpan.org>');
abstract("YAML Ain't Markup Language");
license('perl');
version_from('lib/YAML.pm');

requires(qw(
    perl 5.5.3
));
build_requires(qw(
    Test::More 0.54
));

install_script('ysh');

check_nmake();

&WriteAll();
