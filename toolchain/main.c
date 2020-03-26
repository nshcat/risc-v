#define ISR_TIM1 *((volatile int*)(0x4030))
#define LED_STATE *((volatile int*)(0x4000))
#define RETI do { __asm__ volatile (".word 0x10"); } while(0);

__attribute__((naked)) void handle_isr()
{
	LED_STATE = ~LED_STATE;
	RETI;
}



int main()
{
	ISR_TIM1 = (int)&handle_isr;

	int x = 3;
	int y = 2;
	int z = x + y;
	return z;
}
