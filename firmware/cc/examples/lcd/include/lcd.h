// Driver for 16x2 LCDs

#pragma once
#include "defines.h"

void lcd_init();
void lcd_clear();
void lcd_home();
void lcd_puts(const char* s);
void lcd_goto(unsigned char pos);
void lcd_on();
void lcd_off();
void lcd_blink();
void lcd_no_blink();
void lcd_cursor();
void lcd_no_cursor();
void lcd_set_cursor(unsigned char col, unsigned char row);
void lcd_custom_char(unsigned char loc, unsigned char map[]);
