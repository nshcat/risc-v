void handle_eic();

// A value of 0x0 causes a default ISR to be executed, which clears the triggered flag.
void (*const irq_vector[3])(void) = {
    0x0,                /* Timer 1 interrupt */
    0x0,                /* Timer 2 interrupt */
    &handle_eic         /* EIC interrupt */
};

