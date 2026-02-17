; GameTank Audio Firmware - Sine Wavetable
; 256-byte sine table: round(63 * sin(2*pi*i/256)), signed
; Build with: dasm audio_fw_sine.asm -f3 -oaudio_fw_sine.bin
; Loaded to $3E00 (=$0E00 on coprocessor)

    PROCESSOR 6502
    ORG $0000

; ==========================================
; Sine Waveform Table (256 bytes)
; Values from -63 to +63 (signed)
; Used by phase-offset volume control:
;   sin(phase+amp) + sin(phase-amp) = 2*sin(phase)*cos(amp)
; ==========================================
Sine:
    DC.B $00,$02,$03,$05,$06,$08,$09,$0B,$0C,$0E,$0F,$11,$12,$14,$15,$17
    DC.B $18,$1A,$1B,$1C,$1E,$1F,$20,$22,$23,$24,$26,$27,$28,$29,$2A,$2B
    DC.B $2D,$2E,$2F,$30,$31,$32,$33,$34,$34,$35,$36,$37,$38,$38,$39,$3A
    DC.B $3A,$3B,$3B,$3C,$3C,$3D,$3D,$3D,$3E,$3E,$3E,$3F,$3F,$3F,$3F,$3F
    DC.B $3F,$3F,$3F,$3F,$3F,$3F,$3E,$3E,$3E,$3D,$3D,$3D,$3C,$3C,$3B,$3B
    DC.B $3A,$3A,$39,$38,$38,$37,$36,$35,$34,$34,$33,$32,$31,$30,$2F,$2E
    DC.B $2D,$2B,$2A,$29,$28,$27,$26,$24,$23,$22,$20,$1F,$1E,$1C,$1B,$1A
    DC.B $18,$17,$15,$14,$12,$11,$0F,$0E,$0C,$0B,$09,$08,$06,$05,$03,$02
    DC.B $00,$FE,$FD,$FB,$FA,$F8,$F7,$F5,$F4,$F2,$F1,$EF,$EE,$EC,$EB,$E9
    DC.B $E8,$E6,$E5,$E4,$E2,$E1,$E0,$DE,$DD,$DC,$DA,$D9,$D8,$D7,$D6,$D5
    DC.B $D3,$D2,$D1,$D0,$CF,$CE,$CD,$CC,$CC,$CB,$CA,$C9,$C8,$C8,$C7,$C6
    DC.B $C6,$C5,$C5,$C4,$C4,$C3,$C3,$C3,$C2,$C2,$C2,$C1,$C1,$C1,$C1,$C1
    DC.B $C1,$C1,$C1,$C1,$C1,$C1,$C2,$C2,$C2,$C3,$C3,$C3,$C4,$C4,$C5,$C5
    DC.B $C6,$C6,$C7,$C8,$C8,$C9,$CA,$CB,$CC,$CC,$CD,$CE,$CF,$D0,$D1,$D2
    DC.B $D3,$D5,$D6,$D7,$D8,$D9,$DA,$DC,$DD,$DE,$E0,$E1,$E2,$E4,$E5,$E6
    DC.B $E8,$E9,$EB,$EC,$EE,$EF,$F1,$F2,$F4,$F5,$F7,$F8,$FA,$FB,$FD,$FE
