void handle_tim1();

// A value of 0x0 causes a default ISR to be executed, which clears the triggered flag.
void (*const irq_vector[3])(void) = {
    &handle_tim1,       /* Timer 1 interrupt */
    0x0,                /* Timer 2 interrupt */
    0x0                 /* EIC interrupt */
};

