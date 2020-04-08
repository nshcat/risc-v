#pragma once

#include "defines.h"

// Delay by the given number of milliseconds. This is quite precise since
// it uses the SysTick timer.
void delay_ms(uint32_t amount);

// Delay by the given number of microseconds. This is quite imprecise, and generally
// waits a bit longer than the given duration.
void delay_us(uint32_t amount);
