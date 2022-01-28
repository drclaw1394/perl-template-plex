use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('Template::Plex') };
use Template::Plex;
my $default_data={data=>[1,2,3,4]};

my $template=q|@{[
	do {
		my $s="";
		for my $d ($fields{data}->@*) {
			$s.="row $d\n"
		}
		$s;
	}
]}|;


my $render=plex [$template], $default_data;
my $result=$render->();
my $expected="";
for(1,2,3,4){
	$expected.="row $_\n";
}
ok $result eq $expected, "Base values";




$default_data->{data}=[5,6,7,8];
$result=$render->();
$expected="";
for(5,6,7,8){
	$expected.="row $_\n";
}
ok $result eq $expected, "Updated Base values";



my $override_data={data=>[9,10,11,12]};
$result=$render->($override_data);
$expected="";
for(9,10,11,12){
	$expected.="row $_\n";
}
ok $result eq $expected, "Using override values";



$template=q|@{[
	do {
		my $s="";
		for my $d ($data->@*) {
			$s.="row $d\n"
		}
		$s;
	}
]}|;

$default_data={data=>[1,2,3,4]};
$render=plex [$template], $default_data;
$result=$render->($override_data);
$expected="";
for(1,2,3,4){
	$expected.="row $_\n";
}
ok $result eq $expected, "Lexical access";


$template=q|my name is $name not $fields{name}|;
$default_data={name=>"John"};
$override_data={name=>"Jill"};

$render=plex [$template], $default_data;
$result=$render->($override_data);
$expected="";
ok $result eq "my name is John not Jill", "Lexical and override access"
