#line 1 "inc/Module/Install/Can.pm - /usr/lang/perl/5.8.2/lib/site_perl/5.8.2/Module/Install/Can.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install/Can.pm $ $Author: ingy $
# $Revision: #5 $ $Change: 1377 $ $DateTime: 2003/03/20 15:11:54 $ vim: expandtab shiftwidth=4

package Module::Install::Can;
use Module::Install::Base; @ISA = qw(Module::Install::Base);
$VERSION = '0.01';
use strict;

# check if we can run some command
sub can_run {
    my ($self, $cmd) = @_;

    require Config;
    require File::Spec;
    require ExtUtils::MakeMaker;

    my $_cmd = $cmd;
    return $_cmd if (-x $_cmd or $_cmd = MM->maybe_command($_cmd));

    for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
        my $abs = File::Spec->catfile($dir, $_[1]);
        return $abs if (-x $abs or $abs = MM->maybe_command($abs));
    }

    return;
}

sub can_cc {
    my $self = shift;
    require Config;
    my $cc = $Config::Config{cc} or return;
    $self->can_run($cc);
}

1;
