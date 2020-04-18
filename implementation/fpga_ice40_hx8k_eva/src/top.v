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
  output TIM1_CMP,
  output TIM2_CMP,
  inout [15:0] GPIO_A
  
`ifdef FEATURE_DBG_PORT
  ,
  input UART_RX,
  output UART_TX
`endif

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
  .clk(sysclk),
  .reset(locked),
  .leds_out({LED7, LED6, LED5, LED4, LED3, LED2, LED1, LED0}),
  .tim1_cmp(TIM1_CMP),
  .tim2_cmp(TIM2_CMP),
  .gpio_port_a(GPIO_A)

`ifdef FEATURE_DBG_PORT
  , // Ugly, but needed
  .uart_rx(UART_RX),
  .uart_tx(UART_TX)
`endif
);

endmodule		 

   
  
