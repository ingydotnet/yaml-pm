package YAML::Emitter;
$VERSION = '0.50';
use strict;
use YAML::Base '-base';
use YAML::Base;

# Class attributes
attribute 'printer';

attribute indent => 2;
attribute use_header => 1;
attribute use_ending => 0;
attribute use_version => 0;
attribute use_block => 0;
attribute use_fold => 0;
attribute map_in_seq => 1;
attribute document => 0;
attribute anchor => '';
attribute level => 0;
attribute offset => 0;
attribute stack => [];

sub print {
    my $self = shift;
    my $printer = $self->printer;
    $self->$printer(@_);
}

sub string {
    my $self = shift;
    my $stream = \$_[0];
    my $printer = sub {
        my $self = shift;
        $$stream .= $_[0];
    };
    $self->set_printer($printer);
}

sub file_handle {
    my $self = shift;
    my $file_handle = shift;
    my $printer = sub {
        my $self = shift;
        print $file_handle $_[0];
    };
    $self->set_printer($printer)
}

sub set_printer {
    my ($self, $printer) = @_;
    $self->printer($printer);
    $self->document(0);
    return $self;
}

sub current {
    my $self = shift;
    $self->stack->[-1];
}
    
sub start_stream {
    my $self = shift;
    $self->document(0);
}

sub end_stream {
    my $self = shift;
}

sub start_document {
    my $self = shift;
    $self->document($self->document + 1);
    $self->level(0);
    my $frame = YAML::Emitter::Frame->new;
    $frame->indent(0 - $self->indent);
    $self->stack([$frame]);
    $self->print('---');
    $self->print(' %YAML:1.0')
      if $self->use_version;
}

sub end_document {
    my $self = shift;
    $self->print("\n");
    $self->print("...\n")
      if $self->use_ending;
}

sub start_mapping {
    my $self = shift;
    my ($anchor, $transfer, $style) = @_;
    my $modifiers = $self->start_node($anchor, $transfer);
    $self->level_up(MAPPING, $modifiers);
}

sub end_mapping {
    my $self = shift;
    $self->print(' {}')
      unless $self->current->nodes;
    $self->level_down;
}

sub start_sequence {
    my $self = shift;
    my ($anchor, $transfer, $style) = @_;
    my $modifiers = $self->start_node($anchor, $transfer);
    $self->level_up(SEQUENCE, $modifiers);
}

sub end_sequence {
    my $self = shift;
    $self->print(' []')
      unless $self->current->nodes;
    $self->level_down;
}

sub full_scalar {
    my $self = shift; 
    my ($value, $anchor, $transfer, $style) = @_;
    $self->start_node;
    my $modifiers = $self->print_modifiers($anchor, $transfer);
    $self->print(' ') unless $self->is_mapping_key;
    $self->print($self->emit_scalar($value, $style));
    $self->incr_nodes;
}

sub emit_scalar {
    my $self = shift;
    my ($value, $style) = @_;
    if ($style) {
        return $self->literal_scalar($value) if $style == LITERAL;
        return $self->double_quoted($value) if $style == DOUBLE;
        return $self->single_quoted($value) if $style == SINGLE;
    }
    return $self->single_quoted($value) if $value =~ /: /;
    return $value;
}

sub single_quoted {
    my $self = shift;
    my $value = shift;
    qq{'$value'};
}

sub double_quoted {
    my $self = shift;
    my $value = shift;
    qq{"$value"};
}

sub literal_scalar {
    my $self = shift;
    my $value = shift;
    my $indent = ' ' x ($self->current->indent + $self->indent);
    my $literal = join $indent, "|\n", ($value =~ /(.*\n)/g);
    chomp $literal;
    return $literal;
}

sub anchor_alias {
    my $self = shift; 
    my ($anchor) = @_;
    $self->start_node;
    $self->print(' ') unless $self->is_mapping_key;
    $self->print('*' . $anchor);
    $self->incr_nodes;
}

################################################################################
sub start_node {
    my $self = shift;
    if ($self->is_mapping_key) {
        $self->print($self->indentation);
    }
    if ($self->is_mapping_value) {
        $self->print(':');
    }
    elsif ($self->in_sequence) {
        $self->print($self->indentation . '-')
    }
    return $self->print_modifiers(@_);
}

sub print_modifiers {
    my $self = shift;
    my ($anchor, $transfer) = @_;
    if ($anchor or $transfer) {
        $self->print(" &$anchor") if $anchor;
        $self->print(" !$transfer") if $transfer;
        return 1;
    }
    return 0;
}

sub indentation {
    my $self = shift;
    my $current = $self->current;
    if (not $current->nodes and 
        not $current->modifiers and
        ($current->sequence_in_sequence or $current->mapping_in_sequence)
       ) {
        return ' ' x (($self->indent - 1) || 1);
    }
    return("\n" . (' ' x $current->indent));
}

sub is_mapping_key {
    my $self = shift;
    return
        $self->level && 
        $self->current->kind == MAPPING && 
        not $self->current->nodes % 2;
}

sub is_mapping_value {
    my $self = shift;
    return
        $self->level && 
        $self->current->kind == MAPPING && 
        $self->current->nodes % 2;
}

sub in_sequence {
    my $self = shift;
    $self->current->kind == SEQUENCE;
}

sub in_mapping {
    my $self = shift;
    $self->current->kind == MAPPING;
}

sub level_up {
    my $self = shift;
    my ($kind, $modifiers) = @_;
    my $frame = YAML::Emitter::Frame->new;
    $self->incr_nodes;
    $frame->kind($kind);
    $frame->modifiers($modifiers);
    $frame->indent($self->current->indent + $self->indent);
    if ($kind == SEQUENCE) {
        if ($self->in_sequence) {
            $frame->sequence_in_sequence(1)
        }
        elsif ($self->in_mapping) {
            $frame->indent($self->current->indent);
            $frame->sequence_in_mapping(1);
        }
    }
    elsif ($kind == MAPPING) {
        if ($self->in_sequence) {
            $frame->mapping_in_sequence(1);
        }
    }
    push @{$self->stack}, $frame;
    $self->level($self->level + 1);
}

sub level_down {
    my $self = shift;
    pop @{$self->stack};
    $self->level($self->level - 1);
}

sub incr_nodes {
    my $self = shift;
    return unless $self->level;
    $self->current->nodes($self->current->nodes + 1);
}

package YAML::Emitter::Frame;
use Spiffy qw(-base);
use YAML::Base;

attribute indent => 0;
attribute kind => NONE;
attribute style => NONE;
attribute nodes => 0;
attribute sequence_in_sequence => 0;
attribute mapping_in_sequence => 0;
attribute sequence_in_mapping => 0;
attribute modifiers => 0;

1;
