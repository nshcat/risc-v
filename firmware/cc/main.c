#include "defines.h"

#define PWM_VAL *((volatile unsigned*)0x2FFF)


IRQ_HANDLER void handle_tim1()
{
	LED_STATE = ~LED_STATE;
	PWM_VAL += 50;
	
	if(PWM_VAL >= 255)
		PWM_VAL = 0;

	TIM2_CMPV = PWM_VAL;

	RETI;
}


int main()
{
	LED_STATE = 0b1110111;

	// Initial brightness value
	PWM_VAL = 127;
	
	// Setup timer 1. It will be used to change brightness every 200 ms.
	TIM1_PRESCTH = 17999;		// Prescaler: 18MHz / 18000 => 1 KHz
	TIM1_CNTRTH = 199;			// Counter: 1KHz / 200 = 5 Hz
	
	TIM1_CNTRL = 0b1;			// Enable timer
	
	// Setup timer 2. It will be used to implement PWM.
	TIM2_PRESCTH = 179;			// Prescaler: 18MHz / 180 = 100 KHz
	TIM2_CNTRTH = 255;			// 256 steps of PWM resolution
	TIM2_CMPV = 217;			// 50% initial brightness
	TIM2_CNTRL = 0b11;			// Enable timer and its comparator output
	
	// Setup timer interrupt for timer 1 that changes the brightness
	ISR_TIM1 = IRQ_HANDLER_ADDR(handle_tim1);
	IRQ_MASK = 0b100;
	
	while(1);
	
	return 0;
}
