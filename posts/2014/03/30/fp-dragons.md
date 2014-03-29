---
date: 2014-03-30
title: Here be Dragons - The Interesting Realm of Floating Point Operations
author: Mihai Maruseac
tags: floating point, numerical methods, approximate algorithms, fast transcedental functions, fast inverse square root
---

In every programmer's life there comes a time when he has to leave the realm
of integers and tread into the dangerous land of rational numbers. He/she
might do some scientific computation, or work on a financial application or a
game rendering pipeline or even in some artificial intelligence or data-mining
algorithm -- in all of these cases and many others, restricting oneself to
using only integers is no longer feasible.

And, as soon as one starts using floating point a lot of interesting things
happen, starting from results which don't show up nicely and bad equality
testing and going towards subtler and subtler bugs.

<img src="http://imgs.xkcd.com/comics/e_to_the_pi_minus_pi.png" alt="e to pi
minus pi" title="e to pi minus pi">

Even experts and common-sense is at fault in this realm. For example, did you
know that comparing two floating points like in the following code is *bad*?

~~~ c
if (fabs(a - b) < 0.0001)
    do_something_with_equal_numbers(a);
~~~

Without being a complete guide, this article shows some of the beauties and
dangers of the floating-point realm.

<!--more-->

### Common problems and pitfalls

#### Why numbers don't add up correctly?

#### The "e to pi minus pi" comic explained

#### Equality testing

### The floating point standard

### A Strange Arithmetic

#### The Associativity Problem

#### Rounding and Error Propagation

#### Equality testing done right

### The Three Aspects: Determinism, Correctness and Fastness

#### Focusing on Determinism

#### Focusing on Correctness

#### Focusing on Fastness

##### Fast Inverse Square

##### Transcendental Operations

### Conclusions

This article is quite a long one and filled with seemingly disjoint pieces of
information. They are but mere glimpses into the dangers of using floating
point arithmetic without considering all of the aspects involved with it. For
a more comprehensive reading the obligatory [Oracle Appendix D][fp] is
essential but it is filled with mathematical formulas and equations which are
daunting to the less brave readers. Some more details can be found in [The
Floating Point Guide][fpguide].

[xkcd]: http://www.xkcd.com/217/ "e to pi minus pi"
[fp]: http://docs.oracle.com/cd/E19957-01/806-3568/ncg_goldberg.html "What Every Computer Scientist Should Know About Floating-Point Arithmetic"
[fpguide]: http://floating-point-gui.de/ "The Floating Point Guide"
