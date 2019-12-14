---
date: 2012-07-29
title: A Weird Behaviour Of C
author: Mihai Maruseac
tags: C, undefined behaviour, sequence points
---

Let us start from a common mistake made by programmers learning simple data
structures in C. The following code is an implementation for simple linked
lists of integers in C.

<!--more-->

``` cpp
#include <stdio.h>
#include <stdlib.h>

struct queue {
	int elm;
	struct queue* next;
};

struct queue* init()
{
	struct queue *q = calloc(1, sizeof(*q));
	q->next = q;
	return q;
}

void add(struct queue *q, int x)
{
	struct queue *n = calloc(1, sizeof(*n));
	struct queue *head = q;

	n->elm = x;
	n->next = head;
	while (q->next != head)
		q = q->next;
	q->next = n;
}

int pop(struct queue *q)
{
	int x = q->next->elm;
	struct queue *tmp = q->next;
	q->next = tmp->next;
	free(tmp);
	return x;
}

void free_q(struct queue *q)
{
	struct queue *tmp;
	while (q->next != q) {
		tmp = q->next;
		free(q);
		q = tmp;
	}
	free(q);
}

int main()
{
	struct queue *q = init();
	add(q, 4);
	add(q, 2);
	printf("%d%d\n", pop(q), pop(q));
	free_q(q);
	return 0;
}
```

The idea is simple: we insert `4` and `2` into the queue and expect the output
to be `42`, the digits being output in the order of their insertion into the
queue.

However, running the program, we have a big surprise:

    $ gcc -Wall -Wextra 1.c -g -o 1-gcc
    $ clang -Wall -Wextra 1.c -g -o 1-clang
    $ ./1-gcc 
    24
    $ ./1-clang 
    42

Let's ignore for now the fact that [clang][clang] gives the correct response
and let's answer this question: What went wrong? The queue implementation
seems correct but let's replace it by a dummy implementation:

``` cpp
#include <stdio.h>
#include <stdlib.h>

int x;

int inc()
{
	x++;
	return x;
}

int dec()
{
	x--;
	return x;
}

int main()
{
	inc();
	inc();
	printf("%d%d\n", dec(), dec());
	return 0;
}
```

Basically, we have removed the queue and replaced it by it's length, stored in
the global `x` variable. The expected output is `10`.

    $ clang -Wall -Wextra 2.c -g -o 2-clang
    $ gcc -Wall -Wextra 2.c -g -o 2-gcc
    $ ./2-gcc 
    01
    $ ./2-clang 
    10

The output is consistent with the above example. Thus, the problem is not in
our queue implementation. It must be somewhere else.

Before starting to shout that `printf` or `gcc` or `clang` is buggy, let us
read [the C standard][std]:

> **unspecified behavior**:
>   use of an unspecified value, or other behavior where this International
>   Standard provides two or more possibilities and imposes no further
>   requirements on which is chosen in any instance
>
> **EXAMPLE**
>   An example of unspecified behavior is the order in which the arguments to a
>   function are evaluated.

This explains why the two compilers were allowed to give different results,
while being both correct.

If we want more informations, we can compare the generated assembly code of
the two compilers. The `gcc` version is below (only the relevant snippet):

    call    inc
    movl    $0, %eax
    call    inc
    movl    $0, %eax
    call    dec
    movl    %eax, %ebx
    movl    $0, %eax
    call    dec
    movl    %eax, %ecx
    movl    $.LC0, %eax
    movl    %ebx, %edx
    movl    %ecx, %esi
    movq    %rax, %rdi
    movl    $0, %eax
    call    printf

For comparation, the `clang` version is:

    callq   inc
    movl    %eax, -8(%rbp)          # 4-byte Spill
    callq   inc
    movl    %eax, -12(%rbp)         # 4-byte Spill
    callq   dec
    movl    %eax, -16(%rbp)         # 4-byte Spill
    callq   dec
    leaq    .L.str, %rdi
    movl    -16(%rbp), %esi         # 4-byte Reload
    movl    %eax, %edx
    movb    $0, %al
    callq   printf

The understanding of the assembly code is left as an exercise to the reader.
It is easy to see that `clang` uses the stack to store the results.

Both snippets were obtained using no optimization. As an exercise, try to
observe the effect of each optimization level on the generated code and
explain it.

Let's go on. In the above snippet we have used functions to increment and
decrement the global value. Let us rewrite that code:

``` cpp
#include <stdio.h>
#include <stdlib.h>

int main()
{
	int x = 0;
	x++;
	x++;
	printf("%d%d\n", --x, --x);
	return 0;
}
```

Here, we have another suprise:

    $ ./3-gcc 
    00
    $ ./3-clang 
    10

The `gcc` version printed only the final value of `x`, twice. Clearly, there
is something happening here. Let's look closer.

Looking at the generated assembly, we see that `gcc` generated this code:

    movl    $0, -4(%rbp)
    addl    $1, -4(%rbp)
    addl    $1, -4(%rbp)
    subl    $1, -4(%rbp)
    subl    $1, -4(%rbp)
    movl    $.LC0, %eax
    movl    -4(%rbp), %edx
    movl    -4(%rbp), %ecx
    movl    %ecx, %esi
    movq    %rax, %rdi
    movl    $0, %eax
    call    printf

On the other hand, `clang` generated:

    movl    -8(%rbp), %eax
    addl    $1, %eax
    movl    %eax, -8(%rbp)
    movl    -8(%rbp), %eax
    addl    $1, %eax
    movl    %eax, -8(%rbp)
    movl    -8(%rbp), %eax
    addl    $4294967295, %eax       # imm = 0xFFFFFFFF
    movl    %eax, -8(%rbp)
    movl    -8(%rbp), %ecx
    addl    $4294967295, %ecx       # imm = 0xFFFFFFFF
    movl    %ecx, -8(%rbp)
    movl    %eax, %esi
    movl    %ecx, %edx
    movb    $0, %al
    callq   printf

One can easily see that `gcc` did the operations on `x` before starting the
function call sequence while `clang` interleaved stack operations with
operations on `x` such that the output is the one we would expect. Not to
mention the fact that substraction was replaced by addition.

However, what allows the compilers to do this? Luckily, we have compiled with
warnings on:

    $ clang -Wall -Wextra 3.c -g -o 3-clang
    $ gcc -Wall -Wextra 3.c -g -o 3-gcc
    3.c: In function ‘main’:
    3.c:9:24: warning: operation on ‘x’ may be undefined [-Wsequence-point]

Reading the standard for sequence points we get:

> Evaluation of an expression may produce side effects. At certain specified
> points in the execution sequence called sequence points, all side effects of
> previous evaluations shall be complete and no side effects of subsequent
> evaluations shall have taken place.

Reading further, we see that it is an **undefined behaviour** if:

> Between two sequence points, an object is modified more than once, or is
> modified and the prior value is read other than to determine the value to be
> stored.

Lastly, the standard defines a sequence point to be (among other more complex
constructs):

* a call of a function
* end of the first operand or `&&`, `||`, `?` and `,`

Thus, our side effects in the `printf` function cause undefined behaviour and
unspecified behaviour. Depending on the compiler, the results can be very
different. This harms portability and should be avoided.

Before finishing the article, let's see another example, using different
constructs:

``` cpp
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

int main()
{
	int x = INT_MAX;
	void *p = &x;

	printf("%d %d\n", x, x + 1);
	printf("%p %p\n", p, p + 1);

	return 0;
}
```

The possible outputs of this code and the reasoning behind are left as an
exercise. Use the comments area to provide solutions for all exercises left in
this article.

As a rule of thumb, try to limit the use of side effects inside a function
call. You don't know when you'll fall into this trap again.

[clang]: http://clang.llvm.org/ "clang"
[std]: http://www.open-std.org/jtc1/sc22/wg14/www/standards "C standards"
