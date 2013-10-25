---
layout: post
date: 2011-12-03
title: "The challenges of IPv6"
tags: [IPv6]
author: Alexandru Juncu
---

As we all know, IPv6 is the new protocol of the Internet, that will come to
replace the current version of IP (Internet Protocol), IPv4. It will come
to fix the flaw of the 32 bit addressing in IPv4, flaw that led to the
current shortage of usable address in the Internet.

The addressing issue is not something new. The IETF started looking into a
replacement for IPv4 since 1992-1993, when they started the IPng (IP next
generation) discussion group and by 1996, they had the specifications for
IPv6.

So considering that the Internet is about 40 years old and the IPv4
addressing problem is been known for about half that time, why is it that
after 15 years since having the solution in the form of IPv6, why is it
still not predominately used?

Probably the easiest way to have build the IPng is with a backwards
compatibility (for example, using a variable length address, like OSI’s
CLNP, where all the IPv4’s address space is just a part of the IPv6 space,
using 32 bits). But since they wanted to start from scratch an rewrite
everything in order to fix other problems in IPv4 (like the now almost
useless header checksum) and to add new features (like the header
extensions that allows protocols like IPSec to be built inside IPv6). But
the “rewrite everything” approach meant that almost all of the components
of the network layers had to be rewritten and this resulted in a large
groups of people being affected by the change.

First were the network administrators, the ones that had to ensure that
their routers, multilayer switches, firewall and wireless controllers were
ready to be migrated. Most of the old equipment had to be replaced with new
ones, or at least have their software updated. Current equipment do most of
their packet processing in hardware to get better performance, but this is
valid only for IPv4 packets. Hardware processing for IPv6 packets is
something that only very new models of routers and switches do, and
companies don’t really want to buy new equipment since the costs are rather
big. **Routing protocols** had to be rewritten or modified or written from zero.
OSPFv3, the link state protocol and the simple and lightweight distance
vector, RIPng, had to be implemented from scratch. More modular, IP
independent protocols like EIGRP and Intergrated IS-IS needed new modules
for the new protocol.

System administrators had the same concern, getting their services IPv6
ready. From setting up their web services to listen on both protocols to
the more difficult service, **DNS**. If DNS in IPv4 was a good thing to have,
in IPv6, DNS is critical (nobody wants to remember a 32 hexadecimal digit
number). The DNS protocol needed to add a new record, the AAAA record, and
needed to implement a new reverse DNS zone, the ip6.arpa. zone.

But some of the frustrations of the administrators and the users are caused
by bugs or even lack of implementation in software. Since every hardware
needs a software, IPv6 first of all needs support in the software written.
Kernel, system and application programmers needed starting building in
support for IPv6. For example, people started patching **Linux** 2.1 back in
1996, but real stable, built-in support for IPv6 only came out in 2.6.
Support in kernel still didn't mean that people could use it because it
lacked the userspace tools. The wide used ifconfig wasn't build for v6, and
only with the development of **iproute2**, Linux users could configure IPv6 on
their boxes. Although considered deprecated, newer versions of ifconfig do
support IPv6 address assignments. In the Windows world, things are worse,
since only Windows 7 really has full support (kernel and user space tools)
for IPv6. 

Only after the IPv6 stack is built inside the kernel (the network stack
being one of the hardest part of the kernel to program), the system
programmers could start porting their programs to be IPv6 ready. IPv4
and IPv6 sockets are not compatible, because the second one needs to
implement the address family AF\_INET6. An IPv6 ready application also
needs to be IPv4 working, so it needs to be smart and know when to create
a v4 connection or a v6 connection. Because  if only sometimes a v6
infrastructure is available, a v4 infrastructure is almost sure there. But
if both are available, which one do you chose, because maybe one works
better than the other in that situation?

So as we can see, there is not one group affected by the migration to IPv6,
but rather an entire ecosystem, with several groups affecting each other.
