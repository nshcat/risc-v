void handle_tim1();

// Important: A value of 0x0 is only allowed if the interrupt will never be fired (because it's masked, for example)
// since otherwise the corresponding interrupt flag will never be cleared.
void (*const irq_vector[4])(void) = {
    0x0,                /* External interrupt 1 */
    0x0,                /* External interrupt 2 */
    &handle_tim1,       /* Timer 1 interrupt */
    0x0                 /* Timer 2 interrupt */
};

