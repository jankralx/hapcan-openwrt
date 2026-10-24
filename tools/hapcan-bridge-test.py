#!/usr/bin/env python3
"""End-to-end bridge test: TCP (interface under test) <-> CAN <-> HAPCAN USB interface.

Usage: hapcan-bridge-test.py HOST USB_TTY

Sends a read-only "hardware type request to all groups" (0x103) once over TCP
port 1001 and once from a HAPCAN USB interface on the same bus, and checks
that each request arrives on the other side. Module responses are printed.
Exit status is 0 when both directions work.
"""
import os, socket, sys, termios, time, select

host, tty = sys.argv[1], sys.argv[2]

def frame(payload):
    return bytes([0xAA]) + bytes(payload) + bytes([sum(payload) & 0xFF, 0xA5])

def parse(buf):
    out = []
    while len(buf) >= 15:
        i = buf.find(b"\xaa")
        if i < 0: return out, b""
        buf = buf[i:]
        if len(buf) < 15: break
        f = buf[:15]
        if f[14] == 0xA5 and (sum(f[1:13]) & 0xFF) == f[13]:
            out.append(f[1:13]); buf = buf[15:]
        else:
            buf = buf[1:]
    return out, buf

fd = os.open(tty, os.O_RDWR | os.O_NOCTTY)
a = termios.tcgetattr(fd); a[4] = a[5] = termios.B115200
a[0] = a[1] = a[3] = 0; a[2] = termios.CS8 | termios.CLOCAL | termios.CREAD
termios.tcsetattr(fd, termios.TCSANOW, a); termios.tcflush(fd, termios.TCIOFLUSH)
s = socket.create_connection((host, 1001), timeout=5); s.setblocking(False)

def listen(secs):
    got = {"tcp": [], "usb": []}; bufs = {"tcp": b"", "usb": b""}
    end = time.time() + secs
    while time.time() < end:
        r, _, _ = select.select([s, fd], [], [], 0.1)
        for x in r:
            k = "tcp" if x is s else "usb"
            data = s.recv(4096) if x is s else os.read(fd, 4096)
            f, bufs[k] = parse(bufs[k] + data); got[k] += f
    return got

def show(got):
    for k in ("tcp", "usb"):
        print(f"  {k}: {len(got[k])} frames")
        for f in got[k][:6]: print("    ", f.hex(" "))

listen(1.0)
# hardware type request to all groups, sender node/group 0xFD/0xFD (via TCP)
req1 = [0x10, 0x30, 0xFD, 0xFD, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF]
s.send(frame(req1)); print("sent via TCP:", bytes(req1).hex(" ")); g1 = listen(3); show(g1)
# same from the USB interface, sender 0xFC/0xFC
req2 = [0x10, 0x30, 0xFC, 0xFC, 0xFF, 0xFF, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0xFF]
os.write(fd, frame(req2)); print("sent via USB:", bytes(req2).hex(" ")); g2 = listen(3); show(g2)
ok1 = any(f == bytes(req1) for f in g1["usb"])
ok2 = any(f == bytes(req2) for f in g2["tcp"])
print("TCP->CAN->USB:", "OK" if ok1 else "FAIL", "| USB->CAN->TCP:", "OK" if ok2 else "FAIL")
sys.exit(0 if ok1 and ok2 else 1)
