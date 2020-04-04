#include "defines.h"

#define PWM_VAL *((volatile unsigned*)0x3003)


IRQ_HANDLER void handle_tim1()
{
	LED_STATE = ~LED_STATE;
	GPIO_OUT = (~GPIO_OUT) & 0x1;
	
	PWM_VAL += 50;
	
	if(PWM_VAL >= 255)
		PWM_VAL = 0;

	TIM2_CMPV = PWM_VAL;
	

	RETI;
}


int main()
{
	LED_STATE = 0b1010101010;

	// Initial brightness value
	PWM_VAL = 127;
	
	// Setup GPIO
	GPIO_DDR = 0x1; 			// Set pin 0 to be an output, and pin 1 to be an input
	GPIO_OUT = 0x0; 			// Set initial state to LOW
	
	// Setup timer 1. It will be used to change brightness every 200 ms.
	TIM1_PRESCTH = 16499;		// Prescaler: 16.5MHz / 16500 => 1 KHz
	TIM1_CNTRTH = 199;			// Counter: 1KHz / 200 = 5 Hz
	
	TIM1_CNTRL = 0b1;			// Enable timer
	
	// Setup timer 2. It will be used to implement PWM.
	TIM2_PRESCTH = 164;			// Prescaler: 16.5MHz / 165 = 100 KHz
	TIM2_CNTRTH = 255;			// 256 steps of PWM resolution
	TIM2_CMPV = PWM_VAL;			// 50% initial brightness
	TIM2_CNTRL = 0b11;			// Enable timer and its comparator output
	
	// Setup timer interrupt for timer 1 that changes the brightness
	ISR_TIM1 = IRQ_HANDLER_ADDR(handle_tim1);
	IRQ_MASK = 0b100;
	
	while(1);
	
	return 0;
}
