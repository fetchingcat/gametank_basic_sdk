	; XC=BASIC memory functions
	
	; DECLARE FUNCTION PEEK AS BYTE (address AS WORD) SHARED STATIC INLINE
	MAC F_peek_word ; @push @pull
	IF TARGET == gametank
	; ROM-safe version using indirect addressing
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	ldy #0
	lda (R0),y
	IF !FPUSH
	pha
	ENDIF
	ELSE
	; Self-modifying version (faster, requires RAM execution)
	IF !FPULL
	pla
	sta .l + 2
	pla
	sta .l + 1
	ELSE
	sta .l + 1
	sty .l + 2
	ENDIF
.l  lda $FFFF
	IF !FPUSH
	pha
	ENDIF
	ENDIF
	ENDM

	MAC F_deek_word ; @push @pull
	IF !FPULL
	pla
	sta R1
	pla
	sta R0
	ELSE
	sta R0
	sty R1
	ENDIF
	IF !FPUSH
	ldy #$00
	lda (R0),y
	pha
	iny
	lda (R0),y
	pha
	ELSE
	ldy #$00
	lda (R0),y
	tax
	iny
	lda (R0),y
	tay
	txa
	ENDIF
	ENDM