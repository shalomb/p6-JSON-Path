#!/usr/bin/env perl6

use v6;

unit module TestData;

use Test;
use Assertions;
use JSON::Fast;

our $json is export = q:to"JSON";
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

our $test-data is export = from-json $json;

sub run-test-suite (@test_cases) is export {
  my @indices =
    %*ENV<t>.defined
      ?? %*ENV<t>.split(',').map:{ $_ < 0 ?? *+$_ !! $_ }
      !! 0..*;
  @test_cases = @test_cases[ @indices ];
  plan +@test_cases;
  for @test_cases {
    &$_();
  }
}
