use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 16;
use YAML::Dumper;

package StrIngy;
use overload '""', sub { 'A Stringy String' };
sub new {bless {}, shift}

package main;
my $object = bless {}, 'StrIngy';

# $\ = "\n";
# print ref($object);
# print "$object";
# print overload::StrVal($object);
# print overload::StrVal(bless {}, 'foo');
# exit;

filters {
    node => ['eval_perl' => 'get_info'],
    info => ['lines' => 'make_regexp'],
};

run_like node => 'info';

sub eval_perl {
    my $perl = shift;
    my $stringify = 0;
    $stringify = 1 if $perl =~ s/^#\s*//;
    my $node = eval $perl;
    die "Perl code failed to eval:\n$perl\n$@" if $@;
    return ($node, $stringify);
}

sub get_info {
    my $dumper = YAML::Dumper->new;
    join ';', map {
        defined($_) ? $_ : 'undef'
    } $dumper->node_info(@_);
}

sub make_regexp {
    my $string = join ';', map {
        chomp;
        s/^~$/undef/;
        s/^0x\d+/0x[0-9a-fA-F]+/;
        $_;
    } @_;
    qr/^${string}$/;
}

__DATA__
=== Hash Ref
+++ node: +{1..4};
+++ info
~
HASH
0x12345678

=== Array Ref
+++ node: [1..5]
+++ info
~
ARRAY
0x12345678

=== Scalar
+++ node: 'hello';
+++ info
~
~
0x12345678-S

=== Scalar Ref
+++ node: \ 'hello';
+++ info
~
SCALAR
0x12345678

=== Scalar Ref Ref
+++ node: \\ 'hello';
+++ info
~
REF
0x12345678

=== Code Ref
+++ node: sub { 42; }
+++ info
~
CODE
0x12345678

=== Code Ref Ref
+++ node: \ sub { 42; }
+++ info
~
REF
0x12345678

=== Glob
+++ node: $::x = 5; \ *x;
+++ info
~
GLOB
0x12345678

=== Regular Expression
+++ node: qr{xxx};
+++ info
~
REGEXP
0x12345678

=== Blessed Hash Ref
+++ node: bless {}, 'ARRAY';
+++ info
ARRAY
HASH
0x12345678

=== Blessed Array Ref
+++ node: bless [], 'Foo::Bar';
+++ info
Foo::Bar
ARRAY
0x12345678

=== Blessed Scalar Ref
+++ node: my $b = 'boomboom'; bless ((\ $b), 'Foo::Barge');
+++ info
Foo::Barge
SCALAR
0x12345678

=== Blessed Code Ref
+++ node: bless sub { 43 }, 'Foo::Barbie';
+++ info
Foo::Barbie
CODE
0x12345678

=== Blessed Glob
+++ node: $::x = 5; bless \ *x, 'Che';
+++ info
Che
GLOB
0x12345678

=== Not Stringified Hash Object
+++ node: bless {}, 'StrIngy';
+++ info
StrIngy
HASH
0x12345678

=== Stringified Hash Object
+++ node: # bless {}, 'StrIngy';
+++ info
~
~
0x12345678-S


