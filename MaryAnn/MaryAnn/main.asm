;
; MaryAnn.asm
;
; Created: 3/5/2018 10:26:50 PM
; Author : trapper.mcferron
;
.include "macros.asm"

start:
	cli
    
    ; set pb1,2,3 as output
	ldi r16, (1 << DDB1) | (1 << DDB2) | (1 << DDB3)
	out DDRB, r16

xmem_init:
    ldi r16, 1 << SRE
    out MCUCR, r16

    ldi r16, (1 << XMM2) //pc4+ open
    out SFIOR, r16

pins_init:
    ; set sr toggle as output
	ldi r16, (1 << DDC7)
	out DDRC, r16

	; set hsync/prof vsync as output
	ldi r16, (1 << DDD0) | (1 << DDD1)
	out DDRD, r16

    ;SEND LED1
    ldi r16, (1 << PORTB1)
    out PORTB, r16

; wait for go signal
wait_for_go:
    ; pull up resistor + LED1
    ldi r16, (1 << PORTB0) | (1 << PORTB1)
    out PORTB, r16

; wait loop
wait_for_go_loop:
    in r16, PINB
    andi r16, (1 << PINB0)
    brne wait_for_go_loop   ; wait until it's held low

    ;SEND LED2 + b0 pull up resistor
    ldi r16, (1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2)
    out PORTB, r16

    ; fill 30 tiles
    ldi r30, 0  ; Z registery low byte

fill_buffer_line_1:
    ldi r31, high(SCAN_BUFFER)
    ldi r17, 0x55 ;0101 0101
    ldi r16, 32 ; 30 tiles

fill_buffer_loop_line_1:
    st Z+, r17  ; -> red
    st Z+, r17  ; -> green
    st Z+, r17  ; -> blue
    dec r16
    brne fill_buffer_loop_line_1

    rjmp prepare

    ; fill 30 tiles
fill_buffer_line_2:
    ldi r31, high(SCAN_BUFFER)
    ldi r17, 0xaa   ;1010 1010 
    ldi r16, 30 ; 30 tiles

fill_buffer_loop_line_2:
    st Z+, r17  ; -> red
    st Z+, r17  ; -> green
    st Z+, r17  ; -> blue
    dec r16
    brne fill_buffer_loop_line_2

    ;SEND LED3 + b0 pull up resistor
    ldi r16, (1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2) | (1 << PORTB3)
    out PORTB, r16

prepare:
    ; 8Mhz = 8,000,000 cycles in a second
    ; each cycle = 1/8uS
    ; 8 cycles = 1uS
    ; N cycles = uS * 8 

    ; prime registers
    ldi r17, 0  ; line count0

    ldi r20, (0 << SR_PL)  ; pull low to load
    ldi r21, (1 << SR_PL)  ; pull high

	out PORTC, r20   ; SR1 start outputting

    ldi r30, 0 ;6
    PRIME_TILE r31, r16, Z+  ; tile 0

    SYNC_PULSE r16, 0, 1              

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

    ldi r16, 1 ;3
    and r16, r17    ; 4

    brne send_color_data_skip_z_clear ; 5/6 odd line? don't reset the counter
    nop ;5

    ldi r30, 0 ;6

send_color_data_skip_z_clear:
    
    HOLD_3 send_color_data_back_porch, r16, 0x09   ; 33

    nop ;34
    nop ;35
    nop ;36
    nop ;37
    nop ;38
    ; backporch/prime color burst
    SYNC_PULSE r16, 1, 0           ; 2

    ; color burst: hold high for ~4.7uS (~37.6 cycles)
    HOLD_3 send_color_data_color_burst, r16, 11  ; 35

    ;nop ; 36
    out PORTC, r20             ; 36
    out PORTC, r21             ; 37 [output tile 0]

send_color_data_write_line:
	; go...we have 52.6 uS 420.8 cycles
	; for the visible data

send_color_data_write_line_set_z:


send_color_data_write_line_set_z_push_data:

	LOAD_TILE r31, r16, Z+, r20, r21 ; 14 [tile 0 is rendering | load tile 1]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 28 [tile 1 is rendering | load tile 2]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 42 [tile 2 is rendering | load tile 3]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 56 [tile 3 is rendering | load tile 4]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 70 [tile 4 is rendering | load tile 5]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 84 [tile 5 is rendering | load tile 6]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 98 [tile 6 is rendering | load tile 7]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 112 [tile 7 is rendering | load tile 8]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 126 [tile 8 is rendering | load tile 9]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 140 [tile 9 is rendering | load tile 10]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 154 [tile 10 is rendering | load tile 11]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 168 [tile 11 is rendering | load tile 12]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 182 [tile 12 is rendering | load tile 13]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 196 [tile 13 is rendering | load tile 14]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 210 [tile 14 is rendering | load tile 15]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 224 [tile 15 is rendering | load tile 16]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 238 [tile 16 is rendering | load tile 17]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 252 [tile 17 is rendering | load tile 18]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 266 [tile 18 is rendering | load tile 19]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 280 [tile 19 is rendering | load tile 20]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 294 [tile 20 is rendering | load tile 21]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 308 [tile 21 is rendering | load tile 22]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 322 [tile 22 is rendering | load tile 23]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 336 [tile 23 is rendering | load tile 24]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 350 [tile 24 is rendering | load tile 25]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 364 [tile 25 is rendering | load tile 26]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 378 [tile 26 is rendering | load tile 27]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 392 [tile 27 is rendering | load tile 28]
	LOAD_TILE r31, r16, Z+, r20, r21 ; 406 [tile 28 is rendering | load tile 29]
	
    ;LOAD_TILE r31, r16, Z+, r20, r21 ; 420 [tile 29 is rendering | load tile 30]
	;LOAD_TILE r31, r16, Z+, r20, r21 ; 434 [tile 30 is rendering | load tile 31]

	PRIME_TILE r31, r16, Z+     ; 420 [tile 29 is rendering | prime tile 0]

    ; front porch   1.5uS (12 cycles.. 9 cycles, allowing for 3 roll over to start the sync pulse)
    SYNC_PULSE r16, 1, 0            ; 1/2


    ; last visible line?
    inc r17                 ; 3

    cpi r17, 242            ; 4
    brne send_color_data_loop  ; 5 (6 if taken)
    
    ldi r17, 0  ; 6
    SYNC_PULSE r16, 1, 1            ; 8

    rjmp main_loop  ; 10 (12 for the rjmp to get here)
    
send_color_data_loop:
    nop ; 7

    rjmp send_color_data         ; 9


    
.include "sync_pulse.asm"
