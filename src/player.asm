PLAYER: {
	.label UP = $01
	.label DN = $02
	.label LT = $04
	.label RT = $08
	.label FR = $10

	PlayerFrames:
		.byte 64,65,66
	__PlayerFrames:

	PlayerAnimIndex:
		.byte $00
	PlayerAnimTimer:
		.byte $00, $04

	PlayerX:	//Frac/LSB/MSB
		.byte $00, $00, $00
	PlayerY:	//Frac/LSB
		.byte $00, $00

	PlayerScreenX:
		.byte $00
	PlayerScreenY:
		.byte $00

	PlayerSpeedX:
		.byte $00,$02
	PlayerSpeedY:
		.byte $00,$02


	PlayerFireTimer:
		.byte $00, $0a

	PlayerDrawn:
		.byte $00

	PlayerPower:
		.byte $00
	PowerUpActive:
		.byte $00

	PlayerIsDead:
		.byte $00

	init: {
		//Global sprite setup
		lda #$fd
		sta $d015
		lda #$ff
		sta $d01c
		lda #$09
		sta $d025
		lda #$0d
		sta $d026

		//Just the witch now!
		lda #$02
		sta $d027

		lda PlayerFrames
		sta SPRITE_PTRS + 0
		
		lda #$80
		sta PlayerX + 1
		sta PlayerY + 1
		lda #$00
		sta PlayerX
		sta PlayerX + 2
		sta PlayerY

		lda #$00
		sta PlayerIsDead
		sta PlayerScreenX
		sta PlayerScreenY
		sta PlayerPower
		sta PowerUpActive

		lda #$08
		sta PlayerDrawn

		lda #$0a
		sta PlayerFireTimer
		sta PlayerFireTimer + 1
		rts
	}


	update: {
		//Animations
			dec PlayerAnimTimer
			bpl !Skip+
			lda PlayerAnimTimer + 1
			sta PlayerAnimTimer

			ldx PlayerAnimIndex
			inx
			cpx #[__PlayerFrames - PlayerFrames]
			bne !+
			ldx #$00
		!:
			stx PlayerAnimIndex
		!Skip:


		//Joystick control
			lda $dc00
			sta ZP_JOY2

		//Up
			lda ZP_JOY2
			and #UP
			bne !Skip+
			lda PlayerY + 1
			cmp #$34
			bcc !Skip+
			sec
			lda PlayerY
			sbc PlayerSpeedY
			sta PlayerY
			lda PlayerY + 1
			sbc PlayerSpeedY + 1
			sta PlayerY + 1
		!Skip:

		//Down
			lda ZP_JOY2
			and #DN
			bne !Skip+
			lda PlayerY + 1
			cmp #$de
			bcs !Skip+			
			clc
			lda PlayerY
			adc PlayerSpeedY
			sta PlayerY
			lda PlayerY + 1
			adc PlayerSpeedY + 1
			sta PlayerY + 1
		!Skip:

		//Left
			lda ZP_JOY2
			and #LT
			bne !Skip+
			lda PlayerX + 2
			bne !+
			lda PlayerX + 1
			cmp #$24
			bcc !Skip+
		!:
			sec
			lda PlayerX
			sbc PlayerSpeedX
			sta PlayerX
			lda PlayerX + 1
			sbc PlayerSpeedX + 1
			sta PlayerX + 1
			lda PlayerX + 2
			sbc #$00
			sta PlayerX + 2
		!Skip:

		//Right
			lda ZP_JOY2
			and #RT
			bne !Skip+
			lda PlayerX + 2
			beq !+
			lda PlayerX + 1
			cmp #$36
			bcs !Skip+
		!:
			clc
			lda PlayerX
			adc PlayerSpeedX
			sta PlayerX
			lda PlayerX + 1
			adc PlayerSpeedX + 1
			sta PlayerX + 1
			lda PlayerX + 2
			adc #$00
			sta PlayerX + 2
		!Skip:

		//Fire
			lda PlayerFireTimer
			beq !+
			dec PlayerFireTimer
			jmp !Skip+
		!:
			lda ZP_JOY2
			and #FR
			bne !Skip+
			lda PlayerFireTimer + 1
			sta PlayerFireTimer
			ldx PlayerScreenX
			inx
			inx
			inx
			ldy PlayerScreenY
			iny
			jsr BULLETS.add
			jsr SOUND.SFX_SHOOT
		!Skip:


		//Collision
			jsr getCollision
			rts
	}

	getCollision: {
			lda PlayerY + 1
			sec
			sbc #$34
			lsr
			lsr
			lsr
			bpl !+
			lda #$00
		!:
			cmp #$1a
			bcc !+
			lda #$00
		!:
			sta PlayerScreenY


			lda PlayerX + 1
			sec
			sbc #$1c
			sbc MAP.Hscroll
			sta TEMP1
			lda PlayerX + 2
			sbc #$00
			sta TEMP2


			lda TEMP2
			lsr 
			ror TEMP1
			lsr TEMP1
			lsr TEMP1
			lda TEMP1
			bpl !+
			lda #$00
		!:			
			cmp #39
			bcc !+
			lda #$00
		!:			
			sta PlayerScreenX

			ldx PlayerScreenY
			lda TABLES.ScreenRowLSB, x
			sta VECTOR1
			lda TABLES.ScreenRowMSB, x
			sta VECTOR1 + 1

			lda PlayerScreenX
			clc
			adc #41
			tay		
			lda (VECTOR1), y
			sta TEMP1
			iny
			lda (VECTOR1), y
			ora TEMP1
			sta TEMP1
			tya 
			adc #39
			tay
			lda (VECTOR1), y
			ora TEMP1
			sta TEMP1
			iny
			lda (VECTOR1), y
			ora TEMP1
			
			bpl !NoCollide+

		!Collide:
			lda #$01
			sta PlayerIsDead
			jsr SOUND.SFX_EXPLODE
			rts


		!NoCollide:
			//But maybe sprite collision??
			lda $d01e
			and #$01
			beq !+
			lda PlayerDrawn
			bne !+
			jmp !Collide-
		!:
			rts
	}




	draw: {
			lda PlayerY + 1
			sta $d001
			lda PlayerX + 1
			sta $d000

			lda $d010 
			and #$fe 
			ora PlayerX + 2
			sta $d010

			ldx PlayerAnimIndex
			lda PlayerFrames, x
			sta SPRITE_PTRS + 0

			lda PowerUpActive
			beq !+
			inc $d027
			jmp !Skip+
		!:
			lda #$02
			sta $d027
		!Skip:
			lda PlayerDrawn
			beq !+
			dec PlayerDrawn
		!:
			rts
	}

}