use utf8;
use Test::YAML();
BEGIN {
    @Test::YAML::EXPORT =
        grep { not /^(Dump|Load)(File)?$/ } @Test::YAML::EXPORT;
}
use t::TestYAML tests => 6;

use YAML qw/DumpFile LoadFile/;

ok defined &DumpFile,
    'DumpFile exported';

ok defined &LoadFile,
    'LoadFile exported';

my $file = 't/dump.yaml';

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
