' GameTank Text Library v1.0
' Optional text rendering support - include after gametank.bas
'
' Usage:
'   INCLUDE "gametank.bas"
'   INCLUDE "gametank_text.bas"
'   ...
'   CALL gt_text_init()           ' Initialize font (once at startup)
'   CALL gt_locate(5, 3)          ' Position cursor (char cells)
'   CALL gt_print_str(@my_string) ' Print null-terminated string
'   CALL gt_print_byte(score)     ' Print byte as decimal
'
' Note: Requires ~500 bytes ROM for font data + code
'       Uses GRAM Y=0-31 (32 rows) for pre-rendered font

' Skip font data on include
GOTO _gt_text_end_data

' --- 8x8 Font Data (ASCII 32-90, 59 characters) ---
' Each character is 8 bytes, MSB = left pixel
_gt_font_data:
' Space (32)
DATA AS BYTE $00,$00,$00,$00,$00,$00,$00,$00
' ! (33)
DATA AS BYTE $18,$18,$18,$18,$18,$00,$18,$00
' " (34)
DATA AS BYTE $6C,$6C,$24,$00,$00,$00,$00,$00
' # (35)
DATA AS BYTE $24,$24,$7E,$24,$7E,$24,$24,$00
' $ (36)
DATA AS BYTE $18,$3E,$58,$3C,$1A,$7C,$18,$00
' % (37)
DATA AS BYTE $62,$64,$08,$10,$20,$4C,$8C,$00
' & (38)
DATA AS BYTE $30,$48,$48,$30,$4A,$44,$3A,$00
' ' (39)
DATA AS BYTE $18,$18,$30,$00,$00,$00,$00,$00
' ( (40)
DATA AS BYTE $0C,$18,$30,$30,$30,$18,$0C,$00
' ) (41)
DATA AS BYTE $30,$18,$0C,$0C,$0C,$18,$30,$00
' * (42)
DATA AS BYTE $00,$24,$18,$7E,$18,$24,$00,$00
' + (43)
DATA AS BYTE $00,$18,$18,$7E,$18,$18,$00,$00
' , (44)
DATA AS BYTE $00,$00,$00,$00,$00,$18,$18,$30
' - (45)
DATA AS BYTE $00,$00,$00,$7E,$00,$00,$00,$00
' . (46)
DATA AS BYTE $00,$00,$00,$00,$00,$18,$18,$00
' / (47)
DATA AS BYTE $02,$04,$08,$10,$20,$40,$80,$00
' 0 (48)
DATA AS BYTE $3C,$46,$4A,$52,$62,$42,$3C,$00
' 1 (49)
DATA AS BYTE $18,$38,$18,$18,$18,$18,$7E,$00
' 2 (50)
DATA AS BYTE $3C,$42,$02,$0C,$30,$40,$7E,$00
' 3 (51)
DATA AS BYTE $3C,$42,$02,$1C,$02,$42,$3C,$00
' 4 (52)
DATA AS BYTE $04,$0C,$14,$24,$7E,$04,$04,$00
' 5 (53)
DATA AS BYTE $7E,$40,$7C,$02,$02,$42,$3C,$00
' 6 (54)
DATA AS BYTE $1C,$20,$40,$7C,$42,$42,$3C,$00
' 7 (55)
DATA AS BYTE $7E,$02,$04,$08,$10,$10,$10,$00
' 8 (56)
DATA AS BYTE $3C,$42,$42,$3C,$42,$42,$3C,$00
' 9 (57)
DATA AS BYTE $3C,$42,$42,$3E,$02,$04,$38,$00
' : (58)
DATA AS BYTE $00,$18,$18,$00,$18,$18,$00,$00
' ; (59)
DATA AS BYTE $00,$18,$18,$00,$18,$18,$30,$00
' < (60)
DATA AS BYTE $06,$18,$60,$80,$60,$18,$06,$00
' = (61)
DATA AS BYTE $00,$00,$7E,$00,$7E,$00,$00,$00
' > (62)
DATA AS BYTE $60,$18,$06,$01,$06,$18,$60,$00
' ? (63)
DATA AS BYTE $3C,$42,$02,$0C,$10,$00,$10,$00
' @ (64)
DATA AS BYTE $3C,$42,$5E,$52,$5E,$40,$3C,$00
' A (65)
DATA AS BYTE $18,$24,$42,$42,$7E,$42,$42,$00
' B (66)
DATA AS BYTE $7C,$42,$42,$7C,$42,$42,$7C,$00
' C (67)
DATA AS BYTE $3C,$42,$40,$40,$40,$42,$3C,$00
' D (68)
DATA AS BYTE $78,$44,$42,$42,$42,$44,$78,$00
' E (69)
DATA AS BYTE $7E,$40,$40,$7C,$40,$40,$7E,$00
' F (70)
DATA AS BYTE $7E,$40,$40,$7C,$40,$40,$40,$00
' G (71)
DATA AS BYTE $3C,$42,$40,$4E,$42,$42,$3C,$00
' H (72)
DATA AS BYTE $42,$42,$42,$7E,$42,$42,$42,$00
' I (73)
DATA AS BYTE $7E,$18,$18,$18,$18,$18,$7E,$00
' J (74)
DATA AS BYTE $1E,$04,$04,$04,$04,$44,$38,$00
' K (75)
DATA AS BYTE $42,$44,$48,$70,$48,$44,$42,$00
' L (76)
DATA AS BYTE $40,$40,$40,$40,$40,$40,$7E,$00
' M (77)
DATA AS BYTE $42,$66,$5A,$5A,$42,$42,$42,$00
' N (78)
DATA AS BYTE $42,$62,$52,$4A,$46,$42,$42,$00
' O (79)
DATA AS BYTE $3C,$42,$42,$42,$42,$42,$3C,$00
' P (80)
DATA AS BYTE $7C,$42,$42,$7C,$40,$40,$40,$00
' Q (81)
DATA AS BYTE $3C,$42,$42,$42,$4A,$44,$3A,$00
' R (82)
DATA AS BYTE $7C,$42,$42,$7C,$48,$44,$42,$00
' S (83)
DATA AS BYTE $3C,$42,$40,$3C,$02,$42,$3C,$00
' T (84)
DATA AS BYTE $7E,$18,$18,$18,$18,$18,$18,$00
' U (85)
DATA AS BYTE $42,$42,$42,$42,$42,$42,$3C,$00
' V (86)
DATA AS BYTE $42,$42,$42,$42,$24,$24,$18,$00
' W (87)
DATA AS BYTE $42,$42,$42,$5A,$5A,$66,$42,$00
' X (88)
DATA AS BYTE $42,$42,$24,$18,$24,$42,$42,$00
' Y (89)
DATA AS BYTE $42,$42,$24,$18,$18,$18,$18,$00
' Z (90)
DATA AS BYTE $7E,$02,$04,$18,$20,$40,$7E,$00

_gt_text_end_data:

' --- Text System State Variables ---
DIM _gt_cursor_x AS BYTE : _gt_cursor_x = 0
DIM _gt_cursor_y AS BYTE : _gt_cursor_y = 0
DIM _gt_text_color AS BYTE : _gt_text_color = 7
DIM _gt_font_gram_y AS BYTE : _gt_font_gram_y = 0

' --- Initialize text system - expand font to GRAM ---
' Call once at startup after gt_set_gram()
SUB gt_text_init() SHARED STATIC
    DIM c AS BYTE
    DIM faddr AS WORD
    DIM gramaddr AS WORD
    DIM i AS BYTE
    DIM j AS BYTE
    DIM frow AS BYTE
    DIM bm AS BYTE
    DIM yoff AS WORD
    DIM gx AS BYTE
    DIM gy AS BYTE
    
    _gt_cursor_x = 0
    _gt_cursor_y = 0
    _gt_font_gram_y = 0  ' Font starts at GRAM Y=0
    
    ' Set up GRAM for writing
    POKE GT_BANK_REG, gt_gram_page
    POKE GT_DMA_FLAGS, DMA_NMI OR DMA_ENABLE OR DMA_GCARRY
    POKE GT_GX, 0
    POKE GT_GY, 0
    POKE GT_VX, 0
    POKE GT_VY, 0
    POKE GT_BWIDTH, 0
    POKE GT_BHEIGHT, 0
    POKE GT_BSTART, 1
    POKE GT_DMA_FLAGS, DMA_NMI
    
    ' Expand 59 characters (32-90) from 1bpp to 8bpp in GRAM
    ' Each char is 8x8, arranged in a 16x4 grid (128 wide, 32 tall)
    faddr = @_gt_font_data
    FOR c = 0 TO 58
        ' Calculate position in GRAM (16 chars per row)
        gx = (c AND 15) * 8
        
        ' Row offset: add 8 for each threshold crossed
        gy = _gt_font_gram_y
        IF c >= 16 THEN
            gy = gy + 8
        END IF
        IF c >= 32 THEN
            gy = gy + 8
        END IF
        IF c >= 48 THEN
            gy = gy + 8
        END IF
        
        ' Re-select GRAM at start of each row of characters
        IF (c AND 15) = 0 THEN
            POKE GT_BANK_REG, gt_gram_page
            POKE GT_DMA_FLAGS, DMA_NMI OR DMA_ENABLE OR DMA_GCARRY
            POKE GT_GX, 0
            POKE GT_GY, 0
            POKE GT_VX, 0
            POKE GT_VY, 0
            POKE GT_BWIDTH, 0
            POKE GT_BHEIGHT, 0
            POKE GT_BSTART, 1
            POKE GT_DMA_FLAGS, DMA_NMI
        END IF
        
        FOR j = 0 TO 7
            frow = PEEK(faddr + j)
            yoff = gy + j
            gramaddr = $4000 + (yoff * 128) + gx
            
            bm = 128
            FOR i = 0 TO 7
                IF (frow AND bm) <> 0 THEN
                    POKE gramaddr, _gt_text_color
                ELSE
                    POKE gramaddr, 0  ' Transparent
                END IF
                gramaddr = gramaddr + 1
                bm = bm / 2
            NEXT i
        NEXT j
        
        faddr = faddr + 8
    NEXT c
    
    POKE GT_DMA_FLAGS, gt_dma
    POKE GT_BANK_REG, gt_bank
END SUB

' --- Set text color (call before gt_text_init to change font color) ---
SUB gt_text_color(c AS BYTE) SHARED STATIC
    _gt_text_color = c
END SUB

' --- Set cursor position (in character cells, 16x16 grid) ---
SUB gt_locate(cx AS BYTE, cy AS BYTE) SHARED STATIC
    _gt_cursor_x = cx * 8
    _gt_cursor_y = cy * 8
END SUB

' --- Set cursor position (in pixels) ---
SUB gt_locate_px(px AS BYTE, py AS BYTE) SHARED STATIC
    _gt_cursor_x = px
    _gt_cursor_y = py
END SUB

' --- Print a single character at cursor (blits from GRAM) ---
SUB gt_putchar(c AS BYTE) SHARED STATIC
    DIM char_code AS BYTE
    DIM gx AS BYTE
    DIM gy AS BYTE
    
    ' Only print ASCII 32-90
    IF c < 32 OR c > 90 THEN
        EXIT SUB
    END IF
    
    ' Calculate position in GRAM font
    char_code = c - 32
    gx = (char_code AND 15) * 8
    
    ' Row offset
    gy = _gt_font_gram_y
    IF char_code >= 16 THEN
        gy = gy + 8
    END IF
    IF char_code >= 32 THEN
        gy = gy + 8
    END IF
    IF char_code >= 48 THEN
        gy = gy + 8
    END IF
    
    ' Blit character from GRAM to screen
    CALL gt_draw_sprite(gx, gy, _gt_cursor_x, _gt_cursor_y, 8, 8, 0)
    
    ' Advance cursor
    _gt_cursor_x = _gt_cursor_x + 8
    IF _gt_cursor_x >= 128 THEN
        _gt_cursor_x = 0
        _gt_cursor_y = _gt_cursor_y + 8
        IF _gt_cursor_y >= 128 THEN
            _gt_cursor_y = 0
        END IF
    END IF
END SUB

' --- Print a null-terminated string ---
SUB gt_print_str(addr AS WORD) SHARED STATIC
    DIM ch AS BYTE
    DIM i AS WORD
    i = addr
    DO
        ch = PEEK(i)
        IF ch = 0 THEN
            EXIT DO
        END IF
        CALL gt_putchar(ch)
        i = i + 1
    LOOP
END SUB

' --- Print a byte as decimal (0-255) ---
SUB gt_print_byte(n AS BYTE) SHARED STATIC
    DIM hundreds AS BYTE
    DIM tens AS BYTE
    DIM ones AS BYTE
    
    hundreds = n / 100
    tens = (n - (hundreds * 100)) / 10
    ones = n - (hundreds * 100) - (tens * 10)
    
    IF hundreds > 0 THEN
        CALL gt_putchar(48 + hundreds)
    END IF
    IF hundreds > 0 OR tens > 0 THEN
        CALL gt_putchar(48 + tens)
    END IF
    CALL gt_putchar(48 + ones)
END SUB

' --- Print a word as decimal (0-65535) ---
SUB gt_print_word(n AS WORD) SHARED STATIC
    DIM digits(5) AS BYTE
    DIM i AS INT  ' Signed for STEP -1
    DIM d AS BYTE
    DIM started AS BYTE
    DIM temp AS WORD
    
    temp = n
    
    ' Extract digits (ones to ten-thousands)
    FOR i = 0 TO 4
        digits(CBYTE(i)) = CBYTE(temp MOD 10)
        temp = temp / 10
    NEXT i
    
    ' Print from most significant
    started = 0
    FOR i = 4 TO 0 STEP -1
        d = digits(CBYTE(i))
        IF d > 0 OR started = 1 OR i = 0 THEN
            CALL gt_putchar(48 + d)
            started = 1
        END IF
    NEXT i
END SUB
