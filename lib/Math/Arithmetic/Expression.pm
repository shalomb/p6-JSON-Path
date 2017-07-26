#!/usr/bin/env perl6

use v6;

unit module Math::Arithmetic::Expression;

sub arithmetic-eval (Str $s --> Num) is export {

  grammar expr {
    token TOP         { ^ <sum> $ }
    token sum         { <product> (('+' || '-') <product>)* }
    token product     { <factor>  (('*' || '/') <factor>)* }
    token factor      { <unary_minus>? [ <parens> || <literal> ] }
    token parens      { '(' <sum> ')' }
    token unary_minus { '-' }
    token literal     {
      [ \d+ ['.' \d+]? || '.' \d+ ] [ e <[+-]>? \d+ ]?
    }
  }

  my sub minus ($b) { $b ?? -1 !! +1 }

  my sub sum ($x) {
    [+] flat
          product($x<product>),
          |($x[0] or []).map(
          -> $y {
            minus($y[0] eq '-') * product $y<product>
          },
    );
  }

  my sub product ($x) {
    [*] flat
          factor($x<factor>),
          |($x[0] or []).map(
            -> $y {
              factor($y<factor>) ** minus($y[0] eq '/')
            },
          )
  }

  my sub factor ($x) {
    minus($x<unary_minus>) * ($x<parens> ?? sum $x<parens><sum> !! $x<literal>)
  }

  expr.parse([~] split /\s+/, $s);
  $/ or fail "Could not parse expression '$s'";

  (sum $/<sum>).Num;
}

