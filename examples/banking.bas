' ROM Banking Demo
' Sprite data can live in ROM banks ($8000-$BFFF) to save
' space in the fixed bank ($C000-$FFFF) where code runs.
' Use BANK n to place data, gt_load_sprite_banked() to load it.

INCLUDE "../sdk/gametank.bas"

GOTO skip_data

' Fixed bank - this data lives in the fixed ROM ($C000+)
player_sprite:
INCBMP "assets/sprites/player.bmp"

' ROM bank 0 - data placed at $8000 in bank 0
BANK 0
alien1_data:
INCBMP "assets/sprites/alien1_f1.bmp"
alien2_data:
INCBMP "assets/sprites/alien2_f1.bmp"

' ROM bank 1 - data placed at $8000 in bank 1
BANK 1
alien3_data:
INCBMP "assets/sprites/alien3_f1.bmp"

BANK FIXED
skip_data:

' NOTE: this sets up the GRAM bank  which is different from the ROM banks
' see VRAM viewer in emulator
CALL gt_set_gram(0)

' Fixed bank sprites load normally
CALL gt_load_sprite(@player_sprite, 0, 0, 16, 16)

' Banked sprites need the bank number to switch before copying
CALL gt_load_sprite_banked(0, @alien1_data, 16, 0, 16, 16)
CALL gt_load_sprite_banked(0, @alien2_data, 32, 0, 16, 16)
CALL gt_load_sprite_banked(1, @alien3_data, 48, 0, 16, 16)

main_loop:
    CALL gt_cls(0)

    CALL gt_draw_sprite(0, 0, 56, 100, 16, 16, 0)
    CALL gt_draw_sprite(16, 0, 40, 30, 16, 16, 0)
    CALL gt_draw_sprite(32, 0, 56, 30, 16, 16, 0)
    CALL gt_draw_sprite(48, 0, 72, 30, 16, 16, 0)

    CALL gt_show()
GOTO main_loop
