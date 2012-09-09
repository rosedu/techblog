---
layout: post
date: 2012-09-10
title: Introduction to SSH
tags: [SSH, security, remote access]
author: Silviu-Mihai Popescu
---

This is an article aiming to familiarize the reader with the features and benefits of using [Secure Shell (SSH)][ssh], particularly with the [OpenSSH][openssh] implementation. SSH is an application level protocol used for secure data communication, whether that means remote shell access, command execution, file transfer and some other aspects described in this article. It was meant to be a replacement for existing insecure remote shell protocols such as `telnet`, `rsh` and `rexec` which send information in plaintext, including usernames and passwords.

SSH uses [public-key cryptography][pubkey] for authentication purposes. In short, this works like this: each user has a pair of keys, one public and one private. They are mathematically related, but it is computationally infeasible to derive one from the other. The public key is ... well, public! Anyone can get that, and they would use it to encrypt messages. The private key, however, is (or should be) accessible only by the user, and used to decrypt incoming messages.

The two parties of a SSH communication are the server and the client. The server usually runs on port 22, but that is not a requirement, and the client will use a random available port on the client machine.

### Setting up SSH

The simplest way to install a SSH client is with your package manager. On Debian-based distros, it would be something like:

	$ sudo apt-get install openssh-client

After that finishes, you can generate a pair of cryptographic keys using the command `ssh-keygen`:

	$ ssh-keygen 
	Generating public/private rsa key pair.
	Enter file in which to save the key (/home/silviu/.ssh/id_rsa): test
	Enter passphrase (empty for no passphrase): 
	Enter same passphrase again: 
	Your identification has been saved in test.
	Your public key has been saved in test.pub.
	The key fingerprint is:
	eb:8b:a9:c5:22:46:c8:36:d9:c1:40:67:e1:b3:ec:66 silviu@keter
	The key's randomart image is:
	+--[ RSA 2048]----+
	|.o +.            |
	|  *              |
	|   =             |
	|..+ +            |
	|.=.+    S        |
	|..o  .   .       |
	|  oE. o .        |
	| .o. o +         |
	|    ..o o.       |
	+-----------------+

The lines ending in colon represent where you have to provide input. You may have noticed the word `passphrase`. This is used to lock the private key with a string that you choose. In order to use that key pair, the passphrase is provided and checked locally, not transmitted over the network. Please do not mistake this for the remote password.

The default size for the RSA key is 2048 bits. You can change this and other aspects by checking the manual page for `ssh-keygen`,

On the server you would install the `openssh-server` package:

	$ sudo apt-get install openssh-server

Among other things, this should put a script in `/etc/init.d/ssh` and start the server. Depending on whether you distro uses `inittab` or `upstart`, you can check if the server is running with the following commands:

	$ /etc/init.d/ssh status
	$ service ssh status

You can start the server by passing `start` as the last argument in those commands, but you'd also need root access to do that.

And now you can test the installation from the client like this:

	$ ssh my_user@my.server.com

By default, this will try to connect to the specified server on port 22, using the default key at `~/.ssh/id_rsa`. You can change this behaviour by a quick glance at the manual page. Also, if you specified a passphrase during the generation of the key, you will have to provide that and the remote password for the user you are trying to log on as. You can specify yhe IP instead of the DNS name for the server.

You can also run just one line of commands, such as:

	$ ssh my_user@my.server.com 'ls -la; apt-get moo'

So this would be the basic usage of SSH. You can do a lot just with what is written up to this point, and you might be tempted to close the article and just get back to what you wanted to do in the first place. But seriously, you would be missing a lot of the cool stuff SSH can do. Just [bear with me for a moment][bear_xkcd] and you will end up being more productive with SSH.

### Copying files remotely

You can use `cat` and pipes to copy a file remotely:

	$ cat test.txt | ssh -e none user@host 'cat > remote_test.txt'

The `-e` option disables escape characters so that you can send any bytes that your file may contain. The rest is a trick: the output of the remote `cat` is redirected to a file, but the input comes from the output of the first half of the pipe, which is the contents of the file you want to transfer. Neat, right?

However, that solution is kind of tedious. Instead you would better use `scp`, which comes with the package:

	$ scp test.txt user@host:remote_test.txt

Notice that colon after host because it is critical. If you did not want to rename the file you would have just used `user@host:`. The colon tells scp the destination is a remote location. Otherwise, you would just copy `test.txt` to a file named `user@host`.

Also, the path after the colon is relative to the home directory of the remote user.

There is also the `sftp` utility which provides a FTP-like interface.

### Passwordless authentication

So, up until now you have connected via SSH by providing your password, maybe even a passphrase. You can probably see by now that this is troublesome and can be a major drawback if you would like to make a script using SSH. How about we ditch that remote password?

To do this, you would basically need to append the contents of your public key to a file located at `~/.ssh/authorized_keys` on the server.

Luckily for you, most SSH packages provide an utility called `ssh-copy-id` that does just that. So you would just run:

	$ ssh-copy-id user@host

Next time you will try to log on to that account, you will not be prompted for your password.

As an exercise, knowing what you have read thus far, figure out two more ways of achieving the same result, just in case you do not have `ssh-copy-id`.

### Config file

If you are going to use SSH with several servers, with various settings and different key pairs you will soon have to enter something like this:

	$ ssh -i ~/.ssh/private_key_file10 -l user -p 2222 -o "ForwardX11 yes" the.mother.of.all.servers.com

Now that is an extremely long and ugly line with no particular purpose but to illustrate the complexity of ssh commands. Some who have read the manual page know that X forwading can be achieved by passing `-X`.

Anyway, an initial approach to bypassing this issue is by using aliases of bash functions. But those are limited in functionality and basically you are just placing that ugly command somewhere else. Not cool, not cool.

You can put settings on your local computer in `~/.ssh/config`. The full list of options, and their possible values, is available via `man ssh_config`.

Here is a modified version of my config file, for security reasons:

	Host compilers
		User ubuntu
		Hostname ec2-50-17-91-154.compute-1.amazonaws.com
		IdentityFile /home/silviu/.ssh/amazon
	Host *.cs.pub.ro
		User you_d_like_to_know
		IdentityFile /home/silviu/.ssh/cs
	Host so2-lin
		User root
		Hostname 192.168.56.101
		PubkeyAuthentication no
	Host so-lin
		User student
		Hostname 10,0.2,15
		PubkeyAuthentication no
	Host ubuntu-dev
		User silviu
		Hostname 172.16.48.129
		PubkeyAuthentication no
	Host github
		User git
		Hostname github.com
		PreferredAuthentications publickey
		IdentityFile ~/.ssh/github

Now you could put all those options for that long command above in a organized manner, and it will work with all SSH-related utilities, even `scp`, with the options you specified:

	$ scp something mother:

### Local port forwarding

Let's assume that your employer has banned Facebook, so that people might actually do something useful.

Let's also assume that you have a SSH server that you can reach and has no filtering for Facebook.

You could do something like this 

	$ ssh your.server.com -L 80:facebook.com:80

This achieves the following effect: any connection to port 80 on your machine is passed, via your remote machine, to port 80 on facebook.com, which is the standard port for HTTP.
After that, set an entry matching facebook.com to 127.0.0.1 in `/etc/hosts` and procrastinate.

But first, take a moment to come up with a section in your config file that does this forwarding. (Hint: `LocalForward`)

### Conclusions

So now you have a set of things you could do with SSH that can make you be more productive (or not if you just read the last part). I hope you found the article useful.

If you want to know about more things you could do with SSH here is a list of terms you might want to search the web for:
* SSH tunnels
* SSH remote port forwarding
* Set up a SOCKS proxy for Firefox with SSH
* sshfs
* SSH master sessions
* ssh-agent and ssh-reagent

[ssh]: https://en.wikipedia.org/wiki/Secure_Shell "SSH"
[openssh]: http://www.openssh.org/ "OpenSSH"
[pubkey]: https://en.wikipedia.org/wiki/Public-key_cryptography "public-key cryptography"
[bear_xkcd]: https://xkcd.com/365/ "XKCD"
