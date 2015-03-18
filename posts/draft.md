---
date: 2015-03-20
title: Application process for the Community Development Lab
author: Alex Palcuie
tags: algorithms
---

The Community and Development Lab is a traditional yearly ROSEdu project where we teach students how to start contributing to open source software. This year we had 117 applicants and had to select only 19 of them. To do this, we gave them an algorithm problem to filter some of them and did 60 interviews.

<!--more-->

In the Community and Development Lab students have the chance to come once a week for 9 weeks and learn real industry skills. Every week, there is a 2 hour presentation about different topics, like Linux, Git, Python, OOP, Raspberry Pi, and then for another 2 hours they stay with an assigned mentor and write patches for open source projects.

To select the best students, we gave the students to solve an ACM style algorithm problem on the [Infoarena](http://www.infoarena.ro/) judge. They had to code their solution in C, C++ or Java, submit it online and the judge would run it over 10 tests, checking the output and measuring the time and memory their solution took. Most of the students who tried to solve this problem were in their 1st and 2nd undergraduate years at Computer Science or Computer Engineering in Bucharest.

## Problem Statement

_You can read the Romanian version on [Infoarena](http://www.infoarena.ro/problema/convertor)_

Ada, Calin and Andrei have got bored of learning algorithms at their University and want to learn more practical stuff. To do this, they have decided to apply at ROSEdu CDL. However, the organisers cannot separate the applicants, so they decided to give an algorithm problem for them to solve. Luckily, you don't need lots of knowledge about time complexities

You are given a JSON file that contains a list of objects. Every object contains a list of entries of key-value type, where the value can be a string or an integer. You have to transform it into a CSV.

### Restrictions

* Every JSON line will contain maximum 1.024 characters.
* You have maximum 0.1s of time for every test on a dual core 2.93GHz
* You have maximum 4.906 kbytes of memory for each test

Example input:

```json
[{
"id": 1,
"language": "Ruby",
"usage": "Mainly by hipsters.",
"power": 4
}, {
"id": 2,
"language": "Python",
"usage": "Computer scientists and some wannabe hipsters.",
"power": 2
}, {
"id": 3,
"language": "C++",
"usage": "Hardcore people who love dangling pointers.",
"power": 100
}, {
"id": 4,
"language": "Haskell",
"usage": "A lonely dude in Massachussets.",
"power": 999999
}]
```

Example output:

```csv
id,language,usage,power,
1,Ruby,Mainly by hipsters.,4,
2,Python,Computer scientists and some wannabe hipsters.,2,
3,C++,Hardcore people who love dangling pointers.,100,
4,Haskell,A lonely dude in Massachusetts.,999999,
```

However, since we want to simulate a real life problem better, the JSON file won't be beautifully formatted. But, we guarantee it will be correct.

```json
[ { "name": "Ruby on Rails", "commits": 49507, "contributors": 429,
"last commit" : "an hour ago" }, {"name": "jQuery", "commits":  5745,
"contributors" : 213, "last commit":  "4 days ago" }, {"name": "React",
"commits" : 3557,  "contributors": 288, "last commit": "5 hours ago"} ]
```

```csv
name,commits,contributors,last commit,
Ruby on Rails,49507,429,an hour ago,
jQuery,5745,213,4 days ago,
React,3557,288,5 hours ago,
```

We also guarantee that:

* there are no nested objects
* inside a string surrounded by quotes, only alphanumeric characters can appear
* every object has the same keys, and that they will be in the same order

## Solutions

I originally thought the solution of this problem to be a [finite-state machine](https://en.wikipedia.org/wiki/Finite-state_machine). You have just a pointer, go through each character and based on the current state, you either decide to print the character, a comma or nothing. You first do this to print the first row of the CSV with the columns, reset the pointer to the top of the file and traverse it again by printing the values. My solution is [here](https://github.com/palcu/convertor/blob/master/imp.cpp) and Ada Solcan helped me with a more beautiful version [here](https://github.com/palcu/convertor/blob/master/ada_c.cpp).

For generating the [tests](https://github.com/palcu/convertor/tree/master/teste), I hacked a [Python script](https://github.com/palcu/convertor/blob/master/generator_teste.py) that outputted a JSON. Three tests were special because they had random whitespace. One test was a corner case where there was only one object with lots of keys, and another one had lots of objects with a single key.

The problem gathered 2812 submissions from 158 students.

## Statistics about the online submissions

TODO charts

## Hands-on interviews

TODO finish this section

We were 8 interviewers...
Categories...

## Technical questions

We would first ask the student to present his solution. Then, we would start asking him what would happen if we modified the problem statement and he would start to have special characters inside the keys, like parentheses or colons. Then we would ask him to tell us how easily it would have been to modify the source code and support those edge cases.

From what I've observed, the shorter and cleaner the student's solution was, the easier for him was to tell us a solution.

After this warming questions, we would ask him the important one: what would happen if the keys of the objects were not in the same order. For example

```json
[{
"id": 1,
"language": "Ruby",
"usage": "Mainly by hipsters.",
"power": 4
}, {
"usage": "Computer scientists and some wannabe hipsters.",
"language": "Python",
"id": 2,
"power": 2
}]
```

_All the complexities are assuming a comparison of strings is done in O(1)._

I took about 20 interviews. Almost every student would find the O(N^2) algorithm. The solution would be to print the keys of the first object, read the second object, and for every key search it naively in the first object.

From here, only half of the students would get a better solution alone. The first hint I gave was to try and see if having the keys in a certain order might help. Some of them caught the idea, sorted the keys and said that they would now use binary search to find the position of the keys in O(N*log(N)).

Then I might ask them if they know a data structure where you could do lookups faster than O(log(n)). Most of them knew about hashes and gave the correct complexity solution. However, when I asked them how does a hash work, they raised their shoulders and had no idea. I then explained them that a simple implementation of a hash is a long array with a smart hash function.

I must say that there were some smart students that knew what hashes were, how they worked behind the scenes and they applied them to this problem naturally without any help. For these students I asked them why would you sometimes prefer a binary search tree in place of a hash. The answer is that a BST uses lower memory. Another topic of discussion would be on how would you implement a hash function for this problem. Two students knew that using a base of 26 for the characters of the keys and then doing modulo of a big prime number would be a simple and elegant solution.

All in all, I was surprised by the lack of how the students grasped the concept of a hash and applied it in the problem, but had some interesting discussions with the smart ones.

## Final selection

TODO: Acknowledgements
