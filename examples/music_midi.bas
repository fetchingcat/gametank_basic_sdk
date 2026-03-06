' MIDI Music Player
' Convert: node tools/midiconvert.js <file.mid> --format bin --instruments piano,piano
' Controls: START=Play/Stop, A=Restart

INCLUDE "../sdk/gametank.bas"
INCLUDE "../sdk/gametank_audio.bas"
INCLUDE "../sdk/gametank_text.bas"

DIM prev_lo AS BYTE
DIM new_lo AS BYTE

CALL gt_audio_init()
CALL gt_set_gram(0)
CALL gt_text_init()

prev_lo = 0
CALL gt_song_play(@title_song, 1)

main_loop:
    CALL gt_cls(0)
    CALL gt_read_pad()

    new_lo = gt_pad1 AND (gt_pad1 XOR prev_lo)
    prev_lo = gt_pad1

    IF (new_lo AND BTN_START) <> 0 THEN
        IF gt_song_active <> 0 THEN
            CALL gt_song_stop()
        ELSE
            CALL gt_song_play(@title_song, 1)
        END IF
    END IF

    IF (new_lo AND BTN_A) <> 0 THEN
        CALL gt_song_play(@title_song, 1)
    END IF

    CALL gt_locate(2, 1)
    CALL gt_print_str(@lbl_title)
    CALL gt_locate(3, 6)
    IF gt_song_active <> 0 THEN
        CALL gt_print_str(@lbl_playing)
    ELSE
        CALL gt_print_str(@lbl_stopped)
    END IF
    CALL gt_locate(1, 9)
    CALL gt_print_str(@lbl_c1)
    CALL gt_locate(1, 10)
    CALL gt_print_str(@lbl_c2)

    CALL gt_song_tick()
    CALL gt_border(0)
    CALL gt_show()
GOTO main_loop

lbl_title:
DATA AS STRING*12 "MIDI PLAYER"
lbl_playing:
DATA AS STRING*12 "> PLAYING <"
lbl_stopped:
DATA AS STRING*12 "-- STOP  --"
lbl_c1:
DATA AS STRING*16 "START=PLAY/STOP"
lbl_c2:
DATA AS STRING*13 "  A = RESTART"

title_song:
INCBIN "assets/audio/fiend_title.bin"
