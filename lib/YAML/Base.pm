package YAML::Base;
$VERSION = '0.50';
@EXPORT = qw(
    NONE SCALAR SEQUENCE MAPPING BLOCK FLOW
    PLAIN SINGLE DOUBLE LITERAL FOLDED
);
use strict;
use Spiffy '-base';
use overload;

use constant NONE => 0;
use constant SCALAR => 2 ** 0;
use constant SEQUENCE => 2 ** 1;
use constant MAPPING => 2 ** 2;
use constant BLOCK => 2 ** 3;
use constant FLOW => 2 ** 4;
use constant PLAIN => 2 ** 5;
use constant SINGLE => 2 ** 6;
use constant DOUBLE => 2 ** 7;
use constant LITERAL => 2 ** 8;
use constant FOLDED => 2 ** 9;

sub XXX {
    my $self = shift;
    require Data::Dumper;
    require Carp;
    $Data::Dumper::Indent = 1;
    Carp::croak(Data::Dumper::Dumper(@_));
}

# common serial api
my %push_api = map {($_, 1)} qw(
    start_stream
    end_stream
    start_document
    end_document
    start_mapping
    end_mapping
    start_sequence
    end_sequence
    full_scalar
    anchor_alias
);

# push interface for loader and emitter
sub push {
    my $self = shift;
    my $event = shift;
    die "Unrecognized event '$event'"
      unless $push_api{$event};
    $self->$event(@_);
}

# get a unique id for any node
sub get_id {
    my $self = shift;
    if (not ref $_[0]) {
        return 'undef' if not defined $_[0];
        \$_[0] =~ /\((\w+)\)$/o or die;
        return "$1-S";
    }
    overload::StrVal($_[0]) =~ /\((\w+)\)$/o or die;
    return $1;
}

# yaml "kind" is MAPPING or SEQUENCE or SCALAR
sub get_kind {
    my $self = shift;
    return SCALAR unless ref $_[0];
    overload::StrVal($_[0]) =~ /^(HASH|ARRAY)\(\w+\)$/o 
      or return SCALAR;
    return $1 eq 'HASH' ? MAPPING : SEQUENCE; 
}

# return (class, reftype, id)
sub get_info {
    my $self = shift;
    (overload::StrVal($_[0]) =~ qr{^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$}o)
}

# readonly accessor
sub attribute_ro {
    unshift @_, {mode => 'read-only'};
    goto &attribute;
}

# readwrite accessor
sub attribute_rw {
    unshift @_, {mode => 'read-write'};
    goto &attribute;
}

1;
