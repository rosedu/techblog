---
layout: post
date: 2012-05-08
title: "GNU Make"
tags: [make, Makefile, makefile]
author: Mihai Tiriplica
---

In working with large projects it is necessary to compile from multiple
sources. Since this is quite difficult, different tools have been developed to
make this task easier. One such tool is GNU Make and the associated executable
is  `make`. Make solves compilation from multiple sources problem using the
dependency relationships between them, described in a special file usually called
`Makefile`.

### Syntax

The file which describes the dependency relationships between project’s
sources. It should be named `Makefile` or `makefile` and has the following
syntax:

	target: dependency_list
	<tab>command

Usually, the target’s name matches the name of the resulted file, except only
those which are `.PHONY` targets, called virtual targets (they do not generate
a specific file). List dependencies include dependencies that are required for
target execution. Usually, there are files from which the target will be
built. A common mistake is that spaces are used instead of `TAB`. This will
result in an error message when running make. An example Makefile is:

	exec:
		gcc foo.c bar.c main.c -o exec

This is not the best way we can use make because it doesn’t describe any
dependencies, so every time we run make it will run `gcc foo.c bar.c main.c -o
exec`, even if there are no modified sources. Better use is the following
example:

	exec: foo.c bar.c main.c
		gcc foo.c bar.c main.c -o exec

In this case the target `exec` will run only if a source has changed. Neither
this case takes full advantage of the facilities make offers, because
modifying a single source leads to compiling all the existing sources. An
ideal Makefile describes the lowest level possible dependencies. In our case
it is the object file:

	exec: foo.o bar.o main.o
		gcc foo.o bar.o main.o -o exec
	foo.o: foo.c
		gcc -c foo.c -o foo.o
	bar.o: bar.c
		gcc -c bar.c -o bar.o
	main.o: main.c
		gcc -c main.c -o main.o

###  How it works

A particular target is executed by running `make target`. If there is no
argument, it will execute the first target described. To execute a target all
of his dependencies must be satisfied. For our example, `exec` target is
executed only after `foo.o`, `bar.o`, `main.o`, which are conditioned by
`foo.c`, `bar.c`, `main.c`, are obtained.

### Variables

In Makefile files we can declare variables to replace commonly used sequences
or which are changed frequently. The variables’ values are obtained using the
character `$`: `$(variable_name)`. For the example above, let’s suppose that
one of the source files uses functions from `math.h`. We will declare a
variable that is meant to specify that for linking:

	LDFLAGS=-lm
	exec: foo.o bar.o main.o
		gcc $(LDFLAGS) foo.o bar.o main.o -o exec
	foo.o: foo.c
		gcc -c foo.c -o foo.o
	bar.o: bar.c
		gcc -c bar.c -o bar.o
	main.o: main.c
		gcc -c main.c -o main.o

Make offers several predefined variables, of which the most important are:
* `$@` - target’s name
* `$^` - dependecies list
* `$<` - the first dependencie

The Makefile above can be written in a more simple way:

	CC=gcc
	LDFLAGS=-lm
	exec: ana.o are.o mere.o
		$(CC) $(LDFLAGS) $^ -o $@
	%.o: %.c
		$(CC) -c $< -o $@

Variables in a Makefile can also come from the environment where `make` is
running. While running, make sees each environment variable as a local
variable with the same name and the same value. Thus, assigning a value for
`LDFLAGS` variable in the example above can cause changes to any compile
command. To convert a local variable in an environment variable in order to
use it in other Makefile files we use the `export` directive:

	export variable

Inverse transformation is done using `unexport`:

	unexport variable

### .PHONY target

If we want a target to be marked permanently as out of date we will use the
`.PHONY` target. Let's consider that there is a pack target that creates an
archive which contains the project’s sources. If there is one source named
`pack` and it does not change, the command associated with this target will not
be executed. For this we use `.PHONY`. Also, by convention all Makefile files
contain a `.PHONY` target called `clean`  used to delete the files obtained from
compiling or running the program.

	.PHONY: pack
	pack:
		zip -r project.zip *
	clean:
		rm *.o *.zip exec

### Implicit Rules

Make allows us to use a simplified syntax. For example we don’t always have to
write a command for some targets. This is called an implicit rule:

	ana.o: ana.c

Another implicit rule is that when running the command `make source.c`, the
file source.c will be compiled even if there is no Makefile. Implicit rules
use the environment variables. Thus, the example considered by us is
equivalent to:

	ana.o: ana.c
		$(CC) -c $(LDFLAGS) ana.c -o ana.o

Because implicit rules use environment variables, it is easy to modify their
behavior by a simple change of the variables’ values.

### Final touches

In many cases, the first target in a Makefile is a target that compiles all of
the sources. It is very useful because we don’t have to specify a target every
time we are running make.

Adding these changes to our example we get a complete Makefile:

	CC=gcc
	LDFLAGS=-lm

	all: exec

	exec: ana.o are.o mere.o
		$(CC) $(LDFLAGS) $^ -o $@

	foo.o: foo.c
		gcc -c foo.c -o foo.o
	bar.o: bar.c
		gcc -c bar.c -o bar.o
	main.o: main.c
		gcc -c main.c -o main.o

	.PHONY: clean
		rm -rf *.o exec
