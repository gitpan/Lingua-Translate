#!/usr/bin/perl

use Test::More tests => 3;

use_ok("Lingua::Translate");

my $xl8r = Lingua::Translate->new(src => "en",
				  dest => "de");

# test with default back-end
ok(UNIVERSAL::isa($xl8r, "Lingua::Translate"),
   "Lingua::Translate->new()");

my $german = $xl8r->translate("I would like some cigarettes and a box of matches");

use Unicode::MapUTF8 qw(from_utf8);

is(from_utf8({-string=>$german, -charset=>"ISO-8859-1"}),
   "Ich möchte einige Zigaretten und einen Kasten Übereinstimmungen",
   "Lingua::Translate->translate [en -> de]");
