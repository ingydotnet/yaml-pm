package YAML::Loader::Base;
use YAML::Base -Base;

field load_code => 0;

field stream => '';
field document => 0;
field line => 0;
field documents => [];
field lines => [];
field eos => 0;
field done => 0;
field anchor2node => {};
field level => 0;
field offset => [];
field preface => '';
field content => '';
field indent => 0;
field major_version => 0;
field minor_version => 0;
field inline => '';

sub set_global_options {
    no warnings 'once';
    $self->load_code($YAML::LoadCode || $YAML::UseCode);
}

sub load {
    die 'load() not implemented in this class.';
}
