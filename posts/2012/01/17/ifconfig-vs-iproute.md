---
layout: post
date: 2012-01-17
title: ifconfig vs iproute2
tags: [iproute2, net-tools, ifconfig, ip, route, arp, netlink, IPv4, IPv6]
author: Alexandru Juncu
---



On modern Linux distributions, the users have two main possibilities of
configuring the network: ifconfig and ip.

The ifconfig tool is part of the **net-tools** package along side other
tools like route, arp and netstat. These are the traditional userspace
tools for network configuration, made for older Linux kernels.

The **iproute2** is the new package that comes with the ip tool as
replacement for the ifconfig, route and arp commands, ss as the new
netstat and tc as a new command.

There are pros and cons for each of them and there are users (and fans) of
each. Let's see the differences...

First of all, why was the iproute introduced? There had to have been a need
for it... The reason was the introduction of the
**[Netlink](http://www.faqs.org/rfcs/rfc3549.html "Netlink")** API, which is a
socket like interface for accessing kernel information about interfaces,
address assignments and routes. The tools like ifconfig used the /proc file
hierarchy (procfs) for collecting information. The output was reformatted
data from different network related files in /proc.

	alexj@hathor ~/techblog $ strace -e open ifconfig eth0 2>&1|grep /proc
	open("/proc/net/dev", O_RDONLY)         = 6
	open("/proc/net/if_inet6", O_RDONLY)    = 6

The costs for the operations like open and read from these files were
rather big compared for the netlink interface. For comparison, let's assume
that we have a large number of interfaces (128) with IPv4 and IPv6
addresses and their associated connected routes.

	alexj@hathor ~/if $ time ifconfig -a >/dev/null 

	real	0m1.528s
	user	0m0.080s
	sys	0m1.420s

	alexj@hathor ~/if $ time ip addr show >/dev/null

	real	0m0.016s
	user	0m0.000s
	sys	0m0.012s

But most of normal users are not that geeky to care about millisecond
speedup. They do, however, care about usability. And iproute2 does seem to
have a better user interface. The ip command is better organized, in what
they called objects. Links, addresses, routes, routing rules, tunnels are
all objects, that can be added, deleted or listed. If a user learns how to
add an address, by intuition, he can easily guess how to add a route, for
example, because the syntax in similar.

Keyword shortening and auto completion makes the ip command more efficient
by removing redundant characters. The following commands are identical as
effect:

	ip address show
	ip address
	ip addr show
	ip a s
	ip a

Some network engineers will like iproute2 because it's similar to
Cisco's IOS: "ip route show" in Linux vs "show ip route" in IOS. Another
usability feature is that you have the \number format for subnet masks
instead of the quadded-decimal format, the first one being shorter to
write and more up to date with the concept of VLSM.

So what does ifconfig still have to keep it around? Its biggest weakness is
its biggest strength: its age. ifconfig has been out and used for so long
that it's very hard to put it away. Still many scripts in the heart of
Linux distributions rely on ifconfig to work and most system
administrators are used to the ifconfig command and it's hard to move them
to something new and unfamiliar. A lot of tutorials on the Internet about
network configuration teach ifconfig and not iproute2 to beginners. For
example, LPIC-1, one of the biggest Linux Certification out there, still
requires ifconfig skills for passing the exam and barely mentiones
iproute2.

When released, iproute2 had at least one advantage over ifconfig, and that
was the feature of interacting with the IPv6 stack while ifconfig was only
for IPv4. But since then, fans of ifconfig patched it so it could also be
IPv6 ready.

But other features were not replicated. In old Linux Kernels, an interfaces
could have only one IP address, so in ifconfig you could configure only one
IP address on an interfaces. In newer kernels, each interface has a list of
addresses and iproute2 via the NetLink interface could manage them. Latest
ifconfig versions still rely on the idea of subinterfaces to provide more
than one address on an interfaces.

So, given all these arguments, iproute2 should be declared the winner. But
it's not that easy. Just like in the case of IPv4 vs IPv6, where the latter one
is the obvious choice, iproute2 will eventually replace ifconfig. Only it's
going to take a long time for that to happen, so net-tools will still be
around for some time, but they will be eventually phased out.
