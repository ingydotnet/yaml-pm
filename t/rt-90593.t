# https://rt.cpan.org/Public/Bug/Display.html?id=90593
use Test::More tests => 2;

use YAML;
use constant LENGTH => 32767;

$SIG{__WARN__} = sub { die @_ };

my $yaml = 'x: "' . ('x' x LENGTH) . '"' . "\n";

my $hash = Load $yaml;

is ref($hash), 'HASH', 'Loaded a hash';
is length($hash->{x}), LENGTH, 'Long scalar loaded';
