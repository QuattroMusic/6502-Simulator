; simple program that generates
; random 8bit numbers

max = $ff

    .org $8000
setup:
    lda $2788 ; random seed from ms
    ldx #0

generate_rnd: ; given A as the seed
    ; and X as a pointer in RAM
    beq do_xor
    asl
    bcc no_xor
    do_xor:
        eor #$1d
    no_xor:
        sta $0, x

loop:
    lda $0, x
    cpx #max ; if(x != max) generate_rnd
    inx
    bne generate_rnd

    brk

    .org $fffc
    .word setup
    .word $0000
