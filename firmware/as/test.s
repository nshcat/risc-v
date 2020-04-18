    lui t0, %hi(0x3003)
    addi t0, t0, %lo(0x3003)
    lui t1, %hi(0xAABBCCDD)
    addi t1, t1, %lo(0xAABBCCDD)
    sw t1, 0(t0)
    lw t2, 0(t0)
    
.loop:	j .loop
