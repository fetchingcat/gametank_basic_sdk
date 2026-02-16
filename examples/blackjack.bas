' GameTank Blackjack

INCLUDE "../sdk/gametank.bas"
INCLUDE "../sdk/gametank_text.bas"

GOTO skip_sprite_data

sprite_spade:
INCBMP "assets/cards/spade.bmp"
sprite_club:
INCBMP "assets/cards/club.bmp"
sprite_heart:
INCBMP "assets/cards/heart.bmp"
sprite_diamond:
INCBMP "assets/cards/diamond.bmp"
sprite_back:
INCBMP "assets/cards/card_back.bmp"

skip_sprite_data:

CONST MAX_CARDS = 10
CONST CARD_W = 16
CONST CARD_H = 24

' GRAM positions for suits
CONST GRAM_SPADE_X = 0
CONST GRAM_CLUB_X = 8
CONST GRAM_HEART_X = 16
CONST GRAM_DIAMOND_X = 24
CONST GRAM_SUIT_Y = 120
CONST SUIT_SIZE = 8

' Card back is 16x24, stored at y=96
CONST GRAM_BACK_X = 0
CONST GRAM_BACK_Y = 96

DIM deck(52) AS BYTE
DIM deck_pos AS BYTE      ' Current position in deck

DIM player_hand(10) AS BYTE  ' Player's cards
DIM player_count AS BYTE     ' Number of player cards
DIM player_total AS BYTE     ' Player's hand value

DIM dealer_hand(10) AS BYTE  ' Dealer's cards
DIM dealer_count AS BYTE     ' Number of dealer cards
DIM dealer_total AS BYTE     ' Dealer's hand value

DIM game_state AS BYTE    ' 0=betting, 1=player turn, 2=dealer turn, 3=result
DIM result AS BYTE        ' 0=playing, 1=player win, 2=dealer win, 3=push
DIM chips AS WORD         ' Player's chips
DIM bet AS BYTE           ' Current bet

DIM debounce AS BYTE      ' Button debounce counter
DIM show_hole AS BYTE     ' Show dealer's hole card?

DIM i AS BYTE             ' Loop counter
DIM temp AS BYTE          ' Temp variable
DIM rnd_seed AS WORD      ' For randomization

str_title:
DATA AS STRING*10 "BLACKJACK"
str_chips:
DATA AS STRING*7 "CHIPS:"
str_bet:
DATA AS STRING*5 "BET:"
str_player:
DATA AS STRING*5 "YOU="
str_dealer:
DATA AS STRING*8 "DEALER="
str_hit:
DATA AS STRING*6 "A=HIT"
str_stand:
DATA AS STRING*8 "B=STAND"
str_win:
DATA AS STRING*9 "YOU WIN!"
str_lose:
DATA AS STRING*9 "YOU LOSE"
str_push:
DATA AS STRING*5 "PUSH"
str_bust:
DATA AS STRING*6 "BUST!"
str_bj:
DATA AS STRING*11 "BLACKJACK!"
str_newgame:
DATA AS STRING*13 "A=DEAL B=BET"
str_placebet:
DATA AS STRING*12 "A=DEAL <>=5"
str_betamt:
DATA AS STRING*5 "BET:"

rank_chars:
DATA AS BYTE 65,50,51,52,53,54,55,56,57,49,74,81,75  ' A,2-9,1(for 10),J,Q,K

SUB shuffle_deck() STATIC
    DIM j AS BYTE
    DIM tmp AS BYTE
    DIM r AS BYTE
    DIM range AS BYTE
    DIM entropy AS WORD
    ' Initialize deck in order
    FOR i = 0 TO 51
        deck(i) = i
    NEXT i
    
    ' Seed built-in RNG with entropy from frame counter + hardware
    entropy = rnd_seed
    entropy = entropy XOR CWORD(PEEK($2008))
    entropy = entropy XOR (CWORD(PEEK($2009)) * 256)
    entropy = entropy XOR CWORD(PEEK($00))
    entropy = entropy XOR (CWORD(PEEK($FF)) * 256)
    IF entropy = 0 THEN
        entropy = 12345
    END IF
    RANDOMIZE entropy
    
    FOR i = 0 TO 50
        range = 52 - i
        r = RNDB()
        j = i + (r MOD range)
        
        IF i <> j THEN
            tmp = deck(i)
            deck(i) = deck(j)
            deck(j) = tmp
        END IF
    NEXT i
    
    deck_pos = 0
END SUB

FUNCTION deal_card AS BYTE () STATIC
    DIM card AS BYTE
    card = deck(deck_pos)
    deck_pos = deck_pos + 1
    RETURN card
END FUNCTION

FUNCTION card_value AS BYTE (card AS BYTE) STATIC
    DIM rank AS BYTE
    rank = card MOD 13
    
    IF rank = 0 THEN
        RETURN 11
    END IF
    IF rank >= 10 THEN
        RETURN 10
    END IF
    RETURN rank + 1
END FUNCTION

FUNCTION calc_player_hand AS BYTE () STATIC
    DIM total AS BYTE
    DIM aces AS BYTE
    DIM val AS BYTE
    DIM rank AS BYTE
    
    total = 0
    aces = 0
    
    FOR i = 0 TO player_count - 1
        val = card_value(player_hand(i))
        total = total + val
        rank = player_hand(i) MOD 13
        IF rank = 0 THEN
            aces = aces + 1
        END IF
    NEXT i
    
    DO WHILE total > 21 AND aces > 0
        total = total - 10
        aces = aces - 1
    LOOP
    
    RETURN total
END FUNCTION

FUNCTION calc_dealer_hand AS BYTE () STATIC
    DIM total AS BYTE
    DIM aces AS BYTE
    DIM val AS BYTE
    DIM rank AS BYTE
    
    total = 0
    aces = 0
    
    FOR i = 0 TO dealer_count - 1
        val = card_value(dealer_hand(i))
        total = total + val
        rank = dealer_hand(i) MOD 13
        IF rank = 0 THEN
            aces = aces + 1
        END IF
    NEXT i
    
    DO WHILE total > 21 AND aces > 0
        total = total - 10
        aces = aces - 1
    LOOP
    
    RETURN total
END FUNCTION

SUB draw_card(x AS BYTE, y AS BYTE, card AS BYTE, face_up AS BYTE) STATIC
    DIM rank AS BYTE
    DIM suit AS BYTE
    DIM suit_gx AS BYTE
    
    CALL gt_box(x, y, CARD_W, CARD_H, 7)
    CALL gt_box(x + 1, y + 1, CARD_W - 2, CARD_H - 2, 1)
    
    IF face_up = 0 THEN
        CALL gt_draw_sprite(GRAM_BACK_X, GRAM_BACK_Y, x, y, CARD_W, CARD_H, 1)
        RETURN
    END IF
    
    rank = card MOD 13
    suit = card / 13
    
    suit_gx = GRAM_SPADE_X
    IF suit = 1 THEN
        suit_gx = GRAM_HEART_X
    END IF
    IF suit = 2 THEN
        suit_gx = GRAM_DIAMOND_X
    END IF
    IF suit = 3 THEN
        suit_gx = GRAM_CLUB_X
    END IF
    
    CALL gt_locate_px(x, y + 4)
    IF rank = 9 THEN
        CALL gt_putchar(49)
        CALL gt_putchar(48)
    ELSE
        temp = PEEK(@rank_chars + rank)
        CALL gt_putchar(temp)
    END IF
    
    CALL gt_draw_sprite(suit_gx, GRAM_SUIT_Y, x + 4, y + 12, SUIT_SIZE, SUIT_SIZE, 0)
END SUB

SUB draw_player_hand() STATIC
    DIM x AS BYTE
    x = 0
    FOR i = 0 TO player_count - 1
        CALL draw_card(x, 72, player_hand(i), 1)
        x = x + CARD_W
    NEXT i
END SUB

SUB draw_dealer_hand() STATIC
    DIM x AS BYTE
    DIM face AS BYTE
    x = 0
    FOR i = 0 TO dealer_count - 1
        IF i = 0 AND show_hole = 0 THEN
            face = 0
        ELSE
            face = 1
        END IF
        CALL draw_card(x, 24, dealer_hand(i), face)
        x = x + CARD_W
    NEXT i
END SUB

SUB new_round() STATIC
    player_count = 0
    dealer_count = 0
    show_hole = 0
    result = 0
    
    ' Go to betting phase
    game_state = 0
END SUB

SUB start_deal() STATIC
    CALL shuffle_deck()
    
    IF bet > chips THEN
        bet = CBYTE(chips)
    END IF
    chips = chips - bet
    
    player_hand(0) = deal_card()
    dealer_hand(0) = deal_card()
    player_hand(1) = deal_card()
    dealer_hand(1) = deal_card()
    player_count = 2
    dealer_count = 2
    
    player_total = calc_player_hand()
    dealer_total = calc_dealer_hand()
    
    IF player_total = 21 THEN
        show_hole = 1
        IF dealer_total = 21 THEN
            result = 3
            chips = chips + bet
        ELSE
            result = 1  ' Player blackjack wins
            chips = chips + bet + bet + (bet / 2)  ' 3:2 payout
        END IF
        game_state = 3
    ELSE
        game_state = 1
    END IF
END SUB

SUB player_hit() STATIC
    IF player_count < MAX_CARDS THEN
        player_hand(player_count) = deal_card()
        player_count = player_count + 1
        player_total = calc_player_hand()
        
        IF player_total > 21 THEN
            show_hole = 1
            result = 2  ' Dealer wins
            game_state = 3
        END IF
    END IF
END SUB

SUB player_stand() STATIC
    show_hole = 1
    game_state = 2  ' Dealer's turn
END SUB

SUB dealer_play() STATIC
    ' Dealer hits on 16 or less
    DO WHILE dealer_total < 17 AND dealer_count < MAX_CARDS
        dealer_hand(dealer_count) = deal_card()
        dealer_count = dealer_count + 1
        dealer_total = calc_dealer_hand()
    LOOP
    
    IF dealer_total > 21 THEN
        result = 1
        chips = chips + bet + bet
    END IF
    IF dealer_total <= 21 AND dealer_total > player_total THEN
        result = 2
    END IF
    IF dealer_total <= 21 AND player_total > dealer_total THEN
        result = 1
        chips = chips + bet + bet
    END IF
    IF dealer_total <= 21 AND player_total = dealer_total THEN
        result = 3
        chips = chips + bet
    END IF
    
    game_state = 3
END SUB

SUB draw_screen() STATIC
    CALL gt_locate_px(24, 5)
    CALL gt_print_str(@str_title)
    
    CALL gt_locate(0, 15)
    CALL gt_print_str(@str_chips)
    CALL gt_print_word(chips)
    
    CALL gt_locate(0, 2)
    CALL gt_print_str(@str_dealer)
    IF show_hole = 1 THEN
        CALL gt_print_byte(dealer_total)
    ELSE
        IF game_state > 0 THEN
            CALL gt_putchar(63)  ' Show "?" for hidden total
        END IF
    END IF
    
    IF game_state > 0 THEN
        CALL draw_dealer_hand()
    END IF
    
    CALL gt_locate(0, 8)
    CALL gt_print_str(@str_player)
    IF game_state > 0 THEN
        player_total = calc_player_hand()  ' Recalculate to be sure
        CALL gt_print_byte(player_total)
    END IF
    
    IF game_state > 0 THEN
        CALL draw_player_hand()
    END IF
    
    
    IF game_state = 0 THEN
        ' Betting phase
        CALL gt_locate(0, 6)
        CALL gt_print_str(@str_betamt)
        CALL gt_print_byte(bet)
        CALL gt_locate(0, 13)
        CALL gt_print_str(@str_placebet)
    END IF
    IF game_state = 1 THEN
        ' Player's turn
        CALL gt_locate(0, 13)
        CALL gt_print_str(@str_hit)
        CALL gt_locate(8, 13)
        CALL gt_print_str(@str_stand)
    END IF
    IF game_state = 3 THEN
        ' Show result
        CALL gt_locate(4, 13)
        IF result = 1 THEN
            CALL gt_print_str(@str_win)
        END IF
        IF result = 2 THEN
            CALL gt_print_str(@str_lose)
        END IF
        IF result = 3 THEN
            CALL gt_print_str(@str_push)
        END IF
        CALL gt_locate(2, 14)
        CALL gt_print_str(@str_newgame)
    END IF
    
    IF game_state <> 0 THEN
        CALL gt_locate(9, 15)
        CALL gt_print_str(@str_betamt)
        CALL gt_print_byte(bet)
    END IF
END SUB

CALL gt_set_gram(0)
CALL gt_text_init()

CALL gt_load_sprite(@sprite_spade, GRAM_SPADE_X, GRAM_SUIT_Y, SUIT_SIZE, SUIT_SIZE)
CALL gt_load_sprite(@sprite_club, GRAM_CLUB_X, GRAM_SUIT_Y, SUIT_SIZE, SUIT_SIZE)
CALL gt_load_sprite(@sprite_heart, GRAM_HEART_X, GRAM_SUIT_Y, SUIT_SIZE, SUIT_SIZE)
CALL gt_load_sprite(@sprite_diamond, GRAM_DIAMOND_X, GRAM_SUIT_Y, SUIT_SIZE, SUIT_SIZE)
CALL gt_load_sprite(@sprite_back, GRAM_BACK_X, GRAM_BACK_Y, CARD_W, CARD_H)

chips = 100
bet = 10
debounce = 0
rnd_seed = 0
deck_pos = 52

player_count = 0
dealer_count = 0
show_hole = 0
result = 0
game_state = 0
CALL start_deal()

main_loop:
    CALL gt_vsync()
    
    rnd_seed = rnd_seed + 1
    
    CALL gt_cls(249)
    
    CALL draw_screen()
    
    CALL gt_flip()
    
    CALL gt_read_pad()
    
    IF debounce > 0 THEN
        debounce = debounce - 1
        GOTO main_loop
    END IF
    
    IF game_state = 0 THEN
        IF (gt_pad1 AND BTN_A) <> 0 THEN
            CALL start_deal()
            debounce = 15
            GOTO main_loop
        END IF
        IF (gt_pad1_hi AND BTN_RIGHT) <> 0 THEN
            IF bet < chips AND bet < 100 THEN
                bet = bet + 5
            END IF
            debounce = 10
        END IF
        IF (gt_pad1_hi AND BTN_LEFT) <> 0 THEN
            IF bet > 5 THEN
                bet = bet - 5
            END IF
            debounce = 10
        END IF
    END IF
    IF game_state = 1 THEN
        IF (gt_pad1 AND BTN_A) <> 0 THEN
            CALL player_hit()
            debounce = 15
            GOTO main_loop
        END IF
        IF (gt_pad1_hi AND BTN_B) <> 0 THEN
            CALL player_stand()
            debounce = 15
        END IF
    END IF
    IF game_state = 2 THEN
        CALL dealer_play()
        debounce = 15
        GOTO main_loop
    END IF
    IF game_state = 3 THEN
        IF (gt_pad1 AND BTN_A) <> 0 THEN
            player_count = 0
            dealer_count = 0
            show_hole = 0
            result = 0
            CALL start_deal()
            debounce = 15
        END IF
        IF (gt_pad1_hi AND BTN_B) <> 0 THEN
            CALL new_round()
            debounce = 15
        END IF
    END IF

GOTO main_loop
