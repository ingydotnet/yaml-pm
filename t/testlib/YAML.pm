# This version of Data::Dumper has been rigged to look like the YAML
# module for testing the real YAML.pm.
#
# It was taken from the 5.6.1 distribution, and thus inherits the 
# bugs of that version.
#
# Data/Dumper.pm
#
# convert perl data structures into perl syntax suitable for both printing
# and eval
#
# Documentation at the __END__
#

#package Data::Dumper;
package YAML;

$VERSION = '2.102';

#$| = 1;

# require 5.005_64;
require Exporter;
# use XSLoader ();
require overload;

use Carp;

@ISA = qw(Exporter);
# @EXPORT = qw(Dumper);
# @EXPORT_OK = qw(DumperX);

# XSLoader::load 'Data::Dumper';

# module vars and their defaults
$Indent = 1 unless defined $Indent;
$Purity = 0 unless defined $Purity;
$Pad = "" unless defined $Pad;
$Varname = "VAR" unless defined $Varname;
$Useqq = 0 unless defined $Useqq;
$Terse = 0 unless defined $Terse;
$Freezer = "" unless defined $Freezer;
$Toaster = "" unless defined $Toaster;
$Deepcopy = 0 unless defined $Deepcopy;
$Quotekeys = 1 unless defined $Quotekeys;
$Bless = "bless" unless defined $Bless;
#$Expdepth = 0 unless defined $Expdepth;
$Maxdepth = 0 unless defined $Maxdepth;

#
# expects an arrayref of values to be dumped.
# can optionally pass an arrayref of names for the values.
# names must have leading $ sign stripped. begin the name with *
# to cause output of arrays and hashes rather than refs.
#
sub new {
  my($c, $v, $n) = @_;

  croak "Usage:  PACKAGE->new(ARRAYREF, [ARRAYREF])" 
    unless (defined($v) && (ref($v) eq 'ARRAY'));
  $n = [] unless (defined($n) && (ref($v) eq 'ARRAY'));

  my($s) = { 
             level      => 0,           # current recursive depth
	     indent     => $Indent,     # various styles of indenting
	     pad	=> $Pad,        # all lines prefixed by this string
	     xpad       => "",          # padding-per-level
	     apad       => "",          # added padding for hash keys n such
	     sep        => "",          # list separator
	     seen       => {},          # local (nested) refs (id => [name, val])
	     todump     => $v,          # values to dump []
	     names      => $n,          # optional names for values []
	     varname    => $Varname,    # prefix to use for tagging nameless ones
             purity     => $Purity,     # degree to which output is evalable
             useqq 	=> $Useqq,      # use "" for strings (backslashitis ensues)
             terse 	=> $Terse,      # avoid name output (where feasible)
             freezer	=> $Freezer,    # name of Freezer method for objects
             toaster	=> $Toaster,    # name of method to revive objects
             deepcopy	=> $Deepcopy,   # dont cross-ref, except to stop recursion
             quotekeys	=> $Quotekeys,  # quote hash keys
             'bless'	=> $Bless,	# keyword to use for "bless"
#	     expdepth   => $Expdepth,   # cutoff depth for explicit dumping
	     maxdepth	=> $Maxdepth,   # depth beyond which we give up
	   };

  if ($Indent > 0) {
    $s->{xpad} = "  ";
    $s->{sep} = "\n";
  }
  return bless($s, $c);
}

#
# add-to or query the table of already seen references
#
sub Seen {
  my($s, $g) = @_;
  if (defined($g) && (ref($g) eq 'HASH'))  {
    my($k, $v, $id);
    while (($k, $v) = each %$g) {
      if (defined $v and ref $v) {
	($id) = (overload::StrVal($v) =~ /\((.*)\)$/);
	if ($k =~ /^[*](.*)$/) {
	  $k = (ref $v eq 'ARRAY') ? ( "\\\@" . $1 ) :
	       (ref $v eq 'HASH')  ? ( "\\\%" . $1 ) :
	       (ref $v eq 'CODE')  ? ( "\\\&" . $1 ) :
				     (   "\$" . $1 ) ;
	}
	elsif ($k !~ /^\$/) {
	  $k = "\$" . $k;
	}
	$s->{seen}{$id} = [$k, $v];
      }
      else {
	carp "Only refs supported, ignoring non-ref item \$$k";
      }
    }
    return $s;
  }
  else {
    return map { @$_ } values %{$s->{seen}};
  }
}

#
# set or query the values to be dumped
#
sub Values {
  my($s, $v) = @_;
  if (defined($v) && (ref($v) eq 'ARRAY'))  {
    $s->{todump} = [@$v];        # make a copy
    return $s;
  }
  else {
    return @{$s->{todump}};
  }
}

#
# set or query the names of the values to be dumped
#
sub Names {
  my($s, $n) = @_;
  if (defined($n) && (ref($n) eq 'ARRAY'))  {
    $s->{names} = [@$n];         # make a copy
    return $s;
  }
  else {
    return @{$s->{names}};
  }
}

sub DESTROY {}

sub Dump {
#    return &Dumpxs
#	unless $Data::Dumper::Useqq || (ref($_[0]) && $_[0]->{useqq});
    return &Dumpperl;
}

#
# dump the refs in the current dumper object.
# expects same args as new() if called via package name.
#
sub Dumpperl {
  my($s) = shift;
  my(@out, $val, $name);
  my($i) = 0;
  local(@post);

  $s = $s->new(@_) unless ref $s;

  for $val (@{$s->{todump}}) {
    my $out = "";
    @post = ();
    $name = $s->{names}[$i++];
    if (defined $name) {
      if ($name =~ /^[*](.*)$/) {
	if (defined $val) {
	  $name = (ref $val eq 'ARRAY') ? ( "\@" . $1 ) :
		  (ref $val eq 'HASH')  ? ( "\%" . $1 ) :
		  (ref $val eq 'CODE')  ? ( "\*" . $1 ) :
					  ( "\$" . $1 ) ;
	}
	else {
	  $name = "\$" . $1;
	}
      }
      elsif ($name !~ /^\$/) {
	$name = "\$" . $name;
      }
    }
    else {
      $name = "\$" . $s->{varname} . $i;
    }

    my $valstr;
    {
      local($s->{apad}) = $s->{apad};
      $s->{apad} .= ' ' x (length($name) + 3) if $s->{indent} >= 2;
      $valstr = $s->_dump($val, $name);
    }

    $valstr = "$name = " . $valstr . ';' if @post or !$s->{terse};
    $out .= $s->{pad} . $valstr . $s->{sep};
    $out .= $s->{pad} . join(';' . $s->{sep} . $s->{pad}, @post) 
      . ';' . $s->{sep} if @post;

    push @out, $out;
  }
  return wantarray ? @out : join('', @out);
}

#
# twist, toil and turn;
# and recurse, of course.
#
sub _dump {
  my($s, $val, $name) = @_;
  my($sname);
  my($out, $realpack, $realtype, $type, $ipad, $id, $blesspad);

  $type = ref $val;
  $out = "";

  if ($type) {

    # prep it, if it looks like an object
    if (my $freezer = $s->{freezer}) {
      $val->$freezer() if UNIVERSAL::can($val, $freezer);
    }

    ($realpack, $realtype, $id) =
      (overload::StrVal($val) =~ /^(?:(.*)\=)?([^=]*)\(([^\(]*)\)$/);

    # if it has a name, we need to either look it up, or keep a tab
    # on it so we know when we hit it later
    if (defined($name) and length($name)) {
      # keep a tab on it so that we dont fall into recursive pit
      if (exists $s->{seen}{$id}) {
#	if ($s->{expdepth} < $s->{level}) {
	  if ($s->{purity} and $s->{level} > 0) {
	    $out = ($realtype eq 'HASH')  ? '{}' :
	      ($realtype eq 'ARRAY') ? '[]' :
		'do{my $o}' ;
	    push @post, $name . " = " . $s->{seen}{$id}[0];
	  }
	  else {
	    $out = $s->{seen}{$id}[0];
	    if ($name =~ /^([\@\%])/) {
	      my $start = $1;
	      if ($out =~ /^\\$start/) {
		$out = substr($out, 1);
	      }
	      else {
		$out = $start . '{' . $out . '}';
	      }
	    }
          }
	  return $out;
#        }
      }
      else {
        # store our name
        $s->{seen}{$id} = [ (($name =~ /^[@%]/)     ? ('\\' . $name ) :
			     ($realtype eq 'CODE' and
			      $name =~ /^[*](.*)$/) ? ('\\&' . $1 )   :
			     $name          ),
			    $val ];
      }
    }

    if ($realpack and $realpack eq 'Regexp') {
	$out = "$val";
	$out =~ s,/,\\/,g;
	return "qr/$out/";
    }

    # If purity is not set and maxdepth is set, then check depth: 
    # if we have reached maximum depth, return the string
    # representation of the thing we are currently examining
    # at this depth (i.e., 'Foo=ARRAY(0xdeadbeef)'). 
    if (!$s->{purity}
	and $s->{maxdepth} > 0
	and $s->{level} >= $s->{maxdepth})
    {
      return qq['$val'];
    }

    # we have a blessed ref
    if ($realpack) {
      $out = $s->{'bless'} . '( ';
      $blesspad = $s->{apad};
      $s->{apad} .= '       ' if ($s->{indent} >= 2);
    }

    $s->{level}++;
    $ipad = $s->{xpad} x $s->{level};

    if ($realtype eq 'SCALAR' || $realtype eq 'REF') {
      if ($realpack) {
	$out .= 'do{\\(my $o = ' . $s->_dump($$val, "\${$name}") . ')}';
      }
      else {
	$out .= '\\' . $s->_dump($$val, "\${$name}");
      }
    }
    elsif ($realtype eq 'GLOB') {
	$out .= '\\' . $s->_dump($$val, "*{$name}");
    }
    elsif ($realtype eq 'ARRAY') {
      my($v, $pad, $mname);
      my($i) = 0;
      $out .= ($name =~ /^\@/) ? '(' : '[';
      $pad = $s->{sep} . $s->{pad} . $s->{apad};
      ($name =~ /^\@(.*)$/) ? ($mname = "\$" . $1) : 
	# omit -> if $foo->[0]->{bar}, but not ${$foo->[0]}->{bar}
	($name =~ /^\\?[\%\@\*\$][^{].*[]}]$/) ? ($mname = $name) :
	  ($mname = $name . '->');
      $mname .= '->' if $mname =~ /^\*.+\{[A-Z]+\}$/;
      for $v (@$val) {
	$sname = $mname . '[' . $i . ']';
	$out .= $pad . $ipad . '#' . $i if $s->{indent} >= 3;
	$out .= $pad . $ipad . $s->_dump($v, $sname);
	$out .= "," if $i++ < $#$val;
      }
      $out .= $pad . ($s->{xpad} x ($s->{level} - 1)) if $i;
      $out .= ($name =~ /^\@/) ? ')' : ']';
    }
    elsif ($realtype eq 'HASH') {
      my($k, $v, $pad, $lpad, $mname);
      $out .= ($name =~ /^\%/) ? '(' : '{';
      $pad = $s->{sep} . $s->{pad} . $s->{apad};
      $lpad = $s->{apad};
      ($name =~ /^\%(.*)$/) ? ($mname = "\$" . $1) :
	# omit -> if $foo->[0]->{bar}, but not ${$foo->[0]}->{bar}
	($name =~ /^\\?[\%\@\*\$][^{].*[]}]$/) ? ($mname = $name) :
	  ($mname = $name . '->');
      $mname .= '->' if $mname =~ /^\*.+\{[A-Z]+\}$/;
#      while (($k, $v) = each %$val) {
      foreach $k (sort keys %$val) {
	$v = $val->{$k};
	my $nk = $s->_dump($k, "");
	$nk = $1 if !$s->{quotekeys} and $nk =~ /^[\"\']([A-Za-z_]\w*)[\"\']$/;
	$sname = $mname . '{' . $nk . '}';
	$out .= $pad . $ipad . $nk . " => ";

	# temporarily alter apad
	$s->{apad} .= (" " x (length($nk) + 4)) if $s->{indent} >= 2;
	$out .= $s->_dump($val->{$k}, $sname) . ",";
	$s->{apad} = $lpad if $s->{indent} >= 2;
      }
      if (substr($out, -1) eq ',') {
	chop $out;
	$out .= $pad . ($s->{xpad} x ($s->{level} - 1));
      }
      $out .= ($name =~ /^\%/) ? ')' : '}';
    }
    elsif ($realtype eq 'CODE') {
      $out .= 'sub { "DUMMY" }';
      carp "Encountered CODE ref, using dummy placeholder" if $s->{purity};
    }
    else {
      croak "Can\'t handle $realtype type.";
    }
    
    if ($realpack) { # we have a blessed ref
      $out .= ', \'' . $realpack . '\'' . ' )';
      $out .= '->' . $s->{toaster} . '()'  if $s->{toaster} ne '';
      $s->{apad} = $blesspad;
    }
    $s->{level}--;

  }
  else {                                 # simple scalar

    my $ref = \$_[1];
    # first, catalog the scalar
    if ($name ne '') {
      ($id) = ("$ref" =~ /\(([^\(]*)\)$/);
      if (exists $s->{seen}{$id}) {
        if ($s->{seen}{$id}[2]) {
	  $out = $s->{seen}{$id}[0];
	  #warn "[<$out]\n";
	  return "\${$out}";
	}
      }
      else {
	#warn "[>\\$name]\n";
	$s->{seen}{$id} = ["\\$name", $ref];
      }
    }
    if (ref($ref) eq 'GLOB' or "$ref" =~ /=GLOB\([^()]+\)$/) {  # glob
      my $name = substr($val, 1);
      if ($name =~ /^[A-Za-z_][\w:]*$/) {
	$name =~ s/^main::/::/;
	$sname = $name;
      }
      else {
	$sname = $s->_dump($name, "");
	$sname = '{' . $sname . '}';
      }
      if ($s->{purity}) {
	my $k;
	local ($s->{level}) = 0;
	for $k (qw(SCALAR ARRAY HASH)) {
	  my $gval = *$val{$k};
	  next unless defined $gval;
	  next if $k eq "SCALAR" && ! defined $$gval;  # always there

	  # _dump can push into @post, so we hold our place using $postlen
	  my $postlen = scalar @post;
	  $post[$postlen] = "\*$sname = ";
	  local ($s->{apad}) = " " x length($post[$postlen]) if $s->{indent} >= 2;
	  $post[$postlen] .= $s->_dump($gval, "\*$sname\{$k\}");
	}
      }
      $out .= '*' . $sname;
    }
    elsif (!defined($val)) {
      $out .= "undef";
    }
    elsif ($val =~ /^(?:0|-?[1-9]\d{0,8})$/) { # safe decimal number
      $out .= $val;
    }
    else {				 # string
      if ($s->{useqq}) {
	$out .= qquote($val, $s->{useqq});
      }
      else {
	$val =~ s/([\\\'])/\\$1/g;
	$out .= '\'' . $val .  '\'';
      }
    }
  }
  if ($id) {
    # if we made it this far, $id was added to seen list at current
    # level, so remove it to get deep copies
    if ($s->{deepcopy}) {
      delete($s->{seen}{$id});
    }
    elsif ($name) {
      $s->{seen}{$id}[2] = 1;
    }
  }
  return $out;
}
  
#
# non-OO style of earlier version
#
sub Dumper {
#  return Data::Dumper->Dump([@_]);
  return YAML->Dump([@_]);
}
*Store = \&Dumper;

# compat stub
#sub DumperX {
#  return Data::Dumper->Dumpxs([@_], []);
#}

#sub Dumpf { return Data::Dumper->Dump(@_) }

#sub Dumpp { print Data::Dumper->Dump(@_) }

#
# reset the "seen" cache 
#
sub Reset {
  my($s) = shift;
  $s->{seen} = {};
  return $s;
}

sub Indent {
  my($s, $v) = @_;
  if (defined($v)) {
    if ($v == 0) {
      $s->{xpad} = "";
      $s->{sep} = "";
    }
    else {
      $s->{xpad} = "  ";
      $s->{sep} = "\n";
    }
    $s->{indent} = $v;
    return $s;
  }
  else {
    return $s->{indent};
  }
}

sub Pad {
  my($s, $v) = @_;
  defined($v) ? (($s->{pad} = $v), return $s) : $s->{pad};
}

sub Varname {
  my($s, $v) = @_;
  defined($v) ? (($s->{varname} = $v), return $s) : $s->{varname};
}

sub Purity {
  my($s, $v) = @_;
  defined($v) ? (($s->{purity} = $v), return $s) : $s->{purity};
}

sub Useqq {
  my($s, $v) = @_;
  defined($v) ? (($s->{useqq} = $v), return $s) : $s->{useqq};
}

sub Terse {
  my($s, $v) = @_;
  defined($v) ? (($s->{terse} = $v), return $s) : $s->{terse};
}

sub Freezer {
  my($s, $v) = @_;
  defined($v) ? (($s->{freezer} = $v), return $s) : $s->{freezer};
}

sub Toaster {
  my($s, $v) = @_;
  defined($v) ? (($s->{toaster} = $v), return $s) : $s->{toaster};
}

sub Deepcopy {
  my($s, $v) = @_;
  defined($v) ? (($s->{deepcopy} = $v), return $s) : $s->{deepcopy};
}

sub Quotekeys {
  my($s, $v) = @_;
  defined($v) ? (($s->{quotekeys} = $v), return $s) : $s->{quotekeys};
}

sub Bless {
  my($s, $v) = @_;
  defined($v) ? (($s->{'bless'} = $v), return $s) : $s->{'bless'};
}

sub Maxdepth {
  my($s, $v) = @_;
  defined($v) ? (($s->{'maxdepth'} = $v), return $s) : $s->{'maxdepth'};
}


# used by qquote below
my %esc = (  
    "\a" => "\\a",
    "\b" => "\\b",
    "\t" => "\\t",
    "\n" => "\\n",
    "\f" => "\\f",
    "\r" => "\\r",
    "\e" => "\\e",
);

# put a string value in double quotes
sub qquote {
  local($_) = shift;
  s/([\\\"\@\$])/\\$1/g;
  return qq("$_") unless 
    /[^ !"\#\$%&'()*+,\-.\/0-9:;<=>?\@A-Z[\\\]^_`a-z{|}~]/;  # fast exit

  my $high = shift || "";
  s/([\a\b\t\n\f\r\e])/$esc{$1}/g;

  if (ord('^')==94)  { # ascii
    # no need for 3 digits in escape for these
    s/([\0-\037])(?!\d)/'\\'.sprintf('%o',ord($1))/eg;
    s/([\0-\037\177])/'\\'.sprintf('%03o',ord($1))/eg;
    # all but last branch below not supported --BEHAVIOR SUBJECT TO CHANGE--
    if ($high eq "iso8859") {
      s/([\200-\240])/'\\'.sprintf('%o',ord($1))/eg;
    } elsif ($high eq "utf8") {
#     use utf8;
#     $str =~ s/([^\040-\176])/sprintf "\\x{%04x}", ord($1)/ge;
    } elsif ($high eq "8bit") {
        # leave it as it is
    } else {
      s/([\200-\377])/'\\'.sprintf('%03o',ord($1))/eg;
    }
  }
  else { # ebcdic
      s{([^ !"\#\$%&'()*+,\-.\/0-9:;<=>?\@A-Z[\\\]^_`a-z{|}~])(?!\d)}
       {my $v = ord($1); '\\'.sprintf(($v <= 037 ? '%o' : '%03o'), $v)}eg;
      s{([^ !"\#\$%&'()*+,\-.\/0-9:;<=>?\@A-Z[\\\]^_`a-z{|}~])}
       {'\\'.sprintf('%03o',ord($1))}eg;
  }

  return qq("$_");
}

1;
__END__
