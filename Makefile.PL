use inc::Module::Install;

print << '_';

*** WARNING ***

This release breaks compatibility with versions earlier than version 0.60 of
YAML::Syck and YAML.pm when serializing blessed references.

See the COMPATIBILITY file for more information.

_

if (!is_admin()) {
    exit() unless prompt("Continue installing YAML.pm?", 'y') =~ /^y/i;
}

name            'YAML';
all_from        'lib/YAML.pm';

use_test_base;

install_script  'ysh';

WriteAll;
