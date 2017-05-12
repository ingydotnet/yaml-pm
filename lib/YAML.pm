package YAML;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw( Load Dump );
our @EXPORT_OK = qw( LoadFile DumpFile freeze thaw );

our $VERSION = '1.23_001';

sub import {
    my ($package, @args) = @_;
    for my $arg (@args) {
        if ($arg !~ /^(Load|LoadFile|Dump|DumpFile|freeze|thaw|Bless|Blessed)$/) {
            # Handle new API; return;
            die __PACKAGE__.':'.__LINE__.": import @_\n";
        }
    }
    YAML->export_to_level(1, $package, @args);
}

sub Load {
    require YAML::Old;
    goto &YAML::Old::Load;
}

sub Dump {
    require YAML::Old;
    goto &YAML::Old::Dump;
}

sub LoadFile {
    require YAML::Old;
    goto &YAML::Old::LoadFile;
}

sub DumpFile {
    require YAML::Old;
    goto &YAML::Old::DumpFile;
}

sub thaw {
    require YAML::Old;
    goto &YAML::Old::thaw;
}

sub freeze {
    require YAML::Old;
    goto &YAML::Old::freeze;
}

sub Bless {
    require YAML::Old;
    goto &YAML::Old::Bless;
}

sub Blessed {
    require YAML::Old;
    goto &YAML::Old::Blessed;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

YAML - YAML Aint Markup Language™

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

