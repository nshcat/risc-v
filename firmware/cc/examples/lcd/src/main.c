#include "defines.h"
#include "lcd.h"


const char* messages[5] = {
    "Meow!",
    "Woof!",
    "Bark!",
    "Nya!",
    "Hello World!"
};

uint32_t current_msg = 0;
uint32_t counter = 0;

IRQ_HANDLER void handle_tim1()
{
	LED_STATE = ~LED_STATE;
	
	if(++counter >= 8)
	{
	    counter = 0;
	    current_msg = (current_msg == 4) ? 0 : current_msg + 1;
	    lcd_clear();
	    lcd_puts(messages[current_msg]);
	}

	RETI;
}

int main()
{
	LED_STATE = 0b1010101010;
	
	// Initialize LCD
	lcd_init();
	lcd_clear();
	lcd_no_cursor();
	lcd_no_blink();
	lcd_puts(messages[0]);
	
	// Setup timer 1. It will fire an interrupt every 200 ms.
	TIM1_PRESCTH = 16499;		                    // Prescaler: 16.5MHz / 16500 => 1 KHz
	TIM1_CNTRTH = 199;			                    // Counter: 1KHz / 200 = 5 Hz	
    ISR_TIM1 = IRQ_HANDLER_ADDR(handle_tim1);       // Setup timer interrupt for timer 1.
	IRQ_MASK = 0b100;
    TIM1_CNTRL = 0b1;			                    // Enable timer
	
	
	while(1);
	
	return 0;
}
