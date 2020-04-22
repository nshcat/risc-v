#include "defines.h"
#include "delay.h"

uint32_t counter = 0;

void handle_eic()
{
    // Clear interrupt flag
    IRQ_FLAGS &= ~IRQ_FLAG_EIC;
    
    // React to button input
	if(EIC_ACTIVE == 0b1)
	{
	    counter++;
	    LED_STATE = counter;
	}
	
	// Clear EIC event flag
    EIC_FLAGS &= ~EIC_ACTIVE;
		
	// Rearm EIC for future events
	EIC_ACTIVE = 0;

	return;
}

int main()
{
    // Setup GPIO: We use the first pin as input.
    GPIO_DDR = GPIO_INPUT_PIN;
    
    // Setup EIC: We want to react to GPIO pin 1, and we want to detect a falling edge.
    EIC_DETECT_MASK = 0b1;  // Enable edge detection for pin 1
    EIC_EVENT_MASK = 0b1;   // Enable event handling for pin 1
    EIC_FALLING = 0b1;      // React to falling edges on pin 1
    EIC_DEBOUNCE = 0b1;     // Enable debouncing on pin 1
    
	// Enable interrupt handling for EIC events
	IRQ_MASK = IRQ_FLAG_EIC;
	
	while(1);
	
	return 0;
}
