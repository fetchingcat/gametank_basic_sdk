' Code Banking Example
' BANK N puts SUB/FUNCTION code in switchable ROM banks ($8000-$BFFF)
' BANK FIXED returns to the fixed bank ($C000-$FFFF)
' Rules: no GOTO/GOSUB in banks, strings must be in fixed bank and passed in

INCLUDE "../sdk/gametank.bas"
INCLUDE "../sdk/gametank_text.bas"

DIM score AS WORD
DIM level AS BYTE


BANK 5

SUB draw_hud_screen(s_label AS WORD, s_score AS WORD, s_level AS WORD) SHARED STATIC
    CALL gt_locate_px(4, 28)
    CALL gt_print_str(s_label)

    CALL gt_locate_px(4, 44)
    CALL gt_print_str(s_score)
    CALL gt_print_word(score)

    CALL gt_locate_px(4, 56)
    CALL gt_print_str(s_level)
    CALL gt_print_byte(level)
END SUB

BANK FIXED

BANK 10

' Draw a box
SUB draw_box_screen(s_label AS WORD) SHARED STATIC
    CALL gt_locate_px(4, 28)
    CALL gt_print_str(s_label)

    CALL gt_box(32, 40, 64, 40, 7)
END SUB

BANK FIXED

CALL gt_set_gram(0)
CALL gt_text_init()

str_title:
DATA AS STRING*13 "CODE BANKING"
str_b5_label:
DATA AS STRING*14 "BANK 5: HUD"
str_b10_label:
DATA AS STRING*14 "BANK 10: BOX"
str_score:
DATA AS STRING*7 "SCORE:"
str_level:
DATA AS STRING*7 "LEVEL:"
str_done:
DATA AS STRING*11 "A TO FLIP"

DIM show_bars AS BYTE
show_bars = 0
level = 3
score = 3000

main_loop:
    CALL gt_cls(0)

    CALL gt_locate_px(10, 9)
    CALL gt_print_str(@str_title)

    IF show_bars = 0 THEN
        CALL draw_hud_screen(@str_b5_label, @str_score, @str_level)
    ELSE
        CALL draw_box_screen(@str_b10_label)
    END IF

    CALL gt_locate_px(28, 110)
    CALL gt_print_str(@str_done)

    CALL gt_border(0)
    CALL gt_show()

    CALL gt_read_pad()
    IF (gt_pad1 AND BTN_A) <> 0 THEN
        IF show_bars = 0 THEN
            show_bars = 1
        ELSE
            show_bars = 0
        END IF
        wait_release:
            CALL gt_read_pad()
        IF (gt_pad1 AND BTN_A) <> 0 THEN GOTO wait_release
    END IF

GOTO main_loop
