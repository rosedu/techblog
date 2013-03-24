---
layout: post
date: 2013-03-16
title: Git Is The Answer 3/3
tags: [git]
author: Răzvan Deaconescu and Mihai Maruseac
---

Finally, the third article on advanced [git][git] topics will focus on things
that many will use only in some very special cases.

## Handling Multiple Remotes

There are situations when you decide to use multiple remotes for a repository. For example, I'm using multiple remotes for my snippets repository:

    razvan@einherjar:~/code$ git remote show
    gh
    gl
    glcs
    origin
    
    razvan@einherjar:~/code$ cat .git/config
    [remote "origin"]
        fetch = +refs/heads/*:refs/remotes/origin/*
        url = razvan@swarm.cs.pub.ro:git-repos/code.git
    [remote "gh"]
        url = git@github.com:razvand/snippets.git
        fetch = +refs/heads/*:refs/remotes/gh/*
    [remote "gl"]
        url = git@gitlab.com:razvand/mine.git
        fetch = +refs/heads/*:refs/remotes/gl/*
    [remote "glcs"]
        url = git@gitlab.cs.pub.ro:razvan.deaconescu/code.git
        fetch = +refs/heads/*:refs/remotes/glcs/*

One particular situation when multiple remotes are required is when using a fork of a GitHub repository and doing [pull requests][pr]. This is also mentioned in the ["Syncing a fork" article on GitHub][sync-fork].

After you create a repository fork on GitHub, you clone that fork. For example, I've forked the [ROSEdu site repository][rosedu-site] in [my forked repository][rosedu-site-razvand]. I've cloned [the forked repository][rosedu-site-razvanad], worked on the local clone and then pushed changes. I would then create a pull request with those changes, that that they would be integrated in [the main repository][rosedu-site].

A problem arises when the fork is not synced with the main repository. Ideally, there would be a GitHub option to sync the fork. Since that doesn't exist, the fork needs to be updated manually, though the local copy, as mentioned in the ["Syncing a fork" article on GitHub][sync-fork].

First of all, you need to add the main repository as another remote to the local repository. This is a read-only remote. As suggested by GitHub, I've named this new remote `upstream`:

    razvan@einherjar:~/projects/rosedu/site/site.git$ git remote show
    origin
    upstream
    razvan@einherjar:~/projects/rosedu/site/site.git$ git remote show upstream
    * remote upstream
      Fetch URL: git@github.com:rosedu/site.git
    [...]

In order to sync the local repository with the `upstream` remote ([the main repository][rosedu-site]) just fetch and rebase changes:

    razvan@einherjar:~/projects/rosedu/site/site.git$ git fetch upstream
    remote: Counting objects: 16, done.
    remote: Compressing objects: 100% (7/7), done.
    remote: Total 11 (delta 6), reused 9 (delta 4)
    Unpacking objects: 100% (11/11), done.
    From github.com:rosedu/site
       d21f23f..7411020  master     -> upstream/master
    razvan@einherjar:~/projects/rosedu/site/site.git$ git rebase upstream/master
    First, rewinding head to replay your work on top of it...
    Fast-forwarded master to upstream/master.

This changes are then pushed to the `origin` remote ([the forked repository][rosedu-site-razvand]):

    razvan@einherjar:~/projects/rosedu/site/site.git$ git push origin master
    Counting objects: 16, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (11/11), done.
    Writing objects: 100% (11/11), 1.99 KiB, done.
    Total 11 (delta 6), reused 0 (delta 0)
    To git@github.com:razvand/site.git
       6f3dd4d..7411020  master -> master

New local changes are then going to be pushed to the `origin` remote. These changes are then going to be aggregated into pull requests for the `upstream` remote (the main repository), now in sync with the forked repository.

The above is a specific use case for syncing a fork in GitHub, making use of two remotes: one for the original reposotiry and one for the fork. The [excellent GitHub article][sync-fork] thoroughly describes the steps you need to undertake to sync your fork.

## Bisecting the History

A powerful feature of Git is its ability to quickly find out a commit which
introduced a bad change. Suppose you have a bug in your application:

    $ ./test_math.py 
    2 + 3 = 6

Usually, it is possible that the bug was introduced several commits backwards
in time and it is harder to solve by debugging. Git comes to help with `git
bisect`. First, start, the process with `git bisect start` and mark a good and
a bad commit (the boundaries of the bisect range).

    $ git bisect start
    $ git bisect good 368297b26ac1f0dc4
    $ git bisect bad
    Bisecting: 7 revisions left to test after this (roughly 3 steps)
    [9e7e7252bc95453817187ef4f1a8d69fd4ed74d7] Modify test_math.py

Git has found a commit in the middle of the range. You test your code again
and see if the problem is solved or not. Then pass `good` or `bad` to `git
bisect`

    $ ./test_math.py
    2 + 3 = 5
    $ git bisect good
    Bisecting: 3 revisions left to test after this (roughly 2 steps)
    [1c6fddb664ce6cb7bb483b8413b8e1216666c89f] Modify test_math.py (4).

Continue this process until there are no more commits left in range.

    $ git bisect good 
    1c6fddb664ce6cb7bb483b8413b8e1216666c89f is the first bad commit
    commit 1c6fddb664ce6cb7bb483b8413b8e1216666c89f
    Author: Andrei Petre <p31andrei@gmail.com>
    Date:   Sat Mar 9 00:24:43 2013 +0200

        Modify test_math.py (4).

Git even shows you the commit and it's message. Now, do a simple `git show` to
see the changeset of the bad commit:

    $ git show 1c6fddb664ce6cb7bb
    commit 1c6fddb664ce6cb7bb483b8413b8e1216666c89f
    Author: Andrei Petre <p31andrei@gmail.com>
    Date:   Sat Mar 9 00:24:43 2013 +0200

        Modify test_math.py (4).

    diff --git a/test_math.py b/test_math.py
    index a6624f7..6e7f061 100755
    --- a/test_math.py
    +++ b/test_math.py
    @@ -4,7 +4,7 @@ def custom_sum(*args):
         """Calculate the sum of two given numbers.
            Make the sum work for multiple arguments
         """
    -    crt = 0
    +    crt = 1
         for var in args:
             crt += var
         return crt

In the end, you do a `git bisect reset` to return to the starting point. Do
the fix, commit and continue contributing to the project.

Finally, you can use `git bisect` with automated tests. Start the bisection
with `git bisect start` but pass the two end-points as well

    $ git bisect start HEAD 368297b26ac1f0dc4
    Bisecting: 7 revisions left to test after this (roughly 3 steps)
    [9e7e7252bc95453817187ef4f1a8d69fd4ed74d7] Modify test_math.py

Then use `git bisect run` with a script which returns 0 if the code is ok or
anything else if the bug is still present. Git will do the bisection for you.

    [mihai@esgaroth repo3]$ git bisect run ./test.sh
    running ./test.sh
    Bisecting: 3 revisions left to test after this (roughly 2 steps)
    [1c6fddb664ce6cb7bb483b8413b8e1216666c89f] Modify test_math.py (4).
    running ./test.sh
    Bisecting: 1 revision left to test after this (roughly 1 step)
    [d8a251d8348ac236d344a00b50a987e2af726663] Modify test_math.py (2).
    running ./test.sh
    Bisecting: 0 revisions left to test after this (roughly 0 steps)
    [2a084b613f6b69cc8eb44648b8b5665402f5d9c0] Modify test_math.py (3).
    running ./test.sh
    1c6fddb664ce6cb7bb483b8413b8e1216666c89f is the first bad commit
    commit 1c6fddb664ce6cb7bb483b8413b8e1216666c89f
    Author: Andrei Petre <p31andrei@gmail.com>
    Date:   Sat Mar 9 00:24:43 2013 +0200

        Modify test_math.py (4).

    bisect run success

This is indeed a good tool to have in Git's toolbox.

## Stashing the Goodies

It often happens that you've done some changes that you don't want to commit yet but you need to sync with the remote repository (i.e. do a pull). Or you want to merge a branch without commiting your changes. In this case, the solution is using the stash.

The stash is a special place for Git where you temporarily stash your changes in order to keep your repository clean:

    razvan@einherjar:~/projects/rosedu/site/site.git$ git status
    # On branch master
    # Changes not staged for commit:
    #   (use "git add <file>..." to update what will be committed)
    #   (use "git checkout -- <file>..." to discard changes in working directory)
    #
    #	modified:   irc.markdown
    #
    no changes added to commit (use "git add" and/or "git commit -a")
    razvan@einherjar:~/projects/rosedu/site/site.git$ git stash
    Saved working directory and index state WIP on master: 7411020 Remove a stupid Maruku error.
    HEAD is now at 7411020 Remove a stupid Maruku error.
    razvan@einherjar:~/projects/rosedu/site/site.git$ git status
    # On branch master
    nothing to commit (working directory clean)
    razvan@einherjar:~/projects/rosedu/site/site.git$ git stash pop
    # On branch master
    # Changes not staged for commit:
    #   (use "git add <file>..." to update what will be committed)
    #   (use "git checkout -- <file>..." to discard changes in working directory)
    #
    #	modified:   irc.markdown
    #
    no changes added to commit (use "git add" and/or "git commit -a")
    Dropped refs/stash@{0} (940f594b5f93e616dc16285e0677fbc78aa33620)

The moment you stash changes, they "disappear" from the working directory. You will be able to get them by using `git stash pop`.

When multiple users are working on a given repository it will often happen that you need to pull their updates to see what has been done. Your local copy may have changes you've made yourself, but still far from a commit. In that case you would stash your changes, pull remote updates to sync your repository and then pop the stash to continue your work.

## A Reference For Everything

TODO MM

## Conclusions

TODO MM

[git]: http://git-scm.com/ "Git"
[pr]: https://help.github.com/articles/using-pull-requests "Using Pull Requests"
[sync-fork]: https://help.github.com/articles/syncing-a-fork "Syncing a fork"
[rosedu-site]: https://github.com/rosedu/site
[rosedu-site-razvand]: https://github.com/razvand/site
