' Top-down adventurer (solid-colour tiles)
' See also: adventurer_sprites.bas for a sprite-based version

INCLUDE "../sdk/gametank.bas"

CONST T_GRASS = 0
CONST T_WALL  = 1
CONST T_WATER = 2
CONST T_SAND  = 3
CONST T_TREE  = 4

CONST WORLD_W = 3
CONST WORLD_H = 3
CONST PLR_SPD = 2

DIM tcol(5) AS BYTE
tcol(0) = $FC   ' grass
tcol(1) = $04   ' wall
tcol(2) = $BC   ' water
tcol(3) = $35   ' sand
tcol(4) = $FA   ' tree

CONST PLR_BODY = $07

DIM px AS BYTE
DIM py AS BYTE
DIM room_x AS BYTE
DIM room_y AS BYTE
DIM room_addr AS WORD
DIM raddr(9) AS WORD
DIM rbank(9) AS BYTE
DIM room_buf(256) AS BYTE

DIM tx AS BYTE
DIM ty AS BYTE
DIM t  AS BYTE
DIM np AS BYTE
DIM need_redraw AS BYTE
DIM ctx AS BYTE
DIM cty AS BYTE
DIM fx1 AS BYTE
DIM fy1 AS BYTE
DIM fx2 AS BYTE
DIM fy2 AS BYTE

' Copy current room from banked ROM into room_buf()
SUB copy_room_to_buf() STATIC
    DIM ci AS WORD
    CALL gt_push_rom_bank()
    CALL gt_rom_bank(rbank(CWORD(room_y) * CWORD(WORLD_W) + CWORD(room_x)))
    room_addr = raddr(CWORD(room_y) * CWORD(WORLD_W) + CWORD(room_x))
    FOR ci = 0 TO 255
        room_buf(ci) = PEEK(room_addr + ci)
    NEXT ci
    CALL gt_pop_rom_bank()
END SUB

SUB draw_room_tiles() STATIC
    DIM dtx AS BYTE
    DIM dty AS BYTE
    DIM dt  AS BYTE
    DIM didx AS WORD
    DIM dpx AS BYTE
    DIM dpy AS BYTE

    FOR dty = 0 TO 15
        dpy = dty * 8
        FOR dtx = 0 TO 15
            didx = CWORD(dty) * 16 + CWORD(dtx)
            dt = room_buf(didx)
            dpx = dtx * 8
            CALL gt_box(dpx, dpy, 8, 8, tcol(dt))
        NEXT dtx
    NEXT dty
END SUB

' Draw to both framebuffers (double-buffered)
SUB load_room() STATIC
    DIM lb AS BYTE
    CALL copy_room_to_buf()
    FOR lb = 0 TO 1
        CALL draw_room_tiles()
        CALL gt_border(0)
        CALL gt_flip()
    NEXT lb
END SUB

FUNCTION tile_solid AS BYTE (cpx AS BYTE, cpy AS BYTE) STATIC
    DIM ts AS BYTE
    DIM ttx AS BYTE
    DIM tty AS BYTE
    DIM tidx AS WORD
    ttx = cpx / 8
    tty = cpy / 8
    tidx = CWORD(tty) * 16 + CWORD(ttx)
    ts = room_buf(tidx)
    IF ts = T_WALL  THEN RETURN 1
    IF ts = T_WATER THEN RETURN 1
    IF ts = T_TREE  THEN RETURN 1
    RETURN 0
END FUNCTION

raddr(0) = @room_0_0 : rbank(0) = 0
raddr(1) = @room_1_0 : rbank(1) = 0
raddr(2) = @room_2_0 : rbank(2) = 0
raddr(3) = @room_0_1 : rbank(3) = 0
raddr(4) = @room_1_1 : rbank(4) = 0
raddr(5) = @room_2_1 : rbank(5) = 1
raddr(6) = @room_0_2 : rbank(6) = 1
raddr(7) = @room_1_2 : rbank(7) = 1
raddr(8) = @room_2_2 : rbank(8) = 1

room_x = 1
room_y = 1
px = 56
py = 56

CALL load_room()

main_loop:
    CALL gt_read_pad()
    need_redraw = 0

    IF (gt_pad1_hi AND BTN_LEFT) <> 0 THEN
        IF px >= PLR_SPD THEN
            np = px - PLR_SPD
            IF tile_solid(np, py) = 0 THEN
                IF tile_solid(np, py + 7) = 0 THEN
                    px = np
                END IF
            END IF
        ELSE
            IF room_x > 0 THEN
                room_x = room_x - 1
                px = 120
                need_redraw = 1
            END IF
        END IF
    END IF
    IF need_redraw = 1 THEN GOTO do_redraw

    IF (gt_pad1_hi AND BTN_RIGHT) <> 0 THEN
        IF CWORD(px) + CWORD(PLR_SPD) + 7 < 128 THEN
            np = px + PLR_SPD
            IF tile_solid(np + 7, py) = 0 THEN
                IF tile_solid(np + 7, py + 7) = 0 THEN
                    px = np
                END IF
            END IF
        ELSE
            IF room_x < WORLD_W - 1 THEN
                room_x = room_x + 1
                px = 0
                need_redraw = 1
            END IF
        END IF
    END IF
    IF need_redraw = 1 THEN GOTO do_redraw

    IF (gt_pad1 AND BTN_UP) <> 0 THEN
        IF py >= PLR_SPD THEN
            np = py - PLR_SPD
            IF tile_solid(px, np) = 0 THEN
                IF tile_solid(px + 7, np) = 0 THEN
                    py = np
                END IF
            END IF
        ELSE
            IF room_y > 0 THEN
                room_y = room_y - 1
                py = 120
                need_redraw = 1
            END IF
        END IF
    END IF
    IF need_redraw = 1 THEN GOTO do_redraw

    IF (gt_pad1 AND BTN_DOWN) <> 0 THEN
        IF CWORD(py) + CWORD(PLR_SPD) + 7 < 128 THEN
            np = py + PLR_SPD
            IF tile_solid(px, np + 7) = 0 THEN
                IF tile_solid(px + 7, np + 7) = 0 THEN
                    py = np
                END IF
            END IF
        ELSE
            IF room_y < WORLD_H - 1 THEN
                room_y = room_y + 1
                py = 0
                need_redraw = 1
            END IF
        END IF
    END IF

do_redraw:
    IF need_redraw = 1 THEN
        CALL load_room()
    END IF

    ' Restore tiles around old player position (double-buffered)
    ctx = px + 4
    ctx = ctx / 8
    cty = py + 4
    cty = cty / 8

    IF ctx > 0  THEN fx1 = ctx - 1 ELSE fx1 = 0
    IF cty > 0  THEN fy1 = cty - 1 ELSE fy1 = 0
    IF ctx < 15 THEN fx2 = ctx + 1 ELSE fx2 = 15
    IF cty < 15 THEN fy2 = cty + 1 ELSE fy2 = 15

    DIM rpx AS BYTE
    DIM rpy AS BYTE
    FOR ty = fy1 TO fy2
        rpy = ty * 8
        FOR tx = fx1 TO fx2
            t = room_buf(CWORD(ty) * 16 + CWORD(tx))
            rpx = tx * 8
            CALL gt_box(rpx, rpy, 8, 8, tcol(t))
        NEXT tx
    NEXT ty

    CALL gt_box(px, py, 8, 8, $00)
    CALL gt_box(px + 1, py + 1, 6, 6, PLR_BODY)

    CALL gt_border(0)
    CALL gt_show()
GOTO main_loop

' Room data: 16x16 tiles, 0=grass 1=wall 2=water 3=sand 4=tree
' World: [0,0][1,0][2,0] / [0,1][1,1][2,1] / [0,2][1,2][2,2]
BANK 0
room_0_0:
DATA AS BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
DATA AS BYTE 1,4,4,0,0,0,0,0,0,0,0,0,0,4,4,1
DATA AS BYTE 1,4,0,0,4,0,0,0,0,0,0,4,0,0,4,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,4,0,0,0,4,0,0,4,0,0,0,4,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA AS BYTE 1,0,0,4,0,0,0,0,0,0,0,0,4,0,0,0
DATA AS BYTE 1,0,0,4,0,0,0,0,0,0,0,0,4,0,0,0
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA AS BYTE 1,0,4,0,0,0,4,0,0,4,0,0,0,4,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,4,0,0,4,0,0,0,0,0,0,4,0,0,4,1
DATA AS BYTE 1,4,4,0,0,0,0,0,0,0,0,0,0,4,4,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1

room_1_0:
DATA AS BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,1,1,0,0,0,0,0,0,1,1,0,0,1
DATA AS BYTE 1,0,1,1,1,1,0,0,0,0,1,1,1,1,0,1
DATA AS BYTE 1,0,0,1,1,0,0,3,3,0,0,1,1,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,3,3,0,0,0,0,0,0,1
DATA AS BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA AS BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA AS BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA AS BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA AS BYTE 1,0,0,0,0,0,0,3,3,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,1,0,0,0,3,3,0,0,0,1,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1

room_2_0:
DATA AS BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,2,2,2,2,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,2,2,2,2,2,2,0,0,0,0,1
DATA AS BYTE 1,0,0,0,2,2,2,2,2,2,2,2,0,0,0,1
DATA AS BYTE 1,0,0,0,2,2,2,2,2,2,2,2,0,0,0,1
DATA AS BYTE 0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,1
DATA AS BYTE 0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,1
DATA AS BYTE 0,0,0,0,0,0,2,2,2,2,0,0,0,0,0,1
DATA AS BYTE 0,0,0,0,0,2,2,2,2,2,2,0,0,0,0,1
DATA AS BYTE 1,0,0,0,2,2,2,2,2,2,2,2,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1

room_0_1:
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1
DATA AS BYTE 1,4,4,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,4,4,4,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,4,0,4,4,0,0,0,0,0,4,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,4,4,0,0,0,1
DATA AS BYTE 1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,4,4,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA AS BYTE 1,0,0,0,0,0,4,0,0,4,0,0,0,0,0,0
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,4,0,0,0
DATA AS BYTE 1,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA AS BYTE 1,4,4,0,0,0,0,0,0,0,4,0,0,0,0,1
DATA AS BYTE 1,0,0,0,4,0,0,0,0,0,4,4,0,0,0,1
DATA AS BYTE 1,4,0,0,4,4,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,4,4,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1

room_1_1:
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,3,3,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,4,0,0,3,3,3,3,0,0,4,0,0,1
DATA AS BYTE 1,0,0,0,0,3,3,0,0,3,3,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,3,0,0,0,0,3,0,0,0,0,1
DATA AS BYTE 0,0,0,0,0,3,0,0,0,0,3,0,0,0,0,0
DATA AS BYTE 0,0,0,3,3,3,0,0,0,0,3,3,3,0,0,0
DATA AS BYTE 0,0,0,3,3,3,0,0,0,0,3,3,3,0,0,0
DATA AS BYTE 0,0,0,0,0,3,0,0,0,0,3,0,0,0,0,0
DATA AS BYTE 1,0,0,0,0,3,3,0,0,3,3,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,3,3,3,3,0,0,0,0,0,1
DATA AS BYTE 1,0,0,4,0,0,0,3,3,0,0,0,4,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1

BANK 1

room_2_1:
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,2,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,2,2,2,1
DATA AS BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,1
DATA AS BYTE 0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,1
DATA AS BYTE 0,0,0,0,0,0,0,0,0,0,0,0,2,2,2,1
DATA AS BYTE 0,0,0,0,0,0,0,0,0,0,0,0,0,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,2,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,2,2,2,1
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1

room_0_2:
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,2,2,0,0,0,0,0,0,0,0,2,2,0,1
DATA AS BYTE 1,0,2,0,0,0,0,0,0,0,0,0,0,2,0,1
DATA AS BYTE 1,0,0,0,0,2,2,0,0,2,2,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,2,2,2,2,2,2,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DATA AS BYTE 1,0,0,0,0,0,0,2,2,0,0,0,0,0,0,0
DATA AS BYTE 1,0,2,0,0,0,2,2,2,2,0,0,0,2,0,1
DATA AS BYTE 1,0,2,2,0,0,0,0,0,0,0,0,2,2,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

room_1_2:
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,3,3,3,0,0,0,3,3,3,3,3,0,1
DATA AS BYTE 1,0,3,0,0,0,0,0,0,0,0,3,0,0,0,1
DATA AS BYTE 1,0,3,0,0,0,0,0,0,0,0,3,0,0,0,1
DATA AS BYTE 0,0,3,0,0,0,0,0,0,0,0,3,0,0,0,0
DATA AS BYTE 0,0,3,0,3,3,0,0,0,0,0,3,0,0,0,0
DATA AS BYTE 0,0,3,0,0,3,0,0,0,0,0,3,0,0,0,0
DATA AS BYTE 0,0,3,0,0,3,0,0,0,0,0,3,0,0,0,0
DATA AS BYTE 1,0,0,3,3,3,0,0,0,0,0,3,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
DATA AS BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

room_2_2:
DATA AS BYTE 1,1,1,1,1,1,0,0,0,0,1,1,1,1,1,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,3,3,3,3,3,3,1
DATA AS BYTE 1,0,0,0,0,0,0,0,3,3,3,3,3,3,3,1
DATA AS BYTE 1,0,0,0,0,0,0,3,3,3,2,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,3,3,3,2,2,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,3,3,3,2,2,2,2,2,2,2,1
DATA AS BYTE 0,0,0,0,0,0,3,3,2,2,2,2,2,2,2,1
DATA AS BYTE 0,0,0,0,0,3,3,2,2,2,2,2,2,2,2,1
DATA AS BYTE 0,0,0,0,0,3,3,2,2,2,2,2,2,2,2,1
DATA AS BYTE 0,0,0,0,0,0,3,3,2,2,2,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,3,3,3,2,2,2,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,3,3,3,2,2,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,3,3,3,3,2,2,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,3,3,3,3,3,2,2,1
DATA AS BYTE 1,0,0,0,0,0,0,0,0,3,3,3,3,3,3,1
DATA AS BYTE 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1

BANK FIXED
