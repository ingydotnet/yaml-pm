use strict;
use Test::More tests => 1;
use YAML;

local $YAML::Preserve = 1;

my $yaml = <<'...';
---
z: z
y: y
x: x
w: w
v: v
u: u
t: t
s: s
r: r
q: q
p: p
o: o
n: n
m: m
l: l
k: k
j: j
i: i
h: h
g: g
f: f
e: e
d: d
c: c
b: b
a: a
...

my $data = YAML::Load($yaml);
my $dump = YAML::Dump($data);
cmp_ok($dump, 'eq', $yaml, "Roundtrip with Preserve option");

done_testing;

