#!/usr/bin/env perl6

use v6;

use lib 'lib';
use lib 't/lib';

use Test;
use Assertions;

use TestData;

use JSON::Path::Filter;

my $books = $test-data<store><book>;

my @test-cases = (

{
my $e = '1';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '1 + 42';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '1 + 42 + 1789';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price-1';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price+42 == 54.99';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price+42 == 55.99-1';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price == False';
nok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price+1';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price>1';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price<10.1';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price > 1';
ok my $m = jsonpf($books, "$e"), "<$e>";
},
       
{
my $e = ' @.price > 1 ';
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = ' @.price == 12.99 ';
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/ @.title == 'Sword of Honour' /;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/ @.title == "Sword of Honour" /;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/ @.author == "Evelyn Waugh" /;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.length()';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.length() == 4';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.length() == 10';
nok jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/@.category != "reference" && @.price == 8.99/;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/(@.category=="fiction" && @.price >= 12.99)/;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/!(@.category=="fiction" && @.price >= 12.99)/;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/(@.category=="fiction" && @.price != 12.99)/;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/(@.price== 12.99 || @.category != "fiction")/;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/(@.price=="hello" && @.price != "world")/;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/(@.price=="hello" && @.price != "world") || (@.price == 1)/;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/(@.price=="hello" && @.price != "world") || (@.price == 1 && @.price != 2)/;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/(@.price=="hello" && @.price != "world") || (@.price == 1 && @.price != 2) && 1/;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/!(@.price=="hello" && @.price != "world") || (@.price == 1 && @.price != 2) && 1/;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price() == true';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = '@.price() == "hello"';
ok jsonpf($books, "$e"), "<$e>";
},

{
my $e = q/ @.price.bar == "hello world" /;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q<(@.price=="hello" && @.price =~ /world/)>;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q< @.price =~ /hello/ >;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q< @.price !~ /hello/ >;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q< @.price ~~ /hello/ >;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

{
my $e = q< @.price !~~ /hello/ >;
ok my $m = jsonpf($books, "$e"), "<$e>";
},

);

run-test-suite( @test-cases );

