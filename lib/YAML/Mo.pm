##
# name:      YAML::Mo
# abstract:  Mo Base Class for YAML
# author:    Ingy döt Net <ingy@ingy.net>
# license:   perl
# copyright: 2011

package YAML::Mo;
# use Mo qw[builder default];
no warnings;my$K=__PACKAGE__."::";*{$K.'Object::new'}=sub{my$c=shift;my$s=bless{@_},$c;my@B;do{@B=($c.'::BUILD',@B)}while($c)=@{$c.'::ISA'};exists&$_&&&$_($s)for@B;$s};*{$K.'import'}=sub{import warnings;$^H|=1538;my$P=caller."::";my%e=(extends=>sub{eval"no $_[0]()";@{$P.'ISA'}=$_[0]},has=>sub{my$n=shift;*{$P.$n}=sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}}},);for(@_[1..$#_]){eval"require Mo::$_;1";%e=&{$K."${_}::e"}($P=>%e)}*{$P.$_}=$e{$_}for keys%e;@{$P.'ISA'}=$K.'Object'};*{$K.'builder::e'}=sub{my$P=shift;my%e=@_;my$o=$e{has};$e{has}=sub{my($n,%a)=@_;my$b=$a{builder};*{$P.$n}=$b?sub{$#_?$_[0]{$n}=$_[1]:!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$b:$_[0]{$n}}:$o->(@_)};%e};*{$K.'default::e'}=sub{my$P=shift;my%e=@_;my$o=$e{has};$e{has}=sub{my($n,%a)=@_;my$d=$a{default};*{$P.$n}=$d?sub{$#_?$_[0]{$n}=$_[1]:!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$d:$_[0]{$n}}:$o->(@_)};%e};

1;
