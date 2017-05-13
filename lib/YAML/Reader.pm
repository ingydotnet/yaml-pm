package YAML::Reader;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
}

sub read {
    my ($self) = @_;
    return $self->{input};
}

1;
