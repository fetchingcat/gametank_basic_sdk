' Space Invaders - GameTank BASIC

INCLUDE "../sdk/gametank.bas"
INCLUDE "../sdk/gametank_text.bas"

GOTO main_start

spr_alien1_f1:
INCBMP "assets/sprites/alien1_f1.bmp"
spr_alien1_f2:
INCBMP "assets/sprites/alien1_f2.bmp"
spr_alien2_f1:
INCBMP "assets/sprites/alien2_f1.bmp"
spr_alien2_f2:
INCBMP "assets/sprites/alien2_f2.bmp"
spr_alien3_f1:
INCBMP "assets/sprites/alien3_f1.bmp"
spr_alien3_f2:
INCBMP "assets/sprites/alien3_f2.bmp"
spr_player:
INCBMP "assets/sprites/player.bmp"
spr_bullet:
INCBMP "assets/sprites/bullet.bmp"
spr_alien_bullet:
INCBMP "assets/sprites/alien_bullet.bmp"

str_you_win:
DATA AS STRING*9 "YOU WIN!"
str_game_over:
DATA AS STRING*11 "GAME OVER!"
str_restart:
DATA AS STRING*14 "PRESS START!"

main_start:

CONST SCREEN_W = 128
CONST SCREEN_H = 128
CONST PLAYER_Y = 110
CONST PLAYER_SPEED = 3
CONST BULLET_SPEED = 4
CONST PLAYER_DELAY = 3
CONST BULLET_DELAY = 3
CONST ALIEN_COLS = 6
CONST ALIEN_ROWS = 3
CONST ALIEN_SPACING = 18
CONST ALIEN_BULLET_SPEED = 2

DIM player_x AS BYTE
DIM bullet_x AS BYTE
DIM bullet_y AS BYTE
DIM bullet_active AS BYTE
DIM abull_x AS BYTE
DIM abull_y AS BYTE
DIM abull_active AS BYTE
DIM abull_tick AS BYTE
DIM fire_timer AS BYTE
DIM fire_delay AS BYTE
DIM rnd_seed AS BYTE

DIM aliens(18) AS BYTE
DIM alien_base_x AS BYTE
DIM alien_base_y AS BYTE
DIM alien_dir AS BYTE
DIM alien_frame AS BYTE
DIM frame_count AS BYTE
DIM move_count AS BYTE
DIM move_delay AS BYTE
DIM player_tick AS BYTE
DIM bullet_tick AS BYTE
DIM aliens_alive AS BYTE
DIM game_over AS BYTE

' GRAM layout: sprites stacked vertically, 16px apart
DIM gram_alien1_f1 AS BYTE
DIM gram_alien1_f2 AS BYTE
DIM gram_alien2_f1 AS BYTE
DIM gram_alien2_f2 AS BYTE
DIM gram_alien3_f1 AS BYTE
DIM gram_alien3_f2 AS BYTE
DIM gram_player AS BYTE
DIM gram_bullet AS BYTE
DIM gram_alien_bullet AS BYTE
DIM i AS BYTE
DIM j AS BYTE
DIM ax AS BYTE
DIM ay AS BYTE
DIM idx AS BYTE
DIM lowest_row AS BYTE

SUB init_game() STATIC
    gram_alien1_f1 = 0
    gram_alien1_f2 = 16
    gram_alien2_f1 = 32
    gram_alien2_f2 = 48
    gram_alien3_f1 = 64
    gram_alien3_f2 = 80
    gram_player = 96
    gram_bullet = 112
    gram_alien_bullet = 16
    
    CALL gt_load_sprite(@spr_alien1_f1, 0, gram_alien1_f1, 16, 16)
    CALL gt_load_sprite(@spr_alien1_f2, 0, gram_alien1_f2, 16, 16)
    CALL gt_load_sprite(@spr_alien2_f1, 0, gram_alien2_f1, 16, 16)
    CALL gt_load_sprite(@spr_alien2_f2, 0, gram_alien2_f2, 16, 16)
    CALL gt_load_sprite(@spr_alien3_f1, 0, gram_alien3_f1, 16, 16)
    CALL gt_load_sprite(@spr_alien3_f2, 0, gram_alien3_f2, 16, 16)
    CALL gt_load_sprite(@spr_player, 0, gram_player, 16, 16)
    CALL gt_load_sprite(@spr_bullet, 0, gram_bullet, 16, 16)
    CALL gt_load_sprite(@spr_alien_bullet, 16, gram_alien_bullet, 16, 16)
    
    player_x = (SCREEN_W - 16) / 2
    bullet_active = 0
    
    aliens_alive = ALIEN_COLS * ALIEN_ROWS
    FOR i = 0 TO 17
        aliens(i) = 1
    NEXT i
    
    alien_base_x = 10
    alien_base_y = 10
    alien_dir = 1
    alien_frame = 0
    frame_count = 0
    move_count = 0
    player_tick = 0
    bullet_tick = 0
    abull_active = 0
    abull_tick = 0
    fire_timer = 0
    rnd_seed = 42
    game_over = 0
END SUB

SUB draw_game() STATIC
    CALL gt_draw_sprite(0, gram_player, player_x, PLAYER_Y, 16, 16, 0)
    
    IF bullet_active = 1 THEN
        CALL gt_draw_sprite(0, gram_bullet, bullet_x, bullet_y, 16, 16, 0)
    END IF
    
    IF abull_active = 1 THEN
        CALL gt_draw_sprite(16, gram_alien_bullet, abull_x, abull_y, 16, 16, 0)
    END IF
    
    FOR j = 0 TO ALIEN_ROWS - 1
        FOR i = 0 TO ALIEN_COLS - 1
            idx = j * ALIEN_COLS + i
            IF aliens(idx) = 1 THEN
                ax = alien_base_x + (i * ALIEN_SPACING)
                ay = alien_base_y + (j * ALIEN_SPACING)
                
                IF j = 0 THEN
                    IF alien_frame = 0 THEN
                        CALL gt_draw_sprite(0, gram_alien1_f1, ax, ay, 16, 16, 0)
                    ELSE
                        CALL gt_draw_sprite(0, gram_alien1_f2, ax, ay, 16, 16, 0)
                    END IF
                END IF
                IF j = 1 THEN
                    IF alien_frame = 0 THEN
                        CALL gt_draw_sprite(0, gram_alien2_f1, ax, ay, 16, 16, 0)
                    ELSE
                        CALL gt_draw_sprite(0, gram_alien2_f2, ax, ay, 16, 16, 0)
                    END IF
                END IF
                IF j = 2 THEN
                    IF alien_frame = 0 THEN
                        CALL gt_draw_sprite(0, gram_alien3_f1, ax, ay, 16, 16, 0)
                    ELSE
                        CALL gt_draw_sprite(0, gram_alien3_f2, ax, ay, 16, 16, 0)
                    END IF
                END IF
            END IF
        NEXT i
    NEXT j
END SUB

SUB update_game() STATIC
    CALL gt_read_pad()
    
    player_tick = player_tick + 1
    IF player_tick >= PLAYER_DELAY THEN
        player_tick = 0
        IF (gt_pad1_hi AND BTN_LEFT) <> 0 THEN
            IF player_x >= PLAYER_SPEED THEN
                player_x = player_x - PLAYER_SPEED
            END IF
        END IF
        IF (gt_pad1_hi AND BTN_RIGHT) <> 0 THEN
            IF player_x < SCREEN_W - 16 - PLAYER_SPEED THEN
                player_x = player_x + PLAYER_SPEED
            END IF
        END IF
    END IF
    
    IF (gt_pad1 AND BTN_A) <> 0 THEN
        IF bullet_active = 0 THEN
            bullet_active = 1
            bullet_x = player_x
            bullet_y = PLAYER_Y - 8
        END IF
    END IF
    
    bullet_tick = bullet_tick + 1
    IF bullet_tick >= BULLET_DELAY THEN
        bullet_tick = 0
        IF bullet_active = 1 THEN
            IF bullet_y >= BULLET_SPEED THEN
                bullet_y = bullet_y - BULLET_SPEED
            ELSE
                bullet_active = 0
            END IF
        END IF
    END IF
    
    frame_count = frame_count + 1
    IF frame_count >= 16 THEN
        frame_count = 0
        alien_frame = 1 - alien_frame
    END IF
    
    move_delay = 2 + aliens_alive
    move_count = move_count + 1
    IF move_count >= move_delay THEN
        move_count = 0
        IF alien_dir = 1 THEN
            IF alien_base_x < SCREEN_W - (ALIEN_COLS * ALIEN_SPACING) THEN
                alien_base_x = alien_base_x + 2
            ELSE
                alien_dir = 0
                alien_base_y = alien_base_y + 4
            END IF
        ELSE
            IF alien_base_x > 2 THEN
                alien_base_x = alien_base_x - 2
            ELSE
                alien_dir = 1
                alien_base_y = alien_base_y + 4
            END IF
        END IF
    END IF
    
    IF bullet_active = 1 THEN
        FOR j = 0 TO ALIEN_ROWS - 1
            FOR i = 0 TO ALIEN_COLS - 1
                idx = j * ALIEN_COLS + i
                IF aliens(idx) = 1 THEN
                    ax = alien_base_x + (i * ALIEN_SPACING)
                    ay = alien_base_y + (j * ALIEN_SPACING)
                    IF bullet_x + 7 >= ax THEN
                        IF bullet_x + 7 <= ax + 13 THEN
                            IF bullet_y + 15 >= ay THEN
                                IF bullet_y + 15 <= ay + 15 THEN
                                    aliens(idx) = 0
                                    bullet_active = 0
                                    aliens_alive = aliens_alive - 1
                                END IF
                            END IF
                        END IF
                    END IF
                END IF
            NEXT i
        NEXT j
    END IF
    
    rnd_seed = (rnd_seed * 5 + 1) AND 255
    
    abull_tick = abull_tick + 1
    IF abull_tick >= BULLET_DELAY THEN
        abull_tick = 0
        IF abull_active = 1 THEN
            abull_y = abull_y + ALIEN_BULLET_SPEED
            IF abull_y >= SCREEN_H THEN
                abull_active = 0
            END IF
        END IF
    END IF
    
    fire_delay = 10 + ((aliens_alive * 30) / 18)
    fire_timer = fire_timer + 1
    IF fire_timer >= fire_delay THEN
        fire_timer = 0
        IF abull_active = 0 THEN
            i = rnd_seed MOD ALIEN_COLS
            j = 2
            idx = j * ALIEN_COLS + i
            IF aliens(idx) = 0 THEN
                j = 1
                idx = j * ALIEN_COLS + i
                IF aliens(idx) = 0 THEN
                    j = 0
                    idx = j * ALIEN_COLS + i
                END IF
            END IF
            IF aliens(idx) = 1 THEN
                abull_x = alien_base_x + (i * ALIEN_SPACING)
                abull_y = alien_base_y + (j * ALIEN_SPACING) + 12
                abull_active = 1
            END IF
        END IF
    END IF
    
    IF abull_active = 1 THEN
        IF abull_y + 5 >= PLAYER_Y THEN
            IF abull_y + 5 <= PLAYER_Y + 10 THEN
                IF abull_x + 8 >= player_x + 2 THEN
                    IF abull_x + 8 <= player_x + 14 THEN
                        game_over = 1
                    END IF
                END IF
            END IF
        END IF
    END IF
    
    lowest_row = 0
    FOR j = 0 TO ALIEN_ROWS - 1
        FOR i = 0 TO ALIEN_COLS - 1
            idx = j * ALIEN_COLS + i
            IF aliens(idx) = 1 THEN
                IF j > lowest_row THEN
                    lowest_row = j
                END IF
            END IF
        NEXT i
    NEXT j
    IF alien_base_y + (lowest_row * ALIEN_SPACING) + 16 >= PLAYER_Y THEN
        game_over = 1
    END IF
END SUB

CALL gt_set_gram(0)

game_start:
CALL init_game()

DO
    CALL gt_vsync()
    CALL gt_cls(0)
    CALL update_game()
    CALL draw_game()
    CALL gt_flip()
LOOP WHILE aliens_alive > 0 AND game_over = 0

CALL gt_text_init()

IF game_over = 1 THEN
    CALL gt_cls(112)
    CALL gt_locate(3, 7)
    CALL gt_print_str(@str_game_over)
ELSE
    CALL gt_cls(24)
    CALL gt_locate(4, 7)
    CALL gt_print_str(@str_you_win)
END IF
CALL gt_show()

FOR i = 0 TO 60
    CALL gt_vsync()
NEXT i

IF game_over = 1 THEN
    CALL gt_cls(112)
    CALL gt_locate(3, 7)
    CALL gt_print_str(@str_game_over)
ELSE
    CALL gt_cls(24)
    CALL gt_locate(4, 7)
    CALL gt_print_str(@str_you_win)
END IF
CALL gt_locate(2, 9)
CALL gt_print_str(@str_restart)
CALL gt_show()

game_end:
    CALL gt_vsync()
    CALL gt_read_pad()
    IF (gt_pad1 AND BTN_START) <> 0 THEN
        GOTO game_start
    END IF
GOTO game_end
