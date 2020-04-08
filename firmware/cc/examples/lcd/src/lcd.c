#include "lcd.h"
#include "delay.h"


// LCD commands
typedef enum {
    LCD_CLEAR_DISPLAY = 0x01,
    LCD_RETURN_HOME = 0x02,
    LCD_ENTRY_MODE_SET = 0x04,
    LCD_DISPLAY_CONTROL = 0x08,
    LCD_CURSOR_SHIFT = 0x10,
    LCD_FUNCTION_SET = 0x20,
    LCD_SET_CGRAM_ADDR = 0x40,
    LCD_SET_DDRAM_ADDR = 0x80
} lcd_command_t;

// LCD display entry mode flags
typedef enum {
    LCD_ENTRY_RIGHT = 0x00,
    LCD_ENTRY_LEFT = 0x02,
    LCD_ENTRY_SHIFT_INC = 0x01,
    LCD_ENTRY_SHIFT_DEC = 0x00
} lcd_display_entry_mode_t;

// LCD control flags
typedef enum {
    LCD_DISPLAY_ON = 0x04,
    LCD_DISPLAY_OFF = 0x00,
    LCD_CURSOR_ON = 0x02,
    LCD_CURSOR_OFF = 0x00,
    LCD_BLINK_ON = 0x01,
    LCD_BLINK_OFF = 0x00
} lcd_display_control_t;

// LCD cursor/display shift
typedef enum {
    LCD_DISPLAY_MOVE = 0x08,
    LCD_CURSOR_MOVE = 0x00,
    LCD_MOVE_RIGHT = 0x04,
    LCD_MOVE_LEFT = 0x00
} lcd_display_shift_t;

// LCD function flags
typedef enum {
    LCD_8BIT_MODE = 0x10,
    LCD_4BIT_MODE = 0x00,
    LCD_2LINE = 0x08,
    LCD_1LINE = 0x00,
    LCD_5X10_DOTS = 0x04,
    LCD_5X8_DOTS = 0x00
} lcd_function_t;

// Helper macros for low-level output pin manipulation
#define LCD_STROBE_ON GPIO_OUT |= 0x20;
#define LCD_STROBE_OFF GPIO_OUT &= ~(0x20);
#define LCD_STROBE do{LCD_STROBE_ON LCD_STROBE_OFF} while(0);
#define LCD_RS_OFF do{GPIO_OUT &= ~(0x10);} while(0);
#define LCD_RS_ON do{GPIO_OUT |= 0x10;} while(0);

#define LCD_COLS 16
#define LCD_ROWS 2

// The current LCD state. Assumes 2 line display.
uint32_t lcd_display_state = LCD_4BIT_MODE | LCD_2LINE | LCD_5X8_DOTS | LCD_DISPLAY_ON;

// Row offsets
uint32_t lcd_row_offsets[2] = { 0x00, 0x40 };

// Write a byte of data to the LCD driver. The calling code has to decide if its meant
// to be interpreted as a command or data by setting the RS pin accordingly.
void lcd_write_raw(unsigned char c)
{
    GPIO_OUT = (GPIO_OUT & 0xF0) | (c >> 4);
    LCD_STROBE;
    GPIO_OUT = (GPIO_OUT & 0xF0) | (c & 0x0F);
    LCD_STROBE;
    delay_us(40U);
}

void setup_pins()
{
    // Pins:
    // 0-3 to D4-D7    T1 T2 R2 T3
    // 4 to RS         R3
    // 5 to EN         R4
    GPIO_DDR = 0b111111;
    GPIO_OUT = 0x0;
}

// Send a command. This will pull RS low.
void lcd_command(unsigned char c)
{
    LCD_RS_OFF;
    lcd_write_raw(c);
}

// Send data. This will pull RS high.
void lcd_write(unsigned char c)
{
    LCD_RS_ON;
    lcd_write_raw(c);
}

void lcd_set_cursor(unsigned char col, unsigned char row)
{
    if(col >= LCD_COLS)
        col = LCD_COLS - 1;
        
    if(row >= LCD_ROWS)
        row = LCD_ROWS - 1;
        
    lcd_command(LCD_SET_DDRAM_ADDR | (col + lcd_row_offsets[row]));
}

void lcd_clear()
{
    lcd_command(LCD_CLEAR_DISPLAY);
    delay_ms(2U); // This command takes a long time
}

void lcd_home()
{
    lcd_command(LCD_RETURN_HOME);
    delay_ms(2U); // This command takes a long time
}

void lcd_puts(const char* s)
{
    LCD_RS_ON;
    while(*s)
    {
        lcd_write_raw(*s++);
    }
}

void lcd_goto(unsigned char pos)
{
    LCD_RS_OFF;
    lcd_write(0x80 + pos);
}

void lcd_on()
{
    lcd_display_state |= LCD_DISPLAY_ON;
    lcd_command(LCD_DISPLAY_CONTROL | lcd_display_state);
}

void lcd_off()
{
    lcd_display_state &= ~LCD_DISPLAY_ON;
    lcd_command(LCD_DISPLAY_CONTROL | lcd_display_state);
}

void lcd_blink()
{
    lcd_display_state |= LCD_BLINK_ON;
    lcd_command(LCD_DISPLAY_CONTROL | lcd_display_state);
}

void lcd_no_blink()
{
    lcd_display_state &= ~LCD_BLINK_ON;
    lcd_command(LCD_DISPLAY_CONTROL | lcd_display_state);
}

void lcd_cursor()
{
    lcd_display_state |= LCD_CURSOR_ON;
    lcd_command(LCD_DISPLAY_CONTROL | lcd_display_state);
}

void lcd_no_cursor()
{
    lcd_display_state &= ~LCD_CURSOR_ON;
    lcd_command(LCD_DISPLAY_CONTROL | lcd_display_state);
}

void lcd_custom_char(unsigned char loc, unsigned char map[])
{
    // Make sure to only accept locations with index in [0, 8).
    loc &= 0x7;
    lcd_command(LCD_SET_CGRAM_ADDR | (loc << 3));
    for(uint32_t i = 0; i < 8; ++i)
    {
        lcd_write(map[i]);
    }
}

void lcd_init()
{
    setup_pins();

    LCD_RS_OFF;
    delay_ms(15U);
    GPIO_OUT &= 0xF0;
    GPIO_OUT |= 0x3;
    LCD_STROBE;
    delay_ms(5U);
    LCD_STROBE;
    delay_us(150U);
    LCD_STROBE;
    delay_ms(5U);
    GPIO_OUT &= 0xF0;
    GPIO_OUT |= 0x2;
    LCD_STROBE;
    delay_us(40U);
    lcd_write_raw(0x28);
    lcd_write_raw(0x08);
    lcd_write_raw(0x0F);
    lcd_write_raw(0x06);
}
