use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Lingua::Translate',
    'VERSION'	        => 0.01,
    'PREREQ_PM'		=> {
			    LWP::UserAgent => 2,
			    Pod::Constants => 0.12,
			    HTML::TokeParser => 2.24,
			    Unicode::MapUTF8 => 1.09,
			   },
    ($] >= 5.005 ?
      (ABSTRACT   => 'Natural Language Translation',
       AUTHOR     => 'Sam Vilain <enki@snowcra.sh>') : ()),
);
