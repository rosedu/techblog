---
date: 2014-03-08
title: Unix portability. Autoconf, Automake, Libtool
postTitle: XYZ
author: Alexandru Goia
tags: Unix, C, portable code, autoconf, automake, libtool
---

The purpose of this article is to generally present the utilities
[Autoconf][l1], [Automake][l2] and [Libtool][l3], which ease very much the
process of installation from sources of software packages or libraries, from
the point of view of users. It is assumed that the user uses any
Unix/Unix-like system, and the purpose of the developer, who chooses to use
these GNU tools, is to make the installation, on the user's system, as easy
as possible.

<!--more-->

If you are a serious Unix/Linux user, for sure you have been in the situation
of compiling a program or a library from sources. Then, you called
`./configure; make; make install` and you got an executable or a library.  In
this article, we change the point of view, assuming that we are the software's
developers and not the users, and our purpose is to understand in principle
how can we generate the `configure` script and the other additional files,

This article aims to explain _le raison d'etre_ of these very useful tools
([Autoconf][l1], [Automake][l2], [Libtool][l3]) and to present generic
configuration files, in the case of a simple program and the case of a simple
library -- thus, the base syntax for these GNU tools with the aim of creating
an easy install experience for the users.


### The Theory

Autoconf is a software tool useful in the process of compilation from sources
of a software package. At running time, it generates shell scripts which will
run on the user's system, independently of Autoconf version installed there
(thus there is no need that the user should install this on his system too).
These shell scripts will be run without manual interventions on any Unix/Posix
system. Thus, Autoconf makes easier the porting of source programs on various
Unix/Posix systems by determining the characteristics of the user's system on
which the compilation will take place just before this.

For each software package on which we run it, Autoconf generates a
configuration script from a template file, named `configure.ac` or
`configure.in`, which lists the options of the user's system, options that
the software package needs or uses.

It is being said, like Unix, that those who do not understand Autoconf are
destined to reinvent it; Autoconf doesn't make easier the life of the
developer -- which is supposed to be a mature one --, but it makes easy the
installation experience of the software, on the Unix/Unix-like systems of the
users, which are -- at least a priori -- various.

So, Autoconf solves the problem of determining the pieces of information about
the system needed for compilation, right before it. It is only the first part
of a larger problem which is the 'perfect' compilation on the user's system,
in other words, the development of portable software. Here enters the GNU
Build System, which continues and completes what Autoconf started, by another
two GNU tools: Automake and Libtool.

The `make` tool (GNU make, gmake, etc.) is present on every Unix/Unix-like
system. Automake allows developers to describe in a file named `Makefile.am`
the build specifications, with a syntax simpler and richer than that of a
regular `Makefile`.  From the file `Makefile.am`, after running Automake
(`automake`), a file named `Makefile.in` will be generated, which in turn will
be used by the `configure` script to generate on the user's system the classic
file `Makefile`. Automake is very useful in the situation of software packages
with multiple subdirectories or with multiple sources, but even for simple
programs the reached portability is a gain.

Sometimes, we don't want to generate only executables, we want to also
generate libraries, in order to let them be further used by other developers.
We want to generate shared (dynamic) libraries, and do this in a portable way.
This is the task of the Libtool tool. One of the most used features of Libtool
is the coexistence of multiple versions of a library, so the user may install
or upgrade the library, without destroying the binary compatibility. Libtool
is used by default by Automake, when we want to generate dynamic libraries,
and there is no need to know its syntax.

These GNU tools are based on the macro-preprocessor GNU M4, but in this
article we will not talk about it.

### The Practice

A `configure.ac` file has the following structure:

``` configure
autoconf requirements
AC_INIT(package, version, [bug-report-email], [tarname], [url])
information on the package
checks for programs
checks for libraries
checks for header files
checks for types
checks for structures
checks for compiler characteristics
checks for library functions
checks for system services
AC_CONFIG_FILES([file...])
AC_OUTPUT
```

For example, for a simple project, `configure.ac`/`configure.in` can look like
this (comments inline for each directive):

``` configure
dnl Comments start with dnl
dnl This file will be processed with autoconf command, in order to
dnl generate the configure script

AC_INIT([hello], [1.0])
dnl Do not put spaces between AC_* / AM_* and the open paranthesis!
dnl AC_* : declarations for Autoconf
dnl AM_* : declarations for Automake

AM_INIT_AUTOMAKE([-Wall -Werrror foreign])
dnl for Automake, in order to create Makefile.in
dnl -Wall -Werror request Automake to activate warnings
dnl and to report them as errors (Automake warnings, not compiler
dnl warnings).

dnl If in a configure.in file there is an AM_* directive then
dnl Autoconf will automatically call Automake.

dnl foreign specifies the program does not adhere to
dnl the GNU standard: there are not ChangeLog, AUTHORS, NEWS and
dnl README files.

dnl We determine the standardized name of the machine
AC_CANONICAL_HOST
dnl for Linux on Intel 32-bit this is i686-pc-linux-gnu

AC_LANG_C
dnl or AC_LANG([C])
dnl specifies the C language as the programming language
dnl or AC_LANG([C++]) or AC_LANG_CPLUSPLUS for C++ language

AC_PROG_CC
dnl verifies the existence of the C compiler
AC_PROG_CXX
dnl verifies the existence of the C++ compiler
dnl insert it if the sources are written in the C++ language

AC_PROG_MAKE_SET
dnl verifies the existence of make program

AC_HEADER_STDC
dnl verifies the existence of standard C files

AC_CHECK_HEADERS([stdio.h])
dnl verifies the existence of header file stdio.h

AC_CONFIG_HEADERS([config.h])
dnl the configure script will generate at runtime the config.h file
dnl which will contain useful #define directives for the program.

dnl config.h can be big enough, because every feature tested on
dnl the user's system is added as a #define in config.h

AC_CONFIG_FILES([
   Makefile
   src/Makefile
])
dnl AC_CONFIG_FILES declares the list of files that will be
dnl generated from their templates with .in extension

AC_OUTPUT
dnl the ending line, which produces a sequence of commands
dnl in the configure script, a sequence that will generate
dnl the registered files from AC_CONFIG_HEADERS and 
dnl AC_CONFIG_FILES
```

Of course, the `configure.in` file can be much more complex, with many `AC_*`
and `AM_*` lines.  For this, we recommend the Autoconf manual.

We should also have `Makefile.am` files in every subdirectory in the source
tree. For example, for a tree with few source files (`hello` program with
sources: `main.c` and `functions.c`):

``` makefile
# src/Makefile.am
bin_PROGRAMS = hello
hello_SOURCES = main.c functions.c
```

If the sources of the program contain an `./include/` directory which has
header files then `Makefile.am` file from that directory must also contain
this line:

``` makefile
# include/Makefile.am
include_HEADERS=header1.h header2.h header3.h ... headerN.h
```

In the `Makefile.am` from the root directory we must have the following line:

``` makefile
SUBDIRS = doc src
```

or

``` makefile
SUBDIRS = src
```

`SUBDIRS` is a special variable which lists all directories in which `make`
will enter, before processing the current directory.

In the case of a simple library, the `Makefile.am` from the respective
directory will look like this:

``` makefile
# lib/Makefile.am
lib_LTLIBRARIES = libaa.la
libaa_la_SOURCES = library-aa.c
```

We will run the command `libtoolize`, after which two new files will be
created: `ltconfig` and `ltmain.sh`.

For `configure.in` and `Makefile.am`, we will run the commands `aclocal`,
`autoconf`, and, then, `automake`.

Also, the source code, which must be portable, must "fold" on these tools.

### Examples

1. This examples checks if `ncurses` is installed and saves the name of the
   terminal inside the `s` variable (if `ncurses` is installed then the name
   can be obtained by running `termname`, otherwise a constant value of `TERM`
   is used):

``` configure
#include "config.h"
...
#ifdef HAVE_NCURSES
strcpy(s, termname());
#else
strcpy(s, getenv("TERM"));
#endif // HAVE_NCURSES
```

2. This example checks and includes the proper header for string functions, if
   there is one:

``` configure
#include "config.h"
...
#ifdef HAVE_STRING_H
#include <string.h>
#else
#ifdef HAVE_STRINGS_H
#include <strings.h>
#endif
#endif
```

### Bibliography. Conclusions

For more informations, we recommend the free online book [GNU Autoconf,
Automake and Libtool][l4], and also [Using GNU Autotools][l5], from [the page
of Alexandre Duret-Lutz][l6].

After this article, we wish that the young Unix/Unix-like/Linux programmers
are aware of the existence of these tools, and have them in mind when they
will have to develop open-source programs which are intended to be portable
across all Unix systems.

[l1]: http://www.gnu.org/software/autoconf/manual/index.html "autoconf"
[l2]: http://www.gnu.org/software/automake/manual/index.html "automake"
[l3]: http://www.gnu.org/software/libtool/manual/index.html "libtool"
[l4]: http://www.sourceware.org/autobook "GNU Autoconf, Automake and Libtool"
[l5]: https://www.lrde.epita.fr/~adl/dl/autotools.pdf "Using GNU Autotools"
[l6]: https://www.lrde.epita.fr/~adl/autotools.html "Autotools"
