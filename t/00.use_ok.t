use strict;
use warnings;
use Test::More;

my @real_modules = qw(
    YAML::Any
    YAML
);

my @proxy_modules = qw(
    YAML::Dumper::Base
    YAML::Dumper
    YAML::Error
    YAML::Loader::Base
    YAML::Loader
    YAML::Marshall
    YAML::Mo
    YAML::Node
    YAML::Tag
    YAML::Types
);

for my $module (@real_modules) {
    use_ok($module);
}

for my $module (@proxy_modules) {
    eval "use $module; 1";
    like $@, qr/NOTICE: YAML::(\S+) has been moved to YAML::Old::\1./,
        "Proxy module $module dies properly";
}

done_testing @real_modules + @proxy_modules;
