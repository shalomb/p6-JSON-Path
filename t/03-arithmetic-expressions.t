#!/usr/bin/env perl6

use v6;

use lib 'lib';
use lib 't/lib';

use Test;
use Assertions;

use Math::Arithmetic::Expression;

sub test( $expression, $expected, $tolerance = 1e-15 ) {
  {
    my $*TOLERANCE = $tolerance;
    ok (my $r = eval($expression)) =~= $expected,
    sprintf "%-8.6g =~=  %-8.6g <== %s", $expected, $r, $expression;
  };
}

my @test-cases = (
  { test('5',                           5 ) },
  { test('1+2-3*4/5',                   0.6 ) },
  { test('1+5*3.4-.5 -4/-2*(3+4) -6',  25.5 ) },
  { test('((11+15)*15)*2+(3)*-4*1',   768 ) },
  { test('1-2*3/4',                    -0.5) },
  { test('1',                           1) },
  { test('1 / 13 * 20 / 10 - 5',       -4.8461,   0.0001) },
  { test('1/17+10*11-11',              99.0588,   0.0001) },
  { test('1/17+(10*11)-11',            99.0588,   0.0001) },
  { test('(1/17)+10*11-11',            99.0588,   0.0001) },
  { test('1/17+10*(11-11)',             0.0588,   0.0008) },
  { test('1/(17+10)*11-11',           -10.592593, 0.000001) },
  { test('1/((17+10)*11)-11',         -10.996633, 0.0001) },
  { test('1/((17+10)*11-11)',           0.003497, 0.001) },
);

plan +@test-cases;
.() for @test-cases;

