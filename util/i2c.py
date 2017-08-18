#!/usr/bin/env python
# -*- coding: utf-8 -*-

## @package i2c
# test I2C interface on KC705
#

from __future__ import print_function
import math,sys,time,os,shutil
import socket
from command import *

i2cSleepT = 0.0005

def send_register_file(s, cmd, fname, slaveAddr=0x68):
    regMap = []
    for line in open(fname):
        if line[0] == '#':
            continue
        (a, v) = line.split(',')[0:2]
        regMap.append([int(a), int(v.replace('h', ''), 16)])
    print(regMap)
    for av in regMap:
	# write regAddr with a reg value
    	cmdStr  = cmd.write_register(29, 1)
    	cmdStr += cmd.write_register(31, av[1]<<8)
        cmdStr += cmd.write_register(30, 0<<15 | slaveAddr<<8 | av[0])
        cmdStr += cmd.send_pulse(1<<15)
        s.sendall(cmdStr)
        time.sleep(i2cSleepT)

if __name__ == "__main__":


    host = '192.168.2.3'
    port = 1024
    s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    s.connect((host,port))

    cmd = Cmd()

    # ILA clock
    s.sendall(cmd.write_register(15, 0x07))

    # PCA9548A i2c mux
    addr = 0x74
    ## set mux to Si5324
    cmdStr  = cmd.write_register(29, 0)
    cmdStr += cmd.write_register(30, 0<<15 | addr<<8 | 1<<7)
    cmdStr += cmd.send_pulse(1<<15)
    s.sendall(cmdStr)
    time.sleep(i2cSleepT)
    ## read back
    cmdStr  = cmd.write_register(29, 0)
    cmdStr += cmd.write_register(30, 1<<15 | addr<<8 | 0)
    cmdStr += cmd.send_pulse(1<<15)
    s.sendall(cmdStr)
    time.sleep(i2cSleepT)
    s.sendall(cmd.read_status(10))
    retw = s.recv(4)
    ret = 0
    for i in xrange(1):
        ret |= (ord(retw[i*4+2]) << (i*16 + 8)) | (ord(retw[i*4+3]) << i*16)
    print("0x{:04x}".format(ret))

    # Si5324
    addr = 0x68
    regAddr = 0
    ## write regAddr to stage reg value
    cmdStr  = cmd.write_register(29, 0)
    cmdStr += cmd.write_register(30, 0<<15 | addr<<8 | regAddr)
    cmdStr += cmd.send_pulse(1<<15)
    s.sendall(cmdStr)
    time.sleep(i2cSleepT)
    ## read
    cmdStr  = cmd.write_register(29, 0)
    cmdStr += cmd.write_register(30, 1<<15 | addr<<8 | 0)
    cmdStr += cmd.send_pulse(1<<15)
    s.sendall(cmdStr)
    time.sleep(i2cSleepT)
    s.sendall(cmd.read_status(10))
    retw = s.recv(4)
    ret = 0
    for i in xrange(1):
        ret |= (ord(retw[i*4+2]) << (i*16 + 8)) | (ord(retw[i*4+3]) << i*16)
    print("0x{:04x}".format(ret))

    # configure all registers
    send_register_file(s, cmd, sys.argv[1])
#
    s.close()
