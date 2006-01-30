use Test::YAML();
BEGIN { 
    @Test::YAML::EXPORT =
        grep { not /^(Dump|Load)(File)?$/ } @Test::YAML::EXPORT;
}
use t::TestYAML tests => 3;

use YAML 'DumpFile';

ok defined &DumpFile,
    'Dumpfile exported';

my $file = 't/dump.yaml';

DumpFile($file, [1..3]);

ok -e $file,
    'Output file exists';

open IN, $file or die $!;
my $yaml = join '', <IN>;

is $yaml, <<'...', 'DumpFile YAML is correct';
---
- 1
- 2
- 3
...

unlink $file;
