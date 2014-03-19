---
date: 2013-03-18
title: Git Is The Answer 1/3
author: Răzvan Deaconescu, Mihai Maruseac
tags: git
---

We focus again on [git][git]. This time, we will present some real-world
scenarios where knoweldge of advance git topics helps. In order to keep down
the length of the article, our presentation is divided in 3 parts, this being
the first one of these.

<!--more-->

## User Setup

After installing Git and before doing any commits into a repository, you must
setup your user information and preferences. It is common to make a global
configuration, using `git config`:

    git config --global user.name "Razvan Deaconescu"
    git config --global user.email "razvan.deaconescu@cs.pub.ro"
    git config --global color.ui auto

You should make this setup for each account you are using. At the minimum, you
are going to use it at least for your laptop or workstation.

Global configuration is stored in `~/.gitconfig`.

In case you want to use another username within a repository, use the `git
config` command in that repository, but without the `--global` option:

    cd /path/to/repository.git
    git config user.email "razvan@rosedu.org"

In the above setup, I have only updated the email address for the repository.
The other options used are picked from the global configuration.

Per repository configuration is stored in `/path/to/repository.git/.config`.

## Handling Line Endings Like a Pro

From time to time it is possible that you will have to work with people
working on a different operating system. It is no problem if both of you are
using systems with similar line-endings (`CRLF` for Windows, `LF` for
Linux/OSX). In all other cases, it might be that the default Git options used
for this don't work for you.

You can configure Git globally to handle line-endings if you set the
`core.autocrlf` option in your `~/.gitconfig`. However, the best settings are
different on different platforms.

For Windows you would use

    git config --global core.autocrlf true

While for Linux/OSX you would use

    git config --global core.autocrlf input

You must remember that these changes are valid only for you, and for the
operating systems which have these settings configured. To have the settings
travel with the repository you have to go a different path: you have to create
a `.gitattributes` file with a content similar to

    * text=auto
    *.c text
    *.h text
    *.sln text eol=crlf
    *.png binary
    *.jpg binary

The first line tells git to handle the line endings of all **text** files
automatically. The second two lines declare that `.c` and `.h` files are to be
treated as text (thus their line endings are to be converted to the proper
format). The `.sln` line uses a new parameter (`eol=crlf`) which tells Git to
normalize files on commit but to always checkout them with `CRLF` endings. Use
this for files which need to have `CRLF` endings, even on Linux. A similar
settings exists for `LF` endings.

Finally, there are cases when you need to commit binary files into the
repository. In this cases, changing `LF` characters to `CRLF` or the reverse
will break the binary. You have to tell Git not to handle them, thus you'll
specify `binary` in `.gitattributes` file.

If the repository already contained some files commited, after creating the
`.gitattributes` file each of you will have files show up as modified, even if
they haven't changed. This is because of the line endings changes which was
not followed by repository renormalization. To solve this, you have to do the
following steps (on a **clean** repository, otherwise changes will be lost).

First, remove everything from the index and reset both the index and the
working directory (the risky part):

    git rm --cached -r .
    git reset --hard

Finally, stage all files which were normalized and create a normalizing commit

    git add .
    git commit -m "Normalized line endings"

From now on, Git will properly do the job of handling line endings for you.

## How to Create and Setup a Local Repo

One of the best features of Git is the ability to rapidly create and use local
repositories. You don't have to create a repository and then clone it locally
as you do in Subversion. You just create or access a directory and then
initialize it as a Git repository. Changes to files in the directory will be
able to be handled as commits.

Assuming I am working on a personal project, the first thing I would do is
create a directory and initialize it as a Git repository. I recommend you
append the `.git` extension:

    mkdir ~/projects/troscot.git
    git init ~/projects/troscot.git

The first thing you add in a repository is a `.gitignore` file stating the
files you wish to ignore. Such a sample file is [here][razvand-snippets].

You just create the `.gitignore` file in the repository root and then add it
to the repository:

    vi .gitignore
    git add .gitignore
    git commit -m 'Initial commit. Add global .gitignore file'

After this, one would create, add and commit any files required.

Another use case is adding repository support for existing directories. This
may happen when there is some pieces of code you already have in place and
want to place in a repository or, my personal use case, adding repository
support to configuration directories. For example, if one would want to use
versioning for Apache2 configuration files, one would issue (as `root`):

    cd /etc/apache2/
    git init .
    vi .gitignore
    git add .gitignore
    git commit -m 'Initial commit. Add global .gitignore file'
    git add .
    git status
    git commit -m 'Initial commit. Add all config files to repository'

The above commands add a `.gitignore` file in the repository and then add all
Apache2 configuration files. The `git status` command is always necessary
after a `git add` command to make sure you are committing the right stuff; you
may need to update your `.gitignore` file in case you've missed ignoring
certain types of files.

## I Want To Tweak A Commit

From time to time you realize that you have made something wrong with a
commit. Either you forgot to add a good, descriptive [message][commits] or you
have really screwed up some parts of the committed code. Maybe you have some
compile errors to fix or your commit does too many things at once.

Anyway, for all of these cases, Git allows you to rewrite the commit at will.
You can add changes of tweak metadata (author name, commit message, etc.) just
by issuing the needed commands and ending with

    git commit --amend

However, this works only for the tip of the current branch. If you want to
change a commit which is not HEAD, you'll need to do a rebase process. This
will temporarily move HEAD to the commit you want to change, allowing you to
use the above procedure. It is best to start the rebase interactively, so that
you can have great control over what it does:

    git rebase -i cf80a4ad6d64bff2

The above will open your editor (configurable via `git config`) with a content
similar to the following one (you can see it on the disk if you really want
to, it is in the repository, in `.git/rebase/git-rebase-todo`)


    pick 899e7e6 Add Silviu's contributions.
    pick 02f1ef9 Add contribs to Cristian Mocanu.
    pick 98194cd Add contributions of Andru Gheorghiu.
    pick 2931f1d Add 2 contributions of spopescu.

    # Rebase cf80a4a..2931f1d onto cf80a4a
    #
    # Commands:
    #  p, pick = use commit
    #  r, reword = use commit, but edit the commit message
    #  e, edit = use commit, but stop for amending
    #  s, squash = use commit, but meld into previous commit
    #  f, fixup = like "squash", but discard this commit's log message
    #  x, exec = run command (the rest of the line) using shell
    #
    # These lines can be re-ordered; they are executed from top to bottom.
    #
    # If you remove a line here THAT COMMIT WILL BE LOST.
    #
    # However, if you remove everything, the rebase will be aborted.
    #
    # Note that empty commits are commented out

As you can see, you can select an action to be applied for each one of the
commits. If you only want to edit the commit message, you will change `pick`
with `reword` (or `r`). If you want to edit the content of the commit you will
select `edit`. You can even reorder commits, squash them one a bigger one,
etc.

For now, we will focus on editing the contents of one commit. We will change
last line in `edit`.

    e 2931f1d Add 2 contributions of spopescu.

The rebase process continues and tries to do what we've said it to do. In our
case, it will stop at commit `2931f1d` to allow editing it:

    Stopped at 2931f1d... Add 2 contributions of spopescu.
    You can amend the commit now, with

        git commit --amend

    Once you are satisfied with your changes, run

        git rebase --continue

Now, you can add or remove content, change the commit as you want, etc. Then,
you continue the rebase process by running `git commit --amend` followed by
`git rebase --continue`. Both of them are needed.

If you decide that the commit is ok and that the rebase was not neeeded, you
can always abort it with `git rebase --abort`.

Finally, keep in mind that **it is not recommended to change commits once they have been
pushed to another repository.**

## But My Commit Is Too Big

From time to time, you will have some big changes to commit. However, the case
when all of them are atomic and cannot be split into several shorter
components is very rare. Let's take for our example a LaTeX Beamer file. You
can commit each section separately or even each slide, as you see fit. But how
can you split the commit?

Actually, you can use two commands for this. One is `git add -i` to allow
interactive adding of parts of commits. The second one is to use `git add
-p` which is more simpler.

Running `git add -p` will present you with the first chunk of changes to be
committed. It might be the case that this is chunk is atomic or not. Git
offers this question after presenting the hunk:

    Stage this hunk [y,n,q,a,d,/,e,?]?

Selecting `?` will print the help text and the chunk afterwards. The help text
is

    y - stage this hunk
    n - do not stage this hunk
    q - quit; do not stage this hunk nor any of the remaining ones
    a - stage this hunk and all later hunks in the file
    d - do not stage this hunk nor any of the later hunks in the file
    g - select a hunk to go to
    / - search for a hunk matching the given regex
    j - leave this hunk undecided, see next undecided hunk
    J - leave this hunk undecided, see next hunk
    k - leave this hunk undecided, see previous undecided hunk
    K - leave this hunk undecided, see previous hunk
    s - split the current hunk into smaller hunks
    e - manually edit the current hunk
    ? - print help

Now, you can use these options to split your commit or edit it. Editing is the
most advanced feature of `git add -p`, the only one who needs more explaining.
So let's choose this.

    Stage this hunk [y,n,q,a,d,/,e,?]? e

Again, we will be presented with an editor to edit the contents of
`.git/addp-hunk-edit.diff`. The comment at the end of the file is
self-explanatory:

    # To remove '-' lines, make them ' ' lines (context).
    # To remove '+' lines, delete them.
    # Lines starting with # will be removed.
    #
    # If the patch applies cleanly, the edited hunk will immediately be
    # marked for staging. If it does not apply cleanly, you will be given
    # an opportunity to edit again. If all lines of the hunk are removed,
    # then the edit is aborted and the hunk is left unchanged.

The `-` lines are lines which will be removed by the commit and the `+` ones
will be added. Thus, if you remove a `+` line, the commit will not contain the
addition and if you mark one `-` line as context it won't be removed by the
commit.

Since `git add -p` is a powerful feature, it is advisable to have it added as
an alias, via `git config`. For example, I have `git gap` do the same thing as
`git alias -p`. Then, it is in my muscles' memory to type `git gap` when
adding changes for a new commit.

## I Don't Want This Commit Anymore

There is often the case that you want to rollback a change you've done. As
long as everything is happening locally (i.e. you haven't pushed to a remote
repository), Git offers the proper tools to handle this.

Assume you've updated a file but you want to discard those changes. You've
just done some tests and feel those are not required and want to get back to
the initial version. Then you would issue

    git checkout file-name

This above command restores the file to the repository version. It's very
useful in case you make a mess in a local file.

A quite often situation is preparing to make a commit. When you do that you
use one or more `git add` commands to prepare the commit; sometimes you use a
`git add .` command that gives you little control on what to add to the
staging area. You find out that you've added too much content to the staging
area. In order to remove that extra content from the staging area (and leave
it in the working directory), one issues:

    git reset HEAD file-name

If you want to start building your commit from the beginning and discard all
information in the staging area, you would use:

    git reset HEAD

When leaving out the file name, all content from the staging area is discarded.

Consider that you've done some bad commits and you've just found out. The last
two commits are really bad and need to be dropped. As long as you haven't
pushed anything, you can rework those commits: you can reset the repository
HEAD and leave the commit changes in the working directory. If we want to redo
the last two commits we would just issue:

    git reset HEAD^^

Remember, this doesn't remove the commit changes. The repository HEAD is
simply moved back and the commit changes are left in the working directory;
you will then use them to create proper new commits.

## I Want To Change This File Silently

GitHub has an excellent article on [ignoring files][ignoring-files]. A
particular situation is ignoring updates to files that are already in the
repository (i.e. they've been previously commited and can't be ignored using
.gitignore).

This kind of situation is part of my repository with letters of
recommendation. I'm using a Makefile for compiling out a letter and have
isolated in it some variables:

    $ cat Makefile
    PERSON = Alexandru_Juncu
    FOLDER = alexandru-juncu

    include base.mk

When I would create a new recommendation I update the `Makefile` to compile
it. However this change needn't make it to the repository. If I would do that
then each time I'm only compiling out an old letter of recommendation I would
change the Makefile file and push the new changes; or, if I don't want to push
those changes, I would need to use `git checkout`.

The best solution would be for any updates to the Makefile to not be
considered. The initial Makefile file would be stored in the repository (as a
model) but subsequent changes should not be visible. This can be done by
using:

    git update-index --assume-unchanged Makefile

No changes on the `Makefile` file are going to be considered in the working
directory.

If you want to revert this option, use:

    git update-index --no-assume-unchanged Makefile

[razvand-snippets]: https://github.com/razvand/snippets/blob/master/config/gitignore "gitignore file"
[git]: http://git-scm.com/ "Git"
[commits]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html "A Note About Git Commit Messages"
[ignoring-files]: https://help.github.com/articles/ignoring-files "GitHub: Ignoring files"
