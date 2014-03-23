---
date: 2014-03-23
title: Daemonizing Processes - Part 1
author: Matei Oprea
tags: C, daemon, fork, setsid, nohup, disown
---

A special category of processes in Linux is that formed by **daemon**
processes.

<!--more-->

### What is a daemon ?

A daemon is a program that runs as a background process, forever, without
being directly affected by any user. Let's run a command to see examples of
some daemons.

We need to run a command which will tell us what processes are started by the
`init` process (they must have a `PPID` of 1):

``` bash
ps -ef | awk '$3 == 1'
```

The trimmed result will be the following: 

``` bash
$ ps -ef | awk '$3 == 1'
root       367     1  0 Mar08 ?        00:00:00 upstart-udev-bridge --daemon
root       398     1  0 Mar08 ?        00:00:00 /sbin/udevd --daemon
syslog     521     1  0 Mar08 ?        00:00:03 rsyslogd -c5
102        525     1  0 Mar08 ?        00:00:15 dbus-daemon --system --fork --activation=upstart
avahi      816     1  0 Mar08 ?        00:00:00 avahi-daemon: running [matei-Satellite-C660.local]
```

In Linux, the parent process of a daemon is often the `init` process. To
create a daemon, we need to `fork()` a child process and then exit (after
that the process will be an _orphan process_), causing `init` to adopt the
it as a child. A daemon is often started at boot time having the task of
handling network requests or hardware activity. 

### Let's code a Daemon

In this article we will show how one can write a simple daemon process. First,
we will show the long path of using `fork()` and `setsid()`.

First step (see [this FAQ][1] for reference) is to `fork` and `exit` such that
the process is no longer a process leader:

``` c
/*
 * Fork the parent process
 */
pid = fork();
/* On failure, -1 is returned in the parent
 * No child process is created
 */
if (pid < 0) {
    perror("fork");
    exit(EXIT_FAILURE);
}

/* We are now killing the parent process
 * parent exits -> init "takes the lead"
 */
if (pid > 0)
    exit(EXIT_SUCCESS);
```

Because we want to have a completely new controlling terminal we need to make
our process be a session leader using `setsid()`. The above `fork` was needed
just to allow this to succeed:

``` c
sessionID=setsid();
if (sessionID < 0) {
    perror("setsid");
    exit(EXIT_FAILURE);
}
```

Next step is to `fork()/exit()` again. Since the session leader is now dead
our process can never get access to a controlling terminal:

``` c
pid = fork();
if (pid < 0) {
    perror("fork");
    exit(EXIT_FAILURE);
}

if (pid > 0)
    exit(EXIT_SUCCESS);
```

Now, we will switch to the directory which contains the files needed for this
daemon to run (for example in case of `dovecot` we would switch to
`/run/dovectot` which contains the sockets for different mail queues). Or, we
could switch to `/` (like `apache2` and `sshd` do for example) if we don't
want to change to a specific directory. Anyway, it is essential to change the
current running directory to prevent cases where if the program was started
in a `cwd` from a different partition that partition could no longer be
`umount`ed.

``` c
change_dir = chdir("/");
if (change_dir < 0 ) {
    perror("chdir");
    exit(EXIT_FAILURE);
}
```

Though the following steps are optional, it is better to do them too to ensure
a reproducible behaviour of our executable, no matter what state the system
was when we started it.

Because a child process inherits file descriptors and file descriptors from
his parent, we need to close them. We use `sysconf` to get the maximum number
of opened file descriptors in order to close all of them and prevent leaks.
Then, we will set `umask` to 0 to gain complete permissions over anything we
write.

``` c
maxfd = sysconf(_SC_OPEN_MAX);
if (maxfd < 0) {
    perror("sysconf _SC_OPEN_MAX");
    exit(EXIT_FAILURE);
}

for (fd = 0; fd < maxfd; fd++)
    /* note that we ignore return code here */
    close(fd);

umask(0);
```

Now we should reopen the 3 standard file descriptors. We can point them to
`/dev/null` or to specific log files. Here we open all of them to `/dev/null`:

``` c
fd = open("/dev/null", 0);
if (fd < 0) {
    perror("open /dev/null");
    exit(EXIT_FAILURE);
}

status = dup(fd, 0);
if (status < 0) {
    perror("dup 0");
    exit(EXIT_FAILURE);
}
status = dup(fd, 1);
if (status < 0) {
    perror("dup 1");
    exit(EXIT_FAILURE);
}
status = dup(fd, 2);
if (status < 0) {
    perror("dup 2");
    exit(EXIT_FAILURE);
}
```

We now, have a fully working daemon, created by us. However, certain
considerations must be taken:

1. First, if our code is to be launched by `inetd` then only the `chdir` and
   `umask` steps are useful. No `fork` and `setsid` should be called
   (otherwise `inetd` will get confused) and all other steps are already done
   by `inetd`.
2. Second, all of the above code is already implemented in the `daemon` system
   call with slightly less control over the end-result. It might be easier to
   use it instead of all of the above steps.

All is good and nice but what if we want to daemonize a normal process? Well,
we can use `nohup`, `disown` or `start-stop-daemon`. Or we could resort to
special services to start our daemons like `inetd` and `upstart`.

### Using nohup for daemonizing processes

`nohup` is a command which is used to run a command which ignores the HUP
(hangup) signal. The HUP signal is used by a terminal to warn dependent
processes of logout. Thus, processes started with `nohup` won't be killed
after the `tty` is destroyed.

``` bash
$ nohup sleep 10000 &
[1] 5470
nohup: ignoring input and appending output to ‘nohup.out’
$ exit
```

Now open a new terminal and

``` bash
$ pgrep sleep
5470
```

We can simulate `nohup` inside our C code too. Let's configure signal
handlers:

``` c
memset (&sig_act, 0 , sizeof(sig_act));
/* Ignore SIGHUP signal */
if (signal(SIGHUP, SIG_IGN) == SIG_ERR){
    perror("signal");
    exit(EXIT_FAILURE);
}
```

Now, if `stdout` is a terminal we have to redirect output to a file, just like
the original command does:

```c
if(isatty(fileno(stdout))) {
    rc = open ("nohup.out", O_WRONLY | O_CREAT, 0644);
    if (rc < 0) {
        perror("open");
        exit(EXIT_FAILURE);
    }
}
```

Then we can `fork` and `exec` to get to our new process.

Let's test it now (`./a.out` is our test binary, it receives as arguments the
command line to execute in `exec`):

``` bash
$ ./a.out gedit &
[1] 22727
```

After we close the terminal and open a new one, we clearly see that the
process will be adopted by `init`:

``` bash
$ ps -ef | grep gedit
matei    22727     1  2 18:25 ?        00:00:01 gedit
```

### Disowning a process

What if we already started the process and forgot to use `nohup`? We can use
`disown` to make the process become inherited by `init`, thus acting as a
partial daemon.

Our first job is to use `^Z` to stop/pause the program and to go back to
terminal. Then we have to use `bg` to run it in the background.

``` bash
$ gedit
^Z
[1]+  Stopped                 gedit
$ bg
[1]+ gedit &
```

Now, we use `disown` with the `-h` option, to mark the process so that
`SIGHUP` is not gonna be received. If we don't use the `-h` option the process
is also removed from the current jobs table, which is something we like to do
anyway:

``` bash 
$ disown
```

If we go to another terminal, we'll see that the process has been adopted by
`init`:

```bash
$ ps -ef | grep gedit
matei    23087 22921  8 18:38 pts/6    00:00:01 gedit
```

To conclude :

- we need to use daemons for autonomous tasks
- we have multiple ways for creating daemons
- we can control daemons using signals and config files

All other methods will be presented in a second part article.

[1]: http://web.archive.org/web/20120914180018/http://www.steve.org.uk/Reference/Unix/faq_2.html#SEC16 "How to code a daemon"
