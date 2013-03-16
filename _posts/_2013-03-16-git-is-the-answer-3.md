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

TODO RD

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

TODO RD

## A Reference For Everything

TODO MM

[git]: http://git-scm.com/ "Git"
