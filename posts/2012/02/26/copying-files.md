---
date: 2012-02-26
title: Copying files remotely
author: Alexandru Juncu
tags: scp, nc, netcat, python
---

You are on a (Linux) box and you want to transfer some files on another
system. What are some ways to do that?

<!--more-->

The first and most obvious way is to copy them over `ssh` using the
`scp` tool. You can copy to and from the server and you can use the
recursive copy to transfer entire directories.

But what if you don't have proper account access (you can't reach accounts
because of lack of passwords or keys, for example)? Here is a rather hackish
solution: nc.

The `netcat` tool (the `nc` command) is found on most Linux systems.
You can create TCP or UDP servers and clients with just one command. You
can use the shell redirection operators to put files into a TCP stream and
take the data out of the stream. Here is an example of a copy from a server
to a client:
	
	Server:
	alexj@ixmint ~ $ md5sum lin.zip
	3008726d03363b89bcf743c0fde4d5f8  lin.zip
	alexj@ixmint ~ $ cat lin.zip|nc -l 12345

	Client:
	alexj@hathor /tmp $ nc ixmint.local 12345 >lin.zip
	alexj@hathor /tmp $ md5sum lin.zip
	3008726d03363b89bcf743c0fde4d5f8  lin.zip

You could transfer an entire directory (or several files) by first
compressing the content.

	Server:
	alexj@ixmint ~ $ tar -czvf - some_folder | nc -l 12345

	Client:
	alexj@hathor /tmp $ nc ixmint.local 12345 | tar xzvf -


What other more user friendly ways are there? HTTP would be good at this, but
configuring Apache with vhosts and aliases is kind of an overhead. What you
can do, is start a HTTP server using Python in just one line

	alexj@ixmint ~ $ python -m SimpleHTTPServer 1234
	Serving HTTP on 0.0.0.0 port 1234 ...

The current working directory where you ran the command will be the www
root and any files in that directory will be published (as long as the
process will have correct permissions to those files). You can then use a
web browser (it can be Firefox or other GUI clients or a simple `wget`)
to access the URL.

Credits to Alex Morega for `tar | nc` idea and Vlad Dogaru for `python
SimpleHTTPServer` idea.
