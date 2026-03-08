' MIDI Music Player
' Convert: node tools/midiconvert.js <file.mid> --format bin --instruments piano,piano

INCLUDE "../sdk/gametank.bas"
INCLUDE "../sdk/gametank_audio.bas"
INCLUDE "../sdk/gametank_text.bas"

DIM prev_lo AS BYTE
DIM prev_hi AS BYTE
DIM new_lo AS BYTE
DIM new_hi AS BYTE
DIM cur_song AS BYTE
DIM song_addr AS WORD

CALL gt_audio_init()
CALL gt_set_gram(0)
CALL gt_text_init()

prev_lo = 0
prev_hi = 0
cur_song = 0
song_addr = @title_song
CALL gt_song_play(song_addr, 1)

main_loop:
    CALL gt_cls(0)
    CALL gt_read_pad()

    new_lo = gt_pad1 AND (gt_pad1 XOR prev_lo)
    new_hi = gt_pad1_hi AND (gt_pad1_hi XOR prev_hi)
    prev_lo = gt_pad1
    prev_hi = gt_pad1_hi

    IF (new_lo AND BTN_START) <> 0 THEN
        IF gt_song_active <> 0 THEN
            CALL gt_song_stop()
        ELSE
            CALL gt_song_play(song_addr, 1)
        END IF
    END IF

    IF (new_lo AND BTN_A) <> 0 THEN
        CALL gt_song_play(song_addr, 1)
    END IF

    IF (new_hi AND BTN_B) <> 0 THEN
        cur_song = cur_song XOR 1
        IF cur_song = 0 THEN
            song_addr = @title_song
        ELSE
            song_addr = @drumbeat_song
        END IF
        CALL gt_song_play(song_addr, 1)
    END IF

    CALL gt_locate(2, 1)
    CALL gt_print_str(@lbl_title)
    CALL gt_locate(1, 3)
    IF cur_song = 0 THEN
        CALL gt_print_str(@song_name_1)
    ELSE
        CALL gt_print_str(@song_name_2)
    END IF
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
    CALL gt_locate(1, 11)
    CALL gt_print_str(@lbl_c3)

    CALL gt_song_tick()
    CALL gt_border(0)
    CALL gt_show()
GOTO main_loop

lbl_title:
DATA AS STRING*12 "MIDI PLAYER"
song_name_1:
DATA AS STRING*14 "FIEND TITLE"
song_name_2:
DATA AS STRING*14 "DRUMBEAT"
lbl_playing:
DATA AS STRING*12 "> PLAYING <"
lbl_stopped:
DATA AS STRING*12 "-- STOP  --"
lbl_c1:
DATA AS STRING*16 "START=PLAY/STOP"
lbl_c2:
DATA AS STRING*16 "  A = RESTART"
lbl_c3:
DATA AS STRING*16 "  B = NEXT SONG"

title_song:
INCBIN "assets/audio/fiend_title.bin"

drumbeat_song:
INCBIN "assets/audio/drumbeat.bin"
