#include "delay.h"

void delay_ms(uint32_t dur)
{
    uint32_t start = SYSTICK;
    
    while(SYSTICK - start < dur)
        ;
}

void delay_us(uint32_t dur)
{
    // A single instruction (that is not a load) will take 60.61 ns, so we need
    // roughly 16.5 instructions to pass one microsecond.
    // We do 11 inside the loop, which comes to a total of 17 with the loop logic.
    for(uint32_t i = 0; i < dur; ++i) {
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
        __asm__ __volatile__ ("nop");
    }
}
