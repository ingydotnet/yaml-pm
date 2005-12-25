use t::TestYAML tests => 3;

use YAML;

ok defined(&Dump),
    'Dump() is exported';
ok defined(&Load),
    'Load() is exported';
ok not(defined &Store),
    'Store() is not exported';
