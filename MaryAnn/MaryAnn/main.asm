;
; MaryAnn.asm
;
; Created: 3/5/2018 10:26:50 PM
; Author : trapper.mcferron
;
.include "macros.asm"

start:
	cli

    ldi r30, 0  ; constant always at 0

	;ldi r16, low(STACK_START)
	;out spl, r16

	;ldi r17, high(STACK_START)
	;out sph, r17

color_pins_init:
	; set PORTA0-3 as output (RGB)
	ldi r16, (1 << DDA0) | (1 << DDA1) | (1 << DDA2)
	out DDRA, r16

	; set hsync/prof sync as output
	ldi r16, (1 << DDD0) | (1 << DDD1) | (1 << DDD2)
	out DDRD, r16

    ; send vsync to prof
    SYNC_PULSE r16, 0, 1, 0

; wait for go signal
wait_for_go:
    ; input direction
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

    ; 8Mhz = 8,000,000 cycles in a second
    ; each cycle = 1/8uS
    ; 8 cycles = 1uS
    ; N cycles = uS * 8 

    ; prime registers
    ldi r17, 0

main_loop:
    rjmp inv_sync_pulse                ;6 lines
main_loop_inv_sync_pulse_done:

    rjmp send_blank_lines              ;14 lines
main_loop_send_blank_lines_done:

    rjmp send_color_data               ;242 lines
;main_loop_send_color_data_done:


send_color_data:
    ; sync pulse: hold low for 4.7uS (~37.6 cycles) 
    SYNC_PULSE r16, 0, 0, 0        ; 2 cycles

    HOLD_3 send_color_data_back_porch, r16, 0x0b   ; 35

    ; backporch/prime color burst
    ;SYNC_PULSE r16, 1, 0            ; 37
    SYNC_PULSE r16, 0, 0, 1          ; 37  (3v test)
    nop ; 38 (round 37.6 up)

    ; color burst: hold high for ~4.7uS (~37.6 cycles)
    HOLD_3 send_color_data_color_burst, r16, 12  ; 36   

send_color_data_write_line:
	; go...we have 52.6 uS 420.8 cycles
	; for the visible data

	; 13.15 cycles to push each color
	;WRITE_COLOR r16, 1, 0, 0    ; 13

    nop ;37
    nop ;38

    nop ;1
    nop ;2
    nop ;3
    nop ;4

    ; send full pulse
    SYNC_PULSE r16, 1, 0, 0     ; 5/6  (3v test)

    nop ;7
    nop ;8

    ; write red color with no hold
    HOLD_3 send_color_data_first_color, r16, 3  ; 17

	WRITE_PULSE r16, 0, 0, 1    ; 30
	WRITE_PULSE r16, 1, 0, 0    ; 43
	WRITE_PULSE r16, 0, 0, 1    ; 56
	WRITE_PULSE r16, 1, 0, 0    ; 69
	WRITE_PULSE r16, 0, 0, 1    ; 82
	WRITE_PULSE r16, 1, 0, 0    ; 95
	WRITE_PULSE r16, 0, 0, 1    ; 108
	WRITE_PULSE r16, 1, 0, 0    ; 121
	WRITE_PULSE r16, 0, 0, 1    ; 134
	WRITE_PULSE r16, 1, 0, 0    ; 147
	WRITE_PULSE r16, 0, 0, 1    ; 160
	WRITE_PULSE r16, 1, 0, 0    ; 173
	WRITE_PULSE r16, 0, 0, 1    ; 186
	WRITE_PULSE r16, 1, 0, 0    ; 199
	WRITE_PULSE r16, 0, 0, 1    ; 212
	WRITE_PULSE r16, 1, 0, 0    ; 225
	WRITE_PULSE r16, 0, 0, 1    ; 238
	WRITE_PULSE r16, 1, 0, 0    ; 251
	WRITE_PULSE r16, 0, 0, 1    ; 264
	WRITE_PULSE r16, 1, 0, 0    ; 277
	WRITE_PULSE r16, 0, 0, 1    ; 290
	WRITE_PULSE r16, 1, 0, 0    ; 303
	WRITE_PULSE r16, 0, 0, 1    ; 316
	WRITE_PULSE r16, 1, 0, 0    ; 329
	WRITE_PULSE r16, 0, 0, 1    ; 342
	WRITE_PULSE r16, 1, 0, 0    ; 355
	WRITE_PULSE r16, 0, 0, 1    ; 368
	WRITE_PULSE r16, 1, 0, 0    ; 381
	WRITE_PULSE r16, 0, 0, 1    ; 394
	WRITE_PULSE r16, 1, 0, 0    ; 407

    ; write red color with no hold
    ;ldi r16, (1 << RED) | (0 << GREEN) | (0 << BLUE)  ; 3
    ;out COLOR_PORT, r16                               ; 4

    ;HOLD_3 first_color, r16, 3  ; 13

	;WRITE_COLOR r16, 0, 1, 0    ; 26
	;WRITE_COLOR r16, 0, 0, 1    ; 39
	;WRITE_COLOR r16, 1, 0, 0    ; 52
	;WRITE_COLOR r16, 0, 1, 0    ; 65
	;WRITE_COLOR r16, 0, 0, 1    ; 78
	;WRITE_COLOR r16, 1, 0, 0    ; 91
	;WRITE_COLOR r16, 0, 1, 0    ; 104
	;WRITE_COLOR r16, 0, 0, 1    ; 117
	;WRITE_COLOR r16, 1, 0, 0    ; 130
	;WRITE_COLOR r16, 0, 1, 0    ; 143
	;WRITE_COLOR r16, 0, 0, 1    ; 156
	;WRITE_COLOR r16, 1, 0, 0    ; 169
	;WRITE_COLOR r16, 0, 1, 0    ; 182
	;WRITE_COLOR r16, 0, 0, 1    ; 195
	;WRITE_COLOR r16, 1, 0, 0    ; 208
	;WRITE_COLOR r16, 0, 1, 0    ; 221
	;WRITE_COLOR r16, 0, 0, 1    ; 234
	;WRITE_COLOR r16, 1, 0, 0    ; 247
	;WRITE_COLOR r16, 0, 1, 0    ; 260
	;WRITE_COLOR r16, 0, 0, 1    ; 273
	;WRITE_COLOR r16, 1, 0, 0    ; 286
	;WRITE_COLOR r16, 0, 1, 0    ; 299
	;WRITE_COLOR r16, 0, 0, 1    ; 312
	;WRITE_COLOR r16, 1, 0, 0    ; 325
	;WRITE_COLOR r16, 0, 1, 0    ; 338
	;WRITE_COLOR r16, 0, 0, 1    ; 351
	;WRITE_COLOR r16, 1, 0, 0    ; 364
	;WRITE_COLOR r16, 0, 1, 0    ; 377
	;WRITE_COLOR r16, 0, 0, 1    ; 390
	;WRITE_COLOR r16, 1, 0, 0    ; 403
	
    ; write last color with no hold
    ;ldi r16, (0 << RED) | (1 << GREEN) | (0 << BLUE)  ; 404
    ;out COLOR_PORT, r16                               ; 405
    ; black
    SYNC_PULSE r16, 0, 0, 1     ; 409  (3v test)
    ;nop ; 410
    inc r17 ; 410

    HOLD_3 send_color_data_final_color, r16, 3 ; 419

    ; front porch   1.5uS (12 cycles)
    SYNC_PULSE r16, 0, 0, 1  ; 420/1 cycles
    out COLOR_PORT, r30  ; 2
 
    ; last visible line?
    cpi r17, 242            ; 3
    brne send_color_data_loop  ; 4 (5 if taken)
    
    ldi r17, 0  ; 5
    SYNC_PULSE r16, 0, 1, 1  ; 7    (tell prof)

    nop ; 8

    rjmp main_loop  ; 10 (12 for the rjmp to get here)
    
send_color_data_loop:
    nop ; 6
    nop ; 7
    nop ; 8
    nop ; 9
    nop ; 10

    rjmp send_color_data         ; 12


    
.include "sync_pulse.asm"
