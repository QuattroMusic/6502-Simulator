; program to fill the screen
; with one color (RED)

    .org $8000

col = 3

reset:
    lda #2
    sta $1
    lda #0
    sta $0
    jmp inner

outer:
    tya
    clc
    adc $0
    sta $0
    bcc no_inc_y
    inc $1
no_inc_y:
    ldy #0

inner:
    lda #col
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
