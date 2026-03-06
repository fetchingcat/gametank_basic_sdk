' 3D Wireframe Cube - Bresenham lines + fixed-point rotation

INCLUDE "../sdk/gametank.bas"

' Bresenham line drawing (requires gt_direct_start)
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

' Cube vertices: back face 0-3, front face 4-7
DIM cvx(8) AS INT
DIM cvy(8) AS INT
DIM cvz(8) AS INT

DIM sx(8) AS BYTE
DIM sy(8) AS BYTE
DIM angY AS BYTE
DIM angX AS BYTE
DIM i AS BYTE
DIM cidx AS BYTE
DIM sinY AS INT
DIM cosY AS INT
DIM sinX AS INT
DIM cosX AS INT
DIM tx AS INT
DIM ty AS INT
DIM tz AS INT
DIM rx AS INT
DIM ry AS INT
DIM rz AS INT
DIM denom AS INT

cvx(0) = -25 : cvy(0) = -25 : cvz(0) = -25
cvx(1) =  25 : cvy(1) = -25 : cvz(1) = -25
cvx(2) =  25 : cvy(2) =  25 : cvz(2) = -25
cvx(3) = -25 : cvy(3) =  25 : cvz(3) = -25
cvx(4) = -25 : cvy(4) = -25 : cvz(4) =  25
cvx(5) =  25 : cvy(5) = -25 : cvz(5) =  25
cvx(6) =  25 : cvy(6) =  25 : cvz(6) =  25
cvx(7) = -25 : cvy(7) =  25 : cvz(7) =  25

angY = 0
angX = 0

main_loop:
    CALL gt_cls(0)
    CALL gt_direct_start()

    ' Sin/cos lookup: table value - 128 gives signed -127..+127
    sinY = CINT(PEEK(@sin_tbl + angY)) - 128
    cidx = angY + 64
    cosY = CINT(PEEK(@sin_tbl + cidx)) - 128

    sinX = CINT(PEEK(@sin_tbl + angX)) - 128
    cidx = angX + 64
    cosX = CINT(PEEK(@sin_tbl + cidx)) - 128

    FOR i = 0 TO 7
        ' Rotate Y then X, perspective project (camera z=-200)
        tx = (cvx(i) * cosY - cvz(i) * sinY) / 128
        tz = (cvx(i) * sinY + cvz(i) * cosY) / 128
        ty = cvy(i)

        rx = tx
        ry = (ty * cosX - tz * sinX) / 128
        rz = (ty * sinX + tz * cosX) / 128

        denom = 200 + rz
        sx(i) = 64 + (rx * 200) / denom
        sy(i) = 64 + (ry * 200) / denom
    NEXT i

    CALL gt_line(sx(0), sy(0), sx(1), sy(1), 255)
    CALL gt_line(sx(1), sy(1), sx(2), sy(2), 255)
    CALL gt_line(sx(2), sy(2), sx(3), sy(3), 255)
    CALL gt_line(sx(3), sy(3), sx(0), sy(0), 255)

    CALL gt_line(sx(4), sy(4), sx(5), sy(5), 255)
    CALL gt_line(sx(5), sy(5), sx(6), sy(6), 255)
    CALL gt_line(sx(6), sy(6), sx(7), sy(7), 255)
    CALL gt_line(sx(7), sy(7), sx(4), sy(4), 255)

    CALL gt_line(sx(0), sy(0), sx(4), sy(4), 255)
    CALL gt_line(sx(1), sy(1), sx(5), sy(5), 255)
    CALL gt_line(sx(2), sy(2), sx(6), sy(6), 255)
    CALL gt_line(sx(3), sy(3), sx(7), sy(7), 255)

    CALL gt_direct_end()

    angY = angY + 2
    angX = angX + 1

    CALL gt_border(0)
    CALL gt_show()
GOTO main_loop

' Sine table: 256 entries, value = round(127*sin) + 128, cosine = index + 64
sin_tbl:
ASM
    .byte 128, 131, 134, 137, 140, 144, 147, 150, 153, 156, 159, 162, 165, 168, 171, 174
    .byte 177, 179, 182, 185, 188, 191, 193, 196, 199, 201, 204, 206, 209, 211, 213, 216
    .byte 218, 220, 222, 224, 226, 228, 230, 232, 234, 235, 237, 239, 240, 241, 243, 244
    .byte 245, 246, 248, 249, 250, 250, 251, 252, 253, 253, 254, 254, 254, 255, 255, 255
    .byte 255, 255, 255, 255, 254, 254, 254, 253, 253, 252, 251, 250, 250, 249, 248, 246
    .byte 245, 244, 243, 241, 240, 239, 237, 235, 234, 232, 230, 228, 226, 224, 222, 220
    .byte 218, 216, 213, 211, 209, 206, 204, 201, 199, 196, 193, 191, 188, 185, 182, 179
    .byte 177, 174, 171, 168, 165, 162, 159, 156, 153, 150, 147, 144, 140, 137, 134, 131
    .byte 128, 125, 122, 119, 116, 112, 109, 106, 103, 100, 97, 94, 91, 88, 85, 82
    .byte 79, 77, 74, 71, 68, 65, 63, 60, 57, 55, 52, 50, 47, 45, 43, 40
    .byte 38, 36, 34, 32, 30, 28, 26, 24, 22, 21, 19, 17, 16, 15, 13, 12
    .byte 11, 10, 8, 7, 6, 6, 5, 4, 3, 3, 2, 2, 2, 1, 1, 1
    .byte 1, 1, 1, 1, 2, 2, 2, 3, 3, 4, 5, 6, 6, 7, 8, 10
    .byte 11, 12, 13, 15, 16, 17, 19, 21, 22, 24, 26, 28, 30, 32, 34, 36
    .byte 38, 40, 43, 45, 47, 50, 52, 55, 57, 60, 63, 65, 68, 71, 74, 77
    .byte 79, 82, 85, 88, 91, 94, 97, 100, 103, 106, 109, 112, 116, 119, 122, 125
END ASM
