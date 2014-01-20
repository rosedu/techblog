---
date: 2013-03-26
title: Git Is The Answer 3/3
author: Răzvan Deaconescu and Mihai Maruseac
tags: git
---

Finally, the third article on advanced [git][git] topics will focus on things
that many will use only in some very special cases.

<!--more-->

## Handling Multiple Remotes

There are situations when you decide to use multiple remotes for a repository.
For example, I'm using multiple remotes for my snippets repository:

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

One particular situation when multiple remotes are required is when using a
fork of a GitHub repository and doing [pull requests][pr]. This is also
mentioned in the ["Syncing a fork" article on GitHub][sync-fork].

After you create a repository fork on GitHub, you clone that fork. For
example, I've forked the [ROSEdu site repository][rosedu-site] in [my forked
repository][rosedu-site-razvand]. I've cloned [the forked
repository][rosedu-site-razvand], worked on the local clone and then pushed
changes. I would then create a pull request with those changes, that that they
would be integrated in [the main repository][rosedu-site].

A problem arises when the fork is not synced with the main repository.
Ideally, there would be a GitHub option to sync the fork. Since that doesn't
exist, the fork needs to be updated manually, though the local copy, as
mentioned in the ["Syncing a fork" article on GitHub][sync-fork].

First of all, you need to add the main repository as another remote to the
local repository. This is a read-only remote. As suggested by GitHub, I've
named this new remote `upstream`:

    razvan@einherjar:~/projects/rosedu/site/site.git$ git remote show
    origin
    upstream
    razvan@einherjar:~/projects/rosedu/site/site.git$ git remote show upstream
    * remote upstream
      Fetch URL: git@github.com:rosedu/site.git
    [...]

In order to sync the local repository with the `upstream` remote ([the main
repository][rosedu-site]) just fetch and rebase changes:

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

This changes are then pushed to the `origin` remote ([the forked
repository][rosedu-site-razvand]):

    razvan@einherjar:~/projects/rosedu/site/site.git$ git push origin master
    Counting objects: 16, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (11/11), done.
    Writing objects: 100% (11/11), 1.99 KiB, done.
    Total 11 (delta 6), reused 0 (delta 0)
    To git@github.com:razvand/site.git
       6f3dd4d..7411020  master -> master

New local changes are then going to be pushed to the `origin` remote. These
changes are then going to be aggregated into pull requests for the `upstream`
remote (the main repository), now in sync with the forked repository.

The above is a specific use case for syncing a fork in GitHub, making use of
two remotes: one for the original reposotiry and one for the fork. The
[excellent GitHub article][sync-fork] thoroughly describes the steps you need
to undertake to sync your fork.

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

It often happens that you've done some changes that you don't want to commit
yet but you need to sync with the remote repository (i.e. do a pull). Or you
want to merge a branch without commiting your changes. In this case, the
solution is using the stash.

The stash is a special place for Git where you temporarily stash your changes
in order to keep your repository clean:

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

The moment you stash changes, they "disappear" from the working directory. You
will be able to get them by using `git stash pop`.

When multiple users are working on a given repository it will often happen
that you need to pull their updates to see what has been done. Your local copy
may have changes you've made yourself, but still far from a commit. In that
case you would stash your changes, pull remote updates to sync your repository
and then pop the stash to continue your work.

## A Reference For Everything

We are near the end of the series. You have learned several things and you
might try others as well. Yet, from time to time you may find out that you
have lost a commit while playing around. Or, you rebased somewhere in the
past but you need a commit which you had skipped. Or, you used `git reset
--hard` and threw out a needed commit.

Luckily for you, Git doesn't lose anything. Everything can be recovered by
using a nice feature called *reflog* (from *reference log*). Let's see it in
action first.

    $ git reflog
    096bec6 HEAD@{0}: commit: Add suggestion from Stefan Bucur.
    8647ca7 HEAD@{1}: rebase finished: returning to refs/heads/master
    8647ca7 HEAD@{2}: checkout: moving from master to 8647ca7c213ef26fe3426e079356a8b9c0ef1a8f^0
    f020807 HEAD@{3}: commit: Ready to publish «Git is the answer - part 2» article.
    274c7bc HEAD@{4}: rebase finished: returning to refs/heads/master
    274c7bc HEAD@{5}: checkout: moving from master to 274c7bcc89487e3b3e5f935694046caf17bf005f^0
    97b6f11 HEAD@{6}: commit: Add TODO for conclusions.

The first column lists the commit hash at the point where the reference points
to. The second is the state of `HEAD` (`HEAD{1}` is where `HEAD` previously
was and so on). Then, you have a short description of what the reference is
about (a commit, a checkout, a merge, a reset, etc.). This helps you in
remembering what each change was about.

To recover a commit you just cherry pick it from the reflog using its hash or
even the `HEAD@{id}` reference.

## Garbage Collecting the Repository

In the end, let's focus on trimming down the disk usage of the repository. We
want to prune some references. First, we set an expire date:

    $ git reflog expire --expire=1.day refs/head/master

The above marks all references older than 1 day as being obsolete.

The second step is to find all unreachable objects:

    $ git fsck --unreachable
    Checking object directories: 100% (256/256), done.
    Checking objects: 100% (80/80), done.
    unreachable blob 0aa0869906576afbe970251418982a5ae1a21698
    unreachable blob c1b86d806044ba5e344e037ec0128f7e944d0e0f
    unreachable blob 1f4998496071654c1b16eb33932d9d8b4fee5971
    unreachable tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904
    unreachable blob d9024465bff70288deaa116a646c01f1af7170b6
    unreachable blob ec1a48a4de254e80e803b4a4daa4a1f87fe4acea
    unreachable blob f0c2af9359d0c360fae9779f8c8b3143e7002810
    unreachable blob 17135e0a43db16a2d127a4cb2a692b41257c8c26
    unreachable tree 39d3a7c06c75d063cc13adde71b745f412a6f84f
    unreachable tree fad372db5c9c9b842d3786733437c5e32dda426b
    unreachable blob 07c469400c9ed887416d16a178a28cb911e6634e
    unreachable tree 8c1deacee70bb3329ae6cd4fa2fbf546395ea712
    unreachable blob ad85a1ec621c5b58fd6876c4d88982406bd48156
    unreachable tree c865c8cb1344f77363c5314a91344623fe0dd661
    unreachable blob cdd55939c346385b7938f392f958812b4fa5ddaf
    unreachable blob d8255f99d74b09435a70ad3f2b23b0e69babc818
    unreachable blob f7ddf120540a448c50baba1047230e9ad7d687ac
    unreachable tree 30ce2c01c2792fdc4dfa6ab5c3e0c1cb876a405a
    unreachable blob 09cf62d09bb027f7cfabcb0333c1837fda3c9c92
    unreachable blob 435716d9434a852229aee58d16104c3335684113
    unreachable blob 974f61a4933ee5608b1810e569593adf2ffedd0b
    unreachable tree b3df14961958afa1b0434c1a31065751fef3b30d

Finally, we prune everything and then garbage collect the repository.

    $ git prune
    $ git gc
    Counting objects: 652, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (637/637), done.
    Writing objects: 100% (652/652), done.
    Total 652 (delta 373), reused 64 (delta 10)

We can check the reduction in size by issuing a `du .` before and after the
process. For this repository, we've managed to squeeze 3MB of space, not quite
an impressive feat. However, for rapidly changing projects the gains should be
higher.

In the end, looking at reflog we see

    $ git reflog --all
    16a82d6 refs/remotes/gh/master@{0}: update by push
    d3f979f refs/remotes/gh/master@{1}: update by push
    454935e refs/remotes/gh/master@{2}: pull --rebase: fast-forward
    bae10c0 refs/remotes/gh/master@{3}: update by push
    c0a692b refs/remotes/gh/master@{4}: pull --rebase: fast-forward
    04c5a1b refs/remotes/gh/master@{5}: pull --rebase: fast-forward
    745963b refs/remotes/gh/master@{6}: pull --rebase: fast-forward
    fd23db9

The last line shows the id of one commit but nothing more related to it. You
can still reset/rebase to there but you cannot point to any reference past it.

## Closing Up

We are at the close of this three part article on advanced git usage. Some of
the things presented here might make you ask *when I'll be using that?*. Some
of them will prove useful from time to time while others are a good thing to
know.

In the end, remember that Git is a swiss army knife among VCSs and there are a
lot of features which will make us masters of it should we learn and practice
using them. Like Vim, above a certain threshold Git can only be learnt by
using it on a day to day basis.

[git]: http://git-scm.com/ "Git"
[pr]: https://help.github.com/articles/using-pull-requests "Using Pull Requests"
[sync-fork]: https://help.github.com/articles/syncing-a-fork "Syncing a fork"
[rosedu-site]: https://github.com/rosedu/site
[rosedu-site-razvand]: https://github.com/razvand/site
