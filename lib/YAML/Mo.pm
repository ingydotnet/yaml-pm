##
# name:      YAML::Mo
# abstract:  Mo Base Class for YAML
# author:    Ingy döt Net <ingy@ingy.net>
# license:   perl
# copyright: 2011

package YAML::Mo;
# use Mo qw[builder default];
no warnings;my$K=__PACKAGE__."::";*{$K.'Object::new'}=sub{my$c=shift;my$s=bless{@_},$c;my@B;do{@B=($c.'::BUILD',@B)}while($c)=@{$c.'::ISA'};exists&$_&&&$_($s)for@B;$s};*{$K.'import'}=sub{import warnings;$^H|=1538;my$P=caller."::";my%e=(extends=>sub{eval"no $_[0]()";@{$P.'ISA'}=$_[0]},has=>sub{my$n=shift;*{$P.$n}=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}}},);for(@_[1..$#_]){eval"require Mo::$_;1";%e=&{$K."${_}::e"}($P=>%e)}*{$P.$_}=$e{$_}for keys%e;@{$P.'ISA'}=$K.'Object'};*{$K.'builder::e'}=sub{my$P=shift;my%e=@_;my$o=$e{has};$e{has}=sub{my($n,%a)=@_;my$b=$a{builder};*{$P.$n}=$b?sub{$#_?$_[0]{$n}=$_[1]:!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$b:$_[0]{$n}}:$o->(@_)};%e};*{$K.'default::e'}=sub{my$P=shift;my%e=@_;my$o=$e{has};$e{has}=sub{my($n,%a)=@_;my$d=$a{default};*{$P.$n}=$d?sub{$#_?$_[0]{$n}=$_[1]:!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$d:$_[0]{$n}}:$o->(@_)};%e};use strict;use warnings;
no strict 'refs'; no warnings 'redefine';

my $import = \&import;
*import = sub {
    push @_, qw[builder default];
    goto &$import;
};

my ($_new_error);

$_new_error = sub {
    require Carp;
    my $self = shift;
    require YAML::Error;

    my $code = shift || 'unknown error';
    my $error = YAML::Error->new(code => $code);
    $error->line($self->line) if $self->can('line');
    $error->document($self->document) if $self->can('document');
    $error->arguments([@_]);
    return $error;
};

*{$K.'Object::die'} = sub {
    my $self = shift;
    my $error = $self->$_new_error(@_);
    $error->type('Error');
    Carp::croak($error->format_message);
};

*{$K.'Object::warn'} = sub {
    my $self = shift;
    return unless $^W;
    my $error = $self->$_new_error(@_);
    $error->type('Warning');
    Carp::cluck($error->format_message);
};

1;
