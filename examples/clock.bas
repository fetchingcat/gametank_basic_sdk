' GameTank Clock

INCLUDE "../sdk/gametank.bas"
INCLUDE "../sdk/gametank_text.bas"

DIM hours AS BYTE   : hours = 12
DIM minutes AS BYTE : minutes = 0
DIM seconds AS BYTE : seconds = 0
DIM frames AS BYTE  : frames = 0
DIM ticks_lo AS BYTE
DIM ticks_mid AS BYTE

DIM debounce AS BYTE : debounce = 0

DIM blink AS BYTE : blink = 1

DIM d1 AS BYTE
DIM d0 AS BYTE

str_title:
DATA AS STRING*9 "GAMETANK"
str_clock:
DATA AS STRING*6 "CLOCK"
str_ticks:
DATA AS STRING*7 "TICKS:"
str_reset:
DATA AS STRING*12 "START=RESET"

CALL gt_set_gram(0)
CALL gt_text_color(7)
CALL gt_text_init()

CALL gt_cls(0)
CALL gt_show()
CALL gt_cls(0)

main_loop:
frames = frames + 1
IF frames >= 60 THEN
    frames = 0
    seconds = seconds + 1
    IF blink = 1 THEN
        blink = 0
    ELSE
        blink = 1
    END IF
    IF seconds >= 60 THEN
        seconds = 0
        minutes = minutes + 1
        IF minutes >= 60 THEN
            minutes = 0
            hours = hours + 1
            IF hours >= 13 THEN
                hours = 1
            END IF
        END IF
    END IF
END IF

CALL gt_read_pad()
IF debounce > 0 THEN
    debounce = debounce - 1
ELSE
    IF (gt_pad1 AND BTN_START) <> 0 THEN
        hours = 12
        minutes = 0
        seconds = 0
        frames = 0
        blink = 1
        debounce = 20
    END IF
    IF (gt_pad1_hi AND BTN_UP) <> 0 THEN
        hours = hours + 1
        IF hours >= 13 THEN
            hours = 1
        END IF
        seconds = 0
        frames = 0
        debounce = 15
    END IF
    IF (gt_pad1_hi AND BTN_DOWN) <> 0 THEN
        IF hours <= 1 THEN
            hours = 12
        ELSE
            hours = hours - 1
        END IF
        seconds = 0
        frames = 0
        debounce = 15
    END IF
    IF (gt_pad1_hi AND BTN_RIGHT) <> 0 THEN
        minutes = minutes + 1
        IF minutes >= 60 THEN
            minutes = 0
        END IF
        seconds = 0
        frames = 0
        debounce = 12
    END IF
    IF (gt_pad1_hi AND BTN_LEFT) <> 0 THEN
        IF minutes = 0 THEN
            minutes = 59
        ELSE
            minutes = minutes - 1
        END IF
        seconds = 0
        frames = 0
        debounce = 12
    END IF
END IF

CALL gt_cls(0)

CALL gt_locate(4, 1)
CALL gt_print_str(@str_title)

CALL gt_locate(5, 3)
CALL gt_print_str(@str_clock)

d1 = hours / 10
d0 = hours - (d1 * 10)
CALL gt_locate(4, 7)
CALL gt_putchar(48 + d1)
CALL gt_putchar(48 + d0)

IF blink = 1 THEN
    CALL gt_putchar(58)
ELSE
    CALL gt_putchar(32)
END IF

d1 = minutes / 10
d0 = minutes - (d1 * 10)
CALL gt_putchar(48 + d1)
CALL gt_putchar(48 + d0)

IF blink = 1 THEN
    CALL gt_putchar(58)
ELSE
    CALL gt_putchar(32)
END IF

d1 = seconds / 10
d0 = seconds - (d1 * 10)
CALL gt_putchar(48 + d1)
CALL gt_putchar(48 + d0)

ticks_lo = PEEK($F0)
ticks_mid = PEEK($F1)

CALL gt_locate(2, 11)
CALL gt_print_str(@str_ticks)
CALL gt_print_byte(ticks_mid)
CALL gt_putchar(46)  ' "."
CALL gt_print_byte(ticks_lo)

CALL gt_locate(2, 14)
CALL gt_print_str(@str_reset)

CALL gt_show()
GOTO main_loop
