;
; MaryAnn.asm
;
; Created: 3/5/2018 10:26:50 PM
; Author : trapper.mcferron
;
.include "macros.asm"

start:
	cli
    ldi r30, 0  ; Z registery low byte
    
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

    ; fill 90 bytes (3 bytes per tile, 30 tiles)
fill_buffer_line_1:
    ldi r31, high(SCAN_BUFFER)
    ldi r17, 0x00;0x55 //0101 0101
    ldi r16, 30 ; 31 tiles

fill_buffer_loop_line_1:
    st Z+, r17  ; -> red
    st Z+, r17  ; -> green
    st Z+, r17  ; -> blue
    dec r16
    brne fill_buffer_loop_line_1

    ; fill 90 bytes (3 bytes per tile, 30 tiles)
fill_buffer_line_2:
    ldi r31, high(SCAN_BUFFER)
    ldi r17, 0x00;0xaa //1010 1010
    ldi r16, 30 ; 31 tiles

fill_buffer_loop_line_2:
    st Z+, r17  ; -> red
    st Z+, r17  ; -> green
    st Z+, r17  ; -> blue
    dec r16
    brne fill_buffer_loop_line_2

    ; fill last byte with all black
    ldi r17, 0x0
    st Z+, r17

    ; set Y register low to ref this point
    ldi r28, 180    ;(90 + 90)

    ;SEND LED3 + b0 pull up resistor
    ldi r16, (1 << PORTB0) | (1 << PORTB1) | (1 << PORTB2) | (1 << PORTB3)
    out PORTB, r16

prepare:
    ; 8Mhz = 8,000,000 cycles in a second
    ; each cycle = 1/8uS
    ; 8 cycles = 1uS
    ; N cycles = uS * 8 

    ; prime registers
    ldi r17, 0  ; line count

    ldi r20, (0 << SR_TOGGLE)  ; buffer a
    ldi r21, (1 << SR_TOGGLE)  ; buffer b

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
    ldi r30, 0 ;6

send_color_data_skip_z_clear:
    
    ;PRIME_TILE r31, r16, Z ; 18    ;prime first tile into s1

    HOLD_3 send_color_data_back_porch, r16, 0x0b   ; 33

    nop ;34
    nop ;35
    nop ;36
    nop ;37
    ; backporch/prime color burst
    SYNC_PULSE r16, 1, 0           ; 2

    ; color burst: hold high for ~4.7uS (~37.6 cycles)
    HOLD_3 send_color_data_color_burst, r16, 12  ; 36   

send_color_data_write_line:
	; go...we have 52.6 uS 420.8 cycles
	; for the visible data

send_color_data_write_line_set_z:

    nop ;1
    nop ;2
    nop ;3
    nop ;4
    nop ;5

send_color_data_write_line_set_z_push_data:

	;out PORTC, r21 ; S0 outputs
	LOAD_TILE r31, r16, Z, r21 ; 29 [tile 1 is rendering | load tile 2]    (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 42 [tile 2 is rendering | load tile 3]    (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 55 [tile 3 is rendering | load tile 4]    (load and output S1)   
	LOAD_TILE r31, r16, Z, r20 ; 68 [tile 4 is rendering | load tile 5]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 81 [tile 5 is rendering | load tile 6]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 94 [tile 6 is rendering | load tile 7]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 107 [tile 7 is rendering | load tile 8]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 120 [tile 8 is rendering | load tile 9]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 133 [tile 9 is rendering | load tile 10]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 146 [tile 10 is rendering | load tile 11]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 159 [tile 11 is rendering | load tile 12]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 172 [tile 12 is rendering | load tile 13]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 185 [tile 13 is rendering | load tile 14]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 198 [tile 14 is rendering | load tile 15]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 211 [tile 15 is rendering | load tile 16]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 224 [tile 16 is rendering | load tile 17]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 237 [tile 17 is rendering | load tile 18]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 250 [tile 18 is rendering | load tile 19]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 263 [tile 19 is rendering | load tile 20]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 276 [tile 20 is rendering | load tile 21]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 289 [tile 21 is rendering | load tile 22]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 302 [tile 22 is rendering | load tile 23]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 315 [tile 23 is rendering | load tile 24]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 328 [tile 24 is rendering | load tile 25]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 341 [tile 25 is rendering | load tile 26]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 354 [tile 26 is rendering | load tile 27]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 367 [tile 27 is rendering | load tile 28]   (load and output S1)
	LOAD_TILE r31, r16, Z, r20 ; 380 [tile 28 is rendering | load tile 29]   (load and output S0)   
	LOAD_TILE r31, r16, Z, r21 ; 393 [tile 29 is rendering | load tile 30]   (load and output S1)
    
    WRITE_BLACK r29, r16, Y, r20 ; 406 [tile 30 is rendering | load tile 31 (black)] (load and output S0)

    HOLD_3 send_color_data_black, r16, 4  ; 418   

    nop ;419
    nop ;420
    nop ;421
    nop ;422

    nop ;432

    ; front porch   1.5uS (12 cycles.. 9 cycles, allowing for 3 roll over to start the sync pulse)
    SYNC_PULSE r16, 1, 0            ; 433/1

    ;out COLOR_PORT, r30  ; 2       ; POSSIBLE BUG: do we need to send all black here?
        nop ; 2


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
