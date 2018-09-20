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

    ;SEND LED1

xmem_init:
    ldi r16, 1 << SRE
    out MCUCR, r16

    ldi r16, (1 << XMM2) | (1 << XMM0)  //pc3+ open
    out XMBK, r16

    ;SEND LED2

pins_init:
    ; set sr toggle as output
	ldi r16, (1 << DDC7)
	out DDRD, r16

	; set hsync/prof vsync as output
	ldi r16, (1 << DDD0) | (1 << DDD1)
	out DDRD, r16

    ;SEND LED3

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

    ;SEND LED4

    ; fill 128 bytes (4 bytes per tile, 32 tiles)
fill_buffer:
    ldi r31, high(SCAN_BUFFER)
    ldi r17, 0xaa //0101 0101
    ldi r16, 32

fill_buffer_loop:
    st Z+, r17  ; -> red
    st Z+, r17  ; -> green hi
    st Z+, r17  ; -> green lo
    st Z+, r17  ; -> blue
    dec r16
    brne fill_buffer_loop

    ;SEND LED5

prepare:
    ; 8Mhz = 8,000,000 cycles in a second
    ; each cycle = 1/8uS
    ; 8 cycles = 1uS
    ; N cycles = uS * 8 

    ; prime registers
    ldi r17, 0  ; line count

    ldi r20, 0  ; buffer a
    ldi r21, 1  ; buffer b

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

    HOLD_3 send_color_data_back_porch, r16, 0x0b   ; 35

    ; backporch/prime color burst
    SYNC_PULSE r16, 1, 0           ; 37
    nop ; 38 (round 37.6 up)

    ; color burst: hold high for ~4.7uS (~37.6 cycles)
    HOLD_3 send_color_data_color_burst, r16, 12  ; 36   

    nop ;37
    nop ;38

send_color_data_write_line:
	; go...we have 52.6 uS 420.8 cycles
	; for the visible data

    ldi r30, 0  ;1  Z registery low byte
    nop ;2
    nop ;3

	WRITE_TILE r31, r16, Z, r20 ; 16
	WRITE_TILE r31, r16, Z, r21 ; 29    
	WRITE_TILE r31, r16, Z, r20 ; 42
	WRITE_TILE r31, r16, Z, r21 ; 55
	WRITE_TILE r31, r16, Z, r20 ; 68
	WRITE_TILE r31, r16, Z, r21 ; 81
	WRITE_TILE r31, r16, Z, r20 ; 94
	WRITE_TILE r31, r16, Z, r21 ; 107
	WRITE_TILE r31, r16, Z, r20 ; 120
	WRITE_TILE r31, r16, Z, r21 ; 133
	WRITE_TILE r31, r16, Z, r20 ; 146
	WRITE_TILE r31, r16, Z, r21 ; 159
	WRITE_TILE r31, r16, Z, r20 ; 172
	WRITE_TILE r31, r16, Z, r21 ; 185
	WRITE_TILE r31, r16, Z, r20 ; 198
	WRITE_TILE r31, r16, Z, r21 ; 211
	WRITE_TILE r31, r16, Z, r20 ; 224
	WRITE_TILE r31, r16, Z, r21 ; 237
	WRITE_TILE r31, r16, Z, r20 ; 250
	WRITE_TILE r31, r16, Z, r21 ; 263
	WRITE_TILE r31, r16, Z, r20 ; 276
	WRITE_TILE r31, r16, Z, r21 ; 289
	WRITE_TILE r31, r16, Z, r20 ; 302
	WRITE_TILE r31, r16, Z, r21 ; 315
	WRITE_TILE r31, r16, Z, r20 ; 328
	WRITE_TILE r31, r16, Z, r21 ; 341
	WRITE_TILE r31, r16, Z, r20 ; 354
	WRITE_TILE r31, r16, Z, r21 ; 367
	WRITE_TILE r31, r16, Z, r20 ; 380
	WRITE_TILE r31, r16, Z, r21 ; 393
	WRITE_TILE r31, r16, Z, r20 ; 406
	WRITE_TILE r31, r16, Z, r21 ; 419

    ; front porch   1.5uS (12 cycles)
    SYNC_PULSE r16, 1, 0            ; 420/1

    ;out COLOR_PORT, r30  ; 2       ; POSSIBLE BUG: do we need to send all black here?
        nop ; 1
        nop ; 2

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
