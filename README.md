# Broadcast (120 bytes)

This is an code golf'd Linux ELF64 that broadcasts itself to udp port 60414 over
your lan (via 255.255.255.255 and setsockopts).

See the source (broadcast.asm)!

Usage:
```
box1 $ ./build.sh
box1 $ ./broadcast
box2 $ nc -q1 -vbul 0.0.0.0 60414 </dev/null > /tmp/out.elf
box2 $ /tmp/out.elf # yolo
```

GPL2
