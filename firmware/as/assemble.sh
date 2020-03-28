#! /bin/bash

riscv64-linux-gnu-as -march=rv32i test.s
riscv64-linux-gnu-objcopy -O binary -j ".text" a.out test.bin
xxd -g 4 -u -ps -c 4 test.bin > ./../../implementation/memory/flash.txt
rm test.bin
rm a.out
