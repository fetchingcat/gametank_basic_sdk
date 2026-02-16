' Starfield

INCLUDE "../sdk/gametank.bas"

CONST STARS_PER_LAYER = 20
CONST TOTAL_STARS = 80

' Layer 0: indices  0-19 (slowest)
' Layer 1: indices 20-39
' Layer 2: indices 40-59
' Layer 3: indices 60-79 (fastest)
DIM star_x(80) AS BYTE
DIM star_y(80) AS BYTE

DIM i AS BYTE
DIM speed AS BYTE
DIM color AS BYTE
DIM frame AS BYTE
DIM do_move AS BYTE

frame = 0

RANDOMIZE 7777
FOR i = 0 TO TOTAL_STARS - 1
    star_x(i) = RNDB() AND 127
    star_y(i) = RNDB() AND 127
NEXT i

main_loop:
    CALL gt_cls(0)

    do_move = frame AND 1
    frame = frame + 1

    CALL gt_direct_start()

    FOR i = 0 TO 19
        IF do_move = 0 THEN
            star_y(i) = star_y(i) + 1
            IF star_y(i) > 127 THEN
                star_y(i) = 0
                star_x(i) = RNDB() AND 127
            END IF
        END IF
        CALL gt_plot(star_x(i), star_y(i), 4)
    NEXT i

    FOR i = 20 TO 39
        IF do_move = 0 THEN
            star_y(i) = star_y(i) + 2
            IF star_y(i) > 127 THEN
                star_y(i) = star_y(i) AND 1
                star_x(i) = RNDB() AND 127
            END IF
        END IF
        CALL gt_plot(star_x(i), star_y(i), 5)
    NEXT i

    FOR i = 40 TO 59
        IF do_move = 0 THEN
            star_y(i) = star_y(i) + 3
            IF star_y(i) > 127 THEN
                star_y(i) = star_y(i) AND 3
                star_x(i) = RNDB() AND 127
            END IF
        END IF
        CALL gt_plot(star_x(i), star_y(i), 6)
    NEXT i

    FOR i = 60 TO 79
        IF do_move = 0 THEN
            star_y(i) = star_y(i) + 4
            IF star_y(i) > 127 THEN
                star_y(i) = star_y(i) AND 7
                star_x(i) = RNDB() AND 127
            END IF
        END IF
        CALL gt_plot(star_x(i), star_y(i), 7)
    NEXT i

    CALL gt_direct_end()
    CALL gt_show()

GOTO main_loop
