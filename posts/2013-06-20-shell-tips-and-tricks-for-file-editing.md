---
layout: post
date: 2013-06-20
title: "Shell tips and tricks for log files"
tags: [CLI, bash, shell, files, text, truncate, tee, tail, follow]
author: Alexandru Juncu
---

Here are are some small things you might find useful when you need to
deal with text files. In the Linux/Unix world, a lot of things are text
files, so you need to know how to efficiently handle them. If you are a
sysadmin, you need to look at **log files** for most of your work time
and the following might come in handy.

### Following a log file

Take your `$GENERIC_SERVICE` on your server that generates a lot of logs.
You could open a **text editor** like `vi` or `emacs` to view the
logs or use `tail` to see the latest lines (or a combination of tail
and `head`). But you sometimes you need to view contents of the log in
real time (while the service writes the lines, you read them). This is
where the best use for the tail command comes in: the `--follow` flag.

	tail -f /var/log/mylog

Tail usually creates a process that prints a few lines (the lines that
exist when you run it), but with the `-f` flag, the tail process
keeps running and prints new lines as the file is being appended. The
process will close when the uses issues the `Cltr-D` (end of file)
command.

### Truncating a file

Maybe you need to clear the contents of a log file that has gotten too
big. You could do a `rm` on the file and let the service write the new
logs in a new file. Some services are picky and need the file to already
exist, so you could use the `touch` command (that "updates" an existing
file) which has the interesting side effect when applied on a non
existing file: to create an empty file (a new inode with no data
blocks).

But you just want to empty a file (same inode, just the contents
cleared). You could use the `truncate` command with the size flag of 0
bytes (`-s 0`). Or make use of the redirect operator `>`.

	:>file

or just

	>file

These will open the file, and redirect nothing into it. Since it is not
appending anything, the contents will be erased. `:` is the no-op
command so nothing will actually be done, but the shell with open and
write (well ... nothing) into the file because of the redirection operator
`>`.

### One input, two outputs

Some programs do not have a logging system programmed into them and just
print messages to standard output. Maybe you want to save that output
into a file for future use. This is simple to do with a file
redirection:

	./myprogram > my_log_file

But if you do this, you will lose the output to the (virtual) terminal.
A very interesting command is `tee`, that takes an input and writes
to standard output, but also writes into a specified file. You need
to pipe the output of a process into tee like this:

	./myprogram | tee my_log_file

Now you have both real time printing of the messages and you have them
saved for future use.

Hope this helps!
