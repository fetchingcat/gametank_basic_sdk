' tile16.bas - Tile rendering benchmark (16x16 tiles)
' Draws an 8x8 tile map every frame, no banking.

INCLUDE "../sdk/gametank.bas"

DIM tcol(5) AS BYTE
tcol(0) = $FC   ' grass
tcol(1) = $04   ' wall
tcol(2) = $BC   ' water
tcol(3) = $35   ' sand
tcol(4) = $FA   ' tree

DIM tmap(64) AS BYTE
DIM i AS WORD

' Load map from inline DATA
FOR i = 0 TO 63
    tmap(i) = PEEK(@map_data + i)
NEXT i

DIM tx AS BYTE
DIM ty AS BYTE
DIM px AS BYTE
DIM py AS BYTE
DIM idx AS WORD
DIM t AS BYTE

main_loop:
    ' Draw all 64 tiles (8x8 grid of 16px tiles)
    FOR ty = 0 TO 7
        py = SHL(ty, 4)
        FOR tx = 0 TO 7
            idx = SHL(CWORD(ty), 3) + CWORD(tx)
            t = tmap(idx)
            px = SHL(tx, 4)
            CALL gt_box(px, py, 16, 16, tcol(t))
        NEXT tx
    NEXT ty

    CALL gt_border(0)
    CALL gt_show()
GOTO main_loop

' 8x8 room: 0=grass 1=wall 2=water 3=sand 4=tree
map_data:
DATA AS BYTE 1,1,1,1,1,1,1,1
DATA AS BYTE 1,4,0,0,0,0,4,1
DATA AS BYTE 1,0,0,4,4,0,0,1
DATA AS BYTE 1,0,4,0,0,4,0,1
DATA AS BYTE 1,0,4,0,0,4,0,1
DATA AS BYTE 1,0,0,4,4,0,0,1
DATA AS BYTE 1,4,0,0,0,0,4,1
DATA AS BYTE 1,1,1,1,1,1,1,1
