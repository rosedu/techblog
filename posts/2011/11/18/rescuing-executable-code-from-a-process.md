---
date: 2011-11-18
title: Rescuing executable code from a process
author: Alexandru Juncu
tags: process, procfs, /proc, file descriptor
---

A `process` is an instance of a binary executable file. This means that when
you ‘run’ a  binary, the code from the storage media is copied into the
system’s memory, more precisely, into the process’ `virtual memory space`.
From a single binary, several processes can be spawned.

<!--more-->

The virtual memory of a process, made up of pages, is mapped to several
things, like shared objects(libraries), shared memory, stack and heap space,
read-only space and executable space. A good way to view what is mapped to
what is with the `pmap` utility, or by just looking in the `/proc` directory
hierarchy. The `/proc/$PID/maps` file (where `$PID` is the process ID of the
targeted process) has the page mappings. Also in `/proc/$PID`, you can find
other useful files, like the `exe` file that contains a symlink to the
executable or the `fd` directory that contains symlinks to all the files
opened as _file descriptors_ in a process.

Except useful information, what can we get out of the `procfs`? Here is a
situation that has been known to happen. You are in a console, with your bash
shell, and you manage to delete some important files, like `/bin/bash`.
Without that executable, you cannot run new shells and on a restart, your
system will be inaccessible. What can you do?

The code of your bash is no longer on the hard drive, but it is in the virtual
memory of the process you are currently running. You can find out what’s the
PID of the current shell instance using `$$` enviroment variable . Knowing
that, you can cd to the `/proc/$$` and access the content of the `exe` file
there.

Although the exe `file` is shown as a link to the original file that is now
deleted (thus the link should be broken), if you `cat` it, you will get its
binary content. In fact, all the original binary file. Here is the step by
step process:

	/bin # md5sum bash
	e116963c760727bf9067e1cb96bbf7d3  bash
	/bin # rm bash
	/bin # echo $$
	5051
	/bin # cd /proc/$$
	/proc/5051 # ls -la exe
	lrwxrwxrwx 1 root root 0 2011-11-15 23:47 exe -> /bin/bash (deleted)
	/proc/5051 # cat maps
	[snip]
	00f9e000-00f9f000 rw-p 0001c000 08:01 263123     /lib/i386-linux-gnu/ld-2.13.so
	08048000-0810c000 r-xp 00000000 08:01 284760     /bin/bash (deleted)
	0810c000-0810d000 r--p 000c3000 08:01 284760     /bin/bash (deleted)
	0810d000-08112000 rw-p 000c4000 08:01 284760     /bin/bash (deleted)
	[snip]

	/proc/5051 # cat exe>/bin/bash_rescued
	/proc/5051 # cd -
	/bin # md5sum bash_rescued
	e116963c760727bf9067e1cb96bbf7d3  bash_rescued
	/bin # chmod +x bash_rescured
	/bin # mv bash_rescured bash

What other things can we rescue? How about a file that was opened by a
process? For example, a video file, opened by a player:

	alexj@hathor ~ $ md5sum movie.ogv
	9f701e645fd55e1ae8d35b7671002881  movie.ogv
	alexj@hathor ~ $ vlc movie.ogv &
	[1] 6487
	alexj@hathor ~ $ cd /proc/6487/fd
	alexj@hathor /proc/6487/fd $ ls -la |grep movie
	lr-x------ 1 alexj alexj 64 2011-11-16 00:11 23 -> /home/alexj/movie.ogv
	alexj@hathor /proc/6487/fd $ rm /home/alexj/movie.ogv
	alexj@hathor /proc/6487/fd $ ls -la |grep movie
	lr-x------ 1 alexj alexj 64 2011-11-16 00:11 23 -> /home/alexj/movie.ogv (deleted)
	alexj@hathor /proc/6487/fd $ cp 23 /home/alexj/movie_rescued.ogv
	alexj@hathor /proc/6487/fd $ md5sum /home/alexj/movie_rescued.ogv
	9f701e645fd55e1ae8d35b7671002881  /home/alexj/movie_rescued.ogv

These things are possible because the instances of the files are still kept
and used by the kernel. The VFS (the Virtual File System) still has references
to the inodes of the files. They won't be released until the
processes will be finished.

Thanks to Răzvan Deaconescu and Vlad Dogaru for the idea of this article.
