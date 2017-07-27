#!/usr/bin/env perl6

use v6;

unit module JSON::Path::Filter;

use Assertions;
use Math::Arithmetic::Expression;

grammar JSONPathFilterParser {
  rule TOP  { ^ <branch> [ $ || FAILGOAL ] }

  method FAILGOAL($goal) {
    die "Cannot find $goal near position {self.pos}"
  }

  rule branch {
    <negate>?
    [
    | [ '(' ~ ')' <expr> ]
    | [           <expr> ]
    ] : [ <conjunction> <branch> ] ** 0..1
  }

  rule expr {
    <negate>?
    <subexpr> : [ <conjunction> <subexpr> ] ** 0..1
  }

  rule subexpr { 
    | <operand> :
      [
        | [ $<op>=['~~'] | $<op>=<negate>[\~\~] ] $<p6regex>=<regex>
        | [ $<op>=[\=\~] | $<op>=<negate>[\~]   ] $<p5regex>=<regex>
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

  sub split-array (@array, $pivot, @lhs, @rhs) {
    for @array.kv -> $k,$v {
      state $marked=0;
      if (%*ENV<debug> // '') ge 2 {
        note "$v $pivot $marked " ~ ($v eqv $pivot);
        note "v : " ~ $v.[0];
        note "{$v.WHAT.perl} {$pivot.WHAT.perl} $marked " ~ ($v eqv $pivot);
      }
      if $v eqv $pivot { $marked++ }
      else {
        push ($marked ?? @rhs !! @lhs), $v
      }
    };
  }

  sub fold-logical-terms (@arrays, @ops) {
    given @arrays.elems {
      when      0 { return }
      when      1 { @arrays }
      when $_ > 1 {
        roundrobin( @arrays ).map:
          -> @terms {
            (True, |roundrobin(@terms, ('&&', @ops).flat)).reduce:
              -> $result, [$term, $op] {
                ($result, $term).reduce( &::("infix:<$op>") );
            };
          };
      }
    }
  }

  method TOP($/) {
    note "TOP > $/ > " if %*ENV<debug>; 
      my $expr-as-bool = $/<branch>.made;
    if $obj ~~ Array|List {
      make
        $/<branch>.made.pairs.grep(so *.value).map(*.keys).flat.map({$obj[$_]});
    }
    else {
      die "Do not know how to process object of type { $obj.WHAT.perl }"
    }
  }

  method branch ($/) {
    note "branch > $/".indent(1) ~ " > " if %*ENV<debug>;
    if $/<expr> {
      note "expr: ".indent(2) ~ $/<expr>;
      # note "  " ~ 
      # make $ = $/<expr>.made.map:{ $/<negate> ?? not $_ !! $_ }
      # make (True, False, True, False);
    }
    if $/<branch> {
      make (True, True, True, True);
      note "branch E: ".indent(2) ~ $/<branch><expr>.WHAT.perl;
    }
  }

  method expr ($/) {
    note "expr > $/ > ".indent(1) if %*ENV<debug>;
    note "==> ".indent(4) ~
    make (True, False, True, False);
    # make $ = fold-logical-terms( $/<subexpr>>>.made.list, $/<conjunction> );
  }

  method subexpr ($/) {
    note "subexpr > $/ > ".indent(2) if %*ENV<debug>;
    
    make @$obj.map( -> $node {
      my $eqop = ($/<eqop>.first // '==').Str;

      my @term_stack;
      for $/<op>, $/<eqop> -> $m {
        @term_stack.push: |$m.map({ $_.pos => $_.Str }) if $m;
      }

      for $/<operand> -> $m {
        @term_stack.push: do with $m {
          if (my $function = $_<node_identifier><property>) and $_<function>  {
            # TODO
            #   We may need to support parameterized aggregated functions like
            #   min(), max(), avg(), stddev()
            given $function {
              when 'elems'  { $node.elems }
              when 'length' { $node.elems }
              default { die "Unknown/unimplemented function '$function'" }
            }
          }
          elsif (my $property = $_<node_identifier><property>) {
            $_.pos => $node{$property};
          }
          else {
            $_.pos => $_.made;
          }
        }
      }

      @term_stack  = @term_stack.sort(*.keys)>>.values.flat;
      # note "term_stack : ".indent(4) ~ @term_stack if %*ENV<debug>;

      # NOTE The complexity here warrants using a better mechanism to do this
      #      And we're not even started. :|
      if @term_stack.elems > 1 {
        my @lhs = my @rhs = ();
        split-array @term_stack, $eqop, @lhs, @rhs;

        # note "lhs: " ~ @lhs if %*ENV<debug>;
        # note "rhs: " ~ @rhs if %*ENV<debug>;

        my $lhs = +@lhs > 1 ?? arithmetic-eval @lhs.join !! (@lhs.head // '');
        my $rhs = +@rhs > 1 
                    ?? arithmetic-eval @rhs.join
                    !! +@rhs ?? @rhs.first !! $lhs;

        if $lhs|$rhs ~~ Str {
          $eqop = do given $eqop {
            when '==' { 'eq'  }
            when '!=' { 'ne'  }
          }
        }

        # NOTE This appears to be a bug or inconsistency?
        my $r = reduce &::(
          $eqop ~~ '<'|'>'|'<='|'>='
            ?? "infix:«$eqop»"
            !! "infix:<$eqop>"
        ), $lhs, $rhs;

        if %*ENV<debug> {
          $*ERR.printf("%5s %24s  %s  ".indent(4),
            $r,
            "'$lhs' $eqop '$rhs'",
            "{$lhs.WHAT.perl} $eqop {$rhs.WHAT.perl}");
          note   $node;
        }
        $r;
      }
      else {
        @term_stack.first;
      }
      } 
    );
  }

  method operand ($/) {
    note "operand > $/".indent(3) if %*ENV<debug>;
    if $/<literal> {
      make $/<literal>.Str;
    }
    elsif $/<real> {
      make $/<real>.Rat
    }
    elsif $/<boolean> {
      make $/<boolean>.made;
    }
    else {
      make $/;
    }
  }

  method boolean:sym<True>($/)  { make True }
  method boolean:sym<False>($/) { make False }

  method op ($/) {
    # note "op > $/ ".indent(5) if %*ENV<debug>;
    # dd $/.pos => $/;
  }

  method eqop ($/) {
    # note "eqop > $/ ".indent(5) if %*ENV<debug>;
    # dd $/.pos => $/;
  }

}

sub JSONPathFilter ( :$object, :$expression ) is export {
  my $actions = JSONPathFilterActions.new( object => $object );

  JSONPathFilterParser.parse(
    $expression, actions => JSONPathFilterActions
  ).made;
}

sub jsonpf( $object, $expression )
  is export 
{
  # TODO : Merge with JSONPathFilter
  my $actions = JSONPathFilterActions.new( object => $object );

  say JSONPathFilterParser.parse(
    $expression
  ) if %*ENV<debug>;

  say ('=' x 32).indent(1) if %*ENV<debug>;
  return;

  my $return = JSONPathFilterParser.parse(
    $expression,
    actions => JSONPathFilterActions
  );

  return $return.made;
}

