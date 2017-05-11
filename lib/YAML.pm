package YAML;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw( Load Dump );
our @EXPORT_OK = qw( LoadFile DumpFile );

our $VERSION = '1.23_001';

sub import {
    my ($package, @args) = @_;
    for my $arg (@args) {
        if ($arg !~ /^(Load|LoadFile|Dump|DumpFile)$/) {
            # Handle new API; return;
            die __PACKAGE__.':'.__LINE__.": import @_\n";
        }
    }
    $package->export_to_level(1, @args);
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

1;
