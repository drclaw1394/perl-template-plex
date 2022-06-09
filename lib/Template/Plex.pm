package Template::Plex;
use strict;
use warnings;

use version; our $VERSION = version->declare('v0.4.0');
use Template::Plex::Base;

#use Symbol qw<delete_package>;
use Carp qw<carp croak>;

use feature qw<say state refaliasing lexical_subs>;
no warnings "experimental";

#use File::Basename qw<dirname basename>;
use File::Spec::Functions qw<catfile>;
use File::Basename qw<dirname>;
use Exporter 'import';


#our %EXPORT_TAGS = ( 'all' => [ qw( plex plx  block pl plex_clear jmap) ] );

our @EXPORT_OK = qw<plex plx block pl plex_clear jmap>;# @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	plex
	plx
);

my $Include=qr|\@\{\s*\[\s*include\s*\(\s*(.*?)\s*\)\s*\] \s* \}|x;
my $Init=qr|\@\{\s*\[\s*init\s*\{(?:.*?)\}\s*\] \s* \}|smx;


sub new;	#forward declare new;

sub lexical{
	my $href=shift;
	die "NEED A HASH REF " unless  ref $href eq "HASH" or !defined $href;
	$href//={};
	\my %fields=$href;

	my $string="";
	for my $k (keys %fields){
		$string.= "\\my \$$k=\\\$fields{$k};\n";
	}
	$string;
}

sub  bootstrap{
	my $plex=shift;
	\my $_data_=\shift;
	my $href=shift;
	my %opts=@_;

	$href//={};
	\my %fields=$href;

my $out="package $opts{package} {
use Template::Plex qw<pl block plex_clear jmap>;
";

$out.='my $self=$plex;
';

$out.= '	\my %fields=$href;
';
$out.='		my %options=%opts; 
' if keys %opts;
                for($opts{use}->@*){
			$out.="use $_;\n";
                }

$out.=lexical($href) unless $opts{no_alias};		#add aliased variables	from hash
$out.='
	my %cache;	#Stores code refs using caller as keys

	#lexical plex changes the prepare and also reuses options with out making it explicit
        my sub plex{
                my ($path, $vars, %opts)=@_;
		\my %fields=$href;


                my $template=Template::Plex->new(\&Template::Plex::_prepare_template, $path, $vars?$vars:\%fields, %opts?%opts:%options);

		$template;
        }
	my sub plex_clear {
		%cache=();
	}
        my sub skip{
		goto _PLEX_SKIP;
        }


	$plex->[Template::Plex::Base::skip_]=\&skip;

	my sub plx {
		my ($path,$vars,%opts)=@_;

		my $id=$path.join "", caller;
		$cache{$id} and return $cache{$id}->render;
		
		my $template=&plex;
		$cache{$id}//=$template;
		$template->setup;
		$template->render;
	}

	my sub init :prototype(&){
		$self->_init(@_);
	}


	sub {
		no warnings \'uninitialized\';
		no strict;
		#my $plex=shift;
		my $self=shift;

		\\my %fields=shift//\\%fields;


		return qq{'.$_data_.'};

		_PLEX_SKIP:
		"";

	}
};';

#my $line=0;
#say map { $line++ . $_."\n"; } split "\n", $out;
#$out;
};

# First argument the template string/text. This is any valid perl code
# Second argument is a hash ref to default or base level fields
# returns a code reference which when called renders the template with the values
sub _prepare_template{
	my ($plex, undef, $href, %opts)=@_;
	$href//={};
	\my %fields=$href;
	\my %meta=\%opts;

	#$plex now variable is now of base class
	$plex=($opts{base}//"Template::Plex::Base")->new($plex);

	$plex->[Template::Plex::Base::meta_]=\%opts;
	$plex->[Template::Plex::Base::args_]=$href;

 	my $ref=eval &Template::Plex::bootstrap;
	if($@ and !$ref){
		print STDERR "Error in $opts{file}";
		print  STDERR "EVAL: ",$@;
		print  STDERR "EVAL: ",$!;
	}
	$plex->[Template::Plex::Base::sub_]=$ref;
	$plex;
}





#a little helper to allow 'including' templates into each other
sub _munge {
	my ($input, %options)=@_;

	#test for literals
	my $path;	
	if($input =~ /^"(.*)"$/){
		#literal		
		$path=$1;	
	}
	elsif($input =~ /^'(.*)'$/){
		#literal		
		$path=$1;	
	}
	else {
		#not supported?
		#
	}

	plex($path,"",%options);
}

sub _subst_inject {
	\my $buffer=\(shift);
	while($buffer=~s|$Include|_munge($1, @_)|e){
		#TODO: Possible point for diagnostics?
	};
}

sub _block_fix {
	#remove any new line immediately after a ]} pair
	\my $buffer=\(shift);
	#$buffer=~s/^\]\}$/]}/gms;
	
	$buffer=~s/^(\@\{\[.*?\]\})\n/$1/gms;
        ##############################################
        # while($buffer=~s/^\]\}\n/]}/gs){           #
        # }                                          #
        # while($buffer=~s/^(@\{\[.*?\]\})\n/$1/gs){ #
        # }                                          #
        ##############################################

}

sub _init_fix{
	\my $buffer=\$_[0];
	#Look for an init block
	#unless($buffer=~/\@\[\{\s*init\s*\{
	unless($buffer=~$Init){
		carp "Template::Plex no init block detected. Adding dummy";
		$buffer="\@{[init{}]}".$buffer;
	}

}

my $prepare=\&_prepare_template;

#load a template to be rendered later.
# Compiled once but usable multiple times
sub plex{
	my ($path,$vars,%opts)=@_;
	#unshift @_, $prepare;	#push current top level scope
	my $template=Template::Plex->new($prepare,$path,$vars,%opts);

	$template;
}

my %cache; #toplevel cache
#Load template and render in one call. Easy for on offs
sub plx {
	my ($path,$vars,%opts)=@_;
	my $id=$path.join "", caller;
	$cache{$id} and "exisiting !" and return $cache{$id}->render;
	my $template=&plex;
	$cache{$id}//=$template;
	$template->setup;
	$template->render;
}

sub plex_clear {
	%cache=();
}


sub block :prototype(&) {
	$_[0]->();
	return "";
}
*pl=\*block;



sub new{
	my $plex=bless [], shift;
	my ($prepare, $path, $args, %options)=@_;
	my $root=$options{root};
	#croak "plex: even number of arguments required" if (@_-1)%2;
	croak "plex: first argument must be defined" unless defined $path;
	#croak "plex: at least 2 arguments needed" if ((@_-1) < 2);

	my $data=do {
		local $/=undef;
		if(ref($path) eq "GLOB"){
			#file handle
			$options{file}="$path";
			<$path>;
		}
		elsif(ref($path) eq "ARRAY"){
			#process as inline template
			$options{file}="$path";
			join "", @$path;
		}
		else{
			#Assume a path
			#Prepend the root if present
			$options{file}=$path;
			$path=catfile $root, $path if $root;
			my $fh;
			if(open $fh, "<", $path){
				<$fh> 
			}
			else {
				carp "Could not open file: $path $!";
				"";
			}


		}
	};

	$args//={};		#set to empty hash if not defined
	
	chomp $data;
	#Perform inject substitution
	_subst_inject($data, root=>$root) unless $options{no_include};
	#Perform suppurfluous EOL removal
	_block_fix($data) unless $options{no_block_fix};
	_init_fix($data) unless $options{no_init_fix};
	if($args){
		#Only call this from top level call
		#Returns the render sub

		state $package=0;
		$package++;
		$options{package}="Template::Plex::temp".$package; #force a unique package if non specified
		#$options{self}//=$plex;
		#$options{args}//=$args;
		$prepare->($plex, $data, $args, %options);	#Prepare in the correct scope
	}
	else {
		$data;
	}
}


#Join map
sub jmap :prototype(&$@){
	my ($sub,$delimiter)=(shift,shift);	#block is first
	$delimiter//="";	#delimiter is whats left
	join $delimiter, map &$sub, @_;
}



1;
