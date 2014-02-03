---
date: 2014-02-02
title: Unix standards and implementations. Unix portability
author: Alexandru Goia
tags: Unix, C, portable code
---

The purpose of this article is to present in a general way the Unix standards
and how can we write portable code on Unix systems, not only on Linux ones.

<!--more-->

In the Unix world at present, there are three important standards:

* the C language (ISO C standard) and the standard C library (`libc`), which
  are included in the POSIX standard
* the POSIX standard (*P*ortable *O*perating *S*ystem *I*nterface for Uni*x*),
  which has the last version from 2008
* the SUS standard (*S*ingle *U*nix *S*pecification), which includes as a
  subset the POSIX standard, with the last version from 2010 (SUSv4).

The POSIX standard consists of:

* POSIX.1: core services
* POSIX.1b: real-time extensions
* POSIX.1c: threads extensions
* POSIX.2: shell and utilities

We will be interested in this article only by POSIX.1 (last version:
POSIX.1-2008, or IEEE Std 1003.1-2008) from the whole POSIX standard.

As implementations of the standard, we can name the GNU/Linux-based operating
systems, the systems which descend from the BSD Unix version: FreeBSD, NetBSD,
OpenBSD, DragonflyBSD, the certified and commercial UNIX-es, based on
UNIX System V release 4 and, from case to case, with BSD elements: Oracle
Solaris (known previously as Sun Solaris), HP-UX and Tru64 UNIX (HP), AIX
(IBM), IRIX (SGI), Unixware and OpenServer (SCO), and also Mac OS X, which is
also officially certified as a UNIX system, based on FreeBSD elements and not
on UNIX System V.

The most "popular" Unix systems are at present Linux, FreeBSD, Solaris and Mac
OS X. With regards to the C language, all these operating systems (Linux 3.x,
FreeBSD >= 8.0, Mac OS X >= 10.6.8, Solaris >= 10) support the following LIB C
headers:

* `assert.h`: verify program assertion
* `complex.h`: complex arithmetic support
* `ctype.h`: character classification and mapping support
* `errno.h`: error codes
* `fenv.h`: floating-point environment
* `float.h`: floating-point constants and characteristics
* `inttypes.h`: integer type format conversion
* `iso646.h`: macros for assignment, relational, and unary operators
* `limits.h`: implementation constants
* `locale.h`: locale categories and related definitions
* `math.h`: mathematical functions and type declarations and constants
* `setjmp.h`: nonlocal `goto`
* `signal.h`: signals
* `stdarg.h`: variable argument lists
* `stdbool.h`: boolean type and values
* `stddef.h`: standard definitions
* `stdint.h`: integer types
* `stdio.h`: standard I/O library
* `stdlib.h`: utility functions
* `string.h`: string operations
* `tgmath.h`: type-generic math macros
* `time.h`: time and date
* `wchar.h`: extended multibyte and wide character support
* `wctype.h`: wide character classification and mapping support

They also support the following POSIX headers (in the C language):

* `aio.h`: asynchronous I/O
* `cpio.h`: cpio archive values
* `dirent.h`: directory entries
* `dlfcn.h`: dynamic linking
* `fcntl.h`: file control
* `fnmatch.h`: filename-matching types
* `glob.h`: pathname pattern-matching and generations
* `grp.h`: group file
* `iconv.h`: codeset conversion utility
* `langinfo.h`: language information constants
* `monetary.h`: monetary types and functions
* `netdb.h`: network database operations
* `nl_types.h`: message catalogs
* `poll.h`: `poll()` function
* `pthread.h`: threads
* `pwd.h`: password file
* `regex.h`: regular expressions
* `sched.h`: execution scheduling
* `semaphore.h`: semaphores
* `strings.h`: string operations
* `tar.h`: tar archive values
* `termios.h`: terminal I/O
* `unistd.h`: symbolic constants
* `wordexp.h`: word-expansion definitions
* `arpa/inet.h`: Internet definitions
* `net/if.h`: socket local interfaces
* `netinet/in.h`: Internet address family
* `netinet/tcp.h`: TCP definitions
* `sys/mman.h`: memory management declarations
* `sys/select.h`: `select()` function
* `sys/socket.h`: sockets interface
* `sys/stat.h`: file status
* `sys/statvfs.h`: file system information
* `sys/times.h`: process times
* `sys/types.h`: primitive system data types
* `sys/un.h`: UNIX domain socket definitions
* `sys/utsname.h`: system name
* `sys/wait.h`: process control
* `fmtmsg.h`: message display structures
* `ftw.h`: file tree walking
* `libgen.h`: pathname management functions
* `ndbm.h`: database operations (*exception: Linux*)
* `search.h`: search tables
* `syslog.h`: system error logging
* `utmpx.h`: user accounting database (*exception: FreeBSD*)
* `sys/ipc.h`: inter-processes communication
* `sys/msg.h`: XSI message queues
* `sys/resource.h`: resource operations
* `sys/sem.h`: XSI semaphores
* `sys/shm.h`: XSI shared memory
* `sys/time.h`: time types
* `sys/uio.h`: vector I/O operations
* `mqueue.h`: message queues (exception: Mac OS X)
* `spawn.h`: real-time spawn interface.

The SUS standard (the whole set of UNIX functions and constants) can be found
online for [SUSv2][susv2] (year 1997, naming UNIX 98), [SUSv3][susv3] (year
2001-2002, naming UNIX 03) and [SUSv4][susv4] (year 2010):

To write portable code which can be executed on any Unix systems we must know
the C headers (defined by LIBC and by POSIX) which are recognized by the Unix
systems. We can activate the operating system in order to use only POSIX.1
elements, or also SUSv1, SUSv2, SUSv3, or SUSv4 using the so-called "feature
test macros":

* `_POSIX_SOURCE` and `_POSIX_C_SOURCE`, to activate POSIX functionality
* `_XOPEN_SOURCE`, which activates SUSv1/2/3/4 functionality.

For older POSIX functionality we have to declare the following in our source
file:

``` cpp
#define _POSIX_SOURCE
#define _POSIX_C_SOURCE 1 /* for POSIX 1990 */
/* use 2 for POSIX C bindings 1003.2-1992 */
```

For POSIX 2008 functionality, we define:

``` cpp
#define _POSIX_SOURCE
#define _POSIX_C_SOURCE 200809L
```

Or, we can compile with:

    cc -D_POSIX_SOURCE -D_POSIX_C_SOURCE=200809L filename.c

If our code is written, or it will run on UNIX certified systems (hence on
systems who follow SUSv1, SUSv2, SUSv3, or SUSv4), we must define also
`_XOPEN_SOURCE`:

Thus, we would have to use

* for SUSv1:

``` cpp
#define _POSIX_SOURCE
#define _POSIX_C_SOURCE 2
#define _XOPEN_SOURCE
#define _XOPEN_SOURCE_EXTENDED 1
```

* for SUSv2:

``` cpp
#define _POSIX_SOURCE
#define _POSIX_C_SOURCE 199506L
#define _XOPEN_SOURCE 500
```

* for SUSv3:

``` cpp
#define _POSIX_SOURCE
#define _POSIX_C_SOURCE 200112L
#define _XOPEN_SOURCE 600
```

* for SUSv4:

``` cpp
#define _POSIX_SOURCE
#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 700
```

If we write code only for Linux platforms, we will use the feature test macro
`_GNU_SOURCE`, which will activate GNU LIBC functionality, which sometimes
isn't POSIX compatible. There is also the feature test macro `_SVID_SOURCE`
(to activate System V functionality) and `_BSD_SOURCE` (to activate BSD
functionality). One important note is that a UNIX system (which follows SUSvX)
can be activated to offer any SUSvX functionality.

This is the way we can write Unix portable code. Other methods to find out
more about the operating system on which we compile are:

* LIBC functions: `sysconf(3)`, `pathconf(3)`, `fpathconf(3)` -- functions
  which determine system constants
* `autoconf`, `automake` and `libtool`: utilities which determine at compile
  time, with scripts, what system and libc functions the operating system
  offers. (These will be part of the content of a following article.)

Happy Unix programming!

[susv2]: http://www.unix.org/version2/ "SUSv2"
[susv3]: http://www.unix.org/version3/ "SUSv3"
[susv4]: http://www.unix.org/version4/ "SUSv4"

