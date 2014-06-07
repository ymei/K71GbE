#ifndef __SIP_H__
#define __SIP_H__
/* 4DSP SIP command interface */
#define STELLAR_OPCODE_READ           2  /* Host -> Fw   ( Read a register ) */
#define STELLAR_OPCODE_WRITE          3  /* Host -> Fw   ( Write a register ) */
#define STELLAR_OPCODE_WRITE_ACK      4  /* Fw   -> Host ( Ack a register write ) */
#define STELLAR_OPCODE_WRITE_DATA     5  /* Host -> Fw   ( Host is going to send data ) */
#define STELLAR_OPCODE_WRITE_DATA_ACK 6  /* Fw   -> Host ( Ack a data receiving ) */
#define STELLAR_OPCODE_READ_ACK       7  /* Fw   -> Host ( Ack a register read ) */
#define STELLAR_OPCODE_READ_DATA      8  /* Host -> Fw   ( Host is asking for data) */
#define STELLAR_OPCODE_READ_DATA_ACK  9  /* Fw   -> Host ( Ack a data receiving ) */
#define STELLAR_OPCODE_READ_TO_ACK    10 /* Fw   -> Host ( Ack a register read in case of timeout on the sip address range ) */

#define CMD_OPCODE_WRITE 1
#define CMD_OPCODE_READ  2

#define SIP_CID_BAR 0x00002000
#define SIP_

enum {
    SIP_CID_IDX          = 0,
    SIP_MAC_ENGINE_IDX   = 1,
    SIP_I2C_MASTER_IDX   = 2,
    SIP_CMD12_MUX_IDX    = 3,
    SIP_FMC_CT_GEN_IDX   = 4,
    SIP_FMC112_IDX       = 5,
    SIP_ROUTER_S16D1_IDX = 6,
    SIP_FIFO64K_IDX      = 7
};

typedef struct {
    uint32_t bar; /* base address */
    uint32_t ear; /* end address */
    uint16_t id;
    uint16_t ver;
} sip_star_info_t;

size_t sip_send_recv_command(uint32_t **bufio, uint64_t cmd);
size_t sip_send_command(uint32_t **bufio, uint64_t cmd);
size_t sip_recv_command(uint32_t **bufio);
uint64_t sip_reg_ret2num(char *buf, size_t n);

size_t sip_write_reg(uint32_t **bufio, uint32_t addr, uint32_t data);
size_t sip_read_reg(uint32_t **bufio, uint32_t addr);

#endif /* __SIP_H__ */
