package TestChunks;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT = qw(plan number_of_tests test_load);
use Test::More;
use YAML;
use Spiffy -XXX;
use Data::Dumper;

our $line;   # line number in source of first line of DATA

sub test_load {
    for my $test (get_tests()) {
        my @result = eval {
            YAML::Load($test->{yaml})
        };
        my $error1 = $@ || '';
	if ( $error1 ) {
	    $error1 =~ s{line: (\d+)}{"line: $1   ($0:".($1+$test->{lines}{yaml}-1).")"}e;
	}
        my @expect = eval $test->{perl};
        my $error2 = $@ || ''; 
        if (my $errors = $error1 . $error2) {
            fail($test->{description}
		  . $errors);
            next;
        }
        is_deeply(
            \@result,
            \@expect,
            $test->{description},
        ) or do {
	    diag("Wanted: ".Dumper(\@expect));
	    diag("Got: ".Dumper(\@result));
	}
    }
}

sub number_of_tests {
    scalar get_tests();
}

sub get_tests {
    my $data = get_data();
    my @chunks = ($data =~ /^(===.*?(?=^===|\z))/msg);
    my @tests;
    my $rel_line = 0;
    for my $chunk (@chunks) {
	my $chunk_lines = ($chunk =~ y/\n/\n/);
        my $test = {};
	#print STDERR "chunk is: >-\n$chunk\n...\n";
        $chunk =~ s/\A===[ \t]*(.*)\s+// or die;
        my $description = $1 || 'No test description';
	my $part_line_num = 1;
        my @parts = split /^\+\+\+\s+(\w+)\s+/m, $chunk;
        shift @parts;
	$part_line_num++;
	while ( my ($label, $data) = splice @parts, 0, 2) {
	    $test->{$label} = $data;
	    $test->{lines}{$label} = $rel_line + $line + $part_line_num;
	    $part_line_num += $data =~ y/\n/\n/ + 1;
	}
        $test->{description} = ($description." ($0:".($rel_line+$line).")");
	#print STDERR "test starts line offset: ".($rel_line+$line).
		#" parts (@{[%{$test->{lines}}]})\n";
        return @tests = $test if defined $test->{only};
        push @tests, $test;
	$rel_line += $chunk_lines;
    }
    return @tests;
}

my $data;
sub get_data {
    no warnings;
    $data or ((($data, $line) = do {
	package main;
	my $loc = tell DATA;
	seek DATA, 0, 0;
	my $x;
	read(DATA,$x,$loc);
	seek DATA, $loc, 0;
	my $line = ($x =~ tr/\n/\n/)+1;
	local $/;
	(<DATA>, $line)
    }), $data);
}

1;
