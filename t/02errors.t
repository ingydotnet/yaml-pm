BEGIN {
    push @INC, 't/testlib';
}
use YAML_Test;

my @files;
opendir DIR, "t/data/error";
while (my $file = readdir(DIR)) {
    next if $file =~ /^\.{1,2}$/;
    die "No comparison file t/data/message/$file found\n"
      unless -f "t/data/message/$file";
    push @files, $file;
}

print "1..", scalar @files, "\n";

for my $file (@files) {
    TestError($file);
}
