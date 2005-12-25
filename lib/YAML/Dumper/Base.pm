package YAML::Dumper::Base;
use YAML::Base -Base;
use YAML::Node;

# YAML Dumping options
field spec_version => '1.0';
field indent_width => 2;
field use_header => 1;
field use_version => 0;
field sort_keys => 1;
field anchor_prefix => '';
field dump_code => 0;
field use_block => 0;
field use_fold => 0;
field compress_series => 1;
field inline_series => 0;
field use_aliases => 1;
field purity => 0;

# Properties
field document => 0;
field transferred => {};
field id_refcnt => {};
field id_anchor => {};
field anchor => 1;
field level => 0;
field offset => [];
field headless => 0;
field blessed_map => {};

sub set_global_options {
    no warnings 'once';
    $self->spec_version($YAML::SpecVersion);
    $self->indent_width($YAML::Indent);
    $self->use_header($YAML::UseHeader);
    $self->use_version($YAML::UseVersion);
    $self->sort_keys($YAML::SortKeys);
    $self->anchor_prefix($YAML::AnchorPrefix);
    $self->dump_code($YAML::DumpCode || $YAML::UseCode);
    $self->use_block($YAML::UseBlock);
    $self->use_fold($YAML::UseFold);
    $self->compress_series($YAML::CompressSeries);
    $self->inline_series($YAML::InlineSeries);
    $self->use_aliases($YAML::UseAliases);
    $self->purity($YAML::Purity);
}

sub dump {
    die 'dump() not implemented in this class.';
}

sub blessed {
    my ($ref) = @_;
    $ref = \$_[0] unless ref $ref;
    my (undef, undef, $node_id) = YAML::Node::info($ref);
    $self->{blessed_map}->{$node_id};
}
    
sub bless {
    my ($ref, $blessing) = @_;
    my $ynode;
    $ref = \$_[0] unless ref $ref;
    my (undef, undef, $node_id) = YAML::Node::info($ref);
    if (not defined $blessing) {
        $ynode = YAML::Node->new($ref);
    }
    elsif (ref $blessing) {
        $self->die unless ynode($blessing);
        $ynode = $blessing;
    }
    else {
        no strict 'refs';
        my $transfer = $blessing . "::yaml_dump";
        $self->die unless defined &{$transfer};
        $ynode = &{$transfer}($ref);
        $self->die unless ynode($ynode);
    }
    $self->{blessed_map}->{$node_id} = $ynode;
    my $object = ynode($ynode) or $self->die;
    return $object;
}

