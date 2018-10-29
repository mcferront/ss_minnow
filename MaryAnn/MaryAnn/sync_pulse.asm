
inv_sync_pulse:
    ; inv sync pulse: hold high for 4.7uS (~37.6 cycles + 2 to get the data pushed out) 
    SYNC_PULSE r16, 1, 0        ; 2 cycles

    HOLD_3 inv_sync_pulse_back_porch, r16, 0x0b   ; 35

    nop ;36
    nop ;37
    nop ;38

    ; visible scan line data + front porch + backporc: 57uS (456 cycles)
    SYNC_PULSE r16, 0, 0          ; 40

    inc r17     ; 1

    HOLD_3 inv_sync_pulse_loop_line, r16, 148  ; 445


    ;out COLOR_PORT, r30  ; 2       ; POSSIBLE BUG: do we need to send all black here?
    nop ; 446
    nop ; 447

    nop ; 448
    nop ; 449
    nop ; 450

    ; last visible line?
    cpi r17, 6 ;451
    breq inv_sync_pulse_done    ; 452(453 if taken)

    nop ; 453
    nop ; 454
    nop ; 455

    rjmp inv_sync_pulse         ; 457

inv_sync_pulse_done:

    ldi r17, 0  ; 454
    rjmp main_loop_inv_sync_pulse_done      ; 456 (12 for the rjmp to get here)


send_blank_lines:
    ; sync pulse: hold low for 4.7uS (~37.6 cycles) 
    SYNC_PULSE r16, 0, 0        ; 2 cycles

    HOLD_3 send_blank_lines_back_porch, r16, 0x0c   ; 38

    ; backporch/prime color burst
    SYNC_PULSE r16, 1, 0           ; 39
    nop ; 40

    ; color burst: hold high for ~4.7uS (~37.6 cycles)
    HOLD_3 send_blank_lines_color_burst, r16, 8  ; 24

    inc r17     ; 25
    nop ; 26

    ; visible scan line data 52.6uS (420.8 cycles)
    HOLD_3 send_blank_lines_loop_line, r16, 139  ; 417

    nop ; 418
    nop ; 419

    ; front porch   1.5uS (12 cycles)
    SYNC_PULSE r16, 1, 0            ; 420/1
    ;out COLOR_PORT, r30  ; 2 ; POSSIBLE BUG: do we need to send all black here?

    nop ; 2

    cpi r17, 14                           ; 3
    breq send_blank_lines_done           ; 4 (5 if taken)

    nop ; 5
    nop ; 6
    nop ; 7
    nop ; 8
    nop ; 9
    nop ; 10
 
    ; more lines to go
    rjmp send_blank_lines                 ; 12

send_blank_lines_done:
    ; send vsync to prof
    ldi r17, 0  ; 6
    nop ; 7
    nop ; 8
    rjmp   main_loop_send_blank_lines_done  ; 10 (12 for the rjmp to get here)


