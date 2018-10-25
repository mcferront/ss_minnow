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
    ldi r18, 0  ; store black

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

    ; fill 93 bytes (3 bytes per tile, 31 tiles)
fill_buffer_line_1:
    ldi r31, high(SCAN_BUFFER)
    ldi r17, 0x55 //0101 0101
    ldi r16, 31 ; 31 tiles

fill_buffer_loop_line_1:
    st Z+, r17  ; -> red
    st Z+, r17  ; -> green
    st Z+, r17  ; -> blue
    dec r16
    brne fill_buffer_loop_line_1

    ; fill 93 bytes (3 bytes per tile, 31 tiles)
fill_buffer_line_2:
    ldi r31, high(SCAN_BUFFER)
    ldi r17, 0xaa //1010 1010
    ldi r16, 31 ; 31 tiles

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
    ldi r28, 186    ;(93 + 93)

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

    HOLD_3 send_color_data_back_porch, r16, 0x0b   ; 35

    ; backporch/prime color burst
    SYNC_PULSE r16, 1, 0           ; 37
    nop ; 38 (round 37.6 up)

    ; color burst: hold high for ~4.7uS (~37.6 cycles)
    HOLD_3 send_color_data_color_burst, r16, 12  ; 36   

    nop ;37
    ;nop ;38

    ldi r16, 1 ;38

send_color_data_write_line:
	; go...we have 52.6 uS 420.8 cycles
	; for the visible data

send_color_data_write_line_set_z:
    
    and r16, r17    ; 1 <- r16 preloaded with a 1 right before this loop is called

    brne send_color_data_write_line_set_z_push_data ; 2/3 odd line? don't reset the counter
    ldi r30, 0 ;3

    ;nop ;2
    ;nop ;3
send_color_data_write_line_set_z_push_data:
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
	
    WRITE_BLACK r29, r16, Y, r21 ; 419

    ; front porch   1.5uS (12 cycles)
    SYNC_PULSE r16, 1, 0            ; 420/1

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
    nop ; 8
    nop ; 9
    nop ; 10

    rjmp send_color_data         ; 12


    
.include "sync_pulse.asm"
