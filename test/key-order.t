use strict;
use Test::More tests => 1;
use YAML;

local $YAML::KeyOrder = 1;
my $yaml = <<'EOM';
---
def: 1
abc: 2
EOM
my $data = YAML::Load($yaml);
my $dump = YAML::Dump($data);
cmp_ok($dump, 'eq', $yaml, "Roundtrip with KeyOrder");

done_testing;

