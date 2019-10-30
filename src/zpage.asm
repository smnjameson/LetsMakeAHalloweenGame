* = $02 "Zeropage" virtual

TEMP1: .byte $00
TEMP2: .byte $00
TEMP3: .byte $00
TEMP4: .byte $00
TEMP5: .byte $00
TEMP6: .byte $00
TEMP7: .byte $00
TEMP8: .byte $00
TEMP9: .byte $00
TEMP10: .byte $00
TEMP11: .byte $00



ENEMYSCRX: .byte $00
ENEMYSCRY: .byte $00

SCORETOADD: .byte $00
SCOREVECTOR: .word $0000

VECTOR1: .word $0000

ZP_COUNTER: .byte $00
ZP_JOY2: .byte $00
ZP_GAMELOOP_FLAG: .byte $00

.label MAX_BULLETS = 8
BulletType:
	.fill MAX_BULLETS, 0
BulletX:
	.fill MAX_BULLETS, 0
BulletY:
	.fill MAX_BULLETS, 0
BulletIndex:
	.byte $00

MessageIndex:
	.word $0000

.label MAX_STARS = 16
STARS: .fill MAX_STARS * 2, 0
STARCOLS: .fill MAX_STARS * 2, 0
STARXY: .fill MAX_STARS* 2, 0