; simple program that generates
; a random 8bit number

max = $ff

    .org $8000
setup:
    lda #100 ; set initial state
    ldx #0

generate_rnd: ; giving 'a' as the seed
    ; and 'x' reg as pointer in RAM
    beq do_xor
    asl
    bcc no_xor
    do_xor:
        eor #$1d
    no_xor:
        sta $0, x

loop:
    lda $0, x
    cpx #max ; if(x != max) goto loop
    inx
    bne generate_rnd

    brk

    .org $fffc
    .word setup
    .word $0000
