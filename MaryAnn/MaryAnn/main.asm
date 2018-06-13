;
; MaryAnn.asm
;
; Created: 3/5/2018 10:26:50 PM
; Author : trapper.mcferron
;
.equ STACK_START	= 0x0060

.equ COLOR_PORT		= PORTA
.equ RED    		= PORTA0
.equ GREEN			= PORTA1
.equ BLUE           = PORTA2

.equ VIDEO_PORT		= PORTD
.equ HSYNC			= PORTD0
.equ VSYNC			= PORTD1

.MACRO WRITE_COLOR  ;need to take 13.15 cycles
	ldi @0, (@1 << RED) | (@2 << GREEN) | (@3 << BLUE)  ; 1 cycle
    out COLOR_PORT, @0                                  ; 1 cycle = 2
    nop ;  3
    nop ;  4
    nop ;  5
    nop ;  6
    nop ;  7
    nop ;  8
    nop ;  9
    nop ;  10
    nop ;  11
    nop ;  12
    nop ;  13
.ENDMACRO

.macro SYNC_PULSE	;2 cycles
	ldi @0, (@1 << HSYNC) | (@2 << VSYNC)
	out VIDEO_PORT, @0
.endmacro

.macro HOLD_3	    ;3 cycles * iteration
	ldi @1, @2		;+1 cycle
@0:
	dec @1	        ;+1 cycle
	brne @0			;+2 cycles if taken, -1 cycle when not taken (cancels out the ldi)
.endmacro

start:
	cli

    ldi r30, 0  ; constant always at 0

	ldi r16, low(STACK_START)
	out spl, r16

	ldi r17, high(STACK_START)
	out sph, r17

color_pins_init:
	; set PORTA0-3 as output (RGB)
	ldi r16, (1 << DDA0) | (1 << DDA1) | (1 << DDA2)
	out DDRA, r16

	; set hsync/prof sync as output
	ldi r16, (1 << DDD0) | (1 << DDD1)
	out DDRD, r16

; wait for go signal
wait_for_go:
    ; output direction
    ldi r16, 0 
    out DDRB, r16

    ; pull up resistor 
    ldi r16, 1 << PORTB0
    out PORTB, r16

; wait loop
wait_for_go_loop:
    in r16, PINB
    andi r16, (1 << PINB0)
    breq wait_for_go_loop

    ; prime registers
    ldi r17, 0
    ldi r18, 0

    ; 8Mhz = 8,000,000 cycles in a second
    ; each cycle = 1/8uS
    ; 8 cycles = 1uS
    ; N cycles = uS * 8 
ntsc_hsync:
    ; back porch: hold low for 4.7uS (~37.6 cycles) 
    SYNC_PULSE r16, 0, 0            ; 2 cycles

    HOLD_3 back_porch, r16, 0x0b   ; 35

    ; prime color burst
    SYNC_PULSE r16, 1, 0            ; 37
    
    ; color burst: hold high for ~5uS (~49.6 cycles)
    HOLD_3 color_burst, r16, 0x10  ; 48

    inc r17     ; 49


ntsc_write_line:
	; go...we have 52.6 uS 420.8 cycles (round down to 420?)
	; for the scanline

	; 13.15 cycles to push each color
	WRITE_COLOR r16, 1, 0, 0    ; 13
	WRITE_COLOR r16, 0, 1, 0    ; 26
	WRITE_COLOR r16, 0, 0, 1    ; 39
	WRITE_COLOR r16, 1, 0, 0    ; 52
	WRITE_COLOR r16, 0, 1, 0    ; 65
	WRITE_COLOR r16, 0, 0, 1    ; 78
	WRITE_COLOR r16, 1, 0, 0    ; 91
	WRITE_COLOR r16, 0, 1, 0    ; 104
	WRITE_COLOR r16, 0, 0, 1    ; 117
	WRITE_COLOR r16, 1, 0, 0    ; 130
	WRITE_COLOR r16, 0, 1, 0    ; 143
	WRITE_COLOR r16, 0, 0, 1    ; 156
	WRITE_COLOR r16, 1, 0, 0    ; 169
	WRITE_COLOR r16, 0, 1, 0    ; 182
	WRITE_COLOR r16, 0, 0, 1    ; 195
	WRITE_COLOR r16, 1, 0, 0    ; 208
	WRITE_COLOR r16, 0, 1, 0    ; 221
	WRITE_COLOR r16, 0, 0, 1    ; 234
	WRITE_COLOR r16, 1, 0, 0    ; 247
	WRITE_COLOR r16, 0, 1, 0    ; 260
	WRITE_COLOR r16, 0, 0, 1    ; 273
	WRITE_COLOR r16, 1, 0, 0    ; 286
	WRITE_COLOR r16, 0, 1, 0    ; 299
	WRITE_COLOR r16, 0, 0, 1    ; 312
	WRITE_COLOR r16, 1, 0, 0    ; 325
	WRITE_COLOR r16, 0, 1, 0    ; 338
	WRITE_COLOR r16, 0, 0, 1    ; 351
	WRITE_COLOR r16, 1, 0, 0    ; 364
	WRITE_COLOR r16, 0, 1, 0    ; 377
	WRITE_COLOR r16, 0, 0, 1    ; 390
	WRITE_COLOR r16, 1, 0, 0    ; 403
	WRITE_COLOR r16, 0, 1, 0    ; 416

    ; all zeros for ref black
    out COLOR_PORT, r30  ; 417 cycle
    
    ; last visible line?
    cpi r17, 242            ; 418

    breq vsync_blank_lines  ; 419 (420 if taken)
    rjmp ntsc_hsync         ; 421

vsync_blank_lines:
    ldi r17, 0              ; 1

vsync_blank_lines_loop:
    ; inverted front porch: hold low for 4.7uS (~37.6 cycles) 
    SYNC_PULSE r16, 1, 0    ; 2 cycles

    HOLD_3 back_porch, r16, 0x0b   ; 36

    ; inverted prime color burst
    SYNC_PULSE r16, 0, 0           ; 37
    
    ; color burst: hold high for ~5uS (~49.6 cycles)
    HOLD_3 color_burst, r16, 0x10  ; 48

    ; blank scan line - 52.6uS (~420.8 cycles)
    HOLD_3 vsync_blank_lines_hold, r16, 137     ; 411 cycles, one line
    inc r17                 ; 412
    cpi r17, 20             ; 413
    brne vsync_blank_lines_loop  ; 414 (415 if taken)

    ; done with frame, going back to hsync
    ldi r17, 0              ; 416
    ;  tell prof a vblank is occuring
    SYNC_PULSE  r16, 0, 1   ; 417
    nop                     ; 418
    rjmp ntsc_hsync         ; 420
    