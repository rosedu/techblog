---
title: About
---
## About Techblog[^1]

Techblog is a blog about various IT-related technical topics and it's written
by people interested in technology and high-tech.

### How to write an article on Techblog

All articles on the blog are generated from Markdown files. To write a new
article, all you need to do is write the post under
`posts/$year/$month/$day/$name.md` where `$name` is a short name for the file
containing the article. For example, [the article on floating
point](https://techblog.rosedu.org/fp-dragons.html) resides under
[`posts/2014/03/30/fp-dragons.md`](https://github.com/rosedu/techblog/blob/master/posts/2014/03/30/fp-dragons.md).
This short name is also visible in the URL, so make sure it is relevant to the
article.

Start the article with a simple YAML stanza describing the article: your name,
the expected publication date, the title and a set of tags associated with the
article and related to the contents. Continuing the example, here is the
stanza for the floating point article:

```
---
date: 2014-03-30
title: Here be Dragons - The Interesting Realm of Floating Point Operations
author: Mihai Maruseac
tags: floating point, numerical methods, approximate algorithms, fast transcedental functions, fast inverse square root
---
```

Then, write a short introduction to the article. It should be as long as
needed to create interest into reading the article but not longer than that.
This would create the blurb that is shown on the front page.

After the short introduction, add the following 3 lines to separate it from
the rest of the article:

```

<!--more-->

```

Then, continue writing the article in markdown format, in the same file.

If you have images to attach to the article, place them under `images/$name/`
where `$name` matches the name given to the main article file (without the
`.md` extension). Then refer to the image in the article using Markdown link
format.

If an article needs additional resources (e.g., binaries for CTF puzzles),
then please place them under `res/$name/`. We recommend including a full
version of the source code mentioned in an article including `Makefile` or
other build-related configuration. Make sure these are linked to from the
article itself.

Once the article is written, create a pull request on
[GitHub](https://github.com/rosedu/techblog/compare?expand=1). You can send an
email to `techblog` [_at_] `rosedu` [_dot_] `org` to have people review the PR
as fast as possible.

We require two approving reviewers before the article gets published. If you
have reviewers in mind when you write the article, you can mention them on the
PR.

#### Previewing the article

You can preview how the article looks like using the GitHub preview facility
but if you want to see how it looks on the website you need a few additional
steps: first, clone the repository:

    git clone https://github.com/rosedu/techblog.git

After this, you need to either build the binary that builds the website or
download it from the [releases
page](https://github.com/rosedu/techblog/releases).

To build the binary, you need a working Haskell environment. We provide
tooling for [Haskell Stack](https://docs.haskellstack.org/en/stable/README/)
but installing the [minimal installer or the full Haskell
Platform](https://www.haskell.org/downloads/) should also work.

Assuming a Stack based toolchain, you then have to build the binary using
`stack build`. If you want, you can also install it on a directory in `PATH`
using `stack install`.

Then, you can preview the article on a local web-server that refreshes as soon
as the file contents change by running `techblog` (alternatively, if you
didn't run `stack install`, then you will need to run `stack exec techblog`).

Opening your browser and navigating to `127.0.0.1:8000` will then display the
blog from a locally generated copy.

#### For curators

Once pull requests are merged into `master`, to update the site you will have
to manually run `stack exec techblog -- deploy` (or `techblog deploy` if you
ran `stack install` before) after pulling from the GitHub remote.

The binary has one additional running mode, `techblog validate` where all
articles are scanned and all links are checked to see that their server
returns a `200 OK` HTTP code.

Finally, to completely clean the generated website and all associated caches,
you can run `techblog clean`. You will need to do this again if you compile a
new version of the tool.

#### Automation

Most of these steps have been automated with [GitHub
actions](https://github.com/rosedu/techblog/blob/master/.github/workflows/CI.yaml).
However, automatically pushing to the GitHub page that serves the blog is not
possible, hence one curator will still need to run `stack exec -- techblog
deploy` after merging the PR.

### I have seen a bug

If you have found something which needs to be changed in the layout of the
site, please [leave an
issue](https://github.com/rosedu/techblog/issues/new?assignees=mihaimaruseac&labels=toolchain-issue&template=20-improvement-request.md&title=%5BToolchain+issue%5D+Title)
and we will start working on it as soon as possible.

If you have found something wrong inside one article leave a comment on that
article or open an issue. Alternatively, send an email to `techblog` [_at_]
`rosedu` [_dot_] `org` or `rosedu-general` [_at_] `rosedu` [_dot_] `org`. We
will try to fix things as soon as possible. If need be, we will write a
follow-up article containing your remark and proper thanks and attributions.

### I want to propose an article.

Please open [a new issue with the corresponding
template](https://github.com/rosedu/techblog/issues/new?assignees=mihaimaruseac&labels=new-article-request&template=10-new-article.md&title=%5BArticle+request%5D+Title)
to suggest writing a new article.

If the request is approved, someone (could be you) will write the article and
both the author and the author of the proposal will be credited.

[^1]: Last updated 2020/12/28.
