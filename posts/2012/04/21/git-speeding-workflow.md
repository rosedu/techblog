---
date: 2012-04-21
title: "Git: speeding workflow"
author: Andrei Petre
tags: git, .gitconfig, alias, speed, log, config
---

If you didn't read the [techblog Git Tips and Good Practices][1] article yet,
you should, as it offers tips every git user should know, together with some
very useful references.

When using `git` for the first time, one has to specify his *name* and
*email*, so `git` can associate the commit with who committed it:

<!--more-->

    $ git config --global user.name "Firstname Lastname"
    $ git config --global user.email "your_email@youremail.com"

This adds info to `~/.gitconfig`, a global configuration file `git` uses.
Also, every git project has its own `.git/config` file (similar to the global
one), and any options from this file overwrites the options from the global
file.

    andrei@sherlock:~$ cat ~/.gitconfig
    [user]
        name = Andrei Petre		# filled by the
        email = p31andrei@gmail.com	# above commands
    [color]
        ui = auto
        pager = true
    [core]
        editor = vim
    [github]
        user = andreip
        token = ...
    [alias]
        co = checkout
        ci = commit
        st = status
        br = branch
        df = diff
        pa = add --patch
        rlog = reflog			# useful for lost SHA's
        type = cat-file -t
        dump = cat-file -p
        hist = log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short
        lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset 
             %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative

Most of these configurations are self explanatory. The part that I find it
most useful and what this article was all about (but needed an intro) are the
last two aliases.

* `git hist` (from [gitimmersion][2]) is a short version of `git log`

<img style="float:center" src='/images/git-alias-hist.png' alt='git lg' width="620" height="215"/>

* `git lg` (from [Andrei Maxim][3]) is also a short and pretty formatting version of `git log`

<img style="float:center" src='/images/git-alias-lg.png' alt='git lg' width="620" height="215"/>

Use the one you like best, and add speed to your workflow.

[1]: http://techblog.rosedu.org/git-good-practices.html
[2]: http://gitimmersion.com/
[3]: https://github.com/xhr
