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

TODO RD

## I Want To Tweak A Commit

TODO MM

## But My Commit Is Too Big

TODO MM

## I Don't Want This Commit Anymore

TODO RD

## I Want To Change This File Silently

TODO RD

[git]: http://git-scm.com/ "Git"
