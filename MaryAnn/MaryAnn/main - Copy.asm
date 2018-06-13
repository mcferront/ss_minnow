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
.equ VSYNC_PROF		= PORTD2

.MACRO WRITE_COLOR  ;need to take 13.5 cycles
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

.macro VSYNC_PULSE	;2 cycles
	ldi @0, (@1 << VSYNC)
	out VIDEO_PORT, @0
.endmacro

.macro HSYNC_PULSE	;2 cycles
	ldi @0, (@1 << HSYNC)
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

color_pins_init:
	; set PORTA0-3 as output (RGB)
	ldi r16, (1 << DDA0) | (1 << DDA1) | (1 << DDA2)
	out DDRA, r16

	; set hsync/vsync as output
	ldi r16, (1 << DDD0) | (1 << DDD1) | (1 << DDD2)
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

ntsc_routine_start:
ntsc_vsync:
    ; first 6 equalization pulses
    ldi r17, 0x06
vsync_eq_pulse:
    ; 37.6 cycles for the first pulse
    VSYNC_PULSE r16, 0     ; 34.6 cycles left

    HOLD_3 vsync_eq_pulse_1, r19, 0x0a  ; 3.6 cycles left

    VSYNC_PULSE r16, 1  ; pulse! .6 cycle left
    
    ; scanline is 63.5 (508 cycles)
    ; we held for 37.6 cycles
    ; so we want to pulse again at the end - when 432 cycles remain
    HOLD_3 vsync_eq_pulse_2, r19, 0x8f  ; 3 cycles left
    dec r17; 2 cycles left
    brne vsync_eq_pulse ; 0 cycles left if taken
    
    ; synchronization pulses (3 with 2 serrations)
    ldi r17, 0x06
vsync_sync_pulse:
    ; scanline is 63.5 (508 cycles)
    ; hold low for half of it
    VSYNC_PULSE r16, 0  ;505 cycles left
    
    ; so we want to pulse in the middle with 235 cycles left
    HOLD_3 vsync_sync_pulse_1, r19, 0x4c    ; 7 cycles left
    nop ; 5 cycles left
    dec r17; 4 cycles left
    breq vsync_eq_pulse_post    ; 3 cycles left if not taken
    VSYNC_PULSE r16, 1          ; 0 cycles left
    
    ; hold for 37.6 cycles
    HOLD_3 vsync_sync_pulse_2, r19, 0x0b    ; 4.6 cycles left
    nop ; 3.6 cycles left
    nop ; 2.6 cycles left
    rjmp vsync_sync_pulse   ; 0.6 cycles left if taken
    
    ; last 6 equalization pulses
    ldi r17, 0x06
vsync_eq_pulse_post:
    ; 37.6 cycles for the first pulse
    VSYNC_PULSE r16, 0     ; 34.6 cycles left
    
    HOLD_3 vsync_eq_pulse_post_1, r19, 0x0a ; 4.6 cycles left
    nop ; 3.6 cycles left
    
    VSYNC_PULSE r16, 1  ; pulse! .6 cycle left
    
    ; scanline is 63.5 (508 cycles)
    ; we held for 37.6 cycles
    ; so we want to pulse again at the end - when 432 cycles remain
    HOLD_3 vsync_eq_pulse_post_2, r19, 0x8f ; 3 cycles left
    dec r17; 2 cycles left
    brne vsync_eq_pulse_post    ; 0 cycles left if taken

vsync_do_nothing:
    ; wait for 21-9 lines (12 lines: 762uS | 6,096 cycles)
    HOLD_3 vsync_wait_lines_a, r19, 0xff    ; 5331 cycles left
    HOLD_3 vsync_wait_lines_b, r19, 0xff    ; 4566 cycles left
    HOLD_3 vsync_wait_lines_c, r19, 0xff    ; 3801 cycles left
    HOLD_3 vsync_wait_lines_d, r19, 0xff    ; 3036 cycles left
    HOLD_3 vsync_wait_lines_e, r19, 0xff    ; 2271 cycles left
    HOLD_3 vsync_wait_lines_f, r19, 0xff    ; 1506 cycles left
    HOLD_3 vsync_wait_lines_g, r19, 0xff    ; 741 cycles left
    HOLD_3 vsync_wait_lines_h, r19, 0xf6    ; 3 cycles left

    ldi r16, (1 << VSYNC_PROF) | (1 << VSYNC)   ; 2 cycles left
    out VIDEO_PORT, r16    ; 33.6 cycle         ; 1 cycles left

    ldi r20, 0xf1   ;0 cycles left 240 lines (+1 because we dec first)
    
ntsc_hsync:
    ; blanking, 10.9uS (87.2 cycles)

    ; 1.5 uS and then we need HSYNC PULSE
    ; (12 cycles)

    ; is this the last line?  then move on to vsync
    dec r20                     ; 11 cycles left
    brne ntsc_hsync_continue    ; 10 cycles left (if branch not taken)
    jmp ntsc_vsync              ; do vsync again

ntsc_hsync_continue:

    HOLD_3 hsync_prepulse, r16, 0x02    ; 4 cycles left)
    nop ; 3 cycles left

    ; HSYNC low
    HSYNC_PULSE r16, 0          ; pulse! (this takes 3 cycles)

    ; hold for for 4.7uS    (37.6 cycles)
    HOLD_3 hsync_wait, r19, 0x0b    ; 4.6 cycles left
    nop ; 3 .6 cycles left

    HSYNC_PULSE r16, 1 ; pulse! (this takes 3 cycles)

    ; back porch, stall for 4.7 uS (37.6 cycles)
    HOLD_3 hsync_backporch_wait, r19, 0x0b  ; 4.7 cycles left
    nop     ; 3.7 cycles left

    ldi r17, 0  ; 2.7 cycles left
    nop; 1.7 cycles left
    nop;

ntsc_write_line:
	; go...we have 52.6 uS 420.8 cycles (round down to 420?)
	; for the scanline

	; 13.15 cycles to push each color
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0
	WRITE_COLOR r31, 0, 0, 1
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0
	WRITE_COLOR r31, 0, 0, 1
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0
	WRITE_COLOR r31, 0, 0, 1
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0
	WRITE_COLOR r31, 0, 0, 1
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0
	WRITE_COLOR r31, 0, 0, 1
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0
	WRITE_COLOR r31, 0, 0, 1
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0
	WRITE_COLOR r31, 0, 0, 1
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0
	WRITE_COLOR r31, 0, 0, 1
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0
	WRITE_COLOR r31, 0, 0, 1
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0
	WRITE_COLOR r31, 0, 0, 1
	WRITE_COLOR r31, 1, 0, 0
	WRITE_COLOR r31, 0, 1, 0

	ldi r31, 0           ; 1 cycle
    out COLOR_PORT, r31  ; 1 cycle = 2

	; 416 cycles
	nop
	
    jmp ntsc_hsync	;420 cycles