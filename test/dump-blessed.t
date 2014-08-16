use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 2;

package Foo::Bar;

use TestYAMLBase;

our @ISA = 'TestYAMLBase';

sub yaml_dump {
    my $self = shift;
    my $node = YAML::Node->new({
        two => $self->{two} - 1,
        one => $self->{one} + 1,
    }, 'perl/Foo::Bar');
    YAML::Node::ynode($node)->keys(['two', 'one']);
    return $node;
}

sub yaml_load {
    my $class = shift;
    my $node = shift;
    my $self = $class->new;
    $self->{one} = ($node->{one} - 1);
    $self->{two} = ($node->{two} + 1);
    return $self;
}

package main;

no_diff;
run_roundtrip_nyn;

__END__

=== Object class handles marshalling
+++ perl
my $fb = Foo::Bar->new();
$fb->{one} = 5;
$fb->{two} = 3;
$fb;
+++ yaml
--- !perl/Foo::Bar
two: 2
one: 6
