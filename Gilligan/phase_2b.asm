; store command packet, "Hello World!" string in ROM and then start doing the LOST numbers
; 


VALUE          = $C000
ONESEC_HIGH    = $7a
ONESEC_MID     = $ff
ONESEC_LOW     = $ff

; stack 	  (0x100 - 0x1ff) (6502 REQ)

; reg x = low
; reg y = mid
; reg a = high

.segment "ROM"
reset:
   ldx   #ONESEC_LOW
   ldy   #ONESEC_MID

main:
   inc      VALUE             ; inc the value
   lda      #ONESEC_HIGH      ; reset counter high bits

low_inc:
   dex                        ; dec counter low bits
   bne      low_inc           ; if we haven't hit 0, continue counting

mid_inc:                      ; else fall thruogh to mid bits
   ldx      #ONESEC_LOW       ; reset the counter low bits
   
   dey                        ; dec counter mid bits
   bne      low_inc           ; if we haven't hit 0, countinue counting
   
high_inc:                     ; else fall through to high bits
   ldy      #ONESEC_MID       ; reset counter mid bits
   
   sbc      #$01              ; dec counter high bits (subtract 1 from accumulator)
   beq      main              ; if we've hit 0, jump back to main
   jmp      low_inc           ; else go back to the low bits
      

nmi:
irq:
	rti

	
.segment "VECTORS"
.word nmi, reset, irq

.segment "RAM"
.segment "ZP"

