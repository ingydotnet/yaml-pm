use strict;
use Config;

my $perl = $Config{perlpath};

print "1..1\n";
my $src_path = './t/data/scripts';
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
