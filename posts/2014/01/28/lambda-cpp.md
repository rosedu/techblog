---
date: 2014-01-28
title: Lambda Functions in C++
author: Mădălina-Andreea Grosu, Matei Oprea
tags: lambda, higher-order functions, c++
---

The C++ 2011 standard introduced the lambda expression syntax element causing
some people ask [why it was needed][1]. In reality, it was not a new use case,
people have been using this under different names since C was created. You had
functors (C++ terminology) and pointer to functions for example. A basic
use case was in applying the same transform over all elements of a collection
(the functor's widely shared example) or sorting elements of a vector (via
`qsort` in C). But, in reality, all of these cases can be reduced to using
_higher-order functions_.

<!--more-->

### 1. Higher-order functions

A high-order function is a function that takes one or more functions as an
input and outputs a function. For example, we can use this higher-order
functions to map, filter, fold and sort lists.

Let's start with a simple example of a high-order function, in Haskell:

``` haskell
zipWith1 :: (a -> b -> c) -> [a] -> [b] -> [c]
zipWith1 _ [] _ = []
zipWith1 _ _ [] = []
zipWith1 f (x:xs) (y:ys) = f x y : zipWith1 f xs ys
```

This function will take a function and two lists as parameters and then joins
them by applying the function between corresponding elements.  Let's see a
little demonstration for the function written above:

``` haskell
ghci> zipWith1 (+) [1,2,3,4] [5,6,7,8]
[6,8,10,12]
```

So we found out what a [higher-order function is][2]. Now, what is a lambda
function? The term comes from the Lambda Calculus and refers to anonymous
functions in programming. With a lambda function you can write quick functions
without naming them.

Let's see the above function written using lambdas:

``` haskell
zipWith (\x y -> x + y ) [1,2,3,4] [5,6,7,8]
```

If we run this function in GHCi the result will be the same as above:

``` haskell
Prelude> zipWith (\x y -> x + y ) [1,2,3,4] [5,6,7,8]
[6,8,10,12]
```

Now, to see the equivalence, the following functions are one and the same:

``` haskell
f x y = x + y
f x = \y -> x + y
f = \x y -> x + y
```

Now, we know what is a lambda function and a higher-order function. Let's see
how can we use lambda functions in C++.

### 2. Lambdas in C++

A lambda function, in C++, starts with `[` and it has a specific syntax:

``` cpp
[capture] (params) -> return_type { function_body }
```

Let's see a short example of a lambda function in C++:

``` cpp
[](int x, int y) -> int { return x * y; }
```

This function simply multiplies two integers.

Consider now the following Haskell example of applying a function to a list,
using `map`:

``` haskell
map (\x -> x + 1) [1, 2, 3]
```

In C++, we have the [function transform][3] which does the same thing as the
`map` function from Haskell:

``` cpp
#include <iostream>
#include <algorithm>
#include <vector>

using namespace std;

int main (){
    /* declare 2 vectors */
    vector <int> vector1;
    vector <int> vector2;

    /* pseudo-pseudo-random values */
    for (int i=1;i<4;i++)
        vector1.push_back (i);

    /* alocate memory in vector2 */
    vector2.resize(vector1.size());

    /* applies our lambda function for each element
     * in vector1 and stores it in vector2
     */
    transform (vector1.begin(), vector1.end(), vector2.begin(),
        [] (int i) { return ++i; });

    /* output the result */
    cout << “Vector2 contains: “;
    for (std::vector<int>::iterator it=vector2.begin();
        it!=vector2.end(); ++it)
        std::cout << ' ' << *it;

    return 0;
}
```

And the output is:

    Vector2 contains: 2 3 4

You can see that our result is the same as in Haskell. We used a lambda
function to increment the value for the each element from the first vector and
then we printed it to standard output.

### 3. Conclusions

So, why you should use lambda functions ?

* You can write fast functions and use them in your production code
* You can replace macros (because macros are evil -- citation needed)
* Because $\lambda$ rocks
* Because you can use it when you want a short-term functionality that you do
  not want to have to name

[1]: http://stackoverflow.com/questions/7627098/what-is-a-lambda-expression-in-c11 "What is a lambda expression in C++?"
[2]: http://learnyouahaskell.com/higher-order-functions "Learn You A Haskell"
[3]: http://www.cplusplus.com/reference/algorithm/transform/ "Function transform"
