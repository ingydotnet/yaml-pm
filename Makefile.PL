use ExtUtils::MakeMaker;

my @programs;

if (prompt("Do you want to install 'ysh', the YAML Shell?", "y") =~ /^y/) {
    push(@programs, 'ysh');
}

WriteMakefile(
    NAME => 'YAML',
    VERSION_FROM => 'YAML.pm',
    PL_FILES      => { map {("bin/$_.PL" => "bin/$_")} @programs},
    EXE_FILES     => [ map {"bin/$_"} @programs],
    clean => { FILES => 't/data ysh.log bin/ysh' },
);
