use strict;
use lib 't';
use TestYAML (test_file => 't/data1', only => 0);
use Test::More tests => MAX;

use YAML::Node;
use YAML::Loader;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;
$Data::Dumper::Useqq = 1;

my @events;
for my $test (tests) {
    SKIP: {
        my ($anchor);
        skip("No perl section", 1) unless defined $test->{perl};
        my @expected = eval $test->{perl};
        die $@ if $@;
        skip("No data in perl section", 1) unless @expected;
        @events = @{$test->{events}};
        my $loader = YAML::Loader->new;
        $loader->parser(Test::Parser->new);
        $loader->open($test->{yaml});
        my @results;
        while (my @load = $loader->next) {
            push @results, @load;
        } 
        is(Data::Dumper::Dumper(@results),
           Data::Dumper::Dumper(@expected),
        );
    }
}

package Test::Parser;
use strict;
use YAML::Parser '-base';

sub parse {
    my $self = shift;
    while (@events) {
        if ($self->yield) {
            $self->yield(0);
            return 1;
        }
        $self->receiver->push(@{shift @events});
    }
    return 1;
}
