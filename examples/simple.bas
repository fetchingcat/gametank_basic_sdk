'GameTank SDK Demo

INCLUDE "../sdk/gametank.bas"

DIM bx AS BYTE
DIM by AS BYTE

bx = 60 : by = 60

main_loop:
    CALL gt_read_pad() ' read gamepad state into gt_pad1 and gt_pad1_hi
    
    ' handle input - move box with d-pad
    IF (gt_pad1 AND BTN_UP) <> 0 THEN by = by - 1
    IF (gt_pad1 AND BTN_DOWN) <> 0 THEN by = by + 1
    IF (gt_pad1_hi AND BTN_LEFT) <> 0 THEN bx = bx - 1
    IF (gt_pad1_hi AND BTN_RIGHT) <> 0 THEN bx = bx + 1
    
    CALL gt_cls(0)                 ' clear screen
    CALL gt_box(bx, by, 8, 8, 252) ' Draw box at (bx,by) with size 8x8 and color 252
    CALL gt_show()                 ' present frame (wait for vsync then flip video buffers)
    
    GOTO main_loop
