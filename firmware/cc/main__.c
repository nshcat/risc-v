#include "defines.h"

#define MEM_LOC *((volatile unsigned*)0x21AB)


IRQ_HANDLER void handle_tim1()
{
	MEM_LOC <<= 1;
	
	if(MEM_LOC == 0b100000000)
		MEM_LOC = 0x1;
		
	LED_STATE = MEM_LOC;

	RETI;
}


int main()
{
	MEM_LOC = 0b1;
	LED_STATE = MEM_LOC;
	
	TIM1_PRESCTH = 17999;		// Prescaler: 18MHz / 18000 => 1 KHz
	TIM1_CNTRTH = 199;			// Counter: 1KHz / 200 = 5 Hz
	TIM1_CNTRL = 0b1;			// Enable timer
	
	// Setup timer interrupt for timer 1 that changes the brightness
	ISR_TIM1 = IRQ_HANDLER_ADDR(handle_tim1);
	IRQ_MASK = 0b100;
	
	while(1);
	
	return 0;
}
