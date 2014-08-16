use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 3;

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

# A glob tricked out with everything
my $val = Foo::Bar->new;
${ *$val } = 'wag';
%{ *$val } = qw( key value hash pairs );
@{ *$val } = qw( a b c );
open *$val, '>&', \*STDERR or die "Can't dup STDERR: $!";
*{$val} = sub { 2 + 2 };

my $dump_tricks = Test::YAML::Dump({ blessglob => $val });

# Redact some highly variable stuff from the IO
my $changekeys = join '|',
  qw( fileno device inode mode links uid gid rdev size atime mtime ),
  qw( ctime blksize blocks tell );
$dump_tricks =~ s{($changekeys): \S+$}{$1: redact}mg;

is($dump_tricks, <<EYAM, "dump blessed glob");
---
blessglob: !!perl/glob:Foo::Bar
  PACKAGE: Foo::Glob
  NAME: glob2
  SCALAR: wag
  ARRAY:
    - a
    - b
    - c
  HASH:
    hash: pairs
    key: value
  CODE: !!perl/code '{ "DUMMY" }'
  IO:
    fileno: redact
    stat:
      device: redact
      inode: redact
      mode: redact
      links: redact
      uid: redact
      gid: redact
      rdev: redact
      size: redact
      atime: redact
      mtime: redact
      ctime: redact
      blksize: redact
      blocks: redact
    tell: redact
EYAM
