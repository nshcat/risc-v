OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH("riscv")
ENTRY(_start)
 
MEMORY
{
	FLASH (rx) : ORIGIN = 0x0000, LENGTH = 0x3000	/* 12K ROM  */
	SRAM  (rw) : ORIGIN = 0x3000, LENGTH = 0x1000	/* 4K SRAM  */
}

SECTIONS
{
	/DISCARD/ : { *(.note.gnu.build-id) }

	.text :
	{
		. = 0x000;
		*(.text._start)
		*(.text*)
		. = ALIGN(4);
	} > FLASH

	.rodata :
	{
		. = ALIGN(4);
		*(.rodata)
	} > FLASH
	
	.srodata :
	{
		. = ALIGN(4);
		*(.srodata)
	} > FLASH

	.data :
	{
		. = ALIGN(4);
		_sdata = .;        /* create a global symbol at data start */
		*(.data)           /* .data sections */
		*(.data*)          /* .data* sections */
		*(.sdata*)		   /* small data */

		. = ALIGN(4);
		_edata = .;        /* define a global symbol at data end */
	} >SRAM AT>FLASH	   /* Since we are only flashing the ROM, we need store all initializers
							  in .data in the ROM. The AT causes the contents to be stored right after the .text
							  section inside the address space of the FLASH (with address END_TEXT + 4)
							  instead of at address 0x2000 (BEGIN_SRAM). The labels _sdata and _edata are still
							  based on the SRAM segment though: _sdata is 0x2000 here. This allows a simple copy
							  of (_edata - _sdata) bytes from _sidata to _sdata. */

	.bss :
	{
		. = ALIGN(4);
		_sbss = .;
		*(.bss*)
		
		. = ALIGN(4);
		_ebss = .;
	} >SRAM
}

_sidata = LOADADDR(.data);


