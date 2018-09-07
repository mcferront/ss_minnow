;
; MaryAnn.asm
;
; Created: 3/5/2018 10:26:50 PM
; Author : trapper.mcferron
;
.equ STACK_START	= 0x0060
.equ TILE_VROM		= 0x0100
.equ SCAN_BUFFER	= 0x1000

.equ COLOR_PORT	= PORTC
.equ RED			   = PORTC2
.equ GREEN_LO	   = PORTC3
.equ GREEN_HI		= PORTC4
.equ BLUE			= PORTC5
.equ SR_TOGGLE		= PORTC7

.equ VIDEO_PORT	= PORTD
.equ HSYNC			= PORTD0
.equ VSYNC			= PORTD1

.macro WRITE_TILE
	ldi @0, high(SCAN_BUFFER) | high(RED)
	ld @1, @2+

	ldi @0, high(SCAN_BUFFER) | high(GREEN_LO)
	ld @1, @2+

	ldi @0, high(SCAN_BUFFER) | high(GREEN_HI)
	ld @1, @2+

	ldi @0, high(SCAN_BUFFER) | high(BLUE)
	ld @1, @2+

	out SR_TOGGLE, @3
.endmacro

.macro VSYNC_PULSE	;2 cycles
	ldi @0, @1
	out VIDEO_PORT, @0
.endmacro

.macro HSYNC_PULSE	;2 cycles
	ldi @0, @1
	out VIDEO_PORT, @0
.endmacro

.macro HOLD_3	;3 * iteration
	ldi @1, @2		;+1 cycle
@0:
	dec @1	
	brne @0			;-1 cycle when not taken
.endmacro

start:
	cli

	ldi r16, low(STACK_START)
	out spl, r16

	ldi r17, high(STACK_START)
	out sph, r17

xmem_init:
	;external memory need PC0-PC5
	ldi r16, (1 << XMM1)
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
	; first 6 equalization pulses
	ldi r17, 0x06
vsync_eq_pulse:
	; 37.6 cycles for the first pulse
	VSYNC_PULSE r16, (0 << VSYNC)		; 34.6 cycles left

	HOLD_3 vsync_eq_pulse_1, r19, 0x0a	; 4.6 cycles left
	nop ; 3.6 cycles left

	VSYNC_PULSE r16, (1 << VSYNC)	; pulse! .6 cycle left
	
	; scanline is 63.5 (508 cycles)
	; we held for 37.6 cycles
	; so we want to pulse again at the end - when 432 cycles remain
	HOLD_3 vsync_eq_pulse_2, r19, 0x8f	; 3 cycles left
	dec r17; 2 cycles left
	brne vsync_eq_pulse	; 0 cycles left if taken

	; synchronization pulses (3 with 2 serrations)
	ldi r17, 0x06
vsync_sync_pulse:
	; scanline is 63.5 (508 cycles)
	; hold low for half of it
	VSYNC_PULSE r16, (0 << VSYNC)	;505 cycles left

	; so we want to pulse in the middle with 235 cycles left
	HOLD_3 vsync_sync_pulse_1, r19, 0x4c	; 7 cycles left
	nop	; 5 cycles left
	dec r17; 4 cycles left
	breq vsync_eq_pulse_post	; 3 cycles left if not taken
	VSYNC_PULSE r16, (1 << VSYNC)			; 0 cycles left

	; hold for 37.6 cycles
	HOLD_3 vsync_sync_pulse_2, r19, 0x0b	; 4.6 cycles left
	nop ; 3.6 cycles left
	nop ; 2.6 cycles left
	rjmp vsync_sync_pulse	; 0.6 cycles left if taken


	; last 6 equalization pulses
	ldi r17, 0x06
vsync_eq_pulse_post:
	; 37.6 cycles for the first pulse
	VSYNC_PULSE r16, (0 << VSYNC)		; 34.6 cycles left

	HOLD_3 vsync_eq_pulse_post_1, r19, 0x0a	; 4.6 cycles left
	nop ; 3.6 cycles left

	VSYNC_PULSE r16, (1 << VSYNC)	; pulse! .6 cycle left
	
	; scanline is 63.5 (508 cycles)
	; we held for 37.6 cycles
	; so we want to pulse again at the end - when 432 cycles remain
	HOLD_3 vsync_eq_pulse_post_2, r19, 0x8f	; 3 cycles left
	dec r17; 2 cycles left
	brne vsync_eq_pulse_post	; 0 cycles left if taken

vsync_do_nothing:
	; wait for 21-9 lines (12 lines: 762uS | 6,096 cycles)
	HOLD_3 vsync_wait_lines_a, r19, 0xff	; 5331 cycles left
	HOLD_3 vsync_wait_lines_b, r19, 0xff	; 4566 cycles left
	HOLD_3 vsync_wait_lines_c, r19, 0xff	; 3801 cycles left
	HOLD_3 vsync_wait_lines_d, r19, 0xff	; 3036 cycles left
	HOLD_3 vsync_wait_lines_e, r19, 0xff	; 2271 cycles left
	HOLD_3 vsync_wait_lines_f, r19, 0xff	; 1506 cycles left
	HOLD_3 vsync_wait_lines_g, r19, 0xff	; 741 cycles left
	HOLD_3 vsync_wait_lines_h, r19, 0xf6	; 3 cycles left

	nop	; 2 cycles left
	nop	; 1 cycles left
	ldi r20, 0xf1	;0 cycles left 240 lines (+1 because we dec first)

ntsc_hsync:
	; blanking, 10.9uS (87.2 cycles)

	; 1.5 uS and then we need HSYNC PULSE
	; (12 cycles)

	; is this the last line?  then move on to vsync
	dec r20						; 11 cycles left
	brne ntsc_hsync_continue	; 10 cycles left (if branch not taken)
	jmp ntsc_vsync				; do vsync again

ntsc_hsync_continue:

	HOLD_3 hsync_prepulse, r16, 0x02	; 4 cycles left)
	nop	; 3 cycles left

	; HSYNC low
	HSYNC_PULSE r16, 0			; pulse! (this takes 3 cycles)

	; hold for for 4.7uS	(37.6 cycles)
	HOLD_3 hsync_wait, r19, 0x0b	; 4.6 cycles left
	nop	; 3 .6 cycles left

	HSYNC_PULSE r16, (1 << HSYNC)	; pulse! (this takes 3 cycles)

	; back porch, stall for 4.7 uS (37.6 cycles)
	HOLD_3 hsync_backporch_wait, r19, 0x0b	; 4.7 cycles left
	nop		; 3.7 cycles left

	ldi r17, 0	; 2.7 cycles left
	ldi r18, (1 << SR_TOGGLE)	; 1.7 cycles left
	ldi	r30, low(SCAN_BUFFER)	; .7 cycles left

ntsc_write_line:
	; go...we have 52.6 uS 420.8 cycles (round down to 420?)
	; for the scanline
	; 13.15 cycles to push each pixel to the shift registers
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	WRITE_TILE r31, r16, Z, r17	
	WRITE_TILE r31, r16, Z, r18	
	; 416 cycles

	nop	;417 cycle
	jmp ntsc_hsync	;420 cycles