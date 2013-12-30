---
date: 2011-12-18
title: Stack Allocation
author: Alexandru Juncu
tags: stack, sp, esp, C, assembly, cache, memory
---

**Stack space** is the part of each process' virtual memory where function
arguments and return addresses are stored, along with local variables declared
within a function. Usually, the stack begins at the high address space of the
virtual memory and grows down.

At every function call, a new **stack frame** is created on the stack. It
contains the parameters sent to the function, the return address (the
address of a code in the caller function) and the locally declared
variables.

For each function call, the **SP/ESP** (Stack Pointer/Extended Stack Pointer)
is set so the stack has a big enough size to accommodate local variables. For
example, in theory, if you have a local char variable and an int variable,
the SP should be set (moved) to 5 bytes.

In practice, the compiler will allocate stack space a little different than
expected. It will allocate local variables space in increments of a fixed
size, so sometimes having two int variables or three int variables will be
the same.

As an example, gcc will allocate in increments of 16 bytes. Let's make an
experiment... we take a simple C program and turn into assembly code.

The C file looks something like this:

	int main(void)
	{
		int a=1, b=2;
		return 0;
	}

The variables must be used after declaration or they will be ignored by the
compiler.

The resulting assembly code (with an gcc -S) looks like this:

	main:
		pushl	%ebp
		movl	%esp, %ebp
		subl	$16, %esp
		movl	$1, -4(%ebp)
		movl	$2, -8(%ebp)
		movl	$0, %eax
		leave
		ret

Notice the _subl_ instruction that clears 16 bytes in the stack space by
decrementing the ESP. Those 16 bytes are enough for four 32bit integers. If you
have 1,2,3 or 4 local variables declared (and used), you get those 16 bytes.

If we declare 5 integers, the allocated space will now be 32bytes. Same
thing for 6, 7, or 8. If we have 9 to 12 integers the compiler will
allocate 48 bytes. An so on...

What if we don't only have integers? Let's add some chars.

	int main(void)
	{
		int a=1, b=2;
		char c=3, d=4;
	}

Result:

	main:
		pushl	%ebp
		movl	%esp, %ebp
		subl	$16, %esp
		movl	$1, -8(%ebp)
		movl	$2, -12(%ebp)
		movb	$3, -1(%ebp)
		movb	$4, -2(%ebp)
		movl	$0, %eax
		leave
		ret

The function would need 10 bytes, but still gets 16. So the allocation is in
increments of 16 bytes no matter what.

The question remains why? It has to do with the cache alignment. The
compiler will try to structure the memory usage so that the executed code can
be easily fetched from memory and cached. A correct alignment will cause
minimum cache misses for memory access.

Credits to SofiaN for help with initial observations and tests.
