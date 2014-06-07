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

#include "common.h"
#include "command.h"

char *conv16network_endian(uint16_t *buf, size_t n)
{
    size_t i;
    for(i=0; i<n; i++) {
        buf[i] = htons(buf[i]);
    }
    return (char*)buf;
}

char *conv32network_endian(uint32_t *buf, size_t n)
{
    size_t i;
    for(i=0; i<n; i++) {
        buf[i] = htonl(buf[i]);
    }
    return (char*)buf;
}

size_t cmd_read_status(uint32_t **bufio, uint32_t addr)
{
    uint32_t *buf;
    buf = *bufio;
    if(buf == NULL) {
        buf = (uint32_t*)calloc(1, sizeof(uint32_t));
        if(buf == NULL)
            return -1;
        *bufio = buf;
    }
    buf[0] = (0xffff0000 & ((0x8000 + addr) << 16));
    conv32network_endian(buf, 1);
    return 1*sizeof(uint32_t);
}

size_t cmd_send_pulse(uint32_t **bufio, uint32_t mask)
{
    uint32_t *buf;
    buf = *bufio;
    if(buf == NULL) {
        buf = (uint32_t*)calloc(1, sizeof(uint32_t));
        if(buf == NULL)
            return -1;
        *bufio = buf;
    }
    buf[0] = 0x000b0000 | (0x0000ffff & mask);
    conv32network_endian(buf, 1);
    return 1*sizeof(uint32_t);
}

size_t cmd_write_memory(uint32_t **bufio, uint32_t addr, uint32_t *aval, size_t nval)
{
    size_t idx, i;
    uint32_t *buf;

    buf = *bufio;
    if(buf == NULL) {
        buf = (uint32_t*)calloc(nval*2+2, sizeof(uint32_t));
        if(buf == NULL)
            return -1;
        *bufio = buf;
    }

    idx = 0;
    buf[idx++] = 0x00110000 | (0x0000ffff & addr);          // address LSB
    buf[idx++] = 0x00120000 | (0x0000ffff & (addr>>16));    // address MSB
    buf[idx++] = 0x00130000 | (0x0000ffff & (*aval));       // data LSB
    buf[idx++] = 0x00140000 | (0x0000ffff & ((*aval)>>16)); // data MSB
    for(i=1; i<nval; i++) {                                 // more data
        buf[idx++] = 0x00130000 | (0x0000ffff & aval[i]);
        buf[idx++] = 0x00140000 | (0x0000ffff & (aval[i]>>16));
    }
    conv32network_endian(buf, nval*2+2);
    return (nval*2+2)*sizeof(uint32_t);
}

size_t cmd_read_memory(uint32_t **bufio, uint32_t addr, uint32_t n)
{
    size_t idx;
    uint32_t *buf;

    buf = *bufio;
    if(buf == NULL) {
        buf = (uint32_t*)calloc(4, sizeof(uint32_t));
        if(buf == NULL)
            return -1;
        *bufio = buf;
    }

    idx = 0;
    buf[idx++] = 0x00110000 | (0x0000ffff & addr);       // address LSB
    buf[idx++] = 0x00120000 | (0x0000ffff & (addr>>16)); // address MSB
    buf[idx++] = 0x00100000 | (0x0000ffff & n);          // n words to read
    buf[idx++] = 0x80140000;                             // initialize read

    conv32network_endian(buf, 4);
    return 4*sizeof(uint32_t);
}

size_t cmd_write_register(uint32_t **bufio, uint32_t addr, uint32_t val)
{
    uint32_t *buf;
    buf = *bufio;
    if(buf == NULL) {
        buf = (uint32_t*)calloc(1, sizeof(uint32_t));
        if(buf == NULL)
            return -1;
        *bufio = buf;
    }
    buf[0] = (0xffff0000 & ((0x0020 + addr) << 16)) | (0x0000ffff & val);
    conv32network_endian(buf, 1);
    return 1*sizeof(uint32_t);
}

size_t cmd_read_register(uint32_t **bufio, uint32_t addr)
{
    uint32_t *buf;
    buf = *bufio;
    if(buf == NULL) {
        buf = (uint32_t*)calloc(1, sizeof(uint32_t));
        if(buf == NULL)
            return -1;
        *bufio = buf;
    }
    buf[0] = (0xffff0000 & ((0x8020 + addr) << 16));
    conv32network_endian(buf, 1);
    return 1*sizeof(uint32_t);
}

size_t cmd_read_datafifo(uint32_t **bufio, uint32_t n)
{
    uint32_t *buf;
    buf = *bufio;
    if(buf == NULL) {
        buf = (uint32_t*)calloc(1, sizeof(uint32_t));
        if(buf == NULL)
            return -1;
        *bufio = buf;
    }
    buf[0] = (0xffff0000 & (0x0019 << 16)) | (0x0000ffff & n);
    conv32network_endian(buf, 1);
    return 1*sizeof(uint32_t);
}
