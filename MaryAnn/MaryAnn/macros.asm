;
; MaryAnn.asm
;
; Created: 3/5/2018 10:26:50 PM
; Author : trapper.mcferron
;
.equ VIDEO_PORT		= PORTD
.equ HSYNC			= PORTD0
.equ VSYNC			= PORTD1

.equ SR_TOGGLE      = PORTC7

.equ SCAN_BUFFER	= 0x1000
.equ SR_RED     	= 0x0C00
.equ SR_GRN_LO     	= 0x0C00
.equ SR_GRN_HI     	= 0x0C00
.equ SR_BLU     	= 0x0C00

.macro SYNC_PULSE	;2 cycles
	ldi @0, (@1 << HSYNC) | (@2 << VSYNC)
	out VIDEO_PORT, @0
.endmacro

.macro HOLD_3	    ;3 cycles * iteration
	ldi @1, @2		;+1 cycle
@0:
	dec @1	        ;+1 cycle
	brne @0			;+2 cycles if taken, -1 cycle when not taken (cancels out the ldi)
.endmacro


; tile format in bits:
; R  R  R  R  R  R  R  R       (first byte red bits)
; GL GL GL GL GL GL GL GL      (second byte green low bits)
; GH GH GH GH GH GH GH GH      (third byte green hi bits)
; B  B  B  B  B  B  B  B       (fourth byte blue bits)

;R_GL_GH_B
.macro WRITE_TILE   ;need to take 13.15 cycles
	ldi @0, high(SCAN_BUFFER) | high(SR_RED) ;1 cycle
    ld @1, @2+      ; write red - 4
    
    ; (reset high bytes to activate next SR
    ; low counter(r30) should stay at correct location
	ldi @0, high(SCAN_BUFFER) | high(SR_GRN_LO) ;5 cycle 
    ld @1, @2+      ; write green lo - 8

	ldi @0, high(SCAN_BUFFER) | high(SR_GRN_HI) ;9 cycle
    ld @1, @2+      ; write green hi - 12

	;ldi @0, high(SCAN_BUFFER) | high(SR_BLU) ;10 cycle
    ;ld @1, Z+      ; write blue - 12


	out SR_TOGGLE, @3   ; 13
.endmacro

.macro WRITE_BLACK  ;need to take 13.15 cycles
	ldi @0, high(SCAN_BUFFER) | high(SR_RED) ;1 cycle
    ld @1, @2      ; write red - 4
    
    ; (reset high bytes to activate next SR
    ; low counter(r30) should stay at correct location
	ldi @0, high(SCAN_BUFFER) | high(SR_GRN_LO) ;5 cycle 
    ld @1, @2      ; write green lo - 8

	ldi @0, high(SCAN_BUFFER) | high(SR_GRN_HI) ;9 cycle
    ld @1, @2      ; write green hi - 12

	;ldi @0, high(SCAN_BUFFER) | high(SR_BLU) ;10 cycle
    ;ld @1, Z+      ; write blue - 12


	out SR_TOGGLE, @3   ; 13
.endmacro

;52.6 uS for a scanline
;256 pixels = 0.20546875 uS per pixel
;4.87mhz clock needed for SR


