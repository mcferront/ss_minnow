.segment "ROM"

.include "memory.asm"


; reg x = low
; reg y = mid
; reg a = high

reset:
   ; set up stack
	cld						   ; clear decimal mode flag
	ldx	#$ff				   ; set up stack (0x100 - 0x1ff), setting to 0xff means the first push will be at 0x100
	txs						   ; transfer x register to the stack pointer
   
   ldx   #$0
   lda   #$0
   ldy   #$0

   jsr prof_begin_packet   ; controller packet not currently used by prof
      lda #PR_CMD_ID_CONTROLLER
      jsr prof_write_byte
      
      lda #$02
      jsr prof_write_byte
   jsr prof_end_packet
   
   sei						   ; enable interrupts

do_nothing:
   jmp do_nothing
   
nmi:
  	pha                     ; save registers (a,x,y)
	txa 					
	pha 					
	tya 					
	pha 					
   
   lda   PR_CONTROLLER     ; load controller data
   tay

   tya
   and   #CONTROLLER_START
   pha

   tya
   and   #CONTROLLER_C
   pha

   tya
   and   #CONTROLLER_B
   pha

   tya
   and   #CONTROLLER_A
   pha

   tya
   and   #CONTROLLER_RIGHT
   pha

   tya
   and   #CONTROLLER_LEFT
   pha

   tya
   and   #CONTROLLER_DOWN
   pha
   
   tya
   and  #CONTROLLER_UP   
   pha                     

   jsr prof_begin_packet

      jsr prof_write_string
        .byte "U:%b D:%b L:%b R:%b A:%b B:%b C:%b ST:%b", 0
     
   jsr prof_end_packet

  	pla						; restore registers (y,x,a)
	tay
	pla
	tax
	pla
irq:
	rti

.include "professor.asm"

.segment "VECTORS"
.word nmi, reset, irq


.segment "RAM"
.segment "ZP"


