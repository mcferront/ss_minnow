PR_CONTROLLER  = $02f8  ; $02f8-02ff (8 8bit controller datas)

PR_CMD_ID_STRING     = $01  ;output sz
PR_CMD_ID_CONTROLLER = $02  ;how many times to poll the controller
PR_CMD_ID_END        = $ff  ;no more data
PR_START_LOW         = $00  ;256 bytes
PR_START_HIGH        = $02  ;256 bytes

LOW_CHAR          = MEM_ZP_TEMP_1
HIGH_CHAR         = MEM_ZP_TEMP_2
PR_NEXT_SLOT_LOW  = MEM_ZP_TEMP_3
PR_NEXT_SLOT_HIGH = MEM_ZP_TEMP_4

CONTROLLER_UP      = $01
CONTROLLER_DOWN    = $02
CONTROLLER_LEFT    = $04
CONTROLLER_RIGHT   = $08
CONTROLLER_A       = $10
CONTROLLER_B       = $20
CONTROLLER_C       = $40
CONTROLLER_START   = $80

prof_begin_packet:
   pha
   
   lda   #PR_START_LOW
   sta   PR_NEXT_SLOT_LOW
   
   lda   #PR_START_HIGH
   sta   PR_NEXT_SLOT_HIGH
   
   pla
   rts

prof_end_packet:
   pha
   
   lda   #PR_CMD_ID_END
   jsr   prof_write_byte
   
   pla
   rts
   
   ; a is overwritten
; y is overwritten
prof_write_string:
	pla
	sta   LOW_CHAR	            ; low return address - 1
    
	pla
	sta   HIGH_CHAR            ; high return address

   ldy   #$0                  ; clear x, y
   
   lda   #PR_CMD_ID_STRING       ; load our command header
   jsr   prof_write_byte
   
print_loop:
   jsr   move_to_next_char

print_loop_done:   
   lda	(LOW_CHAR), y        ; pull byte from mem, rolling over to temp_2 if needed
   
print_char:
   beq   print_done           ; if it's the null terminator we are done
   cmp   #$25	               ; is it a '%' signifying a hex character?
	beq   print_special        ; if so then go to special char
   
   jsr   prof_write_byte
   jmp   print_loop
   
print_done:
   jsr   prof_write_byte
   jsr   move_to_next_char
   jmp   (LOW_CHAR)           ; jump back to calling method
   
print_special:
   jsr   move_to_next_char
   lda	(LOW_CHAR), y        ; pull byte from mem, rolling over to temp_2 if needed
   cmp   #$78	               ;' x' ?
   beq   print_hex

   cmp   #$62	               ;' b' ?
   beq   print_bool

   pla                        ; not 'x'? pull whatever it was and ignore it
   jmp   print_loop
   
print_bool:
   pla                        ; special chars are on the stack
   beq   print_bool_0
   lda   #$31                 ; '1'
   jmp   print_bool_done
print_bool_0:
   lda   #$30                 ; '0'
print_bool_done:
   jsr   prof_write_byte
   jmp   print_loop
      
print_hex:
	pla                        ; special chars are on the stack
	pha 	                     ; store it on the stack for later
	
	lsr                        ; shift 4 bits left to move the high into the low
	lsr
	lsr
	lsr
	
	clc				            ; clear carry flag which can mess with our and RESULTS
	and   #$0f		            ; number mod 16
	tax				            ; transfer to x and look up our hex to ascii conversion
	lda   hexToAscii, x

   jsr   prof_write_byte

	pla				            ; pull same value back from the stack
	and   #$0f		            ; number mod 16
	tax				            ; transfer to x and look up our hex to ascii conversion
	lda   hexToAscii, x
	
	jsr   prof_write_byte	         ; back to print loop which will pull it and print it out
   jmp   print_loop
   
move_to_next_char:
   inc   LOW_CHAR                ; inc return address to the next char to write
   bne   move_to_next_char_done  ; if it hasn't wrapped, done
   inc   HIGH_CHAR               ; else inc high address
move_to_next_char_done:
   rts

prof_write_byte:
   sta   (PR_NEXT_SLOT_LOW), y       ; save it in the cmd address byte
   inc   PR_NEXT_SLOT_LOW
   bne   prof_write_byte_done
   inc   PR_NEXT_SLOT_HIGH
prof_write_byte_done:
   rts
   
hexToAscii:                   ; look-up table
   .byte $30
   .byte $31
   .byte $32
   .byte $33
   .byte $34
   .byte $35
   .byte $36
   .byte $37
   .byte $38
   .byte $39
   .byte $41
   .byte $42
   .byte $43
   .byte $44
   .byte $45
   .byte $46