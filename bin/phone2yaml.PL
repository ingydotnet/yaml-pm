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

print OUT <<"!GROK!THIS!", <<'!NO!SUBS!';
$Config{'startperl'} -w

\$VERSION = '$version';

!GROK!THIS!

=head1 NAME

phone2yaml - Convert a Palm phone book to YAML

=head1 USAGE

    phone2yaml phone.tab > phone.yaml

=head1 DESCRIPTION

This program will convert a Palm Pilot phonebook .tab file (tab
separated values) into YAML format. The output can then be easily
processed by using YAML in your favorite programming language.
(Like YAML.pm for Perl) Personally I just grep the YAML file, when
I need a phone number.

=head1 AUTHOR

Brian Ingerson <ingy@cpan.org>

=head1 COPYRIGHT

Copyright 2002, Brian Ingerson - All rights reserved

You may use this hack under the same terms as Perl itself.

=cut

use strict;
use YAML;
use YAML::Node;

my @entries;

while (my $line = <>) {
    $line =~ s/\r\n//g;
    my ($last, $first, $title, $company, $work, $home, $fax, $other, $email,
        $street, $city, $state, $postal, $country, 
        undef, undef, undef, undef, $note, @rest) = 
          map {s/^"(.*)"$/$1/; s/\r/\n/g; $_.="\n" if /\n./; $_} 
            split "\t", $line;

    # YAML Nodes preserve key order.
    my $entry = YAML::Node->new({});
    $entry->{name} = YAML::Node->new({}) if $first or $last;
    $entry->{phones} = YAML::Node->new({}) if $work or $home or $fax or $other;
    $entry->{address} = YAML::Node->new({}) if $street or $city or $state or
                                               $postal or $country;

    $entry->{name}{first} = $first if $first;
    $entry->{name}{last} = $last if $last;
    $entry->{title} = $title if $title;
    $entry->{company} = $company if $company;
    $entry->{phones}{home} = $home if $home;
    $entry->{phones}{work} = $work if $work;
    $entry->{phones}{fax} = $fax if $fax;
    $entry->{phones}{other} = $other if $other;
    $entry->{email} = $email if $email;
    $entry->{address}{street} = $street if $street;
    $entry->{address}{city} = $city if $city;
    $entry->{address}{state} = $state if $state;
    $entry->{address}{postal} = $postal if $postal;
    $entry->{address}{country} = $country if $country;
    $entry->{note} = $note if $note;
    push @entries, $entry;
}

$YAML::UseBlock = 1;
$YAML::UseVersion = 0;
#$YAML::SortKeys = [ qw( name first last title company 
#                        phones work home fax other email
#                        address street city state postal country
#                        note
#                      ) 
#                  ];    
                        
print Dump @entries;

!NO!SUBS!
#vim: set ft=perl
