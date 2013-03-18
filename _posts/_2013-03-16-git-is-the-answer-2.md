---
layout: post
date: 2013-03-16
title: Git Is The Answer 2/3
tags: [git]
author: Răzvan Deaconescu and Mihai Maruseac
---

The second article on advanced [git][git] topics is focused on cases where
multiple branches are involved.

## My Changes Conflict With Yours

Usually, it happens that two developers are working on the same file. Git
tries its best to merge changesets from both developers without complaining.
However, Git is not a human being so it cannot know what change is the good
ones when two changes happen two close to one another in the file.

As opposed to SVN, in Git, it is the responsibility of the one who pulls to
solve conflicts. Thus, you are forced to solve conflicts before being able to
push your changes upstream. But how does it work?

When you try to pull a file which contains conflicting changes, git will stop
with a strange message. We will use the `git pull --rebase` command instead of
the `git pull`.

    Using index info to reconstruct a base tree...
    M   numbers
    Falling back to patching base and 3-way merge...
    Auto-merging numbers
    CONFLICT (content): Merge conflict in numbers
    Failed to merge in the changes.
    Patch failed at 0001 Add a don't like line.
    The copy of the patch that failed is found in:
       /tmp/repos/repo3/.git/rebase-apply/patch

    When you have resolved this problem, run "git rebase --continue".
    If you prefer to skip this patch, run "git rebase --skip" instead.
    To check out the original branch and stop rebasing, run "git rebase --abort".

Even the file you changed looks awkward:

    4
    <<<<<<< HEAD
    insert here 5
    =======
    I don't like this line 5
    >>>>>>> Add a don't like line.
    6

As you can see, there are 3 more lines inserted. The ones starting with
`<<<<<<<` and `>>>>>>>` mark the boundary of the conflicting area as well as
the origin of the two conflicting changes (in our case `HEAD` is our
repository's latest commit while `Add a don't like line.` is the commit
message of the last commit on the remote).

Between the two marks, you have the two changes, separated by `=======`. You,
as a developer, have to choose what makes sense: either keep only one of the
changes, merge them together or even write something totally new.

You edit the file with the desired change and add it back for staging. After
this you simply continue the rebase process.

    git add numbers
    git rebase --continue

If there are more conflicting changes you will have to reapply the same
procedure. Otherwise, you can go forward to pushing your changes. As you can
see, no conflict ever leaves your repository, you are forced to deal with it
before continuing.

## Tags and Branches For The Win

TODO RD

## Branches on a Virtual Machine

TODO RD

## Creating Patches from Branches

TODO MM

## Going After Cherries

In some cases, when working with multiple branches, it might happen that you
need a specific commit from one branch but you don't want to merge that branch
into your current one.

Fortunately, Git allows you to pick a single commit as easy as picking
cherries from a cherry-tree. In fact, the command is `git cherry-pick`.

    $ git cherry-pick 1904c3d4c9720
    [master 3a30153] File to be cherry-picked in master.
     Author: Andrei Petre <p31andrei@gmail.com>
     1 file changed, 0 insertions(+), 0 deletions(-)
     create mode 100644 file_to_get_in_master

Now, you have a **new** commit with the same change as the picked-up commit
but on your branch

    $ git log
    commit 3a3015378c3c1b43c4895a00829034d53fb9a5b5
    Author: Andrei Petre <p31andrei@gmail.com>
    Date:   Fri Mar 8 23:59:07 2013 +0200

        File to be cherry-picked in master.

As you can see, the commit hash is different meaning that there is a new
commit, not the old one.

Should a commit not apply cleanly, Git stops the cherry-picking process and
asks for human intervention. After the problems are resolved, you can continue
it with `git cherry-pick --continue`. Or, you can abort it via `--abort` if
you change your mind after seeing the trouble.

[git]: http://git-scm.com/ "Git"
