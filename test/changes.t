use strict;
use File::Basename;
use lib dirname(__FILE__);

use TestYAML tests => 1;

SKIP: {
    skip("Can't parse Changes file yet :(", 1);
}

# my @values = LoadFile("Changes");
