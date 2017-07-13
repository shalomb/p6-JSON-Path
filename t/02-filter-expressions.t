#!/usr/bin/env perl6

use v6;

use lib 'lib';

use Test;
use Assertions;

use JSON::Path::Filter;

my @test_cases = (

{
my $e = '@.foo';
ok jsonpf({}, "$e"), "<$e>";
},

{
my $e = '@.foo-1';
ok jsonpf({}, "$e"), "<$e>";
},

{
my $e = '@.foo()';
ok jsonpf({}, "$e"), "<$e>";
},

{
my $e = '@.foo+1';
ok jsonpf({}, "$e"), "<$e>";
},

{
my $e = '@.foo>1';
ok jsonpf({}, "$e"), "<$e>";
},

{
my $e = '@.foo<10.1';
ok jsonpf({}, "$e"), "<$e>";
},

{
my $e = '@.foo > 1';
ok my $m = jsonpf({}, "$e"), "<$e>";
},

{
my $e = ' @.foo > 1 ';
ok my $m = jsonpf({}, "$e"), "<$e>";
},

{
my $e = ' @.foo == 1 ';
ok my $m = jsonpf({}, "$e"), "<$e>";
},

{
my $e = q/ @.foo == 'hello' /;
ok my $m = jsonpf({}, "$e"), "<$e>";
},

{
my $e = q/ @.foo == "hello" /;
ok my $m = jsonpf({}, "$e"), "<$e>";
},

{
my $e = q/ @.foo == "hello world" /;
ok my $m = jsonpf({}, "$e"), "<$e>";
},

{
my $e = q/@.foo=="hello" && @.foo/;
ok my $m = jsonpf({}, "$e"), "<$e>";
},

{
my $e = q/(@.foo=="hello" && @.foo)/;
ok my $m = jsonpf({}, "$e"), "<$e>";
},

{
my $e = q/(@.foo=="hello" && @.foo != "world")/;
ok my $m = jsonpf({}, "$e"), "<$e>";
},

);

my @indices =
  %*ENV<t>.defined
    ?? %*ENV<t>.split(',').map:{ $_ < 0 ?? *+$_ !! $_ }
    !! 0..*;
@test_cases = @test_cases[ @indices ];
plan +@test_cases;
for @test_cases {
  &$_();
}

