package YAML::Dumper;
$VERSION = '0.50';
@ISA = qw(YAML::Base);
use strict;
use YAML::Node;
use YAML::Base '-base';
use YAML::Base;

attribute purity => 0;
attribute sort_keys => 1;
attribute transfer_classes => [];
attribute transferred_nodes => {};
attribute seen_nodes => {};
attribute shadowed_nodes => {};
attribute alias_index => {};
attribute tag_index => {};
attribute style_index => {};
attribute anchor => 1;

sub emitter {
    my $self = shift;
    if (@_) {
        my $emitter = shift;
        if (ref $emitter) {
            $self->{emitter} = $emitter;
        }
        else {
            eval "require $emitter"; die $@ if $@;
            $self->{emitter} = $emitter->new;
        }
    }
    return $self->{emitter};
}

sub open {
    my $self = shift;
    $self->emitter->string($_[0]);
    $self->emitter->push('start_stream');
}

sub close {
    my $self = shift;
    $self->emitter->push('end_stream');
}

sub dump {
    my $self = shift;
    $self->transfer($_[0]);
    $self->emitter->push('start_document');
    $self->dump_node($_[0]);
    $self->emitter->push('end_document');
}

sub transfer {
    my $self = shift;
    my $id = $self->get_id($_[0]);
    return if $self->seen_nodes->{$id}++;

    my @node;
    if (defined $self->shadowed_nodes->{$id}) {
        @node = ($self->shadowed_nodes->{$id});
    }
    else {
        for my $class (@{$self->{transfer_classes}}) {
            my @transferred = $class->transfer_to_yaml($_[0])
              or next;
            (@node) = $self->transferred_nodes->{$id} = $transferred[0];
            last;
        }
    }
    my $node = @node ? $node[0] : $_[0];
    my $kind = $self->get_kind($node);
    if ($kind == MAPPING) {
        for my $key (keys %$node) {
            $self->transfer($key);
            $self->transfer($node->{$key});
        }
    }
    elsif ($kind == SEQUENCE) {
        for my $entry (@$node) {
            $self->transfer($entry);
        }
    }
}

sub dump_node {
    my $self = shift;
    my $id = $self->get_id($_[0]);
    
    if (defined $self->shadowed_nodes->{$id}) {
        return $self->dump_ynode($self->shadowed_nodes->{$id});
    }
    elsif (defined $self->transferred_nodes->{$id}) {
        return $self->dump_ynode($self->transferred_nodes->{$id});
    }
    elsif (YAML::Node::ynode($_[0])) {
        return $self->dump_ynode($_[0]);
    }

    my $kind = $self->get_kind($_[0]);
    $self->handle_aliases($id, $kind) and return;

    $kind == MAPPING  ? $self->dump_mapping($_[0]) :
    $kind == SEQUENCE ? $self->dump_sequence($_[0]) :
                        $self->dump_scalar($_[0]);
}

sub dump_ynode {
    my $self = shift;
    my $id = $self->get_id($_[0]);

    my $ynode = YAML::Node::ynode($_[0])
      or die "Expected ynode";
    my $kind = $ynode->kind;
    $self->handle_aliases($id, $kind) and return;
    $self->tag_index->{$id} = $ynode->tag;

    $kind == MAPPING  ? $self->dump_mapping($_[0]) :
    $kind == SEQUENCE ? $self->dump_sequence($_[0]) :
                        $self->dump_scalar($_[0]);
}

sub handle_aliases {
    my ($self, $id, $kind) = @_;
    if ($kind == MAPPING or $kind == SEQUENCE or $self->purity) {
        if (defined $self->alias_index->{$id}) {
            $self->dump_alias($id);
            return 1;
        }
        if ($self->seen_nodes->{$id} > 1) {
            $self->alias_index->{$id} = $self->next_anchor;
        }
    }
    return 0;
}

sub next_anchor {
    my $self = shift;
    my $anchor = $self->anchor;
    my $new_anchor = $anchor;
    $self->anchor(++$new_anchor);
    $anchor;
}

sub dump_mapping {
    my $self = shift;
    my ($node) = @_;
    my $id = $self->get_id($node);
    my $anchor = $self->alias_index->{$id};
    my $tag = ynode($node)->tag 
      if ynode($node);
    $self->emitter->push('start_mapping', $anchor, $tag);
    for (YAML::Node::ynode($_[0]) ? keys %$node :
         $self->sort_keys ? sort keys %$node : 
         keys %$node
        ) {
        $self->dump_node($_);
        $self->dump_node($node->{$_});
    }
    $self->emitter->push('end_mapping');
}

sub dump_sequence {
    my $self = shift;
    my ($node) = @_;
    my $id = $self->get_id($node);
    my $anchor = $self->alias_index->{$id};
    my $tag = ynode($node)->tag 
      if ynode($node);
    $self->emitter->push('start_sequence', $anchor, $tag);
    for my $element (@$node) {
        $self->dump_node($element);
    }
    $self->emitter->push('end_sequence');
}

sub dump_scalar {
    my $self = shift;
    my $anchor = $self->alias_index->{$self->get_id($_[0])};
    $self->emitter->push('full_scalar', $_[0], $anchor);
}

sub dump_alias {
    my ($self, $id) = @_;
    my $anchor = $self->alias_index->{$id};
    $self->emitter->push('anchor_alias', $anchor);
}

sub shadow {
    my $self = shift;

    return $self->shadowed_nodes(undef)
      if @_ == 1 and not defined $_[0];
    my $node_id = $self->get_id($_[0]);
    if (@_ == 1) {
        my $ynode = YAML::Node::ynode($self->shadowed_nodes->{$node_id});
        return if not defined $ynode;
        return $ynode;
    }
    if (@_ == 2) {
        return delete $self->shadowed_nodes->{$node_id}
          unless defined $_[1];
        my $ynode = YAML::Node::ynode($_[1]);
        die "Second argument to YAML::Dumper->shadow must be a ynode"
          unless defined $ynode;
        $self->shadowed_nodes->{$node_id} = $_[0];
        return $ynode;
    }
}

1;
