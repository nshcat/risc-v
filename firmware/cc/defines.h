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

#define GPIO_DDR IO_REG(0x4030)			// GPIO port data direction register (0: Input, 1: Output)
#define GPIO_IN IO_REG(0x4032)			// GPIO port read values (bits only valid if corresponding pin is in input mode)
#define GPIO_OUT IO_REG(0x4031)			// GPIO port write values (bits only valid if corresponding pin is in output mode)

#define SYSTICK IO_REG(0x4010)			// Number of milliseconds elapsed since device boot
