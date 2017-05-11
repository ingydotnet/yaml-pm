use TestML;

TestML->new(
    testml => do { local $/; <DATA> },
    bridge => 'Bridge',
)->run;

{
    package Bridge;
    use base 'TestML::Bridge';
    use TestML::Util;
    use Data::Dumper;
    #use XXX -with => 'Data::Dumper';

    use YAML;
    sub eval {
        native eval $_[1]->value;
    }
    sub dump {
        str Dump $_[1]->value;
    }
    sub load {
        native Load $_[1]->value;
    }
    sub dumper {
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Terse = 1;
        str Data::Dumper::Dumper $_[1]->value;
    }

}

__DATA__
%TestML 0.1.0

*perl.eval.dump == *dump

*yaml.load.dumper == *dumper


=== TEST 1 - basic dump
--- perl
{ foo => 42 }
--- dump
---
foo: 42

=== TEST 2 - basic load
--- yaml
a: 1
--- dumper
{
  'a' => '1'
}


# use YAML;
# print Dump({ foo => 42 });
# use Data::Dumper;
# print Load("---\na: 1")->{a}, "\n";
