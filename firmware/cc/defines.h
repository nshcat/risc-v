#pragma once

typedef unsigned uint32_t;
typedef int int32_t;

// ===== Utilities =====
#define IRQ_HANDLER(_fun) (uint32_t)&(_fun)

// ===== Custom Instructions =====
#define RETI do { __asm__ volatile (".word 0x0000007F"); } while(0);


// ===== I/O Register Definitions =====
#define IO_REG(_addr) *((volatile uint32_t*)(_addr))

#define LED_STATE IO_REG(0x4F00)		// LED status register

#define IRQ_MASK IO_REG(0x4000)			// IRQ mask register
#define ISR_EXT1 IO_REG(0x4001)			// ISR address register for external interrupt 1
#define ISR_EXT2 IO_REG(0x4002)			// ISR address register for external interrupt 2


