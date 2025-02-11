#include <unistd.h>

#define SOL_SOCKET 1
#define AF_INET 2
#define SOCK_DGRAM 2
#define SO_BROADCAST 6

int main() {
    int s;
    int y;
    int buf[64];
    buf[0] = 0x39050002;
    buf[1] = 0xffffffff;

    s = syscall(41, AF_INET, SOCK_DGRAM, 0);
    syscall(54, s, SOL_SOCKET, SO_BROADCAST, &y, 4);
    syscall(44, s, "hello world\n", 13, 0, &buf, 16);
}
