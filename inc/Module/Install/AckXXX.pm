#line 1
package Module::Install::AckXXX;
use strict;
use warnings;
use 5.008003;

use Module::Install::Base;

use vars qw($VERSION @ISA);
BEGIN {
    $VERSION = '0.11';
    @ISA     = 'Module::Install::Base';
}

sub ack_xxx {
    my $self = shift;
    return unless $self->is_admin;

    require Capture::Tiny;
    sub ack { system "ack '^\\s*use XXX\\b'"; }
    my $output = Capture::Tiny::capture_merged(\&ack);
    $self->_report($output) if $output;
}

sub _report {
    my $self = shift;
    my $output = shift;
    chomp ($output);
    print <<"...";

*** AUTHOR WARNING ***
*** Found usage of XXX.pm in this code:
$output

...
}

1;

=encoding utf8

#line 82
