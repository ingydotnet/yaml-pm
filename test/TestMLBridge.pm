package TestMLBridge;

use base 'TestML::Bridge';

use YAML;

# use XXX;

sub yaml_dump {
    my $self = shift;

    return YAML::Dump(@_);
}

sub yaml_dump_ok {
    my $self = shift;

    YAML::Dump(@_);

    return 1;
}

sub yaml_load {
    my ($self, $yaml) = @_;
    local $YAML::Numify = 1;

    return YAML::Load($yaml);
}

sub perl_eval {
    my ($self, $perl) = @_;

    return eval($perl);
}

sub dumper() {
    my $self = shift;

    require Data::Dumper;

    $Data::Dumper::Sortkeys = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;

    return Data::Dumper::Dumper(@_);
}

1;
