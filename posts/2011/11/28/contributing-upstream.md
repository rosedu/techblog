---
date: 2011-11-28
title: Contributing Upstream
author: Mihai
tags: git, patch
---

Suppose your favorite application or a library you are using has a bug. You
find that the code is open source and are happy because of this. Being a programmer
yourself, you know that you can fix the bug and send a patch with the fix to
the maintainers. But how do you do this? This article will provide a short
walkthrough for this task using as an example the Linux kernel. Different
projects use different source version control systems. Because this article
works on the kernel tree, I am going to use git as an example.

So, the first thing to do is to clone the project's repository. This is to
ensure that you are working on the latest source -- maybe the bug was fixed
before and your operating system's package manager is behind on updates. For
our kernel example, we will be cloning the `net-next` tree
since this is where our final patch will land -- from there it would be applied
to the Linux kernel itself but this process is not the subject of this article.

	$ git clone
	git://git.kernel.org/pub/scm/linux/kernel/git/davem/net-next.git
	Cloning into 'net-next'...
	remote: Counting objects: 2241130, done.
	remote: Compressing objects: 100% (350702/350702), done.
	remote: Total 2241130 (delta 1873243), reused 2236736 (delta 1869251)
	Receiving objects: 100% (2241130/2241130), 442.07 MiB | 947 KiB/s,
	done.
	Resolving deltas: 100% (1873243/1873243), done.

Next, create a new branch on which to work and checkout it. All our work will
be done there and we will use this branch later when constructing the patch to
be sent upstream.

	$ cd net-next/
	$ git branch speedup_proc_net_dev
	$ git checkout speedup_proc_net_dev
	Switched to branch 'speedup_proc_net_dev'

Now, do your work, change the source, fix the bug or develop the improvement.
Be sure to follow the coding standards of the project you are contributing to.
Commit often as told in the [git] article. At the end of the task, when
everything is solved and you are ready to submit the patch, you can rebase the
commits into a single one or a set of commits depending on their content -- it
is better to have a single logical change per commit, also your patch will have
an increased chance of being accepted if each commit is small. When
rebasing your commits be sure to have a relevant commit message (as per [git]
article for example). For the Linux kernel there is a standard even in the
commit message. Start with a single line detailing the component you're
patching and a short description of the commit then -- after an empty line --
write a longer message detailing what you have done. Add relevant information
about the problem that you
solved, and -- if possible -- tests made when developing your solution. Also
add a `Signed-off-by` line. For example, the following is an example of a good
commit message.

	    dev: use name hash for dev_seq_ops

	    Instead of using the dev->next chain and trying to resync at each call to
	    dev_seq_start, use the name hash, keeping the bucket and the offset in
	    seq->private field.

	    Tests revealed the following results for ifconfig > /dev/null
		* 1000 interfaces:
			* 0.114s without patch
			* 0.089s with patch
		* 3000 interfaces:
			* 0.489s without patch
			* 0.110s with patch
		* 5000 interfaces:
			* 1.363s without patch
			* 0.250s with patch
		* 128000 interfaces (other setup):
			* ~100s without patch
			* ~30s with patch

	    Signed-off-by: Mihai Maruseac <mmaruseac@ixiacom.com>

Next step is to create the patch files. We do this by switching to the `master`
branch and doing a `git format-patch` operation.

	$ git checkout master 
	Switched to branch 'master'
	$ git format-patch master..speedup_proc_net_dev 
	0001-Speedup-proc-net-dev-filling.patch

As you see, in our case a single file was created since our
`speedup_proc_net_dev` branch was only a commit ahead of the `master` branch
(we previously rebased everything into a single commit). This will be the file
containing our patch, the file we will send upstream. But, before going there
we still have a lot of things to do.

First of all, we will need to check our patch for coding style mistakes. In the
case of the Linux kernel there is a script doing that and we will use it. For
other projects, we may need to do this step manually.

	$ ./scripts/checkpatch.pl 0001-Speedup-proc-net-dev-filling.patch 
	total: 0 errors, 0 warnings, 122 lines checked

	0001-Speedup-proc-net-dev-filling.patch has no obvious style problems and is ready for submission.

If there are problems we will have to go back to our branch, fix them, rebase
all commits and recreate the patches with `git format-patch`. When everything
is ready to be submitted we can send the patch to the developers via an email.
In most projects you will simply create a bug report and attach the fix there
and you are done. But since the Linux kernel is more complex we will have to
use the email path presented in the following paragraphs.

First of all, we have to find where to send the patch. We have another script
which can be used.

	$ ./scripts/get_maintainer.pl 0001-Speedup-proc-net-dev-filling.patch
	"David S. Miller" <davem@davemloft.net> (maintainer:NETWORKING [GENERAL],commit_signer:118/147=80%)
	Eric Dumazet <eric.dumazet@gmail.com> (commit_signer:32/147=22%)
	"Michał Mirosław" <mirq-linux@rere.qmqm.pl> (commit_signer:21/147=14%)
	Jiri Pirko <jpirko@redhat.com> (commit_signer:15/147=10%)
	Ben Hutchings <bhutchings@solarflare.com> (commit_signer:9/147=6%)
	netdev@vger.kernel.org (open list:NETWORKING [GENERAL])
	linux-kernel@vger.kernel.org (open list)

The addresses given as output are those where we will send our email. But,
before sending the first email, we will have to configure `git send-email`. For
example, adding the following lines to `~/.gitconfig` will ensure that you can
use Gmail as a SMTP server for sending the patch email.

	[sendemail]
		smtpencryption = tls
		smtpserver = smtp.gmail.com
		smtpuser = yourname@gmail.com
		smtpserverport = 587

Now, we can send the email. We will have to manually fill in the `--to` and
`--cc` options or we can use a list of `sed` commands as suggested by the
[Chromium] wiki. In our case we will do it manually just to exemplify all
steps, in real life it will be better to use scripts whenever it is possible.

	git send-email --to=netdev@vger.kernel.org \
	> --cc=linux-kernel@vger.kernel.org \
	> --cc=... 0001-Speedup-proc-net-dev-filling.patch
	0001-Speedup-proc-net-dev-filling.patch
	Who should the emails appear to be from? [Mihai Maruseac <mihai.maruseac@rosedu.org>] 
	Emails will be sent from: Mihai Maruseac <mihai.maruseac@rosedu.org>
	Message-ID to be used as In-Reply-To for the first email?
	....

After several more lines of output your mail will be sent. I have responded
with the default entries to the above questions but the last one is very
relevant, as we will see next.

After the mail is sent, it will appear on [patchwork] and on the mailing lists.
You will wait until someone looks through your mail and analyzes your patch.
Then, the patch can be applied or someone can report some problems to you. If
there are some problems, you will go back and solve them and will resend the
patch using the above methodology. This time, you will answer the Message-ID
question with the ID taken from the first email. In our case, the [patch][1]
was not accepted from the start and we had to reiterate. Thus, we answered that
question with the ID taken from the [initial patch][1]:
`<1318412950-22014-1-git-send-email-mmaruseac@ixiacom.com>`. Until the [final
patch][2] was accepted I needed to send several versions.

Even though this lasted a whole week, the feeling I got when it was finally
accepted was awesome. You will feel it too after sending the first few patches.

As a recommended link before the end of the article, make sure you listen the
[YouTube] video of Greg KH about contributing upstream.

[git]: http://techblog.rosedu.org/git-good-practices.html
[patchwork]: http://patchwork.ozlabs.org/project/netdev/list/
[1]: http://patchwork.ozlabs.org/patch/119174/
[2]: http://patchwork.ozlabs.org/patch/120948/
[Chromium]: http://dev.chromium.org/chromium-os/how-tos-and-troubleshooting/kernel-faq#TOC-How-do-I-send-a-patch-upstream-
[YouTube]: http://www.youtube.com/watch?v=LLBrBBImJt4
