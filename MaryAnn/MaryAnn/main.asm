;
; MaryAnn.asm
;
; Created: 3/5/2018 10:26:50 PM
; Author : trapper.mcferron
;
.equ STACK_START	= 0x0060
.equ TILE_VROM		= 0x0100
.equ SCAN_BUFFER	= 0x1000

.equ COLOR_PORT		= PORTC
.equ RED			= PORTC3
.equ GREEN_LO		= PORTC4
.equ GREEN_HI		= PORTC5
.equ BLUE			= PORTC6
.equ SR_TOGGLE		= PORTC7

.equ VIDEO_PORT		= PORTD
.equ HSYNC			= PORTD0
.equ VSYNC			= PORTD1

.MACRO WRITE_TILE
	ldi @0, high(SCAN_BUFFER) | high(RED)
	ld @1, @2+

	ldi @0, high(SCAN_BUFFER) | high(GREEN_LO)
	ld @1, @2+

	ldi @0, high(SCAN_BUFFER) | high(GREEN_HI)
	ld @1, @2+

	ldi @0, high(SCAN_BUFFER) | high(BLUE)
	ld @1, @2+

	nop
.ENDMACRO

start:
	cli

	ldi r16, low(STACK_START)
	out spl, r16

	ldi r17, high(STACK_START)
	out sph, r17

xmem_init:
	;external memory need PC0, PC1
	ldi r16, (1 << XMM1) | (1 << XMM0)
	out SFIOR, r16

color_pins_init:
	; set shift register pins as output
	ldi r16, (1 << DDC3) | (1 << DDC4) | (1 << DDC5) | (1 << DDC6) | (1 << DDC7)
	out DDRC, r16

	; set vsync/hsync as output
	ldi r16, (1 << DDD0) | (1 << DDD1)
	out DDRD, r16


	;	load ram tiles
	;	tile format 8x8	- first line (8 pixels)
	;				r r r r r r r r		1 byte
	;				gggggggggggggggg	2 bytes
	;				b b b b b b b b		1 byte

	;				will be output as this 8 pixel line:
	;				|rggb|rggb|rggb|rggb|rggb|rggb|rggb|rggb|

tile_vrom_init:	
	ldi	r30, low(TILE_VROM)
	ldi r31, high(TILE_VROM)

	ldi	r16, 0x00	;8 pixels of red
	ldi	r17, 0x00	;8 pixels of green low
	ldi	r18, 0x00	;8 pixels of green hi
	ldi r19, 0x00	;8 pixels of blue

tile_routine:
	call store_tile
	inc r30
	brne tile_bit_1
	inc r31
tile_bit_1:
	cpi r16, 0xff
	breq tile_bit_2
	ldi r16, 0xff
	jmp tile_routine
tile_bit_2:
	cpi r17, 0xff
	breq tile_bit_3
	clr r16
	ldi r17, 0xff
	jmp tile_routine
tile_bit_3:
	cpi r18, 0xff
	breq tile_bit_4
	clr r16
	clr r17
	ldi r18, 0xff
	jmp tile_routine
tile_bit_4:
	cpi r19, 0xff
	breq tile_bit_done
	clr r16
	clr r17
	clr r18
	ldi r19, 0xff
	jmp tile_routine

store_tile:
	clr	r20

store_tile_row:
	st	Z+, r16
	st	Z+, r17
	st	Z+, r18
	st	Z+, r19

	inc r20
	cpi	r20, 0x8

	brne store_tile_row
	ret

tile_bit_done:
map_index_init:

	;	load tiles indices
	ldi	r30, low(SCAN_BUFFER)
	ldi r31, high(SCAN_BUFFER)

	; 32 tiles across, we created a tile for each color
	; so fill the scan buffer with each tile (twice)
	; and keep it the same for each scan line

	; Ginger will place tile addresses, not just indices
	; in the scan buffer so MaryAnn doesn't have to convert
	; tile 0
	ldi	r16, low(TILE_VROM)
	ldi	r17, high(TILE_VROM)
	clr r20
map_index_next:
	st	Z+, r16
	st	Z+, r17
	inc r16	;r16 won't go over 0xff, so no need to inc r17
	inc r20
	cpi r20, 0x40
	brne map_index_next


ntsc_routine_start:
ntsc_vsync:
	ldi r16, (1 << VSYNC)
	out VIDEO_PORT, r16

	ldi	r30, low(SCAN_BUFFER)

	; wait for scan line to start


	; 3 cycles each, 12 cycles total
	; 15 cycles with the dec and brne
	ldi r18, 0xf0	;240 lines

ntsc_hsync:
	; blanking, wait 10.9uS (87.2 cycles)
	; use this time to grab the sprite data and load the shift registers

	; is this the last line?  then move on to vsync
	dec r18			; 1 cycle
	breq ntsc_vsync	; 1 cycle if not taken
	
	; wait 1.5 uS before HSYNC (9 more cycles + triggering low)
	nop
	nop
	nop
	nop
	nop
	nop
	nop

	; HSYNC low
	ldi r16, 0				; 1 cycle
	out VIDEO_PORT, r16		; 2 cycles

	; hold for for 4.7uS	(37.6 cycles)
	
	ldi r19, 0x0a			; 1 cycle: load 30 / 3 cycles (10 iterations)
ntsc_hsync_wait:
	dec r19					; 1 cycle
	brne ntsc_hsync_wait	; 2 cycles if taken, 1 if not

	; 5 cycles remain
	ldi r16, (1 << HSYNC)	; 1 cycle
	out VIDEO_PORT, r16		; 2 cycles

	; back porch, stall for 4.7 uS (37.6 cycles)

	ldi r19, 0x0b			; 1 cycle: load 33 / 3 cycles (11 iterations)
ntsc_backporch_wait:
	dec r19						; 1 cycle
	brne ntsc_backporch_wait	; 2 cycles if taken, 1 if not

	nop
	nop
	nop
ntsc_write_line:
	; go...we have 52.6 uS 420.8 cycles (round down to 420?)
	; for the scanline
	; 13.15 cycles to push each pixel to the shift registers
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	WRITE_TILE r31, r16, Z	
	; 416 cycles
	nop
	nop
	nop
	nop