; hello, 6502!

coords = $00       ; 2 bytes
temp_coords = $02  ; 2 bytes

prev_x = $04
prev_y = $05
prev_a = $06
it = $07

	.org $8000
draw_text:
	ldx #16
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #17
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #21
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #22
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #18
	ldy #36
	lda #3
	jsr loop_horizontal
	
	ldx #24
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #25
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #26
	ldy #33
	lda #5
	jsr loop_horizontal
	ldx #26
	ldy #36
	lda #4
	jsr loop_horizontal
	ldx #26
	ldy #39
	lda #5
	jsr loop_horizontal
	
	ldx #32
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #33
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #34
	ldy #39
	lda #5
	jsr loop_horizontal
	
	ldx #40
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #41
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #42
	ldy #39
	lda #5
	jsr loop_horizontal
	
	ldx #48
	ldy #34
	lda #5
	jsr loop_vertical
	ldx #49
	ldy #33
	lda #7
	jsr loop_vertical
	ldx #50
	ldy #33
	lda #4
	jsr loop_horizontal
	ldx #53
	ldy #34
	lda #5
	jsr loop_vertical
	ldx #54
	ldy #34
	lda #5
	jsr loop_vertical
	ldx #49
	ldy #39
	lda #5
	jsr loop_horizontal
	
	ldx #57
	ldy #36
	lda #2
	jsr loop_vertical
	ldx #58
	ldy #36
	lda #3
	jsr loop_vertical
	ldx #57
	ldy #39
	lda #1
	jsr loop_horizontal
	
	ldx #66
	ldy #33
	lda #4
	jsr loop_horizontal
	ldx #65
	ldy #34
	lda #2
	jsr loop_horizontal
	ldx #64
	ldy #35
	lda #4
	jsr loop_vertical
	ldx #65
	ldy #35
	lda #5
	jsr loop_vertical
	ldx #66
	ldy #39
	lda #3
	jsr loop_horizontal
	ldx #69
	ldy #36
	lda #4
	jsr loop_vertical
	ldx #70
	ldy #37
	lda #2
	jsr loop_vertical
	ldx #66
	ldy #36
	lda #3
	jsr loop_horizontal
	
	ldx #72
	ldy #33
	lda #6
	jsr loop_horizontal
	ldx #72
	ldy #34
	lda #2
	jsr loop_horizontal
	ldx #72
	ldy #35
	lda #5
	jsr loop_horizontal
	ldx #77
	ldy #35
	lda #5
	jsr loop_vertical
	ldx #78
	ldy #36
	lda #3
	jsr loop_vertical
	ldx #73
	ldy #39
	lda #4
	jsr loop_horizontal
	ldx #72
	ldy #38
	lda #2
	jsr loop_horizontal
	
	ldx #82
	ldy #33
	lda #3
	jsr loop_horizontal
	ldx #84
	ldy #34
	lda #1
	jsr loop_horizontal
	ldx #85
	ldy #34
	lda #5
	jsr loop_vertical
	ldx #86
	ldy #35
	lda #3
	jsr loop_vertical
	ldx #82
	ldy #39
	lda #3
	jsr loop_horizontal
	ldx #82
	ldy #38
	lda #1
	jsr draw
	ldx #81
	ldy #34
	lda #5
	jsr loop_vertical
	ldx #80
	ldy #35
	lda #3
	jsr loop_vertical
	
	ldx #88
	ldy #34
	lda #2
	jsr loop_horizontal
	ldx #89
	ldy #33
	lda #4
	jsr loop_horizontal
	ldx #93
	ldy #33
	lda #4
	jsr loop_vertical
	ldx #94
	ldy #34
	lda #2
	jsr loop_vertical
	ldx #92
	ldy #35
	jsr draw
	ldx #90
	ldy #36
	lda #3
	jsr loop_horizontal
	ldx #89
	ldy #37
	lda #3
	jsr loop_horizontal
	ldx #88
	ldy #38
	lda #3
	jsr loop_horizontal
	ldx #88
	ldy #39
	lda #7
	jsr loop_horizontal
	
	ldx #101
	ldy #33
	lda #2
	jsr loop_vertical
	ldx #100
	ldy #33
	lda #3
	jsr loop_vertical
	ldx #99
	ldy #33
	lda #4
	jsr loop_vertical
	ldx #98
	ldy #35
	lda #3
	jsr loop_vertical
	ldx #96
	ldy #39
	jsr draw
	
	brk

loop_vertical:
	sta it
	dec it
	loop_v_inner:
		jsr draw
		iny
		dec it
		bpl loop_v_inner
	rts

loop_horizontal:
	sta it
	dec it
	loop_h_inner:
		jsr draw
		inx
		dec it
		bpl loop_h_inner
	rts

draw:
	; store context
	sta prev_a
	stx prev_x
	sty prev_y
	
	jsr calculate_abs_coords
	
	lda #1  ; white
	ldx #0
	sta (coords, X)
	
	; load context
	lda prev_a
	ldx prev_x
	ldy prev_y
	
	rts

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
    lda #$02  ; dispay offset (0x0200)
    adc coords + 1
    sta coords + 1
    rts

	.org $FFFC
	.word draw_text
	.word $0000

