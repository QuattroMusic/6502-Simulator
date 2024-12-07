; numbers from 0 to 9 to change color
; enter to toggle painting
; have fun!

; note: run at 5 - 10 khz for best result

; colors:
; 1 = black, 2 = white,  3 = gray
; 4 = red,   5 = orange, 6 = yellow
; 7 = green, 8 = cyan,   9 = blue
; 0 = purple

col_black   = 0
col_white   = 3
col_gray    = 2
col_red     = 4
col_orange  = 6
col_yellow  = 7
col_green   = 8
col_skyblue = 12
col_blue    = 10
col_purple  = 13

x_pos = 0
y_pos = 1
x_pos_old = 2
y_pos_old = 3
coords = 4  ; 2 bytes
temp_coords = 6  ; 2 bytes
space_input = 8
space_input_old = 9
is_drawing = 10
selected_col = 11
temp_col = 12
temp_col_next = 13

screen_width = 120
screen_height = 80

input_addr = $2780

key_space = 32

key_w = "w" - 32
key_s = "s" - 32
key_a = "a" - 32
key_d = "d" - 32

key_1 = 49
key_2 = 50
key_3 = 51
key_4 = 52
key_5 = 53
key_6 = 54
key_7 = 55
key_8 = 56
key_9 = 57

    .org $8000
init:
    lda #0
    sta x_pos
    sta y_pos
    jsr calculate_abs_coords
    lda #col_white
    sta (coords, x)
loop:
    lda input_addr
    ; parse movement system
    cmp #key_d
    bne no_move_right
        lda x_pos
        cmp #screen_width - 1
        beq loop  ; if at border
        jsr copy_prev_pos
        inc x_pos
        jmp draw
    no_move_right:
    cmp #key_a
    bne no_move_left
        lda x_pos
        beq loop  ; if at border
        jsr copy_prev_pos
        dec x_pos
        jmp draw
    no_move_left:
    cmp #key_w
    bne no_move_up
        lda y_pos
        beq loop  ; if at border
        jsr copy_prev_pos
        dec y_pos
        jmp draw
    no_move_up:
    cmp #key_s
    bne no_move_down
        lda y_pos
        cmp #screen_height - 1
        beq loop  ; if at border
        jsr copy_prev_pos
        inc y_pos
        jmp draw
    no_move_down:

    ; parse spaceboard key
    lda space_input
    sta space_input_old
    lda input_addr
    sta space_input
    cmp #key_space
    beq check_drawing

    ; change colors
    lda input_addr
    cmp #key_1
    bne no_change_col0
        lda #col_black
        sta selected_col
no_change_col0:
    cmp #key_2
    bne no_change_col1
        lda #col_white
        sta selected_col
no_change_col1:
    cmp #key_3
    bne no_change_col2
        lda #col_gray
        sta selected_col
no_change_col2:
    cmp #key_4
    bne no_change_col3
        lda #col_red
        sta selected_col
no_change_col3:
    cmp #key_5
    bne no_change_col4
        lda #col_orange
        sta selected_col
no_change_col4:
    cmp #key_6
    bne no_change_col5
        lda #col_yellow
        sta selected_col
no_change_col5:
    cmp #key_7
    bne no_change_col6
        lda #col_green
        sta selected_col
no_change_col6:
    cmp #key_8
    bne no_change_col7
        lda #col_skyblue
        sta selected_col
no_change_col7:
    cmp #key_9
    bne no_change_col8
        lda #col_blue
        sta selected_col
no_change_col8:
    cmp #48
    bne no_change_col9
        lda #col_purple
        sta selected_col
no_change_col9:
    jmp loop

check_drawing:
    cmp #32
    ; 'and' condition to check if key
    ; is pressed (not down, just press!)
    bne no_toggle_drawing
        lda space_input_old
        cmp #0
        bne no_toggle_drawing
            lda #32
            eor is_drawing
            sta is_drawing
            jmp loop
no_toggle_drawing:
    jmp loop

copy_prev_pos:
    lda x_pos
    sta x_pos_old
    lda y_pos
    sta y_pos_old
    rts

draw:
    lda temp_col
    sta temp_col_next
    ldx x_pos
    ldy y_pos
    jsr calculate_abs_coords
    ldx #0
    lda (coords, x)
    sta temp_col
    lda #col_white
    sta (coords, x)

    lda is_drawing
    cmp #32
    bne no_drawing
        ldx x_pos_old
        ldy y_pos_old
        jsr calculate_abs_coords
        lda selected_col
        ldx #0
        sta (coords, x)
        jmp finish_draw
no_drawing:
    ldx x_pos_old
    ldy y_pos_old
    jsr calculate_abs_coords
    lda temp_col_next
    ldx #0
    sta (coords, x)
finish_draw:
    jmp loop

calculate_abs_coords:
; calculate aboslute coords from [x, y]
; input pos is inside registers x and y
; y * 120 + x = y * (128 - 8) + x
; y * 128 - y * 8 + x
; y << 7 - y << 3 + x
; we need to also add the display offset
; coords = pos + 0x0200

    ; clean previous res
    lda #0
    sta coords
    sta coords + 1
    sta temp_coords
    sta temp_coords + 1

    ; y1 = y << 7
    sty coords
    clc
    rol coords
    rol coords + 1
    clc
    rol coords
    rol coords + 1
    clc
    rol coords
    rol coords + 1
    clc
    rol coords
    rol coords + 1
    clc
    rol coords
    rol coords + 1
    clc
    rol coords
    rol coords + 1
    clc
    rol coords
    rol coords + 1

    ; y2 = y << 3
    sty temp_coords
    clc
    rol temp_coords
    rol temp_coords + 1
    clc
    rol temp_coords
    rol temp_coords + 1
    clc
    rol temp_coords
    rol temp_coords + 1

    ; y = y1 - y2
    sec
    lda coords
    sbc temp_coords
    sta coords
    lda coords + 1
    sbc temp_coords + 1
    sta coords + 1

    ; pos = y + x
    clc
    txa
    adc coords
    sta coords
    lda #$02  ; display offset (0x200)
    adc coords + 1
    sta coords + 1
    rts

    .org $fffc
    .word init
    .word $0000
