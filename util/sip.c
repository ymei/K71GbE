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
#include "sip.h"

size_t sip_send_recv_command(uint32_t **bufio, uint64_t cmd)
{
    uint32_t *cmdBuf=NULL, *p;
    size_t n, cmdnbytes;
    ssize_t i;

    n = 0;
    cmdBuf = (uint32_t*)calloc(4+1+4+4, sizeof(uint32_t));
    p = cmdBuf;
    /* write to register */
    for(i=0; i<4; i++) {
        cmdnbytes = cmd_write_register(&p, 4+i, ((cmd)>>(i*16)) & 0x0000ffff);
        n += cmdnbytes;
        p += cmdnbytes / sizeof(uint32_t);
    }

    /* send a pulse */
    cmdnbytes = cmd_send_pulse(&p, 0x00000002);
    n += cmdnbytes;
    p += cmdnbytes / sizeof(uint32_t);

    /* add a blank command for to allow time for return values */
    for(i=0; i<4; i++) {
        cmdnbytes = cmd_write_register(&p, 4+i, ((cmd)>>(i*16)) & 0x0000ffff);
        n += cmdnbytes;
        p += cmdnbytes / sizeof(uint32_t);
    }

    /* read status register back */
    for(i=0; i<4; i++) {
        cmdnbytes = cmd_read_status(&p, 4+i);
        n += cmdnbytes;
        p += cmdnbytes / sizeof(uint32_t);
    }

    if(*bufio == NULL) {
        *bufio = cmdBuf;
    } else {
        memcpy(*bufio, cmdBuf, n);
        free(cmdBuf);
    }
    return n;
}

size_t sip_send_command(uint32_t **bufio, uint64_t cmd)
{
    uint32_t *cmdBuf=NULL, *p;
    size_t n, cmdnbytes;
    ssize_t i;

    n = 0;
    cmdBuf = (uint32_t*)calloc(4+1, sizeof(uint32_t));
    p = cmdBuf;
    /* write to register */
    for(i=0; i<4; i++) {
        cmdnbytes = cmd_write_register(&p, 4+i, ((cmd)>>(i*16)) & 0x0000ffff);
        n += cmdnbytes;
        p += cmdnbytes / sizeof(uint32_t);
    }

    /* send a pulse */
    cmdnbytes = cmd_send_pulse(&p, 0x00000002);
    n += cmdnbytes;
    p += cmdnbytes / sizeof(uint32_t);

    if(*bufio == NULL) {
        *bufio = cmdBuf;
    } else {
        memcpy(*bufio, cmdBuf, n);
        free(cmdBuf);
    }
    return n;
}

size_t sip_recv_command(uint32_t **bufio)
{
    uint32_t *cmdBuf=NULL, *p;
    size_t n, cmdnbytes;
    ssize_t i;

    n = 0;
    cmdBuf = (uint32_t*)calloc(4, sizeof(uint32_t));
    p = cmdBuf;

    /* read status register back */
    for(i=0; i<4; i++) {
        cmdnbytes = cmd_read_status(&p, 4+i);
        n += cmdnbytes;
        p += cmdnbytes / sizeof(uint32_t);
    }

    if(*bufio == NULL) {
        *bufio = cmdBuf;
    } else {
        memcpy(*bufio, cmdBuf, n);
        free(cmdBuf);
    }
    return n;
}

uint64_t sip_reg_ret2num(char *buf, size_t n)
{
    unsigned char *p = (unsigned char *)buf;
    uint64_t ret = 0;
    if(n<16) {
        error_printf("Only %zd bytes in the buffer, 16 expected\n", n);
        return 0;
    }
    ret |= ((uint64_t)p[14] << (8*7)) | (uint64_t)p[15] << (8*6);
    ret |= ((uint64_t)p[10] << (8*5)) | (uint64_t)p[11] << (8*4);
    ret |= ((uint64_t)p[6]  << (8*3)) | (uint64_t)p[7]  << (8*2);
    ret |= ((uint64_t)p[2]  << (8*1)) | (uint64_t)p[3]  << (8*0);
    return ret;
}

size_t sip_write_reg(uint32_t **bufio, uint32_t addr, uint32_t data)
{
    uint64_t cmd = 0;

    cmd |= ((uint64_t)CMD_OPCODE_WRITE)<<60;
    cmd |= ((uint64_t)addr)<<32;
    cmd |= (uint64_t)data;
    
    return sip_send_command(bufio, cmd);
}

size_t sip_read_reg(uint32_t **bufio, uint32_t addr)
{
    uint64_t cmd = 0;

    cmd |= ((uint64_t)CMD_OPCODE_READ)<<60;
    cmd |= ((uint64_t)addr)<<32;
    
    return sip_send_recv_command(bufio, cmd);
}
