use strict;
use lib 't';
use TestYAML (test_file => 't/data1', only => 0);
use Test::More tests => MAX;
use YAML::Node;

use YAML::Dumper;

my $result;
for my $test (tests) {
    SKIP: {
        skip("No perl section", 1) unless defined $test->{perl};
        $result = '';
        my ($anchor);
        my @data = eval $test->{perl};
        die $@ if $@;
        skip("Nothing returned by perl", 1) 
          unless @data;
        my $dumper = YAML::Dumper->new;
        $dumper->anchor($anchor) if $anchor;

        $dumper->emitter(Test::Emitter->new);
        $dumper->open('');
        $dumper->dump($_) for @data;
        $dumper->close;
        $test->{events_string} =~ s/( _){1,2} [A-Z]+$//mg;
        is($result, $test->{events_string});
    }
}

package Test::Emitter;
use strict;
use YAML::Emitter '-base';

sub push {
    my $self = shift;
    my $event = shift;
    my @args = @_;
    pop @args while @args and (not defined $args[-1] or not length $args[-1]);
    @args = map {
        $_ = '_' if not defined $_;
        s/ /_/g;
        s/\n/\\n/g;
        $_;
    } @args;
    my $line = join(' ', $event, @args) . "\n";
    $result .= $line;
}
