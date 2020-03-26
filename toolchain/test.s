		li t0, 31
		li t1, 63
		add t2, t0, t1  
		beq t2, t2, .loop
		nop
.loop:	j .loop
