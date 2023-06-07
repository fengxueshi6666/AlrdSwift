//
//  DnsResolver.c
//  
//
//  Created by 冯学仕 on 2023/5/26.
//

#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <string.h>

char** get_localDns() {
    struct addrinfo hints, *res, *p;
    int status;
    char ipstr[INET6_ADDRSTRLEN];
    char** dnsServers = NULL;
    int i = 0;
    int *count = 0;

    // 设置 hints 结构体
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;  // IPv4 或 IPv6
    hints.ai_socktype = SOCK_STREAM;

    // 获取本机地址信息
    if ((status = getaddrinfo("localhost", NULL, &hints, &res)) != 0) {
        fprintf(stderr, "getaddrinfo error: %s\n", gai_strerror(status));
        return NULL;
    }

    // 计算地址数量
    for (p = res; p != NULL; p = p->ai_next) {
        (*count)++;
    }

    // 动态分配数组空间
    dnsServers = (char**)malloc((*count) * sizeof(char*));
    if (dnsServers == NULL) {
        fprintf(stderr, "Memory allocation error\n");
        freeaddrinfo(res);
        return NULL;
    }

    // 遍历地址信息并保存 DNS 服务器地址
    for (p = res; p != NULL; p = p->ai_next) {
        void *addr;

        // 获取地址指针
        if (p->ai_family == AF_INET) {
            struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
            addr = &(ipv4->sin_addr);
        } else {
            struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)p->ai_addr;
            addr = &(ipv6->sin6_addr);
        }

        // 将地址转换为可打印的字符串
        inet_ntop(p->ai_family, addr, ipstr, sizeof ipstr);

        // 分配内存并复制字符串
        dnsServers[i] = (char*)malloc((strlen(ipstr) + 1) * sizeof(char));
        if (dnsServers[i] == NULL) {
            fprintf(stderr, "Memory allocation error\n");
            freeaddrinfo(res);

            // 释放之前分配的内存
            for (int j = 0; j < i; j++) {
                free(dnsServers[j]);
            }
            free(dnsServers);

            return NULL;
        }

        strcpy(dnsServers[i], ipstr);
        i++;
    }

    freeaddrinfo(res);

    return dnsServers;
}

void freeDNSServers(char** dnsServers, int count) {
    if (dnsServers == NULL) {
        return;
    }

    // 释放内存
    for (int i = 0; i < count; i++) {
        free(dnsServers[i]);
    }

    free(dnsServers);
}

