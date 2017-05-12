use strict;
use lib 't/old';
my $t = -e 't' ? 't' : 'test';

use utf8;
use lib 'inc';
use Test::YAML();
BEGIN {
    @Test::YAML::EXPORT =
        grep { not /^(Dump|Load)(File)?$/ } @Test::YAML::EXPORT;
}
use IO::Pipe;
use IO::File;
use TestYAML tests => 6;
use YAML qw/DumpFile LoadFile/;;

my $testdata = 'El país es medible. La patria es del tamaño del corazón de quien la quiere.';


# IO::Pipe

my $pipe = new IO::Pipe;

if ( fork() ) { # parent reads from IO::Pipe handle
    $pipe->reader();
    my $recv_data = LoadFile($pipe);
    is length($recv_data), length($testdata), 'LoadFile from IO::Pipe read data';
    is $recv_data, $testdata, 'LoadFile from IO::Pipe contents is correct';
} else { # child writes to IO::Pipe handle
    $pipe->writer();
    DumpFile($pipe, $testdata);
    exit 0;
}

# IO::File

my $file = "$t/dump-io-file-$$.yaml";
my $fh = new IO::File;

# write to IO::File handle
$fh->open($file, '>:utf8') or die $!;
DumpFile($fh, $testdata);
$fh->close;
ok -e $file, 'IO::File output file exists';

# read from IO::File handle
$fh->open($file, '<:utf8') or die $!;
my $yaml = do { local $/; <$fh> };
is $yaml, "--- $testdata\n", 'LoadFile from IO::File contents is correct';

$fh->seek(0, 0);
my $read_data = LoadFile($fh) or die $!;
$fh->close;

is length($read_data), length($testdata), 'LoadFile from IO::File read data';
is $read_data, $testdata, 'LoadFile from IO::File read data';

unlink $file;
