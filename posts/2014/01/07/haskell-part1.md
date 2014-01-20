---
date: 2014-01-07
title: A superficial exploration of Haskell - part 1
author: Dan Șerban
tags: haskell
---

This series of blog posts is aimed at experienced programmers who have heard
that Haskell is an interesting programming language, but have not had the
chance to invest any time in researching it.

In this series I am going to highlight a few remarkable things at a high level,
while glossing over some implementation details that would take too long to
explain properly. Therefore, expect a lot of "here's a practical application of
Haskell and here's some sample code, but don't ask to see the gory details"
hand-waving.

For the purposes of this series, I will simply assume that it's easy for the
experienced reader to jump into a new imperative programming language after a
few hours or days of becoming familiar with its syntax. And I'll start with an
example that illustrates how you have to adopt a completely different mindset
when you start learning Haskell.

Part 1 of this series covers:

- Mutability
- Upside Down Maps
- Tokenizing Kernel Code

<!--more-->

**Before you ask:** All the Haskell snippets I'm showing here consist of GHCi
interactive console sessions. I have configured a custom prompt for myself, by
placing the line `:set prompt "λ: "` in GHCi's configuration file
`~/.ghc/ghci.conf`. The prompt is going to [look
different](http://www.haskell.org/ghc/docs/7.6.2/html/users_guide/interactive-evaluation.html)
if you're just starting out with a freshly installed copy of Haskell.

### Mutability

To start with, here's a Python code sample, cut and pasted from a Python 2.7
REPL (interactive console session):

~~~ python
>>> x = 1
>>> x = x + 1
>>> x
2
>>>
~~~

Nothing could be simpler!

OK then. Time to port this snippet of code over to Haskell. I'm just going to
go with the flow and naively assume -- just as many newcomers to Haskell would
-- that porting Python code is a direct 1-to-1 syntactic translation, in other
words, an easy, straightforward thing to do.

The following is what happens in the Haskell REPL (called GHCi). By the way,
here we have to prepend the keyword `let` - it's the law of the land in GHCi:

~~~ haskell
λ: let x = 1
λ: let x = x + 1
λ: x
^CInterrupted.
λ:
~~~

Huh? What just happened? I was expecting Haskell to compute the value 2. It
took forever for the GHCi interactive console to evaluate `x`, so I got bored
and pressed `Ctrl-C`. What's happening? Explain this to me.

Well, as one Reddit commenter once observed, this is just one of the many
things Haskell does to haze you during your initiation.

What you're actually doing is giving Haskell a puzzle (`x = x + 1`) and saying
"Go find me a solution". Mathematically speaking, there are only 2 possible
solutions to that puzzle: $\infty$ and $- \infty$. So when you saw it hang,
Haskell wasn't merely taking its time -- for no good reason -- before giving
you back the value 2. Instead, Haskell's runtime was trying its hardest to
give you a correct result by taking every integer value it could think of, one
by one, and checking whether it was equal to its successor.

Just to be clear, there is a way to emulate the behavior of the Python snippet
we saw above, and the Haskell code for doing that looks like this:

~~~ haskell
λ: let x = 1
λ: x <- return $ x + 1
λ: x
2
λ:
~~~

As you can see, the syntax is much more verbose (and uglier) than in Python,
and for good reason -- in Haskell, you are strongly discouraged from using
variables and mutation as the primary means of expressing algorithms.

Haskell is divided in two major parts: a crystal palace of unspeakable beauty
and *mathematical purity*, and an imperative ghetto for doing *I/O* and
dealing with *mutation*. The equal sign in `x = x + 1` lives in the beautiful
palace and symbolizes mathematical unification, while the construct `<- return
$` lives in the ghetto and means "evaluate the right hand side and shove the
result into the identifier on the left hand side, thus overwriting what was
there beforehand, in true imperative style".

### Reverse Map? Upside Down Map? You decide

OK, for the next segment I'm going to assume that your beloved programming
language of choice has a construct called `map`, and that you know how to use
it.

We start again with some Python code. While Python does indeed offer a
higher-order function called `map`, it's much more common for experienced
Python developers to prefer using a list comprehension, like this:

~~~ Python
>>> list = range(20,31)
>>> list
[20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30]
>>> [ x + 1 for x in list ]
[21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]
>>>
~~~

Nothing new or earth-shattering - I would hope - so here's the Haskell
equivalent before we jump into the interesting stuff:

~~~ haskell
λ: let list = [20..30]
λ: list
[20,21,22,23,24,25,26,27,28,29,30]
λ: map (+1) list
[21,22,23,24,25,26,27,28,29,30,31]
λ:
~~~

So the basic idea I'm getting at here is that in the beginning we have:

- one single operation (compute an integer's successor)
- a list of integer values

**Now for the interesting part.**

Let's take those bullet points above and turn them upside down, such that in
the beginning we have:

- one single integer value
- a list of unary integer-to-integer operations

Python can still deal with this situation fairly well, since Python's
functions are first-class values (you can place several of them inside of a
list). But the Python code wouldn't be as concise or expressive as the Haskell
equivalent, shown here:

``` haskell
λ: let function_list_1 = [(+2),(*3),(^2)]
λ: let function_list_2 = [(*5),(+7),(*4),(subtract 10)]
λ: let i = 12
λ: import Control.Applicative
λ: function_list_1 <*> [i]
[14,36,144]
λ: function_list_2 <*> [i]
[60,19,48,2]
λ:
```

**Side note:** Due to brevity concerns, it is not practical to go into a
detailed explanation of the `<*>` operator in `Control.Applicative` (a module
in Haskell's standard library). That is a topic for another blog post. The
point here was to show how concisely you can express non-trivial computations
with Haskell.

**Fun fact:** implementing the "upside-down map" described above was recently
a requirement for admittance into [WebDev](http://webdev.rosedu.org/) (an
extracurricular course organized by ROSEdu). Candidates sent us solutions they
had written in various programming languages, with varying degrees of
conciseness. We found that the most verbose implementations were predominantly
Java-based.

### Let's tokenize some kernel code

For the next segment I'll just grab a [snippet of code from the Linux
kernel](https://github.com/torvalds/linux/blob/master/kernel/sched/fair.c#L507)
and demonstrate how concisely you can express a tokenizer for it in Haskell.

The code for Linux's completely fair scheduler is stored in a file called
`fair.c`; I'll just grab a small function from it (function
`__enqueue_entity`, which starts at line 507) and store it locally in a file
called `enqueue_entity.c`.

Here's what I do subsequently, step by step:

``` haskell
λ: sample_cfs_code <- readFile "enqueue_entity.c"
λ:
```

I just slurped the contents of the file into `sample_cfs_code`. This is our raw material, let's look at it:

``` haskell
λ: sample_cfs_code
"static void __enqueue_entity(struct cfs_rq *cfs_rq, struct sched_entity *se)\n{\n        struct rb_node **link = &cfs_rq->tasks_timeline.rb_node;\n        struct rb_node *parent = NULL;\n        struct sched_entity *entry;\n        int leftmost = 1;\n        while (*link) {\n                parent = *link;\n                entry = rb_entry(parent, struct sched_entity, run_node);\n                if (entity_before(se, entry)) {\n                        link = &parent->rb_left;\n                } else {\n                        link = &parent->rb_right;\n                        leftmost = 0;\n                }\n        }\n        if (leftmost)\n                cfs_rq->rb_leftmost = &se->run_node;\n\n        rb_link_node(&se->run_node, parent, link);\n        rb_insert_color(&se->run_node, &cfs_rq->tasks_timeline);\n}\n\n"
λ:
```

We now define our tokenizing function in Haskell (I trust you will appreciate
how concise it is):

``` haskell
λ: import Data.List
λ: let tokenize_this = unfoldr (\x -> case lex x of [("","")] -> Nothing; x:_ -> Just x)
λ:
```

The most interesting keyword here is `lex`, which is a function that is
defined in Haskell's standard library as part of the `GHC.Read` module. The
`unfoldr` function also deserves some explanation, but just as before, it
wouldn't be practical to go into much detail here.

So far, so good. Let's apply our tokenizing function to the C code:

``` haskell
λ: let tokenized_cfs_code = tokenize_this sample_cfs_code
λ:
```
Finally, let's view the resulting stream of tokens:

``` haskell
λ: mapM_ print tokenized_cfs_code
"static"
"void"
"__enqueue_entity"
"("
"struct"
"cfs_rq"
"*"
"cfs_rq"
","
"struct"
"sched_entity"
"*"
"se"
")"
"{"
"struct"
"rb_node"
"**"
"link"
"="
"&"
"cfs_rq"
"->"
[ ... many more tokens I'm not showing here ... ]
"rb_insert_color"
"("
"&"
"se"
"->"
"run_node"
","
"&"
"cfs_rq"
"->"
"tasks_timeline"
")"
";"
"}"
λ:
```

You can use this approach to help your language design efforts, if you plan on
inventing your own DSL, or even your own general-purpose programming language.
Once your source code is tokenized, you can now parse the stream of tokens
into the target Haskell data structures using a technique called combinator
parsing, which is where the Haskell programming language really shines.

### End of part 1

That's it for part 1 -- there will be more to come.

If you're interested in picking up Haskell, there are a number of very good
free online resources ([1][1], [2][2], [3][3]), as well as classes and workshops
held in various locations.

Speaking of Haskell classes and workshops, allow me to draw your attention to
a project called [lambda.rosedu.org](http://lambda.rosedu.org/#english), which
is an instructor-led, in-depth, hands-on workshop on functional programming
centered around Haskell, Scala and Clojure. The workshop is free of charge,
but the standards for admittance are fairly high (you will need to solve a few
programming as well as logic problems). The workshop will be hosted by ROSEdu
at the department for Computer Science of the POLITEHNICA University of
Bucharest some time during the summer of 2014. The topics I glossed over --
due to brevity concerns -- in this blog post will be covered in depth during
the workshop.

[1]: https://www.fpcomplete.com/school
[2]: http://learnyouahaskell.com/
[3]: http://book.realworldhaskell.org/
