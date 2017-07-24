#!/usr/bin/env perl6

use v6;

unit module JSON::Path::Filter;

use Assertions;

grammar JSONPathFilterParser {
  rule TOP  { ^ <branch> [ $ || FAILGOAL ] }

  method FAILGOAL($goal) {
    die "Cannot find $goal near position {self.pos}"
  }

  rule branch {
    <negate>? [
                | [ '(' ~ ')' <expr> ]
                | [           <expr> ]
              ]
      : [ <conjunction> <branch> ] ** 0..1
  }

  rule expr {
    <negate>? <subexpr> : [ <conjunction> <subexpr> ] ** 0..1
  }

  rule subexpr { 
    | <operand> :
      [
        | [ $<op>=['~~'] | $<op>=<negate>[\~\~] ] $<p6regex>=<regex>
        | [ $<op>=[\=\~] | $<op>=<negate>[\~] ]   $<p5regex>=<regex>
      ]
    | <operand> :
      [ <op> <operand> ] ** 0..*
      [
        <eqop> <operand> [ <op> <operand> ] ** 0..*
      ] ** 0..*
  }

  token operand {
    | $<function>=[ <node_identifier> '()' ]
    |     $<node>=[ <node_identifier> ]
    | <real>
    | <literal>
    | <boolean>
  }

  token node_identifier {
    [<curnode> | <rootnode>] '.' [ <property> [ '.' <property> ] ** 0..* ]
  }

  token property { \w+ [ '-' \D\w+ ]? }
  token curnode  { '@' }
  token rootnode { '$' }
  token negate   { '!' }

  token function { <operand>'()' } # length()

  token conjunction { [ '&&' | '||' | 'and' | 'or' ] }

  token eqop {
    | '==' | '!=' | '~~' | '!~~' | '===' | '=~=' | '=:='
    | '<=>' | 'cmp' | 'leg'
    | 'eq' | 'ne' | 'eqv' | 'before' | 'after'
    | [ '<' | '>' ] '='? | 'ge' | 'gt' | 'le' | 'lt'
  }

  token op {
    [ 
      | '+' | '-' | '*' | '/' | '%' | '%%' | '**' | '~'
      | 'div' | 'mod' | 'gcd' | 'lcm' 
    ]
  }

  proto token boolean      { * }
  token boolean:sym<True>  { <[Tt]>rue  }
  token boolean:sym<False> { <[Ff]>alse }

  token literal {
      "'" <(<-[']>*)> "'"    # stuff inbetween '' - bug with ' ~ ' <(...)> '
    | '"' <(<-["]>*)> '"'    # stuff inbetween "" - bug with " ~ " <(...)> "
  }  
  token regex {
    '/' <(<-[/]>+)> '/'      #' /foo? b[ae]r/
  }
  token real    {
    '-'?
    \d+ 
    [ '.' \d+ ]?
    [ e <[+-]>? \d+ ]?
  }
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

