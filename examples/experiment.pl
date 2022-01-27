use feature ":all";
use warnings;
#use strict;
#no warnings "uninitialized";
use Template::Plex;
use Data::Dumper;
my @items=qw<eggs watermellon hensteeth>;
my $hash={
	title=>"Mr",
	surname=>"chick"
};

my $template=slurp_template("external.tpl",$hash);

say $template->();
$hash->{surname}="lkajsdf";
say $template->();
#################################################
#                                               #
# my $render=prepare_template($template,$hash); #
# say $render->();                              #
# $hash->{surname}="dude";                      #
# say $render->();                              #
#################################################

#my $template=slurp_template "examples/external.tpl",{title=>$title};
#say $template;

###########################################################
# my $render=prepare_template($template,{title=>$title}); #
# print "\n";                                             #
# print $render->();                                      #
# my $d=Data::Dumper->new([$render]);                     #
# $d->Deparse(1);                                         #
# #say $d->Dump;                                          #
#                                                         #
#                                                         #
# #say "result: \n",eval "qq|".$template."|";             #
# say $! if $!;                                           #
# say $@ if $@;                                           #
###########################################################

__DATA__
<html>
	Dear $title $surname,

	The presents of you feet have nothing to do with the price of the following in china:

@{[ 
do {
	my $list;

	for(1..10){
		$list.=$_;
	}
	scalar reverse $list;
}
]}
@{[ 
do {
	join "\n", map " " x8 . uc, @items
    }
]}
	Regards

		Managment
</html>
