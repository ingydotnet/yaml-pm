package TestYAML;
use strict;
use YAML::Base;

my %args;
my $tests = [];

sub tests { 
    return @$tests if not $args{only};
    my @indices = map {
        $_ - 1;
    } ref($args{only}) ? @{$args{only}} : $args{only};
    return @{$tests}[@indices];
}

sub import {
    my $class = shift;
    %args = @_;
    $class->parse_file($args{test_file});
    my $package = caller;
    {
        no strict 'refs';
        *{$package . '::MAX'} = sub { scalar @$tests };
        *{$package . '::tests'} = \&tests;
    }
}

sub parse_file {
    my $self = shift;
    my $file = shift;
    open FILE, $file or die "Can't open $file for input";
    my $data = do {local $/; <FILE>};
    close FILE;
    $data =~ /(.*)/;
    my $separator = "^$1\n";
    my @parts = ($data =~ /($separator.*?(?=(?:$separator|\z)))/gsm);
    for my $part (@parts) {
        my @test = split /^(###|\*\*\*|\+\+\+)\n/m, $part;
        shift @test;
        my %test = @test;
        $test{perl} = delete $test{'###'}
          if $test{'###'};
        $test{yaml} = delete $test{'+++'}
          if $test{'+++'};
        if ($test{'***'}) {
            $test{events_string} = delete $test{'***'};
            $test{events} = [];
            for (split /\n/, $test{events_string}) {
                my ($event, @args) = split;
                @args = map { 
                    s/^_$//g; 
                    s/_/ /g; 
                    s/\\n/\n/g; 
                    no strict 'refs';
                    $_ = &{"YAML::Base::$_"} if /^[A-Z]+$/;
                    $_;
                } @args;
                push @{$test{events}}, [$event, @args];
            }
        }
        push @$tests, \%test;
    }
}

1;
