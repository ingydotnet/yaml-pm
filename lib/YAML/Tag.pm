package YAML::Tag;
use strict;

sub new {
    my ($class, $self) = @_;
    bless \$self, $class;
}

sub short {
    ${$_[0]};
}

sub canonical {
    ${$_[0]};
}

1;
