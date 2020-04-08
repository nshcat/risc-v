TARGET=flash
INTERNAL_SOURCES=./../../sys/boot.s $(SOURCES)
CC=riscv64-linux-gnu-gcc
OBJCOPY=riscv64-linux-gnu-objcopy
OBJDUMP=riscv64-linux-gnu-objdump
SIZE=riscv64-linux-gnu-size
NM=riscv64-linux-gnu-nm

CFLAGS=-nostdlib -Wl,--build-id=none -nostartfiles -march=rv32i -mabi=ilp32 -I./../../sys -I./include -T./../../sys/link.ld -g
LDFLAGS=

all: elf flat fpga copy mem_usage

elf: $(TARGET).elf

flat: $(TARGET).bin

fpga: $(TARGET).txt

$(TARGET).elf: $(INTERNAL_SOURCES)
	@$(CC) $(CFLAGS) -o $(TARGET).elf $(INTERNAL_SOURCES)
	@printf "%-8s %s\n" "CC" "$(INTERNAL_SOURCES)"
	
$(TARGET).bin: $(TARGET).elf
	@$(OBJCOPY) -O binary -j ".text" -j ".rodata" -j ".srodata" -j ".data" $(TARGET).elf $(TARGET).bin
	@printf "%-8s %s\n" "OBJCOPY" "$< -> $@"
	
$(TARGET).txt: $(TARGET).bin
	@xxd -g 4 -u -ps -c 4 $(TARGET).bin > $(TARGET).txt
	@printf "%-8s %s\n" "XXD" "$< -> $@"
	
mem_usage: $(TARGET).elf
	@$(SIZE) $(TARGET).elf | ./../../scripts/stats.py --mem-usage --flash-size=12288 --sram-size=4096 --newline
	
copy: $(TARGET).txt
	@cp $(TARGET).txt ./../../../../implementation/memory/
	@printf "%-8s %s\n" "CP" "$< -> /memory"
	
disasm: $(TARGET).elf
	@$(OBJDUMP) -dS $(TARGET).elf
	
sections: $(TARGET).elf
	@$(OBJDUMP) -s $(TARGET).elf
	
symbols: $(TARGET).elf
	@riscv64-linux-gnu-nm --print-size --size-sort --reverse-sort -td flash.elf | ./../../scripts/stats.py --newline --sym-size
	
clean:
	rm -rf *.o
	rm -rf *.elf
	rm -rf *.bin
	rm -rf *.txt

