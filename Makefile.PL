use ExtUtils::MakeMaker;

my @programs;

for (split "\n", <<'QUERIES') {
ysh|y|YAML Shell
xyx|y|YAML<->XML transform
yaml2outline|y|YAML-to-Outline converter
phone2yaml|y|Palm phone list converter
QUERIES
    my ($program, $default, $description) = split /\|/, $_;
    if (prompt("Do you want to install '$program', the $description?", 
               $default) =~ /^y/) {
	push(@programs, $program);
    }
}

WriteMakefile(
    NAME => 'YAML',
    VERSION_FROM => 'YAML.pm',
    PL_FILES      => { map {("bin/$_.PL" => "bin/$_")} @programs},
    EXE_FILES     => [ map {"bin/$_"} @programs],
    clean => { FILES => 't/data ysh.log bin/ysh bin/yaml2outline bin/phone2yaml bin/xyx' },
);
