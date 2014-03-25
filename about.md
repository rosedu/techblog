---
title: About
---
## About Techblog

Techblog is a blog about various IT-related technical topics and it's written
by people interested in technology and high-tech.

### How to write an article on Techblog

The simplest way is just to send an e-mail to `techblog` [_at_] `rosedu` [_dot_]
`org` to announce your desire to write something along with a draft in any
format you want (text file, PDF, HTML). If the idea looks good we will work
from there.

If you want to be extremely formal and do the entire work yourself then you
first clone the repository:

    git clone https://github.com/rosedu/techblog.git

then you install Haskell Platform and run `./build-exec` to have `hakyll` and
dependencies installed. After this you write your article in a
`posts/year/month/day/name.md` file -- using [markdown
syntax](http://daringfireball.net/projects/markdown/syntax) --, run
`./techblog` to see the future aspect of the site on `0.0.0.0:8000` and then
make a pull request. Please send an email to `techblog` [_at_] `rosedu`
[_dot_] `org` afterwards to ensure that your pull request is acted upon as
soon as possible.

### I have seen a bug

If you have found something which needs to be changed in the layout of the
site, please [leave an issue](https://github.com/rosedu/techblog/issues/new)
and we will start working on it as soon as possible.

If you have found something wrong inside one article leave a comment on that
article or send an email to `techblog` [_at_] `rosedu` [_dot_] `org` or
`rosedu-general` [_at_] `rosedu` [_dot_] `org`. We will try to fix things as
soon as possible. If need be, we will write a follow-up article containing
your remark and proper thanks and attributions.
