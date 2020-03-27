module top(
  input CLK,
  output LED0,
  output LED1,
  output LED2,
  output LED3,
  output LED4,
  output LED5,
  output LED6,
  output LED7,
  input INT0,
  input INT1,
  output TIM1_CMP,
  output TIM2_CMP,
  output TIM3_CMP
);

// PLL to get 18MHz clock
wire       sysclk;
wire       locked;
pll pll(
    .clock_in(CLK),
    .global_clock(sysclk),
    .locked(locked)
);


microcontroller mc(
  .clk(CLK),
  .reset(locked),
  .leds_out({LED7, LED6, LED5, LED4, LED3, LED2, LED1, LED0}),
  .int_ext1(INT0),
  .int_ext2(INT1),
  .tim1_cmp(TIM1_CMP),
  .tim2_cmp(TIM2_CMP),
  .tim3_cmp(TIM3_CMP)
);

endmodule		 

   
  
