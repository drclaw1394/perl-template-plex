use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Template::Lexical',
    VERSION_FROM      => 'lib/Template/Lexical.pm', 
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Template/Lexical.pm', # retrieve abstract from module
    AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
    LICENSE           => 'mit',

    MIN_PERL_VERSION => '5.24.0',		#for ref aliasing
    TEST_REQUIRES => { "Test::More" => 0},
    CONFIGURE_REQUIRES => {"ExtUtils::MakeMaker"=>0},


    META_ADD => {
	    "meta-spec" => {
		    version => 2
	    },
	    resources=> {
		    repository =>{
			    type => "git",
			    url => "git://github.com/drclaw1394/perl5-template-lexical.git",
			    web => "http://github.com/drclaw1394/perl5-template-lexical",
		    }
	    }
    }

);
