' Hello World - GameTank BASIC

INCLUDE "../sdk/gametank.bas"
INCLUDE "../sdk/gametank_text.bas"

str_hello:
DATA AS STRING*13 "HELLO WORLD!"    ' string data located at label str_hello (12 characters + null terminator)

CALL gt_set_gram(0)                 ' Use GRAM 0 for text font data
CALL gt_text_color(27)              ' optionally set text color, default will be white (7)
CALL gt_text_init()                 ' initialize text system (must be called before any text functions)

loop:
    CALL gt_cls(0)                  ' clear the frame buffer to 0
    CALL gt_locate(2, 7)            ' set text cursor to column 2, row 7
    CALL gt_print_str(@str_hello)   ' print the string at the current cursor position
    CALL gt_show()                  ' wait for vsync, then flip the frame buffer to display the text

GOTO loop
