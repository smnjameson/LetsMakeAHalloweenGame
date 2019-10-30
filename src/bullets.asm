BULLETS: {


	init: {
			lda #$00
			sta BulletIndex
			ldx #MAX_BULLETS - 1
		!:
			sta BulletType, x
			sta BulletX, x
			sta BulletY, x
			dex
			bpl !-
			rts
	}

	add: {
			txa
			ldx BulletIndex
			sta BulletX, x
			tya
			sta BulletY, x
			lda #$01
			sta BulletType, x

			inx
			cpx #MAX_BULLETS	
			bne !+
			ldx #$00
		!:
			stx BulletIndex	

			rts
	}

	//clear - MAPSHIFT - update - draw

	update: {
			ldx #MAX_BULLETS - 1
		!Loop:
			lda BulletType, x
			beq !Skip+

			ldy BulletX, x
			iny
			cpy #40
			bcc !+
			lda #$00
			sta BulletType, x
			beq !Skip+
		!:
			tya
			sta BulletX, x

		!Skip:
			dex
			bpl !Loop-
			rts			
	}

	clear: {
			ldx #MAX_BULLETS - 1
		!:
			lda BulletType, x
			beq !Skip+
			
			ldy BulletY, x
			lda TABLES.ScreenRowLSB, y 
			sta VECTOR1
			lda TABLES.ScreenRowMSB, y 
			sta VECTOR1 + 1

			ldy BulletX, x
			lda #$00
			sta (VECTOR1), y

		!Skip:
			dex
			bpl !-
			rts
	}


	draw: {
			stx SelfMod

			ldx #MAX_BULLETS - 1
		!:
			ldy BulletY, x
			cpy #12
		SelfMod:
			bcc !Skip+

			lda BulletType, x
			beq !Skip+
			bmi !Remove+

			lda TABLES.ScreenRowLSB, y 
			sta VECTOR1
			lda TABLES.ScreenRowMSB, y 
			sta VECTOR1 + 1

			ldy BulletX, x
			
			
			lda (VECTOR1), y
			bpl !Draw+
		!Remove:
			lda #$00
			sta BulletType,x
			beq !Skip+
		!Draw:
			lda #59
			sta (VECTOR1), y

		!Skip:
			dex
			bpl !-
			rts
	}
}