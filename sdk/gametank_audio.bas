' GameTank Audio Library - 4-channel FM synthesis
' Requires: gametank.bas. Firmware (audio_full_fw.bin) stored in ROM bank 0.

' --- Hardware registers ---
SHARED CONST GT_AUDIO_RESET = $2000
SHARED CONST GT_AUDIO_NMI = $2001
SHARED CONST GT_AUDIO_RATE = $2006
SHARED CONST GT_ARAM = $3000
SHARED CONST GT_AUDIO_PARAMS = $3070

' ACP parameter offsets (relative to GT_ARAM)
SHARED CONST AUD_FEEDBACK = $04
SHARED CONST AUD_PITCH_MSB = $10
SHARED CONST AUD_PITCH_LSB = $20
SHARED CONST AUD_AMPLITUDE = $30

SHARED CONST GT_NUM_CHANNELS = 4
SHARED CONST GT_OPS_PER_CH = 4
SHARED CONST GT_NUM_OPS = 16

' --- Instrument preset IDs (1-indexed to match C SDK) ---
SHARED CONST GT_INSTR_PIANO = 1
SHARED CONST GT_INSTR_GUITAR = 2
SHARED CONST GT_INSTR_GUITAR2 = 3
SHARED CONST GT_INSTR_SLAPBASS = 4
SHARED CONST GT_INSTR_SNARE = 5
SHARED CONST GT_INSTR_SITAR = 6
SHARED CONST GT_INSTR_HORN = 7
SHARED CONST GT_NUM_INSTRUMENTS = 8
SHARED CONST GT_INSTR_SIZE = 18

' --- State ---
DIM gt_audio_ready AS BYTE SHARED
DIM gt_beep_frames AS BYTE SHARED

' Operator state: index = ch*4 + op (0-15)
DIM gt_amp(16) AS BYTE SHARED
DIM gt_env_init(16) AS BYTE SHARED
DIM gt_env_decay(16) AS BYTE SHARED
DIM gt_env_sustain(16) AS BYTE SHARED
DIM gt_op_trans(16) AS BYTE SHARED

DIM gt_ch_offset(4) AS INT SHARED      ' Signed channel transpose (from instrument)
DIM gt_note_held AS BYTE SHARED        ' Bitmask of channels with active notes
DIM gt_audio_param_idx AS BYTE SHARED

gt_ch_masks:
DATA AS BYTE 1, 2, 4, 8

' Pitch table: MIDI 0-107, 2 bytes each (MSB, LSB)
gt_full_pitch_table:
' --- Octave -1: notes 0-11 ---
DATA AS BYTE $00,$4D, $00,$51, $00,$56, $00,$5B  ' C-1  C#-1 D-1  D#-1
DATA AS BYTE $00,$61, $00,$66, $00,$6C, $00,$73  ' E-1  F-1  F#-1 G-1
DATA AS BYTE $00,$7A, $00,$81, $00,$89, $00,$91  ' G#-1 A-1  A#-1 B-1
' --- Octave 0: notes 12-23 ---
DATA AS BYTE $00,$99, $00,$A2, $00,$AC, $00,$B6  ' C0   C#0  D0   D#0
DATA AS BYTE $00,$C1, $00,$CD, $00,$D9, $00,$E6  ' E0   F0   F#0  G0
DATA AS BYTE $00,$F3, $01,$02, $01,$11, $01,$21  ' G#0  A0   A#0  B0
' --- Octave 1: notes 24-35 ---
DATA AS BYTE $01,$33, $01,$45, $01,$58, $01,$6D  ' C1   C#1  D1   D#1
DATA AS BYTE $01,$82, $01,$99, $01,$B2, $01,$CB  ' E1   F1   F#1  G1
DATA AS BYTE $01,$E7, $02,$04, $02,$22, $02,$43  ' G#1  A1   A#1  B1
' --- Octave 2: notes 36-47 ---
DATA AS BYTE $02,$65, $02,$8A, $02,$B0, $02,$D9  ' C2   C#2  D2   D#2
DATA AS BYTE $03,$04, $03,$32, $03,$63, $03,$97  ' E2   F2   F#2  G2
DATA AS BYTE $03,$CD, $04,$07, $04,$44, $04,$85  ' G#2  A2   A#2  B2
' --- Octave 3: notes 48-59 ---
DATA AS BYTE $04,$CA, $05,$13, $05,$60, $05,$B2  ' C3   C#3  D3   D#3
DATA AS BYTE $06,$09, $06,$65, $06,$C6, $07,$2D  ' E3   F3   F#3  G3
DATA AS BYTE $07,$9A, $08,$0E, $08,$89, $09,$0B  ' G#3  A3   A#3  B3
' --- Octave 4: notes 60-71 (Middle C = 60) ---
DATA AS BYTE $09,$94, $0A,$26, $0A,$C1, $0B,$64  ' C4   C#4  D4   D#4
DATA AS BYTE $0C,$12, $0C,$CA, $0D,$8C, $0E,$5B  ' E4   F4   F#4  G4
DATA AS BYTE $0F,$35, $10,$1D, $11,$12, $12,$16  ' G#4  A4   A#4  B4
' --- Octave 5: notes 72-83 ---
DATA AS BYTE $13,$29, $14,$4D, $15,$82, $16,$C9  ' C5   C#5  D5   D#5
DATA AS BYTE $18,$24, $19,$93, $1B,$19, $1C,$B5  ' E5   F5   F#5  G5
DATA AS BYTE $1E,$6A, $20,$39, $22,$24, $24,$2B  ' G#5  A5   A#5  B5
' --- Octave 6: notes 84-95 ---
DATA AS BYTE $26,$52, $28,$99, $2B,$03, $2D,$92  ' C6   C#6  D6   D#6
DATA AS BYTE $30,$48, $33,$27, $36,$31, $39,$6A  ' E6   F6   F#6  G6
DATA AS BYTE $3C,$D4, $40,$72, $44,$47, $48,$57  ' G#6  A6   A#6  B6
' --- Octave 7: notes 96-107 ---
DATA AS BYTE $4C,$A4, $51,$32, $56,$06, $5B,$24  ' C7   C#7  D7   D#7
DATA AS BYTE $60,$8F, $66,$4D, $6C,$62, $72,$D4  ' E7   F7   F#7  G7
DATA AS BYTE $79,$A8, $80,$E4, $88,$8E, $90,$AD  ' G#7  A7   A#7  B7

' Instrument presets: env_init[4], env_decay[4], env_sustain[4], op_transpose[4], feedback, transpose
gt_instruments:
' --- Dummy (ID 0) - placeholder to match C SDK 1-indexed table ---
DATA AS BYTE $00, $00, $00, $00  ' env_initial
DATA AS BYTE $00, $00, $00, $00  ' env_decay
DATA AS BYTE $00, $00, $00, $00  ' env_sustain
DATA AS BYTE   0,   0,   0,   0  ' op_transpose
DATA AS BYTE   0                  ' feedback
DATA AS BYTE   0                  ' transpose
' --- Piano (ID 1) ---
DATA AS BYTE $30, $40, $40, $5F  ' env_initial
DATA AS BYTE $04, $02, $10, $02  ' env_decay
DATA AS BYTE $04, $02, $10, $30  ' env_sustain
DATA AS BYTE   0,   0,   0,   0  ' op_transpose
DATA AS BYTE   0                  ' feedback
DATA AS BYTE   0                  ' transpose (0)
' --- Guitar (ID 2) ---
DATA AS BYTE $6F, $40, $68, $5F  ' env_initial
DATA AS BYTE $00, $FF, $02, $08  ' env_decay
DATA AS BYTE $00, $00, $40, $08  ' env_sustain
DATA AS BYTE  12,  36,   0,  24  ' op_transpose
DATA AS BYTE   8                  ' feedback
DATA AS BYTE $F4                  ' transpose (-12)
' --- Guitar2 (ID 3) ---
DATA AS BYTE $60, $40, $88, $4F  ' env_initial
DATA AS BYTE $00, $FF, $02, $01  ' env_decay
DATA AS BYTE $00, $00, $40, $30  ' env_sustain
DATA AS BYTE  12,  36,   0,  24  ' op_transpose
DATA AS BYTE   8                  ' feedback
DATA AS BYTE $F4                  ' transpose (-12)
' --- Slap Bass (ID 4) ---
DATA AS BYTE $58, $88, $58, $5F  ' env_initial
DATA AS BYTE $18, $08, $04, $02  ' env_decay
DATA AS BYTE $18, $08, $04, $02  ' env_sustain
DATA AS BYTE  28,  12,   0,  12  ' op_transpose
DATA AS BYTE   0                  ' feedback
DATA AS BYTE $E8                  ' transpose (-24)
' --- Snare (ID 5) ---
DATA AS BYTE $88, $8F, $8F, $38  ' env_initial
DATA AS BYTE $18, $02, $04, $04  ' env_decay
DATA AS BYTE $18, $08, $08, $04  ' env_sustain
DATA AS BYTE  36,   0,   0,   0  ' op_transpose
DATA AS BYTE   8                  ' feedback
DATA AS BYTE $F8                  ' transpose (-8)
' --- Sitar (ID 6) ---
DATA AS BYTE $60, $40, $01, $10  ' env_initial
DATA AS BYTE $00, $FF, $F8, $FF  ' env_decay
DATA AS BYTE $00, $60, $60, $30  ' env_sustain
DATA AS BYTE  12,  36,  12,  24  ' op_transpose
DATA AS BYTE   4                  ' feedback
DATA AS BYTE $E8                  ' transpose (-24)
' --- Horn (ID 7) ---
DATA AS BYTE $00, $00, $01, $10  ' env_initial
DATA AS BYTE $00, $00, $FC, $FC  ' env_decay
DATA AS BYTE $00, $00, $30, $50  ' env_sustain
DATA AS BYTE  12,  36,  12,  24  ' op_transpose
DATA AS BYTE   0                  ' feedback
DATA AS BYTE $F4                  ' transpose (-12)

' Full 4KB ACP firmware, stored in ROM bank 0
BANK 0
gt_full_fw:
INCBIN "../sdk/audio_full_fw.bin"
BANK FIXED

' Load an instrument preset into a channel (0-3)
SUB gt_load_instrument(ch AS BYTE, instr_id AS BYTE) SHARED STATIC
    DIM base_addr AS WORD
    DIM base_op AS BYTE
    DIM i AS BYTE
    DIM fb AS BYTE
    DIM tr AS BYTE

    base_addr = @gt_instruments + CWORD(instr_id) * GT_INSTR_SIZE
    base_op = ch * 4

    FOR i = 0 TO 3
        gt_env_init(base_op + i)    = PEEK(base_addr + CWORD(i))
        gt_env_decay(base_op + i)   = PEEK(base_addr + 4 + CWORD(i))
        gt_env_sustain(base_op + i) = PEEK(base_addr + 8 + CWORD(i))
        gt_op_trans(base_op + i)    = PEEK(base_addr + 12 + CWORD(i))
    NEXT i

    fb = PEEK(base_addr + 16)
    POKE GT_ARAM + AUD_FEEDBACK + ch, SHL(fb, 3) + 128

    ' Transpose is a signed two's complement byte
    tr = PEEK(base_addr + 17)
    IF tr AND $80 THEN
        gt_ch_offset(ch) = CINT(tr) - 256
    ELSE
        gt_ch_offset(ch) = CINT(tr)
    END IF
END SUB

' Initialize the audio coprocessor. Call once at startup before any other audio functions.
SUB gt_audio_init() SHARED STATIC
    DIM i AS BYTE

    POKE GT_AUDIO_RATE, $7F
    CALL gt_push_rom_bank()
    CALL gt_rom_bank(0)
    MEMCPY @gt_full_fw, GT_ARAM, $1000
    CALL gt_pop_rom_bank()
    POKE GT_AUDIO_RESET, 0
    POKE GT_AUDIO_RATE, 255

    ' Firmware signals ready by writing wavetable page to $3003 (non-zero when done)
    _gt_acp_wait:
    IF PEEK($3003) = 0 THEN GOTO _gt_acp_wait

    gt_note_held = 0
    gt_beep_frames = 0
    gt_audio_param_idx = 0

    FOR i = 0 TO 15
        gt_amp(i) = 0
        gt_env_init(i) = 0
        gt_env_decay(i) = 0
        gt_env_sustain(i) = 0
        gt_op_trans(i) = 0
        POKE GT_ARAM + AUD_AMPLITUDE + i, 128  ' 128 = silence
    NEXT i
    FOR i = 0 TO 3
        gt_ch_offset(i) = 0
    NEXT i

    ' Pre-load piano so gt_beep() works without an explicit instrument load
    FOR i = 0 TO 3
        CALL gt_load_instrument(i, GT_INSTR_PIANO)
    NEXT i

    gt_audio_ready = 1
END SUB

' Start a note on channel (0-3). note = MIDI 0-107 (60 = middle C).
SUB gt_note_on(ch AS BYTE, note AS BYTE) SHARED STATIC
    DIM base_op AS BYTE
    DIM i AS BYTE
    DIM cur_op AS BYTE
    DIM transposed AS INT
    DIM pitch_idx AS WORD

    base_op = ch * 4

    FOR i = 0 TO 3
        cur_op = base_op + i
        transposed = CINT(gt_op_trans(cur_op)) + CINT(note) + gt_ch_offset(ch)
        IF transposed < 0 THEN transposed = 0
        IF transposed > 107 THEN transposed = 107
        pitch_idx = CWORD(transposed) * 2
        POKE GT_ARAM + AUD_PITCH_MSB + cur_op, PEEK(@gt_full_pitch_table + pitch_idx)
        POKE GT_ARAM + AUD_PITCH_LSB + cur_op, PEEK(@gt_full_pitch_table + pitch_idx + 1)
        gt_amp(cur_op) = gt_env_init(cur_op)
        POKE GT_ARAM + AUD_AMPLITUDE + cur_op, SHR(gt_amp(cur_op), 1) + 128
    NEXT i

    gt_note_held = gt_note_held OR PEEK(@gt_ch_masks + ch)
    POKE GT_AUDIO_NMI, 1
END SUB

' Stop a note on channel (0-3).
SUB gt_note_off(ch AS BYTE) SHARED STATIC
    DIM base_op AS BYTE
    DIM i AS BYTE

    base_op = ch * 4
    FOR i = 0 TO 3
        gt_amp(base_op + i) = 0
        POKE GT_ARAM + AUD_AMPLITUDE + base_op + i, 128
    NEXT i
    gt_note_held = gt_note_held AND (PEEK(@gt_ch_masks + ch) XOR $FF)
    POKE GT_AUDIO_NMI, 1
END SUB

' Update envelopes and song sequencer. Call once per frame.
SUB gt_audio_tick() SHARED STATIC
    DIM op AS BYTE
    DIM ch AS BYTE
    DIM i AS BYTE
    DIM ch_mask AS BYTE
    DIM diff AS BYTE

    op = 0
    ch_mask = 1

    FOR ch = 0 TO 3
        IF (gt_note_held AND ch_mask) <> 0 THEN
            FOR i = 0 TO 3
                ' XOR sign-bit trick: decay until amplitude sign matches sustain sign
                diff = gt_env_sustain(op) - gt_amp(op)
                IF (diff XOR gt_env_decay(op)) AND $80 THEN
                    gt_amp(op) = gt_amp(op) - gt_env_decay(op)
                ELSE
                    gt_amp(op) = gt_env_sustain(op)
                END IF
                ' Hardware: (amp >> 1) + 128, where 128=silence, 255=max
                POKE GT_ARAM + AUD_AMPLITUDE + op, SHR(gt_amp(op), 1) + 128
                op = op + 1
            NEXT i
        ELSE
            op = op + 4
        END IF
        ch_mask = ch_mask + ch_mask
    NEXT ch

    POKE GT_AUDIO_NMI, 1

    IF gt_beep_frames > 0 THEN
        gt_beep_frames = gt_beep_frames - 1
        IF gt_beep_frames = 0 THEN CALL gt_note_off(0)
    END IF
END SUB

' Silence all channels immediately.
SUB gt_silence_all() SHARED STATIC
    DIM i AS BYTE

    FOR i = 0 TO 15
        gt_amp(i) = 0
        POKE GT_ARAM + AUD_AMPLITUDE + i, 128
    NEXT i
    gt_note_held = 0

    POKE GT_AUDIO_NMI, 1
END SUB

' Play a note on ch 0 for N frames (60 ~ 1 second).
SUB gt_beep(note AS BYTE, frames AS BYTE) SHARED STATIC
    CALL gt_note_on(0, note)
    gt_beep_frames = frames
END SUB

' Stop sound on channel 0.
SUB gt_audio_stop() SHARED STATIC
    CALL gt_note_off(0)
    gt_beep_frames = 0
END SUB

' Low-level: queue a raw ACP parameter. Call gt_audio_flush() to send.
SUB gt_audio_param(param AS BYTE, value AS BYTE) SHARED STATIC
    POKE GT_AUDIO_PARAMS + gt_audio_param_idx, param
    gt_audio_param_idx = gt_audio_param_idx + 1
    POKE GT_AUDIO_PARAMS + gt_audio_param_idx, value
    gt_audio_param_idx = gt_audio_param_idx + 1
END SUB

' Send queued parameters to the ACP via NMI.
SUB gt_audio_flush() SHARED STATIC
    POKE GT_AUDIO_PARAMS + gt_audio_param_idx, 0
    POKE GT_AUDIO_NMI, 1
    gt_audio_param_idx = 0
END SUB

' --- Sound effects (all use channel 0) ---
SUB gt_sfx_blip() SHARED STATIC : CALL gt_beep(68, 3) : END SUB
SUB gt_sfx_pickup() SHARED STATIC : CALL gt_beep(48, 2) : END SUB
SUB gt_sfx_explode() SHARED STATIC : CALL gt_beep(24, 8) : END SUB
SUB gt_sfx_shoot() SHARED STATIC : CALL gt_beep(60, 2) : END SUB

' --- Song Sequencer ---
' Song format (from midiconvert.js):
'   Byte 0:    config flags (bit0=velocity)
'   Bytes 1-4: instrument IDs for channels 0-3
'   Events: delay byte, noteMask byte, note bytes (0=note off)
' gt_audio_tick() drives the sequencer automatically.

DIM gt_song_ptr AS WORD SHARED
DIM gt_song_start AS WORD SHARED
DIM gt_song_delay AS BYTE SHARED
DIM gt_song_loop AS BYTE SHARED
DIM gt_song_active AS BYTE SHARED
DIM gt_song_cfg AS BYTE SHARED

' Play a song. do_loop=1 to repeat, 0 for once.
SUB gt_song_play(song_addr AS WORD, do_loop AS BYTE) SHARED STATIC
    DIM cfg AS BYTE
    DIM i AS BYTE

    gt_song_cfg = PEEK(song_addr)
    FOR i = 0 TO 3
        CALL gt_load_instrument(i, PEEK(song_addr + 1 + CWORD(i)))
    NEXT i

    gt_song_start = song_addr + 5
    gt_song_ptr = gt_song_start
    gt_song_delay = PEEK(gt_song_ptr)
    gt_song_ptr = gt_song_ptr + 1
    ' Pre-decrement: delay is checked after decrement, so subtract 1 to align
    IF gt_song_delay > 0 THEN gt_song_delay = gt_song_delay - 1

    gt_song_loop = do_loop
    gt_song_active = 1
END SUB

' Stop the current song.
SUB gt_song_stop() SHARED STATIC
    gt_song_active = 0
    CALL gt_silence_all()
END SUB

' Internal: advance the sequencer one frame. Called by gt_audio_tick().
SUB gt_song_tick() SHARED STATIC
    DIM note_mask AS BYTE
    DIM ch AS BYTE
    DIM n AS BYTE

    IF gt_song_active = 0 THEN
        CALL gt_audio_tick()
        RETURN
    END IF

    IF gt_song_delay > 0 THEN
        gt_song_delay = gt_song_delay - 1
        CALL gt_audio_tick()
        RETURN
    END IF

    _gt_seq_event:
    note_mask = PEEK(gt_song_ptr)
    gt_song_ptr = gt_song_ptr + 1

    FOR ch = 0 TO 3
        IF (note_mask AND PEEK(@gt_ch_masks + ch)) <> 0 THEN
            n = PEEK(gt_song_ptr)
            gt_song_ptr = gt_song_ptr + 1
            IF (gt_song_cfg AND 1) <> 0 THEN gt_song_ptr = gt_song_ptr + 1  ' skip velocity
            IF n > 0 THEN
                CALL gt_note_on(ch, n)
            ELSE
                CALL gt_note_off(ch)
            END IF
        END IF
    NEXT ch

    gt_song_delay = PEEK(gt_song_ptr)
    gt_song_ptr = gt_song_ptr + 1

    ' delay=0 is the single-byte end-of-song terminator (matches C SDK)
    IF gt_song_delay = 0 THEN
        IF gt_song_loop <> 0 THEN
            gt_song_ptr = gt_song_start
            gt_song_delay = PEEK(gt_song_ptr)
            gt_song_ptr = gt_song_ptr + 1
            IF gt_song_delay > 0 THEN gt_song_delay = gt_song_delay - 1
        ELSE
            gt_song_active = 0
            CALL gt_silence_all()
        END IF
        CALL gt_audio_tick()
        RETURN
    END IF

    gt_song_delay = gt_song_delay - 1
    CALL gt_audio_tick()
END SUB

_gt_fullaudio_end:
