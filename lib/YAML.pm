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

=pod

=encoding utf-8

=head1 NAME

YAML - YAML Ain't Markup Language™

=head1 STATUS

L<YAML> is undergoing changes that will make it the future gateway to almost
all (new and old) YAML functionality, while at the same time working almost
exactly the same for existing code.

See
L<https://github.com/ingydotnet/yaml-old-pm/blob/master/doc/yaml-old-transition.md#yaml-to-yamlold-transition>
for details.

    use YAML;

    my $yaml = "foo: 42\n";
    my $hash = Load $yaml;
    $hash->{bar} = 44;
    $yaml = Dump $hash;

=head1 DESCRIPTION

YAML is a human friendly data serialization language with implementations in
many programming languages.

YAML.pm is Perl 5's first YAML module. Written in 2001, that code has been
moved to L<YAML::Old> an L<YAML> is now the API frontend to various YAML
backends.

NOTE: This is a current WIP and more doc will follow as things develop.

=head1 AUTHORS

=over

=item Ingy döt Net <ingy@cpan.org>

=item Tina Müller <cpan2@tinita.de>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2001-2017. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
