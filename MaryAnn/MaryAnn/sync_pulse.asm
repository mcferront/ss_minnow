
inv_sync_pulse:
    ; sync pulse: hold low for 4.7uS (~37.6 cycles)
    SYNC_PULSE r16, 1, 0        ; 2 cycles

    HOLD_3 inv_sync_pulse_back_porch, r16, 0x0b   ; 35

    nop ;36

    nop ;37
    nop ;x round

    ; breezeway + color burst + backporch + visible line + front porch: 58.8uS (~470.4 cycles)
    SYNC_PULSE r16, 0, 0          ; 1/2

    inc r17     ; 3

    HOLD_3 inv_sync_pulse_loop_line, r16, 152  ; 459

    nop ;460
    nop ;461

    ; last visible line?
    cpi r17, 6 ;462
    breq inv_sync_pulse_done    ; 463 (464 if taken)

    nop ; 464
    nop ; 465
    nop ; 466
    nop ; 467
    nop ; 468

    rjmp inv_sync_pulse         ; 470

inv_sync_pulse_done:

    ldi r17, 0  ; 465
    nop ;466
    rjmp main_loop_inv_sync_pulse_done      ; 468 ;allow time for main to rjmp


send_blank_lines:
    ; sync pulse: hold low for 4.7uS (~37.6 cycles)
    SYNC_PULSE r16, 0, 0        ; 2 cycles

    HOLD_3 send_blank_lines_back_porch, r16, 0x0b   ; 35

    nop ;36

    nop ;37
    nop ;x round

    ; breezeway + color burst + visible scan line data + front porch + backporch: 58.8uS (~470.4 cycles)
    SYNC_PULSE r16, 1, 0           ; 1/2

    inc r17     ; 3

    nop ;4
    nop ;5

    HOLD_3 send_blank_lines_color_burst, r16, 151  ; 458

    ; last visible line?
    cpi r17, 14     ; 459
    breq send_blank_lines_done           ; 460 (461 if taken)

    nop ; 461
    nop ; 462
    nop ; 463
    nop ; 464
    nop ; 465
    nop ; 466
    nop ; 467
    nop ; 468

    ; more lines to go
    rjmp send_blank_lines                 ; 470

send_blank_lines_done:

    ldi r17, 0  ; 462
    nop ;463

    ; notify prof
    SYNC_PULSE r16, 1, 1            ; 465

    nop ;466

    rjmp   main_loop_send_blank_lines_done  ; 468


