.align 4
.globl _start
_start:
	# Setup stack pointer
	li sp, 0x3FFF
	
	# Copy .data segment initializers
	lui t0, %hi(_sidata)		# Data source begin
	addi t0, t0, %lo(_sidata)		
	
	lui t1, %hi(_sdata)			# Data destination begin
	addi t1, t1, %lo(_sdata)
	
	lui t2, %hi(_edata)			# Data destination end
	addi t2, t2, %lo(_edata)
	
.copy_loop:
	bgeu t1, t2, .copy_end		# Stop if cur_dest > dest_end
	lw t3, 0(t0)
	sw t3, 0(t1)
	
	addi t0, t0, 4
	addi t1, t1, 4
	
	j .copy_loop
	
.copy_end:

	# Clear .bss section
	lui t0, %hi(_sbss)			# BSS begin
	addi t0, t0, %lo(_sbss)		
	
	lui t1, %hi(_ebss)			# BSS end
	addi t1, t1, %lo(_ebss)
	
.zero_loop:
	bgeu t0, t1, .zero_end
	sw zero, 0(t0)
	addi t0, t0, 4
	j .zero_loop

.zero_end:
	
	
	# Jump to main function
	jal main
	
.loop: j .loop
