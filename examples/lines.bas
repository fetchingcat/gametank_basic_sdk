' lines.bas - Triangle drawn with Bresenham lines

INCLUDE "../sdk/gametank.bas"

' Bresenham line drawing (uses gt_plot, requires gt_direct_start)
SUB gt_line(x0 AS BYTE, y0 AS BYTE, x1 AS BYTE, y1 AS BYTE, c AS BYTE) STATIC
    DIM dx AS INT
    DIM dy AS INT
    DIM sx AS INT
    DIM sy AS INT
    DIM err AS INT
    DIM e2 AS INT
    DIM x AS BYTE
    DIM y AS BYTE

    x = x0
    y = y0

    IF x1 > x0 THEN
        dx = x1 - x0
        sx = 1
    ELSE
        dx = x0 - x1
        sx = -1
    END IF

    IF y1 > y0 THEN
        dy = y1 - y0
        sy = 1
    ELSE
        dy = y0 - y1
        sy = -1
    END IF

    dy = -dy
    err = dx + dy

    DO
        CALL gt_plot(x, y, c)
        IF x = x1 AND y = y1 THEN EXIT DO
        e2 = err + err
        IF e2 >= dy THEN
            err = err + dy
            x = x + sx
        END IF
        IF e2 <= dx THEN
            err = err + dx
            y = y + sy
        END IF
    LOOP
END SUB

main_loop:

CALL gt_cls(0)
CALL gt_direct_start()

CALL gt_line(64, 10, 15, 110, 7)
CALL gt_line(15, 110, 112, 110, 7)
CALL gt_line(112, 110, 64, 10, 7)

CALL gt_direct_end()

CALL gt_border(0)
CALL gt_show()
GOTO main_loop
