#include "defines.h"


IRQ_HANDLER void handle_tim1()
{
	RETI;
}


int main()
{
	TIM1_PRESCTH = 3U;
	TIM1_CNTRTH = 3U;

	ISR_TIM1 = IRQ_HANDLER_ADDR(handle_tim1);
	IRQ_MASK = 0b100;
	
	TIM1_CNTRL |= TIMER_ENABLE;
	
	while(1);
	
	return 0;
}
