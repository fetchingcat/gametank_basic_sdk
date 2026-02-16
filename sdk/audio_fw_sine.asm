; GameTank Audio Firmware - Sine Table + Vectors
; 256 bytes total: 250 bytes sine + 6 bytes vectors
; Build with: dasm audio_fw_sine.asm -f3 -oaudio_fw_sine.bin

    PROCESSOR 6502
    
; Code addresses (from audio_fw_code.asm symbol file)
; Code chunk at $0000 is copied to $3300 = $0300 in coproc space
RESET       = $0300     ; $0000 + $0300
IRQ         = $0312     ; $0012 + $0300
NMI_Handler = $032C     ; $002C + $0300

    ORG $0000           ; Will be copied to $3F00 (=$0F00 on coprocessor)

; ==========================================
; Sine Waveform Table (250 bytes)
; Values from -63 to +63 (signed)
; ==========================================
Sine:
    DC.B $00,$02,$03,$05,$06,$08,$09,$0B,$0C,$0E,$10,$11,$13,$14,$16,$17
    DC.B $18,$1A,$1B,$1D,$1E,$1F,$21,$22,$23,$24,$26,$27,$28,$29,$2A,$2B
    DC.B $2C,$2D,$2E,$2F,$30,$31,$32,$33,$33,$34,$35,$35,$36,$36,$37,$37
    DC.B $38,$38,$38,$39,$39,$39,$39,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A
    DC.B $3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$39,$39,$39,$39,$38,$38,$38,$37
    DC.B $37,$36,$36,$35,$35,$34,$33,$33,$32,$31,$30,$2F,$2E,$2D,$2C,$2B
    DC.B $2A,$29,$28,$27,$26,$24,$23,$22,$21,$1F,$1E,$1D,$1B,$1A,$18,$17
    DC.B $16,$14,$13,$11,$10,$0E,$0C,$0B,$09,$08,$06,$05,$03,$02,$00,$FE
    DC.B $FD,$FB,$FA,$F8,$F7,$F5,$F4,$F2,$F0,$EF,$ED,$EC,$EA,$E9,$E8,$E6
    DC.B $E5,$E3,$E2,$E1,$DF,$DE,$DD,$DC,$DA,$D9,$D8,$D7,$D6,$D5,$D4,$D3
    DC.B $D2,$D1,$D0,$CF,$CE,$CD,$CD,$CC,$CB,$CB,$CA,$CA,$C9,$C9,$C8,$C8
    DC.B $C8,$C7,$C7,$C7,$C7,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6,$C6
    DC.B $C6,$C6,$C6,$C6,$C6,$C6,$C7,$C7,$C7,$C7,$C8,$C8,$C8,$C9,$C9,$CA
    DC.B $CA,$CB,$CB,$CC,$CD,$CD,$CE,$CF,$D0,$D1,$D2,$D3,$D4,$D5,$D6,$D7
    DC.B $D8,$D9,$DA,$DC,$DD,$DE,$DF,$E1,$E2,$E3,$E5,$E6,$E8,$E9,$EA,$EC
    DC.B $ED,$EF,$F0,$F2,$F4,$F5,$F7,$F8,$FA,$FB  ; 250 bytes ending at $0FF9

; ==========================================
; Vectors at $0FFA (6 bytes) - in audio coprocessor space  
; ==========================================
    DC.W NMI_Handler    ; $0FFA NMI
    DC.W RESET          ; $0FFC Reset
    DC.W IRQ            ; $0FFE IRQ
