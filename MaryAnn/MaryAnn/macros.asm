;
; MaryAnn.asm
;
; Created: 3/5/2018 10:26:50 PM
; Author : trapper.mcferron
;
.equ STACK_START	= 0x0060

.equ COLOR_PORT		= PORTA
.equ RED    		= PORTA0
.equ GREEN_HI		= PORTA1
.equ GREEN_LO		= PORTA1
.equ BLUE           = PORTA3

.equ VIDEO_PORT		= PORTD
.equ HSYNC			= PORTD0
.equ VSYNC			= PORTD1

.MACRO WRITE_COLOR  ;need to take 13.15 cycles
	ldi @0, (@1 << RED) | (@2 << GREEN_HI) | (@3 << GREEN_LO) | (@3 << BLUE)  ; 13 cycle
    out COLOR_PORT, @0                                  ; 1
    nop ;  2
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
