
inv_sync_pulse:
    ; inv sync pulse: hold high for 4.7uS (~37.6 cycles) 
    SYNC_PULSE r16, 1, 0, 0        ; 2 cycles

    HOLD_3 inv_sync_pulse_back_porch, r16, 0x0b   ; 35

    ; backporch/prime color burst
    ;SYNC_PULSE r16, 1, 0            ; 37
    SYNC_PULSE r16, 0, 0, 0          ; 37  (3v test)
    nop ; 38 (round 37.6 up)

    ; color burst: hold high for ~4.7uS (~37.6 cycles)
    HOLD_3 inv_sync_pulse_color_burst, r16, 12  ; 36   

    inc r17     ; 37
    nop ; 38 (round 37.6 up)

    ; visible scan line data 52.6uS (420.8 cycles)
    HOLD_3 inv_sync_pulse_loop_line, r16, 139  ; 417

    nop ; 418
    nop ; 419

    ; front porch   1.5uS (12 cycles)
    SYNC_PULSE r16, 0, 0, 0  ; 420/1 cycles
    out COLOR_PORT, r30  ; 2
 
    ; last visible line?
    cpi r17, 6 ;3
    breq inv_sync_pulse_done    ; 4 (5 if taken)

    nop ; 5
    nop ; 6
    nop ; 7
    nop ; 8
    nop ; 9
    nop ; 10

    rjmp inv_sync_pulse         ; 12

inv_sync_pulse_done:
    ldi r17, 0  ; 6
    nop ; 7
    nop ; 8
    rjmp main_loop_inv_sync_pulse_done      ; 10 (12 for the rjmp to get here)


send_blank_lines:
    ; sync pulse: hold low for 4.7uS (~37.6 cycles) 
    SYNC_PULSE r16, 0, 0, 0        ; 2 cycles

    HOLD_3 send_blank_lines_back_porch, r16, 0x0b   ; 35

    ; backporch/prime color burst
    ;SYNC_PULSE r16, 1, 0            ; 37
    SYNC_PULSE r16, 0, 0, 1          ; 37  (3v test)
    nop ; 38 (round 37.6 up)

    ; color burst: hold high for ~4.7uS (~37.6 cycles)
    HOLD_3 send_blank_lines_color_burst, r16, 12  ; 36   

    inc r17     ; 37
    nop ; 38 (round 37.6 up)

    ; visible scan line data 52.6uS (420.8 cycles)
    HOLD_3 send_blank_lines_loop_line, r16, 139  ; 417

    nop ; 418
    nop ; 419

    ; front porch   1.5uS (12 cycles)
    SYNC_PULSE r16, 0, 0, 1  ; 420/1 cycles
    out COLOR_PORT, r30  ; 2

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


