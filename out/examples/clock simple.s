	.org $8000

init:
	brk

	.org $fffc
	.word init
	.word $0000
