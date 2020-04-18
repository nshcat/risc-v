// A value of 0x0 causes a default ISR to be executed, which clears the triggered flag.
void (*const irq_vector[4])(void) = {
    0x0,                /* External interrupt 1 */
    0x0,                /* External interrupt 2 */
    0x0,                /* Timer 1 interrupt */
    0x0                 /* Timer 2 interrupt */
};

