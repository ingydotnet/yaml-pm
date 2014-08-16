use strict;
use lib -e 't' ? 't' : 'test';
use TestYAML tests => 25;

no_diff;
run_yaml_tests;

__DATA__

=== Date: Tue, 03 Jan 2006 18:04:56
+++ perl: { key1 => '>value1' }
+++ yaml
---
key1: '>value1'



=== Date: Wed, 04 Jan 2006 10:23:18
+++ perl: { key1 => '|value' }
+++ yaml
---
key1: '|value'



=== Date: Thu, 3 Mar 2005 14:12:10
+++ perl: { "foo,bar" => "baz"}
+++ yaml
---
'foo,bar': baz



=== Date: Wed, 9 Mar 2005 09:16:19
+++ perl: {'a,v' => 'c'}
+++ yaml
---
'a,v': c



=== Date: Fri, 18 Mar 2005 15:08:57
+++ perl: {'foo[bar', 'baz'}
+++ yaml
---
'foo[bar': baz



=== Date: Sun, 20 Mar 2005 16:32:50
+++ subject: Argument "E5" isn't numeric in multiplication (*)
+++ function: load_passes
+++ yaml
--- #YAML:1.0 !!perl/Blam::Game
board:
  E5: R1
history:
  - 1E5



=== Date: Sat, 26 Mar 2005 22:55:55
+++ perl: {"a - a" => 1}
+++ yaml
---
'a - a': 1



=== Date: Sun, 8 May 2005 15:42:04
+++ skip_this_for_now
+++ perl: [{q</.*/> => {any_key => { } }}]
+++ yaml
---
- /.*/:
    any_key: {}



=== Date: Thu, 12 May 2005 14:57:20
+++ function: load_passes
+++ yaml
--- #YAML:1.0

WilsonSereno1998:
    authors:
        - Wilson, Jeffrey. A
        - Paul C. Sereno
    title: Early evolution and Higher-level phylogeny of sauropod dinosaurs
    year: 1998
    journal: Journal of Vertebrate Paleontology, memoir
    volume: 5
    pages: 1-68

WedelEtAl2000:
    authors:
        - Wedel, M. J.
        - R. L. Cifelli
        - R. K. Sanders
    year: 2000
    title: _Sauroposeidon proteles_, a new sauropod from the Early Cretaceous of Oklahoma.
    journal: Journal of Vertebrate Paleontology
    volume: 20
    issue: 1
    pages: 109-114



=== Date: Thu, 09 Jun 2005 18:49:01
+++ perl: {'test' => '|testing'}
+++ yaml
---
test: '|testing'



=== Date: Mon, 22 Aug 2005 16:52:47
+++ skip_this_for_now
+++ perl
  my $y = {

    ok_list_of_hashes => [
      {one => 1},
      {two => 2},
    ],

    error_list_of_hashes => [
      {-one => 1},
      {-two => 2},
    ],

  };
+++ yaml
---
error_list_of_hashes:
  - -one: 1
  - -two: 2
ok_list_of_hashes:
  - one: 1
  - two: 2



=== Date: Wed, 12 Oct 2005 17:16:48
+++ skip_this_for_now
+++ function: load_passes
+++ yaml
fontsize_small:  '9px'  # labelsmall
fontsize:        '11px' # maintext, etc
fontsize_big:    '12px' # largetext, button
fontsize_header: '13px' # sectionheaders
fontsize_banner: '16px' # title



=== Date: Mon, 07 Nov 2005 15:49:07
+++ perl: \ '|something'
+++ yaml
--- !!perl/ref
=: '|something'



=== Date: Thu, 24 Nov 2005 10:49:06
+++ perl: { url => 'http://www.test.com/product|1|2|333333', zzz => '' }
+++ yaml
---
url: http://www.test.com/product|1|2|333333
zzz: ''



=== Date: Sat, 3 Dec 2005 14:26:23
+++ perl
my @keys = qw/001 002 300 400 500/;
my $h = {};
map {$h->{$_} = 1} @keys;
$h;
+++ yaml
---
001: 1
002: 1
300: 1
400: 1
500: 1

