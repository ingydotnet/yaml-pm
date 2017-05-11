package YAML;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(Load Dump);

our $VERSION = '1.23_001';

sub import {
    my $package = shift;
    if (not @_) {
        $package->export_to_level(1, @_);
    }
    else {
        warn __PACKAGE__.':'.__LINE__.": import @_\n";
    }
}

sub Load {
    require YAML::Old;
    goto &YAML::Old::Load;
}

sub Dump {
    require YAML::Old;
    goto &YAML::Old::Dump;
}

1;
