#pragma once

typedef unsigned uint32_t;
typedef int int32_t;

// ===== Utilities =====
#define IRQ_HANDLER_ADDR(_fun) (uint32_t)&(_fun)
#define IRQ_HANDLER __attribute__((naked)) 

// ===== Custom Instructions =====
#define RETI do { __asm__ __volatile__ (".word 0x0000007F"); } while(0);


// ===== I/O Register Definitions =====
#define IO_REG(_addr) *((volatile uint32_t*)(_addr))

#define LED_STATE IO_REG(0x4F00)		// LED status register

#define IRQ_MASK IO_REG(0x4000)			// IRQ mask register
#define ISR_EXT1 IO_REG(0x4001)			// ISR address register for external interrupt 1
#define ISR_EXT2 IO_REG(0x4002)			// ISR address register for external interrupt 2
#define ISR_TIM1 IO_REG(0x4003)			// ISR address register for timer interrupt 1
#define ISR_TIM2 IO_REG(0x4004)			// ISR address register for timer interrupt 2
#define ISR_TIM3 IO_REG(0x4005)			// ISR address register for timer interrupt 3

#define TIMER_ENABLE 0x1				// Timer enable flag in control register
#define TIM1_CNTRL IO_REG(0x40A0)		// Timer 1 control register
#define TIM1_PRESCTH IO_REG(0x40A1)		// Timer 1 prescaler threshold
#define TIM1_CNTRTH IO_REG(0x40A2)		// Timer 1 counter threshold
#define TIM1_CMPV IO_REG(0x40A3)		// Timer 1 comparator value
#define TIM1_PRESCV IO_REG(0x40AA)		// Timer 1 prescaler value (read-only)
#define TIM1_CNTRV IO_REG(0x40AB)		// Timer 1 counter value (read-only)

#define TIM2_CNTRL IO_REG(0x40B0)		// Timer 2 control register
#define TIM2_PRESCTH IO_REG(0x40B1)		// Timer 2 prescaler threshold
#define TIM2_CNTRTH IO_REG(0x40B2)		// Timer 2 counter threshold
#define TIM2_CMPV IO_REG(0x40B3)		// Timer 2 comparator value
#define TIM2_PRESCV IO_REG(0x40BA)		// Timer 2 prescaler value (read-only)
#define TIM2_CNTRV IO_REG(0x40BB)		// Timer 2 counter value (read-only)

#define TIM3_CNTRL IO_REG(0x40C0)		// Timer 3 control register
#define TIM3_PRESCTH IO_REG(0x40C1)		// Timer 3 prescaler threshold
#define TIM3_CNTRTH IO_REG(0x40C2)		// Timer 3 counter threshold
#define TIM3_CMPV IO_REG(0x40C3)		// Timer 3 comparator value
#define TIM3_PRESCV IO_REG(0x40CA)		// Timer 3 prescaler value (read-only)
#define TIM3_CNTRV IO_REG(0x40CB)		// Timer 3 counter value (read-only)
