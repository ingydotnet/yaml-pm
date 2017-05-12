use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker;

my %FallbackPrereqs = (
  "Test::More" => "0.88",
  "Test::YAML" => "1.05",
  "TestML" => "0.54",
);

my %WriteMakefileArgs = (
  "ABSTRACT_FROM" => "lib/YAML.pm",
  "AUTHOR" => [
    "Ingy d\x{f6}t Net <ingy\@cpan.org>",
    "Tina Müller <cpan2\@tinita.de>",
  ],
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
  },
  "DISTNAME" => "YAML",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008001",
  "NAME" => "YAML",
  "PREREQ_PM" => {},
  "TEST_REQUIRES" => {
    %FallbackPrereqs,
  },
  "VERSION_FROM" => "lib/YAML.pm",
  "test" => {
    "TESTS" => "t/*.t",
  },
);



unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
