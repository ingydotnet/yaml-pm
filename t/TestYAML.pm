BEGIN { $^W = 1 }
use strict;
use YAML;
use Test;
use TestDumper;
use diagnostics;

my $current_test = 1;
my $output = '';

sub test_basic {
    my ($abstract, $load, $expect) = @_;
    ok(TestDump(YAML::Load($load)), 
       eval $expect, 
       "Failed while testing: $abstract"
      );
}

# A hack so that the tests can have a place to put stuff:
use vars qw(*joe_random_global);

sub test_round_trip {
    my (@tests_as_yaml) = @_;
    for (pick_which_tests_to_run(@tests_as_yaml)) {
        eval {
            run_round_trip_case($_);
        }; if ($@) {
            $output .= "not ok " . $current_test++ . "\n";
            $output .= $@;
        }
    }
    my $total_tests = $current_test - 1;
    print "1..$total_tests\n$output";
}

sub run_round_trip_case {
    $_ = shift;
    my ($perl_input, $yaml_input, $config) = @$_{qw(perl yaml config)};

    # Make sure this gets reset:
    local *joe_random_global;

    (my $pseudo_id = $perl_input) =~ s/\s+/ /g;

    $config ||= '';

    my @perl_struct = eval $perl_input;
    die $@ if $@;

    my $first_dump = eval( $config . '; YAML::Dump(@perl_struct)' );
    die $@ if $@;
    # Hack for 5.8.0 B::Deparse
    $first_dump =~ s/^\s*use strict 'refs';\n//m;

    is($first_dump, $yaml_input, "manual: $pseudo_id");

    return if $_->{'no-round-trip'};

    my @loaded = YAML::Load($first_dump);
    # TODO: Add another assertion here

    my $second_dump = eval( $config . '; YAML::Dump(@loaded)' );
    die $@ if $@;

    is($second_dump, $first_dump, "round-tripped: $pseudo_id");
}

sub test_pass {
    my @test_objects = pick_single_tests(@_);

    plan(tests=>scalar @test_objects);

    for (@test_objects) {
        eval {YAML::Load($_)};
        ok($@, '', "Parse failed for:\n$_\nError was:$@\n") 
    }
}

sub test_fail {
    my @test_objects = pick_single_tests(@_);

    plan(tests=>scalar @test_objects);

    for (@test_objects) {
        eval {YAML::Load($_)};
        ok($@);
        warn "The following parsed when it ought not to have:\n$_" unless $@;
    }
}

sub pick_single_tests {
    my @tests = split /^\.\.\.\n/m, join '', @_;
    my @solo_tests = grep {s/^only\n//i} @tests;
    return (@solo_tests ? (@solo_tests) : (@tests));
}

sub test_load {
    my (@tests_as_yaml) = @_;
    my @test_objects = pick_which_tests_to_run(@tests_as_yaml);

    plan(tests=>scalar @test_objects);

    for (@test_objects) {
        my $config = $_->{config} || '';
        ok((eval {eval $config;TestDump(YAML::Load($_->{load}))}) || $@, 
           TestDump(eval $_->{expect})); 
    }
}

sub test_errors {
    my @test_objects = YAML::Load(join '', @_);

    plan(tests=>scalar @test_objects);

    for (@test_objects) {
        if ($_->{error} eq 'YAML_PARSE_ERR_BAD_CHARS') {
            $_->{load} =~ s/\Q<%CNTL-G%>\E/\007/;
        } 
        my $warning = '';
        local $SIG{__WARN__} = sub { $warning = join '', @_ };
        if (defined $_->{code}) {
            eval $_->{code};
        }
        else {
            eval {YAML::Load($_->{load})};
        }
        $@ ||= $warning;
        if ($@) {
            my $real_error = $@;
            $@ =~ s/.*?\ncode:\s+(\w+).*/$1/s;
            ok($@, $_->{error},
               "\nReally got this error:\n$real_error\n"
              );
        }
        else {
            print STDERR "Loaded ok when expected failure: $_->{error}\n";
            ok(0);
        }
    }
}

# Because Test.pm is... umm... "less than featureful".
sub is {
    my ($x, $y, $id) = @_;
    if ($x ne $y) {
        s/\n/\n# /g for $x, $y;
        my $msg = <<EOFAILURE;
#     Failed test ('$id')
#          got: '$x'
#     expected: '$y'
EOFAILURE
        $output .= "not ok $current_test\n$msg";
    } else {
        $output .= "ok $current_test\n" unless $ENV{HUSH};
    }
    $current_test++
}

sub pick_which_tests_to_run {
    my @test_objects = YAML::Load(join '', @_);
    my @flagged_test_objects = grep { $_->{only} } @test_objects;
    @test_objects = @flagged_test_objects if @flagged_test_objects;
    @test_objects;
}

1;
