package YAML::Parser;
use strict;
use YAML::Base '-base';
use Carp;

attribute stream =>;
attribute receiver =>;
attribute stream_line_number => 0;
attribute document_line_number => 0;
attribute yield => 0;
attribute state =>;
attribute pos =>;
attribute stack =>;

my $fsmd = load_fsmd();

sub string {
    my $self = shift;
    $self->stream(\ $_[0]);
    $self->stream_line_number(0);
    $self->document_line_number(0);
}

sub parse_error {
    my $self = shift;
    my $state = shift;
    my $line_number = $self->stream_line_number;
    "Parser Error: No match in state $state; line #$line_number";
}

sub parse {
    my $self = shift;
    my $stream = ${$self->stream};
    my $pos = 0;
    my $state = 'beginning_of_stream';
    if (defined $self->state) {
        $state = $self->state;
        $pos = $self->pos;
    }
  LOOP:
    while ($state ne 'end_of_stream') {
        if ($self->yield) {
            $self->state($state);
            $self->pos($pos);
            $self->yield(0);
            return 1;
        }
        if (not defined $fsmd->{$state}) {
            my $line_number = $self->stream_line_number;
            die "Parser Error: No such state ($state) at line $line_number\n";
        }
        for my $def (@{$fsmd->{$state}}) {
            my ($regexp, $handlers, $next_state) = @$def;
            pos($stream) = $pos;
            if ($stream =~ /$regexp/g) {
                my @captures = ($1, $2, $3);
                $pos = pos($stream);
                for my $handler (@$handlers) {
                    $self->$handler(@captures); 
                }
                $state = $next_state;
                next LOOP;
            }
        }
        croak $self->parse_error($state);
    }
    return 1; 
}

sub start_stream {
    my $self = shift;
    $self->receiver->start_stream();
}

sub end_stream {
    my $self = shift;
    $self->receiver->end_stream();
}

sub start_document {
    my $self = shift;
    $self->receiver->start_document();
}

sub end_document {
    my $self = shift;
    $self->receiver->end_document();
}

sub end_node {
    my $self = shift;
    $self->receiver->end_mapping(); #XXX punt
}

sub start_mapping {
    my $self = shift;
    $self->receiver->start_mapping();
}

sub start_sequence {
    my $self = shift;
    $self->receiver->start_sequence();
}

sub scalar_key {
    my $self = shift;
    my $key = shift;
    $self->receiver->full_scalar($key);
}

sub inc {
    my $self = shift;
    $self->stream_line_number($self->stream_line_number + 1);
    $self->document_line_number($self->document_line_number + 1);
}

sub line_comment {}
sub empty_line {}

sub load_fsmd {
    local $/ = '';
    for my $chunk (<DATA>) {
        $chunk =~ s/^(\w+)\n//
          or die $chunk;
        my $state_id = $1;
        my @lines = grep {not /^#/} split /\n/, $chunk;
        while (my ($pattern, $rest) = splice(@lines, 0, 2)) {
            $pattern =~ s/^\s*//;
            my $regexp = qr/\G$pattern/;
            $rest =~ s/^\s*//;
            my ($handlers, $next_state) = split /->/, $rest;
            $handlers = [ split /\./, $handlers ];
            push @{$fsmd->{$state_id}}, [$regexp, $handlers, $next_state];
        }
    }
}

1;

__DATA__
beginning_of_stream
# '^' == 'always match'
  ^
    start_stream.inc->before_first_document

before_first_document
  \s*#(.*)\n
    line_comment.inc->before_first_document
  \s*\n
    empty_line.inc->before_first_document
  ---\s*\n
    start_document.inc->start_document

start_document
  -(?:\s+|(?=\n))
    start_sequence->before_first_sequence_element
  (?=\w+:)
    start_mapping->expect_key
  \z
    end_stream->end_of_stream

expect_key
  (\w+)\s*:\s+
    scalar_key->expect_value
  \z
    end_node.end_document->start_document

expect_value
  (.*?)\s*\n
    scalar_key->expect_key
