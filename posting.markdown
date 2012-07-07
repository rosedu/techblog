---
layout: default
title: Posting
---

# [Posting][]

This page lists the requirements for posting to this [blog][Posting].

First, you have to clone the [git] repository used. You need to clone the
`contrib` branch where the main development (that is writing content and
revising it) gets done.

	git clone gitolite@git.rosedu.org:techblog.git -b contrib

If this command fails, send a mail to <mihai@rosedu.org>. All people from
[ROSEdu][] should have their public SSH key added to the repository,
allowing them to use the `contrib` branch for pulling and pushing. If it
doesn't work, I will do some debugging.

In the newly created directory (`techblog` if you used the above command) you
will have a number of files. Some of them are in [Markdown][] format and are
named `year-month-day-title.markdown` while others are in [Textile][] format
and are named `year-month-day-title.textile`.

You create your new file, setting the date a few days ahead (such as to account
for the time it takes for the article to be reviewed). Use the format of your
choice. If the title contains multiple words separate each word with a dash.
For example, an article named _A Debugging Story_, using the [Markdown][]
format, published on 1st of April 2012 should be named
`2012-04-01-a-debugging-story.markdown`.

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
commit`) and push it. After each push the [preview site][preview] gets updated,
look at the [archive][previewarchive] to find your article. Edit the article
until the desired preview.

Finally, send a mail to the [ROSEdu mailinglist][mailinglist] in which you
announce the article and ask for review, giving the link to the preview
article. After a few days of review and changes the article will be pushed to
the `main` branch making it public on the [Techblog][].

[Posting]:./ "home"
[ROSEdu]: http://rosedu.org "ROSEdu"
[git]: http://git-scm.com/ "Git"
[markdown]: http://daringfireball.net/projects/markdown/ "Markdown"
[textile]: http://textile.thresholdstate.com/ "Textile"
[mailinglist]: mailto:rosedu-general@lists.rosedu.org
[preview]: http://rosedu.org/~techblog/site2
[previewarchive]: http://rosedu.org/~techblog/site2/archive
[Techblog]: http://techblog.rosedu.org "Techblog"
