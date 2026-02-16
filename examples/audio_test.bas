' GameTank Audio Test

INCLUDE "../sdk/gametank.bas"
INCLUDE "../sdk/gametank_audio.bas"
INCLUDE "../sdk/gametank_text.bas"

DIM note AS BYTE
DIM dur AS BYTE
DIM name_idx AS BYTE
DIM octave AS BYTE
DIM prev_lo AS BYTE
DIM prev_hi AS BYTE
DIM new_lo AS BYTE
DIM new_hi AS BYTE

CALL gt_audio_init()
CALL gt_set_gram(0)
CALL gt_text_init()

note = 60
dur = 10
prev_lo = 0
prev_hi = 0

main_loop:
    CALL gt_cls(0)
    CALL gt_read_pad()

    ' Edge detect: only trigger on new presses
    new_lo = gt_pad1 AND (gt_pad1 XOR prev_lo)
    new_hi = gt_pad1_hi AND (gt_pad1_hi XOR prev_hi)
    prev_lo = gt_pad1
    prev_hi = gt_pad1_hi

    IF (new_lo AND BTN_A) <> 0 THEN
        CALL gt_sfx_blip()
    END IF

    IF (new_hi AND BTN_B) <> 0 THEN
        CALL gt_sfx_shoot()
    END IF

    IF (new_lo AND BTN_START) <> 0 THEN
        CALL gt_sfx_explode()
    END IF

    IF (new_hi AND BTN_LEFT) <> 0 THEN
        IF note > 36 THEN note = note - 1
    END IF
    IF (new_hi AND BTN_RIGHT) <> 0 THEN
        IF note < 96 THEN note = note + 1
    END IF

    IF (new_lo AND BTN_UP) <> 0 THEN
        IF dur < 255 THEN dur = dur + 1
    END IF
    IF (new_lo AND BTN_DOWN) <> 0 THEN
        IF dur > 1 THEN dur = dur - 1
    END IF

    IF (new_hi AND BTN_C) <> 0 THEN
        CALL gt_beep(note, dur)
    END IF

    name_idx = (note MOD 12) * 2
    octave = (note / 12) - 1

    CALL gt_locate(1, 2)
    CALL gt_print_str(@lbl_note)
    CALL gt_putchar(PEEK(@note_names + name_idx))
    CALL gt_putchar(PEEK(@note_names + name_idx + 1))
    CALL gt_print_byte(octave)

    CALL gt_locate(2, 4)
    CALL gt_print_str(@lbl_dur)
    CALL gt_print_byte(dur)

    CALL gt_locate(0, 7)
    CALL gt_print_str(@lbl_c1)
    CALL gt_locate(0, 8)
    CALL gt_print_str(@lbl_c2)
    CALL gt_locate(0, 9)
    CALL gt_print_str(@lbl_c3)
    CALL gt_locate(0, 11)
    CALL gt_print_str(@lbl_c4)
    CALL gt_locate(0, 12)
    CALL gt_print_str(@lbl_c5)
    CALL gt_locate(0, 13)
    CALL gt_print_str(@lbl_c6)

    CALL gt_audio_tick()
    CALL gt_show()
GOTO main_loop

note_names:
DATA AS BYTE 67,32, 67,35, 68,32, 68,35, 69,32, 70,32
DATA AS BYTE 70,35, 71,32, 71,35, 65,32, 65,35, 66,32

lbl_note:
DATA AS STRING*7 "NOTE: "
lbl_dur:
DATA AS STRING*6 "DUR: "
lbl_c1:
DATA AS STRING*11 "L/R = NOTE"
lbl_c2:
DATA AS STRING*11 "U/D = DUR"
lbl_c3:
DATA AS STRING*11 "  C = PLAY"
lbl_c4:
DATA AS STRING*11 "  A = BLIP"
lbl_c5:
DATA AS STRING*12 "  B = SHOOT"
lbl_c6:
DATA AS STRING*11 " ST = BOOM"
