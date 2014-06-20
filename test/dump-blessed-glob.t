use strict;
use File::Basename;
use lib dirname(__FILE__);

use TestYAML tests => 2;

package Foo::Bar;

sub new {
    my ($class) = @_;
    my $ref = globref();
    my $self = bless $ref, $class;
    return $self;
}

my $globnum = 0;
sub globref {
    my $symbolname = "Foo::Glob::glob$globnum";
    $globnum ++;
    no strict 'refs';
    return \*{ $symbolname };
}


package main;

is(Test::YAML::Dump({ globref => Foo::Bar::globref() }), <<EYAM, "dump glob-in-hash");
---
globref: !!perl/ref
  =: !!perl/glob:
    PACKAGE: Foo::Glob
    NAME: glob0
EYAM

is(Test::YAML::Dump({ blessglob => Foo::Bar->new }), <<EYAM, "dump blessed glob");
---
blessglob: !!perl/glob:Foo::Bar
  PACKAGE: Foo::Glob
  NAME: glob1
EYAM
