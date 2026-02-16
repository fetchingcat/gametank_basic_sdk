' GRAM Sprite Demo
' Draws sprites directly into GRAM using gram_fill/gram_poke, no BMP files needed

INCLUDE "../sdk/gametank.bas"

DIM x AS BYTE
DIM y AS BYTE
DIM bgx AS BYTE
DIM bgy AS BYTE

CALL gt_set_gram(0)
CALL gt_gram_fill(0, 0, 128, 128, 0)

' Smiley face at (0,0) - 8x8, color 0 = transparent
CALL gt_gram_fill(0, 0, 8, 8, 85)
CALL gt_gram_poke(2, 2, 7)
CALL gt_gram_poke(5, 2, 7)
CALL gt_gram_poke(2, 5, 0)
CALL gt_gram_poke(3, 5, 0)
CALL gt_gram_poke(4, 5, 0)
CALL gt_gram_poke(5, 5, 0)

' Nested box at (16,0)
CALL gt_gram_fill(16, 0, 8, 8, 0)
CALL gt_gram_fill(17, 1, 6, 6, 42)
CALL gt_gram_fill(18, 2, 4, 4, 21)

' Arrow at (32,0)
CALL gt_gram_fill(32, 0, 8, 8, 0)
CALL gt_gram_poke(35, 0, 170)
CALL gt_gram_poke(34, 1, 170)
CALL gt_gram_poke(35, 1, 170)
CALL gt_gram_poke(36, 1, 170)
CALL gt_gram_poke(33, 2, 170)
CALL gt_gram_poke(34, 2, 170)
CALL gt_gram_poke(35, 2, 170)
CALL gt_gram_poke(36, 2, 170)
CALL gt_gram_poke(37, 2, 170)
CALL gt_gram_fill(34, 3, 3, 5, 170)

x = 60
y = 60
bgx = 20
bgy = 80

main_loop:
    CALL gt_read_pad()

    IF (gt_pad1 AND BTN_UP) <> 0 THEN y = y - 1
    IF (gt_pad1 AND BTN_DOWN) <> 0 THEN y = y + 1
    IF (gt_pad1_hi AND BTN_LEFT) <> 0 THEN x = x - 1
    IF (gt_pad1_hi AND BTN_RIGHT) <> 0 THEN x = x + 1

    CALL gt_cls(32)

    CALL gt_draw_sprite(32, 0, bgx, bgy, 8, 8, 0)
    CALL gt_draw_sprite(16, 0, 100, 50, 8, 8, 0)
    CALL gt_draw_sprite(0, 0, x, y, 8, 8, 0)

    CALL gt_show()

GOTO main_loop
