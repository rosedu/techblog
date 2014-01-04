---
date: 2012-08-18
title: Tracing processes for fun and profit
author: Mihai Maruseac
tags: trace, strace, ptrace
---

After talking about [Valgrind][valgrind-post] and [GDB][gdb-post], it is time
to present another useful program for developers and system administrators.

Often-overlooked, though common on most of the GNU/Linux systems,
`strace` is a tool which traces system calls done by a process during its
execution. However, this is only a simplistic point of view: using `strace`,
you can filter by a group of system calls, you can profile your application
from the syscalls point of view and you can trace signals sent to a process.

### Simple Example

The simplest possible use is of the form `strace command`. For example:

    $ strace ls
    execve("/bin/ls", ["ls"], [/* 39 vars */]) = 0
    brk(0)                                  = 0x92c000
    ...
    access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
    ...
    open("/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
    fstat(3, {st_mode=S_IFREG|0644, st_size=130982, ...}) = 0
    mmap(NULL, 130982, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7fc4e95c2000
    close(3)                                = 0
    ...
    open("/lib/x86_64-linux-gnu/librt.so.1", O_RDONLY|O_CLOEXEC) = 3
    read(3, "\177ELF\2\1\1\0\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0\340!\0\0\0\0\0\0"..., 832) = 832
    ...
    openat(AT_FDCWD, ".", O_RDONLY|O_NONBLOCK|O_DIRECTORY|O_CLOEXEC) = 3
    getdents(3, /* 25 entries */, 32768)    = 880
    getdents(3, /* 0 entries */, 32768)     = 0
    close(3)                                = 0
    ...
    write(1, "1.c git"..., 1221.c gitignore....
    ) = 122
    ...
    exit_group(0)                           = ?

In the above trace we have removed some of the lines to keep the output within
reasonable limits. We have kept some relevant outputs, though.

From the above output we can observe how a process is started (first group) or
ended (last group), how libraries and system options are read (second, third
and fourth section), how directory entries are read (fifth section) and how
the output is written to the output (sixth section).

As you can see, each line presents a syscall, giving information about all
parameters and the return value of the call.

### How Is This Useful?

Only by looking at the output lines, can we quickly find out why our process
doesn’t behave as expected or what it does behind the scenes. Let us see
some examples.

First, consider a binary which takes too long to finish. Using `strace` we get
this as the last few lines:

    read(3, "\333\310'\16\\\363<\244u\324", 4096) = 10
    read(3, 

We see that the application stopped while trying to read data from the third
file descriptor. Looking backwards we find:

    open("/dev/random", O_RDONLY)           = 3

Using these clues, we can construct a new source file which will compile into
an application which has the exact same bug and nothing more:

~~~ cpp
#include <stdio.h>
#include <stdlib.h>

#define SIZE 1000

int main ()
{
        char a[SIZE];
        FILE *f = fopen("/dev/random", "r");
        fgets(a, SIZE, f);
        return 0;
}
~~~

Of course, the building of a new application is not always needed. In our
case, we see that we are reading from `dev/random`. Knowing that this requires
entropy sources to generate the random stream, we understand why the process
stopped. Changing the file to `dev/urandom` solves the bug for our toy
application, therefore it must solve it for the original one as well. Or, we
could generate more entropy to increase the speed of the application.

For the second example, let's consider the problem of finding which
configuration files are read when launching an application. This can be used
to debug a faulty `vim` setting, to see what `*rc` files are read when
launching `bash`, etc. In our case, we want to see the order in which `git`
reads its configuration files to see what files are to be ignored from the
repository (we have 4 options: global `.gitignore`, `.gitignore` in
root folder or in a subdirectory and `.git/info/exclude`):

    $strace git status
    ...
    access(".git/info/exclude", R_OK)       = 0
    open(".git/info/exclude", O_RDONLY)     = 3
    ...
    access("/home/mihai/.gitignore", R_OK)  = 0
    open("/home/mihai/.gitignore", O_RDONLY) = 3
    ...
    open(".gitignore", O_RDONLY)            = 4
    ...
    open("tag/.gitignore", O_RDONLY)        = -1 ENOENT (No such file or directory)
    ...
    open("_includes/.gitignore", O_RDONLY)  = -1 ENOENT (No such file or directory)
    ...
    open("_layouts/.gitignore", O_RDONLY)   = -1 ENOENT (No such file or directory)
    ...

Observer the multiple lines with error `-ENOENT`. Those files don't exist in
the filesystem. The fact that we can quickly observe this makes `strace` a
perfect tool for finding out why a specific command doesn't start anymore.

### Too Much Output

A problem with the simplest case is that we get too much output and scanning
through it takes a long time while also being error prone.

Fortunately, once we know what to look for, we can select only a group of
system calls to be traced.

    $ strace -e openat,getdents ls
    openat(AT_FDCWD, ".", O_RDONLY|O_NONBLOCK|O_DIRECTORY|O_CLOEXEC) = 3
    getdents(3, /* 9 entries */, 32768)     = 256
    getdents(3, /* 0 entries */, 32768)     = 0

Here, we have traced only the `openat` and `getdents` system calls of the `ls`
command.

Moreover, we can save the trace to a file for further analyzing.

    $ strace -o trace ls
    $ wc -l trace
    117 trace
    $ head trace -n 3
    execve("/bin/ls", ["ls"], [/* 39 vars */]) = 0
    brk(0)                                  = 0xced000
    access("/etc/ld.so.nohwcap", F_OK)      = -1 ENOENT (No such file or directory)

Combining these two options lets you use the output of `strace` as input to
other tools like `sed`, `awk`, `grep`, etc. This way, you can quickly
determine what went wrong in your application.

### But I Have Started The Process..

Let's consider another scenario. You have started a process and it is taking
too much time to finish. You want to find out what it is doing right now.
Restarting the process is not an option. Luckily, `strace` allows attaching to
a running process:

    $ strace -p 5545
    rt_sigprocmask(SIG_BLOCK, [CHLD], [], 8) = 0
    rt_sigaction(SIGCHLD, NULL, {SIG_DFL, [], 0}, 8) = 0
    rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
    nanosleep({5, 0},

The last argument is the process id of the faulty process.

### Could I Sniff Private Data This Way?

This quickly raises a concern: couldn't an attacker use `strace` over an
existing `ssh` connection in order to make a Man In The Middle attack?

Actually, no. If the programmer behind `ssh` used the `prctl` system call
disabling `PR_SET_DUMPABLE` (the capability to create crash dumps and to be
traced), then only the superuser could trace the process.

In fact, some systems have gone a step further. Starting 2010, there is a Yama
Linux Security Module. This includes a protection for ptrace. Having `1` in
the `/proc/sys/kernel/yama/ptrace_scope` associated procfs file means that
tracing is only possible only for children of the tracing process.

### What About Subprocesses?

It is possible to trace subprocesses of an application by using the `-f` or
`-ff` flag (the second one is used in conjuction with `-o` and creates one
output file per each subprocess).

    $ strace -f ./a.out 
    ...
    clone(Process 6187 attached
    child_stack=0, flags=CLONE_CHILD_CLEARTID|CLONE_CHILD_SETTID|SIGCHLD, child_tidptr=0x7f9de09ee9d0) = 6187
    [pid  6186] wait4(6187, Process 6186 suspended
     <unfinished ...>
    [pid  6187] rt_sigprocmask(SIG_BLOCK, [CHLD], [], 8) = 0
    [pid  6187] rt_sigaction(SIGCHLD, NULL, {SIG_DFL, [], 0}, 8) = 0
    [pid  6187] rt_sigprocmask(SIG_SETMASK, [], NULL, 8) = 0
    [pid  6187] nanosleep({1, 0}, 0x7fff306a3cf0) = 0
    [pid  6187] exit_group(0)               = ?
    Process 6186 resumed
    Process 6187 detached
    <... wait4 resumed> [{WIFEXITED(s) && WEXITSTATUS(s) == 0}], 0, NULL) =
    6187
    --- SIGCHLD (Child exited) @ 0 (0) ---
    exit_group(0)                           = ?

When tracing multiple processes, the PID of the process making a system call is
written on the respective line. The tracing of a child starts as soon as it's
PID is returned to the parent (as a result of the `clone` system call).

### Profiling With `strace`

Another thing that `strace` can do is help in profiling the application,
considering the number of system calls. This could be useful, for example, to
optimize the I/O calls done by the application.

    $ strace -c firefox
    % time     seconds  usecs/call     calls    errors syscall
    ------ ----------- ----------- --------- --------- ----------------
     99.50    0.012001        1091        11           readahead
      0.31    0.000037           0      1456       972 recvfrom
      0.19    0.000023           0       963           poll
      0.00    0.000000           0       123           read
      0.00    0.000000           0       134        33 open
      0.00    0.000000           0       107           close
      0.00    0.000000           0         8         3 stat
      0.00    0.000000           0        87           fstat
      0.00    0.000000           0        16           lstat
      0.00    0.000000           0         8           lseek
      0.00    0.000000           0       189           mmap
      0.00    0.000000           0       148           mprotect
      0.00    0.000000           0        20           munmap
      0.00    0.000000           0         4           brk
      0.00    0.000000           0        17           rt_sigaction
      0.00    0.000000           0         1           rt_sigprocmask
      ....    ........           .       ...           ................
    ------ ----------- ----------- --------- --------- ----------------
    100.00    0.012061                  3900      1079 total

### But I Don't Want To Be Traced..

In the end, let's consider the case of an application which should be designed
as untraceable as possible.

We already know how to prevent attaching from the outside of the process. If
we want to also deny root tracing and starting the process under `strace` then
we need to take some extra steps.

We know that each application can be under a single tracer. Thus, the obvious
solution is to create a dummy tracer.

A better solution is to inspect whether the process is traced and act accordingly
(exit forcibly, display dummy messages, etc.). To do this, you can either use
the `ptrace` system call on top of which `strace` is implemented or use the
`proc/[pid]/status` file, looking for `TracerPid`.

### Conclusions

The `strace` program is a good tool to have in your toolbox. Knowing how to use
it will greatly improve your debugging experience.

However, using `strace` has some disadvantages as well. The traced process
runs slower and each system call is done at least twice. You can also get a
different behaviour while running a process under `strace`: either because
some timing bugs will manifest, because some timeouts are reached or because
someone has taken measures that the process cannot be properly traced.

In the end, remember that debugging doesn't stop at [GDB][gdb-post] and/or
[Valgrind][valgrind-post]. Beside `strace`, there is also `ltrace` for
library calls and `perf` for profiling. These two tools will be presented
in further articles.

[valgrind-post]: http://techblog.rosedu.org/valgrind-introduction.html "Valgrind introduction"
[gdb-post]: http://techblog.rosedu.org/gdb-a-basic-workflow.html "GDB - basic workflow"
