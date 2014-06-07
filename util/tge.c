/*
 * Copyright (c) 2013
 *
 *     Yuan Mei
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <arpa/inet.h>
#include <assert.h>

#include "common.h"
#include "command.h"
#include "tge.h"

size_t tge_build_arp_reply(uint16_t **bufio, uint64_t srcMAC, uint32_t srcIP,
                           uint64_t dstMAC, uint32_t dstIP)
{
    size_t n = 21;
    ssize_t i;
    uint16_t *buf;
    
    buf = *bufio;
    if(buf == NULL) {
        buf = (uint16_t*)calloc(n, sizeof(uint16_t));
        if(buf == NULL)
            return -1;
        *bufio = buf;
    }
    i = 0;
    /* MAC is enclosed in big endian in a 64bit integer */
    buf[i++] = (dstMAC >> 4*8) & 0xffff;
    buf[i++] = (dstMAC >> 2*8) & 0xffff;
    buf[i++] = (dstMAC >> 0*8) & 0xffff;
    buf[i++] = (srcMAC >> 4*8) & 0xffff;
    buf[i++] = (srcMAC >> 2*8) & 0xffff;
    buf[i++] = (srcMAC >> 0*8) & 0xffff;
    buf[i++] = 0x0806; // type ARP
    buf[i++] = 0x0001; // hardware type Ethernet
    buf[i++] = 0x0800; // protocol type IP
    buf[i++] = 0x0604; // hardware and protocol address length
    buf[i++] = 0x0002; // Opcode reply (2)
    // src MAC address
    buf[i++] = (srcMAC >> 4*8) & 0xffff;
    buf[i++] = (srcMAC >> 2*8) & 0xffff;
    buf[i++] = (srcMAC >> 0*8) & 0xffff;
    // src IP address
    buf[i++] = (srcIP >> 2*8) & 0xffff;
    buf[i++] = (srcIP >> 0*8) & 0xffff;
    // dst MAC address
    buf[i++] = (dstMAC >> 4*8) & 0xffff;
    buf[i++] = (dstMAC >> 2*8) & 0xffff;
    buf[i++] = (dstMAC >> 0*8) & 0xffff;
    // dst IP address
    buf[i++] = (dstIP >> 2*8) & 0xffff;
    buf[i++] = (dstIP >> 0*8) & 0xffff;

    conv16network_endian(buf, n);
    return n*sizeof(uint16_t);
}

size_t tge_cmd_send_arp_reply(uint32_t **bufio, uint64_t srcMAC, uint32_t srcIP,
                              uint64_t dstMAC, uint32_t dstIP)
{
    uint32_t *cmdBuf=NULL, *p;
    uint16_t *arpBuf=NULL;
    size_t n, cmdnbytes, arpnbytes;

    arpBuf = (uint16_t*)calloc(22, sizeof(uint16_t));
    arpnbytes = tge_build_arp_reply(&arpBuf, srcMAC, srcIP, dstMAC, dstIP);
    assert(arpnbytes == 42);

    n = 0;
    cmdBuf = (uint32_t*)calloc(24+1+1, sizeof(uint32_t));
    /* write to memory */
    cmdnbytes = cmd_write_memory(&cmdBuf, 0, (uint32_t*)arpBuf, 11 /* pay attention!!! */);
    n += cmdnbytes;
    p = cmdBuf + cmdnbytes / sizeof(uint32_t);
    /* write number of bytes to send to register */
    cmdnbytes = cmd_write_register(&p, 0, (uint32_t)arpnbytes);
    n += cmdnbytes;
    p += cmdnbytes / sizeof(uint32_t);
    /* send a pulse to start packet tx */
    cmdnbytes = cmd_send_pulse(&p, 0x01);
    n += cmdnbytes;

    free(arpBuf);
    if(*bufio == NULL) {
        *bufio = cmdBuf;
    } else {
        memcpy(*bufio, cmdBuf, n);
        free(cmdBuf);
    }
    return n;
}

/* dataLen (bytes) is the effective payload data bytes (excluding the
 * wasted dummy data bytes in the header.  The total transferred bytes
 * is dataLen + (retur)n */
size_t tge_build_udp(uint16_t **bufio, uint64_t srcMAC, uint32_t srcIP, uint16_t srcPort,
                     uint64_t dstMAC, uint32_t dstIP, uint16_t dstPort, size_t dataLen)
{
    size_t n = 24;
    ssize_t i;
    uint16_t *buf;
    uint32_t checksum;
    
    buf = *bufio;
    if(buf == NULL) {
        buf = (uint16_t*)calloc(n, sizeof(uint16_t));
        if(buf == NULL)
            return -1;
        *bufio = buf;
    }
    i = 0;
    /* MAC is enclosed in big endian in a 64bit integer */
    buf[i++] = (dstMAC >> 4*8) & 0xffff;
    buf[i++] = (dstMAC >> 2*8) & 0xffff;
    buf[i++] = (dstMAC >> 0*8) & 0xffff;
    buf[i++] = (srcMAC >> 4*8) & 0xffff;
    buf[i++] = (srcMAC >> 2*8) & 0xffff;
    buf[i++] = (srcMAC >> 0*8) & 0xffff;
    buf[i++] = 0x0800; // type IP
    buf[i++] = 0x4500; // V4, 5x32bit words header length; DSCP, ECN all 0
    buf[i++] = (dataLen + 8 + 6 + 20) & 0xffff; //total length (bytes)
    buf[i++] = 0x0000; // identification
    buf[i++] = 0x0000; // fragmentation
    buf[i++] = 0x4011; // TTL, protocol
    buf[i++] = 0x0000; // header checksum
    // src IP address
    buf[i++] = (srcIP >> 2*8) & 0xffff;
    buf[i++] = (srcIP >> 0*8) & 0xffff;
    // dst IP address
    buf[i++] = (dstIP >> 2*8) & 0xffff;
    buf[i++] = (dstIP >> 0*8) & 0xffff;
    // src port
    buf[i++] = srcPort & 0xffff;
    // dst port
    buf[i++] = dstPort & 0xffff;
    // UDP length (bytes)
    buf[i++] = (dataLen + 8 + 6) & 0xffff;
    // checksum
    buf[i++] = 0x0000; // disabled
    // 3 more 16-bit words (dummy), so that the header ends at 64bit boundary
    buf[i++] = 0x794d;
    buf[i++] = 0x6569;
    buf[i++] = 0x4950;

    // compute checksum
    checksum = 0;
    for(i=7; i<17; i++)
        checksum += buf[i];
    buf[12] = ((checksum >> 16) & 0xffff) + (checksum & 0xffff);
    buf[12] = ~buf[12];

    conv16network_endian(buf, n);
    return n*sizeof(uint16_t);
}

size_t tge_cmd_send_udp(uint32_t **bufio, uint64_t srcMAC, uint32_t srcIP, uint16_t srcPort,
                        uint64_t dstMAC, uint32_t dstIP, uint16_t dstPort, size_t dataLen)
{
    uint32_t *cmdBuf=NULL, *p;
    uint16_t *udpBuf=NULL;
    size_t n, cmdnbytes, udpnbytes;

    udpBuf = (uint16_t*)calloc(24, sizeof(uint16_t));
    udpnbytes = tge_build_udp(&udpBuf, srcMAC, srcIP, srcPort, dstMAC, dstIP, dstPort, dataLen);
    assert(udpnbytes == 48);
    udpnbytes += dataLen;

    n = 0;
    cmdBuf = (uint32_t*)calloc(26+1+1, sizeof(uint32_t));
    /* write to memory */
    cmdnbytes = cmd_write_memory(&cmdBuf, 0, (uint32_t*)udpBuf, 12 /* pay attention!!! */);
    n += cmdnbytes;
    p = cmdBuf + cmdnbytes / sizeof(uint32_t);
    /* write number of bytes to send to register */
    cmdnbytes = cmd_write_register(&p, 0, (uint32_t)udpnbytes);
    n += cmdnbytes;
    p += cmdnbytes / sizeof(uint32_t);
    /* send a pulse to start packet tx */
    cmdnbytes = cmd_send_pulse(&p, 0x01);
    n += cmdnbytes;

    free(udpBuf);
    if(*bufio == NULL) {
        *bufio = cmdBuf;
    } else {
        memcpy(*bufio, cmdBuf, n);
        free(cmdBuf);
    }
    return n;
}
