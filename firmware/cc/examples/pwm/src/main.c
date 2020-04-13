#include "defines.h"

uint32_t pwm_val = 127;

const uint32_t animation[10] = {
	0, 30, 70, 120, 180, 230, 180, 120, 70, 30
};

uint32_t counter;

void handle_tim1()
{
    // Clear interrupt flag
    IRQ_FLAGS &= ~IRQ_FLAG_TIM1;

	LED_STATE = ~LED_STATE;
	
	TIM2_CMPV = animation[counter];
	
	++counter;
	
	if(counter >= 10)
		counter = 0;

	return;
}

int main()
{
	LED_STATE = 0b1010101010;
	counter = 0;
	
	// Setup GPIO
	GPIO_DDR = 0x1; 			                    // Set pin 0 to be an output, and pin 1 to be an input
	GPIO_OUT = 0x0; 			                    // Set initial state to LOW
	
	// Setup timer 1. It will be used to change brightness every 200 ms.
	TIM1_PRESCTH = 16499;		                    // Prescaler: 16.5MHz / 16500 => 1 KHz
	TIM1_CNTRTH = 199;			                    // Counter: 1KHz / 200 = 5 Hz
	
	TIM1_CNTRL = TIMER_ENABLE;	                    // Enable timer
	
	// Setup timer 2. It will be used to implement PWM.
	TIM2_PRESCTH = 164;			                    // Prescaler: 16.5MHz / 165 = 100 KHz
	TIM2_CNTRTH = 255;			                    // 256 steps of PWM resolution
	TIM2_CMPV = 0;		                            // 0% initial brightness
	TIM2_CNTRL = TIMER_ENABLE | TIMER_CMP_ENABLE;	// Enable timer and its comparator output
	
	// Enable interrupt handling for timer interrupt 1
	IRQ_MASK = IRQ_FLAG_TIM1;
	
	while(1);
	
	return 0;
}
