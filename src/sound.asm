
SOUND: {
	
	init: {
		lda #SUBTUNE_INTRO
		jsr music.init
		rts
	}

	Shoot:
		.import binary "../assets/Hallow-Shoot.bin"
	Explode:
		.import binary "../assets/Hallow-Explode.bin"
	Bonus:
		.import binary "../assets/Hallow-Bonus.bin"

	currChannelIndex:
		.byte $00
	channelList:
		.byte $00,$07,$0e
	getNextChannel: {
			ldx MusicActive
			beq !+
			ldx #$0e
			rts
		!:
			ldx currChannelIndex
			inx
			cpx #$03
			bne !+
			ldx #$00
		!:
			stx currChannelIndex
			pha
			lda channelList, x
			tax 
			pla 
			rts 
	}

	SFX_SHOOT: {
		lda #<Shoot
		ldy #>Shoot 
		jsr getNextChannel
		jmp music.init + 6
	}

	SFX_EXPLODE: {
		lda #<Explode
		ldy #>Explode 
		jsr getNextChannel
		jmp music.init + 6
	}

	SFX_BONUS: {
		lda #<Bonus
		ldy #>Bonus 
		jsr getNextChannel
		jmp music.init + 6
	}	
}