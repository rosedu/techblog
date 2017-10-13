---
date: 2014-03-02
title: "A superficial exploration of Haskell, part 2: Lazy by default"
author: Dan Șerban
tags: haskell
---

Haskell uses lazy evaluation by default, but what does that mean exactly?

We're going to state the abstract definition of laziness, behold its
nonsensical beauty for a few seconds, and then conclude that a concrete
example is necessary in order to understand the concept:

> Laziness is the separation of equation from execution.

<!--more-->

Before we look at an example, let me remind you of a bit of syntactic sugar
that Haskell provides in order to quickly define a list of successive
integers:

``` haskell
λ: [20..70]
[20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70]
```

As you might remember from [part
1](http://techblog.rosedu.org/haskell-part1.html), `λ: ` is my custom GHCi
prompt, so we're effectively looking at the result of how GHCi interprets the
notation `[20..70]`.

OK then. To start, let's define two lists:

``` haskell
λ: let list1 = [20..70]
λ: let list2 = map (+1) list1
```

At this point you might be thinking "Oh look, `list1` is the enumeration of
all integers between 20 and 70, and `list2` is the enumeration of all integers
between 21 and 71".

**Well, no.** Not yet, at least.

GHCi provides a command called `:sprint` that allows us to take a peek at how
far along the evaluation of a given expression has progressed.

``` haskell
λ: :sprint list1
list1 = _
λ: :sprint list2
list2 = _
```

So what `:sprint` is telling us in the above snippet is that both `list1` and
`list2` are unevaluated at this point. To establish some terminology, an
underscore in the context of `:sprint` output represents a **thunk**. Formally
defined, a thunk is an expression that hasn't yet been evaluated. You may
think of it as a value wrapped in a function of zero arguments. When the
function is called, the value springs into existence.

We are now going to ask increasingly "intrusive" questions about `list2` and
then each step along the way examine what has been evaluated and what hasn't.

The simplest and least intrusive question we can ask about a list is whether
or not it's empty.

``` haskell
λ: null list2
False
λ: :sprint list1
list1 = 20 : _
λ: :sprint list2
list2 = _ : _
```

In order to answer that question, GHCi needs to know whether or not the first
element exists, and as a result, `list2` is no longer unevaluated, it is now
partially evaluated. GHCi now knows something about the structure of `list2` -
it knows that it consists of something "consed onto" (prepended to) something
else. In the next round, that "something" will turn out to be the value `21`,
but for right now this fact is irrelevant to the process of answering the
question "is `list2` empty". However, we notice the value `20` is fully
evaluated as the head of `list1` - this particular evaluation was necessary in
order to construct the thunk `(+1) 20`.

Next, we ask for the first element of `list2`:

``` haskell
λ: head list2
21
λ: :sprint list1
list1 = 20 : _
λ: :sprint list2
list2 = 21 : _
```

We notice that the expression `(+1) 20` mentioned above is now fully evaluated
and therefore no longer a thunk.

Next, let's ask for the first 5 elements of `list2`:

``` haskell
λ: take 5 list2
[21,22,23,24,25]
λ: :sprint list1
list1 = 20 : 21 : 22 : 23 : 24 : _
λ: :sprint list2
list2 = 21 : 22 : 23 : 24 : 25 : _
```

Next, let's ask for the 18th element of `list2`:

``` haskell
λ: list2 !! 17
38
λ: :sprint list1
list1 = 20 : 21 : 22 : 23 : 24 : 25 : 26 : 27 : 28 : 29 :
        30 : 31 : 32 : 33 : 34 : 35 : 36 : 37 : _
λ: :sprint list2
list2 = 21 : 22 : 23 : 24 : 25 : _ : _ : _ : _ : _ :
        _ : _ : _ : _ : _ : _ : _ : 38 : _
```

Now this is interesting.

Elements from the 6th to the 17th are fully evaluated in `list1` but
unevaluated in `list2`. Because of how `list1` is defined, it is going to be
evaluated in small, close-proximity increments from left to right. But all
values in `list2` are evaluated by applying a transformation on elements in
the corresponding positions in `list1`. That is why we are starting to see
gaps in `list2`.

This example really drives home the essence of lazy evaluation. By default,
Haskell will evaluate as little as possible, as late as possible. This is in
contrast to traditional, imperative programming languages which evaluate as
much as possible, as soon as possible.

Next, let's ask for the length of `list2`:

``` haskell
λ: length list2
51
λ: :sprint list1
list1 = [20,21,22,23,24,25,26,27,28,29,
         30,31,32,33,34,35,36,37,38,39,
         40,41,42,43,44,45,46,47,48,49,
         50,51,52,53,54,55,56,57,58,59,
         60,61,62,63,64,65,66,67,68,69,70]
λ: :sprint list2
list2 = [21,22,23,24,25,_,_,_,_,_,
         _,_,_,_,_,_,_,38,_,_,
         _,_,_,_,_,_,_,_,_,_,
         _,_,_,_,_,_,_,_,_,_,
         _,_,_,_,_,_,_,_,_,_,_]
```

At this point, `list1` is fully evaluated because there are no two ways around
it - in order to compute the length of `list2`, GHCi needs to keep track of
each and every one of its thunks, therefore it needs to generate the entire
"spine" of the list. The process of generating the thunks `(+1) 25` through
`(+1) 70` will require all elements of `list1` to be fully evaluated.

Finally, there is only one thing left for us to do such that `list2` is fully
evaluated too - compute the sum of its elements:

``` haskell
λ: sum list2
2346
λ: :sprint list2
list2 = [21,22,23,24,25,26,27,28,29,30,
         31,32,33,34,35,36,37,38,39,40,
         41,42,43,44,45,46,47,48,49,50,
         51,52,53,54,55,56,57,58,59,60,
         61,62,63,64,65,66,67,68,69,70,71]
```

### Conclusion

Laziness can be a tremendously helpful device for designing Haskell programs
that run in constant space and feature a clean separation of pure code vs.
side-effecting code. However, care must be taken to avoid what is known as
"space leaks", which we are going to cover in the next instalment of this
series.

### Editorial note

This blog post was inspired by chapter 2 of Simon Marlow's excellent book
["Parallel and Concurrent Programming in
Haskell"](http://chimera.labs.oreilly.com/books/1230000000929) which is
available both in e-book format as well as free of charge online.

### Update

In recent versions of GHC, due to the `Monomorphism Restriction` being off by
default (in contrast with the current ones) some of the examples might look a
little different. See [the discussion on
twitter](http://www.reddit.com/r/haskell/comments/1zfz5m/a_superficial_exploration_of_haskell_part_2_lazy/).
