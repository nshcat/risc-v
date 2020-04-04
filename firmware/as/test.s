		add t0, zero, zero
		li t1, 0x20
.copy:	bgtu t0, t1, .loop
		lw t2, 0(t0)
		addi t0, t0, 4
		j .copy
		
		
.loop:	j .loop
