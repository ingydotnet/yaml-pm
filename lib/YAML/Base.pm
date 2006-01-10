package YAML::Base;
use Spiffy 0.25 -Base;

our @EXPORT = qw(
    XXX
);

# Use lexical subs to reduce pollution of private methods by base class.
my ($_new_error, $_info, $_scalar_info);

sub XXX() {
    require Data::Dumper;
    CORE::die(Data::Dumper::Dumper(@_));
}

sub die {
    my $error = $self->$_new_error(@_);
    $error->type('Error');
    Carp::croak($error->format_message);
}

sub warn {
    return unless $^W;
    my $error = $self->$_new_error(@_);
    $error->type('Warning');
    Carp::cluck($error->format_message);
}

# This code needs to be refactored to be simpler and more precise, and no,
# Scalar::Util doesn't DWIM.
#
# Can't handle:
# * blessed regexp
sub node_info {
    my $stringify = $_[1] || 0;
    my ($class, $type, $id) =
        ref($_[0])
        ? $stringify
          ? &$_info("$_[0]")
          : do {
              require overload;
              my @info = &$_info(overload::StrVal($_[0]));
              if (ref($_[0]) eq 'Regexp') {
                  @info[0, 1] = (undef, 'REGEXP');
              }
              @info;
          }
        : &$_scalar_info($_[0]);
    ($class, $type, $id) = &$_scalar_info("$_[0]")
        unless $id;
    return wantarray ? ($class, $type, $id) : $id;
}

#-------------------------------------------------------------------------------
$_info = sub {
    return (($_[0]) =~ qr{^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$}o);
};

$_scalar_info = sub {
    my $id = 'undef';
    if (defined $_[0]) {
        \$_[0] =~ /\((\w+)\)$/o or CORE::die();
        $id = "$1-S";
    }
    return (undef, undef, $id);
};

$_new_error = sub {
    my $self = shift;
    require YAML::Error;
    require Carp;

    my $code = shift || 'unknown error';
    my $error = YAML::Error->new(code => $code);
    $error->line($self->line) if $self->can('line');
    $error->document($self->document) if $self->can('document');
    $error->arguments([@_]);
    return $error;
};
    
__END__

=head1 NAME

YAML::Base - Base class for YAML classes

=head1 SYNOPSIS

    package YAML::Something;
    use YAML::Base -base;

=head1 DESCRIPTION

YAML::Base is the parent of all YAML classes. YAML::Base itself inherits
from Spiffy.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
