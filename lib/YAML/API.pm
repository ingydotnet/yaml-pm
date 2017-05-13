package YAML::API;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    # TODO check %args
    my $self = bless { %args }, $class;
    return $self;
}

sub load {
}

sub loader {
}

1;
