#pragma once

typedef unsigned uint32_t;
typedef int int32_t;

#define IO_REG(_addr) *((volatile uint32_t*)(_addr))

// ===== I/O Register Definitions =====
#define LED_STATE IO_REG(0x4F00)		// LED status register
