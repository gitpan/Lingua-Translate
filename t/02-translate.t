#!/usr/bin/perl

use Test::More tests => 4;

use_ok("Lingua::Translate");

my $xl8r = Lingua::Translate->new(src => "en",
				  dest => "de");

# test with default back-end
ok(UNIVERSAL::isa($xl8r, "Lingua::Translate"),
   "Lingua::Translate->new()");

my $german = $xl8r->translate("I would like some cigarettes and a box of matches");

eval "use Unicode::MapUTF8 qw(from_utf8);";

if ( $@ ) {
    # No Unicode::MapUTF8
    like($german,
	 qr/m..chte.*Zigaretten.*(bereinstimmungen|Gleichem)/,
	 "Lingua::Translate->translate [en -> de]");

    # "skip" doesn't seem to be reliable
    ok("No Unicode::MapUTF8!");

} else {

    like(from_utf8({-string=>$german, -charset=>"ISO-8859-1"}),
	 qr/m.chte.*Zigaretten/,
	 "Lingua::Translate->translate [en -> de]");

    # test Unicode
    my $jap_xl8r = Lingua::Translate->new(src => "en", dest => "ja",
					  dest_enc => "euc-jp");
    my $japanese = $jap_xl8r->translate
	("I would like some cigarettes and a box of matches");

    # just look for some likely euc-jp byte sequence.  The translation
    # from Babelfish seems to change regularly.
    my $seq = pack ('C*', 187, 228, 164);
    like($japanese, qr/$seq/, "Set destination character set");
}
