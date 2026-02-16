INCLUDE "../sdk/gametank.bas"

DIM ship_x AS BYTE : ship_x = 56
DIM ship_y AS BYTE : ship_y = 100
DIM ship_w AS BYTE : ship_w = 16
DIM ship_h AS BYTE : ship_h = 16

DIM gram_ship_x AS BYTE : gram_ship_x = 0
DIM gram_ship_y AS BYTE : gram_ship_y = 0

' set the GRAM bank to 0 so we can load our sprite there
CALL gt_set_gram(0)

' load sprite data from ROM into GRAM at position (0,0)
CALL gt_load_sprite(@spr_player, gram_ship_x, gram_ship_y, ship_w, ship_h)

main_loop:
    CALL gt_cls(0)
    CALL gt_draw_sprite(gram_ship_x, gram_ship_y, ship_x, ship_y, ship_w, ship_h, 0)
    CALL gt_show()

GOTO main_loop

' put our sprite data in ROM
spr_player:
INCBMP "assets/sprites/player.bmp"
