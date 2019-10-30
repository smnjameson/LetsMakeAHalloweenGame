HUD: {
	init: {
			ldx #$00
		!:
			lda HUDDATA, x
			sta SCREEN + 24 * 40, x
			lda HUDCOLORS, x
			sta COLORRAM + 24*40, x
			inx
			cpx #40
			bne !-
			rts
	}

	BCDtoDec:
		.fill 100, (floor(i/10) * $10) + mod(i,10)
		.fill 156, 99

	addScore: {
			//x = digit position
			//a = bcd value
			tay
			lda BCDtoDec, y

			sta SCORETOADD
			lda #<[SCREEN + 24 * 40 + 6]
			sta SCOREVECTOR
			lda #>[SCREEN + 24 * 40 + 6]
			sta SCOREVECTOR + 1

			stx TEMP4
			lda #$07
			sec
			sbc TEMP4
			tay

			clc
		!Loop:
			lda SCORETOADD
			and #$0f
			adc (SCOREVECTOR), y
			cmp #58
			bcc !+
			sbc #10
		!:
			sta (SCOREVECTOR), y 
			php //SAVE CARRY
			
			lda SCORETOADD
			lsr
			lsr
			lsr
			lsr
			sta SCORETOADD
			plp //RESTORE CARRY
			dey
			bpl !Loop-

			rts			

	}

	DisplayWaveNumber: {
			lda ENEMIES.CurrentWaveNumber
			sta TEMP8

			ldx #$30
		!:
			cmp #100
			bcc !Tens+
			inx
			sbc #100
			bcs !-

		!Tens:
			stx SCREEN + 24 * 40 + 36
			ldx #$30
		!:
			cmp #10
			bcc !Ones+
			inx
			sbc #10
			bcs !-

		!Ones:
			stx SCREEN + 24 * 40 + 37
			clc
			adc #$30
			sta SCREEN + 24 * 40 + 38

			rts
	}


	decPower: {
			ldx PLAYER.PlayerPower
			dex
			stx PLAYER.PlayerPower
			bne !+
			lda #$0a
			sta PLAYER.PlayerFireTimer + 1
			lda #$00
			sta PLAYER.PowerUpActive			
		!:		
			bne addPower.Draw
	}

	addPower: {
			ldx PLAYER.PlayerPower
			inx
			stx PLAYER.PlayerPower
			cpx #36
			bcc !+
		!DoPOWER:
			ldx #36
			stx PLAYER.PlayerPower
			lda #$01
			sta PLAYER.PowerUpActive
			lda #$05
			sta PLAYER.PlayerFireTimer + 1

		!:
		Draw:
			ldy #$00
			lda PLAYER.PlayerPower
		!Loop:
			sta TEMP10
			cmp #$00
			bmi !Blank+
			cmp #$04
			bcs !Full+
			// 
		!Part:
			cmp #$00
			beq !Blank+
			clc
			adc #26
			sta SCREEN + 24 * 40 + 21, y
			bne !Skip+
		!Blank:	
			lda #$00
			sta TEMP10
			sta SCREEN + 24 * 40 + 21, y
			beq !Skip+
		!Full:

			lda #30
			sta SCREEN + 24 * 40 + 21, y

		!Skip:
			lda #$05
			ldx PLAYER.PowerUpActive
			beq !+

			lda ZP_COUNTER
			lsr
			lsr
			and #$07
			tax
			lda GameOverColRamp, x
		!:
			sta COLORRAM + 24 * 40 + 21, y


			lda TEMP10
			sec
			sbc #$04
			iny
			cpy #$09
			bne !Loop-

			rts

	}
}