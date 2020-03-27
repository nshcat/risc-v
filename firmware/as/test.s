		li t0, 0x2000
		li t1, 0xAABBCCDD
		sw t1, 0(t0)
		lw t2, 0(t0)
		
.loop:	j .loop
