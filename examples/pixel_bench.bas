' Pixel Benchmark - Test gt_plot speed

INCLUDE "../sdk/gametank.bas"

DIM x AS BYTE
DIM y AS BYTE
DIM frame AS BYTE
DIM c AS BYTE

frame = 0

main_loop:
    CALL gt_cls(0)
    
    ' Enter direct mode
    CALL gt_direct_start()
    
    ' Fill a 32x32 block (1024 pixels)
    c = frame
    FOR y = 48 TO 79
        FOR x = 48 TO 79
            CALL gt_plot(x, y, c)
        NEXT x
        c = c + 1
    NEXT y
    
    CALL gt_direct_end()
    
    CALL gt_border(0)
    CALL gt_show()
    frame = frame + 1
GOTO main_loop
