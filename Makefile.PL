use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'hw1309',
    VERSION_FROM  => 'lib/hw1309.pm',
    PREREQ_PM     => {
        'Kossy' =>  '0.19',
    },
    MIN_PERL_VERSION => '5.008001'
);

