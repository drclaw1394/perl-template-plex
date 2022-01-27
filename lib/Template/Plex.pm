package Template::Plex;
use strict;
use warnings;
use version; our $VERSION = version->declare('v0.1.0');
use feature qw<say refaliasing>;
no warnings "experimental";

use Exporter 'import';


our %EXPORT_TAGS = ( 'all' => [ qw( prepare_template slurp_template) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	prepare_template	
	slurp_template
);

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

sub _subst_inject {
	\my 	$buffer=\$_[0];
	while($buffer=~s|\@\{\[\s*inject\("(\w+)"\)\]\}|slurp_template("$1.tpl")|e){
		
	}
}

#Read an entire file and return the contents
sub slurp_template{
	my $path=shift;
	my $args=shift;
	do {
		local $/=undef;
		if(open my $fh, "<", $path){
			my $data=<$fh>;
			_subst_inject($data);
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
