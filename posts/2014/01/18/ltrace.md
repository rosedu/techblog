---
date: 2014-01-18
title: Inspecting library calls for fun and profit
author: Mihai Maruseac
tags: trace, ltrace, strace, ptrace, debugging
---

Two years ago this blog had a series of articles on debugging tools. We have
presented tools like [Valgrind][valgrind-post] and [GDB][gdb-post] and we
stopped with an introduction to [strace][strace-post]. At the end of that
article we mentioned that there are other tools useful for debugging beyond
these three already mentioned. After two years of silence, the debugging
series is on with an article on `ltrace`.

Ask around developers and you'll see that the proportion of those knowing
about `ltrace` compared to those knowing how to use `strace` is at most the
same as the proportion of `strace` users among users knowing how to use `gdb`
and `valgrind`.

But how is `ltrace` different? Why is this an useful tool? This article will
try to shine some light on this while also providing comparisons with the
`strace` tool.

### Basic Example

The simples way to use both `ltrace` and `strace` is to append this tool in
front of the command you're tracing. We will illustrate here the [same example
used for `strace`][strace-post-simple-example]

    $ ltrace ls
    __libc_start_main(0x402c60, 1, 0x7fffa36d7038, 0x412bb0 <unfinished ...>
    strrchr("ls", '/')                               = nil
    setlocale(LC_ALL, "")                            = "en_US.UTF-8"
    bindtextdomain("coreutils", "/usr/share/locale") = "/usr/share/locale"
    textdomain("coreutils")                          = "coreutils"
    __cxa_atexit(0x40ace0, 0, 0, 0x736c6974756572)   = 0
    isatty(1)                                        = 1
    getenv("QUOTING_STYLE")                          = nil
    getenv("COLUMNS")                                = nil
    ioctl(1, 21523, 0x7fffa36d6bd0)                  = 0
    getenv("TABSIZE")                                = nil
    getopt_long(1, 0x7fffa36d7038, "abcdfghiklmnopqrstuvw:xABCDFGHI:"..., 0x61a5e0, -1)         = -1
    getenv("LS_BLOCK_SIZE")                          = nil
    ...
    opendir(".")                                     = 0x2789c30
    readdir(0x2789c30)                               = 0x2789c60
    readdir(0x2789c30)                               = 0x2789c78
    readdir(0x2789c30)                               = 0x2789c90
    strlen("a.out")                                  = 5
    malloc(6)                                        = 0x2791c70
    memcpy(0x2791c70, "a.out\0", 6)                  = 0x2791c70
    readdir(0x2789c30)                               = 0x2789cb0
    strlen("out.9373")                               = 8
    malloc(9)                                        = 0x2791c90
    memcpy(0x2791c90, "out.9373\0", 9)               = 0x2791c90
    ...
    closedir(0x2789c30)                              = 0
    free(0)                                          = <void>
    malloc(432)                                      = 0x2789c30
    _setjmp(0x61b640, 0x400000, 0x2785e50, 0x2789cc0)= 0
    __errno_location()                               = 0x7f95ad5916c0
    strcoll("out.9307", "1.c")                       = 23
    ...
    fwrite_unlocked("1.c", 1, 3, 0x3573db9400)       = 3
    ...
    fwrite_unlocked("out", 1, 3, 0x3573db9400)       = 3
    ...
    exit(0 <unfinished ...>
    __fpending(0x3573db9400, 0, 64, 0x3573db9eb0)    = 0
    fileno(0x3573db9400)                             = 1
    __freading(0x3573db9400, 0, 64, 0x3573db9eb0)    = 0
    __freading(0x3573db9400, 0, 2052, 0x3573db9eb0)  = 0
    fflush(0x3573db9400)                             = 0
    fclose(0x3573db9400)                             = 0
    __fpending(0x3573db91c0, 0, 0x3573dbaa00, 0xfbad000c)= 0
    fileno(0x3573db91c0)                             = 2
    __freading(0x3573db91c0, 0, 0x3573dbaa00, 0xfbad000c)= 0
    __freading(0x3573db91c0, 0, 4, 0xfbad000c)       = 0
    fflush(0x3573db91c0)                             = 0
    fclose(0x3573db91c0)                             = 0
    +++ exited (status 0) +++

Looking at the trace we see that the `ls` process starts by acknowledging the
current [locale][locale-wiki] after which several environment variables which
control the output are read (only a few of them shown, the others ellided by
`...`). Then [`opendir`][man-opendir] is called on `.` (since `ls` had no
other arguments) and each entry is read via [`readdir`][man-readdir] and then
copied into a vector of entries (after using `strdup` seen here as a triple of
`strlen`, `malloc` and `memcpy`). Next step is to sort all of these entries
according to the current locale ([`strcoll`][man-strcoll], the variable
`LC_COLLATE`). This allows sorting the filenames in alphabetical order. Then,
each filename is written on the `1` file descriptor (`stdout`) using the
non-blocking [`fwrite_unlocked`][man-fwrite_unlocked]. Last step is to call
`exit` and flush all open streams.

Right now you are more enlightened on what `ls` does than before reading this
part. Knowing the above information you can do things like changing the way
files are quoted (I retrieved the options by providing an invalid value and
looking on the `QUOTING_STYLE='-' ltrace ls` output to see what arguments are
tested for):

    $ ls a*
    a file  a.out

    $ QUOTING_STYLE="shell" ls a*
    'a file'  a.out

    $ QUOTING_STYLE="c" ls a*
    "a file"  "a.out"

The next question we are interested in is "*Can `ltrace` trace syscalls as
well?*". Luckily, the answer is *yes*, by using the `-S` flag:

    $ ltrace -S ls
    SYS_brk(0)                               = 0x1d4b000
    SYS_mmap(0, 4096, 3, 34)                 = 0x7f4d8b352000
    SYS_access("/etc/ld.so.preload", 04)     = -2
    SYS_open("/etc/ld.so.cache", 524288, 01) = 3
    SYS_fstat(3, 0x7fff9f3a4110)             = 0
    SYS_mmap(0, 0x246b0, 1, 2)               = 0x7f4d8b32d000
    ...

Contrast with the results of `strace`:

    $ strace ls
    execve("/usr/bin/ls", ["ls"], [/* 48 vars */]) = 0
    brk(0)                                  = 0x1190000
    mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fcf80794000
    access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
    open("/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
    fstat(3, {st_mode=S_IFREG|0644, st_size=149168, ...}) = 0
    mmap(NULL, 149168, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7fcf8076f000
    ...

Differences are easily seen. The main one is that `ltrace` prefixes each
syscall with `SYS_` and doesn't represent macros as macros but expands them
(so instead of `PROT_READ|PROT_WRITE` you have `3`). In fact, even the number
of arguments is different. For understandability reason, it is better to use
`strace` for tracing the system calls and `ltrace` for tracing the library
ones.


### Why Is `ltrace` Useful?

From the above section you have seen that we can use `ltrace` to understand
undocumented behavior of an application. For example the `QUOTING_STYLE` was
found neither in the [`ls`][man-ls] manual nor in the [`bash`][man-bash] one.

Another way `ltrace` is useful is when one of the libraries your application
depends on is faulty. Instead of trying to debug a full-scale application you
might want to isolate the culprit into a minimal application which exhibits
only the bad behaviour. For that, you can use `ltrace` in the same way we used
`strace` in [its own article][strace-post-how-is-this-useful] in the past.

### I Have Too Much Output

Like in the case of [`strace`][strace-post-too-much-output], `ltrace` produces
a long list of output lines and it is quite hard to find what you're looking
for or to understand what's happening while they are scrolling on the screen.

Just like `strace` we can save the output to a file, using `-o`:

    $ ltrace -o ltraceout ls
    $ wc -l ltraceout
    523 ltraceout
    $ head ltraceout
    __libc_start_main(0x402c60, 1, 0x7fffbc2e3348, 0x412bb0 <unfinished ...>
    strrchr("ls", '/')                              = nil
    setlocale(LC_ALL, "")                           = "en_US.UTF-8"
    bindtextdomain("coreutils", "/usr/share/locale")= "/usr/share/locale"
    textdomain("coreutils")                         = "coreutils"
    __cxa_atexit(0x40ace0, 0, 0, 0x736c6974756572)  = 0
    isatty(1)                                       = 1
    getenv("QUOTING_STYLE")                         = nil
    getenv("COLUMNS")                               = nil
    ioctl(1, 21523, 0x7fffbc2e2ee0)                 = 0

Like `strace`, we can also use `-e` to filter on specific calls.

In the following examples we would use the following C source file which
computes `41^41` and `42^42` both using the float `libmath` version and the
`libgmp` multi-precision integers one. We will use threads to compute `42^42`
and compute `41^41` in the `main` function with both arguments.

~~~ cpp
#include <math.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>

#include <gmp.h>

void *do_double_thread(void *data)
{
  double x = 42;
  x = pow(x, x);
}

void *do_mpz_thread(void *data)
{
  mpz_t x;

  mpz_init_set_ui(x, 42);
  mpz_pow_ui(x, x, 42);

  mpz_clear(x);
}

int main()
{
  pthread_t double_thread, mpz_thread;
  pthread_attr_t attr;

  double y = 41;
  mpz_t x;

  mpz_init_set_ui(x, 41);
  mpz_pow_ui(x, x, 41);

  mpz_clear(x);

  y = pow(y, y);

  /* initialize the attribute */
  if (pthread_attr_init(&attr) != 0) {
    perror("pthread_attr_init");
    pthread_exit(NULL);
  }

  /* set detached state */
  if (pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE) != 0) {
    perror("pthread_attr_setdetachstate");
    pthread_exit(NULL);
  }

  if (pthread_create(&double_thread, &attr, do_double_thread, NULL)) {
    perror("pthread_create");
    exit(EXIT_FAILURE);
  }

  if (pthread_create(&mpz_thread, &attr, do_mpz_thread, NULL)) {
    perror("pthread_create");
    exit(EXIT_FAILURE);
  }

  pthread_attr_destroy(&attr);

  if (pthread_join(double_thread, NULL))
    perror("pthread_join");

  if (pthread_join(mpz_thread, NULL))
    perror("pthread_join");

  return 0;
}
~~~

To compile, we have to link against `libmath`, `libpthread` and `libgmp`:

    $ gcc -lm -lpthread -lgmp test.c -o test

Running `ltrace` on the full output we have the following:

    $ ltrace ./test
    __libc_start_main(0x400aeb, 1, 0x7fff6afa8b78, 0x400c60 <unfinished ...>
    __gmpz_init_set_ui(0x7fff6afa8a30, 41, 0x7fff6afa8b88, 0x400c60)     = 1
    __gmpz_pow_ui(0x7fff6afa8a30, 0x7fff6afa8a30, 41, 0x7fff6afa8a30)    = 0
    __gmpz_clear(0x7fff6afa8a30, 0x6bb020, 0, 0x129c08be7ca69)           = 0
    pow(0x3573db8760, 0xffffffff, 0x4044800000000000, 0)                 = 0x4da9465e5d9d1629
    pthread_attr_init(0x7fff6afa8a40, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0
    pthread_attr_setdetachstate(0x7fff6afa8a40, 0, 0x7fefffffffffffff, 0)= 0
    pthread_create(0x7fff6afa8a80, 0x7fff6afa8a40, 0x400a60, 0)          = 0
    pthread_create(0x7fff6afa8a78, 0x7fff6afa8a40, 0x400aa8, 0)          = 0
    pthread_attr_destroy(0x7fff6afa8a40, 0x7f60ece77fb0, 0x7f60ece789d0, -1)= 0
    pthread_join(0x7f60ed679700, 0, 0x7f60ece789d0, -1)                  = 0
    pthread_join(0x7f60ece78700, 0, 0x7f60ed679700, 0x3574418290)        = 0
    +++ exited (status 0) +++

If we want to capture only the bignum operations we can use `-e` flag:

    $ ltrace -e '*gmpz*' ./test
    test->__gmpz_init_set_ui(0x7ffffb01f830, 41, 0x7ffffb01f988, 0x400c60)= 1
    test->__gmpz_pow_ui(0x7ffffb01f830, 0x7ffffb01f830, 41, 0x7ffffb01f830 <unfinished ...>
    libgmp.so.10->__gmpz_n_pow_ui(0x7ffffb01f830, 0xbf0010, 1, 41 <unfinished ...>
    libgmp.so.10->__gmpz_realloc(0x7ffffb01f830, 7, 42, 7)         = 0xbf0010
    <... __gmpz_n_pow_ui resumed> )                                  = 0
    <... __gmpz_pow_ui resumed> )                                    = 0
    test->__gmpz_clear(0x7ffffb01f830, 0xbf0020, 0, 0x129c08be7ca69) = 0
    +++ exited (status 0) +++

From this output we see that `__gmpz_pow_ui` from our code calls
`__gmpz_n_pow_ui` from `libgmp.so.10` which in turn calls `__gmpz_realloc` to
expand the space allocated to the number.

However, in some cases one library might call functions from another or you
might want to filter and keep only the calls done by your application.
Fortunately, we can still do that:

    $ ltrace -e '*gmpz*-@libgmp.so*' ./test
    test->__gmpz_init_set_ui(0x7fff45c5cd70, 41, 0x7fff45c5cec8, 0x400c60) = 1
    test->__gmpz_pow_ui(0x7fff45c5cd70, 0x7fff45c5cd70, 41, 0x7fff45c5cd70)= 0
    test->__gmpz_clear(0x7fff45c5cd70, 0xc02020, 0, 0x129c08be7ca69)       = 0
    +++ exited (status 0) +++

If you want to trace all calls _inside_ a library then it is better to use
`-x`.

    $ ltrace -x '@libgmp.so.*' ./test
    __libc_start_main(0x400aeb, 1, 0x7fff656660b8, 0x400c60 <unfinished ...>
    __gmpz_init_set_ui(0x7fff65665f70, 41, 0x7fff656660c8, 0x400c60 <unfinished ...>
    __gmpz_init_set_ui@libgmp.so.10(0x7fff65665f70, 41, 0x7fff656660c8, 0x400c60 <unfinished ...>
    __gmp_default_allocate@libgmp.so.10(8, 41, 0x7fff656660c8, 0x400c60)= 0x222a010
    <... __gmpz_init_set_ui resumed> )= 1
    <... __gmpz_init_set_ui resumed> )= 1
    __gmpz_pow_ui(0x7fff65665f70, 0x7fff65665f70, 41, 0x7fff65665f70 <unfinished ...>
    __gmpz_pow_ui@libgmp.so.10(0x7fff65665f70, 0x7fff65665f70, 41, 0x7fff65665f70 <unfinished ...>
    __gmpz_n_pow_ui@libgmp.so.10(0x7fff65665f70, 0x222a010, 1, 41 <unfinished ...>
    __gmpz_realloc@libgmp.so.10(0x7fff65665f70, 7, 42, 7 <unfinished ...>
    __gmp_default_reallocate@libgmp.so.10(0x222a010, 8, 56, 7)= 0x222a010
    <... __gmpz_realloc resumed> )= 0x222a010
    __gmpn_sqr@libgmp.so.10(0x222a010, 0x7fff65665e80, 2, 48 <unfinished ...>
    __gmpn_sqr_basecase@libgmp.so.10(0x222a010, 0x7fff65665e80, 2, 48)= 0x3562f3ea0787ecff
    <... __gmpn_sqr resumed> )= 0
    __gmpn_mul_1@libgmp.so.10(0x222a010, 0x222a010, 3, 0x129c08be7ca69)= 0xca32f2e
    <... __gmpz_n_pow_ui resumed> )= 0
    <... __gmpz_pow_ui resumed> )= 0
    <... __gmpz_pow_ui resumed> )= 0
    __gmpz_clear(0x7fff65665f70, 0x222a020, 0, 0x129c08be7ca69 <unfinished ...>
    __gmpz_clear@libgmp.so.10(0x7fff65665f70, 0x222a020, 0, 0x129c08be7ca69 <unfinished ...>
    __gmp_default_free@libgmp.so.10(0x222a010, 56, 0, 0x129c08be7ca69)= 0
    <... __gmpz_clear resumed> )= 0
    <... __gmpz_clear resumed> )= 0
    pow(0x3573db8760, 0xffffffff, 0x4044800000000000, 0)= 0x4da9465e5d9d1629
    pthread_attr_init(0x7fff65665f80, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0
    pthread_attr_setdetachstate(0x7fff65665f80, 0, 0x7fefffffffffffff, 0)= 0
    pthread_create(0x7fff65665fc0, 0x7fff65665f80, 0x400a60, 0)= 0
    pthread_create(0x7fff65665fb8, 0x7fff65665f80, 0x400aa8, 0)= 0
    pthread_attr_destroy(0x7fff65665f80, 0x7f3164bc1fb0, 0x7f3164bc29d0, -1)= 0
    pthread_join(0x7f31653c3700, 0, 0x7f3164bc29d0, -1)= 0
    pthread_join(0x7f3164bc2700, 0, 0x7f31653c3700, 0x3574418290)= 0
    _fini@libgmp.so.10(0x358cc761f0, 0, 0xffffffff, 0)= 0x358ca5edc4
    +++ exited (status 0) +++

To catch only the calls to the specific library use `-L` which will make
`ltrace` not trace anything from the `MAIN` library:

    $ ltrace -L -x '@libgmp.so.*' ./test
    __gmpz_init_set_ui@libgmp.so.10(0x7fffbf630930, 41, 0x7fffbf630a88, 0x400c60 <unfinished ...>
    __gmp_default_allocate@libgmp.so.10(8, 41, 0x7fffbf630a88, 0x400c60)= 0x17b5010
    <... __gmpz_init_set_ui resumed> )= 1
    __gmpz_pow_ui@libgmp.so.10(0x7fffbf630930, 0x7fffbf630930, 41, 0x7fffbf630930 <unfinished ...>
    __gmpz_n_pow_ui@libgmp.so.10(0x7fffbf630930, 0x17b5010, 1, 41 <unfinished ...>
    __gmpz_realloc@libgmp.so.10(0x7fffbf630930, 7, 42, 7 <unfinished ...>
    __gmp_default_reallocate@libgmp.so.10(0x17b5010, 8, 56, 7)= 0x17b5010
    <... __gmpz_realloc resumed> )= 0x17b5010
    __gmpn_sqr@libgmp.so.10(0x17b5010, 0x7fffbf630840, 2, 48 <unfinished ...>
    __gmpn_sqr_basecase@libgmp.so.10(0x17b5010, 0x7fffbf630840, 2, 48)= 0x3562f3ea0787ecff
    <... __gmpn_sqr resumed> )= 0
    __gmpn_mul_1@libgmp.so.10(0x17b5010, 0x17b5010, 3, 0x129c08be7ca69)= 0xca32f2e
    <... __gmpz_n_pow_ui resumed> )= 0
    <... __gmpz_pow_ui resumed> )= 0
    __gmpz_clear@libgmp.so.10(0x7fffbf630930, 0x17b5020, 0, 0x129c08be7ca69 <unfinished ...>
    __gmp_default_free@libgmp.so.10(0x17b5010, 56, 0, 0x129c08be7ca69)= 0
    <... __gmpz_clear resumed> )= 0
    _fini@libgmp.so.10(0x358cc761f0, 0, 0xffffffff, 0)= 0x358ca5edc4
    +++ exited (status 0) +++

### Attaching To Other Processes

Like in [`strace`][strace-post-but-i-started-the-process] case, we can use
`-p` to attach to running processes:

    $ ./test &
    [1] 26026

    $ ltrace -p 26026
    __gmpz_clear(0x7fff1fa3bb50, 1, 0, 0x1b9b000)= 0
    pow(0x7f2c3dca8000, 0x49ff000, 0x4044800000000000, -1)= 0x4da9465e5d9d1629
    pthread_attr_init(0x7fff1fa3bb60, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0
    pthread_attr_setdetachstate(0x7fff1fa3bb60, 0, 0x7fefffffffffffff, 0)= 0
    pthread_create(0x7fff1fa3bba8, 0x7fff1fa3bb60, 0x400a60, 0)= 0
    pthread_create(0x7fff1fa3bba0, 0x7fff1fa3bb60, 0x400aa8, 0)= 0
    pthread_attr_destroy(0x7fff1fa3bb60, 0x7f2c42073fb0, 0x7f2c420749d0, -1)= 0
    pthread_join(0x7f2c42875700, 0, 0x7f2c420749d0, -1)= 0
    pthread_join(0x7f2c42074700, 0, 0x7f2c42875700, 0x3574418290)= 0
    +++ exited (status 0) +++
    [1]+  Done                    ./test

In fact, just as `strace`, we can use multiple `-p` arguments to attach to
multiple processes simultaneously:

    $ ./test & ./test &
    [1] 26149
    [2] 26150

    $ ltrace -p 26149 -p 26150
    __gmpz_clear(0x7fff52a4fed0, 1, 0, 0xa2c000)= 0
    pow(0x7f85fb6f0000, 0x49ff000, 0x4044800000000000, -1)= 0x4da9465e5d9d1629
    pthread_attr_init(0x7fff52a4fee0, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0
    pthread_attr_setdetachstate(0x7fff52a4fee0, 0, 0x7fefffffffffffff, 0)= 0
    pthread_create(0x7fff52a4ff28, 0x7fff52a4fee0, 0x400a60, 0)= 0
    pthread_create(0x7fff52a4ff20, 0x7fff52a4fee0, 0x400aa8, 0)= 0
    pthread_attr_destroy(0x7fff52a4fee0, 0x7f85ffabbfb0, 0x7f85ffabc9d0, -1)= 0
    pthread_join(0x7f86002bd700, 0, 0x7f85ffabc9d0, -1)= 0
    pthread_join(0x7f85ffabc700, 0, 0x7f86002bd700, 0x3574418290)= 0
    +++ exited (status 0) +++
    __gmpz_clear(0x7fff4cbac6e0, 1, 0, 0x1207000)= 0
    pow(0x7fbf03640000, 0x49ff000, 0x4044800000000000, -1)= 0x4da9465e5d9d1629
    pthread_attr_init(0x7fff4cbac6f0, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0
    pthread_attr_setdetachstate(0x7fff4cbac6f0, 0, 0x7fefffffffffffff, 0)= 0
    pthread_create(0x7fff4cbac738, 0x7fff4cbac6f0, 0x400a60, 0)= 0
    pthread_create(0x7fff4cbac730, 0x7fff4cbac6f0, 0x400aa8, 0)= 0
    pthread_attr_destroy(0x7fff4cbac6f0, 0x7fbf07a0bfb0, 0x7fbf07a0c9d0, -1)= 0
    pthread_join(0x7fbf0820d700, 0, 0x7fbf07a0c9d0, -1)= 0
    pthread_join(0x7fbf07a0c700, 0, 0x7fbf0820d700, 0x3574418290)= 0
    +++ exited (status 0) +++
    [1]-  Done                    ./test
    [2]+  Done                    ./test

Though, this case is useful only when debugging multiple programs which need
to communicate between themselves, it is nice to know that this is possible.

### Tracing the Threads and Children of a Process

The `strace` tools allows attaching to subprocesses of a process using `-f`.
Also, you can use `-ff` with a `-o` to get the output of each thread in a
separate file.

However, `ltrace` knows only the `-f` option. Lines from different processes
are prefixed with the `PID` of that process.

    $ ltrace -f ./test
    [pid 26192] __libc_start_main(0x400aeb, 1, 0x7fffc406b9c8, 0x400c60 <unfinished ...>
    [pid 26192] __gmpz_init_set_ui(0x7fffc406b880, 41, 0x7fffc406b9d8, 0x400c60)= 1
    [pid 26192] __gmpz_pow_ui(0x7fffc406b880, 0x7fffc406b880, 41, 0x7fffc406b880)= 0
    [pid 26192] __gmpz_clear(0x7fffc406b880, 0x1b21020, 0, 0x129c08be7ca69)= 0
    [pid 26192] pow(0x3573db8760, 0xffffffff, 0x4044800000000000, 0)= 0x4da9465e5d9d1629
    [pid 26192] pthread_attr_init(0x7fffc406b890, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0
    [pid 26192] pthread_attr_setdetachstate(0x7fffc406b890, 0, 0x7fefffffffffffff, 0)           = 0
    [pid 26192] pthread_create(0x7fffc406b8d0, 0x7fffc406b890, 0x400a60, 0)= 0
    [pid 26193] pow(0, 0, 0x4045000000000000, -1 <unfinished ...>
    [pid 26192] pthread_create(0x7fffc406b8c8, 0x7fffc406b890, 0x400aa8, 0 <unfinished ...>
    [pid 26193] <... pow resumed> )= 0x4e1646505f35a847
    [pid 26193] +++ exited (status 0) +++
    [pid 26192] <... pthread_create resumed> )= 0
    [pid 26192] pthread_attr_destroy(0x7fffc406b890, 0x7fc1a1041fb0, 0x7fc1a10429d0, -1)= 0
    [pid 26192] pthread_join(0x7fc1a1843700, 0, 0x7fc1a10429d0, -1)= 0
    [pid 26192] pthread_join(0x7fc1a1042700, 0, 0x7fc1a1843700, 0x3574418290 <unfinished ...>
    [pid 26194] __gmpz_init_set_ui(0x7fc1a1041f00, 42, 0x59a85877c49edc2b, -1)= 1
    [pid 26194] __gmpz_pow_ui(0x7fc1a1041f00, 0x7fc1a1041f00, 42, 0x7fc1a1041f00)= 0
    [pid 26194] __gmpz_clear(0x7fc1a1041f00, 0x7fc19c0008c0, 0, 42)= 0
    [pid 26192] <... pthread_join resumed> )= 0
    [pid 26194] +++ exited (status 0) +++
    [pid 26192] +++ exited (status 0) +++

Thus, if you want to filter only a single child you have to resort to text
filter utilities like `grep`.

### Profiling

One nice thing about `strace` is that you can use the `-c` flag to get a table
with all syscalls used in a program, the time needed to execute them and the
count of error results. However, `ltrace` lacks this option but it can be
simulated by using the other timing options and text filters.

Both `strace` and `ltrace` allow you to get timestamps around any call by
using `-r`, `-t`, `-tt` or `-ttt`:

`-r` shows a relative timestamp since program startup

    $ ltrace -r ./test
      0.000000 __libc_start_main(0x400aeb, 1, 0x7fff2a51a328, 0x400c60 <unfinished ...>
      0.000418 __gmpz_init_set_ui(0x7fff2a51a1e0, 41, 0x7fff2a51a338, 0x400c60)= 1
      0.000296 __gmpz_pow_ui(0x7fff2a51a1e0, 0x7fff2a51a1e0, 41, 0x7fff2a51a1e0)= 0
      0.000166 __gmpz_clear(0x7fff2a51a1e0, 0x1f66020, 0, 0x129c08be7ca69)= 0
      0.000137 pow(0x3573db8760, 0xffffffff, 0x4044800000000000, 0)= 0x4da9465e5d9d1629
      0.000168 pthread_attr_init(0x7fff2a51a1f0, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0
      0.000147 pthread_attr_setdetachstate(0x7fff2a51a1f0, 0, 0x7fefffffffffffff, 0)= 0
      0.000216 pthread_create(0x7fff2a51a230, 0x7fff2a51a1f0, 0x400a60, 0)= 0
      0.000409 pthread_create(0x7fff2a51a228, 0x7fff2a51a1f0, 0x400aa8, 0)= 0
      0.000474 pthread_attr_destroy(0x7fff2a51a1f0, 0x7f25016c5fb0, 0x7f25016c69d0, -1)= 0
      0.000250 pthread_join(0x7f2501ec7700, 0, 0x7f25016c69d0, -1)= 0
      0.000257 pthread_join(0x7f25016c6700, 0, 0x7f2501ec7700, 0x3574418290)= 0
      0.000735 +++ exited (status 0) +++

`-t` shows the time of day when the call was made

    $ ltrace -t ./test
    14:50:42 __libc_start_main(0x400aeb, 1, 0x7fff84229b38, 0x400c60 <unfinished ...>
    14:50:42 __gmpz_init_set_ui(0x7fff842299f0, 41, 0x7fff84229b48, 0x400c60)= 1
    14:50:42 __gmpz_pow_ui(0x7fff842299f0, 0x7fff842299f0, 41, 0x7fff842299f0)= 0
    14:50:42 __gmpz_clear(0x7fff842299f0, 0x1d02020, 0, 0x129c08be7ca69)= 0
    14:50:42 pow(0x3573db8760, 0xffffffff, 0x4044800000000000, 0)= 0x4da9465e5d9d1629
    14:50:42 pthread_attr_init(0x7fff84229a00, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0
    14:50:42 pthread_attr_setdetachstate(0x7fff84229a00, 0, 0x7fefffffffffffff, 0)= 0
    14:50:42 pthread_create(0x7fff84229a40, 0x7fff84229a00, 0x400a60, 0)= 0
    14:50:42 pthread_create(0x7fff84229a38, 0x7fff84229a00, 0x400aa8, 0)= 0
    14:50:42 pthread_attr_destroy(0x7fff84229a00, 0x7f48e7ec0fb0, 0x7f48e7ec19d0, -1)= 0
    14:50:42 pthread_join(0x7f48e86c2700, 0, 0x7f48e7ec19d0, -1)= 0
    14:50:42 pthread_join(0x7f48e7ec1700, 0, 0x7f48e86c2700, 0x3574418290)= 0
    14:50:42 +++ exited (status 0) +++

`-tt` also displays the microseconds

    $ ltrace -tt ./test
    14:50:45.465708 __libc_start_main(0x400aeb, 1, 0x7fff83373968, 0x400c60 <unfinished ...>
    14:50:45.465942 __gmpz_init_set_ui(0x7fff83373820, 41, 0x7fff83373978, 0x400c60)= 1
    14:50:45.466216 __gmpz_pow_ui(0x7fff83373820, 0x7fff83373820, 41, 0x7fff83373820)= 0
    14:50:45.466400 __gmpz_clear(0x7fff83373820, 0x192e020, 0, 0x129c08be7ca69)= 0
    14:50:45.466584 pow(0x3573db8760, 0xffffffff, 0x4044800000000000, 0)= 0x4da9465e5d9d1629
    14:50:45.466764 pthread_attr_init(0x7fff83373830, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0
    14:50:45.466932 pthread_attr_setdetachstate(0x7fff83373830, 0, 0x7fefffffffffffff, 0)= 0
    14:50:45.467101 pthread_create(0x7fff83373870, 0x7fff83373830, 0x400a60, 0)= 0
    14:50:45.467417 pthread_create(0x7fff83373868, 0x7fff83373830, 0x400aa8, 0)= 0
    14:50:45.468024 pthread_attr_destroy(0x7fff83373830, 0x7fc1e7ebdfb0, 0x7fc1e7ebe9d0, -1)= 0
    14:50:45.468253 pthread_join(0x7fc1e86bf700, 0, 0x7fc1e7ebe9d0, -1)= 0
    14:50:45.468480 pthread_join(0x7fc1e7ebe700, 0, 0x7fc1e86bf700, 0x3574418290)= 0
    14:50:45.469108 +++ exited (status 0) +++

`-ttt` displays microseconds as above but use the seconds till epoch instead
of the actual time.

    $ ltrace -ttt ./test
    1390074648.833755 __libc_start_main(0x400aeb, 1, 0x7fff5b1c8e28, 0x400c60 <unfinished ...>
    1390074648.833981 __gmpz_init_set_ui(0x7fff5b1c8ce0, 41, 0x7fff5b1c8e38, 0x400c60)= 1
    1390074648.834289 __gmpz_pow_ui(0x7fff5b1c8ce0, 0x7fff5b1c8ce0, 41, 0x7fff5b1c8ce0)= 0
    1390074648.834481 __gmpz_clear(0x7fff5b1c8ce0, 0x1e7c020, 0, 0x129c08be7ca69)= 0
    1390074648.834678 pow(0x3573db8760, 0xffffffff, 0x4044800000000000, 0)= 0x4da9465e5d9d1629
    1390074648.834858 pthread_attr_init(0x7fff5b1c8cf0, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0
    1390074648.835033 pthread_attr_setdetachstate(0x7fff5b1c8cf0, 0, 0x7fefffffffffffff, 0)= 0
    1390074648.835242 pthread_create(0x7fff5b1c8d30, 0x7fff5b1c8cf0, 0x400a60, 0)= 0
    1390074648.835935 pthread_create(0x7fff5b1c8d28, 0x7fff5b1c8cf0, 0x400aa8, 0)= 0
    1390074648.836327 pthread_attr_destroy(0x7fff5b1c8cf0, 0x7fc3da214fb0, 0x7fc3da2159d0, -1)= 0
    1390074648.837980 pthread_join(0x7fc3daa16700, 0, 0x7fc3da2159d0, -1)= 0
    1390074648.838436 pthread_join(0x7fc3da215700, 0, 0x7fc3daa16700, 0x3574418290)= 0
    1390074648.839230 +++ exited (status 0) +++

Also, both tools allow you to time each individual call by using `-T`:

    $ ltrace -T ./test
    __libc_start_main(0x400aeb, 1, 0x7fffc4512768, 0x400c60 <unfinished ...>
    __gmpz_init_set_ui(0x7fffc4512620, 41, 0x7fffc4512778, 0x400c60)    = 1 <0.000290>
    __gmpz_pow_ui(0x7fffc4512620, 0x7fffc4512620, 41, 0x7fffc4512620)   = 0 <0.000167>
    __gmpz_clear(0x7fffc4512620, 0x21cc020, 0, 0x129c08be7ca69)         = 0 <0.000142>
    pow(0x3573db8760, 0xffffffff, 0x4044800000000000, 0)                = 0x4da9465e5d9d1629 <0.000209>
    pthread_attr_init(0x7fffc4512630, 213, 0x7fefffffffffffff, 0x7fffffffffffffff)= 0 <0.000130>
    pthread_attr_setdetachstate(0x7fffc4512630, 0, 0x7fefffffffffffff, 0)= 0 <0.000139>
    pthread_create(0x7fffc4512670, 0x7fffc4512630, 0x400a60, 0)         = 0 <0.000304>
    pthread_create(0x7fffc4512668, 0x7fffc4512630, 0x400aa8, 0)         = 0 <0.000421>
    pthread_attr_destroy(0x7fffc4512630, 0x7f09988a1fb0, 0x7f09988a29d0, -1)= 0 <0.000266>
    pthread_join(0x7f09990a3700, 0, 0x7f09988a29d0, -1)                 = 0 <0.000181>
    pthread_join(0x7f09988a2700, 0, 0x7f09990a3700, 0x3574418290)       = 0 <0.000467>
    +++ exited (status 0) +++

Though you can profile applications using `ltrace` and `strace`, a much better
tool to use is `perf` which will be presented on a future article.

### Blaming it on the Culprit Line

It is possible to use `ltrace` and `strace` to show you the line numbers of
the caller by using the `-i` flag to get the value of the `EIP` register and
then using [`addr2line`][man-addr2line] to get the exact line (compile with
`-g`):

    $ ltrace -i ./test
    ...
    [0x400bfb] pthread_create(0x7fff0804c998, 0x7fff0804c960, 0x400aa8, 0)= 0
    [0x400c1f] pthread_attr_destroy(0x7fff0804c960, 0x7f708d112fb0, 0x7f708d1139d0, -1)= 0
    ...
    [0xffffffffffffffff] +++ exited (status 0) +++

    $ addr2line -iCse ./test 0x400c1f
    test.c:63

This is useful when your code makes repeated calls to the same subset of
functions but only a few of them cause problems.

### Nicer Output

One interesting feature of `ltrace` is that you can get a nice call tree when
functions from one library call other traced functions. For that, you would
use the `-n` option.

    $ ltrace -n 3 -L -x '@libgmp.so.*' ./test
    __gmpz_init_set_ui@libgmp.so.10(0x7fff7bb2e810, 41, 0x7fff7bb2e968, 0x400c60 <unfinished ...>
       __gmp_default_allocate@libgmp.so.10(8, 41, 0x7fff7bb2e968, 0x400c60)= 0x12b2010
    <... __gmpz_init_set_ui resumed> )= 1
    __gmpz_pow_ui@libgmp.so.10(0x7fff7bb2e810, 0x7fff7bb2e810, 41, 0x7fff7bb2e810 <unfinished ...>
       __gmpz_n_pow_ui@libgmp.so.10(0x7fff7bb2e810, 0x12b2010, 1, 41 <unfinished ...>
          __gmpz_realloc@libgmp.so.10(0x7fff7bb2e810, 7, 42, 7 <unfinished ...>
             __gmp_default_reallocate@libgmp.so.10(0x12b2010, 8, 56, 7)= 0x12b2010
          <... __gmpz_realloc resumed> )= 0x12b2010
          __gmpn_sqr@libgmp.so.10(0x12b2010, 0x7fff7bb2e720, 2, 48 <unfinished ...>
             __gmpn_sqr_basecase@libgmp.so.10(0x12b2010, 0x7fff7bb2e720, 2, 48)= 0x3562f3ea0787ecff
          <... __gmpn_sqr resumed> )= 0
          __gmpn_mul_1@libgmp.so.10(0x12b2010, 0x12b2010, 3, 0x129c08be7ca69)= 0xca32f2e
       <... __gmpz_n_pow_ui resumed> )= 0
    <... __gmpz_pow_ui resumed> )= 0
    __gmpz_clear@libgmp.so.10(0x7fff7bb2e810, 0x12b2020, 0, 0x129c08be7ca69 <unfinished ...>
       __gmp_default_free@libgmp.so.10(0x12b2010, 56, 0, 0x129c08be7ca69)= 0
    <... __gmpz_clear resumed> )= 0
    _fini@libgmp.so.10(0x358cc761f0, 0, 0xffffffff, 0)= 0x358ca5edc4
    +++ exited (status 0) +++

If `ltrace` was compiled with `libunwind` support then you can also use the
`-w` option to get a backtrace for a specific number of frames around each
traced call. If not (like in our case) one can still use the `-i` way or the
`-n`, depending on what he is interested in.

### Conclusions

Though very rarely used, `ltrace` is a nice program to have in your toolbox.
It will greatly help you in those hard to debug cases caused by undocumented
behaviors of third-party libraries.

Notice that `ltrace` has most of the bugs of `strace`:

1. a program with `setuid` doesn't have `euid` privileges while being traced
1. a program is slow while being traced
1. the `-i` support is weak

Next article on this series will present tools for profiling applications and
solving timing bugs.

[valgrind-post]: http://techblog.rosedu.org/valgrind-introduction.html "Valgrind introduction"
[gdb-post]: http://techblog.rosedu.org/gdb-a-basic-workflow.html "GDB - basic workflow"
[strace-post]: http://techblog.rosedu.org/tracing-processes-for-fun-and-profit.html "Tracing Processes for Fun and Profit"
[strace-post-simple-example]: http://techblog.rosedu.org/tracing-processes-for-fun-and-profit.html#simple-example "Tracing Processes for Fun and Profit"
[strace-post-how-is-this-useful]: http://techblog.rosedu.org/tracing-processes-for-fun-and-profit.html#how-is-this-useful "Tracing Processes for Fun and Profit"
[strace-post-too-much-output]: http://techblog.rosedu.org/tracing-processes-for-fun-and-profit.html#too-much-output "Tracing Processes for Fun and Profit"
[strace-post-but-i-started-the-process]: http://techblog.rosedu.org/tracing-processes-for-fun-and-profit.html#but-i-started-the-process.. "Tracing Processes for Fun and Profit"

[locale-wiki]: http://en.wikipedia.org/wiki/Locale "Locale (computing)"

[man-opendir]: http://linuxmanpages.com/man3/opendir.3.php "opendir - open a directory"
[man-readdir]: http://linuxmanpages.com/man2/readdir.2.php "readdir - read directory entry"
[man-strcoll]: http://linuxmanpages.com/man3/strcoll.3.php "strcoll - compare two strings using the current locale"
[man-fwrite_unlocked]: http://linuxmanpages.com/man3/fwrite_unlocked.3.php "fwrite_unlocked - non-locking stdio function"
[man-ls]: http://linuxmanpages.com/man1/ls.1.php "ls - list directory contents"
[man-bash]: http://linuxmanpages.com/man1/bash.1.php "bash - GNU Bourne-Again SHell"
[man-addr2line]: http://linuxmanpages.com/man1/addr2line.1.php "addr2line - convert addresses into file names and line numbers"
