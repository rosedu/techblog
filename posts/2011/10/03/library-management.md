---
date: 2011-10-03
title: Linking, Loading and Library Management under Linux
author: Răzvan Deaconescu
tags: library, dynamic linker, dynamic loader, ldconfig
---

This article aims to shed some light on the topic of library management
with insight on the linker and loader. The `ldconfig` command, for
example, is heavily used in Linux, though unknown to some of users.

A library is a collection of object files "meshed" together in another
file. Its benefit is avoiding "reimplementing the wheel". Once one
has implemented a given set of functionalities, he/she may store those in a
library file; this file is distributed to others and used in various
software projects. Libraries are heavily used in all modern operating
systems; the greater part of packages in Linux distributions are
library packages. One can barely imagine being able to do any kind of
development without the presence of the C Standard Library on the local
system.

### Linking and Loading

A library is said to be "linked" together with other library files or
object files into an executable. The executable integrates all required
components from library files, avoiding the need of implementing these
components from scratch.

Linking is thus the process where external references in each module
(object file) are resolved; that is, undefined functions are now looked
in other linked modules or library files and their code is used in the
executable. The linker is the application responsible for resolving and
integrating functions in the end executable file.

With respect to the phase when linking occurs, we differentiate between
three types of linking:

1. static linking
2. load-time dynamic linking
3. run-time dynamic linking

The above nomenclature is specific to MSDN ([load-time dynamic
linking][load-time-linking] and [run-time dynamic
linking][run-time-linking]) but it's a good depiction of any system using
dynamic linking.

When using static linking, required library function code is inserted
into the executable at link-time. Link-time refers to the moment when
the linker process (`ld`) is invoked (typically wrapped by the `gcc`
command). The result is an executable that comprises all required code to
create a process.

When using dynamic linking, the linker process does not integrate code
from the library. It simply creates stubs in the executable code stating
what library file should be looked for that function. The actual
"linking", that is the "integration" of code in the executable, is done
later.

Depending on the "later" part of dynamic linking, we differentiate
between two types of linking. Load-time is when a process is created from an
executable; the loader is responsible for "transforming" an executable
into a process (actually, it's not a transformation, but an
instantiation). Run-time is the time while the process is running (using memory
space, running code on the CPU etc.).

For load-time dynamic linking, the linking is done at load-time. That
is, when running the executable (`./myexec`) and when the process is
created, code from the library is mapped into memory and then referred
to by the newly created process. For run-time dynamic linking, a
specialized API allows the developer to load the library code into memory
and, on demand, use specific functions.

### Library types

Modern OSes such as Windows, Linux, Mac OS X and other Unices use two
types of libraries, strongly related to the types of linking shown
above: *static libraries* and *dynamic libraries*. Static libraries are
used in conjunction with static linking, while dynamic libraries with
load-time/run-time dynamic linking.

Static libraries use the `.a` extension on Unix and `.lib` on Windows.
Each time some modules are linked against a library file, static linking
is enabled and code for functions used is copied into the executable
file.

    ar rc libtest.a module1.o module2.o
    gcc -o myexec exec.o -L. -l test

Dynamic libraries are called shared-object library on Unix and use the
`.so` extension on Unix. On Windows, they are called dynamic-link
libraries and use the `.dll` extensions.  If a shared-object library is
linked against a module, only references to the library are filled, no
actual code is copied; that step is done later on (either at load-time
or run-time).

In order to use a shared-object library for load-time linking, one would
simply pass it as an argument to the linker:

    gcc -share -fPIC -o libtest.so module1.o module2.o
    gcc -o myexec exec.o -L. -l test
    LD_LIBRARY_PATH=. ./myexec

When the loader creates a new process (`LD_LIBRARY_PATH=. ./myexec`),
the library (`libtest.so`) is mapped into memory and necessary function
code is accessed.

The use of run-time linking requires a specialized API for loading
needed function code while the process is running: [dlopen &
friends][man-dlopen]. A sample is shown below:

~~~ cpp
    double (*cosine)(double);

    handle = dlopen ("libm.so", RTLD_LAZY);
    cosine = dlsym(handle, "cos");
    printf ("%f\n", (*cosine)(2.0));
~~~

Unlike static and load-time dynamic linking, run-time dynamic linking doesn't
require the presence of a library argument to the link command (that is `-L.
-ltest`).

Advantages of a certain type of library (static or dynamic) are
disadvantages for the other one and vice versa.

Static library-generated executables have increased portability. All
code is inserted into the executable such that, moving it on a different
platform doesn't require the presence of that library. These executables
tend to be faster as no additional overhead is implied during load-time
or run-time.

Dynamic library-generated executables have two main advantages: they are
smaller in size and library files have a smaller memory footprint. The
first advantage is due to not copying function code at link time: only
references are added to the executable without additional code. The
second advantage is stated in the Unix name for dynamic libraries:
shared-object libraries. A library may be mapped in memory and all
processes that use the library would use the same code. Thus, 50
processes that use the C standard library would require a single
instance of the library to be mapped in memory.

### Library Management

When discussing about library management, we are talking about dynamic
libraries. This is due to the fact that, when using the library code
(either at load-time or run-time), the loader needs to know where to
find the requested libraries.

The Linux loader is called `ld-linux.so`. As stated in the [man
page][man-ld-linux.so]: "The programs ld.so and ld-linux.so find and
load the shared libraries needed by a program, prepare the program to
run, and then run it." The loader needs to lookup shared libraries in
order to run the program and instantiate a process.

Bear in mind that the `-L.` option passed to GCC when doing linking is
only used at link-time. It's used to locate the library at link-time,
not at load-time or run-time.

In order to configure the loader to lookup libraries for dynamic linking
in a given folder (for example, the current folder -- `.`), there are two
main options: using the `LD_LIBRARY_PATH` environment variable or the
`ldconfig` command.

The `LD_LIBRARY_PATH` variable is a list of colon delimited folders
where libraries are searched. It must be set when the loader is invoked
-- that is, when running the executable:

    export LD_LIBRARY_PATH=.
    ./myexec

Using the `LD_LIBRARY_PATH` variable is excellent for testing. It does
however pose two disadvantages: it does not allow persistent
configuration and it may suffer from [security vulnerabilities similar
to the PATH environment variable][path-dot].

The configuration approach is the use of the `ldconfig` command.
`ldconfig` is used to populate the library list cache file
`/etc/ld.so.cache`. The cache file is read by the loader to search for
libraries. On Debian-based systems, every time you install a library,
`ldconfig` is run to populate the cache file.

In order to incorporate a new folder in the library search path, one may
resort to a persistent configuration or a temporary one. For a temporary
run, simply pass the new folder to `ldconfig`:

    razvan@einherjar:~/code$ /sbin/ldconfig -p | grep libtest
    razvan@einherjar:~/code$ sudo /sbin/ldconfig /home/razvan/code/
    razvan@einherjar:~/code$ /sbin/ldconfig -p | grep libtest
    	libtest.so (libc6,x86-64) => /home/razvan/code/libtest.so

For a persistent, configuration, one would need to edit the
configuration file and/or folder for `ldconfig`, namely
`/etc/ld.so.conf` and `/etc/ld.so.conf.d/`. Simply add a new folder in
the configuration file and run `ldconfig`.

When using [dlopen & friends][man-dlopen], the same kind of
configurations may be used: `LD_LIBRARY_PATH`, temporary use of
`ldconfig` and persistent use of `/etc/ld.so.conf`.

### Conclusion and Further Info

Extensive information about the actions used by the loader to use
dynamic libraries are found in man pages: [ld-linux.so][man-ld-linux.so],
[ldconfig][man-ldconfig] and [dlopen & friends][man-dlopen].

[John R. Levine's "Linkers & Loaders"][linkers-and-loaders] is an
extensive depiction of linkers, loaders, libraries and the load process.

Proper knowledge of library management on a Linux based system relies on
good understanding of the linking and loading processes and library
types. Make sure you understand the advantages and disadvantages of each
approach and choose the one most suitable to your specific needs.

[load-time-linking]: http://msdn.microsoft.com/en-us/library/windows/desktop/ms684184(v=vs.85).aspx "Load-Time Dyamic Linking"
[run-time-linking]: http://msdn.microsoft.com/en-us/library/windows/desktop/ms685090(v=vs.85).aspx "Run-Time Dynamic Linking"
[man-dlopen]: http://linux.die.net/man/3/dlopen "dlopen(3) - Linux man page"
[man-ld-linux.so]: http://linux.die.net/man/8/ld-linux "ld-linux(8): dynamic linker/loader - Linux man page"
[man-ldconfig]: http://linux.die.net/man/8/ldconfig "ldconfig(8) - Linux man page"
[path-dot]: http://www.unix.com/unix-dummies-questions-answers/22806-why-bad-idea-insert-dot-path.html "Why is is a Bad Idea to Insert . (Dot) to PATH?"
[linkers-and-loaders]: http://books.google.com/books?id=Id9cYsIdjIwC "John R. Levine – Linkers & Loaders"
