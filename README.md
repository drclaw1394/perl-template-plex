# NAME

Template::Plex - Templates in (P)erl using (Lex)ical Aliasing

# SYNOPSIS

```perl
    use Template::Plex;

    #Data for templates to alias and access
    my $base_data={
            name=>"James",
            age=>"12",
            fruit=>"banana"
    };


    #The actual template text
    #
    my $inline_template='$name\'s age $age and favourite fruit is $fruit'

    #Preparing the template in Template::Plex object
    #
    my $t=plex [$inline_template], $base_data, %options;


    #Render with the values aliased in $base_data
    $t->render;
    #
    #=>     James's age is 12 and favourite fruit is banana

    #Update the data in the hash used during preparation.
    #
    $base_data->{qw<name,fruit>}=qw<John apple>;


    #Rendering again will use updated aliased values
    #
    $t->render;
    #
    #=>     John's age is 12 and favourite fruit is apple
```

# DESCRIPTION

This module is a mechanism to facilitate the use of perl (not embedded perl) as
a text processing template language. 

Conceptually, a `Template::Plex` template is just a string returned from a
subroutine in perl's double quoted context, with the outer operators removed:

```
    #PERL
    "This is is a perl string interpolating @{[ map uc, qw<a b c d>]}"

    #  or

    qq{This is is a perl string interpolating @{[ map uc, qw<a b c d>]}}
    

    #PLEX template. Same as PERL syntax, without the outer double quotes
    This is is a perl string interpolating @{[ map uc, qw<a b c d>]};

    #OUTPUT is the same for all of the above:
    This is is a perl string interpolating A B C D
```

Because of the powerful and flexible interpolation of strings in perl, you can
do just about anything in a Plex template. After all the template is just perl. 

The 'lexical' part of this modules refers to ability of variables to be
aliased into the template (more on this later). It improves the style and usage
of variables in a template while also allowing sub templates to access/override
variables using lexical scoping.

Some feature highlights:

- Templates are written in perl syntax
- Templates are compiled into a perl subroutine
- Lexical and package variables accessed/created within templates
- Call and create subroutines within templates
- 'Include' Templates within templates easily
- Recursive and conditional sub template loading
- Declare variables and subroutines in templates
- `use` other modules directly in templates

To get started after installation, copy the following lines into perl and execute:

```perl
    use strict;
    use warnings;
    use feature "say";
    use Template::Plex;
    my %vars=(name=>"Susan", age=>99);
    my $template=plex ['this is ${name}\'s inline template. $age young'], \%vars;
    say $template->render;
    
    @vars{qw<name age>}=qw<Richard 23>;
    say $template->render;
```

For more examples, checkout the examples directory in this distribution.

# MOTIATION

- So many templating systems available, yet none use perl as the template language?
- Lexical aliasing allows the input variables to be accessed directly by name
(i.e. `$name`) instead of as a member of a hash ref (i.e.
`$fields->{name}`) or by delimiting with custom syntax (i.e. `<%= name %>`)
- The perl syntax `@{[...]}`  will execute arbitrary perl statements in a double
quoted string. 
- Other templating system are very powerful, but have huge a huge APIs and
options. [Template::Plex](https://metacpan.org/pod/Template%3A%3APlex) could have a very minimal API with perl doing the
hard work

# TODO

- More tests
- Add a guide document
- CLI app to render .plex files
- Fix any bugs

# API

## `plex`

```
    plex $path, $variables_hash, %options
    
```

Creates a new instance of a template, loaded from a scalar, file path or an
existing file handle. 

**Multi Argument Version**

If 2 or more arguments are provided, the template is
loaded and prepared and returned. The returned template can be rendered by
calling the `render` method on it.

**Single  Argument Version**

If only the first argument is supplied, the template is loaded, prepared, and
rendered immediately. The rendered text is returned.  This is useful when using
sub templates, as the variables and options are already available from the top
level template.

The arguments are detailed below:

- `$path`

    This is a required argument.

    If `$path` is a string, it is treated as a file
    path to a template file. The file is opened and slurped with the content being
    used as the template

    If `$path` is filehandle, or GLOB ref, it is slurped with the content being
    used as the template. Can be used to read template stored in `__DATA__` for
    example

    If `$path` is an array ref, the items of the array are joined into a string,
    which is used directly as the template.

- `$variables_hash`

    This is an optional argument but if present must be an empty hash ref `{}` or
    `undef`.

    The top level items of the `$variables_hash` hash are aliased into the
    template using the key name (key names must be valid for a variable name for
    this to operate). This allows an element such as `$fields{name`}> to be
    directly accessible as `$name`.

    It also means any external modification of the items in `$variable_hash` will
    be visible in the template.

    In addition, the `$variables_hash` itself is aliased to `%fields` variable
    (note the %) and directly usable in the template like a normal hash e.g.
    `$fields{name}`

    If the `$variables_hash` is an empty hash ref `{}` or `undef` then no
    variables will be lexically aliased. The only variables accessible to the
    template will be via the `render` method call

- `Options`

    These are non required arguments, but must be key value pairs when used.

    Options are stored lexically in the rendering sub in the variable `%options`
    for recursive `plex` calls within a template.

    Currently supported options are:

    - **root**

        `root` is a directory path, which if present, is prepended to to the `$path`
        parameter if `$path` is a string (file path).

    - **no\_include**

        Disables the uses of the preprocessor include feature. The template text will
        not be scanned  and will prevent the `include` feature from operating.
        See `include` for more details

        This doesn't impact recursive calls to `plex` when dynamically/conditionally
        loading templates.

    - **package**

        Specifies a package to run the template in. Any `our` variables defined in
        the template will be in this package.  If a package is not specified, a unique
        package name is created to prevent name collisions

- Return value

    The return value is `Template::Plex` object which can be rendered using the
    `render` method

- Example Usage
		my $hash={
			name=>"bob",
			age=>98
		};

    ```perl
                my $template_dir="/path/to/dir";

                my $obj=plex "template.plex", $hash, root=>$template_dir;
    ```

## `render`

```
    $obj->render($fields);
```

This object method renders a template object created by `plex` into
a string. It takes an optional argument `$fields` which is a reference to a
hash containing field variables. `fields` is aliased into the template as
`%fields` which is directly accessible in the template

```perl
    eg
            my $more_data={
                    name=>"John",
            };
            my $string=$template->render($more_data);
            
            #Template:
            My name is $fields{John}
```

Note that the lexically aliased variables in `plex` are independent to the
`%fields` variable and can both be used simultaneously in a template

## `include`

```
    @{[include("path")}]

    where $path is path to template file to inject
```

Used in templates only.

This is a special directive that substitutes the text **@{\[include("path")\]}**
with the contents of the file pointed to by path. This is a preprocessing step
which happens before the template is prepared for execution

This API is only available in templates. If `root` was included in the options
to `plex`, then it is prepended to `path` if defined.

When a template is loaded by `plex` the processing of this is
subject to the `no_include` option. If `no_include` is specified, any
template text that contains the `@{[include("path")}]` text will result in a
syntax error

# PLEX TEMPLATE SYNTAX \\w EXAMPLES

Well, its just perl. Seriously. But if you haven't grasped the concept just
yet, a [Template::Plex](https://metacpan.org/pod/Template%3A%3APlex) template is a perl program with the two following
constraints:

- consists only of perl syntax permissible in a double quoted string
- outermost double quote operators are ommited from the program/template

This is best illustrated by example. Suppose the following text is stored in a
file or in the `__DATA__ ` section:

```
    The pot of gold at the end of the rainbow has $amount gold coins
    As for the rainbow, the colors are:
    @{[ map ucfirst."\n", @$colors ]}
    Good day!
```

Everything in the text is valid syntax in double quote operator, but the outer
double quote operator is omitted.

Or in other words, the template looks like plain text, but with double quoted
added, it is valid perl code.

Neat!

Following sections show example of particular scenarios

## Access to Existing Scalars, Arrays and Hashes

If `$variables_hash` was supplied during a `plex` call, the top level
elements will be aliased and accessible as normal scalars in the template. 

```perl
    This template uses a scalar $name that was lexically aliased
    Here the same variable can be accessed via $fields{name}        
    Calling render with an hash argument will override the $fields{name}
    AReallylong${word}WithAVariable

    access the array element $array->[$index]
    Accessing element $hash->{key} just for fun
```

## Executing a single (or list) of Statements

To achieve this, a neat trick is to dereference an inline reference to an
anonymous array. That is `@{[...]}`. The contents of the array is then the
result of the statements.  Sounds like a mouthful, but it is only a couple of
braces and lets you do some powerful things:

```perl
    Calling a subrotine @{[ my_sub() ]}
    Doing math a + b = @{[ $a+$b ]}
    Building an array @{[ uc("red"),uc("blue")]}
    Mapping @{[ join "\n", map uc, @items]}
    
```

## Executing Multiple Statements

When a single statement won't do, the `do{}` construct executes a block, which
can have any number of statements and returns the last statement executed into
the template

```perl
    Executing multiple statments @{[ do {
            my $a=1; 
            $a++; 
            ($a,-$a)

    } ]} in this template
```

## Using/Requiring Modules

Again standard perl syntax for the win

```perl
    Template will call hi res time 
    The time is: @{[ time ]}
    @{[ do {
            BEGIN {
                    use Time::HiRes qw<time>;
            }
    }
    ]}
```

## Declaring Variables

Variables can be declared in the `@{[..}]` container. 

`my` variables will only be visible within the `@{[..]}` block it was defined.

```perl
    eg      #render a mini single line template with my variable
            @{[ do {
                    my $a=time;
                    $a+=23;
                    "Time is: $a";  
            } }]
```

`our` variables can be used instead of `my` variables and are visible
throughout the current template, including recursively used templates

```
    eg
            @{[ do {
                    our $a=time;
                    "";
            } }]
            
            Template package variable is $a

            @{[ do {
                    $a+=23:
                    ""
            } ]}
            Updated template package variable is $a
```

Sub templates loaded with `include` and recursive `plex` calls will have
direct access to package variables created in the template. A new unique
package is created for each top level use of plex to prevent name collisions.

# TIPS ON USAGE

## Points to note

- Aliasing is a two way steet

    Changes made to aliased variables external to the template are available inside
    the template (one of the main tenets of this module)

    Changes make to aliased variables internal to the template are available outside
    the template.

- Unbalanced Delimiter Pairs

    Perl double quote operators are smart and work on balanced pairs of delimiters.
    This allows for the delimiters to appear in the text body without error.

    However if your template doesn't have balanced pairs (i.e. a missing "}" in
    javascript/c/perl/etc), the template will fail to compile and give a strange
    error.

    If you know you don't have balanced delimiters, then you can escape them with a
    backslash

    Currently [Template::Plex](https://metacpan.org/pod/Template%3A%3APlex) delimiter pair used is **{ }**.  It isn't changeable in
    this version.

- Are you sure it's one statement?

    If you are having trouble with `@{[...]}`, remember the result of the last
    statement is returned into the template.

    Example of single statements

    ```perl
        @{[time]}                       #Calling a sub and injecting result
        @{[$a,$b,$c,time,my_sub]}       #injecting list
        @{[our $temp=1]}                #create a variable and inject 
        @{[our ($a,$b,$c)=(7,8,9)]}     #declaring a
    ```

    If you are declaring a package variable, you might not want its value injected
    into the template at that point.  So instead you could use `do{..}` execute
    multiple statements, with the last statement being an empty string (or the
    value you want returned into the template).

    ```
        @{[ do {our $temp=1;""} }];
    ```

- Last newline of templates are chomped

    Most text editors insert a newline as the last character in a file.  A chomp is
    performed before the template is prepared to avoid extra newlines in the output
    when using sub templates. If you really need that newline, place an empty line
    at the end of your template

## More on Input Variables

If the variables to apply to the template completely change (note: variables
not values), then the aliasing setup during a `plex` call will not
reflect what you want.

However the `render` method call allows a hash ref containing values to be
used.  The hash is aliased to the `%fields` variable in the template.

```perl
    my $new_variables={name=>data};
    $template->render($new_variables);
```

However to use this data the template must be constructed to access the fields
directly:

```perl
    my $template='my name is $fields{name} and I am $fields{age}';
```

Note that the `%field` is aliased so any changes to it is reflected outside
the template

Interestingly the template can refer to the lexical aliases and the direct
fields at the same time. The lexical aliases only refer to the data provided at
preparation time, while the `%fields` refer to the latest data provided during
a `render` call:

```perl
    my $template='my name is $fields{name} and I am $age

    my $base_data={name=>"jimbo", age=>10};

    my $override_data={name=>"Eva"};

    my $template=plex $template, $base_data;

    my $string=$template->render($override_data);
    #string will be "my name is Eva and I am 10
```

As an example, this could be used to 'template a template' with global, slow
changing variables stored as the aliased variables, and the fast changing, per
render data being supplied as needed.

# SECURITY

This module uses `eval` to generate the code ref for rendering. This means
that your template, being perl code, is being executed. If you do not know what
is in your templates, then maybe this module isn't for you.

Aliasing means that the template has access to variables outside of it.
That's the whole point. So again if you don't know what your templates are
doing, then maybe this module isn't for you

# SEE ALSO

Yet another template module right? 

Do a search on CPAN for 'template' and make a cup of coffee.

# REPOSITORY and BUG REPORTING

Please report any bugs and feature requests on the repo page:
[GitHub](http://github.com/drclaw1394/perl-template-plex)

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2022 by Ruben Westerberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, or under the MIT license
