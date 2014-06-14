use strict;
use File::Basename;
use lib dirname(__FILE__);

my $testdir = -e 'test' ? 'test' : 't';

use utf8;
use lib 'inc';
use Test::YAML();
BEGIN {
    @Test::YAML::EXPORT =
        grep { not /^(Dump|Load)(File)?$/ } @Test::YAML::EXPORT;
}
use TestYAML tests => 6;

use YAML qw/DumpFile LoadFile/;

ok defined &DumpFile,
    'DumpFile exported';

ok defined &LoadFile,
    'LoadFile exported';

my $file = "$testdir/dump-file-utf8-$$.yaml";

# A scalar containing non-ASCII characters
my $data = 'Olivier Mengué';
is length($data), 14, 'Test source is correctly encoded';

DumpFile($file, $data);

ok -e $file,
    'Output file exists';

open IN, '<:utf8', $file or die $!;
my $yaml = do { local $/; <IN> };
close IN;

is $yaml, "--- $data\n", 'DumpFile YAML encoding is correct';


my $read = LoadFile($file);
is $read, $data, 'LoadFile is ok';

unlink $file;
