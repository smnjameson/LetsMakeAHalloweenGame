ENEMIES: {
	.label MAX_ENEMIES = 6

	EnemyX0:
		.fill MAX_ENEMIES, 0
	EnemyX1:
		.fill MAX_ENEMIES, 0
	EnemyX2:
		.fill MAX_ENEMIES, 0
	EnemyY0:
		.fill MAX_ENEMIES, 0
	EnemyY1:
		.fill MAX_ENEMIES, 0
	EnemyActive:
		.fill MAX_ENEMIES, 0
	EnemyAnimIndex:
		.fill MAX_ENEMIES, 0
	EnemyDying:
		.fill MAX_ENEMIES, 0
	EnemyDeathIndex:
		.fill MAX_ENEMIES, 0
	EnemyDeathFrame:
		.fill MAX_ENEMIES, 0

	CurrentEnemyType:
		.byte $00
	CurrentWaveType:
		.byte $00
		*=*"EnemyCount"
	CurrentEnemyCount:
		.byte $00
	CurrentEnemyKillCount:
		.byte $00

	CurrentWaveNumber:
		.byte $00

	EnemyFrame:
		.byte $00
	EnemyFrameIndex: 
		.byte $00
	EnemyAnimationTimer:
		.byte $00, $03

	DeathFrames:
		.byte 68,69,70,71,67
	EnemyStartFrames:
		.byte 72,88,96,112,120,128
	EnemyFrameCount:
		.byte 10,6,4,4,4,4
	EnemyColors:
		.byte 8,14,1,5,1,4

	SectorTransition:
		.byte $00

	init: {
		lda #$00
		sta CurrentEnemyCount
		lda #$00
		sta CurrentWaveNumber

		lda #$00
		ldx #$00
	!:
		sta EnemyX0, x
		inx
		cpx #[MAX_ENEMIES * 10]
		bne !-

		lda #$20
		sta SectorTransition
		rts
	}

	addWave: {
			lda SectorTransition
			beq !Skip+
			cmp #40
			bcs !Skip+
			rts
		!:

		!Skip:
			lda #$00
			sta SectorTransition
			inc CurrentWaveNumber
			jsr HUD.DisplayWaveNumber

			//Difficulty ramp
			lda CurrentWaveNumber
			lsr
			lsr
			lsr
			cmp #13
			bcc !+
			lda #13
		!:
			sta TEMP9
			lda #$11
			sec
			sbc TEMP9
			sta MAP.MinGap

			lda CurrentWaveNumber
			lsr
			lsr
			clc
			adc #$01
			cmp #7
			bcc !+
			lda #7
		!:
			sta MAP.HscrollSpeed


			lda #$00
			sta EnemyFrameIndex

			lda #MAX_ENEMIES
			sta CurrentEnemyCount
			lda #$00
			sta CurrentEnemyKillCount
		!:
			jsr Random.get
			and #$07
			cmp #$06
			bcs !-
			sta CurrentEnemyType

		!:
			jsr Random.get
			and #$07
			clc
			adc #$01
			sta CurrentWaveType
			ldy #INIT
			jsr DoWaveAction 

			
			ldx #$00
		!:
			lda #$01
			sta EnemyActive, x
			lda #$00
			sta EnemyDying, x
			sta EnemyDeathIndex, x
			inx
			cpx #MAX_ENEMIES
			bne !-

			rts
	}


	update: {	
			//Frame updates
			dec EnemyAnimationTimer
			bpl !+
			lda EnemyAnimationTimer + 1
			sta EnemyAnimationTimer

			ldy CurrentEnemyType
			ldx EnemyFrameIndex
			inx
			txa
			cmp EnemyFrameCount, y
			bne !ApplyFrame+
			lda #$00
		!ApplyFrame:
			sta EnemyFrameIndex	
			clc
			adc EnemyStartFrames, y
			sta EnemyFrame
		!:



			ldx #MAX_ENEMIES - 1
		!:
			lda EnemyActive, x
			beq !Skip+

			//Death anim?
			lda EnemyDying, x
			beq !NotDying+

			ldy EnemyDeathIndex, x
			lda DeathFrames, y

			sta EnemyDeathFrame, x
			iny
			cpy #$05
			bne !Apply+
			ldy #$04
			lda #$00
			sta EnemyActive, x
			dec CurrentEnemyCount
		!Apply:
			tya
			sta EnemyDeathIndex, x

			jmp !Skip+

		!NotDying:
			//Position Update
			sec
			lda EnemyX1, x
			sbc #$02 //Maybe HScroll?
			sta EnemyX1, x
			lda EnemyX2, x
			sbc #$00
			sta EnemyX2, x
			beq !Skip+
			//Are we offscreen??
			lda EnemyX1, x
			cmp #$f0
			bcc !Skip+
			lda #$00
			sta EnemyActive, x
			dec CurrentEnemyCount
		!Skip:
			dex
			bpl !-

			lda CurrentWaveType
			beq !NoWaveAction+
			ldy #UPDATE
			jsr DoWaveAction 

		!NoWaveAction:
			lda CurrentEnemyCount
			bmi !EndWave+
			bne !+
		!EndWave:

			lda SectorTransition
			bne !+
			lda CurrentWaveNumber
			and #$0f
			cmp #$08
			bne !Skp+
			inc SectorTransition
			rts
		!Skp:

			jsr ENEMIES.addWave
		!:		
			rts
	}



	draw: {
			ldx #$00
			ldy #$00
		!:
			lda EnemyActive, x
			bne !DoDraw+
			lda #$00
			sta $d000 + 4, y
			sta $d001 + 4, y
			jmp !EndLoop+	

		!DoDraw:
			lda EnemyDying, x
			beq !Normal+
			lda EnemyDeathFrame, x
			bne !Set+
		!Normal:
			lda EnemyFrame
		!Set:
			sta SPRITE_PTRS + 2, x
			


			lda EnemyX1, x
			sta $d000 + 4, y
			lda EnemyY1, x
			sta $d001 + 4, y

			sty TEMP3

			ldy CurrentEnemyType
			lda EnemyColors, y
			sta $d027 + 2, x

			lda $d010 
			and TABLES.InvPOT + 2, x
			ldy EnemyX2, x
			beq !Skip+
			ora TABLES.POT + 2, x
		!Skip:
			sta $d010	
			ldy TEMP3

			jsr CheckVsBullets

		!EndLoop:
			iny
			iny
			inx
			cpx #$06
			bne !-	


			rts
	}

	CheckVsBullets: {
			lda EnemyDying, x
			beq !+
			rts
		!:
			tya
			pha 

			lda EnemyY1, x
			sec
			sbc #$32
			lsr
			lsr
			lsr
			sta ENEMYSCRY

			lda EnemyX1, x
			sec
			sbc #$18
			// sbc MAP.Hscroll
			sta ENEMYSCRX
			lda EnemyX2, x
			sbc #$00
			sta TEMP6

			lda TEMP6
			lsr 
			ror ENEMYSCRX
			lsr ENEMYSCRX
			lsr ENEMYSCRX


			ldy #$00
		!Loop:
			lda BulletType, y
			beq !Skip+

			lda BulletY, y 
			sec
			sbc ENEMYSCRY
			bmi !Skip+
			cmp #$03
			bcs !Skip+

			lda BulletX, y
			sec
			sbc ENEMYSCRX
			bmi !Skip+
			cmp #$03
			bcs !Skip+

				lda #$ff
				sta BulletType, y
				lda #$01
				sta EnemyDying, x
				lda #$00
				sta EnemyDeathIndex
				txa
				pha
				tya
				pha
					jsr SOUND.SFX_EXPLODE
					lda CurrentWaveNumber
					lsr
					lsr
					clc
					adc #$01
					ldx #$00
					jsr HUD.addScore

					jsr HUD.addPower

					ldx CurrentEnemyKillCount
					inx
					stx CurrentEnemyKillCount
					cpx #MAX_ENEMIES
					bne !+
					
					jsr SOUND.SFX_BONUS
					lda CurrentWaveNumber
					lsr
					lsr
					clc
					adc #$01
					ldx #$01
					jsr HUD.addScore
				!:

				pla
				tay
				pla
				tax
		!Skip:
			iny
			cpy #MAX_BULLETS
			bne !Loop-

			pla
			tay
			rts
	}


	DoWaveAction: {
			//A = wave type
			//Y = action
			sty TEMP2

			asl
			tay
			dey
			dey

			clc
			lda WaveTable, y
			adc TEMP2
			sta SelfMod + 1
			lda WaveTable + 1, y
			adc #$00
			sta SelfMod + 2
		SelfMod:
			jmp $BEEF
	}

	
	WaveTable:

		.word WAVE_001
		.word WAVE_002
		.word WAVE_003
		.word WAVE_004
		.word WAVE_005
		.word WAVE_006
		.word WAVE_007
		.word WAVE_008



	.label INIT = $00
	.label UPDATE = $03

	WAVE_001: {
		jmp init
		jmp update
		StartX:
			.fill MAX_ENEMIES, $60 + i * $10
		StartY:
			.fill MAX_ENEMIES, $38 + i * $18

		SinTicker:
			.byte $00	
		SinY:
			.fill 256, sin((i/256) * (PI*2)) * 80 + 88 + 50

		init: {
				ldx #$00
			!:
				lda StartX, x
				sta EnemyX1, x
				lda StartY, x
				sta EnemyY1, x
				lda #$01
				sta EnemyX2, x
				inx
				cpx #$06
				bne !-	
				rts
		}


		update: {
				inc SinTicker

				ldx #$00
			!:
				lda EnemyDying, x
				bne !Skip+
				txa 
				asl 
				asl 
				asl 
				asl
				clc
				adc SinTicker
				tay
				lda SinY, y
				sta EnemyY1, x
			!Skip:
				inx
				cpx #$06
				bne !-
				rts
		}
	}


	WAVE_002: {
		jmp init
		jmp update
		StartX:
			.fill MAX_ENEMIES, $60 + i * $10
		StartY:
			.fill MAX_ENEMIES, $38 + i * $18
		SinTicker:
			.byte $00	
		SinY:
			.fill 256, sin((i/256) * (PI*2)) * 80 + 88 + 50
		init: {
				ldx #$00
			!:
				lda StartX, x
				sta EnemyX1, x
				lda StartY, x
				sta EnemyY1, x
				lda #$01
				sta EnemyX2, x
				inx
				cpx #$06
				bne !-	
				rts
		}

		update: {
				inc SinTicker

				ldx #$00
			!:
				lda EnemyDying, x
				bne !Skip+
				txa 
				ror
				ror
				ror

				clc
				adc SinTicker
				tay
				lda SinY, y
				sta EnemyY1, x
			!Skip:
				inx
				cpx #$06
				bne !-
				rts
		}
	}


	WAVE_003: {
		jmp init
		jmp update
		StartX:
			.fill MAX_ENEMIES, $60 + i * $10
		StartY:
			.fill MAX_ENEMIES, $38 + i * $18
		SinTicker:
			.byte $00	
		SinY:
			.fill 256, sin((i/256) * (PI*2)) * 80 + 88 + 50
		SinX:
			.fill 256, (cos(((i-1)/128) * (PI*2)) * 64 + 32) - (cos((i/128) * (PI*2)) * 64 + 32)

		init: {
				ldx #$00
			!:
				lda StartX, x
				sta EnemyX1, x
				lda StartY, x
				sta EnemyY1, x
				lda #$01
				sta EnemyX2, x
				inx
				cpx #$06
				bne !-	
				rts
		}

		update: {
				inc SinTicker

				ldx #$00
			!:
				lda EnemyDying, x
				bne !Skip+
				txa 
				asl 
				asl 
				asl 
				asl

				clc
				adc SinTicker
				tay
				lda SinY, y
				sta EnemyY1, x

				lda SinX, y	
				bpl !Add+
			!Sub:
				dec EnemyX2, x
			!Add:
				clc
				lda EnemyX1, x
				adc SinX, y
				sta EnemyX1, x
				lda EnemyX2, x
				adc #$00
				sta EnemyX2, x

			!Skip:
				inx
				cpx #$06
				bne !-
				rts
		}
	}

	WAVE_004: {
		jmp init
		jmp update
		StartX:
			.fill MAX_ENEMIES, $60 + i * $10
		StartY:
			.fill MAX_ENEMIES, $38 + i * $18
		SinTicker:
			.byte $00	
		SinY:
			.fill 256, sin((i/128) * (PI*2)) * 80 + 88 + 50
		SinX:
			.fill 256, (cos(((i-1)/64) * (PI*2)) * 64 + 64) - (cos((i/64) * (PI*2)) * 64 + 64)

		init: {
				ldx #$00
			!:
				lda StartX, x
				sta EnemyX1, x
				lda StartY, x
				sta EnemyY1, x
				lda #$01
				sta EnemyX2, x
				inx
				cpx #$06
				bne !-	
				rts
		}

		update: {
				inc SinTicker

				ldx #$00
			!:
				lda EnemyDying, x
				bne !Skip+
				txa 
				asl 
				asl 
				asl 
				

				clc
				adc SinTicker
				tay
				lda SinY, y
				sta EnemyY1, x

				lda SinX, y	
				bpl !Add+
			!Sub:
				dec EnemyX2, x
			!Add:
				clc
				lda EnemyX1, x
				adc SinX, y
				sta EnemyX1, x
				lda EnemyX2, x
				adc #$00
				sta EnemyX2, x

			!Skip:
				inx
				cpx #$06
				bne !-
				rts
		}
	}


	WAVE_005: {
		jmp init
		jmp update
		StartX:
			.fill MAX_ENEMIES, $60 + i * $10
		StartY:
			.fill MAX_ENEMIES, $38 + i * $18
		SinTicker:
			.byte $00	
		SinY:
			.fill 256, sin((i/128) * (PI*2) * 0.5) * 80 + 88 + 50
		SinX:
			.fill 256, ((cos(((i-1)/64) * (PI*2)) * 64 + 64) - (cos((i/64) * (PI*2)) * 64 + 64))/2

		init: {
				ldx #$00
			!:
				lda StartX, x
				sta EnemyX1, x
				lda StartY, x
				sta EnemyY1, x
				lda #$01
				sta EnemyX2, x
				inx
				cpx #$06
				bne !-	
				rts
		}

		update: {
				inc SinTicker

				ldx #$00
			!:
				lda EnemyDying, x
				bne !Skip+
				txa 
				asl 
				asl 
				asl 
				

				clc
				adc SinTicker
				tay
				lda SinY, y
				sta EnemyY1, x

				lda SinX, y	
				bpl !Add+
			!Sub:
				dec EnemyX2, x
			!Add:
				clc
				lda EnemyX1, x
				adc SinX, y
				sta EnemyX1, x
				lda EnemyX2, x
				adc #$00
				sta EnemyX2, x

			!Skip:
				inx
				cpx #$06
				bne !-
				rts
		}
	}


	WAVE_006: {
		jmp init
		jmp update
		StartX:
			.fill MAX_ENEMIES, $50
		SinTicker:
			.byte $00	
		SinX:
			.fill 256, ((cos(((i-1)/128) * (PI*2)) * 96 + 32) - (cos((i/128) * (PI*2)) * 96 + 32)) 

		init: {
				ldx #$00
			!:
				jsr Random.get
				and #$7f
				adc StartX, x
				sta EnemyX1, x

				jsr Random.get
				and #$7f
				adc #$40
				sta EnemyY1, x
				lda #$01
				sta EnemyX2, x
				inx
				cpx #$06
				bne !-	
				rts
		}

		update: {
				inc SinTicker

				ldx #$00
			!:
				lda EnemyDying, x
				bne !Skip+
	
				txa 
				asl 
				asl 
				asl 
				asl
				clc
				adc SinTicker
				tay

				lda SinX, y	
				bpl !Add+
			!Sub:
				dec EnemyX2, x
			!Add:
				clc
				lda EnemyX1, x
				adc SinX, y
				sta EnemyX1, x
				lda EnemyX2, x
				adc #$00
				sta EnemyX2, x

			!Skip:
				inx
				cpx #$06
				bne !-
				rts
		}
	}


	WAVE_007: {
		jmp init
		jmp update

		SinTicker:
			.byte $00	
		SinY:
			.fill 256, sin((i/256) * (PI*2)) * 80 + 88 + 50

		init: {
				ldx #$00
			!:
				jsr Random.get
				and #$7f
				adc #$50
				sta EnemyX1, x

				jsr Random.get
				and #$7f
				adc #$40
				sta EnemyY1, x
				lda #$01
				sta EnemyX2, x
				inx
				cpx #$06
				bne !-	
				rts
		}


		update: {
				inc SinTicker

				ldx #$00
			!:
				lda EnemyDying, x
				bne !Skip+
				txa 
				asl 
				asl 
				asl 
				asl
				clc
				adc SinTicker
				tay
				lda SinY, y
				sta EnemyY1, x

				sec
				lda EnemyX1, x
				sbc #$02
				sta EnemyX1, x
				lda EnemyX2, x
				sbc #$00
				sta EnemyX2, x

			!Skip:
				inx
				cpx #$06
				bne !-
				rts
		}
	}
	WAVE_008: {
		jmp init
		jmp update

		SinTicker:
			.byte $00	
		SinY:
			.fill 256, sin((i/128) * (PI*2)) * 80 + 88 + 50
		SinX:
			.fill 256, (cos(((i-1)/64) * (PI*2)) * 64 + 64) - (cos((i/64) * (PI*2)) * 64 + 64)

		init: {
				ldx #$00
			!:
				jsr Random.get
				and #$7f
				adc #$50
				sta EnemyX1, x

				jsr Random.get
				and #$7f
				adc #$40
				sta EnemyY1, x
				lda #$01
				sta EnemyX2, x
				inx
				cpx #$06
				bne !-	
				rts
		}

		update: {
				inc SinTicker

				ldx #$00
			!:
				lda EnemyDying, x
				bne !Skip+
				txa 
				asl 
				asl 
				asl 
				

				clc
				adc SinTicker
				tay
				lda SinY, y
				sta EnemyY1, x

				lda SinX, y	
				bpl !Add+
			!Sub:
				dec EnemyX2, x
			!Add:
				clc
				lda EnemyX1, x
				adc SinX, y
				sta EnemyX1, x
				lda EnemyX2, x
				adc #$00
				sta EnemyX2, x

			!Skip:
				inx
				cpx #$06
				bne !-
				rts
		}
	}
}
