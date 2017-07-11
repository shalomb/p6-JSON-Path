#!/usr/bin/env perl6

use v6;

unit module JSONPath;

use JSON::Fast;
use Assertions;

%*ENV<debug> //= 0;

grammar JSONPParser {
  token TOP { <sigil> <expr>* }

  token expr   {
    [
       <deepscan>  |
       <subscript> |
       <dotref>    |
       <deepscan> 
    ] <expr>*
  }

  token deepscan { '..' [ <word> | <star> ] }

  proto rule dotref {*}
  token dotref:sym<word>     { '.' <word> }
  token dotref:sym<star>     { '.' <star> }

  proto rule subscript {*}
  token subscript:sym<star>  { [ '.' | <word>? ] '['  ~  ']' <star> }
  token subscript:sym<slice> { [ '.' | <word>? ] '['  ~  ']' <array-slice>       }
  token subscript:sym<array> { [ '.' | <word>? ] '['  ~  ']' <array-subscript>   }
  token subscript:sym<assoc> { [ '.' | <word>? ] "['" ~ "']" <between-brackets>  }

  token sigil  { <[@$]> }

  token array-subscript { [ <list> | <num> ] }
  token array-slice     { <num>? ':'  <num>? }
  token array-range     { <num>  '..' <num> }

  token list { <num>+ %% ',' }

  token star   { '*' }
  token word   { \w+ } # TODO: s/*/+/
  token num    { '-'? \d+ }

  token op { . ** 1..* }
}

class JSONPActions {
  my $obj;

  submethod BUILD (:$object) {
    $obj = $object;
  }

  method emit {
    say self.json;
  }

  method TOP ($/) {
    if $<expr> {
      note "TOP > $/ [$<expr>[0]]" if %*ENV<debug> == 1;
      assert $<sigil>, 'no sigils found';
      assert !$<expr>[1], 'expr[1] is defined';
      make $<expr>[0].made
    }
    elsif $<sigil> {
      make $obj
    }
    else {
      die "Unhandled exception"
    }
  }

  method expr ($/) {
    note "expr > $/ ".indent(1) if %*ENV<debug> == 1;
    if $<dotref> {
      make $obj = $<dotref>.made;
    }
    elsif $<deepscan> {
      make $obj = $<deepscan>.made;
    }
  }

  method dotref:sym<word> ($/) {
    note "dotref:w > $/ ".indent(2) if %*ENV<debug>;
    assert $<word>, 'dotref:sym<word> not set';
    if $obj ~~ List {
      make $obj = @ = $obj.grep({
        $_ ~~ Hash
      }).map({
        slip $_{ $<word> } 
      });
    }
    elsif $obj ~~ Hash|Pair {
      make $obj = $obj{$<word>};
    }
    else {
      die "Unable to process object of type " ~ $obj.WHAT.perl;
    }
  }

  method dotref:sym<star> ($/) {
    note "dotref:* > $/ > star:$<star> > {$obj.WHAT.perl}".indent(2) if %*ENV<debug> == 1;
    if $obj ~~ Hash {
      make $obj = @ = $obj.keys.map({ $obj{$_} });
    }
    elsif $obj ~~ List {
      make $obj
    }
    else {
      die "Unknown type of object processing <star>";
    }
  }
  
  method subscript:sym<star> ($/) {
    note "ss:star > $/ > {$obj.WHAT.Str}".indent(2) if %*ENV<debug> == 1;
    make $obj;
  }

  method subscript:sym<array> ($/) {
    note "ss:array > $/ ".indent(4) if %*ENV<debug> == 1;
    if my $i = $<array-subscript><num> {
      # make $obj = $obj[$i];
    }
  }

  method subscript:sym<slice> ($/) {
    note "ss:slice  > $/ ".indent(4) if %*ENV<debug> == 1;
    assert $<array-slice>, '$<array-slice> not set';

    my sub index-at(@arr, $i) {
      return $i if $i >= 0;
      (*+$i)(@arr); # Generate WhateverCode for Int < 0
    }

    my Int $start is default(0);
    my Int $end   is default(-1);

    ($start, $end) = $<array-slice>.split(':').map({ .chars ?? +$_ !! Nil });

    $end -= 1 if $end > 0;
    $end = $start if $end < $start and $end >= 0;

    if $start < 0 and $start > $end {
      make $obj = Nil;
      return;
    }

    note "start<$start>, end<$end>".indent(6) if %*ENV<debug>;

    my @indices = index-at($obj, $start) .. index-at($obj, $end);
    make $obj = $obj[ @indices ];
  }

  method list ($/) {
    note "list > $/ ".indent(6) if %*ENV<debug> == 1;
    my @i = $/.split(",");
    if $obj ~~ Array {
      make $obj = @i.elems > 1 ?? $obj[ @i ] !! $obj[ @i.first ];
    }
    else {
      die "Unable to <list> on " ~ $obj.WHAT.perl;
    }
  }

  method num ($/) {
    note "num > $/ ".indent(8) if %*ENV<debug>;
  }

  # TODO
  # * $..* deepscan is itself probably flaky as there is no consistency across
  #   implementations. We do it on a best-effort basis.
  method deepscan($/) {
    note "deepscan > $/".indent(4) if %*ENV<debug>;

    my multi sub do-deepscan( $obj, '*' ) {
      my @results;

      if $obj ~~ Hash {
        for $obj.keys -> $k {
          push @results, slip $obj{$k};
          push @results, slip do-deepscan $obj{$k}, '*';
        }
      }
      elsif $obj ~~ List|Array {
        push @results, slip do-deepscan $obj[$_], '*' for $obj.keys;
      }
      else {
        push @results, slip $obj;
      }

      return @results if @results;
    }

    my multi sub do-deepscan( $obj, Str $word ) {
      my @results;

      if $obj ~~ Hash {
        for $obj.keys -> $k {
          push @results, slip $obj{$word} if $k eq $word;
          push @results, slip do-deepscan $obj{$k}, $word;
        }
      }
      elsif $obj ~~ List|Array {
        push @results, slip do-deepscan $obj[$_], $word for $obj.keys;
      } 

      return @results if @results;
    }

    if $<word> {
      make $obj = @ = do-deepscan $obj, $<word>.Str;
    }
    elsif $<subscript> {
      make $obj; # TODO - hack
    }
    elsif $<star> {
      make $obj = @ = do-deepscan $obj, '*';
    }
    else {
      die "Unable to process this kind of deepscan";
    }
  }

}

multi sub jsonpath (
  Mu  :$object!,
  Str :$path = '$'
)
  is export( :jsonpath )
{
  my $actions = JSONPActions.new( object => $object );

  JSONPParser.parse(
      $path,
      actions => JSONPActions
    ).made;
}

multi sub jsonpath (
  Mu $object!,
  Str $path = '$' 
)
  is export( :jsonpath )
{
  jsonpath( object => $object, path => $path );
}

# provides a shorthand like so
#   ($object => q/$.store.book[2].author/).jsonpath
Pair.^add_fallback(
  -> $object, $name { $name eq q/jsonpath/ },
  -> $object, $name {
    -> $p {
      jsonpath( object => $object.key, path => $object.value )
    }
  }
);

