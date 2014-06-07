#ifndef __TGE_H__
#define __TGE_H__

size_t tge_build_arp_reply(uint16_t **bufio, uint64_t srcMAC, uint32_t srcIP,
                           uint64_t dstMAC, uint32_t dstIP);
size_t tge_cmd_send_arp_reply(uint32_t **bufio, uint64_t srcMAC, uint32_t srcIP,
                              uint64_t dstMAC, uint32_t dstIP);
size_t tge_cmd_send_udp(uint32_t **bufio, uint64_t srcMAC, uint32_t srcIP, uint16_t srcPort,
                        uint64_t dstMAC, uint32_t dstIP, uint16_t dstPort, size_t dataLen);

#endif /* __TGE_H__ */
