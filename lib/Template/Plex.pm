package Template::Plex;
use strict;
use warnings;

use Symbol qw<delete_package>;
use Carp qw<carp croak>;
use version; our $VERSION = version->declare('v0.1.0');
use feature ":all";#qw<say state refaliasing>;
no warnings "experimental";

use File::Basename qw<dirname basename>;
use File::Spec::Functions qw<catfile>;
use Exporter 'import';
use Data::Dumper;


our %EXPORT_TAGS = ( 'all' => [ qw( plex) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	plex
);

my $Include=qr|\@\{\s*\[\s*include\s*\(\s*(.*?)\s*\)\s*\] \s* \}|x;

use constant KEY_OFFSET=>0;
use enum  ("package_=".KEY_OFFSET, qw<sub_>);
use constant KEY_COUNT=>sub_-package_+1;

sub new;	#forward declare new;

sub lexical{
	my $href=shift;
	die "NEED A HASH REF " unless  ref $href eq "HASH" or !defined $href;
	$href//={};
	\my %fields=$href;

	my $string="";
	say "Fields: ", %fields;
	for my $k (keys %fields){
		$string.= "\\my \$$k=\\\$fields{$k};\n";
	}
	$string;
}

sub  bootstrap{
	say "BOOTSTRAP OPTIONS: ", Dumper @_;
	my $self=shift;
	\my $_data_=\shift;
	my $href=shift;

	$href//={};
	\my %fields=$href;
	say "FIELDS are: ",%fields;
	my %opts=@_;

my $out="{";
$out.= '	\my %fields=$href;
';
$out.=lexical($href);		#add aliased variables	from hash
$out.='
	my $prepare=sub {
	say "IN PREPARE IN SUB";
		my $self=$_[0];
		#my $_data_=\$_[1];
		my $href=$_[2];

		$href//={};
		\my %fields=$href;
		';

		#$out.=lexical($href);		#add aliased variables	from hash
$out.='
		#say "DATA IS: $data in PREPARE";
		my $ref=eval bootstrap (@_);
		#say "REF IN PREPARE SUB: ", Dumper $ref;
		if($@ and !$ref){
			print  $@;
			print  $!;
		}
		#say "EXECUTING: ", $ref->();
		#say $ref;
		$self->[sub_]=$ref;
		$self;
	};

';
				#into current lexical scope
$out.='

	sub plex{
		unshift @_, $prepare;	#Sub templates now access lexical plex sub routine
					#with access to its scoped $prepare sub and variables
		say "IN LEXICAL PLEX";
		__PACKAGE__->new(@_)
	}

';
$out.='
sub {
	no warnings \'uninitialized\';
	no strict;
	say "Template is: ",Dumper @_;
	my $self=shift;
	\\my %fields=shift//\\%fields;
	my %options=%opts;
';


$out.='
	qq{'.$_data_.'};

}
}';
my $line=0;
say map { $line++ . $_."\n"; } split "\n", $out;
$out;
};

# First argument the template string/text. This is any valid perl code
# Second argument is a hash ref to default or base level fields
# returns a code reference which when called renders the template with the values
sub _prepare_template{
	my $self=$_[0];
	#my $_data_=\$_[1];
	my $href=$_[2];

	$href//={};
	\my %fields=$href;

	my $ref=eval &bootstrap;
	if($@ and !$ref){
		print  "EVAL: ",$@;
		print  "EVAL: ",$!;
	}
	$self->[sub_]=$ref;
	$self;
}

sub render {
	$_[0][sub_](@_);
}

sub sub {
	$_[0][sub_];
}

sub DESTROY {
	delete_package $_[0][package_] if $_[0][package_];
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
	#my $root=$_[1];
	while($buffer=~s|$Include|_munge($1, @_)|e){
		#TODO: Possible point for diagnostics?
	};
}
my $prepare=\&_prepare_template;

sub plex{
	unshift @_, $prepare;	#push current top level scope
	__PACKAGE__->new(@_)
}



sub new{
	my $self=bless [], shift;
	my ($prepare, $path, $args, %options)=@_;
	my $root=$options{root};
	croak "plex: even number of arguments required" if (@_-1)%2;
	croak "plex: first argument must be defined" unless defined $path;
	croak "plex: at least 2 arguments needed" if ((@_-1) < 2);

	my $data=do {
		local $/=undef;
		if(ref($path) eq "GLOB"){
			#file handle
			<$path>;
		}
		elsif(ref($path) eq "ARRAY"){
			#process as inline template
			join "", @$path;
		}
		else{
			#Assume a path
			#Prepend the root if present
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
	
	#Perform inject substitution
	_subst_inject($data, root=>$root) unless $options{no_include};
	if($args){
		#Only call this from top level call
		#Returns the render sub
		$prepare->($self, $data, $args,%options);	#Prepare in the correct scope
		#$self->_prepare_template($data, $args, %options);
	}
	else {
		$data;
	}
}

1;
