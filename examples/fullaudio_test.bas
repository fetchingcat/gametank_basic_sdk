' Full Audio Test - 4-channel FM synth
' L/R=note, U/D=octave, A=play, B=chord, C=stop, START=instrument

INCLUDE "../sdk/gametank.bas"
INCLUDE "../sdk/gametank_audio.bas"
INCLUDE "../sdk/gametank_text.bas"

DIM note AS BYTE
DIM instr_id AS BYTE
DIM prev_lo AS BYTE
DIM prev_hi AS BYTE
DIM new_lo AS BYTE
DIM new_hi AS BYTE
DIM name_idx AS BYTE
DIM octave AS BYTE
DIM roll_timer AS BYTE
CONST ROLL_INTERVAL = 8  ' frames between snare roll hits

CALL gt_audio_init()
CALL gt_set_gram(0)
CALL gt_text_init()

CALL gt_load_instrument(0, GT_INSTR_PIANO)
CALL gt_load_instrument(1, GT_INSTR_PIANO)
CALL gt_load_instrument(2, GT_INSTR_PIANO)
CALL gt_load_instrument(3, GT_INSTR_PIANO)

note = 60
instr_id = 1
prev_lo = 0
prev_hi = 0
roll_timer = 0

main_loop:
    CALL gt_cls(0)
    CALL gt_read_pad()

    CALL gt_audio_tick()

    ' Edge detect new presses
    new_lo = gt_pad1 AND (gt_pad1 XOR prev_lo)
    new_hi = gt_pad1_hi AND (gt_pad1_hi XOR prev_hi)
    prev_lo = gt_pad1
    prev_hi = gt_pad1_hi

    IF (new_lo AND BTN_A) <> 0 THEN
        CALL gt_note_on(0, note)
    END IF

    ' B = chord, or snare roll when snare is selected
    IF instr_id = GT_INSTR_SNARE THEN
        ' Snare: hold B for rapid re-trigger roll
        IF (gt_pad1_hi AND BTN_B) <> 0 THEN
            IF roll_timer = 0 THEN
                CALL gt_note_off(0)
                CALL gt_note_on(0, note)
                roll_timer = ROLL_INTERVAL
            ELSE
                roll_timer = roll_timer - 1
            END IF
        ELSE
            roll_timer = 0
        END IF
    ELSE
        ' Other instruments: B = chord
        IF (new_hi AND BTN_B) <> 0 THEN
            CALL gt_note_on(0, note)
            CALL gt_note_on(1, note + 4)
            CALL gt_note_on(2, note + 7)
            CALL gt_note_on(3, note + 12)
        END IF
    END IF

    IF (new_hi AND BTN_C) <> 0 THEN
        CALL gt_silence_all()
    END IF

    IF (new_lo AND BTN_START) <> 0 THEN
        instr_id = instr_id + 1
        IF instr_id >= GT_NUM_INSTRUMENTS THEN instr_id = 1
        CALL gt_load_instrument(0, instr_id)
        CALL gt_load_instrument(1, instr_id)
        CALL gt_load_instrument(2, instr_id)
        CALL gt_load_instrument(3, instr_id)
    END IF

    IF (new_hi AND BTN_LEFT) <> 0 THEN
        IF note > 24 THEN note = note - 1
    END IF
    IF (new_hi AND BTN_RIGHT) <> 0 THEN
        IF note < 96 THEN note = note + 1
    END IF

    IF (new_lo AND BTN_UP) <> 0 THEN
        IF note <= 84 THEN note = note + 12
    END IF
    IF (new_lo AND BTN_DOWN) <> 0 THEN
        IF note >= 36 THEN note = note - 12
    END IF

    ' Note name lookup: C, C#, D, D#, E, F, F#, G, G#, A, A#, B (2 chars each)
    name_idx = (note MOD 12) * 2
    octave = (note / 12) - 1

    CALL gt_locate(1, 1)
    CALL gt_print_str(@lbl_title)

    CALL gt_locate(1, 3)
    CALL gt_print_str(@lbl_note)
    CALL gt_putchar(PEEK(@note_names + name_idx))
    CALL gt_putchar(PEEK(@note_names + name_idx + 1))
    CALL gt_print_byte(octave)

    CALL gt_locate(1, 4)
    CALL gt_print_str(@lbl_instr)
    CALL gt_print_byte(instr_id)

    ' Display instrument name
    CALL gt_locate(1, 5)
    IF instr_id = 1 THEN CALL gt_print_str(@instr_piano)
    IF instr_id = 2 THEN CALL gt_print_str(@instr_guitar)
    IF instr_id = 3 THEN CALL gt_print_str(@instr_guitar2)
    IF instr_id = 4 THEN CALL gt_print_str(@instr_bass)
    IF instr_id = 5 THEN CALL gt_print_str(@instr_snare)
    IF instr_id = 6 THEN CALL gt_print_str(@instr_sitar)
    IF instr_id = 7 THEN CALL gt_print_str(@instr_horn)

    CALL gt_locate(0, 8)
    CALL gt_print_str(@lbl_c1)
    CALL gt_locate(0, 9)
    CALL gt_print_str(@lbl_c2)
    CALL gt_locate(0, 10)
    CALL gt_print_str(@lbl_c3)
    CALL gt_locate(0, 11)
    IF instr_id = GT_INSTR_SNARE THEN
        CALL gt_print_str(@lbl_c4b)
    ELSE
        CALL gt_print_str(@lbl_c4)
    END IF
    CALL gt_locate(0, 12)
    CALL gt_print_str(@lbl_c5)
    CALL gt_locate(0, 13)
    CALL gt_print_str(@lbl_c6)

    CALL gt_border(0)
    CALL gt_show()
GOTO main_loop

note_names:
DATA AS BYTE 67,32, 67,35, 68,32, 68,35, 69,32, 70,32
DATA AS BYTE 70,35, 71,32, 71,35, 65,32, 65,35, 66,32

lbl_title:
DATA AS STRING*17 "FULL AUDIO TEST"
lbl_note:
DATA AS STRING*7 "NOTE: "
lbl_instr:
DATA AS STRING*7 "INST: "
instr_piano:
DATA AS STRING*6 "PIANO"
instr_guitar:
DATA AS STRING*7 "GUITAR"
instr_guitar2:
DATA AS STRING*8 "GUITAR2"
instr_bass:
DATA AS STRING*5 "BASS"
instr_snare:
DATA AS STRING*6 "SNARE"
instr_sitar:
DATA AS STRING*6 "SITAR"
instr_horn:
DATA AS STRING*5 "HORN"
lbl_c1:
DATA AS STRING*14 " L/R  = NOTE"
lbl_c2:
DATA AS STRING*14 " U/D  = OCT"
lbl_c3:
DATA AS STRING*14 "  A   = PLAY"
lbl_c4:
DATA AS STRING*14 "  B   = CHORD"
lbl_c4b:
DATA AS STRING*14 "  B   = ROLL"
lbl_c5:
DATA AS STRING*14 "  C   = STOP"
lbl_c6:
DATA AS STRING*14 " ST   = INST"
