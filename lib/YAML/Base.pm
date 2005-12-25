package YAML::Base;
use Spiffy 0.24 -Base;
our @EXPORT = qw'XXX';

my sub new_error {
    require YAML::Error;

    my $message = shift || 'unknown error';
    my $error = YAML::Error->new(message => $message);
    $error->line($self->line) if $self->can('line');
    $error->document($self->document) if $self->can('document');
    $error->arguments([@_]);
    return $error;
}
    
sub die {
    $self->$new_error(@_)->die;
}

sub warn {
    $self->$new_error(@_)->warn;
}

sub XXX() {
    require Data::Dumper;
    CORE::die(Data::Dumper::Dumper(@_));
}
