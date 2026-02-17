; GameTank Audio Firmware - Code Chunk
; Just the executable code starting at $0300
; Build with: dasm audio_fw_code.asm -f3 -oaudio_fw_code.bin

    PROCESSOR 6502
    
; ==========================================
; W65C02 Instruction Macros (encoded as bytes)
; ==========================================
    MAC WAI         ; Wait for Interrupt
    DC.B $CB
    ENDM
    
    MAC PHX         ; Push X
    DC.B $DA
    ENDM
    
    MAC PLX         ; Pull X
    DC.B $FA  
    ENDM
    
    MAC PHY         ; Push Y
    DC.B $5A
    ENDM
    
    MAC PLY         ; Pull Y
    DC.B $7A
    ENDM

; ==========================================
; Constants (coprocessor addresses)
; ==========================================
DAC         = $8000     ; Audio DAC output
AccBuf      = $00       ; Accumulator buffer (temp)
WavePtr     = $02       ; Wavetable pointer (2 bytes)
PitchMSB    = $10       ; Pitch MSB
PitchLSB    = $20       ; Pitch LSB
Amplitude   = $30       ; Amplitude (phase offset: $00=full, $40=silent)
WavePhaseH  = $50       ; Wave phase high
WavePhaseL  = $60       ; Wave phase low
Inputs      = $70       ; Parameter input buffer

; Code starts at $0300 in audio RAM
; Must use ORG $0300 so JMP addresses are correct when loaded!
    ORG $0300
    
; ==========================================
; Code
; ==========================================
RESET:
    SEI                 ; Disable interrupts during setup
    CLD                 ; Clear decimal mode
    LDX #$FF
    TXS                 ; Initialize stack
    
    ; Set wavetable pointer to $0E00 (sine table)
    LDA #$00
    STA WavePtr
    LDA #$0E
    STA WavePtr+1
    
    CLI                 ; Enable interrupts
    
Forever:
    WAI                 ; Wait for interrupt (W65C02)
    JMP Forever

; ==========================================
; IRQ Handler - Generate audio sample
; Volume uses phase-offset identity:
;   sin(phase+amp) + sin(phase-amp) = 2*sin(phase)*cos(amp)
;   Amplitude $00 = full volume, $40 = silence
; ==========================================
IRQ:
    ; Advance phase for operator 0
    CLC
    LDA WavePhaseL
    ADC PitchLSB
    STA WavePhaseL
    LDA WavePhaseH
    ADC PitchMSB
    STA WavePhaseH
    
    ; sin(phase + amplitude)
    CLC
    ADC Amplitude
    TAY
    LDA (WavePtr),Y
    STA AccBuf              ; temp = sin(phase + amp)
    
    ; sin(phase - amplitude)
    LDA WavePhaseH
    SEC
    SBC Amplitude
    TAY
    LDA (WavePtr),Y         ; A = sin(phase - amp)
    
    ; Sum: sin(phase+amp) + sin(phase-amp)
    CLC
    ADC AccBuf
    
    ; Bias to unsigned ($80 center)
    CLC
    ADC #$80
    
    ; Output to DAC
    STA DAC
    
    RTI

; ==========================================
; NMI Handler - Process parameter commands
; Format: addr, value pairs until addr=0
; ==========================================
NMI_Handler:
    PHA
    PHX             ; W65C02
    PHY             ; W65C02
    
    LDY #0
.Loop:
    LDX Inputs,Y        ; Get address
    BEQ .Done           ; 0 = end of list
    INY
    LDA Inputs,Y        ; Get value
    STA $00,X           ; Store to zero page address
    INY
    JMP .Loop
    
.Done:
    PLY             ; W65C02
    PLX             ; W65C02
    PLA
    RTI

CODE_END:
