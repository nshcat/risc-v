#define LED_STATE *((volatile unsigned*)0x4F00)

int main()
{
	LED_STATE = 0x1;
	return 0;
}
