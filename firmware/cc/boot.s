.align 4
.globl _start
_start:
	# Setup stack pointer
	li sp, 0x3FFF

	# Jump to main function
	jal main
	
.loop: j .loop
