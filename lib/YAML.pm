package YAML;
$VERSION = '0.49_01';
my @XXX = qw(XXX YYY WWW);
@EXPORT = qw(Load Dump);
%EXPORT_TAGS = (all => [@EXPORT, @XXX, qw(LoadFile DumpFile Shadow)],
                XXX => [@XXX],
               );
Exporter::export_ok_tags(keys %EXPORT_TAGS);
use strict;
# use diagnostics;
use YAML::Base '-base';
use YAML::Base;
# use base 'Exporter', 'YAML::Base';

attribute 'dumper';
attribute 'loader';

#------------------------------------------------------------------------------
# Standard API
#------------------------------------------------------------------------------

sub Dump {
    my $self = YAML->new->_set_dumper_attributes;
    my $stream_string = '';
    $self->dumper->open($stream_string);
    for (@_) {
        $self->dumper->dump($_);
    }
    $self->dumper->close;
    return $stream_string;
}

sub Load {
    my $self = YAML->new->_set_loader_attributes;
    $self->loader->open($_[0]);
    my @data;
    while (my @next = $self->loader->next) {
        push @data, @next;
    }
    $self->loader->close;
    return wantarray ? @data : $data[0];
}

# XXX Allow concatenation to existing file.
sub DumpFile {
    my $self = YAML->new->_set_dumper_attributes;
    $self->dumper->emitter->file_path(shift);
    for (@_) {
        $self->dumper->dump($_);
    }
    return scalar @_;
}

sub LoadFile {
    my $self = YAML->new->_set_loader_attributes;
    $self->loader->parser->file_path(shift);
    my @data;
    while (my @next = $self->loader->next) {
        push @data, @next;
    }
    return wantarray ? @data : $data[0];
}

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

sub XXX {
    require Carp;
    Carp::croak(YAML::Dump(@_));
}

sub YYY {
    print YAML::Dump @_;
    return @_;
}

sub WWW {
    warn YAML::Dump @_;
    return @_;
}

# # Sugar for self-dumping objects
# # my $yaml = $object->to_yaml; 
# sub UNIVERSAL::to_yaml {
#     YAML::Dump(shift)
# }
# # my $object = PackageName->from_yaml($yaml);
# sub UNIVERSAL::from_yaml {
#     bless YAML::Load($_[1]), $_[0]
# }

# For Storable API compatible modules like POE
*YAML::freeze = \&Dump;
*YAML::freeze = \&Dump;
*YAML::thaw = \&Load;
*YAML::thaw = \&Load;

#------------------------------------------------------------------------------
# Shadowing API
#------------------------------------------------------------------------------
$YAML::shadow = YAML->new; # A global object (for shadowing only)
sub Shadow { 
    $YAML::shadow->shadow(@_) 
}

sub shadow {
    require YAML::Node;
    my ($self, $ref, $shadow) = @_;
    my $ynode;
    if (@_ == 2 and not defined $ref) {
        $self->{shadow} = {};
        return 1;
    }
    $ref = \$_[1] unless ref $ref;
    my (undef, undef, $node_id) = YAML::Node::info($ref);
    if (@_ == 3 and not defined $shadow) {
        return delete $self->{shadow}{$node_id};
    }
    if (defined $self->{shadow}{$node_id}) {
        $ynode = $self->{shadow}{$node_id};
    }
    elsif (not defined $shadow) {
        $ynode = YAML::Node->new($ref);
    }
    elsif (ref $shadow) {
        $ynode = $shadow;
    }
    else {
        if ($shadow->can('yaml_dump')) {
            no strict 'refs';
            $ynode = &{$shadow . '::yaml_dump'}($ref);
        }
        else {
            warn "No yaml_dump method for shadow class '$shadow'\n"
              if $^W;
        }
    }
    $self->{shadow}{$node_id} = $ynode;
    return YAML::Node::ynode($ynode);
}

#------------------------------------------------------------------------------
# Convert user global config variables into the appropriate 
#------------------------------------------------------------------------------
sub _set_loader_attributes {
    my $self = shift;
    my $loader = $YAML::Loader || 'YAML::Loader';
    my $loader_object = ref($loader) 
      ? $loader
      : do {
            eval "require $loader";
            die $@ if $@;
            $loader->new;
        };
    $loader_object->parser($YAML::Parser || 'YAML::Parser');
    $self->loader($loader_object);
    $self->_set_global_attributes($self->loader);
    $self->_set_global_attributes($self->loader->parser);
}

sub _set_dumper_attributes {
    my $self = shift;
    my $dumper = $YAML::Dumper || 'YAML::Dumper';
    my $dumper_object = ref($dumper) 
      ? $dumper
      : do {
            eval "require $dumper";
            die $@ if $@;
            $dumper->new;
        };
    $dumper_object->emitter($YAML::Emitter || 'YAML::Emitter');
    $self->dumper($dumper_object);
    $self->_set_global_attributes($self->dumper);
    $self->_set_global_attributes($self->dumper->emitter);
}

sub _set_global_attributes {
    my $self = shift;
    my $object = shift;
    for (keys %YAML::) {
        next unless /^[A-Z][a-z][A-Za-z]+$/;
        next unless defined ${*{$YAML::{$_}}{SCALAR}};
        my $method = $_;
        $method =~ s/([A-Z])/_\l$1/g;
        $method =~ s/^_//;
        next unless $object->can($method);
        $object->$method(${*{$YAML::{$_}}{SCALAR}});
    }
    return $self;
}

1;
