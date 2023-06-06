//
//  DnsResolver.c
//  
//
//  Created by 冯学仕 on 2023/5/26.
//

#include <stdio.h>
#include <resolv.h>
#include <stdlib.h>
#include <arpa/inet.h>
#include <string.h>

char** get_localDns() {
    struct __res_state res;
    res_ninit(&res);
    char **address = NULL;
    int *count;
    *count = res.nscount;
    address = (char**)malloc(*count * sizeof(char*));
    for (int i; i < *count; i++) {
        char *dns = inet_ntoa(res.nsaddr_list[i].sin_addr);
        address[i] = strdup(dns);
    }
    return address;
}

void free_localDns(char** address, int count) {
    if (address == NULL)
        return;
    for (int i = 0; i < count; i++) {
        free(address[i]);
    }
    free(address);
}
