package YAML::Node;
@EXPORT = qw(ynode);
use strict;
use Exporter;
use YAML::Base '-base';
use YAML::Base; # XXX
use YAML::Tag;
use Carp;

spiffy_constructor 'new_node';

attribute 'node';
attribute 'kind';
attribute 'tag';

sub ynode {
    my $self;
    if (ref($_[0]) eq 'HASH') {
	$self = tied(%{$_[0]});
    }
    elsif (ref($_[0]) eq 'ARRAY') {
	$self = tied(@{$_[0]});
    }
    else {
	$self = tied($_[0]);
    }
    return (ref($self) =~ /^yaml_(scalar|sequence|mapping)$/) 
      ? $self 
      : undef;
}

my $kind_map = {
    mapping => MAPPING,
    sequence => SEQUENCE,
    scalar => SCALAR,
};
sub new {
    my ($class, $node, $tag) = @_;
    my $self;
    $self->{node} = $node;
    my (undef, $type) = YAML::Base->get_info($node);
    my $kind = (not defined $type) ? 'scalar' :
               ($type eq 'ARRAY') ? 'sequence' :
               ($type eq 'HASH') ? 'mapping' :
               croak "Can't create YAML::Node from '$type'";
    $self->{kind} = $kind_map->{$kind};
    $self->{tag} = ($tag || '');
    if ($kind eq 'scalar') {
	yaml_scalar->new($self, $_[1]);
	return \ $_[1];
    }
    my $package = "yaml_$kind";    
    $package->new($self)
}

#==============================================================================
package yaml_scalar;
@yaml_scalar::ISA = qw(YAML::Node);

sub new {
    my ($class, $self) = @_;
    tie $_[2], $class, $self;
}

sub TIESCALAR {
    my ($class, $self) = @_;
    bless $self, $class;
    return $self;
}

sub FETCH {
    my ($self) = @_;
    return $self->node;
}

sub STORE {
    my ($self, $value) = @_;
    $self->{node} = $value;
}

#==============================================================================
package yaml_sequence;
@yaml_sequence::ISA = qw(YAML::Node);

sub new {
    my ($class, $self) = @_;
    my $new;
    tie @$new, $class, $self;
    return $new;
}

sub TIEARRAY {
    my ($class, $self) = @_;
    return bless $self, $class;
}

sub FETCHSIZE {
    my ($self) = @_;
    return scalar @{$self->node};
}

# sub FETCHSIZE {
#     my ($self, $count) = @_;
#     return $#{$self->node} = $count;
# }

sub FETCH {
    my ($self, $index) = @_;
    return $self->node->[$index]
}

sub STORE {
    my ($self, $index, $value) = @_;
    return $self->node->[$index] = $value;
}

sub PUSH {
    my $self = shift;
    return push @{$self->node}, @_;
}

sub POP {
    my $self = shift;
    return pop @{$self->node};
}

sub SHIFT {
    my $self = shift;
    return shift @{$self->node};
}

sub UNSHIFT {
    my $self = shift;
    return unshift @{$self->node}, @_;
}

sub SPLICE {
    my $self = shift;
    my $offset = shift;
    my $length = shift;
    return splice(@{$self->node}, $offset, $length, @_);
}

sub EXISTS {
    my ($self, $index) = @_;
    return exists $self->node->[$index]
}

sub DELETE {
    my ($self, $index) = @_;
    return delete $self->node->[$index]
}

sub CLEAR {
    my ($self) = @_;
    return $self->node([]);
}

#==============================================================================
package yaml_mapping;
@yaml_mapping::ISA = qw(YAML::Node);

sub new {
    my ($class, $self) = @_;
    @{$self->{keys}} = sort keys %{$self->{node}}; 
    my $new;
    tie %$new, $class, $self;
    return $new;
}

sub keys {
    my $self = shift;
    if (@_) {
        $self->{keys} = (ref $_[0] eq 'ARRAY') ? $_[0] : [@_];
    }
    return wantarray 
      ? @{$self->{keys}} 
      : $self->{keys};
}

sub TIEHASH {
    my ($class, $self) = @_;
    return bless $self, $class;
}

sub FETCH {
    my ($self, $key) = @_;
    if (exists $self->node->{$key}) {
	return (grep {$_ eq $key} @{$self->keys}) 
	       ? $self->node->{$key} : undef;
    }
    return $self->{hash}->{$key};
}

sub STORE {
    my ($self, $key, $value) = @_;
    if (exists $self->{node}{$key}) {
	$self->{node}{$key} = $value;
    }
    elsif (exists $self->{hash}{$key}) {
	$self->{hash}{$key} = $value;
    }
    else {
	if (not grep {$_ eq $key} @{$self->{keys}}) {
	    push(@{$self->{keys}}, $key);
	}
	$self->{hash}{$key} = $value;
    }
    $value
}

sub DELETE {
    my ($self, $key) = @_;
    my $return;
    if (exists $self->{node}{$key}) {
	$return = $self->{node}{$key};
    }
    elsif (exists $self->{hash}{$key}) {
	$return = delete $self->{node}{$key};
    }
    for (my $i = 0; $i < @{$self->{keys}}; $i++) {
	if ($self->{keys}[$i] eq $key) {
	    splice(@{$self->{keys}}, $i, 1);
	}
    }
    return $return;
}

sub CLEAR {
    my ($self) = @_;
    @{$self->{keys}} = ();
    %{$self->{hash}} = ();
}

sub FIRSTKEY {
    my ($self) = @_;
    $self->{iter} = 0;
    $self->{keys}[0]
}

sub NEXTKEY {
    my ($self) = @_;
    $self->{keys}[++$self->{iter}]
}

sub EXISTS {
    my ($self, $key) = @_;
    exists $self->{node}{$key}
}

1;

__END__


=head1 NAME

YAML::Node - A generic data node that encapsulates YAML information

=head1 SYNOPSIS

    use YAML;
    use YAML::Node;
    
    my $ynode = YAML::Node->new({}, 'ingerson.com/fruit');
    %$ynode = qw(orange orange apple red grape green);
    print Dump $ynode;

yields:

    --- #YAML:1.0 !ingerson.com/fruit
    orange: orange
    apple: red
    grape: green

=head1 DESCRIPTION

A generic node in YAML is similar to a plain hash, array, or scalar node
in Perl except that it must also keep track of its type. The type is a
URI called the YAML tag.

YAML::Node is a class for generating and manipulating these containers.
A YAML node (or ynode) is a tied hash, array or scalar. In most ways it
behaves just like the plain thing. But you can assign and retrieve and
YAML tag URI to it. For the hash flavor, you can also assign the
order that the keys will be retrieved in. By default a ynode will offer
its keys in the same order that they were assigned.

YAML::Node has a class method call new() that will return a ynode. You
pass it a regular node and an optional tag. After that you can
use it like a normal Perl node, but when you YAML::Dump it, the magical
properties will be honored.

This is how you can control the sort order of hash keys during a YAML
serialization. By default, YAML sorts keys alphabetically. But notice
in the above example that the keys were Dumped in the same order they
were assigned.

YAML::Node exports a function called ynode(). This function returns the tied object so that you can call special methods on it like ->keys().

keys() works like this:

    use YAML;
    use YAML::Node;
    
    %$node = qw(orange orange apple red grape green);
    $ynode = YAML::Node->new($node);
    ynode($ynode)->keys(['grape', 'apple']);
    print Dump $ynode;

produces:

    --- #YAML:1.0
    grape: green
    apple: red

It tells the ynode which keys and what order to use.

ynodes will play a very important role in how programs use YAML. They
are the foundation of how a Perl class can marshall the Loading and
Dumping of its objects.

The upcoming versions of YAML.pm will have much more information on this.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
