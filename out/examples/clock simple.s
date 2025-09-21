	.org $8000

loop_enabled = 1  ; zero to disable

time_unlock = $0
time_lock   = $1
time_ready  = $2

control  = $2780
year_lo  = $2781
year_hi  = $2782
month    = $2783
day      = $2784
hour     = $2785
minute   = $2786
seconds  = $2787
milli_lo = $2788
milli_hi = $2789

init:
	; this is a simple program to
	; demonstrate how to use the time api
	
	; start by locking the data,
	; so we can safe-copy it
	lda #time_lock
	sta control
	
	; copy all data
	lda year_lo
	sta 0
	lda year_hi
	sta 1
	lda month
	sta 2
	lda day
	sta 3
	lda hour
	sta 4
	lda minute
	sta 5
	lda seconds
	sta 6
	lda milli_lo
	sta 7
	lda milli_hi
	sta 8

	; unlock
	lda #time_unlock
	sta control
	
	; if the loop is disabled,
	; stop execution
	cmp #loop_enabled
	beq stop_execution
	
	; if we want to loop over
wait_time:
	lda control

	; we could also do "and $02"
	cmp #time_ready
	bne wait_time
	jmp init

stop_execution:
	brk
	

	.org $fffc
	.word init
	.word $0000
