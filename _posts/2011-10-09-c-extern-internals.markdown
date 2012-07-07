---
layout: post
date: 2011-10-09
title: C's extern internals
tags: [arrays, pointers, extern, c]
author: Daniel
---

The idea for this post came from [Virgil's][v-comment] comment on
[char\[\] versus char\*][old-art] entry. We will dig into some of
C's extern keyword internals by means of examples and then
analyze the differences between `extern char`\* and `extern char`\[\].

`extern` is a storage class specifier, indicating that the actual
storage of a variable or the definition of a function is located
elsewhere, typically in another source file.

<img style="float:right" src='./img/c-extern-simple-usage.png'
alt="C extern simple usage" width="227" height="263"/>


Let's start with a simple example:

**helper.c**

	int sample = 42; /* definition */

**main.c**

	extern int sample; /* declaration */
	int main(void)
	{
		printf("sample = %d\n", sample);
	}

Having obtained the corresponding object files `helper.o` and `main.o` we link them together
into an executable named `main`. We will use the [nm][man-nm] tool to check the symbols from
each object file:
<pre>
$ nm helper.o 
00000000 D sample
$ nm main.o
         U sample
00000000 T main
</pre>

Notice that the symbol `sample` is only declared in `main.c` but not defined there. In the linking phase, the linker searches throughout all
linked object files and finds out that the actual storage for `sample` is defined in `helper.c`. As a result our `main` executable will
print value `42` declared in `helper.c` external file:
<pre>
$./main 
sample = 42
</pre>

Now let's see how the compiler behaves if the types for cross-referenced variables do not match:

**foo.c**

	char *foo = "Hello";

**main.c**

	void foo(void);

	int main(void)
	{
		foo();
		return 0;
	}
<pre>
$ gcc -Wall -c foo.c -o foo.o
$ gcc -Wall -c main.c -o main.o
$ gcc -o main main.o foo.o
$ ./main
Segmentation fault

</pre>
Functions are by default extern, hence the declaration of symbol `foo` in `main.c`
file allows the compiler to create `main.o` object file without errors or warnings.
Anyhow, the linker does not check the type of symbol `foo`; thus, running the `main` executable results in a function call into an non-executable memory area.

Finally, let's analyze if we can use a pointer and an array interchangeably between
2 source files.

First try. The file `main.c` declares an extern array of chars, leaving it to the linker to find the actual
storage area defined for it. File `pointer.c` defines a pointer to a memory area
holding a string literal. At link time, the symbol `str` from `main.c` is bound to a memory area
representing the address of a string.

<img style="float:right" src='./img/c-extern-char.png'
alt="C extern simple usage" width="217" height="252"/>

**pointer.c**

	char *str = "1234";
	char a = 'A'; /* memory guards */
	char b = 'B';
	char c = 'C';

**main.c** 

	extern char str[];

	int main(void)
	{
		printf("%s\n", str);
		return 0;
	}


By compiling and linking `main.c` and `pointer.c` together we get `main` executable.
<pre>
$ ./main
\�ABC
</pre>
Notice how the array `str` is mapped to a memory area where an address is stored. The `printf`
function will display raw data until a `\0` is encountered. Fortunately, because of our
guarding arrays, printing stops after showing some garbage and string `ABC`.

Second try. The file `main.c` declares a pointer to a memory area holding one or more characters. The linker
will associate `str` from `main.o` with the storage defined by `str` array from `array.o`.

<img style="float:right" src='./img/c-extern-pointer.png'
alt="C extern simple usage" width="217" height="252"/>

**array.c**

	char str[] = "1234";

**main.c** 

	extern char *str;

	int main(void)
	{
		printf("%s\n", str);

		return 0;
	}

By compiling and linking together these programs we notice that running the `main` executable results in a crash.
<pre>
$ ./main
Segmentation fault
</pre>
Let's use GDB to see the reason:

<pre>
$gdb ./main
(gdb) b main
Breakpoint 1 at 0x8048385: file main2.c, line 6.
(gdb) run
Breakpoint 1, main () at main2.c:6
6		printf("%s\n", str);
(gdb) p str
$1 = 0x34333231 Address 0x34333231 out of bounds
</pre>

One can notice that the value of the pointer `str` is the content of array `str`. This content is an invalid address dereferenced by the pointer, resulting in the delivery of the dreaded `SIGSEGV` signal.

[v-comment]: http://techblog.rosedu.org/arrays-vs-pointers.html#IDComment189927033
[oldart]: http://techblog.rosedu.org/arrays-vs-pointers.html
[man-nm]: http://linux.die.net/man/1/nm
