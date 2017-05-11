use YAML;
print Dump({ foo => 42 });
use Data::Dumper;
print Load("---\na: 1")->{a}, "\n";
