package t::TestYAML;
use Test::Base -Base;
use lib 'lib';
use YAML '0.49_60';

delimiters('===', '+++');

package t::TestYAML::Filter;
use base 'Test::Base::Filter';

sub yaml_dump {
    return YAML::Dump(@_);
}

sub yaml_load {
    return YAML::Load(@_);
}


sub yaml_load_or_fail {
    $self->assert_scalar(@_);
    my $yaml = shift;
    my $result = eval {
        YAML::Load($yaml);
    };
    return $@ || $result;
}
