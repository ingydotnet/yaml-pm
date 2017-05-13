package YAML::API;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
}

sub load {
    my ($self, $input) = @_;
    require YAML::PP::Loader;
    require YAML::PP::Parser;
    require YAML::Reader;
    my $reader = YAML::Reader->new(
        input => $input
    );
    my $parser = YAML::PP::Parser->new(
        reader => $reader,
    );
    my $loader = YAML::PP::Loader->new(
        parser => $parser,
    );
    return $loader->load;
}

1;
