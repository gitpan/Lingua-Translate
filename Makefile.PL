use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Lingua::Translate',
    'VERSION'	        => 0.05,
    'PREREQ_PM'		=> {
			    LWP::UserAgent => 1.73,
			    Pod::Constants => 0.15,
			    HTML::TokeParser => 2.19,
			    Unicode::MapUTF8 => 1.09,
			   },
    ($] >= 5.005 ?
      (ABSTRACT   => 'Natural Language Translation',
       AUTHOR     => 'Sam Vilain <enki@snowcra.sh>') : ()),
);
