package YAML::Loader;
$VERSION = '0.01';
use strict;
use YAML::Base '-base';

attribute eos => 0;
attribute stack => [];
attribute document =>;
attribute document_number => 0;
attribute anchor_map => {};

# Stack frame constants
use constant LAST => -1;
use constant COLLECTION => 0;
use constant CONTAINER => 1;
use constant ANCHOR => 2;
use constant TAG => 3;

sub parser {
    my $self = shift;
    if (@_) {
        my $parser = shift;
        if (ref $parser) {
            $self->{parser} = $parser;
        }
        else {
            eval "require $parser"; die $@ if $@;
            $self->{parser} = $parser->new;
        }
    }
    $self->{parser}->receiver($self);
    return $self->{parser};
}

sub open {
    my $self = shift;
    $self->parser->string($_[0]);
}

sub close {
    my $self = shift;
    $self->parser->string(undef);
}

sub next {
    my $self = shift;
    $self->parser->parse;
    return $self->eos ? () : ($self->document);
}

sub new_frame {
    my $self = shift;
    my ($anchor, $tag) = @_;
    my $frame = [];
    $frame->[COLLECTION] = [];
    $frame->[ANCHOR] = $anchor || '';
    $frame->[TAG] = $tag || '';
    return $frame;
}

sub start_stream {
    my $self = shift;
    $self->document_number(0);
    $self->document(undef);
    $self->eos(0);
    $self->stack([]);
}

sub end_stream {
    my $self = shift;
    $self->eos(1);
    $self->stack(undef);
}

sub start_document {
    my $self = shift;
    $self->anchor_map({});
    $self->document_number($self->document_number + 1);
    push @{$self->stack}, $self->new_frame;
}

sub end_document {
    my $self = shift;
    my $stack = $self->stack;
    my $frame = pop @$stack;
    $self->document($frame->[COLLECTION][LAST]);
    $self->parser->yield(1);
}

sub start_mapping {
    my $self = shift;
    my $frame = $self->new_frame(@_);
    $frame->[CONTAINER] = {};
    $self->mark_anchor($frame);
    push @{$self->stack}, $frame;
}

sub end_mapping {
    my $self = shift;
    my $frame = pop @{$self->stack};
    my $mapping = $frame->[CONTAINER];
    %$mapping = @{$frame->[COLLECTION]};
    push @{$self->stack->[LAST][COLLECTION]}, $mapping;
}

sub start_sequence {
    my $self = shift;
    my $frame = $self->new_frame(@_);
    $frame->[CONTAINER] = [];
    $self->mark_anchor($frame);
    push @{$self->stack}, $frame;
}

sub end_sequence {
    my $self = shift;
    my $frame = pop @{$self->stack};
    my $sequence = $frame->[CONTAINER];
    @$sequence = @{$frame->[COLLECTION]};
    push @{$self->stack->[LAST][COLLECTION]}, $sequence;
}

sub full_scalar {
    my $self = shift;
    my $scalar = shift;
    my $frame = $self->new_frame(@_);
    $frame->[CONTAINER] = $scalar;
    $self->mark_anchor($frame);
    push @{$self->stack->[LAST][COLLECTION]}, $scalar;
}

sub anchor_alias {
    my $self = shift;
    my $alias = shift;
    my $node;
    if (not defined $self->anchor_map->{$alias}) {
        warn "No anchor for alias '$alias'", $self->parse_message_suffix
          if $^W;
    }
    else {
        $node = $self->anchor_map->{$alias};
    }
    push @{$self->stack->[LAST][COLLECTION]}, $node;
}

sub mark_anchor {
    my $self = shift;
    my $frame = shift;
    my $anchor = $frame->[ANCHOR];
    return unless length $anchor;
    $self->anchor_map->{$anchor} = $frame->[CONTAINER];
}

sub parse_message_suffix {
    my $self = shift;
    my $document = $self->document_number;
    my $line = $self->parser->document_line_number;
    return " in yaml document '$document', line '$line'";
}

1;
