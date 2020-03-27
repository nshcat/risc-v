TARGET=flash
SOURCES=main.c
INTERNAL_SOURCES=boot.s $(SOURCES) 
CC=riscv64-linux-gnu-gcc
OBJCOPY=riscv64-linux-gnu-objcopy
OBJDUMP=riscv64-linux-gnu-objdump

CFLAGS=-nostdlib -nostartfiles -march=rv32i -mabi=ilp32 -Tlink.ld -g
LDFLAGS=

all: elf flat fpga copy

elf: $(TARGET).elf

flat: $(TARGET).bin

fpga: $(TARGET).txt

$(TARGET).elf:
	$(CC) $(CFLAGS) -o $(TARGET).elf $(INTERNAL_SOURCES)
	
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary -j ".text" -j ".data" $(TARGET).elf $(TARGET).bin
	
$(TARGET).txt: $(TARGET).bin
	xxd -g 4 -u -ps -c 4 $(TARGET).bin > $(TARGET).txt 
	
copy: $(TARGET).txt
	cp $(TARGET).txt ./../../implementation/memory/
	
disasm: $(TARGET).elf
	$(OBJDUMP) -dS $(TARGET).elf
	
clean:
	rm -rf *.o
	rm -rf *.elf
	rm -rf *.bin
	rm -rf *.txt


