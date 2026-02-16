' Sprite Sheet Demo
' One INCBMP holds all sprites; GX selects which 16x16 tile to draw

INCLUDE "../sdk/gametank.bas"

' GX offsets into the 128x16 sprite sheet
CONST SPR_ALIEN1_F1 = 0
CONST SPR_ALIEN1_F2 = 16
CONST SPR_ALIEN2_F1 = 32
CONST SPR_ALIEN2_F2 = 48
CONST SPR_ALIEN3_F1 = 64
CONST SPR_ALIEN3_F2 = 80
CONST SPR_PLAYER = 96
CONST SPR_BULLET = 112

DIM frame AS BYTE : frame = 0
DIM anim_frame AS BYTE : anim_frame = 0
DIM alien_y AS BYTE : alien_y = 20
DIM player_x AS BYTE : player_x = 56

CALL gt_set_gram(0)
CALL gt_load_sprite(@spritesheet, 0, 0, 128, 16)

main_loop:
    CALL gt_cls(0)

    ' Toggle animation frame every 16 ticks
    frame = frame + 1
    IF frame >= 16 THEN
        frame = 0
        anim_frame = 1 - anim_frame
    END IF

    ' Row 1
    IF anim_frame = 0 THEN
        CALL gt_draw_sprite(SPR_ALIEN1_F1, 0, 10, alien_y, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN1_F1, 0, 30, alien_y, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN1_F1, 0, 50, alien_y, 16, 16, 0)
    ELSE
        CALL gt_draw_sprite(SPR_ALIEN1_F2, 0, 10, alien_y, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN1_F2, 0, 30, alien_y, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN1_F2, 0, 50, alien_y, 16, 16, 0)
    END IF

    ' Row 2
    IF anim_frame = 0 THEN
        CALL gt_draw_sprite(SPR_ALIEN2_F1, 0, 10, alien_y + 20, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN2_F1, 0, 30, alien_y + 20, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN2_F1, 0, 50, alien_y + 20, 16, 16, 0)
    ELSE
        CALL gt_draw_sprite(SPR_ALIEN2_F2, 0, 10, alien_y + 20, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN2_F2, 0, 30, alien_y + 20, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN2_F2, 0, 50, alien_y + 20, 16, 16, 0)
    END IF

    ' Row 3
    IF anim_frame = 0 THEN
        CALL gt_draw_sprite(SPR_ALIEN3_F1, 0, 10, alien_y + 40, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN3_F1, 0, 30, alien_y + 40, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN3_F1, 0, 50, alien_y + 40, 16, 16, 0)
    ELSE
        CALL gt_draw_sprite(SPR_ALIEN3_F2, 0, 10, alien_y + 40, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN3_F2, 0, 30, alien_y + 40, 16, 16, 0)
        CALL gt_draw_sprite(SPR_ALIEN3_F2, 0, 50, alien_y + 40, 16, 16, 0)
    END IF

    CALL gt_draw_sprite(SPR_PLAYER, 0, player_x, 100, 16, 16, 0)

    CALL gt_show()

GOTO main_loop

spritesheet:
INCBMP "assets/sprites/spritesheet.bmp"

