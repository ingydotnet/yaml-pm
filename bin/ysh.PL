use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
        if ($Config{'osname'} eq 'VMS' or
            $Config{'osname'} eq 'OS2');  # "case-forgiving"

open YAMLPM, "< ../YAML.pm" or die $!;
$version = "unknown";
while (<YAMLPM>) {
    if (/\bVERSION\b/ && /(\d\.\d\d)/) {
	$version = "$1";
    }
}
close YAMLPM;
	    
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w

\$VERSION = '$version';
\$perl_version = '$Config{version}';

!GROK!THIS!

print OUT <<'!NO!SUBS!';

=head1 NAME

ysh - The YAML Test Shell

=head1 SYNOPSIS

 ysh [-l | -L] [-r | -R] [-c] [-v | -V] [-h]

=head1 DESCRIPTION

This program is designed to let you play with the YAML.pm module in
an interactive way. When you to type in Perl, you get back YAML. And
vice versa.

By default, every line you type is a one line Perl program, the return
value of which will be displayed as YAML.

To enter multi-line Perl code start the first line with ';' and use as
many lines as needed. Terminate with a line containing just ';'.

To enter YAML text, start with a valid YAML separator/header line
which is typically '---'. Use '===' to indicate that there is no YAML
header. Enter as many lines as needed. Terminate with a line
containing just '...'.

=head1 COMMAND LINE OPTIONS

=over 4

NOTE: Whenever you find a bug in YAML.pm, please try to recreate it in
      ysh using the '-l' or '-L' flags. Then send the log file to
      ingy@cpan.org.

=item -l

Keep a log of all ysh activity in './ysh.log'. If the log file already
exists, new content will be concatenated to it.

=item -L

Keep a log of all ysh activity in './ysh.log'. If the log file already
exists, it will be deleted first.

=item -r

Test roundtripping. Every piece of Perl code entered will be Stored,
Loaded, and Stored again. If the two stores do not match, an error
message will be reported.

=item -R

Same as above, except that a confirmation message will be printed when
everything is fine.

=item -c

Shortcut for setting '$YAML::PerlCode = 1'. Allows subroutine references
to be processed.

=item -v

Print the versions of ysh and YAML.pm.

=item -V

In addition to the -v info, print the versions of YAML related modules.

=item -h

Print a help message.

=back

=head1 SEE ALSO

L<YAML>

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=cut

use strict;

use Term::ReadLine;
use YAML;
use Data::Dumper;
use vars qw($prompt);
$prompt = 'ysh > ';
my $round_trip = 0;
my $force = 0;
my $log = 0;
$| = 1;

while (my $arg = shift @ARGV) {
    handle_help(), exit if $arg =~ /^-h$/;
    handle_version(), exit if $arg =~ /^-v$/;
    handle_Version(), exit if $arg =~ /^-V$/;
    $YAML::PerlCode = 1, next if $arg =~ /^-c$/;
    $round_trip = 1, next if $arg =~ /^-r$/;
    $round_trip = 2, next if $arg =~ /^-R$/;
    $log = 1, next if $arg =~ /^-l$/;
    $log = 2, next if $arg =~ /^-L$/;
    $force = 1, next if $arg =~ /^-F$/;
    warn(<<END), exit; 
Unknown YAML Shell argument: '$arg'.
For help, try: perldoc ysh
END
}

check_install() unless $force;

if ($log) {
    if ($log == 2) {
        open LOGFILE, "> ./ysh.log" or die $!;
    }
    else {
        open LOGFILE, ">> ./ysh.log" or die $!;
    }
    print LOGFILE "\nYAML.pm Version $YAML::VERSION\n";
    print LOGFILE "Begin logging at ", scalar localtime, "\n\n";
}

sub Print {
    print @_;
    print LOGFILE @_ if $log;
}
local $SIG{__WARN__} = sub { Print @_ };

Print "Welcome to the YAML Test Shell. Type ':help' for more information\n\n";

{
    my $sh = Term::ReadLine::->new('The YAML Shell');
    #$readline::rl_completion_function =
    #$readline::rl_completion_function = sub { () };
    sub my_readline {
        print LOGFILE $prompt if $log;
        $sh->readline($prompt) . "\n";
    }
}

while ($_ = my_readline()) {
    print LOGFILE $_ if $log;
    next if /^\s*$/;
    handle_command($_),next if /^:/;
    handle_file($1),next if /^<\s*(\S+)\s*$/;
    handle_yaml($_),next if /^--\S/;
    handle_yaml(''),next if /^===$/;
    handle_perl($_,1),next if /^;/;
    handle_perl($_,0),next;
    Print "Unknown command. Type ':help' for instructions.\n";
}

sub handle_file {
    my ($file) = $1;
    my @objects;
    eval { @objects = YAML::LoadFile("$file") };
    if ($@) {
        Print $@;
    }
    else {
        Print Data::Dumper::Dumper(@objects);
    }
}
    
sub handle_perl {
    my ($perl, $multi) = @_;
    my (@objects, $yaml, $yaml2);
    local $prompt = 'perl> ';
    my $line = '';
    if ($multi) {
        while ($line !~ /^;$/) {
            $line = my_readline();
            print LOGFILE $line if $log;
            $perl .= $line;
        }
    }
    @objects = eval "no strict;$perl";
    Print("Bad Perl expression:\n$@"), return if $@;
    eval { $yaml = Store(@objects) };
    $@ =~ s/^ at.*\Z//sm if $@;
    Print("Store failed:\n$@"), return if $@;
    # my $yaml1 = $yaml;  #
    # $yaml1 =~ s/ /_/g;  #
    # $yaml1 =~ s/\n/+/g; #
    # Print $yaml1, "\n"; #
    Print $yaml;
    if ($round_trip) {
        {
            local $SIG{__WARN__} = sub {};
            eval { $yaml2 = Store(Load($yaml)) };
        }
        $@ =~ s/^ at.*\Z//sm if $@;
        Print("Load failed:\n$@"), return if $@;
        if ($yaml eq $yaml2) {
            if ($round_trip > 1) {
                Print "\nData roundtripped OK!!!\n";
            }
        }
        else {
            Print "================\n";
            Print "after roundtrip:\n";
            Print "================\n";
            # $yaml2 =~ s/ /_/g;  #
            # $yaml2 =~ s/\n/+/g; #
            # Print $yaml2, "\n"; #
            Print $yaml2;
            Print "=========================\n";
            Print "Data did NOT roundtrip...\n";
        }
    }
}

sub handle_yaml {
    my $yaml = shift;
    my $line = $yaml;
    my (@objects);
    local $prompt = 'yaml> ';
    $line = my_readline();
    print LOGFILE $line if $log;
    $line = '' unless defined $line;
    while ($line !~ /^\.{3}$/) {
        $yaml .= $line;
        $line = my_readline();
        print LOGFILE $line if $log;
        last unless defined $line;
    }
    eval { @objects = Load($yaml) };
    $@ =~ s/^ at.*\Z//sm if $@;
    $@ =~ s/^/  /gm if $@;
    Print("YAML Load Failed:\n$@"), return if $@;
    Print Data::Dumper::Dumper(@objects);
}

sub handle_command {
    my $line = shift;
    chomp $line;
    my ($cmd, $args);
    if ($line =~ /^:(\w+)\s*(.*)$/) {
        $cmd = $1;
        $args = $2;
        exit if $cmd =~ /^(exit|q(uit)?)$/;
        handle_help(),return if $cmd eq 'help';
        print `clear`,return if $cmd =~ /^c(lear)?$/;
    }
    Print "Invalid command\n";
}

sub handle_help {
    Print <<END;
                      Welcome to the YAML Test Shell.

   When you to type in Perl, you get back YAML. And vice versa.

   By default, every line you type is a one line Perl program, the
   return value of which will be displayed as YAML.

   To enter multi-line Perl code start the first line with ';' and use
   as many lines as needed. Terminate with a line containing just ';'.

   To enter YAML text, start with a valid YAML separator/header line
   which is typically '---'. Use '===' to indicate that there is no YAML
   header. Enter as many lines as needed. Terminate with a line
   containing just '...'.

   Shell Commands:             (Begin with ':')
      :exit or :q(uit) - leave the shell
      :help - get this help screen

END
}

sub check_install {
    if (-f "./YAML.pm" && -f "./pm_to_blib" &&
        -M "./YAML.pm" <  -M "./pm_to_blib"
       ) {
        die "You need to 'make install'!\n";
    }
}

sub handle_version {
    print STDERR <<END;

ysh: '$main::VERSION'
YAML: '$YAML::VERSION'

END
}

sub handle_Version {
    my $TRP = get_version('Term::ReadLine::Perl');
    my $TRG = get_version('Term::ReadLine::Gnu');
    my $POE = get_version('POE');
    my $TO = get_version('Time::Object');

    print STDERR <<END;

ysh: '$main::VERSION'
YAML: '$YAML::VERSION'
perl: '$main::perl_version'
Data::Dumper: '$Data::Dumper::VERSION'
Term::ReadLine::Perl: '$TRP'
Term::ReadLine::Gnu: '$TRG'
POE: '$POE'
Time::Object: '$TO'

END
}

sub get_version {
    my ($module) = @_;
    my $version;
    eval "no strict; use $module; \$version = \$${module}::VERSION";
    #$version = "$@" if $@;
    $version = "not installed" if $@;
    return $version;
}

1;
!NO!SUBS!
