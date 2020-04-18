// Super fast blinky example meant to test debugger breakpoints and single stepping
#include "defines.h"

int main()
{
	// Disable all interrupts
	IRQ_MASK = 0x0;
	
	LED_STATE = 0b1010101010;
	
	while(1)
	{
	    LED_STATE = ~LED_STATE;
	}
	
	return 0;
}
