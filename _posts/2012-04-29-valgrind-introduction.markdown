---
layout: post
date: 2012-04-29
title: "Valgrind introduction"
tags: [valgrind]
author: Mihai
---

A good programmer has a variety of tools to help him in developing good
applications. We talked about [gdb][] in an [article][tgdb] at the beginning
of April. Now, it is time for a crash introduction to [Valgrind][valgrind].

This program is a collection of different tools. For example, it offers a
[heap profiler][massif], a [thread error detector][helgrind] or a [cache
profiler][cachegrind]. However, the tool which gave [Valgrind][valgrind]'s
fame is [Memcheck][memcheck], a memory error detector. Because of its
popularity, this tool is the default one (to use other [Valgrind][valgrind]
tools you have to use the `--tool=option` command line argument). In this
article, we will concentrate on [Memcheck][memcheck] only.

### Detecting memory leaks

Mainly, one would use [Valgrind][valgrind] to detect memory leaks in his
application. By this, we mean memory which was allocated but wasn't released
back. For example, take this program:

{% highlight cpp %}
void f()
{
    int *a = calloc(1024, sizeof(a[0]));
}

int main()
{
    int i;

    for (i = 0; i < 1024; i++)
        f();

    return 0;
}
{% endhighlight %}

This program allocates `sizeof(int)` MB of memory and doesn't free them. Of
course, at the end of the execution, the operating systems takes care of
releasing this memory. However, suppose that the `f` function was instead
called from a server executable which shouldn't be stopped. In this case, each
invocation of `f` will eat away `sizeof(int)` KB memory (depending on
architecture, 4KB or 8KB).

The example is simple, the problem could be observed with naked eyes. However,
let's see what [Valgrind][valgrind] tells us:

    ==11418== Memcheck, a memory error detector
    ==11418== Copyright (C) 2002-2011, and GNU GPL'd, by Julian Seward et al.
    ==11418== Using Valgrind-3.7.0 and LibVEX; rerun with -h for copyright info
    ==11418== Command: ./a.out
    ==11418==
    ==11418==
    ==11418== HEAP SUMMARY:
    ==11418==     in use at exit: 4,194,304 bytes in 1,024 blocks
    ==11418==   total heap usage: 1,024 allocs, 0 frees, 4,194,304 bytes allocated
    ==11418==
    ==11418== LEAK SUMMARY:
    ==11418==    definitely lost: 4,194,304 bytes in 1,024 blocks
    ==11418==    indirectly lost: 0 bytes in 0 blocks
    ==11418==      possibly lost: 0 bytes in 0 blocks
    ==11418==    still reachable: 0 bytes in 0 blocks
    ==11418==         suppressed: 0 bytes in 0 blocks
    ==11418== Rerun with --leak-check=full to see details of leaked memory
    ==11418==
    ==11418== For counts of detected and suppressed errors, rerun with: -v
    ==11418== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 3 from 3)

The number that gets repeated on each line of the output is the PID of our
executable. At the end of the run, we are offered a heap summary (from where
we can see that our program allocated 4MB of memory) and a leak summary.

Let's see what happens after we take into account the suggestion to run with
`--leak-check=full`. First, we compile the program adding debugging
information, using the `-g` [GCC][gcc] flag. And, then, we run the executable under
[Valgrind][valgrind]:

    mihai@keldon:/tmp/mm/valgrind$ valgrind --leak-check=full ./a.out
    ==11527== Memcheck, a memory error detector
    ==11527== Copyright (C) 2002-2011, and GNU GPL'd, by Julian Seward et al.
    ==11527== Using Valgrind-3.7.0 and LibVEX; rerun with -h for copyright info
    ==11527== Command: ./a.out
    ==11527==
    ==11527==
    ==11527== HEAP SUMMARY:
    ==11527==     in use at exit: 4,194,304 bytes in 1,024 blocks
    ==11527==   total heap usage: 1,024 allocs, 0 frees, 4,194,304 bytes allocated
    ==11527==
    ==11527== 4,194,304 bytes in 1,024 blocks are definitely lost in loss record 1 of 1
    ==11527==    at 0x4C29024: calloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==11527==    by 0x4004F2: f (1.c:6)
    ==11527==    by 0x400513: main (1.c:14)
    ==11527==
    ==11527== LEAK SUMMARY:
    ==11527==    definitely lost: 4,194,304 bytes in 1,024 blocks
    ==11527==    indirectly lost: 0 bytes in 0 blocks
    ==11527==      possibly lost: 0 bytes in 0 blocks
    ==11527==    still reachable: 0 bytes in 0 blocks
    ==11527==         suppressed: 0 bytes in 0 blocks
    ==11527==
    ==11527== For counts of detected and suppressed errors, rerun with: -v
    ==11527== ERROR SUMMARY: 1 errors from 1 contexts (suppressed: 3 from 3)

This time, we see that the memory was allocated in line 6 in function `f`.
This allows us to insert the needed `free` at the correct spot.

**Quick question**: what would have happened if our program was compiled with
optimizations on (try `-O3` for example)?

### Wrong cases of memory release

What happens when we free the same memory address twice? Let's use this
program:

{% highlight cpp %}
void *f()
{
	int *a = calloc(16, sizeof(a[0]));
	free(a);
	return a;
}

int main()
{
	int *a = f();
	free(a);
	return 0;
}
{% endhighlight %}

Running it with [Valgrind][valgrind] yields:

    mihai@keldon:/tmp/mm/valgrind$ valgrind ./a.out
    ==11734== Memcheck, a memory error detector
    ==11734== Copyright (C) 2002-2011, and GNU GPL'd, by Julian Seward et al.
    ==11734== Using Valgrind-3.7.0 and LibVEX; rerun with -h for copyright info
    ==11734== Command: ./a.out
    ==11734==
    ==11734== Invalid free() / delete / delete[] / realloc()
    ==11734==    at 0x4C29A9E: free (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==11734==    by 0x40057A: main (1.c:14)
    ==11734==  Address 0x51d2040 is 0 bytes inside a block of size 64 free'd
    ==11734==    at 0x4C29A9E: free (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==11734==    by 0x400552: f (1.c:7)
    ==11734==    by 0x40056A: main (1.c:13)
    ==11734==
    ==11734==
    ==11734== HEAP SUMMARY:
    ==11734==     in use at exit: 0 bytes in 0 blocks
    ==11734==   total heap usage: 1 allocs, 2 frees, 64 bytes allocated
    ==11734==
    ==11734== All heap blocks were freed -- no leaks are possible
    ==11734==
    ==11734== For counts of detected and suppressed errors, rerun with: -v
    ==11734== ERROR SUMMARY: 1 errors from 1 contexts (suppressed: 3 from 3)

We can see both locations where the memory was released.

Now, consider this C++ code, a tweaked version of the above:

{% highlight cpp %}
int *f()
{
	int *a = (int *)calloc(16, sizeof(a[0]));
	return a;
}

int main()
{
	int *a = f();
	delete a;
	return 0;
}
{% endhighlight %}

Running under [Valgrind][valgrind], we receive the following output (we will
use `-q` to show only the errors reported by Valgrind -- no header and no
statistics at the end):

    mihai@keldon:/tmp/mm/valgrind$ valgrind -q ./a.out
    ==11757== Mismatched free() / delete / delete []
    ==11757==    at 0x4C2972C: operator delete(void*) (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==11757==    by 0x400659: main (1.c:13)
    ==11757==  Address 0x59e0040 is 0 bytes inside a block of size 64 alloc'd
    ==11757==    at 0x4C29024: calloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==11757==    by 0x400632: f() (1.c:6)
    ==11757==    by 0x400649: main (1.c:12)

Before finishing this section, let's consider the case of freeing from inside
an allocated block. See this code:

{% highlight cpp %}
void *f()
{
	int *a = calloc(16, sizeof(a[0]));
	return a + 4;
}

int main()
{
	int *a = f();
	free(a);
	return 0;
}
{% endhighlight %}

[Valgrind][valgrind] gives the following output:

    mihai@keldon:/tmp/mm/valgrind$ valgrind -q ./a.out
    ==11765== Invalid free() / delete / delete[] / realloc()
    ==11765==    at 0x4C29A9E: free (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==11765==    by 0x400572: main (1.c:13)
    ==11765==  Address 0x51d2050 is 16 bytes inside a block of size 64 alloc'd
    ==11765==    at 0x4C29024: calloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==11765==    by 0x400542: f (1.c:6)
    ==11765==    by 0x400562: main (1.c:12)

From this we can easily see that we tried to free from inside an allocated
block instead of using the block's address. Moreover, we find where the block
was allocated and we can fix our program now.

### Incorrect usage of memory

Let's see this simple code:

{% highlight cpp %}
struct s {
	int a, b;
};

int main()
{
	struct s s;
	s.a = 42;
	if (s.b)
		printf("s.b\n");
	return 0;
}
{% endhighlight %}

We didn't initialize `s.b`. [Valgrind][valgrind] reports this:

    mihai@keldon:/tmp/mm/valgrind$ valgrind -q ./a.out
    ==11868== Conditional jump or move depends on uninitialised value(s)
    ==11868==    at 0x4004F0: main (1.c:12)
    ==11868==

This was simple. Now, consider this common case:

{% highlight cpp %}
int main()
{
	char *s = strdup("Valgrind rocks");
	char *q = malloc(strlen(s));
	strcpy(q, s);
	return 0;
}
{% endhighlight %}

This code looks perfectly valid. Does it? [Valgrind][valgrind] says otherwise:

    mihai@keldon:/tmp/mm/valgrind$ valgrind -q ./a.out
    ==12038== Invalid write of size 1
    ==12038==    at 0x4C2B27F: strcpy (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==12038==    by 0x4005FC: main (1.c:9)
    ==12038==  Address 0x51d209e is 0 bytes after a block of size 14 alloc'd
    ==12038==    at 0x4C2A93D: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==12038==    by 0x4005E5: main (1.c:8)

Indeed, we missed space for the `\0` terminating character. Suppose we do this
fix: we change `strcpy(q, s)` with `strcpy(q, s + 1)`. This works.

Now, let us assume that -- by mistake -- we also change `q`:

{% highlight cpp %}
int main()
{
	char *s = strdup("Valgrind rocks");
	strcpy(s, s + 1);
	return 0;
}
{% endhighlight %}

[Valgrind][valgrind] is prompt to show us that we use `strcpy` in a wrong way,
possibly destroying content:

    mihai@keldon:/tmp/mm/valgrind$ valgrind -q ./a.out
    ==12058== Source and destination overlap in strcpy(0x51d2040, 0x51d2041)
    ==12058==    at 0x4C2B2F5: strcpy (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==12058==    by 0x400600: main (1.c:9)

But what if that was the indented behaviour? What if we really needed to
remove the first letter of `s`?

We can generate a suppression and use it in other calls of
[Valgrind][valgrind] to ignore this error. To generate it, we use another
flag:

    mihai@keldon:/tmp/mm/valgrind$ valgrind --gen-suppressions=yes -q ./a.out
    ==12079== Source and destination overlap in strcpy(0x51d2040, 0x51d2041)
    ==12079==    at 0x4C2B2F5: strcpy (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)
    ==12079==    by 0x400600: main (1.c:9)
    ==12079==
    ==12079==
    ==12079== ---- Print suppression ? --- [Return/N/n/Y/y/C/c] ---- y
    {
       <insert_a_suppression_name_here>
       Memcheck:Overlap
       fun:strcpy
       fun:main
    }

We copy the printed lines into a file, `strcpy_main.supp`:

    {
       strcpy_main
       Memcheck:Overlap
       fun:strcpy
       fun:main
    }

When we run [Valgrind][valgrind] again, we will use this file to ignore that
error.

    mihai@keldon:/tmp/mm/valgrind$ valgrind --suppressions=strcpy_main.supp -q ./a.out
    mihai@keldon:/tmp/mm/valgrind$

Even though this works, we should not use `strcpy` with overlapping arguments.
The manual page for `strcpy` tells:

    The  strcpy()  function  copies  the  string pointed to by src, including
    the terminating null byte ('\0'), to the buffer pointed to by dest. The
    strings may not overlap, and the destination string dest must be large
    enough to receive the copy.

One last word before finishing this article. If your program has too many
errors, [Valgrind][valgrind] tries to be funny and gives the following
message:

    ==21573== More than 10000000 total errors detected.  I'm not reporting any more.
    ==21573== Final error counts will be inaccurate.  Go fix your program!

You should do this, of course.

In a later article we will show how can you combine [Valgrind][valgrind] and
[GDB][gdb] to fix some nasty bugs. But until then, remember how to use
[Memcheck][memcheck] and keep in mind that [Valgrind][valgrind] has many
useful tools and a programmer can create others if he needs them.

[cachegrind]: http://valgrind.org/docs/manual/cg-manual.html
[gcc]: http://gcc.gnu.org/
[gdb]: http://sources.redhat.com/gdb/
[helgrind]: http://valgrind.org/docs/manual/hg-manual.html
[massif]: http://valgrind.org/docs/manual/ms-manual.html
[memcheck]: http://valgrind.org/docs/manual/mc-manual.html
[tgdb]: http://techblog.rosedu.org/gdb-a-basic-workflow.html
[valgrind]: http://valgrind.org/

