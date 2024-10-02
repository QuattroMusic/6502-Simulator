; program to display
; all the colors on screen
; each row contain one color

color = 2

    .org $8000
reset:
    lda #2
    sta $1
    lda #0
    sta $0
    jmp inner

outer:
    inc color
    cmp #9
    bne no_reset_col
    lda #0
    sta color
no_reset_col:
    tya
    clc
    adc $0
    sta $0
    bcc no_inc_y
    inc $1
no_inc_y:
    ldy #0

inner:
    lda color
    sta ($0), y
    iny
    cpy #120
    bne inner
    inx
    cpx #80
    bne outer

    .org $fffc
    .word reset
    .word $0000
