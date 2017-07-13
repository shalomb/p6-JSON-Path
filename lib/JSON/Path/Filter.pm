#!/usr/bin/env perl6

use v6;

unit module JSON::Path::Filter;

use Assertions;

grammar JSONPathFilterParser {
  rule TOP  { <expr> <expr>* }

  # rule expr    { '('? ~ ')'? [ <subexpr> ] }
  rule expr    {
      <assertion> | <assertion> <conjunction> <assertion>
  }

  rule assertion {
      '('? [ <subexpr> [ <conjunction> | <subexpr> ]? ] ')'?
  }

  rule subexpr { 
      <operand> <op> <operand>
    | <operand> $<op>=[\=\~] <p5regex>
    | <operand>
    | <function>                         # @.length()
    #[ <operand> <op> <operand> ] #|     # @.length-1, @.price<10
    # <operand>                          # @.isbn, curnode has property
  }

  token operand {
      [ [<curnode>|<rootnode>] '.' <property> ]    # @.isbn
    | <real>                                     # 1
    | <literal>                                  # 'foo'
  }

  token property { \w+ [ '-' \D\w+ ]? }
  token curnode  { '@' }
  token rootnode { '$' }

  token function { <operand>'()' } # length()

  token conjunction { [ '&&' | '||' | 'and' | 'or' ] }

  token op       {
    [
      [ '+' | '-' | '*' | '/' | '%' ]  | 
      [ '=' | '<' | '>' ] '='? |
      '!='
    ]
  }

  token literal {
      "'" <(<-[']>*)> "'"    # stuff inbetween '' - bug with ' ~ ' <(...)> '
    | '"' <(<-["]>*)> '"'    # stuff inbetween "" - bug with " ~ " <(...)> "
  }  
  token p5regex {
    '/' <(<-[/]>+)> '/'
  }
  token real    { '-'? \d+ [ '.' \d+ ]? }
}

class JSONPathFilterActions {
  my $obj;

  submethod BUILD (:$object) {
    $obj = $object;
  }

  method emit {
    say $obj.perl;
  }

}

sub jsonpf( $obj, $expr )
  is export 
{
  my $actions = JSONPathFilterActions.new( object => $obj );

  JSONPathFilterParser.parse( $expr );
    # actions => JSONPathFilterActions
}

