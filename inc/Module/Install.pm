#line 1 "inc/Module/Install.pm - /usr/lang/perl/5.8.2/lib/site_perl/5.8.2/Module/Install.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install.pm $ $Author: autrijus $
# $Revision: #64 $ $Change: 1812 $ $DateTime: 2003/12/14 20:24:49 $ vim: expandtab shiftwidth=4

package Module::Install;
$VERSION = '0.29';

die <<END unless defined $INC{'inc/Module/Install.pm'};
Please invoke Module::Install with:

    use inc::Module::Install;

not:

    use Module::Install;

END

use strict 'vars';
use File::Find ();
use File::Path ();

@inc::Module::Install::ISA = 'Module::Install';

#line 128

sub import {
    my $class = shift;
    my $self = $class->new(@_);

    if (not -f $self->{file}) {
        require "$self->{path}/$self->{dispatch}.pm";
        File::Path::mkpath("$self->{prefix}/$self->{author}");
        $self->{admin} = 
          "$self->{name}::$self->{dispatch}"->new(_top => $self);
        $self->{admin}->init;
        @_ = ($class, _self => $self);
        goto &{"$self->{name}::import"};
    }

    *{caller(0) . "::AUTOLOAD"} = $self->autoload;
}

#line 151

sub autoload {
    my $self = shift;
    my $caller = caller;
    sub {
        ${"$caller\::AUTOLOAD"} =~ /([^:]+)$/ or die "Cannot autoload $caller";
        unshift @_, ($self, $1);
        goto &{$self->can('call')} unless uc($1) eq $1;
    };
}

#line 168

sub new {
    my ($class, %args) = @_;

    return $args{_self} if $args{_self};

    $args{dispatch} ||= 'Admin';
    $args{prefix}   ||= 'inc';
    $args{author}   ||= '.author';
    $args{bundle}   ||= 'inc/BUNDLES';

    $class =~ s/^\Q$args{prefix}\E:://;
    $args{name}     ||= $class;
    $args{version}  ||= $class->VERSION;

    unless ($args{path}) {
        $args{path}  = $args{name};
        $args{path}  =~ s!::!/!g;
    }
    $args{file}     ||= "$args{prefix}/$args{path}.pm";

    bless(\%args, $class);
}

#line 197

sub call {
    my $self   = shift;
    my $method = shift;
    my $obj = $self->load($method) or return;

    unshift @_, $obj;
    goto &{$obj->can($method)};
}

#line 212

sub load {
    my ($self, $method) = @_;

    $self->load_extensions(
        "$self->{prefix}/$self->{path}", $self
    ) unless $self->{extensions};

    foreach my $obj (@{$self->{extensions}}) {
        return $obj if $obj->can($method);
    }

    my $admin = $self->{admin} or die << "END";
The '$method' method does not exist in the '$self->{prefix}' path!
Please remove the '$self->{prefix}' directory and run $0 again to load it.
END

    my $obj = $admin->load($method, 1);
    push @{$self->{extensions}}, $obj;

    $obj;
}

#line 242

sub load_extensions {
    my ($self, $path, $top_obj) = @_;

    unshift @INC, $self->{prefix}
        unless grep { $_ eq $self->{prefix} } @INC;

    local @INC = ($path, @INC);
    foreach my $rv ($self->find_extensions($path)) {
        my ($file, $pkg) = @{$rv};
        next if $self->{pathnames}{$pkg};

        eval { require $file; 1 } or (warn($@), next);
        $self->{pathnames}{$pkg} = $INC{$file};
        push @{$self->{extensions}}, $pkg->new( _top => $top_obj );
    }
}

#line 266

sub find_extensions {
    my ($self, $path) = @_;
    my @found;

    File::Find::find(sub {
        my $file = $File::Find::name;
        return unless $file =~ m!^\Q$path\E/(.+)\.pm\Z!is;
        return if $1 eq $self->{dispatch};

        $file = "$self->{path}/$1.pm";
        my $pkg = "$self->{name}::$1"; $pkg =~ s!/!::!g;
        push @found, [$file, $pkg];
    }, $path) if -d $path;

    @found;
}

1;

__END__

#line 567
