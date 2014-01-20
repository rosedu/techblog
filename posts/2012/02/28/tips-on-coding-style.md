---
date: 2012-02-28
title: Tips on coding style
author: Alexandru Juncu
tags: C, coding style, linux, checkpatch.pl
---

Good programmers know that writing code is more than just... writing code.
It's more than writing efficient code... It's also about writing good code
with respect to the ones that are going to read and/or use that code. This
is specially true in open source communities where potentially hundreds of
people could be looking at your code. You have to write code that can be
easily read and used by others. And to do that, you need some some sort of
standards of code writing. This is where the idea of **coding styles**
comes in.

<!--more-->

Every software project has its (hopefully properly defined) coding style. It
can depend a lot on the programming language that the project uses. The
style can specify the indentation, the variable naming, the use of spaces
or the use of curly braces.

For example, the Linux Kernel has its coding style well defined in the
[Documentation pages](http://www.kernel.org/doc/Documentation/CodingStyle).
It is based on the Kernighan & Ritchie (K&R) style, the Linux Kernel being
written in C. This is a very popular coding style with several projects
using it, sometimes considered the de facto coding style for C.

If you want to check if your code follows the coding style of Linux, you
can use `checkpatch.pl`. This script can be found in the source code of
the Linux Kernel in the scripts directory. It is mainly used for checking
patches submitted for Linux, but it can be used on normal C source fies
using the `-f` parameter. You need to clone the Linux tree to get the
script, and you need to run it from the root of the tree.

Here is an example of badly written code:

~~~ cpp
  1
  2 int main(void)···
  3 {
  4    int i,a;···
  5 »       »       
  6    for(i=0;i<10;i++)
  7       a=i;
  8    //this code is useless
  9    if(a==i){
 10    return 0;
 11    }
 12
 13    return 0;
 14 }·····
~~~

Note that the · character would represent a space and » would represent a
tab. Spaces would represent... spaces.

And this is what checkpatch would report:

    alexj@ixmint ~/linux $ scripts/checkpatch.pl -f bad.c
    ERROR: trailing whitespace
    #2: FILE: bad.c:2:
    +int main(void)   $

    ERROR: trailing whitespace
    #4: FILE: bad.c:4:
    +   int i,a;   $

    WARNING: please, no spaces at the start of a line
    #4: FILE: bad.c:4:
    +   int i,a;   $

    ERROR: space required after that ',' (ctx:VxV)
    #4: FILE: bad.c:4:
    +   int i,a;   
    	 ^

    ERROR: trailing whitespace
    #5: FILE: bad.c:5:
    +^I^I$

    WARNING: please, no spaces at the start of a line
    #6: FILE: bad.c:6:
    +   for(i=0;i<10;i++)$

    WARNING: suspect code indent for conditional statements (3, 6)
    #6: FILE: bad.c:6:
    +   for(i=0;i<10;i++)
    +      a=i;

    ERROR: spaces required around that '=' (ctx:VxV)
    #6: FILE: bad.c:6:
    +   for(i=0;i<10;i++)
    	 ^

    ERROR: space required after that ';' (ctx:VxV)
    #6: FILE: bad.c:6:
    +   for(i=0;i<10;i++)
    	   ^

    ERROR: spaces required around that '<' (ctx:VxV)
    #6: FILE: bad.c:6:
    +   for(i=0;i<10;i++)
    	     ^

    ERROR: space required after that ';' (ctx:VxV)
    #6: FILE: bad.c:6:
    +   for(i=0;i<10;i++)
    		^

    ERROR: space required before the open parenthesis '('
    #6: FILE: bad.c:6:
    +   for(i=0;i<10;i++)

    WARNING: please, no spaces at the start of a line
    #7: FILE: bad.c:7:
    +      a=i;$

    ERROR: spaces required around that '=' (ctx:VxV)
    #7: FILE: bad.c:7:
    +      a=i;
    	^

    WARNING: please, no spaces at the start of a line
    #8: FILE: bad.c:8:
    +   //this code is useless$

    ERROR: do not use C99 // comments
    #8: FILE: bad.c:8:
    +   //this code is useless

    WARNING: please, no spaces at the start of a line
    #9: FILE: bad.c:9:
    +   if(a=i){$

    WARNING: suspect code indent for conditional statements (3, 3)
    #9: FILE: bad.c:9:
    +   if(a=i){
    +   return 1;

    ERROR: spaces required around that '=' (ctx:VxV)
    #9: FILE: bad.c:9:
    +   if(a=i){
    	^

    ERROR: space required before the open brace '{'
    #9: FILE: bad.c:9:
    +   if(a=i){

    ERROR: space required before the open parenthesis '('
    #9: FILE: bad.c:9:
    +   if(a=i){

    ERROR: do not use assignment in if condition
    #9: FILE: bad.c:9:
    +   if(a=i){

    WARNING: braces {} are not necessary for single statement blocks
    #9: FILE: bad.c:9:
    +   if(a=i){
    +   return 1;
    +   }

    WARNING: please, no spaces at the start of a line
    #10: FILE: bad.c:10:
    +   return 1;$

    WARNING: please, no spaces at the start of a line
    #11: FILE: bad.c:11:
    +   }$

    WARNING: please, no spaces at the start of a line
    #13: FILE: bad.c:13:
    +   return 0$

    ERROR: trailing whitespace
    #14: FILE: bad.c:14:
    +}     $

    total: 16 errors, 11 warnings, 14 lines checked

    NOTE: whitespace errors detected, you may wish to use scripts/cleanpatch or
          scripts/cleanfile

    bad.c has style problems, please review.

Most of the errors are regarding whitespaces, space or tab characters that
shouldn't be there. It's hard to spot spaces or tabs because they are
invisible. But a good tip is to make them visible in your editor. Visually
replacing characters will not modify the source (spaces will still be
spaces) but they will pop up in your editor so you know to delete them.
For example, in `vi` you can use this (credits to Vlad Dogaru for it):

    set list listchars=tab:»\ ,trail:·,extends:»,precedes:«

Other warnings come from the fact that indentation was made with 3 spaces
and not 8. Tabs and spaces should be used consistently. For example, you
can set in vi the 'width' of a tab with:

    :set tabstop=8

There are places where you don't want spaces, but there are situations where
you do want them. You should leave a space after keywords like `if` or
`for` and around operators like `=`. Doing this makes the code a lot
more readable.

Curly braces should be used, but only when needed. If an `if` has only
one instruction to be executed on the branch, it is pointless to have
braces enclosing it. Indentation is enough to mark the instruction.

Comment types are a delicate subject. The classic C specification only
allows `/* */` block comments. C99 allows `//` as one line comments. Some
coding styles (like the Linux coding style) don't allow C99 comments.

This is the way the code **should** look like with proper coding style:

~~~ cpp
  1 int main(void)
  2 {
  3 »       int i, a;
  4 
  5 »       for (i = 0; i < 10; i++)
  6 »       »       a = i;
  7 »       /* This code is useless */
  8 »       if (a == i)
  9 »       »       return 1;
 10 
 11 »       return 0;
 12 }
~~~

Other programing languages can have similar coding guidelines. For Python,
there is [PEP](http://www.python.org/dev/peps/pep-0008/), as dictated by
the creator of Python himself.

But we should always keep in mind that there is no One True Coding Style.
Like all great debates, everybody could argue that one is better than
another. What is important and everybody (mostly) agrees is to have
consistency within a project in regards to the code the community writes.
