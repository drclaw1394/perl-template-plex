use strict;
use warnings;

use Test::More tests => 17;
use Data::Dumper;


BEGIN { use_ok('Template::Plex') };

use Template::Plex;

my $default_data={data=>[1,2,3,4]};

my $template=q|@{[init { }]}
@{[
	do {
		#my $sub='Sub template: $data->@*';
		my $s="";
		for my $d ($fields{data}->@*) {
			$s.="row $d\n"
		}
		$s;
	}
]}|;


$template=plex [$template], $default_data;
$template->setup;
my $result=$template->render();
my $expected="";
for(1,2,3,4){
	$expected.="row $_\n";
}
ok $result eq $expected, "Base values";





$default_data->{data}=[5,6,7,8];
$result=$template->render();
$expected="";
for(5,6,7,8){
	$expected.="row $_\n";
}
ok $result eq $expected, "Updated Base values";



my $override_data={data=>[9,10,11,12]};
$result=$template->render($override_data);
$expected="";
for(9,10,11,12){
	$expected.="row $_\n";
}
ok $result eq $expected, "Using override values";



$template=q|@{[init {}]}
@{[
	do {
		my $s="";
		for my $d ($data->@*) {
			$s.="row $d\n"
		}
		$s;
	}
]}|;

$default_data={data=>[1,2,3,4]};
$template=plex [$template], $default_data;
$template->setup;
$result=$template->render($override_data);
$expected="";
for(1,2,3,4){
	$expected.="row $_\n";
}
ok $result eq $expected, "Lexical access";


$template=q|@{[init {}]}my name is $name not $fields{name}|;
$default_data={name=>"John"};
$override_data={name=>"Jill"};

$template=plex [$template], $default_data;
$template->setup;
$result=$template->render($override_data);
$expected="";
ok $result eq "my name is John not Jill", "Lexical and override access";




{
	my $top_level='@{[init{}]}top level template recursively using another:@{[plx "sub1.plex"]}';

	my $t=plex [$top_level], {}, root=> "t";
	$t->setup;
	my $text=$t->render;
	my($first,$last)=split ":", $text;
	ok $last eq 'Sub template 1', "Recursive plex";
}

{
	my $top_level='@{[init{}]}top level template recursively using another:@{[plx "sub2.plex"]}';
	my %vars=(value=>10,user=>{});
	my $t=plex [$top_level], \%vars, root=> "t";
	$t->setup;
	my $text=$t->render;
	my($first,$last)=split ":", $text;
	ok $last eq 'Sub template 2 10', "Recursive plex, top aliased";
	#print Dumper \%vars;
	ok $vars{user}{new_field} eq "NEW", "New field from sub template";
	#print $text;
	#exit;
}


{
	my $top_level='This template is loaded,cached and executed automatically. $value';
	my %vars=(value=>10);
	for(10,20){
		$vars{value}=$_;
		my $output= plx [$top_level], \%vars;
		ok $output =~ /$_/, "plx rendering ok";
	}
}

{
	my $top_level='@{[init{}]}skipped:@{[plx "sub3.plex"]}';
	my %vars=(value=>10);
	my $t=plex [$top_level], \%vars, root=> "t";
	$t->setup;

	my $text=$t->render;
	ok $text eq 'skipped:', "skip template";
}

{
	#Testing base class
	my %vars;
	my $result=plx ['@{[init{}]}@{[$self->__internal_test_proxy__]}'], \%vars;

	#print  "TESTING BASE: ".$result; exit;

	ok $result eq "PROXY", "Base class methods";

}
{
	#Testing sub class
	package My::Base{
		use parent "Template::Plex::Base";
		sub __internal_test_proxy__{
			"OVERRIDE";

		}
	}
	my %vars;
	my $result=plx ['@{[$plex->__internal_test_proxy__]}'], \%vars, base=>"My::Base";

	ok $result eq "OVERRIDE", "Subclass methods";

}

{

	#Testing perpare/init
	my $tt=[
		'@{[init{
			$self->args->{test}="testing";
		} ]}Hello!'
	];

	my %vars;
	my $template=plex $tt, \%vars;
	$template->setup;
	my $setup=$template->setup;
	my $render=$template->render;
	ok $setup eq "", "Setup without render";
	ok $vars{test} eq "testing", "Setup without render";
	ok $render eq "Hello!", "Render";
}
