#line 1 "inc/Module/Install/WriteAll.pm - /usr/lang/perl/5.8.2/lib/site_perl/5.8.2/Module/Install/WriteAll.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install/WriteAll.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 1818 $ $DateTime: 2003/12/14 20:58:38 $ vim: expandtab shiftwidth=4

package Module::Install::WriteAll;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

sub WriteAll {
    my $self = shift;
    my %args = (check_nmake => 1, meta => 1, sign => 0, @_);

    $self->sign(1) if $args{sign};
    $self->Meta->write if $args{meta};
    $self->admin->WriteAll(%args) if $self->is_admin;

    if ($0 =~ /Build.PL$/i) {
	$self->Build->write;
    }
    else {
	$self->check_nmake if $args{check_nmake};
        $self->makemaker_args( PL_FILES => {} )
            unless $self->makemaker_args->{'PL_FILES'};
	$self->Makefile->write;
    }
}

1;
