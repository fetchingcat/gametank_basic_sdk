; GameTank Audio Firmware - Zero Page Chunk
; Only the non-zero initialization data
; Build with: dasm audio_fw_zp.asm -f3 -oaudio_fw_zp.bin

    PROCESSOR 6502
    ORG $0000
    
; === Zero Page Initialization ($00-$7F) ===
    DC.B 0              ; $00 AccBuf
    DC.B 0              ; $01 spare
    DC.B $00, $0E       ; $02-$03 WavePtr -> $0E00 (Sine table)
    DC.B $80,$80,$80,$80 ; $04-$07 Feedback (neutral)
    DC.B 0,0,0,0,0,0,0,0 ; $08-$0F spare
    
    ; $10-$1F: Pitch MSB (16 operators)
    DC.B 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
    ; $20-$2F: Pitch LSB (16 operators)  
    DC.B 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
    ; $30-$3F: Amplitude (16 operators) - $40 = silent (phase offset)
    DC.B $40,$40,$40,$40, $40,$40,$40,$40
    DC.B $40,$40,$40,$40, $40,$40,$40,$40
    ; $40-$4F: spare
    DC.B 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0
    ; $50-$5F: Wave phase high (16 operators)
    DC.B 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
    ; $60-$6F: Wave phase low (16 operators)
    DC.B 0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,0
    ; $70-$7F: Input buffer (16 bytes)
    DC.B 0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0
