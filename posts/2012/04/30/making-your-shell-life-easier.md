---
date: 2012-04-30
title: Making your shell life easier
author: Alexandru Juncu
tags: CLI, bash, shell, terminal, tmux, screen, jobs, fg, pushd, popd
---

Most Linux users prefer to use the CLI because of its efficiency. But
the days of the single terminal in which you had your shell are long
gone. Users take advantage of the GUI and use graphical terminals like
[`gnome-terminal`][gnome-terminal], [`konsole`][konsole] or similar utilities,
to start several shell instances. For example if you are a programmer, you
might want to have one instance for the editor (with the code you are working on),
another one to test and debug the compiled executable and -- maybe -- another for the
documentation (`man` pages). If you are a system administrator you might have a
shell with the configuration file of a service, one you use to test the running
service, and maybe one shell connected to another server. But  having a lot of
windows (or tabs) can get confusing.

Some prefer to optimize their environment and use a CLI-oriented Window
Manager, like [`xmonad`][xmonad], to *productively manage windows without the
use of the mouse*. But what if you can only get access to a single
terminal, like in the case of a SSH client to a remote host? What if you don't
have a GUI, when configuring a server on-site? Or what if you just
like to have one terminal window opened? What you can do is install
terminal multiplexing programs like [`screen`][screen] or [`tmux`][tmux]. These
programs fork several shell instances behind your primary shell instance
and you can switch between them using keyboard shortcuts. Or you can
learn to make use of things your shell ([`bash`][bash], for example) already
offers you.

### Lesson 1: Don't close things that you will open again soon.

If you are using your editor to write code or to change a configuration file
and you want to compile the code or restart a service and test the result, you
can send your editor into background with the `CTRL-Z` keyboard shortcut, that
sends a `SIGTSTOP` signal to the process. You can run other command and then
return to your edited file with the `fg` command. You may have several tasks in
background for that shell instance. You can use the `jobs` command to see them
and their jobid, and you can send a specific job in foreground with `fg
$JOBID`.

Some processes can not be sent into background with the `CTRL-Z` shortcut. For
example, if you have a `ssh` connection to a remote server where the `CTRL-Z`
will run not on the local host but on the remote host. In this case you will
need to use the escape sequence of `[ENTER]~` and then send the `CTRL-Z` signal
(you you need to press Enter, then the `~` key, then the `CTRL` and `Z` keys
together).

Always try to take advantage of the current process' features. For
example you can run `make` from a `vim` (or actually run any
commands by prefixing them with a `!`) and you can `kill` a process
from inside a `top` or `htop` process.

### Lesson 2: Save paths for directories you need.

Unlike a GUI, in a CLI you can go directly to a specific directory from the
current one by `cd`-ing to an absolute or relative path (not going one
directory at a time like in the GUI). But you shouldn't always have to type the
path. If you are going back and forth between two directories, use the `cd -`
command to change directory to the last working directory you were in.

If you have several directories you are going to go through, but you
know you will return to a specific one, you can use the directory stack
to save that directory. You can `pushd $DIR` a directory into the
stack and then `popd` to change into the top-of-stack directory.

Also, you can always use the reverse history (`CTRL-R`) to reuse
commands already given.


	rosedu:~# cd /etc/apache2/sites-available/
	rosedu:/etc/apache2/sites-available# cd /var/www/
	rosedu:/var/www# cd -
	/etc/apache2/sites-available
	rosedu:/etc/apache2/sites-available# pushd
	/etc/apache2/sites-available /etc/apache2/sites-available
	rosedu:/etc/apache2/sites-available# cd /home
	rosedu:/home# cd /etc/
	rosedu:/etc# popd
	/etc/apache2/sites-available
	rosedu:/etc/apache2/sites-available#


### Lesson 3: Always know who and where you are.

Some people open different terminals to keep track of what they are doing or
where they are (and not change the location inside that terminal). The shell is
made for having its current directory changes and it helps you know where you
are with the `prompt`. A normal prompts looks like `user@host:current_path$`.
It's important to know with what user and on what machine you are logged in.
The `$` and `#` characters will show you what privileges you have (either
limited or administrator). The `current\_path` is usually the name of the
current directory (but it can sometimes be a full path). If that doesn't
provide you enough information, use the `pwd` command to print the working
directory or setup the `PS1` variabile to include more information.

Shells like [`bash`][bash] have lots of not so well known tricks. But if you
learn those tricks, they will make your life easier.

[gnome-terminal]: http://library.gnome.org/users/gnome-terminal/stable/gnome-terminal-get-started.html.en
[konsole]: http://konsole.kde.org/
[xmonad]: http://xmonad.org/
[screen]: http://www.gnu.org/software/screen/
[tmux]: http://tmux.sourceforge.net/
[bash]: http://www.gnu.org/software/bash/
