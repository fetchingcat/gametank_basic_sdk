' tile.bas - Minimal tile rendering benchmark
' Draws a 16x16 tile map (one room) every frame, no banking.

INCLUDE "../sdk/gametank.bas"

DIM tcol(5) AS BYTE
tcol(0) = $FC   ' grass
tcol(1) = $04   ' wall
tcol(2) = $BC   ' water
tcol(3) = $35   ' sand
tcol(4) = $FA   ' tree

DIM tmap(256) AS BYTE
DIM i AS WORD

' Load map from inline DATA
FOR i = 0 TO 255
    tmap(i) = PEEK(@map_data + i)
NEXT i

DIM tx AS BYTE
DIM ty AS BYTE
DIM px AS BYTE
DIM py AS BYTE
DIM idx AS WORD
DIM t AS BYTE

main_loop:
    ' Draw all 256 tiles
    FOR ty = 0 TO 15
        py = SHL(ty, 3) ' ty * 8
        FOR tx = 0 TO 15
            idx = SHL(CWORD(ty), 4) + CWORD(tx)  ' ty * 16 + tx
            t = tmap(idx)
            px = SHL(tx, 3) ' tx * 8
            CALL gt_box(px, py, 8, 8, tcol(t))
        NEXT tx
    NEXT ty

    CALL gt_border(0)
    CALL gt_show()
GOTO main_loop

' 16x16 room: 0=grass 1=wall 2=water 3=sand 4=tree
' Spells "GT" in sand tiles on a water background
map_data:
DATA AS BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
DATA AS BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
DATA AS BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
DATA AS BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
DATA AS BYTE 2,2,2,3,3,3,3,2,2,3,3,3,3,3,2,2
DATA AS BYTE 2,2,2,3,2,2,2,2,2,2,2,3,2,2,2,2
DATA AS BYTE 2,2,2,3,2,2,2,2,2,2,2,3,2,2,2,2
DATA AS BYTE 2,2,2,3,2,3,3,2,2,2,2,3,2,2,2,2
DATA AS BYTE 2,2,2,3,2,2,3,2,2,2,2,3,2,2,2,2
DATA AS BYTE 2,2,2,3,3,3,3,2,2,2,2,3,2,2,2,2
DATA AS BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
DATA AS BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
DATA AS BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
DATA AS BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
DATA AS BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
DATA AS BYTE 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
