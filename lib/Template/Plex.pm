package Template::Plex;
use strict;
use warnings;
use version; our $VERSION = version->declare('v0.1.0');
use feature qw<say refaliasing>;
no warnings "experimental";

use File::Basename qw<dirname basename>;
use File::Spec::Functions qw<catfile>;
use Exporter 'import';


our %EXPORT_TAGS = ( 'all' => [ qw( prepare_template slurp_template) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	prepare_template	
	slurp_template
);

my $Inject=qr|\@\{\s*\[\s*inject\s*\(\s*(.*?)\s*\)\s*\] \s* \}|x;
#my $Inject=qr|\@ \s* \{ \s* \[ \s* inject \s* \( (.*+) \) \s* \] \}|x;

my @Caller; #stack of paths to curretly preparing templates

# First argument the template string/text. This is any valid perl code
# Second argument is a hash ref to default or base level fields
# returns a code reference which when executed returns anything that perl ca
sub prepare_template{
	\my $data=\shift;
	my $href=shift;
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
	."\\my %fields=shift//\\%fields;\n"
	."qq{$data}; };\n";
	my $ref=eval $string;
	if($@ and !$ref){
		print  $@;
		print  $!;
	}
	$ref;
}

sub _munge {
	my $input=shift;
	say "in munge: $input";
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
	}
	say $path;
        #########################################
        # #Do relative-to-template file mapping #
        # my $dir=dirname((caller)[1]);         #
        # $path =catfile $dir,$path;            #
        # say $path;                            #
        #########################################
	slurp_template($path);
}

sub _subst_inject {
	\my 	$buffer=\$_[0];
	say "asdofj";
	#say $buffer;
	if($buffer=~$Inject){
		say "got one $1";
	};
	while($buffer=~s|$Inject|_munge($1)|e){say "GOT A MATCH"};
	#while($buffer=~s|$Inject|slurp_template("$1.plex")|e){say "GOT A MATCH"};
	#while($buffer=~s|\@\{\[\s*inject\("(\w+)"\)\]\}|slurp_template("$1.tpl")|e){}
}

#Read an entire file and return the contents
sub slurp_template{
	my $path=shift;
	my $args=shift;
	do {
		local $/=undef;
		if($args){
			#Called from application
			push @Caller ,dirname $path;		#push to stack
		}
		else {
			#Called from template
			say catfile $Caller[-1],$path
		}

		if(open my $fh, "<", $path){
			my $data=<$fh>;
			_subst_inject($data);
			pop @Caller;
			if($args){
				prepare_template($data,$args);
			}
			else {
				$data;
			}
		}
		else {
			#say "Error slurpping";
			"";
		}
	}
}

1;
