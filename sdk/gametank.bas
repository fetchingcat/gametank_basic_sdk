' ==========================================
' GameTank SDK Library for XC-BASIC
' gametank.bas - INCLUDE this file
' ==========================================

' ==========================================
' W65C02 Instruction Macros (for inline ASM)
' These are free if not used - macros only
' generate code when invoked.
' ==========================================
ASM
    ; --- W65C02 Macros ---
    ; Usage in inline ASM: STZ_ZP $10  or  PHX_  etc.
    
    MAC STZ_ZP   ; STZ zp - Store Zero to zero page
    DC.B $64, {1}
    ENDM
    
    MAC STZ_ABS  ; STZ abs - Store Zero to absolute
    DC.B $9C
    DC.W {1}
    ENDM
    
    MAC PHX_     ; PHX - Push X
    DC.B $DA
    ENDM
    
    MAC PLX_     ; PLX - Pull X
    DC.B $FA
    ENDM
    
    MAC PHY_     ; PHY - Push Y
    DC.B $5A
    ENDM
    
    MAC PLY_     ; PLY - Pull Y
    DC.B $7A
    ENDM
    
    MAC INC_A    ; INC A - Increment Accumulator
    DC.B $1A
    ENDM
    
    MAC DEC_A    ; DEC A - Decrement Accumulator
    DC.B $3A
    ENDM
    
    MAC BRA_     ; BRA rel - Branch Always (1-byte signed offset)
    DC.B $80, {1}
    ENDM
END ASM

' ==========================================
' Hardware Constants (SHARED)
' ==========================================
SHARED CONST GT_DMA_FLAGS = $2007
SHARED CONST GT_BANK_REG = $2005
SHARED CONST GT_VIA_ORA = $2801
SHARED CONST GT_VIA_DDRA = $2803
SHARED CONST GT_GAMEPAD1 = $2008
SHARED CONST GT_GAMEPAD2 = $2009

SHARED CONST GT_VX = $4000
SHARED CONST GT_VY = $4001
SHARED CONST GT_GX = $4002
SHARED CONST GT_GY = $4003
SHARED CONST GT_BWIDTH = $4004
SHARED CONST GT_BHEIGHT = $4005
SHARED CONST GT_BSTART = $4006
SHARED CONST GT_BCOLOR = $4007
SHARED CONST GT_VRAM = $4000

SHARED CONST DMA_ENABLE = 1
SHARED CONST DMA_PAGE_OUT = 2
SHARED CONST DMA_NMI = 4
SHARED CONST DMA_COLORFILL = 8
SHARED CONST DMA_GCARRY = 16
SHARED CONST DMA_CPU_TO_VRAM = 32
SHARED CONST DMA_IRQ = 64
SHARED CONST DMA_OPAQUE = 128

SHARED CONST BANK_GRAM_MASK = 7
SHARED CONST BANK_FRAMEBUFFER = 8
SHARED CONST BANK_CLIP_X = 16
SHARED CONST BANK_CLIP_Y = 32

' Button masks for LOW byte (gt_pad1)
SHARED CONST BTN_UP = 8
SHARED CONST BTN_DOWN = 4
SHARED CONST BTN_A = 16
SHARED CONST BTN_START = 32

' Button masks for HIGH byte (gt_pad1_hi)
SHARED CONST BTN_LEFT = 2
SHARED CONST BTN_RIGHT = 1
SHARED CONST BTN_B = 16
SHARED CONST BTN_C = 32

' ==========================================
' SDK Variables (SHARED)
' ==========================================
DIM gt_frameflag AS BYTE SHARED
DIM gt_dma AS BYTE SHARED
DIM gt_bank AS BYTE SHARED
DIM gt_pad1 AS BYTE SHARED
DIM gt_pad1_hi AS BYTE SHARED
DIM gt_pad2 AS BYTE SHARED
DIM gt_pad2_hi AS BYTE SHARED
DIM gt_tmp AS BYTE SHARED
DIM gt_gram_page AS BYTE SHARED
DIM gt_draw_busy AS BYTE SHARED

' ROM Banking variables
DIM gt_rom_bank_mirror AS BYTE SHARED    ' Current ROM bank (mirror of hardware state)
DIM gt_rom_bank_idx AS BYTE SHARED       ' Stack index (0-7)
' ROM bank stack uses RAM $02F0-$02F7 (8 bytes)

' ==========================================
' SDK Initialization
' ==========================================

ASM
    LDA #0
    STA $2007
    LDA #$0c
    STA $2801
    LDX #0
    LDA #0
._rst_audio:
    STA $3000,X
    INX
    BNE ._rst_audio
    LDA #$04
    STA $2801
    LDA #$05
    STA $2007
    STA V_gt_dma
    LDA #$08
    STA $2005
    STA V_gt_bank
END ASM

GOTO _gt_sdk_end

' ==========================================
' SDK Subroutines (SHARED STATIC)
' ==========================================

SUB gt_vsync() SHARED STATIC
    gt_frameflag = 1
    DO
    LOOP WHILE gt_frameflag = 1
END SUB

SUB gt_flip() SHARED STATIC
    gt_dma = gt_dma XOR DMA_PAGE_OUT
    gt_bank = gt_bank XOR BANK_FRAMEBUFFER
    POKE GT_DMA_FLAGS, gt_dma
    POKE GT_BANK_REG, gt_bank
END SUB

' Convenience: vsync + flip in one call (typical end-of-frame)
SUB gt_show() SHARED STATIC
    CALL gt_vsync()
    CALL gt_flip()
END SUB

' ==========================================
' ROM Banking Functions
' ==========================================
' Switch to ROM bank n (0-127)
' The bank window is at $8000-$BFFF
SUB gt_rom_bank(n AS BYTE) SHARED STATIC
    ' Only switch if different
    IF n = gt_rom_bank_mirror THEN RETURN
    
    ' Shift out 7-bit bank number (MSB first) via serial interface
    ' Port $2801 bit 0 = clock, bit 1 = data, bit 2 = latch
    gt_rom_bank_mirror = n
    ASM
    LDA V_gt_rom_bank_mirror
    ; Shift left 1 bit to prepare for ROL extraction
    STZ_ABS $2801       ; Clear outputs
    CLC
    ROL                 ; Shift left once
    ROL
    ROL
    TAY                 ; Save in Y
    
    ; Shift out 7 bits (MSB first)
    .REPEAT 7
    AND #2              ; Isolate data bit
    STA $2801           ; Data out
    ORA #1              ; Clock high
    STA $2801
    TYA
    ROL                 ; Next bit
    TAY
    .REPEND
    
    ; Final bit + latch
    AND #2
    STA $2801
    ORA #1
    STA $2801
    ORA #4              ; Latch pulse
    STA $2801
    STZ_ABS $2801       ; Clear all
    END ASM
END SUB

' Push current ROM bank onto stack (max 8 levels)
' Stack uses RAM $02F0-$02F7
SUB gt_push_rom_bank() SHARED STATIC
    gt_rom_bank_idx = (gt_rom_bank_idx + 1) AND 7
    POKE $02F0 + gt_rom_bank_idx, gt_rom_bank_mirror
END SUB

' Pop ROM bank from stack and switch to it
SUB gt_pop_rom_bank() SHARED STATIC
    CALL gt_rom_bank(PEEK($02F0 + gt_rom_bank_idx))
    IF gt_rom_bank_idx = 0 THEN
        gt_rom_bank_idx = 7
    ELSE
        gt_rom_bank_idx = gt_rom_bank_idx - 1
    END IF
END SUB

SUB gt_box(x AS BYTE, y AS BYTE, w AS BYTE, h AS BYTE, c AS BYTE) SHARED STATIC
    POKE GT_DMA_FLAGS, gt_dma OR DMA_COLORFILL OR DMA_OPAQUE OR DMA_IRQ
    POKE GT_VX, x
    POKE GT_VY, y
    POKE GT_BWIDTH, w
    POKE GT_BHEIGHT, h
    POKE GT_BCOLOR, NOT c
    gt_draw_busy = 1
    POKE GT_BSTART, 1
    ASM
    CLI
._boxwait:
    LDA V_gt_draw_busy
    BNE ._boxwait
    END ASM
    POKE GT_DMA_FLAGS, gt_dma
END SUB

SUB gt_cls(c AS BYTE) SHARED STATIC
    POKE GT_DMA_FLAGS, gt_dma OR DMA_COLORFILL OR DMA_OPAQUE OR DMA_IRQ
    POKE GT_VX, 0
    POKE GT_VY, 0
    POKE GT_BWIDTH, 127
    POKE GT_BHEIGHT, 127
    POKE GT_BCOLOR, NOT c
    gt_draw_busy = 1
    POKE GT_BSTART, 1
    ' CLI then WAI - wait for blitter IRQ
    ASM
    CLI
._clswait:
    LDA V_gt_draw_busy
    BNE ._clswait
    END ASM
    POKE GT_DMA_FLAGS, gt_dma
END SUB

' Fill border/overscan region with color c (typically 0 for black).
' The safe playable area is 126x113. Borders: top 7, bottom 8,
' left 1, right 1 — matching the C SDK's queue_clear_border layout.
SUB gt_border(c AS BYTE) SHARED STATIC
    CALL gt_box(0,   0,   127, 7,   c)
    CALL gt_box(0,   7,   1,   121, c)
    CALL gt_box(1,   120, 127, 8,   c)
    CALL gt_box(127, 0,   1,   120, c)
END SUB

SUB gt_read_pad() SHARED STATIC
    DIM lo AS BYTE
    DIM hi AS BYTE
    ' Read gamepad - need to read both bytes and combine
    ' Latch
    lo = PEEK(GT_GAMEPAD2)
    ' Read low byte
    lo = PEEK(GT_GAMEPAD1)
    ' Read high byte
    hi = PEEK(GT_GAMEPAD1)
    ' Combine and invert (active low)
    gt_pad1 = NOT lo
    gt_pad1_hi = NOT hi
    
    ' Player 2
    lo = PEEK(GT_GAMEPAD2)
    hi = PEEK(GT_GAMEPAD2)
    gt_pad2 = NOT lo
    gt_pad2_hi = NOT hi
END SUB

' ==========================================
' Sprite Functions
' ==========================================

SUB gt_set_gram(page AS BYTE) SHARED STATIC
    gt_gram_page = page AND BANK_GRAM_MASK
END SUB

SUB gt_draw_sprite(gx AS BYTE, gy AS BYTE, vx AS BYTE, vy AS BYTE, w AS BYTE, h AS BYTE, opaque AS BYTE) SHARED STATIC
    DIM flags AS BYTE
    DIM banks AS BYTE
    
    flags = gt_dma OR DMA_GCARRY OR DMA_IRQ
    IF opaque <> 0 THEN
        flags = flags OR DMA_OPAQUE
    END IF
    
    banks = (gt_bank AND (NOT BANK_GRAM_MASK)) OR gt_gram_page OR BANK_CLIP_X OR BANK_CLIP_Y
    
    POKE GT_DMA_FLAGS, flags
    POKE GT_BANK_REG, banks
    
    POKE GT_GX, gx
    POKE GT_GY, gy
    POKE GT_VX, vx
    POKE GT_VY, vy
    POKE GT_BWIDTH, w
    POKE GT_BHEIGHT, h
    gt_draw_busy = 1
    POKE GT_BSTART, 1
    ASM
    CLI
._spwait:
    LDA V_gt_draw_busy
    BNE ._spwait
    END ASM
    
    POKE GT_DMA_FLAGS, gt_dma
    POKE GT_BANK_REG, gt_bank
END SUB

SUB gt_gram_poke(x AS BYTE, y AS BYTE, c AS BYTE) SHARED STATIC
    DIM addr AS WORD
    DIM yoff AS WORD
    
    ' Set up bank and do dummy blit to select quadrant 0
    POKE GT_BANK_REG, gt_gram_page
    POKE GT_DMA_FLAGS, DMA_NMI OR DMA_ENABLE OR DMA_GCARRY
    POKE GT_GX, 0
    POKE GT_GY, 0
    POKE GT_VX, 0
    POKE GT_VY, 0
    POKE GT_BWIDTH, 0
    POKE GT_BHEIGHT, 0
    POKE GT_BSTART, 1
    ' Now disable DMA for CPU writes
    POKE GT_DMA_FLAGS, DMA_NMI
    
    yoff = y
    addr = $4000 + (yoff * 128) + x
    
    POKE addr, c
    
    POKE GT_DMA_FLAGS, gt_dma
    POKE GT_BANK_REG, gt_bank
END SUB

SUB gt_gram_fill(x AS BYTE, y AS BYTE, w AS BYTE, h AS BYTE, c AS BYTE) SHARED STATIC
    DIM row AS BYTE
    DIM col AS BYTE
    DIM addr AS WORD
    DIM yoff AS WORD
    
    ' Set up bank and do dummy blit to select quadrant 0
    POKE GT_BANK_REG, gt_gram_page
    POKE GT_DMA_FLAGS, DMA_NMI OR DMA_ENABLE OR DMA_GCARRY
    POKE GT_GX, 0
    POKE GT_GY, 0
    POKE GT_VX, 0
    POKE GT_VY, 0
    POKE GT_BWIDTH, 0
    POKE GT_BHEIGHT, 0
    POKE GT_BSTART, 1
    ' Now disable DMA for CPU writes
    POKE GT_DMA_FLAGS, DMA_NMI
    
    FOR row = 0 TO h - 1
        yoff = y + row
        addr = $4000 + (yoff * 128) + x
        FOR col = 0 TO w - 1
            POKE addr, c
            addr = addr + 1
        NEXT col
    NEXT row
    
    POKE GT_DMA_FLAGS, gt_dma
    POKE GT_BANK_REG, gt_bank
END SUB

' ------------------------------------------
' gt_load_sprite - Copy sprite data from ROM to GRAM
' src: address of sprite data (use @label)
' gx, gy: destination position in GRAM
' w, h: sprite dimensions
' Handles GRAM's 128-byte row stride automatically
' ------------------------------------------
SUB gt_load_sprite(src AS WORD, gx AS BYTE, gy AS BYTE, w AS BYTE, h AS BYTE) SHARED STATIC
    DIM row AS BYTE
    DIM col AS BYTE
    DIM dst AS WORD
    DIM yoff AS WORD
    DIM c AS BYTE
    
    ' Set up bank and do dummy blit to select quadrant 0
    POKE GT_BANK_REG, gt_gram_page
    POKE GT_DMA_FLAGS, DMA_NMI OR DMA_ENABLE OR DMA_GCARRY
    POKE GT_GX, 0
    POKE GT_GY, 0
    POKE GT_VX, 0
    POKE GT_VY, 0
    POKE GT_BWIDTH, 0
    POKE GT_BHEIGHT, 0
    POKE GT_BSTART, 1
    ' Now disable DMA for CPU writes
    POKE GT_DMA_FLAGS, DMA_NMI
    
    FOR row = 0 TO h - 1
        yoff = gy + row
        dst = $4000 + (yoff * 128) + gx
        FOR col = 0 TO w - 1
            c = PEEK(src)
            POKE dst, c
            src = src + 1
            dst = dst + 1
        NEXT col
    NEXT row
    
    POKE GT_DMA_FLAGS, gt_dma
    POKE GT_BANK_REG, gt_bank
END SUB

' ------------------------------------------
' gt_load_sprite_banked - Load sprite from a banked ROM address
' Automatically switches bank, loads sprite, restores previous bank
' ------------------------------------------
SUB gt_load_sprite_banked(bank AS BYTE, src AS WORD, gx AS BYTE, gy AS BYTE, w AS BYTE, h AS BYTE) SHARED STATIC
    CALL gt_push_rom_bank()
    CALL gt_rom_bank(bank)
    CALL gt_load_sprite(src, gx, gy, w, h)
    CALL gt_pop_rom_bank()
END SUB

' ------------------------------------------
' gt_pset - Plot a single pixel to framebuffer
' x, y: screen coordinates (0-127)
' c: color
' Note: This is relatively slow - better to use gt_direct_start/end for batching
' ------------------------------------------
SUB gt_pset(x AS BYTE, y AS BYTE, c AS BYTE) SHARED STATIC
    DIM addr AS WORD
    DIM yoff AS WORD
    DIM flags AS BYTE
    
    ' Wait for any blitter operation to complete
    DO WHILE gt_draw_busy <> 0
    LOOP
    
    ' Set up for direct CPU write to framebuffer
    ' Enable CPU->VRAM, disable blitter
    flags = (gt_dma OR DMA_CPU_TO_VRAM) AND (NOT DMA_ENABLE)
    POKE GT_DMA_FLAGS, flags
    
    ' gt_bank already points to back buffer (maintained by gt_flip)
    POKE GT_BANK_REG, gt_bank
    
    ' Calculate address: VRAM base + y*128 + x
    yoff = y
    addr = $4000 + (yoff * 128) + x
    POKE addr, c
    
    ' Restore normal state
    POKE GT_DMA_FLAGS, gt_dma
END SUB

' ------------------------------------------
' gt_direct_start - Begin direct pixel mode (for batch operations)
' Call before drawing many pixels, then gt_direct_end when done
' Much faster than calling gt_pset for each pixel!
' ------------------------------------------
SUB gt_direct_start() SHARED STATIC
    DIM flags AS BYTE
    
    ' Wait for any blitter operation to complete
    DO WHILE gt_draw_busy <> 0
    LOOP
    
    ' Enable CPU->VRAM, disable blitter
    flags = (gt_dma OR DMA_CPU_TO_VRAM) AND (NOT DMA_ENABLE)
    POKE GT_DMA_FLAGS, flags
    POKE GT_BANK_REG, gt_bank
END SUB

' ------------------------------------------
' gt_direct_end - End direct pixel mode
' ------------------------------------------
SUB gt_direct_end() SHARED STATIC
    POKE GT_DMA_FLAGS, gt_dma
END SUB

' ------------------------------------------
' gt_plot - Fast pixel plot (use only between gt_direct_start/end)
' Pure assembly: uses LSR for y/2 and ROR for (y&1)<<7
' addr = $4000 + y*128 + x = $4000 + (y<<7) + x
' high byte = $40 + (y >> 1)
' low byte = ((y AND 1) << 7) + x
' ------------------------------------------
SUB gt_plot(x AS BYTE, y AS BYTE, c AS BYTE) SHARED STATIC
    ASM
        ; Calculate high byte: $40 + (y >> 1)
        LDA {y}
        LSR             ; y >> 1 (accumulator mode)
        CLC
        ADC #$40        ; + $40
        STA $03         ; high byte
        
        ; Calculate low byte using ROR trick
        ; bit 0 of y becomes bit 7, then add x
        LDA {y}
        ROR             ; bit 0 -> carry -> bit 7 on next ROR
        LDA #0
        ROR             ; carry -> bit 7 (gives $80 or $00)
        CLC
        ADC {x}         ; + x
        STA $02         ; low byte
        
        ; Store color
        LDA {c}
        LDY #0
        STA ($02),Y
    END ASM
END SUB

' ==========================================
' Interrupt Handlers (inline, with tick counter)
' ==========================================
nmi_entry:
ASM
    PHA
    LDA #0
    STA V_gt_frameflag
    ; Tick counter at ZP $F0-$F2
    INC $F0
    BNE ._nmi_done
    INC $F1
    BNE ._nmi_done
    INC $F2
._nmi_done:
    PLA
    RTI
END ASM

irq_entry:
ASM
    PHA
    LDA #0
    STA $4006           ; Acknowledge DMA
    STA V_gt_draw_busy
    PLA
    RTI
END ASM

_gt_sdk_end:
