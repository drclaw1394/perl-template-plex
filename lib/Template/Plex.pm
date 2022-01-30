package Template::Plex;
use strict;
use warnings;

use Symbol qw<delete_package>;
use Carp qw<croak>;
use version; our $VERSION = version->declare('v0.1.0');
use feature ":all";#qw<say state refaliasing>;
no warnings "experimental";

use File::Basename qw<dirname basename>;
use File::Spec::Functions qw<catfile>;
use Exporter 'import';


our %EXPORT_TAGS = ( 'all' => [ qw( plex) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	plex
);

my $Include=qr|\@\{\s*\[\s*include\s*\(\s*(.*?)\s*\)\s*\] \s* \}|x;

use constant KEY_OFFSET=>0;
use enum  ("package_=".KEY_OFFSET, qw<sub_>);
use constant KEY_COUNT=>sub_-package_+1;

# First argument the template string/text. This is any valid perl code
# Second argument is a hash ref to default or base level fields
# returns a code reference which when called renders the template with the values
sub _prepare_template{
	my $self=shift;
	\my $data=\shift;
	my $href=shift;
	my %opts=@_;


	die "NEED A HASH REF " unless  ref $href eq "HASH" or !defined $href;
	$href//={};
	\my %fields=$href;	#hash ref

	my $string="";
	#make lexically available aliases for all keys currently defined in the input
	for my $k (keys %fields){
		$string.= "\\my \$$k=\\\$fields{$k};\n";
	}
	state $package="plex0";
	$package++;
	$self->[package_]=$package;
	$string.=
	"package $package;\n"			#unique package for dynamic templates variables
	."*plex=*Template::Plex::plex;\n"	#Add plex symbol for recursive calls
	."sub {\n"
	."no warnings 'uninitialized';\n"	#Disable warnings for uninitialised variables
	."no strict;\n"				#Non existant variables don't stop execution
	#."no feature qw<indirect>;\n"		#
	."my \$self=shift;\n"
	."\\my %fields=shift//\\%fields;\n"
	#."my \$__root__=".($options{root}?"\"$options{root}\"":"undef").";\n"
	."my %options=%opts;\n"
	."qq{$data}; };\n";
	my $ref=eval $string;
	if($@ and !$ref){
		print  $@;
		print  $!;
	}
	$self->[sub_]=$ref;
	$self;
}

sub render {
	$_[0][sub_](@_);
}

sub DESTROY {
	say "IN DESTROY";
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
	plex($path,undef,%options);
}

sub _subst_inject {
	\my $buffer=\(shift);
	#my $root=$_[1];
	while($buffer=~s|$Include|_munge($1, @_)|e){
		#TODO: Possible point for diagnostics?
	};
}

sub plex{
	__PACKAGE__->new(@_)
}

#Read an entire file and return the contents
sub new{
	my $self=bless [], shift;
	my ($path, $args, %options)=@_;
	my $root=$options{root};
	croak "plex: even number of arguments required" if @_%2;
	croak "plex: first argument must be defined" unless defined $path;
	croak "plex: at least two arguments needed" if @_ < 2;

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
			<$fh> if open $fh, "<", $path;
		}
	};
	
	#Perform inject substitution
	_subst_inject($data, root=>$root) unless $options{no_include};
	if($args){
		#Only call this from top level call
		#Returns the render sub
		$self->_prepare_template($data, $args, %options);
	}
	else {
		$data;
	}
}

1;
