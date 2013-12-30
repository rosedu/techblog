---
date: 2011-09-12
title: Git Tips and Good Practices
author: Răzvan
tags: SCM, Git, tip, good practice
---

[Git][git] is an excellent SCM (source code management system). I use it
for a plethora of tasks such as managing code, scripts, LaTeX files,
config files, [Org-Mode][org-mode] files. I try to base all my actions
on text files such that it could be managed through Git.

In this post I wish to share some of the knowledge and skills I've
gathered throughout the time of using Git. I am novice myself in many
aspects of using Git, but I feel confident of my basic usage skill and
good practices.

My aim is to present tips and good practices that allow using Git at its
value and conforming to recommendations. This is not a tutorial or a
comprehensive view of Git. In case you are looking for that I recommend
the excellent [Gitimmersion tutorial][gitimmersion] and the [Pro Git
Book][pro-git].

An important aspect to have in mind is the data model that Git uses.
While most SCMs use changesets to manage commits, Git uses snapshots.
Each commit is a snapshot of the entire project; it is not a set of file
patches. Bear this in mind when using Git commands and playing around with
commits. You may also check [this tutorial][learn-github] for a more thorough
presentation.

### Configuring Git

The first step of using Git is configuring your identity and
preferences, as highlighted by most tutorials. The recommended practice
is to configure Git at system level (using the `--global` option):

    git config --global user.name "Razvan Deaconescu"
    git config --global user.email "razvan.deaconescu@cs.pub.ro"
    git config --global color.ui auto

I recommend issuing the above commands each time you are using an
account that will make use of Git commands.

In case you want a different configuration (another email address, for
example) for a given repository, just issue the above commands (sans the
`--global` option) while in that repository.

A situation may arise when you want to create a commit (or a series of
commits) that use different user information. This may happen when you
and a friend have access to a common account, and you want to separate
your commits form hers/his (although run from the same account). There
are two situations and approaches to this:

1. Situation: You want to use a different identity for all (or most)
   commits in a shell session (such as an SSH login session). Solution:
Define the `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL` environment
variables:

      `export GIT_AUTHOR_NAME="Mighty McWolf"`

      `export GIT_AUTHOR_EMAIL="mighty@mcwolf.org"`

2. Situation: You want to use a different identity for a single commit.
   Solution: Use the `--author` option when committing:

      `git commit --author "Mighty McWolf <mighty@mcwolf.org>"`

### Commits

Everything in Git revolves around commits. A commit is a basic unit of
information that you submit to Git for handling. Git stores each commit
and links it to other commits such that you see a commit history, get
back to a previous state, create a branch, watch the commit tree, update
certain commits, create tags and many others. As mentioned above, a
commit represents a snapshot of the entire project.

A basic rule, that applies to all other SCMs, is that each commit must
keep the repository in a compilable state. That is, if one would
checkout to a random place in the commit history, he/she would still be
able to compile the source code. Make sure the project is in a
compilable state when issuing your commit.

While the repository needs to be in a compilable state, it need not run
perfectly. In fact it may end up in "Segmentation fault" or other
critical errors. That's no problem; it's not achievable (not possible
actually) to have a clean repository where each commit would break
nothing. Do not be afraid to break the application when issuing a
commit as long as its in a compilable state. If the application breaks,
another commit will fix it; an impatient contributor could very well
revert to a previous commit and create a branch from there. Moreover,
trying to keep the application running, may force you to disobey the
next recommendation.

Another important recommendation, heavily stressed in Git but
probably insisted on in other SCMs, is creating small, atomic commits.
Each commit should do one thing and do it well. A commit should not use
a message such as "Update everything." or "Fix plenty of errors."
Rather, each fix should go into a separate commit. This would make it
very easy for a reviewer to analyze and diff your commit and,
possibly, isolate a bug that you may have introduced. If your commit
ranges a whole bunch of features that introduce multiple bugs, isolating
those bugs and fixing them is a pain.

So, remember: **Create small atomic commits that keep the repository in a
compilable state**.

### Commit Messages

When your commit is ready, you'll issue the `git commit` command and
either use the configured editor or the `-m` option to write the commit
message. Either way there's a basic set of recommendations you should
follow when writing a commit message.

1. Keep it short. Ideally, your commit message should consist of at most 50
   characters. In case your message is longer, break it into sentences, and
leave a blank line between the 50 characters message and the rest. The
rationale, as mentioned in the [git commit manpage][git-commit], is that the
first line is used as an email subject line by various tools.

2. Use present tense when issuing a commit. This ensures "compatibility"
   with messages used by tools such as `git merge`.

3. Write sentences not descriptions, similar to good code comments. Use
   capital letter, use verbs and end with dot.

Tim Pope [writes][model-commit-message] about what makes a model Git
commit message.

### Creating and Updating Commits

Remember that your commits should be small: do one thing, do one thing
well.

What happens when you've made a lot of changes and you want to
create a commit? You need to "split" your changes in multiple commits.
For that you use `git add -i` (`-i` for interactive). When using `-i`
Git inquires you about the commit. Most likely you would:
1. choose the `patch` option (press `p` or `5`)
2. choose the file you want to "split"
3. press `Enter`
4. answer `y` or `n` to include/exclude certain chunks
5. press `q` to quit

At this point, the modified file would be found both in the staging area
and in the "changes" area. The staging area would solely consist of the
chunks you selected previously.

What if you've just created a commit and realized that the commit message
may be wrong or that there should have been another hunk or file
committed? In this case you would use `git commit --amend`. As the
options says, this gives you the possibility of amending the commit, be
it to update the commit message or to add certain files: just issue `git
add` (or `git add -i`) and then invoke `git commit --amend`. By adding
`--author`, the `--amend` option allows you to even update the author
identity.

What if you want to update a commit that is not the latest? If the
commit has been pushed in the remote repository, then it's quite
complicated and not recommended. However, if the commit is local and
hasn't been pushed, you may used `git rebase -i`. You have to specify
the commit id where rebasing will take place. Afterwards you will be
prompted with an editor screen where you can select which of the commits
that have been created. Usually you would replace the `pick` string with
`edit` and Git will pass you through all commits.

For each commit you will most likely issue some `git add` commands, then
`git commit --amend` and, finally, `git rebase --continue`.

As long as the commits are local (not pushed to the remote repository),
all is fine.

### Stashing

On certain occasions, you may need to run some commit update commands
(such as `git rebase`, `git pull`) but retain some "dirty data" in the
repository. As Git disallows the existence of non-committed data in such
occasions, the solution is stashing.

Stashing means you temporarily store your data in a specialized zone
such that it would not get in the way of the above commands. In order to
stash local changes, you would simply issue the `git stash` command.
After updates have occurred, use `git stash pop` to bring back changes
and revert to the original "dirty state".

### Ignoring Data

Some files or data have to be ignored from being commit, while others
need to be ignored because of process specifics or use preference.

As a rule of thumb, a repository should only manage text files; no
binary files such as image files, compressed files, object files,
executable files. If you are a web developer or someone who has to work
extensively with image files, the above rule wouldn't apply 100%. You
should however, only commit source code files and files that cannot be
compiled or linked from other files.

Such that a good practice is to create a top-level `.gitignore` file in
your repository and define files to be ignored. A basic `.gitignore`
file is shown below:

**sample .gitignore**

	*~
	*.swp
	*.swo
	*.o
	*.obj
	*.a
	*.so
	*.dll
	*.lib
	*.gz
	*.bz2
	*.zip

Optional `.gitignore` files may be created in subfolders of the
repository according to need.

`.gitignore` files are committed in the repository and their exclusion
rules are applied to all contributors. A situation may arise when you
create a folder that you want to reside in your repository clone but
never get committed. For example a `lib` folder consisting of libraries
you are linking against for testing purposes. As it is binary data it
shouldn't be committed, and, as you are the only one using it, it should
be ignored. You could add it to the `.gitignore` file but that would
complicate it. The best solution is to edit the `.git/info/exclude`
file. It follows the same syntax as `.gitignore` files but is local to
your clone.

The above solutions are not useful in a specific situation: you want
to ignore changes you make to a file that is being tracked. `.gitignore`
and `.git/info/exclude` only ignore non-tracked files; they can't be
used on files that are being tracked. Your solution lies in running the
command `git update-index --assume-unchanged abc.txt`. Issuing this
command ensures that any local updates to the `abc.txt` file are not
going to be taken into account when creating subsequent commits.

### Viewing Git Information

A large part of your interaction with Git is analyzing commits, diffing,
checking commit history etc. Visual tools are very important and provide
you an intuitive view of the repository commits. Such tools are [Git
GUI][git-gui], [gitk][gitk] and [giggle][giggle]. A nice tool, running
on an ncurses-based interface is [tig][tig].

Apart from that, several commands are heavily used throughout your work in
Git, from a "view point of view" so to say:

* `git status` provides you with information regarding the current
  branch, information in staging area, "dirty" information etc.;

* `git log` provides you with a CLI view of the commit history; an useful
  option is `--oneline` providing you with a `one commit on one line` view;

* `git diff` presents a diff between various states of the repository;

* without any option, `git diff` it shows changes in the working directory
  (versus `HEAD`);

* a single option to `git diff` is a commit ID or tag that is diffed
  against `HEAD`;

* two options tor `git diff` are two commit IDs or tags to be diffed.

An useful option to `git diff` is `--cached`. This option presents a diff
between `HEAD` and data in staging area. It's useful to check everything
is in order before creating a commit.

### Cleaning Up

An important activity is cleaning up files in different states (staging,
modified, non-tracked).

The list below highlights various user requirements and solutions to
those predicaments:

* You want to clear any updates you've done to a file that's being
  tracked:

	`git checkout file.name`

* You want to remove a file from the staging area and place it in the
  modified state; you want to build your commit in a different manner:

	`git reset HEAD file.name`

* You want to clear non-tracked files from the working clone:

	`git clean file.name`

* You want to clear all non-tracked files from the working clone:

	`git clean -f`

* You want to clear all changes and revert to the initial state of
  `HEAD` (by changes I'm referring to tracked files changes; this doesn't
affect non-tracked files):

	`git reset --hard`

###Other Resources

The Internet is filled with tutorials and tips regarding the use of Git.
[Google][google] is one of your best friends to provide you a rapid
solution to a problem. Through Google, I've found a lot of answers on
[Stack Overflow][stackoverflow].

As mentioned above, I find the [Git Immersion tutorial][gitimmersion] to
be very well presented and easy to follow and the [Pro Git
Book][pro-git] as a good technical presentation of Git and its features.
An excellent site, consisting of a plethora of very nicely presented
tips is [git ready][git-ready].

As a funny link, I recommend you access [Commit Message
Generator][whatthecommit].

[git]: http://git-scm.com/ "Git"
[org-mode]: http://orgmode.org/ "Org-Mode"
[learn-github]: http://learn.github.com/p/intro.html#snapshots_not_changesets "GitHub - Introduction to Git"
[model-commit-message]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html "A Note About Git Commit Messages"
[git-commit]: http://www.kernel.org/pub/software/scm/git/docs/git-commit.html "git commit manual page"
[git-gui]: http://kernel.org/pub/software/scm/git/docs/git-gui.html "git-gui"
[gitk]: http://www.kernel.org/pub/software/scm/git/docs/gitk.html "Gitk"
[giggle]: http://live.gnome.org/giggle "Giggle"
[tig]: http://jonas.nitro.dk/tig/ "tig"
[google]: http://www.google.com/ "Google"
[stackoverflow]: http://stackoverflow.com/ "Stack Overflow"
[gitimmersion]: http://gitimmersion.com/ "Git Immersion"
[pro-git]: http://progit.org/ "Pro Git Book"
[git-ready]: http://gitready.com/ "git ready >> learn git one commit at a time"
[whatthecommit]: http://whatthecommit.com/ "Commit Message Generator"
