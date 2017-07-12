#!/usr/bin/env perl6

use v6;

use lib 'lib';
use Test;
use Assertions;

use JSON::Fast;
use JSON::Path :jsonpath;

my $json = q:to"JSON";
{ "store": {
    "book": [
      { "category": "reference",
        "author": "Nigel Rees",
        "title": "Sayings of the Century",
        "price": 8.95
      },
      { "category": "fiction",
        "author": "Evelyn Waugh",
        "title": "Sword of Honour",
        "price": 12.99
      },
      { "category": "fiction",
        "author": "Herman Melville",
        "title": "Moby Dick",
        "isbn": "0-553-21311-3",
        "price": 8.99
      },
      { "category": "fiction",
        "author": "J. R. R. Tolkien",
        "title": "The Lord of the Rings",
        "isbn": "0-395-19395-8",
        "price": 22.99
      }
    ],
    "bicycle": {
      "color": "red",
      "price": 19.95,
      "dimensions" : {
        "height": 24,
        "weight": 14,
        "bars": [
          1729,
          42,
          {
            "2": {
              "foo": "bar"
            }
          }
        ]
      }
    }
  }
}
JSON

use Terminal::ANSIColor;
sub line {
  say color('red') ~ ( '=' x 32 ) ~ RESET();
}

my $test-data = from-json $json;

sub run-test($verdict, $path, $expected, $description) {
  say color('bold magenta') ~ "Running $path" ~ RESET() if %*ENV<debug>;
  try {
    my $run = jsonpath(object => $test-data, path => $path);
    if %*ENV<debug> {
      say
        color('yellow')  ~ "<$run>" ~
        color('bold black') ~ " == " ~
        color('magenta') ~ "<$expected>";
      print RESET();

      my $rt = $run.WHAT.perl;
      my $et = $expected.WHAT.perl;
      my $eq = $rt eq $et;

      say
        color('yellow') ~ $rt ~
        color('bold black') ~ " eq " ~
        color('magenta') ~ $et ~
        " " ~ ($eq ?? color('green') !! color('red')) ~ $eq;

      say RESET();
    }
    given $verdict {
      when 'ok'  {
        if $expected ~~ Str|Any {
          ok  $run eq $expected,
            "ok  -- { color('yellow') ~ $path ~ RESET() } ::= $description"
        }
        else {
          ok  $run == $expected, "ok  -- $path ::= $description"
        }
      }
      when 'nok' {
        nok $run == $expected, "nok -- $path ::= $description"
      }
    }
    CATCH {
      default {
        note "failed test for $path, " ~ .message ~ "\n" ~ .backtrace;
        ok False, "$verdict -- $path ::= $description";
      }
    }
  }
}

my @test_cases = (
{ nok 1 == False, 'sanity check'; },

{ run-test('ok',  '$', $test-data, 'fetch root node' ); },
{ run-test('nok', '$', $test-data<store><book>, 'root node is not something else' ); },

{
  my $path = '';
  my $run = jsonpath(object => $test-data, path => $path);
  nok $run.defined, "'' -- empty path";
},

{ run-test('ok',  '$.store', $test-data<store>, 'simple path' ); },
{ run-test('nok', '$.store', $test-data, 'simple path does not return root'); },

{ run-test('ok',  '$.store.book', $test-data<store><book>, 'simple path - nested dotref' ); },

{ run-test('ok',  '$.store.book[0]', $test-data<store><book>[0], 'array index'); },
{ run-test('ok',  '$.store.book[3]', $test-data<store><book>[3], 'array index > 0'); },

{ run-test('ok',
   '$.store.book[0].author',
   $test-data<store><book>[0]<author>,
   'dotref of array index');
},

{ run-test('ok',
   '$.store.book[3].author',
   $test-data<store><book>[3]<author>,
   'dotref of array index > 0');
},

{ run-test('ok',
    '$.store.bicycle.dimensions.bars[2].2.foo',
    $test-data<store><bicycle><dimensions><bars>[2]<2><foo>,
    'nested dotref of array index > 0');
},

{ run-test('ok',  '$.store.book[1,3]', $test-data<store><book>[1,3], 'array subscript - list'); },
{ run-test('ok',  '$.store.book[3,2,1]', $test-data<store><book>[3,2,1], 'array subscript - list'); },

{ run-test('ok',
    '$.store.book[3,2,1].author',
    $test-data<store><book>[3,2,1].map({ $_<author> }),
    'dotref of array subscript - list');
},

{ run-test('ok',
    '$.store.*',
    $test-data<store>.keys.map({ $test-data<store>{$_} }),
    'dotref star');
},

{ run-test('ok',
    '$.store.book[*]',
    $test-data<store><book>,
    'array subscript star');
},

{ run-test('ok',
    '$.store.book.*',
    $test-data<store><book>,
    'dotref star');
},

{ run-test('ok',
    '$.store.book[*].author',
    $test-data<store><book>.map({ $_<author> }),
    'array subscript star');
},

{ run-test('ok',
    '$.store.book.*.author',
    $test-data<store><book>.map({ $_<author> }),
    'dotref star');
},

{ run-test('ok',
    '$.store.bicycle.dimensions.bars.[0]',
    $test-data<store><bicycle><dimensions><bars>[0],
    'dotref star');
},

{ run-test('ok',
    '$.store.bicycle',
    $test-data<store><bicycle>,
    'dotref star');
},

{ run-test('ok',
    '$.store.bicycle.*',
    $test-data<store><bicycle>.values,
    'dotref star');
},

{
  my $h =$test-data<store><bicycle>;
  run-test('ok',
    '$.store.bicycle.*.bars',
    $h.keys.grep({ $h{$_} ~~ Hash }).map({ $h{$_}<bars> }),
    'dotref star');
},

{
  my $h =$test-data<store><bicycle>;
  run-test('ok',
    '$.store.bicycle.*.bars.[1]',
    $h.keys.grep({ $h{$_} ~~ Hash }).map({ $h{$_}<bars>[1] }),
    'array subscript of dotref star');
},

{
  my $h =$test-data<store><bicycle>;
  run-test('ok',
    '$.store.bicycle.*.bars.[0,1]',
    $h.keys.grep({ $h{$_} ~~ Hash }).map({ $h{$_}<bars>[0,1] }),
    'array subscript of dotref star');
},

{
  my $h =$test-data<store><bicycle>;
  run-test('ok',
    '$.store.bicycle.*.bars.[2]',
    $h.keys.grep({ $h{$_} ~~ Hash }).map({ $h{$_}<bars>[2] }),
    'array subscript of dotref star');
},

{
  my $h =$test-data<store><bicycle>;
  run-test('ok',
    '$.store.bicycle.*.bars.[2].2',
    $h.keys.grep({ $h{$_} ~~ Hash }).map({ $h{$_}<bars>[2]<2> }),
    'array subscript of dotref star');
},

{
  my $h =$test-data<store><bicycle>;
  run-test('ok',
    '$.store.bicycle.*.bars.[2].2.foo',
    $h.keys.grep({ $h{$_} ~~ Hash }).map({ $h{$_}<bars>[2]<2><foo> }),
    'array subscript of dotref star');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[0:3]',
    $h[0..2],
    'array slice');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book.[0:1]',
    $h[0..0],
    'array slice - dot form');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book.[0:2]',
    $h[0..1],
    'array slice - dot form');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book.[0:0]',
    $h[0..0],
    'array slice - dot form');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book.[0:3]',
    $h[0..2],
    'array slice - dot form');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[:2]',
    $h[0..1],
    'array slice missing start');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[2:]',
    $h[2..*],
    'array slice missing end');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[:7]',
    $h[0..6],
    'array slice to index out of bounds');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[7:]',
    $h[7..*],
    'array slice starting from index out of bounds');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[-1:]',
    $h[*-1 .. *],
    'array slice');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[-2:]',
    $h[*-2 .. *],
    'array slice negative start, missing end');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[:-1]',
    $h[0 .. *-1],
    'array slice missing start, negative end');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[0:-1]',
    $h[0 .. *-1],
    'array slice missing start, negative end');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[-1:-1]',
    $h[*-1 .. *-1],
    'array slice missing start, negative end');
},

{
  # TODO - This behaviour seems inconsistent across implementations
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[-1:0]',
    $h[*-1 .. 0],
    'array slice negative start, positive end - returns nil');
},

{
  my $h =$test-data<store><book>;
  run-test('ok',
    '$.store.book[:-1].author',
    $h[0 .. *-1].map( *<author> ),
    'dotref of array slice missing start negative end');
},

{
  my $h =$test-data<store>;
  run-test('ok', '$..store', $h, 'deepscan simple');
},

{
  my $h =$test-data<store><book>.map:{ $_<author> };
  run-test('ok', '$..author', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>.map:{ $_<author> };
  run-test('ok', '$..book..author', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>;
  run-test('ok', '$..book', $h, 'deepscan recursive');
},

{
  my $h = (
    $test-data<store><bicycle>.grep({ $_<price> }).map({ $_<price> }),
    $test-data<store><book>.map({ $_<price> })
  );
  run-test('ok', '$..price', $h, 'deepscan recursive');
},

{
  my $h = (
    $test-data<store><bicycle>.grep({ $_<price> }).map({ $_<price> }),
    $test-data<store><book>.map({ $_<price> })
  );
  run-test('ok', '$.store..price', $h, 'deepscan recursive');
},

{
  my $h = (
    $test-data<store><bicycle>.grep({ $_<price> }).map({ $_<price> }),
    $test-data<store><book>.map({ $_<price> })
  );
  run-test('ok', '$..store..price', $h, 'deepscan recursive');
},

{
  my $h = $test-data<store><bicycle><dimensions><bars>;
  run-test('ok', '$..bars', $h, 'deepscan recursive');
},

{
  my $h = $test-data<store><bicycle><dimensions><bars>[2]<2><foo>;
  run-test('ok', '$..foo', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>;
  run-test('ok', '$..book', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>;
  run-test('ok', '$..book.*', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>[2];
  run-test('ok', '$..book[2]', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>[2,3];
  run-test('ok', '$..book[2,3]', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>[2,3];
  run-test('ok', '$..book.[2,3]', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>[0..1];
  run-test('ok', '$..book[:2]', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>[0..1];
  run-test('ok', '$..book.[:2]', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>;
  run-test('ok', '$..book.[*]', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>.map({ $_<author> });
  run-test('ok', '$..book.[*].author', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><book>.map({ $_<author> })[2];
  run-test('ok', '$..book..author[2]', $h, 'deepscan recursive');
},

{
  my $h =$test-data<store><bicycle>;
  my $path = '$..*'; 
  my $run = jsonpath(object => $test-data, path => $path);
  # TODO
  # * no order is guaranteed from results - this test is potentially flaky.
  ok $run[0]<bicycle> eq $h,
     "ok  -- $path ::= deepscan star"
},

{
  my $h =$test-data<store><book>.map({ $_<author> })[2..3];
  run-test('ok', '$..book..author[2..3]', $h, 'subscript range');
},

{
  my $h =$test-data<store><book>.map({ $_<author> })[0..*-1];
  run-test('ok', '$..book..author[0..*-1]', $h, 'subscript range');
},

{
  my $h =$test-data<store><book>.map({ $_<author> })[*-3..*-1];
  run-test('ok', '$..book..author[*-3..*-1]', $h, 'subscript range');
},

{
  my $path = '$..book..author[*-1..*-3]';
  my $run = jsonpath(object => $test-data, path => $path);
  nok $run.elems, "nok -- $path range end-points unordered";
},

{
  my $path = '$..book..author[*..*]';
  my $run = jsonpath(object => $test-data, path => $path);
  nok $run.defined, "nok -- $path range end-points both stars - returns empty";
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

#{
#  line;
#  my $path = '$.store.book[0:3]';
#  my $h =$test-data<store><book>[0..2];
#  say color('yellow') ~
#    my $expected = $h;
#  say color('yellow') ~
#    my $run = jsonpath(object => $test-data, path => $path);
#  ok $run eq $expected, $path;
#  line;
#},
#
#{
#  line;
#  my $path = '$.store.bicycle.*.bars[0]';
#  my $h =$test-data<store><bicycle>;
#  say color('yellow') ~
#    my $expected = $test-data<store><bicycle><dimensions><bars>[0];
#  say color('yellow') ~
#    my $run = jsonpath(object => $test-data, path => $path);
#  ok $run eq $expected, $path;
#  line;
#},

#{
#  line;
#  my $path = '$.store.bicycle.*.bars.[0]';
#  my $h =$test-data<store><bicycle>;
#  say color('yellow') ~
#    my $expected = $test-data<store><bicycle><dimensions><bars>[0];
#  say color('yellow') ~
#    my $run = jsonpath(object => $test-data, path => $path);
#  ok $run eq $expected, $path;
#  line;
#},

