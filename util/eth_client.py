#!/usr/bin/env python

import socket

host = '192.168.2.2'
port = 1024
size = 4096
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host,port))
s.setblocking(1)

while True:
    s.send('Hello'*200)
    data = s.recv(size)

s.close()
