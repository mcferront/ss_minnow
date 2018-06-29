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
	; set PORTA0-3 as output (RGGB)
	ldi r16, (1 << DDA0) | (1 << DDA1) | (1 << DDA2) | (1 << DDA3)
	out DDRA, r16

	; set hsync/prof sync as output
	ldi r16, (1 << DDD0) | (1 << DDD1)
	out DDRD, r16

    ; send vsync to prof
    SYNC_PULSE r16, 0, 1

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
    brne wait_for_go_loop   ; wait until it's held low

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
    SYNC_PULSE r16, 0, 0        ; 2 cycles

    HOLD_3 send_color_data_back_porch, r16, 0x0b   ; 35

    ; backporch/prime color burst
    SYNC_PULSE r16, 1, 0           ; 37
    nop ; 38 (round 37.6 up)

    ; color burst: hold high for ~4.7uS (~37.6 cycles)
    HOLD_3 send_color_data_color_burst, r16, 12  ; 36   

send_color_data_write_line:
	; go...we have 52.6 uS 420.8 cycles
	; for the visible data

    nop ;37
    nop ;38

    nop ;1
    nop ;2
    nop ;3
    nop ;4

; BEGIN COLOR BAR TEST --------------------------------------
    ; write red color with no hold
    ldi r16, (1 << BLUE)                                 ; 5
    out COLOR_PORT, r16                               ; 6

    HOLD_3 first_color, r16, 3  ; 15
    nop ;16
    nop ;17

	WRITE_COLOR r16, 0, 0, 1, 0 ; 30
	WRITE_COLOR r16, 0, 0, 1, 1 ; 43
	WRITE_COLOR r16, 0, 1, 0, 0 ; 56
	WRITE_COLOR r16, 0, 1, 0, 1 ; 69
	WRITE_COLOR r16, 0, 1, 1, 0 ; 82
	WRITE_COLOR r16, 0, 1, 1, 1 ; 95
	WRITE_COLOR r16, 1, 0, 0, 0 ; 108
	WRITE_COLOR r16, 1, 0, 0, 1 ; 121
	WRITE_COLOR r16, 1, 0, 1, 0 ; 134
	WRITE_COLOR r16, 1, 0, 1, 1 ; 147
	WRITE_COLOR r16, 1, 1, 0, 0 ; 160
	WRITE_COLOR r16, 1, 1, 0, 1 ; 173
	WRITE_COLOR r16, 1, 1, 1, 0 ; 186
	WRITE_COLOR r16, 1, 1, 1, 1 ; 199
	WRITE_COLOR r16, 0, 0, 0, 0 ; 212
	WRITE_COLOR r16, 0, 0, 0, 1 ; 225
	WRITE_COLOR r16, 0, 0, 1, 0 ; 238
	WRITE_COLOR r16, 0, 0, 1, 1 ; 251
	WRITE_COLOR r16, 0, 1, 0, 0 ; 264
	WRITE_COLOR r16, 0, 1, 0, 1 ; 277
	WRITE_COLOR r16, 0, 1, 1, 0 ; 290
	WRITE_COLOR r16, 0, 1, 1, 1 ; 303
	WRITE_COLOR r16, 1, 0, 0, 0 ; 316
	WRITE_COLOR r16, 1, 0, 0, 1 ; 329
	WRITE_COLOR r16, 1, 0, 1, 0 ; 342
	WRITE_COLOR r16, 1, 0, 1, 1 ; 355
	WRITE_COLOR r16, 1, 1, 0, 0 ; 368
	WRITE_COLOR r16, 1, 1, 0, 1 ; 381
	WRITE_COLOR r16, 1, 1, 1, 0 ; 394
	WRITE_COLOR r16, 1, 1, 1, 1 ; 407
	
    ; write last color with no hold
    ldi r16, 0  ; 408
    out COLOR_PORT, r16                               ; 409

; END COLOR BAR TEST --------------------------------------

    inc r17 ; 410

    HOLD_3 send_color_data_final_color, r16, 3 ; 419

    ; front porch   1.5uS (12 cycles)
    SYNC_PULSE r16, 1, 0            ; 420/1
    out COLOR_PORT, r30  ; 2
 
    ; last visible line?
    cpi r17, 242            ; 3
    brne send_color_data_loop  ; 4 (5 if taken)
    
    ldi r17, 0  ; 5
    SYNC_PULSE r16, 1, 1            ; 7

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
