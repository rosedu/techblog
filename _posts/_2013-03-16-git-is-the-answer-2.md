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

Tags are the best way to keep references to old commits. They are particularly helpful in school related activities, where you update lectures and lab tasks on an yearly basis.

The right way to handle this is to create a tag at the end of each year and update labs and tasks. If at any time you want to check out the old curriculum you can get back to that tag.

For example, for the [SAISP][saisp] repository, we've created tag a tag at the end of each year of study:

    razvan@einherjar:~/school/current/saisp/repo$ git tag
    2009-2010
    2010-2011
    2011-2012

If we would like to go to an old version we would simply create a branch starting from that tag:

    razvan@einherjar:~/school/current/saisp/repo$ git checkout -b br-2010-2011 2010-2011
    Switched to a new branch 'br-2010-2011'
    razvan@einherjar:~/school/current/saisp/repo$ git status
    # On branch br-2010-2011
    nothing to commit (working directory clean)

This allows easy organization of your tree, with no need to create other folders (one for each year). If you want to access information for a given year, you would just create a new branch.

This isn't the case for the current [CDL repository][cdl-repo]. I'm not particularly happy with it and will probably update it soon. As we weren't very Git aware at the time we've created the repository, we started using a folder for each year:

    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ ls
    2009  2010  2011  2012  2013  Makefile  curs1  git_tutorial  template  util

This is unnecessary and results in duplicate information, copied from one year to the other.

The solution is pretty simple: identify the last commit for each CDL session/year, tag it and then, if required create branches out of it.

Identifying the last commit for each CDL session is easily done through `gitk`. Browse the commits, look at the dates, identify the last commit and create a tag:

    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git tag 2009 e9858a9e74
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git tag 2010 26cd285f47
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git tag 2011-spring eaa2d7e9a8
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git tag 2011-fall f69e679ebd
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git tag 2012 fd23db9181

Afterwards, we can create branches for each of them to easily go to that point:

    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git branch br-2012 2012
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git branch br-2011-fall 2011-fall
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git branch br-2011-spring 2011-spring
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git branch br-2010 2010
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git branch br-2009 2009
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git branch
      br-2009
      br-2010
      br-2011-fall
      br-2011-spring
      br-2012
    * master
      old-master
      razvan

Of course, it would only makes sense to really clear the repository and turn it into a "normal" one that only stores current information. Remove old year data and show only current one:

    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ ls
    2009  2010  2011  2012  2013  Makefile  curs1  git_tutorial  template  util
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git rm -r 2009
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git rm -r 2010
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git rm -r 2011
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git rm -r 2012
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git mv 2013/* .
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ rmdir 2013
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ ls
    Makefile  curs1  curs3  git.mm  git_tutorial  schelet_inscriere  template  util
    razvan@einherjar:~/projects/rosedu/cdl/repo.git$ git commit -m 'Clear folder structure. Leave only current items'

All is now nice and clear. Any updates are going to be done on the current folder structure; any request to see old data can be handled by checking out one of the branches.

## Branches on a Virtual Machine

In our experience we come to situations when required to work on the desktop/laptop and on a virtual machine. Of course, we are using Git for storing code. It would only make sense for one repository to be a remote for another one. The case is that, with Git, every repository can be a remote.

As such, I usually create a clone of the laptop repository on the virtual machine. I usually do that with the [SO2][so2] repository when updating lab tasks or assignment solutions and tests. The laptop stores the main repository and the virtual machine uses a clone of that:

    root@spook:~# git clone razvan@einherjar.local:school/current/so2/git-repos/lab lab.git
    root@spook:~# cd lab.git/
    root@spook:~/lab.git# git remote show origin
    * remote origin
      Fetch URL: razvan@einherjar.local:school/current/so2/git-repos/lab
      Push  URL: razvan@einherjar.local:school/current/so2/git-repos/lab
    [...]

In order to work properly on the remote you would need to use a dedicated branch to push information. You'll have problems if you push to the master branch of a repository that is using the master branch itself. I usually dub this 'vm' (for virtual machine):

    root@spook:~/lab.git# git checkout -b vm
    Switched to a new branch 'vm'

Any further changes are going to be committed in the 'vm' branch. Subsequently you would push these commits to the main repository, on the laptop:

    root@spook:~/lab.git# git push origin vm
    Total 0 (delta 0), reused 0 (delta 0)
    To razvan@einherjar.local:school/current/so2/git-repos/lab
     * [new branch]      vm -> vm

On the main repository, you would just merge or rebase your changes from that branch:

    razvan@einherjar:~/school/current/so2/git-repos/teme$ git rebase vm
    First, rewinding head to replay your work on top of it...
    Fast-forwarded master to vm.

At this moment, all changes in the repository clone on the virtual machine are present in the master branch on the repository on the laptop. You need to create a separate branch on the virtual machine clone and then push that branch to the main repository. If you would work on the master branch on the virtual machine clone and push that, it would be problematic to integrate those changes in the master branch on the main repository.

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
[saisp]: http://elf.cs.pub.ro/saisp/ "SAISP"
[cdl-repo]: https://github.com/rosedu/cdl "CDL repository"
[so2]: http://ocw.cs.pub.ro/courses/so2/ "SO2"
