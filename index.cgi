#!/usr/bin/perl

use strict;
use CGI qw(:standard);
print header, start_html;

my $num = param('num');
my (@num, %descrip);

$num = sprintf("%04d", ($num + 0));  # Anti Hacker protection

if ($num ne "0000") {
    the_data($num);
}
else {
    the_index();
}

print end_html;

sub the_data {
    my $num = shift;
    print h1($descrip{$num});
    if (-f "t/data/yaml/$num") {
        print h3("YAML");
	my $text = `cat t/data/yaml/$num`;
	$text =~ s/\</\&lt;/g;
        print "<PRE>\n", $text, "</PRE>\n";
    }
    if (-f "t/data/dumper/$num") {
        print h3("Data::Dumper");
	my $text = `cat t/data/dumper/$num`;
	$text =~ s/\</\&lt;/g;
        print "<PRE>\n", $text, "</PRE>\n";
    }
    if (-f "t/data/scripts/$num") {
        print h3("Perl Script");
	my $text = `cat t/data/scripts/$num`;
	$text =~ s/\</\&lt;/g;
        print "<PRE>\n", $text, "</PRE>\n";
    }
}

sub the_index {
    print "<UL>\n";
    for my $num (@num) {
	print "<LI>", a({'-href' => "index.cgi?num=$num"}, 
			$descrip{$num}), "\n";
    }
    print "</UL>\n";
}

BEGIN {
    open INDEX, "< t/data/index" or die $!;
    while (<INDEX>) {
	chomp;
	my ($num, $descrip) = split ':';
	push @num, $num;
	$descrip{$num} = $descrip;
    }
}
