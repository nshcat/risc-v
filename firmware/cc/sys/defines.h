#pragma once

typedef unsigned uint32_t;
typedef int int32_t;

// ===== I/O Register Definitions =====
#define IO_REG(_addr) *((volatile uint32_t*)(_addr))

#define LED_STATE IO_REG(0x40F0)		// LED status register

#define IRQ_MASK IO_REG(0x4000)			// IRQ mask register
#define IRQ_FLAGS IO_REG(0x4004)		// IRQ flags
#define IRQ_ACTIVE IO_REG(0x4008)       // Currently active IRQ index
#define IRQ_ACTIVE_FLAG IO_REG(0x400C)  // Flag that triggered currently active IRQ

#define EIC_EVENT_MASK IO_REG(0x4010)   // EIC event mask
#define EIC_DETECT_MASK IO_REG(0x4014)  // EIC edge detection mask
#define EIC_FLAGS IO_REG(0x4018)        // EIC pending event flags
#define EIC_ACTIVE IO_REG(0x401C)       // EIC active event flag
#define EIC_FALLING IO_REG(0x4020)      // EIC falling edge detection flags
#define EIC_RISING IO_REG(0x4024)       // EIC rising edge detection flags
#define EIC_DEBOUNCE IO_REG(0x4028)     // EIC debounce enable flags

#define IRQ_FLAG_TIM1 0b1               // IRQ flag for timer interrupt 1
#define IRQ_FLAG_TIM2 0b10              // IRQ flag for timer interrupt 2
#define IRQ_FLAG_EIC 0b100              // IRQ flag for extended interrupt controller

#define TIMER_ENABLE 0x1				// Timer enable flag in timer control register
#define TIMER_CMP_ENABLE 0x2            // Comparator output enable flag in timer control register
#define TIM1_CNTRL IO_REG(0x40A0)		// Timer 1 control register
#define TIM1_PRESCTH IO_REG(0x40A4)		// Timer 1 prescaler threshold
#define TIM1_CNTRTH IO_REG(0x40A8)		// Timer 1 counter threshold
#define TIM1_CMPV IO_REG(0x40AC)		// Timer 1 comparator value
#define TIM1_PRESCV IO_REG(0x40B0)		// Timer 1 prescaler value (read-only)
#define TIM1_CNTRV IO_REG(0x40B4)		// Timer 1 counter value (read-only)

#define TIM2_CNTRL IO_REG(0x40C0)		// Timer 2 control register
#define TIM2_PRESCTH IO_REG(0x40C4)		// Timer 2 prescaler threshold
#define TIM2_CNTRTH IO_REG(0x40C8)		// Timer 2 counter threshold
#define TIM2_CMPV IO_REG(0x40CC)		// Timer 2 comparator value
#define TIM2_PRESCV IO_REG(0x40D0)		// Timer 2 prescaler value (read-only)
#define TIM2_CNTRV IO_REG(0x40D4)		// Timer 2 counter value (read-only)

#define GPIO_INPUT_PIN 0x0
#define GPIO_OUTPUT_PIN 0x1
#define GPIO_DDR IO_REG(0x4034)			// GPIO port data direction register (0: Input, 1: Output)
#define GPIO_IN IO_REG(0x403C)			// GPIO port read values (bits only valid if corresponding pin is in input mode)
#define GPIO_OUT IO_REG(0x4038)			// GPIO port write values (bits only valid if corresponding pin is in output mode)

#define SYSTICK IO_REG(0x4030)			// Number of milliseconds elapsed since device boot
