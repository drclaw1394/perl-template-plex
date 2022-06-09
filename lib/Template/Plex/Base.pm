package Template::Plex::Base;

use strict;
use warnings;

use feature qw<say isa>;
no warnings "experimental";
use Template::Plex;
use Log::ger;
use Log::OK;

use Symbol qw<delete_package>;

use constant KEY_OFFSET=>0;
use enum ("plex_=0",qw<meta_ args_ sub_ package_ init_done_flag_ skip_

	slots_ parent_ default_result_
	>);

use constant KEY_COUNT=>default_result_ - plex_ +1;


sub new {
	my ($package, $plex)=@_;
	my $self=[];
	$self->[plex_]=$plex;
	bless $self, $package;
}


sub _plex_ {
	$_[0][Template::Plex::Base::plex_];
}

sub meta :lvalue { $_[0][Template::Plex::Base::meta_]; }

sub args :lvalue{ $_[0][Template::Plex::Base::args_]; }

sub init_done_flag:lvalue{ $_[0][Template::Plex::Base::init_done_flag_]; }


sub _render {
	#sub in plex requires self as first argument
	return $_[0][sub_](@_);
}

sub skip {
	Log::OK::DEBUG and log_debug("Template::Plex::Base: Skipping Template: ".$_[0]->meta->{file});
	$_[0]->[skip_]->();
}

#A call to this method will run the sub an preparation
#and immediately stop rendering the template
sub _init {
	my ($self, $sub)=@_;
	
	return if $self->[init_done_flag_];
	Log::OK::DEBUG and log_debug("Template::Plex::Base: Initalising Template: :".$self->meta->{file});
	unless($self isa Template::Plex::Base){
	#if($self->[meta_]{package} ne caller){
		Log::OK::ERROR and log_error("Template::Plex::Base: init must only be called within a template: ".$self->meta->{file});
		return;
	}

	$self->pre_init;
	$sub->();
	$self->post_init;

	$self->[init_done_flag_]=1;
	$self->skip;
	"";		#Must return an empty string
}

sub pre_init {

}

sub post_init {

}

#Execute the template in setup mode
sub _setup {
	my $self=shift;
	#Test that the caller is not the template package
	Log::OK::DEBUG and log_debug("Template::Plex::Base: Setup Template: ".$self->meta->{file});
	if($self->[meta_]{package} eq caller){
		#Log::OK::ERROR and log_error("Template::Plex::Base: setup must only be called outside a template: ".$self->meta->{file});
		#		return;
	}
	$self->[init_done_flag_]=undef;
	$self->render(@_);
	
	#Check if an init block was used
	unless($self->[init_done_flag_]){
		Log::OK::WARN and log_warn "Template::Plex::Base ignoring no \@{[init{...}]} block in template from ". $self->meta->{file};
		$self->[init_done_flag_]=1;
	}
}

# Slotting and Inheritance
#
#

#Marks a slot in a parent template.
#A child template can fill this out by calling fill_slot on the parent
sub slot {
	my ($self, $slot_name)=@_;
	$slot_name//="default";	#If no name assume default

	Log::OK::TRACE and log_trace "Plexsite: Template called slot: $slot_name";
	my $data=$self->[slots_]{$slot_name};
	my $output="";
	#for my $data (@data){
		if($data isa Template::Plex::Base){
			#render template
			if($slot_name eq "default"){
				Log::OK::TRACE and log_trace "Plexsite: copy default slot";
				$output.=$self->[default_result_];
			}
			else {
				Log::OK::TRACE and log_trace "Plexsite: render non default template slot";
				$output.=$data->render;
			}
		}
		else {
			Log::OK::TRACE and log_trace "Plexsite: render non template slot";
			#otherwise treat as text
			$output.=$data
		}
	#}
	$output
}

sub fill_slot {
	my ($self)=shift;
	my $parent=$self->[parent_];
	unless($parent){
		Log::OK::WARN and log_warn "Plexsite: Not parent setup for ". $self->meta->{file};
		return;
	}

	unless(@_){
		#An unnamed fill spec implies the default slot
		$parent->[slots_]{default}=$self;
	}
	else{
		for my ($k,$v)(@_){
			$parent->[slots_]{$k}=$v;
		}
	}
	"";
}


sub inherit {
	my ($self, $path)=@_;
	Log::OK::DEBUG and log_debug "Plexsite Inherit ".__PACKAGE__;
	#If any parent variables have be setup load the paret template

	#Setup the parent
	my $p=plex($path, $self->args, $self->meta->%*);
	$p->[slots_]={};

	#Add this template to the default slot
	$p->[slots_]{default}=$self;
	$self->[parent_]=$p;
	#$self->[parent_]->setup;
}
sub setup {
	my ($self)=@_;
	#Run super setup.
	Log::OK::DEBUG and log_debug "Plexsite: setup ". $self->meta->{file};
	$self->_setup;


	#Check for inheritance. Run setup.
	#This setup call is after init block so
	#inhert call can be anywhere an init block

	if($self->[parent_]){
		$self->[parent_]->setup;
	}
	"";
}

sub render {
	my ($self, $fields, $top_down)=@_;
	#We don't call parent render if we are uninitialised


	
	#If the template uninitialized, we just do a first pass
	unless($self->init_done_flag){

		return $self->_render;

	}
	Log::OK::TRACE and log_trace "Plexsite: render :".$self->meta->{file}." flag: ".($top_down//"");
	#From here is a normal render call on this template

	#Render with no inheritance when no parent present

	#Render as if no parent is  present
	if(!$self->[parent_] and !$top_down){
		#This is Normal template or top of hierarchy
		#child has called parent and parent is the top
		#
		#Turn it around and call back down the chain
		#

		Log::OK::TRACE and log_trace "Plexsite: render. no parent bottom up. assume normal render";
		#Check slots. Slots indicate we need to call the child first
		if($self->[slots_] and $self->[slots_]->%*){
			Log::OK::TRACE and log_trace "Plexsite: render. rendering default slot";
			$self->[default_result_]=$self->[slots_]{default}->render($fields,1);
		}

		#now call render on self. This renders non hierarchial templates
		Log::OK::TRACE and log_trace "Plexsite: render. rendering body and sub templates";
		my $total=$self->_render($fields); #Call down the chain with top_down flag
		$self->[default_result_]="";	#Clear
		return $total;
	}
	elsif($top_down){

		Log::OK::TRACE and log_trace "Plexsite: render: top down call";
		$self->_render($fields, $top_down);

	}
	elsif($self->[parent_] and !$top_down) {
		Log::OK::TRACE and log_trace "Plexsite: render: child calling up to parent";
		#Child is calling parent
		$self->[parent_]->render($fields);

	}
	else{
	}
}

sub parent {$_[0][parent_];}







sub DESTROY {
	delete_package $_[0][package_] if $_[0][package_];
}

#Internal testing use only
sub __internal_test_proxy__ {
	"PROXY";
}

1;
