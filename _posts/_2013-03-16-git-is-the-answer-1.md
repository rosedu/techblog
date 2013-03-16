---
layout: post
date: 2013-03-16
title: Git Is The Answer 1/3
tags: [git]
author: Răzvan Deaconescu and Mihai Maruseac
---

We focus again on [git][git]. This time, we will present some real-world
scenarios where knoweldge of advance git topics helps. In order to keep down
the length of the article, our presentation is divided in 3 parts, this being
the first one of these.

## User Setup

After installing Git and before doing any commits into a repository, you must setup your user information and preferences. It is common to make a global configuration, using `git config`:

    git config --global user.name "Razvan Deaconescu"
    git config --global user.email "razvan.deaconescu@cs.pub.ro"
    git config --global color.ui auto

You should make this setup for each account you are using. At the minimum, you are going to use it at least for your laptop or workstation.

Global configuration is stored in `~/.gitconfig`.

In case you want to use another username within a repository, use the `git config` command in that repository, but without the `--global` option:

    cd /path/to/repository.git
    git config user.email "razvan@rosedu.org"

In the above setup, I have only updated the email address for the repository. The other options used are picked from the global configuration.

Per repository configuration is stored in `/path/to/repository.git/.config`.

## Handling Line Endings Like a Pro

TODO MM

## How to Create and Setup a Local Repo

One of the best features of Git is the ability to rapidly create and use local repositories. You don't have to create a repository and then clone it locally as you do in Subversion. You just create or access a directory and then initialize it as a Git repository. Changes to files in the directory will be able to be handled as commits.

Assuming I am working on a personal project, the first thing I would do is create a directory and initialize it as a Git repository. I recommend you append the `.git` extension:

    mkdir ~/projects/troscot.git
    git init ~/projects/troscot.git

The first thing you add in a repository is a `.gitignore` file stating the files you wish to ignore. Such a sample file is [razvand-snippets][here].

You just create the `.gitignore` file in the repository root and then add it to the repository:

    vi .gitignore
    git add .gitignore
    git commit -m 'Initial commit. Add global .gitignore file'

After this, one would create, add and commit any files required.

Another use case is adding repository support for existing directories. This may happen when there is some pieces of code you already have in place and want to place in a repository or, my personal use case, adding repository support to configuration directories. For example, if one would want to use versioning for Apache2 configuration files, one would issue (as `root`):

    cd /etc/apache2/
    git init .
    vi .gitignore
    git add .gitignore
    git commit -m 'Initial commit. Add global .gitignore file'
    git add .
    git commit -m 'Initial commit. Add all config files to repository'

The above commands add a `.gitignore` file in the repository and then add all Apache2 configuration files.

## I Want To Tweak A Commit

From time to time you realize that you have made something wrong with a
commit. Either you forgot to add a good, descriptive [commits][message] or you
have really screwed up some parts of the committed code. Maybe you have some
compile errors to fix or your commit does too many things at once.

Anyway, for all of these cases, Git allows you to rewrite the commit at will.

If the to-be-changed commit is the latest one and you only want to change it's
message or some related fields, but not the content, things are pretty simple.

    git commit --amend

However, for all the other cases things are a little more complex. But
possible. All you have to do is start a rebase process from the commit you
want to change. Start it interactively, so that you can have great control
over what it does:

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
you continue the rebase process by running `git rebase --continue`.

If you decide that the commit is ok and that the rebase was not neeeded, you
can always abort it with `git rebase --abort`.

Finally, keep in mind that **it is not recommended to change commits once they have been
pushed to another repository.**

## But My Commit Is Too Big

TODO MM

## I Don't Want This Commit Anymore

TODO RD

## I Want To Change This File Silently

TODO RD

[razvand-snippets]: https://github.com/razvand/snippets/blob/master/config/gitignore "gitignore file"
[git]: http://git-scm.com/ "Git"
[commits]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html "A Note About Git Commit Messages"
