use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'YAML',
    VERSION_FROM => 'YAML.pm',
    clean => { FILES => 't/data/dumper ysh.log' },
);
