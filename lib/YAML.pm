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
        if ($arg !~ /^(Load|LoadFile|Dump|DumpFile|freeze|thaw)$/) {
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

sub freeze {
    require YAML::Old;
    goto &YAML::Old::freeze;
}

sub Blessed {
    require YAML::Old;
    goto &YAML::Old::Blessed;
}

sub Bless {
    require YAML::Old;
    goto &YAML::Old::Bless;
}

sub thaw {
    require YAML::Old;
    goto &YAML::Old::thaw;
}

1;
