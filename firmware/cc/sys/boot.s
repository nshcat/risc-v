#########################################################################################################
## boot.s - Microcontroller boot and startup code
##
## Defined symbols:
##  _reset:         Reset vector. Is jumped to when µC resets. Jumps to _start.
##  _isr_common:    Common entry-point for interrupt handling. Will execute user-specified
##                  ISR according to interrupt vector table.
##  _irq_reg_save:  Scratch space for saved register contents during ISR execution
##  _start:         Main entry point. Sets up stack, .data and .bss contents, and calls C main().
##
## The C side of things is required to define at least two symbols:
##  main():         The C main function.
##  irq_vector:     Interrupt vector tabke: Read-only array of function pointers to user-specified
##                  ISRs.
#########################################################################################################


# Reset vector. Must be placed at address 0x0.
.align 4
.section .reset,"ax",%progbits   # The "ax" is required to make this section actually occupy memory when converting
.global _reset                   # to a flat binary
_reset:
    j _start
    
# Safe space for register contents during ISR execution
.align 4
.section .bss
.global _irq_reg_save
_irq_reg_save: .fill 20*4

# Address of ICU flag register
.set ICU_IRQ_FLAGS, 0x4004

# Address of current IRQ number, stored in the ICU
.set ICU_IRQ_ACTIVE_NUM, 0x4008

# Address of register containing the flag that triggered current IRQ
.set ICU_IRQ_ACTIVE_FLAG, 0x400C    

# Common IRQ handler. Must be placed at address 0x10.
.align 4
.section .isr_common,"ax",%progbits
.global _isr_common
_isr_common:
    # Save all registers
    # First, make space for t0 on the stack and save its contents. We need one register to construct the base address of the register
    # save field in data memory, and the data memory address space starts at 3000h, which is too high for a immediate field.
    addi sp, sp, -4
    sw t0, 0(sp)       
    
    # Now we can use t0 to build the address for the register contents save location
    lui t0, %hi(_irq_reg_save)
    addi t0, t0, %lo(_irq_reg_save)
    
    # Store all registers, other than t0
    sw x1, 0*4(t0)
    sw x2, 1*4(t0)
    sw x3, 2*4(t0)
    sw x4, 3*4(t0)
    sw x6, 4*4(t0) # x5 is t0
    sw x7, 5*4(t0)
    sw x8, 6*4(t0)
    sw x9, 7*4(t0)
    sw x10, 8*4(t0)
    sw x11, 9*4(t0)
    sw x12, 10*4(t0)
    sw x13, 11*4(t0)
    sw x14, 12*4(t0)
    sw x15, 13*4(t0)
    sw x16, 14*4(t0)
    sw x17, 15*4(t0) # We don't have to save the saved registers, since that's the job of the ISR function
    sw x28, 16*4(t0)
    sw x29, 17*4(t0)
    sw x30, 18*4(t0)
    sw x31, 19*4(t0)
    
    # Retrieve IRQ number. It is stored in the interrupt control unit.
    lui t0, %hi(ICU_IRQ_ACTIVE_NUM)
    addi t0, t0, %lo(ICU_IRQ_ACTIVE_NUM)
    lw t0, 0(t0)
    
    # Create offset: index * 4
    slli t0, t0, 2
    
    # Retrieve base address of interrupt vector table.
    lui t1, %hi(irq_vector)
    addi t1, t1, %lo(irq_vector)
    
    # Add IRQ number to retrieve absolute address inside vector table
    add t1, t1, t0
    
    # Load interrupt vector address
    lw t1, 0(t1)
    
    # If it's not zero, call it. 
    beq t1, zero, .is_zero
    jalr ra, 0(t1)
    j .restore
    
    # If entry was zero, call default handler
.is_zero:
    lui t1, %hi(_default_isr)
    addi t1, t1, %lo(_default_isr)
    jalr ra, 0(t1)
    
.restore:
    # Restore all registers
    # Build base address. The called ISR could have clobbered t0, so we have to recalculate it.
    lui t0, %hi(_irq_reg_save)
    addi t0, t0, %lo(_irq_reg_save)
    
    # Load most registers, except t0 and the saved registers
    lw x1, 0*4(t0)
    lw x2, 1*4(t0)
    lw x3, 2*4(t0)
    lw x4, 3*4(t0)
    lw x6, 4*4(t0)
    lw x7, 5*4(t0)
    lw x8, 6*4(t0)
    lw x9, 7*4(t0)
    lw x10, 8*4(t0)
    lw x11, 9*4(t0)
    lw x12, 10*4(t0)
    lw x13, 11*4(t0)
    lw x14, 12*4(t0)
    lw x15, 13*4(t0)
    lw x16, 14*4(t0)
    lw x17, 15*4(t0)
    lw x28, 16*4(t0)
    lw x29, 17*4(t0)
    lw x30, 18*4(t0)
    lw x31, 19*4(t0)
    
    # Since we subtracted 4 from the SP prior to saving it, we have to add it again after restoring t0.
    lw t0, 0(sp)
    addi sp, sp, 4
    
    # Return from ISR
    .word 0x0000007F


# Default ISR used when the common ISR encounters a nullptr inside the interrupt vector table.
# Clears the IRQ flag that triggered the interrupt and returns.
.align 4
.global _default_isr
.section .text
_default_isr:
    # Prepare address to triggered flag ICU register and load
    lui t0, %hi(ICU_IRQ_ACTIVE_FLAG)
    addi t0, t0, %lo(ICU_IRQ_ACTIVE_FLAG)
    lw t0, 0(t0)
    
    # Turn it into a mask
    not t0, t0
    
    # Prepare address of flag ICU register
    lui t1, %hi(ICU_IRQ_FLAGS)
    addi t1, t1, %lo(ICU_IRQ_FLAGS)
    
    # Load current value
    lw t2, 0(t1)
    
    # Clear triggered flag
    and t2, t2, t0
    
    # Store it back
    sw t2, 0(t1)
    
    # We are done
    ret
    

.align 4
.global _start
.section .text
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
