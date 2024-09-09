; program to calculate (and save oon ram)
; the fibonacci sequence up to n term
    .org $8000

max = 255

setup:
    lda #1
    sta $0
    sta $1
    ldx #0
loop:
    clc
    adc $0, x
    inx
    sta $1, x
    cpx #max - 2
    bne loop
    brk

    .org $fffc
    .word setup
    .word $0000
