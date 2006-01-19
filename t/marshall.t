use t::TestYAML tests => 10;

#-------------------------------------------------------------------------------
package Foo::Bar;
use Class::Spiffy -base;
use YAML::Marshall -mixin;

field 'x';
field 'y';

sub yaml_dump {
    my $self = shift;
    my $array = [];
    for my $k (sort keys %$self) {
        push @$array, $k, $self->{$k};
    }
    $self->yaml_node($array, 'perl/Foo::Bar');
}

sub yaml_load() {
    my $class = shift;
    my $node = shift;
    my $self = $class->new;
    %$self = @$node;
    return $self;
}

#-------------------------------------------------------------------------------
package Bar::Baz;
use Class::Spiffy -base;
use YAML::Marshall -mixin, 'random/object:bar.baz';

#-------------------------------------------------------------------------------
package Baz::Foo;
use Class::Spiffy -base;
use YAML::Marshall -mixin;

sub yaml_dump {
    my $node = super;
    $node->{comment} = "Hi, Mom";
    return $node;
}

sub yaml_load {
    my $node = super;
    delete $node->{comment};
    return $node;
}

#-------------------------------------------------------------------------------
package main;
no_diff;
run_roundtrip_nyn;

is $main::BazFoo->{11}, 12,
   'first key exists';

is $main::BazFoo->{13}, 14,
   'second key exists';

ok not($main::BazFoo->{comment}),
   'extra key not added';

__DATA__

=== Serialize a hash object as a sequence
+++ perl
my $fb = Foo::Bar->new;
$fb->{x} = 5;
$fb->{y} = 'che';
[$fb];
+++ yaml
---
- !perl/Foo::Bar
  - x
  - 5
  - y
  - che


=== Use a non-standard tag
+++ perl: bless {11 .. 14}, 'Bar::Baz';
+++ yaml
--- !random/object:bar.baz
11: 12
13: 14


=== super calls to mixins work
+++ perl: bless {11 .. 14}, 'Baz::Foo';
+++ yaml
--- !perl/Baz::Foo
11: 12
13: 14
comment: 'Hi, Mom'


=== yaml_dump doesn't mutate original hash
+++ no_round_trip
+++ perl: $main::BazFoo = bless {11 .. 14}, 'Baz::Foo';
+++ yaml
--- !perl/Baz::Foo
11: 12
13: 14
comment: 'Hi, Mom'


