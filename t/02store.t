BEGIN {
    push @INC, 't/testlib';
}
use YAML_Test;

my @files;
opendir DIR, "t/data/emit";
while (my $file = readdir(DIR)) {
    next if $file =~ /^\.{1,2}$/;
    die "No comparison file t/data/expect/$file found\n"
      unless -f "t/data/expect/$file";
    push @files, $file;
}

print "1..", scalar @files, "\n";

for my $file (@files) {
    TestStore($file);
}
