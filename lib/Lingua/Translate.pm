#!/usr/bin/perl -w

package Lingua::Translate;

use strict;
use Carp;

use vars qw($VERSION $back_end);
$VERSION = '0.01';

=head1 NAME

Lingua::Translate - Translate text from one language to another

=head1 SYNOPSIS

 use Lingua::Translate;

 my $xl8r = Lingua::Translate->new(src => "en",
                                   dest => "de")
     or die "No translation server available for en -> de";

 my $english = "I would like some cigarettes and a box of matches";

 my $german = $xl8r->translate($english); # dies or croaks on error

 # prints "Mein Luftkissenfahrzeug ist voll von den Aalen";
 print $german;

=head1 DESCRIPTION

Locale::Translate translates text from one written language to
another.  Currently this is implemented by contacting Babelfish
(http://babelfish.altavista.com/), so see there for the language pairs
that are supported.  Babelfish uses SysTran (http://www.systran.org/)
to perform the translation, and contacting a SysTran translation
server directly is also supported (in case your translation needs grow
beyond babelfish' capacity).

=head1 OVERVIEW

To translate text, you first have to obtain a translation "handle" for
the language pair (source language, destination language) that you are
translating, using a constructor (see CONSTRUCTORS, below).  This is
returned as a perl object.  You can then use this handle to translate
arbitrary text, using the "translate" method (see METHODS, below).

Depending on the back-end that you are using, either the constructor
or the translation will open a connection to a translation server.  If
there are any network errors or timeouts, then an exception will be
thrown.  If you want to check for this type of error, you will need to
wrap both the constructor and the translation function in an eval { }
block.

If you are using a systrans server, you will need to use the "config"
function to tell this module where your translation server is running,
and the port that it is listening on.

Translating is generally a heavily expensive task; you should try to
save the results you get back from this module somewhere so that you
do not overload Babelfish.

=head1 CONSTRUCTORS

=cut

# I'm not sure whether the "src", "dest" options should be hard coded
# like this.  Perhaps they should just be treated as configuration
# options.  But I think they're necessary.

=head2 new(src => $lang, dest => $lang)

This function creates a new translation handle and returns it.  It
takes the following construction options, passed as Option => "value"
pairs:

=over

=item src

The source language, in RFC3066 form.  See L<I18N::LangTags>.  There
is no default.

=item dest

The destination language in the same form.  There is no default.

=back

Additionally, any configuration option that is normally passed to the
"config" function (see below) may be passed to the "new" constructor
as well.

=cut

use I18N::LangTags qw(is_language_tag);

sub new {
    my $class = shift;
    my %options = @_;

    my $self = bless { }, $class;

    croak "Must supply source and destination language"
	unless (defined $options{src} and defined $options{dest});

    is_language_tag($self->{src} = delete $options{src})
	or croak "$self->{src} is not a valid RFC3066 language tag";

    is_language_tag($self->{dest} = delete $options{dest})
	or croak "$self->{dest} is not a valid RFC3066 language tag";

    # allow custom back end
    $self->{back_end} = load_back_end(delete $options{back_end}
				      || $back_end);

    # For flexibility, we allow two methods of configuration; if
    # the module defines &save_config(), then we call that
    # function, then call config(%options), new(), then
    # &restore_config().
    # list.
    if ( keys %options and
	 my $code_ref = $self->{back_end}->can("save_config") ) {
	my $saved_config = $code_ref->();
	$self->{back_end}->config(%options);
	$self->{worker} =
	    $self->{back_end}->new( src => $self->{src},
				    dest => $self->{dest} );
	$self->{back_end}->restore_config($saved_config);
    } else {
	# If they don't define that function, then we just call
	# their &new() function with the remaining options as a
	# parameter
	$self->{worker} =
	    $self->{back_end}->new( src => $self->{src},
				    dest => $self->{dest},
				    %options );
    }

    bless $self, $class;
}

=head1 METHODS

=head2 translate($text) : $text

Translates $text and returns the translated text.  die on any error.

=cut

sub translate {
    my ($self, $text) = map { shift } (1..2);

    return $self->{worker}->translate($text);
}

=head1 CONFIGURATION FUNCTIONS

This collection of functions configures general operation of the
Lingua::Translate module, which is stored in package scoped variables.

These options only affect the construction of new objects, not the
operation of existing objects.

=head2 load_back_end($backend)

This function loads the specified back-end.  Used internally by
config().  Returns the package name of the backend.

=cut

sub load_back_end {
    my ($back_end) = (@_);

    if ( $back_end !~ m/::/ ) {
	$back_end = "Lingua::Translate::$back_end";
    }
    eval "use $back_end;";
    if ( $@ ) {
	croak "Back end $back_end not available; $@";
    }

    return $back_end;
}

=head2 config(option => $value)

This function sets defaults for use when constructing objects.

=cut

sub config {

    my ($self, $our_back_end);
    if ( UNIVERSAL::isa($_[0], __PACKAGE__) ) {
	$self = shift;
	my $be = ref $self;
	$our_back_end = \$be;
    } else {
	$our_back_end = \$back_end;
    }

    while ( my ($option, $value) = splice @_, 0, 2 ) {

	if ( $option eq "back_end" ) {

	    # the user is selecting a back end.  Load it
	    $$our_back_end = load_back_end($value);

	} elsif (
		 my $code_ref = UNIVERSAL::can($$our_back_end,"config")
		) {

	    # call the back-end's configuration function
	    $code_ref->($option => $value);

	} else {
	    croak "Unknown configuration option $option";
	}
    }
}

# extract the default values from the POD
use Pod::Constants
    'CONFIGURATION FUNCTIONS' => sub {
	Pod::Constants::add_hook
		('*item' => sub {
		     my ($varname) = m/(\w+)/;
		     my ($default) = m/The default value is "(.*)"\./;
		     config($varname => $default);
		 }
		);
	Pod::Constants::add_hook
		(
		 '*back' => sub {
		     Pod::Constants::delete_hook('*item');
		     Pod::Constants::delete_hook('*back');
		 }
		);
    };

=over

=item back_end

This specifies the method to use for translation.  Currently supported
values are "Babelfish" and "SysTran".  The case is significant.

The default value is "Babelfish".

Setting this option will "use" the appropriate back-end module from
Lingua::Translate::*, which should be a derived class of
Lingua::Translate.

If the configuration option requested is not found, and a back-end is
configured, then that back-end's config function is called with the
options.

=back

This function can also be called as an instance method (ie
$object->config(name => value), in which case it configures that
object only.

=head1 BUGS/TODO

No mechanism for backends registering which language pairs they have
along with a priority, so that the most efficient back-end for a
translation can be selected automatically.

Some much shorter invocation rules, suitable for one liners, etc.

No character set management; for instance, the Babelfish back-end uses
UTF8, but the SysTran back-end uses ISO-8859-1.  The way I envisage
this working is that all backends must use UTF8.

=head1 SEE ALSO

L<Lingua::Translate::Babelfish>, L<LWP::UserAgent>,
L<Unicode::MapUTF8>

The original interface to the fish - L<WWW::Babelfish>, by Daniel
J. Urist <durist@world.std.com>

=head1 AUTHOR

Sam Vilain, <enki@snowcra.sh>

=cut

4;
