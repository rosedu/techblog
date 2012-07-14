---
layout: default
title: Posting
---

# [Posting][]

This page lists the requirements for posting to this [blog][Techblog]. If you
intend to write an article, then this page is for you. However, if you
want to sugest an article but not write it yourself, you can [leave a
request][request] on the [issues][request] page of the [GitHub][GitHub] repo
of the [blog][Techblog].

First, you have to clone the [git][git] repository used. As per [GitHub][GitHub],
this is done by issuing the following command:

	git clone git@github.com:rosedu/techblog.git

The above works if you are added in the [ROSEdu][ROSEdu] team on
[GitHub][GitHub] (that is you are a full member of the organisation). If not
you can fork the [repository][repo] and send a pull request. If anything looks
wrong, send a mail to <mihai@rosedu.org>.

In the newly created directory (`techblog` if you used the above command) you
have a new directory named `_posts` inside which there are a number of files.
Some of them are in [Markdown][] format and are named
`year-month-day-title.markdown` while others are in [Textile][] format and are
named `year-month-day-title.textile`. These represent each article of the
[blog][Techblog]. All other files are used for the entire configuration of the
blog, if you want to solve an issue or do some improvements you can change them.

Now, for posting, in the `_posts` directory, you create your new file, setting
the date a few days ahead (such as to account for the time it takes for the
article to be reviewed). Use the format of your choice. If the title contains
multiple words separate each word with a dash. For example, an article named
_A Debugging Story_, using the [Markdown][] format, published on 1st of April
2012 should be named `2012-04-01-a-debugging-story.markdown`. We support the
`.md` extension as well.

Fill in the content of the article. It should have the following form (where
`$TEXT` is intended as a placeholder for the value of `TEXT`):

	---
	layout: post
	date: $DATE
	title: "$TITLE"
	tags: [$TAGLIST]
	author: $NAME
	---
	$EMPTY_LINE
	Text of the article.

The `$DATE` should follow the same convention: `year-month-day`. The `$TITLE`
should be enclosed by \" and should be exactly what you desire your article to
be titled. Use relevant tags for the `$TAGLIST`: single words, separated by
commas. Use your actual name for the `$NAME` variable and don't forget to leave
an empty line for the `$EMPTY_LINE` variable.

At any moment in time you can add the article (`git add`), commit it (`git
commit`) and push it to the [repository][repo]. After each push you can look
at the article in the [GitHub][GitHub] browser-based view. Edit the article
until it looks ok to you.

Finally, send a mail to the [ROSEdu mailinglist][mailinglist] in which you
announce the article and ask for review. After a few days of review and
changes the article will be published to the [Techblog][].

[Posting]:./ "home"
[ROSEdu]: http://rosedu.org "ROSEdu"
[git]: http://git-scm.com/ "Git"
[markdown]: http://daringfireball.net/projects/markdown/ "Markdown"
[textile]: http://textile.thresholdstate.com/ "Textile"
[mailinglist]: mailto:rosedu-general@lists.rosedu.org
[Techblog]: http://techblog.rosedu.org "Techblog"
[request]: https://github.com/rosedu/techblog/issues
[GitHub]: https://github.com
[repo]: https://github.com/rosedu/techblog
