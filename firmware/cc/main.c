#include "defines.h"


__attribute__((naked)) void handle_ext1()
{
	RETI;
}



int main()
{
	ISR_EXT1 = IRQ_HANDLER(handle_ext1);
	IRQ_MASK = 0x1;
	
	while(1);
	
	return 0;
}
