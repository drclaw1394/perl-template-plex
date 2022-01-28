package Template::Plex;
use strict;
use warnings;

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

my $Inject=qr|\@\{\s*\[\s*inject\s*\(\s*(.*?)\s*\)\s*\] \s* \}|x;


# First argument the template string/text. This is any valid perl code
# Second argument is a hash ref to default or base level fields
# returns a code reference which when called renders the template with the values
sub _prepare_template{
	\my $data=\shift;
	my $href=shift;
	my $root=shift;
	die "NEED A HASH REF " unless  ref $href eq "HASH" or !defined $href;
	$href//={};
	\my %fields=$href;	#hash ref

	my $string="";
	#make lexically available aliases for all keys currently defined in the input
	for my $k (keys %fields){
		$string.= "\\my \$$k=\\\$fields{$k};\n";
	}
	$string.=
	"sub {\nno warnings 'uninitialized';\n"
	."no strict;\n"
	."\\my %fields=shift//\\%fields;\n"
	."my \$root=".($root?"\"$root\"":"undef").";\n"
	."qq{$data}; };\n";
	my $ref=eval $string;
	if($@ and !$ref){
		print  $@;
		print  $!;
	}
	$ref;
}

#a little helper to allow 'including' templates into each other
sub _munge {
	my ($input, $root)=@_;

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
	plex($path,undef,$root);
}

sub _subst_inject {
	\my $buffer=\$_[0];
	my $root=$_[1];
	while($buffer=~s|$Inject|_munge($1,$root)|e){
		#TODO: Possible point for diagnostics?
	};
}

#Read an entire file and return the contents
sub plex{
	my ($path, $args, $root, $cb)=@_;
	
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
			say "PATH: $path";
			my $fh;
			<$fh> if open $fh, "<", $path;
		}
	};
	
	#Perform inject substitution
	_subst_inject($data, $root);
	if($args){
		#Only call this from top level call
		#Returns the render sub
		_prepare_template($data, $args, $root);
	}
	else {
		$data;
	}
}

1;
