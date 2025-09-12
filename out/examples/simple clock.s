	.org $8000

control = $2780
year_lo = $2781
year_hi = $2782
month   = $2783
day     = $2784
hour    = $2785
minute  = $2786
seconds = $2787

time_unlock = $00
time_lock   = $01
time_ready  = $02

; high values to not pollute zero page
value = $2790  ; 2 bytes
mod10 = $2792  ; 2 bytes
pos   = $2794
temp  = $2795

loop:
	; this program reads the time from the clock
	; and display it in decimal in the ram.

	; the second bit in the control registry means
	; that the time is set.
time_is_not_set_yet:
	lda control
	and #time_ready
	beq time_is_not_set_yet
	
	; the first bit in the control registry means
	; that the time is locked and values could be read
	; safely.
	lda #time_lock
	sta control

	lda year_lo
	ldx year_hi
	ldy #1
	jsr draw_number  ; draw yer
	
	lda month
	ldx #0
	ldy #2
	jsr draw_number  ; draw month
	
	lda day
	ldx #0
	ldy #3
	jsr draw_number  ; draw day
	
	lda hour
	ldx #0
	ldy #5
	jsr draw_number  ; draw hour
	
	lda minute
	ldx #0
	ldy #6
	jsr draw_number  ; draw minute
	
	lda seconds
	ldx #0
	ldy #7
	jsr draw_number  ; draw seconds
	
	; unlock time and wait for it to be updated
	lda #time_unlock
	sta control
	
	jmp loop

draw_number: ; a, x is value, y is position
	sta value
	stx value + 1
	sty pos
draw_number_inner:
	; get two chars in one byte
	jsr get_single_char
	sta temp
	jsr get_single_char
	asl
	asl
	asl
	asl
	ora temp
	ldx pos
	sta 0, x
	
	lda value
	ora value + 1
	beq exit_draw  ; if the draw is complete, exit
	
	; write next char
	dec pos
	jmp draw_number_inner
	
	brk
	
exit_draw:
	rts

get_single_char:  ; kudos for ben eater and his 6502 serie
	lda #0
	sta mod10
	sta mod10 + 1
	
	clc
	ldx #16
divloop:
	; rotate quotient
	rol value
	rol value + 1
	rol mod10
	rol mod10 + 1
	
	; a, y = dividend - divisor
	sec
	lda mod10
	sbc #10
	tay
	lda mod10 + 1
	sbc #0
	bcc ignore_result ; branch if dividend < divisor
	sty mod10
	sta mod10 + 1
ignore_result:
	dex
	bne divloop
	rol value  ; shift in the last bit of the quotient
	rol value + 1
	
	lda mod10

	rts

	.org $fffc
	.word loop
	.word $0000
