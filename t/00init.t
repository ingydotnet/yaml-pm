use strict;
use Config;
use YAML;

mkdir('t/data', 0777) || die "$!" unless -d 't/data';
unpack_tests('t/load.dat');
unpack_tests('t/errors.dat');

my $perl = $Config{perlpath};

print "1..1\n";
my $src_path = './t/data/script';
my $dest_path = './t/data/dumper';
die "Can't find $src_path\n" unless -d $src_path;
mkdir($dest_path, 0777) unless -d $dest_path;

opendir SCRIPTS, $src_path or die $!;
while (my $script = readdir SCRIPTS) {
    next if $script =~ /^\.{1,2}$/;
    open DUMPER, "$perl -It/testlib $src_path/$script |" or die $!;
    my $dump = join '', <DUMPER>;
    close DUMPER;
    open DUMP, "> $dest_path/$script" or die $!;
    print DUMP $dump;
}

print "ok 1\n";

sub unpack_tests {
    my ($filepath) = @_;
    my $testname = '0001';
    my @objects = YAML::LoadFile($filepath);
    for my $object (@objects) {
        for my $directory (grep {$_ ne 'abstract'} keys %$object) {
	    mkdir("t/data/$directory", 0777) || die "$!" 
	      unless -d "t/data/$directory";
	    open TEST, "> t/data/$directory/$testname" or die $!;
	    my $test_stream = $object->{$directory};
	    if ($directory eq 'error') {
	        if ($object->{abstract} eq 'Bad Characters in Stream') {
	            $test_stream =~ s/\Q<CNTL-G>\E/\007/;
		} 
		elsif ($object->{abstract} eq 'No Last Newline in Stream') {
	            $test_stream =~ s/\n\Z//s;
		} 
	    }	
	    print TEST $test_stream;
	    close TEST;
	}
	$testname++;
    }    
}
