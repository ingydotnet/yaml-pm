##
# name:      YAML::Mo
# abstract:  Mo Base Class for YAML
# author:    Ingy döt Net <ingy@ingy.net>
# license:   perl
# copyright: 2011

package YAML::Mo;
no warnings;my$P=__PACKAGE__.'::';*{$P.import}=sub{import warnings;$^H|=1538;my$p=caller.::;@{$p.ISA}=$P.'Object';*{$p.extends}=sub{eval"no $_[0]()";@{$p.ISA}=$_[0]};*{$p.has}=sub{my($n,%a)=@_;my$d=$a{default}||$a{builder};*{$p.$n}=$d?sub{$#_?$_[0]{$n}=$_[1]:!exists$_[0]{$n}?$_[0]{$n}=$_[0]->$d:$_[0]{$n}}:sub{$#_?$_[0]{$n}=$_[1]:$_[0]{$n}}}};*{$P.'Object::new'}=sub{$c=shift;my$s=bless{@_},$c;my@c;do{@c=($c.::BUILD,@c)}while($c)=@{$c.::ISA};exists&$_&&&$_($s)for@c;$s};

# This code needs to be refactored to be simpler and more precise, and no,
# Scalar::Util doesn't DWIM.
#
# Can't handle:
# * blessed regexp
sub node_info {
    my $self = shift;
    my $stringify = $_[1] || 0;
    my ($class, $type, $id) =
        ref($_[0])
        ? $stringify
          ? &$_info("$_[0]")
          : do {
              require overload;
              my @info = &$_info(overload::StrVal($_[0]));
              if (ref($_[0]) eq 'Regexp') {
                  @info[0, 1] = (undef, 'REGEXP');
              }
              @info;
          }
        : &$_scalar_info($_[0]);
    ($class, $type, $id) = &$_scalar_info("$_[0]")
        unless $id;
    return wantarray ? ($class, $type, $id) : $id;
}
