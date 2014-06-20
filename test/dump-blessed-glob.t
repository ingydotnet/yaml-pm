use strict;
use File::Basename;
use lib dirname(__FILE__);

use TestYAML tests => 2;

package Foo::Bar;

my $globnum = 0;
sub new {
    my ($class) = @_;
    my $symbolname = "glob$globnum";
    $globnum ++;
    my $ref = do {
        no strict 'refs';
        \*{ $symbolname };
    };
    my $self = bless $ref, $class;
    return $self;
}


package main;

is(Test::YAML::Dump( Foo::Bar->new ), <<EYAM, "dump glob");
--- !perl/Foo::Bar
EYAM
