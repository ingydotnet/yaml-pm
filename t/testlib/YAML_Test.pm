package YAML_Test;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(SetTestNumber TestLoad TestStore TestError);

use strict;
use YAML;

#==============================================================================
# These subroutines are used to support the YAML test suite
#==============================================================================
my $test_number = 1;

sub SetTestNumber {
    $test_number = shift;
}

sub TestLoad {
    eval "use lib qw(./t/testlib)";
    croak $@ if $@;
    eval "use Yumper";
    croak $@ if $@;
    eval "use diagnostics";
    croak $@ if $@;

    my $test = shift;
    my ($yaml, $yumper, $dumper, @objects);
    if (-f "./t/data/yaml/$test" &&
        -f "./t/data/dumper/$test"
       ) {
        open MYYAML, "< ./t/data/yaml/$test" or croak $!;
        open DUMPER, "< ./t/data/dumper/$test" or croak $!;
        $yaml = join '', <MYYAML>;
        $dumper = join '', <DUMPER>;
        close MYYAML;
        close DUMPER;
        eval { @objects = YAML::Load($yaml) };
        if (not $@) {
            $yumper = Yumper(@objects);
            if ($yumper eq $dumper) {
                print "ok $test_number\n";
            }
            else {
		local $YAML::UseBlock = 1;
                print STDERR YAML::Store({test => $test_number,
		                          result => $yumper,
				          expected => $dumper,
				         });
                print "not ok $test_number\n"
            }
        }
        else {
            warn $@;
            print "not ok $test_number\n";
        }
    }
    else {
        warn "Invalid test file '$test'\n";
        print "not ok $test_number\n";
    }
    $test_number++;
}

sub TestStore {
    eval "use diagnostics";
    croak $@ if $@;

    my $test = shift;
    my ($emit, $result, $expect);
    if (-f "./t/data/emit/$test" &&
        -f "./t/data/expect/$test"
       ) {
        open EMIT, "< ./t/data/emit/$test" or croak $!;
        open EXPECT, "< ./t/data/expect/$test" or croak $!;
        $emit = join '', <EMIT>;
        $expect = join '', <EXPECT>;
        close EMIT;
        close EXPECT;
        $result = eval "$emit";
        if (not $@) {
            if ($result eq $expect) {
                print "ok $test_number\n";
            }
            else {
		local $YAML::UseBlock = 1;
                print STDERR YAML::Store({test => $test_number,
		                          result => $result,
				          expected => $expect,
				         });
                print "not ok $test_number\n"
            }
        }
        else {
            warn $@;
            print "not ok $test_number\n";
        }
    }
    else {
        warn "Invalid test file '$test'\n";
        print "not ok $test_number\n";
    }
    $test_number++;
}

sub TestError {
    my $test = shift;
    my ($yaml, $message, @objects);
    if (-f "./t/data/error/$test" &&
        -f "./t/data/message/$test"
       ) {
        open MYYAML, "< ./t/data/error/$test" or croak $!;
        open MESSAGE, "< ./t/data/message/$test" or croak $!;
        $yaml = join '', <MYYAML>;
        $message = join '', <MESSAGE>;
        close MYYAML;
        close MESSAGE;
	my $error = '';
	my $warning = '';
	{
	    local $SIG{__WARN__} = sub { $warning .= join '', @_ };
            eval { @objects = YAML::Load($yaml) };
	    $error = $@ || $warning;
	}    
        if ($error) {
	    $error =~ s/^ at .*//sm;
            if ($error eq $message) {
                print "ok $test_number\n";
            }
            else {
		warn "The folowing message was not what I expected:\n$error\n";
                print "not ok $test_number\n";
            }
        }
	else {
            warn "Warning. Supposedly bad YAML parsed correctly in t/data/error/$test\n";
            print "not ok $test_number\n";
        }
    }
    else {
        warn "Invalid test file '$test'\n";
        print "not ok $test_number\n";
    }
    $test_number++;
}

1;
