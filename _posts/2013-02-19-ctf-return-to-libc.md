---
layout: post
date: 2013-02-19
title: "GiTS 2013 CTF -- return-to-libc -- pwnable 250
tags: [exploit, ctf, return-to-libc]
author: Lucian Cojocar
---

This is a write-up for Pwnable 250 level from [Ghost in the Shellcode]: http://ghostintheshellcode.com/ capture the flag competion. Basically a return-to-libc attack will be described; we will also describe the steps for solving the mentioned CTF level using the [original binary]: www.to.do from the competion.


# Hello binary!
* 32bit dynamically liked binary
{% highlight bash %}
	$ file ./back2skool-3fbcd46db37c50ad52675294f566790c777b9d1f ./back2skool-3fbcd46db37c50ad52675294f566790c777b9d1f: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.24, BuildID[sha1]=0xf15ebb11ff673d095abafc932f694bdac7ee5ae9, stripped
* it waits for connections on port 31337
	# strace -f ./back2skool-3fbcd46db37c50ad52675294f566790c777b9d1f
		[...]
	setsockopt(3, SOL_SOCKET, SO_REUSEADDR, [1], 4) = 0
	bind(3, {sa_family=AF_INET, sin_port=htons(31337), sin_addr=inet_addr("0.0.0.0")}, 16) = 0
	listen(3, 20)                           = 0
	accept(3, 

`SO_REUSEADDR` is used, just for easy debugging ;-).

	$ telnet localhost 31337
	Trying ::1...
	Trying 127.0.0.1...
	Connected to localhost.
	Escape character is '^]'.
	Connection closed by foreign host.
	$

It drops connection, something is missing.

* it needs user `back2skool`
	Let's have a look at what happens when we are connecting to it.
	# ltrace -f ./back2skool-3fbcd46db37c50ad52675294f566790c777b9d1f
	[...]
	[pid 4359] accept(3, 0, 0, 0x697a0002, 1)                                           = 4
	[pid 4359] fork()                                                                   = 4361
	[pid 4359] close(4)                                                                 = 0
	[pid 4359] accept(3, 0, 0, 0x697a0002, 1 <unfinished ...>
	[pid 4361] <... fork resumed> )                                                     = 0
	[pid 4361] getpwnam("back2skool")                                                   = NULL
	[pid 4361] err(-1, 0x804997b, 0x80499b8, 0, 0back2skool-3fbcd46db37c50ad52675294f566790c777b9d1f: Failed to find user back2skool: Success
	 <unfinished ...>
	[pid 4361] +++ exited (status 255) +++

In short, `getpwnam` fails, and the forked child exits. It also prints a conclusive error -- the user `back2skool` is required.

Usually, the *first* step, when trying to solve a remote challenge is to debug it locally. Of course this is possible as long as we can run the application ourselves.

After we setup the user we can see the following output when connecting:
	$ telnet localhost 31337
	Trying ::1...
	Trying 127.0.0.1...
	Connected to localhost.
	Escape character is '^]'.
	    __  ___      __  __   _____
	   /  |/  /___ _/ /_/ /_ / ___/___  ______   __ v0.01
	  / /|_/ / __ `/ __/ __ \\__ \/ _ \/ ___/ | / /
	 / /  / / /_/ / /_/ / / /__/ /  __/ /   | |/ /
	/_/  /_/\__,_/\__/_/ /_/____/\___/_/    |___/
	===============================================
	Welcome to MathServ! The one-stop shop for all your arithmetic needs.
	This program was written by a team of fresh CS graduates using only the most
	agile of spiraling waterfall development methods, so rest assured there are
	no bugs here!
	
	Your current workspace is comprised of a 10-element table initialized as:
	{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }
	
	Commands:
		read	Read value from given index in table
		write	Write value to given index in table
		func1	Change operation to addition
		func2	Change operation to multiplication
		math	Perform math operation on table
		exit	Quit and disconnect
	exit
	Exiting program!
	Connection closed by foreign host.
	$

# The vulnerability
The output of the program is self-explanatory. Let's try some values for the commands.
