; ------------------------------------------
; XC=BASIC - GameTank IRQ/NMI Support
;
; NMI/IRQ entry points are defined inline in
; gametank.bas (BASIC SDK). They handle:
;   NMI: clear frameflag, increment tick counter
;   IRQ: acknowledge blitter DMA
;
; This file provides IRQSETUP/IRQRESET stubs
; when USEIRQ == 1 (for ON IRQ GOSUB support).
;
; Tick counter locations (ZP, always available):
;   $F0 = GT_TICKS_LO  (low byte)
;   $F1 = GT_TICKS_MID  (mid byte)
;   $F2 = GT_TICKS_HI   (high byte)
; ------------------------------------------

; Tick counter in zero page (set by NMI handler in SDK)
GT_TICKS_LO  EQU $F0
GT_TICKS_MID EQU $F1
GT_TICKS_HI  EQU $F2

	IF USEIRQ == 1

IRQSETUP SUBROUTINE
	; Initialize tick counter to zero
	lda #0
	sta GT_TICKS_LO
	sta GT_TICKS_MID
	sta GT_TICKS_HI
	rts

IRQRESET SUBROUTINE
	; Nothing to reset on GameTank - NMI is hardware-driven
	rts

	; Stub macros to satisfy the compiler when IRQ statements are parsed
	MAC irqenable
	ENDM

	MAC irqdisable
	ENDM

	MAC onirqgosub
	ENDM

	ENDIF
