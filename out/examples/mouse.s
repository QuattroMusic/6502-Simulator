	.org $8000

mouse_x = $278b
mouse_y = $278c

coords      = $00  ; 2 bytes
temp_coords = $02  ; 2 bytes

loop:
	ldx mouse_x
	ldy mouse_y
	
	jsr calculate_abs_coords
	
	ldx #0
	lda #3
	sta (coords, x)
	
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
    
    asl coords
    rol coords + 1
    
    asl coords
    rol coords + 1
    
    asl coords
    rol coords + 1
    
    asl coords
    rol coords + 1
    
    asl coords
    rol coords + 1
    
    asl coords
    rol coords + 1
    
    asl coords
    rol coords + 1

    ; y2 = y << 3
    sty temp_coords
    
    asl temp_coords
    rol temp_coords + 1
    
    asl temp_coords
    rol temp_coords + 1
    
    asl temp_coords
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
	.word loop
	.word $0000
