use strict;
use lib 't';
use TestYAML (test_file => 't/data1');
use Test::More tests => MAX;

use YAML::Emitter;

for my $test (tests) {
    my $emitter = YAML::Emitter->new;
    my $result = '';
    $emitter->string($result);
    for my $event (@{$test->{events}}) {
        $emitter->push(@$event);
    }
    is($result, $test->{yaml});
}
