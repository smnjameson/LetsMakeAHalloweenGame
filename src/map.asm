MAP: {
	Hscroll:
		.byte $07
	HscrollSpeed:
		.byte $01
	MapCols:
		.byte $00

	init: {
			//Enable MC
			lda $d016
			ora #$10
			sta $d016

			//Set MC cols
			lda #$ff
			sta MapCols
			jsr ChangeMapColors


			lda #$00
			jsr ClearScreen

			lda #$0d
			jsr ClearColor

			lda #$01
			ldx #$00
		!:
			sta SCREEN + 24 * 40, x
			inx
			cpx #40
			bne !-

			lda #$01
			sta HscrollSpeed

			lda #$10
			sta MinGap

			lda #$00
			sta CeilHeight
			sta PrevCeilHeight
			sta FloorHeight
			lda #$00
			sta FloorDir
			sta CeilDir

			lda #$02
			sta MinHeight
			rts
	}

.align $100
*=*"Mapstats"
	CeilHeight:
		.byte $01
	PrevCeilHeight:
		.byte $01
	CeilDir:
		.byte $00
	DecorateType:
		.byte $00
	decorateTypeChars:
		.byte $00,$00,141,142
	FloorHeight:
		.byte $01
	FloorDir:
		.byte $00
	DirRandom:
		.byte $c0
	MinGap:
		.byte $10
	MinHeight:
		.byte $02

	DummyBytes:
		.fill 4, 0
	ColData:
		.fill 24, 0	
	DummyBytes2:
		.fill 4, 0

	GrassTop:
		.byte 130,129,128
	CeilTop:
		.byte 131,132,133
	HoleData:
		.byte 137,138,139,140
		.fill 12, 135
		.fill 16, 135

	GenerateColumn: {

		ldx #$02
		stx MinHeight
		lda ENEMIES.SectorTransition
		beq !Skip+



		ldx #$00
		stx MinHeight
		// cmp #$02
		// bcs !EndTransitionFadeOut+

		lda CeilHeight
		beq !NoCeil+
		ldy #$ff
		dec CeilHeight
		bpl !+
		lda #$00
		sta CeilHeight
	!:
		bne !NoFlatCeil+
		ldy #$00
	!NoFlatCeil:		
		sty CeilDir
	!NoCeil:

		lda FloorHeight
		beq !NoFloor+
		ldy #$ff
		dec FloorHeight
		bpl !+
		lda #$00
		sta FloorHeight
	!:		
		bne !NoFlatFloor+
		ldy #$00
	!NoFlatFloor:		
		sty FloorDir
	!NoFloor:
	!:


	!EndTransitionFadeOut:
		lda FloorHeight
		clc
		adc CeilHeight
		bne !+
		inc ENEMIES.SectorTransition
		lda ENEMIES.SectorTransition
		cmp #40
		bcc !+
		jsr ChangeMapColors
		jsr ENEMIES.addWave
		// // 
		jmp !Skip+
	!:

		jmp !NotRandomChange+



	!Skip:
	//Ceiling

		jsr Random.get
		cmp DirRandom
		bcc !NoChange+
		jsr Random.get
		bmi !Neg+
	!Pos:
		lda CeilDir
		cmp #$01
		beq !Skip+
		inc CeilDir
		jmp !Skip+
	!Neg:
		lda CeilDir
		cmp #$ff
		beq !Skip+
		dec CeilDir
	!Skip:
		lda CeilDir
		cmp #$01
		bne !+
		lda #23
		sec
		sbc CeilHeight
		sbc FloorHeight
		cmp MinGap
		bcs !+
		lda #$00
		sta CeilDir
		jmp !NoChange+
	!:

		lda CeilHeight
		clc
		adc CeilDir
		sta CeilHeight
		cmp MinHeight
		bpl !+
		lda #$00
		sta CeilDir
		lda MinHeight
		sta CeilHeight
	!:
	!NoChange:




	//Floor
		jsr Random.get
		cmp DirRandom
		bcc !Skip+
		jsr Random.get
		bmi !Neg+
	!Pos:
		lda FloorDir
		cmp #$01
		beq !Skip+
		inc FloorDir
		jmp !Skip+
	!Neg:
		lda FloorDir
		cmp #$ff
		beq !Skip+
		dec FloorDir
		jmp !Skip+
	!Skip:
		lda FloorDir
		cmp #$01
		bne !+
		lda #23
		sec
		sbc CeilHeight
		sbc FloorHeight
		cmp MinGap
		bcs !+
		lda #$00
		sta FloorDir
		jmp !NoChange+
	!:

		lda FloorHeight
		clc
		adc FloorDir
		sta FloorHeight
		cmp MinHeight
		bpl !+

		lda #$00
		sta FloorDir
		lda MinHeight
		sta FloorHeight
	!:
	!NoChange:	


	!NotRandomChange:


		//Clear column
			ldx #23
			lda #$0
		!:
			sta ColData, x
			dex
			bpl !-

		//Apply ceil
			ldx CeilHeight
			stx TEMP9
			// jmp !Startloop+
		!:
			dex
			bmi !Skip+
		CharMod1:
			lda #135
			sta ColData, x
			jmp !-
		!Skip:
			lda #132
			ldx CeilHeight
			dex
			sta ColData, x



		//Apply floor
			lda #<ColData
			clc
			adc #24
			sec
			sbc FloorHeight

			ldx FloorDir
			cpx #$ff
			bne !+
			sec
			sbc #$01
		!:
			sta SelfMod + 1
			sta DecorateMod + 1

		//Reset char
			lda #135
			sta CharMod + 1

			//Draw Floor
			ldx FloorHeight
			lda FloorDir
			cmp #$ff
			bne !+
			inx
			stx TEMP9
		!:
			jmp !Startloop+
		!:
			dex
			bmi !Skip+
		CharMod:
			lda #135
		SelfMod:
			sta ColData, x


		!Startloop:	
			cpx #$01
			bne !NoCharChange+
			ldy FloorDir
			cpy #$01
			bne !FlatMaybe+
			lda GrassTop + 2
			bne !Set+
		!FlatMaybe:
			cpy #$ff
			bne !Flat+
			lda GrassTop + 0
			bne !Set+
		!Flat:
			lda #129
		!Set:
			sta CharMod + 1

		!NoCharChange:
			jmp !-
		!Skip:



		//Decorate floor
			lda DecorateType
			cmp #$03
			beq !Change+

			jsr Random.get
			cmp #$80
			bcc !+
		!Change:
			jsr Random.get
			and #$03
			sta DecorateType
		!:
			ldx #$00
			dec DecorateMod + 1
			lda FloorHeight
			beq !NoDecorate+
			lda FloorDir
			bne !NoDecorate+
			ldy DecorateType
			lda decorateTypeChars, y
		DecorateMod:
			sta ColData, x
		!NoDecorate:



		//Fix ceiling
			ldx CeilHeight
			lda PrevCeilHeight
			cmp CeilHeight
			beq !CeilingDone+
			bmi !GoingUp+
		!GoingDown:
			lda CeilTop + 2
			sta ColData, x
			bne !CeilingDone+
		!GoingUp:
			dex
			lda CeilTop + 0
			sta ColData, x

		!CeilingDone:
			lda CeilHeight
			sta PrevCeilHeight


		//Add random holes and fix the floor slopes
			ldx #$00
		!Loop:
			lda ColData, x
			cmp #128
			beq !ApplyFix+
			cmp #130
			beq !ApplyFix+
			bne !+
		!ApplyFix:
			clc
			adc #6
			sta ColData + 1, x
			bne !Skip+
		!:
			cmp #135
			bne !Skip+
			jsr Random.get
			bmi !Skip+
			and #$1f
			tay
			lda HoleData, y
			sta ColData, x
		!Skip:
			inx
			cpx #24
			bne !Loop-

			rts
	}


	AdvanceMap: {
			lda #$00
			sta NeedToShift

			lda Hscroll
			sec
			sbc HscrollSpeed
			sta Hscroll

			// and #$07
			// ora #$d0
			// sta $d016

			lda Hscroll
			bpl !+
			
			and #$07
			sta Hscroll
			jsr GenerateColumn

			inc NeedToShift
		!:
			rts
	}

	NeedToShift: 
		.byte $00

	ScreenShift: {
		lda NeedToShift
		bne !+
		rts
	!:

		lda IntroActive
		beq !+
		jmp !NoIntro+
	!:


	cpx #$00
	beq First
	jmp Second
	First:
		.for(var row=0;row<12;row++) {
			.for(var col=1;col<40;col++) {
				lda SCREEN + row * 40 + col
				sta SCREEN + row * 40 + col - 1
			}
			lda ColData + row
			sta SCREEN + row * 40 + 39
		}
		rts
	Second:
		.for(var row=12;row<24;row++) {
			.for(var col=1;col<40;col++) {
				lda SCREEN + row * 40 + col
				sta SCREEN + row * 40 + col - 1
			}
			lda ColData + row
			sta SCREEN + row * 40 + 39
		}
		rts

	!NoIntro:
		.for(var row=2;row<6;row++) {
			.for(var col=1;col<40;col++) {
				lda SCREEN + row * 40 + col
				sta SCREEN + row * 40 + col - 1
			}
			lda ColData + row
			sta SCREEN + row * 40 + 39
		}
		.for(var row=16;row<23;row++) {
			.for(var col=1;col<40;col++) {
				lda SCREEN + row * 40 + col
				sta SCREEN + row * 40 + col - 1
			}
			lda ColData + row
			sta SCREEN + row * 40 + 39
		}

		.for(var col=1;col<40;col++) {
			lda SCREEN + 24 * 40 + col
			sta SCREEN + 24 * 40 + col - 1
		}	



		ldy #$00
		lda (MessageIndex), y
		cmp #$ff
		bne !+
		lda #<MessageText
		sta MessageIndex
		lda #>MessageText
		sta MessageIndex + 1
		lda #$00
		sta SCREEN + 24 * 40 + 39
		rts
	!:
		sta SCREEN + 24 * 40 + 39
		clc
		lda MessageIndex
		adc #$01
		sta MessageIndex
		lda MessageIndex + 1
		adc #$00
		sta MessageIndex + 1

		rts		
	}


	MapColors:
		.byte $0b,$06,$02,$0d,$04,$0b,$0b,$03
		.byte $08,$0e,$0a,$09,$03,$07,$0c,$02
	ChangeMapColors: {
			lda MapCols
			and #$07
			tax
			lda MapColors, x
			sta $d022
			lda MapColors + 8, x
			sta $d023
			inc MapCols
			rts
	}
}