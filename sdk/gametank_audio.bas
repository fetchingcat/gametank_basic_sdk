' ==========================================
' GameTank Audio Library for XC-BASIC
' gametank_audio.bas - Optional audio support
' ==========================================
'
' This module provides simple audio functionality.
' For full music support, see gametank_music.bas (future).
'
' Usage:
'   INCLUDE "../sdk/gametank_audio.bas"
'   CALL gt_audio_init()
'   CALL gt_beep(60, 10)  ' MIDI note 60 (middle C), 10 frames
'
' Note: Audio requires the audio coprocessor firmware to be
' initialized. gt_audio_init() handles this automatically.
' ==========================================

' ==========================================
' Audio Hardware Constants
' ==========================================
SHARED CONST GT_AUDIO_RESET = $2000
SHARED CONST GT_AUDIO_NMI = $2001
SHARED CONST GT_AUDIO_RATE = $2006
SHARED CONST GT_ARAM = $3000
SHARED CONST GT_AUDIO_PARAMS = $3070

' FM synthesis parameter offsets (in aram)
SHARED CONST AUD_FEEDBACK = $04      ' Feedback per channel (4 bytes)
SHARED CONST AUD_PITCH_MSB = $10     ' Pitch MSB per operator (16 bytes)
SHARED CONST AUD_PITCH_LSB = $20     ' Pitch LSB per operator (16 bytes)
SHARED CONST AUD_AMPLITUDE = $30     ' Amplitude per operator (16 bytes)

' ==========================================
' Audio State Variables
' ==========================================
DIM gt_audio_ready AS BYTE SHARED
DIM gt_beep_frames AS BYTE SHARED     ' Frames remaining for current beep

' Parameter buffer index
DIM gt_audio_param_idx AS BYTE SHARED

' ==========================================
' Pitch Table (MIDI notes 36-96 = C2 to C7)
' This is a subset of the full 216-entry table
' Each entry is 2 bytes (MSB, LSB)
' ==========================================
gt_pitch_table:
DATA AS BYTE $01,$33, $01,$45, $01,$58, $01,$6D  ' C2-D#2 (36-39)
DATA AS BYTE $01,$82, $01,$99, $01,$B2, $01,$CB  ' E2-G#2 (40-43)
DATA AS BYTE $01,$E7, $02,$04, $02,$22, $02,$43  ' A2-C3  (44-47)
DATA AS BYTE $02,$65, $02,$8A, $02,$B0, $02,$D9  ' C#3-F3 (48-51)
DATA AS BYTE $03,$04, $03,$32, $03,$63, $03,$97  ' F#3-A#3 (52-55)
DATA AS BYTE $03,$CD, $04,$07, $04,$44, $04,$85  ' B3-D4  (56-59)
DATA AS BYTE $04,$CA, $05,$13, $05,$60, $05,$B2  ' D#4-G4 (60-63)
DATA AS BYTE $06,$09, $06,$65, $06,$C6, $07,$2D  ' G#4-B4 (64-67)
DATA AS BYTE $07,$9A, $08,$0E, $08,$89, $09,$0B  ' C5-D#5 (68-71)
DATA AS BYTE $09,$94, $0A,$26, $0A,$C1, $0B,$64  ' E5-G#5 (72-75)
DATA AS BYTE $0C,$12, $0C,$CA, $0D,$8C, $0E,$5B  ' A5-C6  (76-79)
DATA AS BYTE $0F,$35, $10,$1D, $11,$12, $12,$16  ' C#6-F6 (80-83)
DATA AS BYTE $13,$29, $14,$4D, $15,$82, $16,$C9  ' F#6-A#6 (84-87)
DATA AS BYTE $18,$24, $19,$93, $1B,$19, $1C,$B5  ' B6-D7  (88-91)
DATA AS BYTE $1E,$6A, $20,$39, $22,$24, $24,$2B  ' D#7-G7 (92-95)
DATA AS BYTE $26,$52                             ' G#7 (96)

' ==========================================
' Audio Coprocessor Firmware (Sparse Version)
' Split into 3 chunks to save ROM space (~451 bytes vs 4096)
' Stored in ROM Bank 0 to free main code space
' Built from: sdk/audio_fw_zp.asm, audio_fw_code.asm, audio_fw_sine.asm
' ==========================================

BANK 0
' ZP chunk: 128 bytes -> copied to $3000 (=$0000 on coproc)
gt_audio_fw_zp:
INCBIN "../sdk/audio_fw_zp.bin"
gt_audio_fw_zp_end:

' Code chunk: 67 bytes -> copied to $3300 (=$0300 on coproc)
gt_audio_fw_code:
INCBIN "../sdk/audio_fw_code.bin"
gt_audio_fw_code_end:

' Sine table: 256 bytes -> copied to $3E00 (=$0E00 on coproc)
gt_audio_fw_sine:
INCBIN "../sdk/audio_fw_sine.bin"
gt_audio_fw_sine_end:
BANK FIXED

' ==========================================
' Audio Subroutines
' ==========================================

' Initialize the audio coprocessor
' Must be called once before any audio functions
' Loads sparse firmware chunks from Bank 0 and starts coprocessor
SUB gt_audio_init() SHARED STATIC
    DIM src AS WORD
    DIM size AS WORD
    
    ' Set audio rate slow during init
    POKE GT_AUDIO_RATE, $7F
    
    ' Switch to bank 0 where firmware is stored
    CALL gt_push_rom_bank()
    CALL gt_rom_bank(0)
    
    ' Copy ZP chunk to $3000 (128 bytes)
    src = @gt_audio_fw_zp
    size = @gt_audio_fw_zp_end - @gt_audio_fw_zp
    MEMCPY src, $3000, size
    
    ' Copy Code chunk to $3300 (67 bytes)
    src = @gt_audio_fw_code
    size = @gt_audio_fw_code_end - @gt_audio_fw_code
    MEMCPY src, $3300, size
    
    ' Copy Sine table to $3E00 (256 bytes)
    src = @gt_audio_fw_sine
    size = @gt_audio_fw_sine_end - @gt_audio_fw_sine
    MEMCPY src, $3E00, size
    
    ' Restore previous bank
    CALL gt_pop_rom_bank()
    
    ' Write 6502 vectors directly ($0FFA-$0FFF on coproc)
    ' NMI=$0339, RESET=$0300, IRQ=$0312
    POKE $3FFA, $39 : POKE $3FFB, $03
    POKE $3FFC, $00 : POKE $3FFD, $03
    POKE $3FFE, $12 : POKE $3FFF, $03
    
    ' Set audio rate to full speed
    POKE GT_AUDIO_RATE, 255
    
    ' Trigger reset to start coprocessor
    POKE GT_AUDIO_RESET, 0
    
    gt_audio_ready = 1
    gt_beep_frames = 0
    gt_audio_param_idx = 0
END SUB

' Send a parameter to the audio coprocessor
' param: parameter address (e.g., AUD_AMPLITUDE + operator)
' value: parameter value
SUB gt_audio_param(param AS BYTE, value AS BYTE) SHARED STATIC
    POKE GT_AUDIO_PARAMS + gt_audio_param_idx, param
    gt_audio_param_idx = gt_audio_param_idx + 1
    POKE GT_AUDIO_PARAMS + gt_audio_param_idx, value
    gt_audio_param_idx = gt_audio_param_idx + 1
END SUB

' Flush queued parameters to audio coprocessor
SUB gt_audio_flush() SHARED STATIC
    ' Terminate parameter list
    POKE GT_AUDIO_PARAMS + gt_audio_param_idx, 0
    ' Trigger NMI to process parameters
    POKE GT_AUDIO_NMI, 1
    gt_audio_param_idx = 0
END SUB

' Play a simple beep on channel 0
' note: MIDI note number (36-96 supported, 60 = middle C)
' frames: duration in frames (60 = 1 second)
SUB gt_beep(note AS BYTE, frames AS BYTE) SHARED STATIC
    DIM pitch_idx AS BYTE
    DIM pitch_msb AS BYTE
    DIM pitch_lsb AS BYTE
    
    ' Clamp note to valid range
    IF note < 36 THEN note = 36
    IF note > 96 THEN note = 96
    
    ' Calculate pitch table index (note 36 = index 0)
    pitch_idx = (note - 36) * 2
    
    ' Get pitch values from table
    pitch_msb = PEEK(@gt_pitch_table + pitch_idx)
    pitch_lsb = PEEK(@gt_pitch_table + pitch_idx + 1)
    
    ' Set pitch for operator 0 (single-voice firmware)
    CALL gt_audio_param(AUD_PITCH_MSB + 0, pitch_msb)
    CALL gt_audio_param(AUD_PITCH_LSB + 0, pitch_lsb)
    
    ' Set amplitude: $00 = full volume, $40 = silence (phase-offset control)
    CALL gt_audio_param(AUD_AMPLITUDE + 0, $00)  ' Full volume
    
    ' Send parameters to coprocessor
    CALL gt_audio_flush()
    
    gt_beep_frames = frames
END SUB

' Stop any playing sound on channel 0
SUB gt_audio_stop() SHARED STATIC
    ' Set amplitude to $40 (silence) and zero pitch
    CALL gt_audio_param(AUD_AMPLITUDE + 0, $40)
    CALL gt_audio_param(AUD_PITCH_MSB + 0, 0)
    CALL gt_audio_param(AUD_PITCH_LSB + 0, 0)
    CALL gt_audio_flush()
    gt_beep_frames = 0
END SUB

' Call this every frame to update audio state (envelope decay, beep timing)
SUB gt_audio_tick() SHARED STATIC
    IF gt_beep_frames > 0 THEN
        gt_beep_frames = gt_beep_frames - 1
        IF gt_beep_frames = 0 THEN
            CALL gt_audio_stop()
        END IF
    END IF
END SUB

' ==========================================
' Simple Sound Effects (canned sounds)
' ==========================================

' Play a "blip" sound (short high beep)
SUB gt_sfx_blip() SHARED STATIC
    CALL gt_beep(80, 3)  ' High note, 3 frames
END SUB

' Play a "pickup" sound (rising tone)
SUB gt_sfx_pickup() SHARED STATIC
    CALL gt_beep(60, 2)  ' Start low
    ' Note: For a real rising tone, you'd need to update pitch each frame
END SUB

' Play an "explosion" sound (noise burst)
' Note: True explosion needs noise, this is a low rumble approximation
SUB gt_sfx_explode() SHARED STATIC
    CALL gt_beep(36, 8)  ' Very low, longer duration
END SUB

' Play a "shoot" sound (short mid beep)
SUB gt_sfx_shoot() SHARED STATIC
    CALL gt_beep(72, 2)  ' Mid-high, very short
END SUB

_gt_audio_end:
