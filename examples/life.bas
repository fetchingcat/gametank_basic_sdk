' Game of Life - 32x32 toroidal grid, 4x4 pixel cells
' Controls: A = randomize, B = R-pentomino

INCLUDE "../sdk/gametank.bas"

CONST GRID_W = 32
CONST GRID_SZ = 1024
CONST CELL_PX = 4

DIM cells(1024) AS BYTE
DIM ncells(1024) AS BYTE

DIM i AS INT
DIM x AS BYTE
DIM y AS BYTE
DIM n AS BYTE
DIM xl AS BYTE
DIM xr AS BYTE
DIM yu AS INT
DIM yc AS INT
DIM yd AS INT
DIM idx AS INT
DIM bx AS BYTE
DIM by AS BYTE
DIM clr AS BYTE
DIM alive AS INT

GOSUB randomize_grid

main_loop:
CALL gt_cls(0)
FOR i = 0 TO 1023
    IF cells(i) = 1 THEN
        bx = CBYTE(i AND 31)
        by = CBYTE(SHR(i, 5))
        clr = SHL((bx + by) AND 7, 5) OR $1F  ' rainbow hue from position
        CALL gt_box(SHL(bx, 2), SHL(by, 2), CELL_PX, CELL_PX, clr)
    END IF
NEXT i
CALL gt_border(0)
CALL gt_show()

CALL gt_read_pad()

' Compute next generation
FOR y = 0 TO 31
    IF y = 0 THEN
        yu = 992
    ELSE
        yu = CINT(y - 1) * 32
    END IF
    yc = CINT(y) * 32
    IF y = 31 THEN
        yd = 0
    ELSE
        yd = CINT(y + 1) * 32
    END IF

    FOR x = 0 TO 31
        IF x = 0 THEN xl = 31 ELSE xl = x - 1
        IF x = 31 THEN xr = 0 ELSE xr = x + 1

        ' Count 8 neighbors
        n = cells(yu + CINT(xl))
        n = n + cells(yu + CINT(x))
        n = n + cells(yu + CINT(xr))
        n = n + cells(yc + CINT(xl))
        n = n + cells(yc + CINT(xr))
        n = n + cells(yd + CINT(xl))
        n = n + cells(yd + CINT(x))
        n = n + cells(yd + CINT(xr))

        idx = yc + CINT(x)
        ncells(idx) = 0
        IF n = 3 THEN
            ncells(idx) = 1
        END IF
        IF n = 2 THEN
            IF cells(idx) = 1 THEN
                ncells(idx) = 1
            END IF
        END IF
    NEXT x
NEXT y

alive = 0
FOR i = 0 TO 1023
    cells(i) = ncells(i)
    IF cells(i) = 1 THEN
        alive = alive + 1
    END IF
NEXT i

IF alive = 0 THEN
    GOSUB randomize_grid
END IF

IF gt_pad1 AND BTN_A THEN
    GOSUB randomize_grid
END IF
IF gt_pad1_hi AND BTN_B THEN
    GOSUB place_rpentomino
END IF

GOTO main_loop

randomize_grid:
    FOR i = 0 TO 1023
        IF RNDB() < 64 THEN
            cells(i) = 1
        ELSE
            cells(i) = 0
        END IF
    NEXT i
RETURN

place_rpentomino:
    FOR i = 0 TO 1023
        cells(i) = 0
    NEXT i
    cells(464) = 1     ' (16, 14) = 14*32 + 16
    cells(465) = 1     ' (17, 14) = 14*32 + 17
    cells(495) = 1     ' (15, 15) = 15*32 + 15
    cells(496) = 1     ' (16, 15) = 15*32 + 16
    cells(528) = 1     ' (16, 16) = 16*32 + 16
RETURN
