' Simple music player using the audio coprocessor
' Plays "Twinkle Twinkle Little Star" from DATA tables.

INCLUDE "../sdk/gametank.bas"
INCLUDE "../sdk/gametank_audio.bas"
INCLUDE "../sdk/gametank_text.bas"

DIM note AS BYTE
DIM dur AS BYTE
DIM pos AS BYTE
DIM wait_timer AS BYTE
DIM song_len AS BYTE
DIM playing AS BYTE
DIM prev_lo AS BYTE
DIM new_lo AS BYTE

' --- Init audio and text ---
CALL gt_audio_init()
CALL gt_set_gram(0)
CALL gt_text_init()

song_len = 48
pos = 0
wait_timer = 0
playing = 1
prev_lo = 0

' --- Main loop ---
main_loop:
    CALL gt_cls(0)

    ' Edge-detect Start button press
    CALL gt_read_pad()
    new_lo = gt_pad1 AND (gt_pad1 XOR prev_lo)
    prev_lo = gt_pad1

    IF (new_lo AND BTN_START) <> 0 THEN
        IF playing = 0 THEN
            playing = 1
        ELSE
            playing = 0
            CALL gt_audio_stop()
        END IF
    END IF

    ' Advance sequencer when current note's timer expires
    IF playing <> 0 THEN
        IF wait_timer = 0 THEN
            note = PEEK(@melody_notes + pos)
            dur  = PEEK(@melody_durs  + pos)

            IF note = 0 THEN
                CALL gt_audio_stop()
            ELSE
                CALL gt_beep(note, dur)
            END IF

            wait_timer = dur
            pos = pos + 1
            IF pos >= song_len THEN pos = 0
        ELSE
            wait_timer = wait_timer - 1
        END IF
    END IF

    ' --- HUD ---
    CALL gt_locate(2, 1)
    CALL gt_print_str(@lbl_title)

    CALL gt_locate(1, 3)
    CALL gt_print_str(@lbl_song)

    CALL gt_locate(3, 6)
    IF playing <> 0 THEN
        CALL gt_print_str(@lbl_playing)
    ELSE
        CALL gt_print_str(@lbl_paused)
    END IF

    CALL gt_locate(3, 8)
    CALL gt_print_str(@lbl_pos)
    CALL gt_print_byte(pos)
    CALL gt_putchar(47)  ' /
    CALL gt_print_byte(song_len)

    CALL gt_locate(1, 10)
    CALL gt_print_str(@lbl_help)

    CALL gt_audio_tick()  ' Must be called every frame
    CALL gt_border(0)
    CALL gt_show()
GOTO main_loop

' --- Melody: Twinkle Twinkle Little Star ---
' Notes are MIDI values (C4=60 D4=62 E4=64 F4=65 G4=67 A4=69), 0=rest
' Durations in frames: 12=quarter, 22=half, 2=rest gap

melody_notes:
DATA AS BYTE 60, 60, 67, 67, 69, 69, 67,  0, 65, 65, 64, 64, 62, 62, 60,  0
DATA AS BYTE 67, 67, 65, 65, 64, 64, 62,  0, 67, 67, 65, 65, 64, 64, 62,  0
DATA AS BYTE 60, 60, 67, 67, 69, 69, 67,  0, 65, 65, 64, 64, 62, 62, 60,  0

melody_durs:
DATA AS BYTE 12, 12, 12, 12, 12, 12, 22,  2, 12, 12, 12, 12, 12, 12, 22,  2
DATA AS BYTE 12, 12, 12, 12, 12, 12, 22,  2, 12, 12, 12, 12, 12, 12, 22,  2
DATA AS BYTE 12, 12, 12, 12, 12, 12, 22,  2, 12, 12, 12, 12, 12, 12, 22,  2

lbl_title:
DATA AS STRING*13 "MUSIC PLAYER"
lbl_song:
DATA AS STRING*16 "TWINKLE TWINKLE"
lbl_playing:
DATA AS STRING*12 "> PLAYING <"
lbl_paused:
DATA AS STRING*11 "-- PAUSE --"
lbl_pos:
DATA AS STRING*7 "NOTE: "
lbl_help:
DATA AS STRING*16 "START=PLAY/STOP"
