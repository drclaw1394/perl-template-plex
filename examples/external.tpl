This is the main template: Title in external is $title
@{[ do {
	BEGIN {
		use Time::HiRes qw<time>
	}
	join "", map time."\n", (1..10) 
}
]}

	
@{[inject("header")]}

@{[$surname =~ /chick/i ?"@{[inject("header")]}":"Not for you" ]}

@{['other perl code']}

