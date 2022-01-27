# NAME

Template::Plex - Templates with Perl and Lexical Aliasing

# SYNOPSIS

```perl
       use Template::Plex;

       my $base_data={name=>"James", age=>"12", fruit=>"banana"};

       #An inline template in a scalar
       my $template = '$name\'s age $age and favourite fruit is $fruit';

       #Prepare and construct a render function
       my $render=prepare_template($template,$base_data);

       #Render with the values aliased in $base_data
       $render->();            
       #James's age is 12 and favourite fruit is banana

       #Update the data, 
       $base_data->{qw<name,fruit>}=qw<John apple>;

       #Rendering again will use updated aliased values
       $render->();            
       #John's age is 12 and favourite fruit is apple


       ##Load template recursively from file and prepare

       my $render=slurp_template($path,$base_data);

       $render->();

```

# DESCRIPTION

A very small, very powerful templating mechanism. After all the template
language is perl itself. If you are looking for an 'embedded perl' template
module, this is NOT it. Instead of classes with render methods, a template when
prepared is simply a subroutine refernce which has aliased lexical access to
variables you provide

That means you can alter the variables outside of the call to the template and
the changes are direclty accessable the next time the template is renderd.

As perl is doing the heavy lifting in the syntax deparment, the actual code is
quite small. The documentaion is larger (significantly) in byte size. In that spirit, this module does no management on templates.

However as the result of preparing a template is sub reference it is very easy to memorize or include in your applicaiton

A summary of features:

- Perl is the template language
- Templates are compiled into subroutine for repeated execution
- Variables are aliased for speedy access
- Templates can inject other template from file

# MOTIATION

So many templating systems available, but none of them that I know of actually
use perl as the template language. There are lots of 'embedded perl' templating
modules, but that is a different beast.  Also I wanted to experiment using
lexical aliasing as it can have good performance benefits, and streamline to an
efficient functional API

# API

## Executing Templates

### `slurp_template`

```
    slurp_template $path, $hash_ref

    where
            $path is the path to a .tpl file 
            $hash_ref is a anonymouns hash with elements to alias
    
```

Opens a the file given by `$path` and reads the contents. If any `inject` statements are presents they are replaced with content from recursive loading templates specified.

The `$hash_ref` has all its keys used to create aliased aliased lexical variables in to the prepared tempate sub routine.

```perl
    eg
            my $hash={
                    name=>"bob",
                    age=>98
            };

            my $renderer-slurp_template "my_template.plex", $hash;


            #my_template.plex
            My name is $name and my age is $age
```

In this example the hash elements `{name}` and `{age}` are aliased so lexical variables `$name` and `$age` which are directly accessable to the template.

### `prepare_template`

```perl
    prepare_template 'template string', $hash_ref;


    eg
            my $hash={
                    name=>"bob",
                    age=>98
            };

            my $template='My name is $name and my age is $age';

            my $renderer-slurp_template $template, $hash;
```

Similar to `slurp_tempalte`, however, the template text is provided by a string literal or scalar.

## Template Only

# `inject`

```
    @{[inject($path)}]

    where $path is path to template file to inject
```

This special subroutine call is replaced with the contents of the template at `$path`. Once it is replaced, any subsequent instances are also processed recursively.

# TEMPLATE SYNTAX

Well, its just perl. Seriously. A template is a perl program with the two following constraints:

- 1. The program consists only of (powerful) syntax permissible in a double quoted string
- 2. The outermost double quote operators are ommited from the program/template

This is best illustrated by example.  The following  shows a valid (boring) template stored in a scalar:

```perl
    my $template = 'this is a $adj template';
```

The two rules are satisfied. Firstly the syntax is valid for a double quoted
string (the `$adj` is a scalar to be interpolated into the tempalte). Secondly
the outer double quotes for the string are omitted.

A template could also be stored in a file following the same two rules.

```
    How many colours are in the rainbow? If you said $count  you would be correct
```

Again, the syntax is that of a double quoted interpolation and the outer double quotes are
ommited.

In otherwords, template looks like plain text, but with double quoted added is valid perl code.

# THE POWER OF DOUBLE QUOTE INERPOLATION

Perl has the abiliby to interpolate just about anything into a string. The
following shows examples of valid perl syntax to get you salivating:

### Access to Scalars, Arrays and Hashes

```perl
    This template uses a $scalar and it will also

    access the array element $array->[$index]

    Accessing element $hash->{key} just for fun
```

## Executing Subroutine statements

To achieve this, a neat trick is to dereference an inline reference to an
annonynous array. The contents of the array is then the result of the
subroutine call. Sounds like alot but it is only a couple of braces:

```perl
    Calling the sub @{[ my_sub()} ]}
```

For comparison, this technique is only 1 more character to type than similar embedded perl
templates systems

```perl
    Calling the sub <% my_sub() %>
```

## Executing Multiplle Statements

The `do{}` construct executes a block, which can have any number of statements
and returns the last statement executed into the template

```perl
    Calling multiple statments @{[ do { my $a=1; $a++; ($a,-$a) } ]} in this template
```

## Other Examples

### Simple mapping (single statement)

```
    My shoppling list @{[ join "\n", map uc, @items]}
```

### Executing a BEGIN block

Again standard perl syntax for the win

```perl
    Template will call hi res time 
    The time is: @{[ time ]}
    @{[ BEGIN {
            use Time::HiRes qw<time>;
            }
    ]}
    
```

## MORE ON LEXICAL ALIASING

Any keys present in the hash when `prepare_template` or `slurp_template` is called are used to
construct lexical variables which are aliases to the hash elements of the same
key name. The hash itself is also aliased to a variable called `%fields` 

So for a `$base_data` hash like this:

```perl
    my $base_data={name=>"jimbo", age=>10};
```

The template can access the fields "name" and age like this:

```perl
    my $template='my name is $name an I am $age';
```

or like this:

```perl
    my $template='my name is $fields{name} and I am $fields{age}';
```

The first version uses the lexical variables skips the hash lookup, which gives
higher rendering rates.  The caveat is that all fields must exist at the time
the template is prepared.

To change the values and render the template the same `$base_data` variable
must be manipulated. ie

```
    $base_data->{name}="Tim";
    $render->();
```

This still performs no hash lookups in the rendering and is a very quick way of
rendering the changing data.

## NOT USING LEXICAL ALIASING 

If the data to apply to the template completely changes, it can be passed as a
hash ref to the render code reference.

```perl
    my $new_variable={name=>data};
    $render->($new_variable);
```

However to use this data the template must be constructed to access the fields
directly:

```perl
    my $template='my name is $fields{name} and I am $fields{age}';
```

## HYBRID ACCESS

This is interesting. The template can refer to the lexical aliases and the
direct fields at the same time. The lexical aliases only refer to the data
provided at preparation time, while the field refer to the latest data
provided:

```perl
    my $template='my name is $fields{name} and I am $age
    my $base_data={name=>"jimbo", age=>10};
    my $override_data={name=>"Eva"};

    my $render=prepare_template $template, $base_data;
    my $string=$render($override_data);
    #string will be "my name is Eva and I am 10
```

# SECURITY

This module uses `eval` to generate the code ref for rendering. This means
that your template, being perl code, is being executed. If you do not know what
is in your templates, then maybe this module isn't for you.

To mitigate the security risk, the rendering code refs should be generated  and
cached, so they are not needing to be run during normal execution. That will
provide faster rendering and also, prevent unknown templates from accidentally
being executed.

# SEE ALSO

Yet another template module right? 

Do a search on CPAN for 'template' and make a cup of coffee.

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2021 by Ruben Westerberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, or under the MIT license
