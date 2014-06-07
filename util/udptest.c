/* waitpid on linux */
#include <sys/types.h>
#include <sys/wait.h>

#include <sys/ioctl.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <netdb.h>

#include <err.h>
#include <errno.h>
#include <fcntl.h>

#ifdef __linux /* on linux */
#include <pty.h>
#include <utmp.h>
#else /* (__APPLE__ & __MACH__) */
#include <util.h> /* this is for mac or bsd */
#endif

#include <paths.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <pthread.h>

#ifdef DEBUG
  #define debug_printf(fmt, ...) do { fprintf(stderr, fmt, ##__VA_ARGS__); fflush(stderr); \
                                    } while (0)
#else
  #define debug_printf(...) ((void)0)
#endif
#define error_printf(fmt, ...) do { fprintf(stderr, fmt, ##__VA_ARGS__); fflush(stderr); \
                                  } while(0)

#ifndef strlcpy
#define strlcpy(a, b, c) do { \
    strncpy(a, b, (c)-1); \
    (a)[(c)-1] = '\0';    \
} while (0)
#endif

static int get_socket(char *host, char *port)
{
    int status;
    struct addrinfo addrHint, *addrList, *ap;
    int sockfd;
    struct timeval sockopt;

    memset(&addrHint, 0, sizeof(struct addrinfo));
    addrHint.ai_flags = AI_CANONNAME|AI_NUMERICSERV;
    addrHint.ai_family = AF_INET; /* we deal with IPv4 only, for now */
    addrHint.ai_socktype = SOCK_DGRAM;
    addrHint.ai_protocol = IPPROTO_UDP;
    addrHint.ai_addrlen = 0;
    addrHint.ai_canonname = NULL;
    addrHint.ai_addr = NULL;
    addrHint.ai_next = NULL;

    status = getaddrinfo(host, port, &addrHint, &addrList);
    if(status < 0) {
        error_printf("getaddrinfo: %s\n", gai_strerror(status));
        return status;
    }

    for(ap=addrList; ap!=NULL; ap=ap->ai_next) {
        sockfd = socket(ap->ai_family, ap->ai_socktype, ap->ai_protocol);
        if(sockfd < 0) continue;
        sockopt.tv_sec = 1;
        sockopt.tv_usec= 0;
        if(setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, (char*)&sockopt, sizeof(sockopt)) == -1) {
            close(sockfd);
            warn("setsockopt");
            continue;
        }
        break; /* success */
    }
    if(ap == NULL) { /* No address succeeded */
        error_printf("Could not connect, tried %s:%s\n", host, port);
        goto errout;
    }
    if(bind(sockfd, ap->ai_addr, ap->ai_addrlen) < 0) {
        error_printf("bind error.\n");
        goto errout;
    }
errout:
    freeaddrinfo(addrList);
    return sockfd;
}

int main(int argc, char **argv)
{
#define BUFLEN 2048
    char buf[BUFLEN];
    ssize_t i, errcnt, nret;
    int sockfd;
    struct sockaddr src_addr;
    struct sockaddr_in *src_addr_in;
    socklen_t addrlen;
    char addrbuf[BUFLEN];
    uint64_t cnt, cnt1;

    if(argc<3) {
        error_printf("%s adddress port\n", argv[0]);
        return EXIT_FAILURE;
    }

    sockfd = get_socket(argv[1], argv[2]);
    if(sockfd < 0) {
        error_printf("Failed to establish a socket.\n");
        return EXIT_FAILURE;
    }

    /* send something */
    src_addr_in = (struct sockaddr_in *)&src_addr;
    bzero(src_addr_in,sizeof(src_addr));
    src_addr_in->sin_family = AF_INET;
    src_addr_in->sin_addr.s_addr=inet_addr("192.168.3.2");
    src_addr_in->sin_port=htons(60002);
    *(uint32_t*)buf = 0x00abcdef;
    nret = sendto(sockfd, buf, 1000, 0, &src_addr, sizeof(src_addr));
    if(nret < 0) {
        error_printf("sendto returned %zd.\n", nret);
    }

    cnt1 = 0;
    errcnt = -1;
    for(i=0; i<10000000; i++) {
        addrlen = sizeof(src_addr);
        if((nret = recvfrom(sockfd, buf, BUFLEN, 0, &src_addr, &addrlen)) < 0) {
            if(errno != EINTR)
                alarm(0);
            error_printf("recv error\n");
        }
        /* printf("%02x %02x %02x %02x %02x %02x\n", (unsigned)buf[0],(unsigned)buf[1], */
        /*        (unsigned)buf[2],(unsigned)buf[3],(unsigned)buf[4],(unsigned)buf[5]); */
        cnt = *(uint64_t*)buf;
        if(cnt - cnt1 != 1) errcnt++;
        cnt1 = cnt;
    }
    printf("cnt = %ld, i = %zd, errcnt = %zd\n", cnt, i, errcnt);
    src_addr_in = (struct sockaddr_in *)&src_addr;
    inet_ntop(AF_INET, &src_addr_in->sin_addr, addrbuf, INET_ADDRSTRLEN);
    printf("%zd bytes received from %s:%d\n", nret, addrbuf, ntohs(src_addr_in->sin_port));
    close(sockfd);
    return EXIT_SUCCESS;
}
