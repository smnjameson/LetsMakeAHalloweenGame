#import "zpage.asm"
.var music = LoadSid("../assets/Hallow-Music.sid")

:BasicUpstart2(Entry)

.label SCREEN = $c000
.label COLORRAM = $d800
.label SPRITE_PTRS = SCREEN + $03f8

.label SUBTUNE_BLANK = 2
.label SUBTUNE_INTRO = 0
.label SUBTUNE_GAME = 0
.label SUBTUNE_GAME_OVER = 1

IntroActive:
	.byte $00
IntroRamp:
	.byte $01,$07,$03,$05,$04,$02,$06,$05
IntroRamp2:
	.byte $01,$0f,$0c,$0b,$0b,$0b,$0c,$0f
	.byte $07,$08,$09,$0b,$0b,$0b,$09,$08
IntroFireCounter:
	.byte $00
MusicActive:
	.byte $01
MusicText:
	.text " (%)    "
	.text " ($)    "

* = $2400
#import "map.asm"
#import "irq.asm"
#import "player.asm"
#import "bullets.asm"
#import "sound.asm"
#import "hud.asm"
#import "enemies.asm"

Entry: 
		sei
		lda #$00
		sta $d020
		lda #$00
		sta $d021

		//All ram
		lda $01
		and #%11111000
		ora #%00000101
		sta $01

		//VIC banking
		lda $dd00
		and #%11111100
		sta $dd00

		//Screen/char ram
		lda #%00000010
		sta $d018

		jsr IRQ.init
		jsr Random.init
		
		jsr SOUND.init

		//Set ZP Bullets
		lda #$00
		ldx #$00
	!:
		sta BulletType, x
		inx
		cpx #MAX_BULLETS
		bne !-



	//INTROLOOP
	!IntroStart:
		lda #$7b
   		sta $d011

   		jsr StopSounds

		lda #$30
		sta IntroFireCounter

		lda #<MessageText
		sta MessageIndex
		lda #>MessageText
		sta MessageIndex + 1



		lda $d418
		ora #$0f
		sta $d418


		lda #SUBTUNE_BLANK
		ldy MusicActive
		beq !+
		lda #SUBTUNE_GAME
	!:
		jsr music.init


		jsr MAP.init

		lda #$00
		jsr ClearScreen
		lda #$0d
		jsr ClearColor

		ldx #$00
	!:
		lda MessageCols, x
		sta COLORRAM + 24 * 40, x
		inx
		cpx #40
		bne !-


		lda #$01
		sta IntroActive
		lda #$11
		sta MAP.MinGap
		lda #$02
		sta MAP.HscrollSpeed
		lda #$00
		sta $d015

		//Initial intro setup
		ldx #$00
	!:
		txa
		pha
		jsr MAP.GenerateColumn
		lda #$01
		sta MAP.NeedToShift
		jsr MAP.ScreenShift
		pla
		tax 
		inx
		cpx #40
		bne !-


		ldx #$00
	!:
		lda INTROMAP,x
		sta SCREEN + 6 * 40, x
		tay
		lda CHARCOLORS, y
		sta COLORRAM + 6 * 40, x

		lda INTROMAP + 200,x
		sta SCREEN + 6 * 40 + 200, x
		tay
		lda CHARCOLORS , y
		sta COLORRAM + 6 * 40 + 200, x
		inx
		cpx #200
		bne !-

		lda #$0b
		sta $d022
		lda #$08
		sta $d023

		lda #$00
		sta ZP_GAMELOOP_FLAG

		jsr DrawHighscore

		lda #$1b
   		sta $d011
	!Introloop:
		lda ZP_GAMELOOP_FLAG
		beq !Introloop-
		dec ZP_GAMELOOP_FLAG
		
		jsr music.play 
		inc GameOverSinTicker

		lda GameOverSinTicker
		and #$0f
		lsr 
		tay
		ldx #$00
	!lp:
		lda IntroRamp, y
		sta COLORRAM + 6 * 40 + 19, x
		sta COLORRAM + 10 * 40 + 19, x
		iny
		cpy #$08
		bne !+
		ldy #$00
	!:
		inx
		cpx #20
		bne !lp-

		lda GameOverSinTicker
		and #$0f
		lsr 
		tay
		ldx #19
	!lp:
		lda IntroRamp, y
		sta COLORRAM + 8 * 40 + 19, x
		sta COLORRAM + 12 * 40 + 19, x
		iny
		cpy #$08
		bne !+
		ldy #$00
	!:
		dex
		bpl !lp-


		lda GameOverSinTicker
		and #$1f
		lsr 
		tay
		ldx #9
	!lp:
		lda IntroRamp2, y
		sta COLORRAM + 0 * 40 + 10, x
		sta COLORRAM , x
		iny
		cpy #$10
		bne !+
		ldy #$00
	!:
		dex
		bpl !lp-


		lda GameOverSinTicker
		and #$1f
		lsr 
		tay
		ldx #10
	!lp:
		lda IntroRamp2, y
		sta COLORRAM + 0 * 40 + 10, x

		iny
		cpy #$10
		bne !+
		ldy #$00
	!:
		inx
		cpx #20
		bne !lp-




		ldx #$07
		lda GameOverSinTicker
		and #$10
		beq !+
		ldx #$00
	!:
		txa
		ldx #$00
	!:
		sta COLORRAM + 15 * 40 + 15, x
		
		inx
		cpx #10
		bne !-	


		lda MusicActive
		asl
		asl
		asl
		tax

		ldy #$00
	!:
		lda MusicText, x
		sta SCREEN + 1, y
		inx
		iny
		cpy #$05
		bne !-
		//cb38
		lda GameOverSinTicker
		and #$03
		bne !Skip+
		ldy $cb38 + $0f
		ldx #$0e
	!:
		lda $cb38,x
		sta $cb39,x
		dex
		bpl !-
		sty $cb38
	!Skip:

		lda GameOverSinTicker
		and #$07
		bne !Skip+
		ldy $cb28 + $0f
		ldx #$0e
	!:
		lda $cb28,x
		sta $cb29,x
		dex
		bpl !-
		sty $cb28
	!Skip:



		jsr MAP.AdvanceMap
		jsr MAP.ScreenShift
		lda $dc00
		sta ZP_JOY2
		and #$10
		beq !+
		lda #$00
		sta GameOverFirePressed
	!:
		lda GameOverFirePressed
		bne !FireStillDown+

		dec IntroFireCounter
		bpl !+
		inc IntroFireCounter
	!:
		bne !FireStillDown+

		lda MusicActive
		beq !+
		lda ZP_JOY2
		and #$04
		bne !+
		lda #$00
		sta MusicActive
		lda #SUBTUNE_BLANK
		jsr music.init
	!:


		lda MusicActive
		bne !+
		lda ZP_JOY2
		and #$08
		bne !+
		lda #$01
		sta MusicActive
		lda #SUBTUNE_INTRO
		jsr music.init
	!:

		lda ZP_JOY2
		and #$10
		bne !FireStillDown+
		jmp !StartGame+	
	!FireStillDown:
		jmp !Introloop-







	!StartGame:
		lda $d418
		ora #$0f
		sta $d418

		lda #$00
		sta IntroActive
	//GAMELOOP
		jsr MAP.init
		jsr PLAYER.init
		jsr ENEMIES.init
		jsr HUD.init
		jsr GenerateStars

		lda #SUBTUNE_BLANK
		ldy MusicActive
		beq !+
		lda #SUBTUNE_GAME
	!:
		jsr music.init
	!Loop:
		lda ZP_GAMELOOP_FLAG
		beq !Loop-
		dec ZP_GAMELOOP_FLAG

		//clear - MAPSHIFT - update - draw
		jsr ClearStars
		jsr ENEMIES.draw

		jsr BULLETS.clear
		jsr BULLETS.update

		jsr MAP.AdvanceMap
	
		//Draw top half
		ldx #$00
		jsr MAP.ScreenShift
		ldx #$b0 //BCS
		jsr BULLETS.draw	
		ldx #$b0
		jsr DrawStars

		jsr ENEMIES.update
		
		//Draw bottom half
		ldx #$01
		jsr MAP.ScreenShift
		ldx #$90 //BCC
		jsr BULLETS.draw	
		ldx #$90
		jsr DrawStars
		

		jsr PLAYER.update
		jsr PLAYER.draw


		jsr music.play 




	!:


		lda PLAYER.PlayerIsDead
		bne !GameOverBegin+

		lda PLAYER.PowerUpActive
		beq !+
		lda ZP_COUNTER
		and #$07
		bne !+
		jsr HUD.decPower
	!:
		jmp !Loop-







	//GAMEOVER LOOP!
	DeathAnimTimer:
		.byte $00, $04
	DeathAnimIndex:
		.byte $00
	DeathFrames:
		.byte 68,69,70,71,67
	GameOverFirePressed:
		.byte $00
	GameOverFireCountdown:
		.byte $00
	GameOverMusicTimer:
		.byte $00
	!GameOverBegin:

		lda #$02
		jsr music.init

		lda #$00
		sta MAP.HscrollSpeed
		sta GameOverMusicTimer
		lda #$00
		sta DeathAnimIndex
		lda ZP_JOY2
		and #$10
		eor #$ff
		sta GameOverFirePressed

		lda #$40
		sta GameOverFireCountdown

		jsr CheckForHighscore

	!GameOver:
		lda ZP_GAMELOOP_FLAG
		beq !GameOver-
		dec ZP_GAMELOOP_FLAG
		
		lda GameOverFireCountdown
		beq !+
		dec GameOverFireCountdown
		jmp !FireStillDown+
	!:
		lda $dc00
		sta ZP_JOY2
		and #$10
		beq !+
		lda #$00
		sta GameOverFirePressed
	!:
		lda GameOverFirePressed
		bne !FireStillDown+
		lda ZP_JOY2
		and #$10
		bne !FireStillDown+
		lda #$01
		sta GameOverFirePressed
		jmp !IntroStart-

	!FireStillDown:
		dec DeathAnimTimer
		bpl !+
		lda DeathAnimTimer + 1
		sta DeathAnimTimer	
		ldx DeathAnimIndex
		inx
		cpx #$05
		bne !Apply+
		ldx #$04
	!Apply:
		stx DeathAnimIndex
	!:
		ldx DeathAnimIndex
		lda DeathFrames, x
		beq !+
		sta SPRITE_PTRS + 0
		lda #$0e
		sta $d027
	!:


		lda #$00
		jsr BULLETS.clear
		jsr BULLETS.update
		
		jsr ClearStars
		jsr MAP.AdvanceMap

		//Draw top half
		ldx #$00
		jsr MAP.ScreenShift
		ldx #$b0 //BCS
		jsr BULLETS.draw	
		ldx #$b0
		jsr DrawStars

		//Draw bottom half
		ldx #$01
		jsr MAP.ScreenShift
		ldx #$90
		jsr BULLETS.draw	
		ldx #$90
		jsr DrawStars



		ldx DeathAnimIndex
		cpx #$04
		bne !+
		jsr music.play
		jmp !ShowGameOver+
	!:
		jsr ENEMIES.update
		jsr ENEMIES.draw

		jsr music.play
		jmp !GameOver-


	GameOverSinY:
		.fill 256, sin((i/128) * (PI*2)) * $18 + $80
	GameOverSinTicker:
		.byte $00
	GameOverColRamp:
		.byte $01,$0d,$03,$0c,$04,$02,$09,$08

	!ShowGameOver:
		ldx MusicActive
		beq !+
		ldx GameOverMusicTimer
		cpx #240
		bcs !+
		cpx #1
		bne !DontStartMusic+
		lda #SUBTUNE_GAME_OVER
		// .break
		jsr music.init
	!DontStartMusic:
		ldx GameOverMusicTimer
		inx
		stx GameOverMusicTimer
		cpx #240
		bne !+
		lda #SUBTUNE_BLANK
		jsr music.init	
	!:



		lda #$00
		sta MAP.HscrollSpeed

		lda HighscoreAcheived
		beq !NoHighscore+
		ldx #$00
	!Lp:
		lda HighScoreText, x
		sta SCREEN + 18 * 40 + 7, x
		inx
		cpx #26
		bne !Lp-

		lda #$01
		sta COLORRAM + 18 * 40 + 7 + 2
		sta COLORRAM + 18 * 40 + 7 + 3
		sta COLORRAM + 18 * 40 + 7 + 4
		sta COLORRAM + 18 * 40 + 7 + 21
		sta COLORRAM + 18 * 40 + 7 + 22
		sta COLORRAM + 18 * 40 + 7 + 23

		lda ZP_COUNTER
		lsr
		lsr
		lsr
		and #$01
		beq !+
		lda #$07
	!:
		ldx #$00
	!Lp:
		sta COLORRAM + 18 * 40 + 7 + 5, x
		inx
		cpx #16
		bne !Lp-


	!NoHighscore:

		lda #00
		sta PLAYER.PlayerIsDead

		lda #$ff
		sta $d015

		lda #144
		ldx #$00
		clc
	!:
		sta SPRITE_PTRS, x
		adc #$01
		inx
		cpx #$08
		bne !-

		inc GameOverSinTicker

		.for(var x=0; x<4; x++) {
			lda #[70 + x * 26]
			sta $d000 + 2 * x	
		}
		.for(var x=4; x<8; x++) {
			lda #[94 + x * 26]
			sta $d000 + 2 * x	
		}
		lda #$80
		sta $d010

		ldx #$00
		ldy #$00
	!:
		txa
		pha
		asl
		asl
		asl
		clc
		adc GameOverSinTicker
		tax
		lda GameOverSinY, x
		sta $d001, y
		iny 
		iny 
		pla
		tax
		inx 
		cpx #$08
		bne !-

		ldx #$00
	!:
		txa
		adc GameOverSinTicker
		and #$0f
		lsr 
		tay
		lda GameOverColRamp, y
		sta $d027, x
		inx
		cpx #$08
		bne !-

		jmp !GameOver-














	ClearScreen: {
			ldx #$00
		!:
			sta SCREEN + 000, x
			sta SCREEN + 250, x
			sta SCREEN + 500, x
			sta SCREEN + 750, x
			inx
			cpx #250
			bne !-
			rts
	}

	ClearColor: {
			ldx #$00
		!:
			sta COLORRAM + 000, x
			sta COLORRAM + 250, x
			sta COLORRAM + 500, x
			sta COLORRAM + 750, x
			inx
			cpx #250
			bne !-
			rts
	}

	Random: {
		init: {
			lda #$7f
			sta $dc04
			lda #$33
			sta $dc05
			lda #$2f
			sta $dd04
			lda #$79
			sta $dd05

			lda #$91
			sta $dc0e
			sta $dd0e
			rts

		}

		get: {
		        lda seed
		        beq doEor
		        asl
		        beq noEor
		        bcc noEor
		    doEor:    
		        eor #$1d
		        eor $dc04
		        eor $dd04
		    noEor:  
		        sta seed
		        rts
		    seed:
		        .byte $62
		}
	}

	DrawHighscore: {
			ldx #$00
		!:
			lda Hiscore, x
			sta SCREEN, x
			inx
			cpx #40
			bne !-
			rts
	}

	Hiscore:
		.fill 12, 0
		.text "hiscore  0000000"
		.fill 12, 0
	HighscoreAcheived:
		.byte $00
	HighScoreText:
		.fill 2, 0
		.fill 3, 31
		.text " new high score "
		.fill 3, 31
		.fill 2, 0

	TABLES: {
		ScreenRowLSB:
			.fill 25, <[SCREEN + i * 40]
		ScreenRowMSB:
			.fill 25, >[SCREEN + i * 40]
		ColRowLSB:
			.fill 25, <[COLORRAM + i * 40]
		ColRowMSB:
			.fill 25, >[COLORRAM + i * 40]
		POT:
			.byte 1,2,4,8,16,32,64,128,256
		InvPOT:
			.byte 255-1, 255-2, 255-4, 255-8
			.byte 255-16,255-32,255-64,255-128
	}








	GenerateStars: {
			ldx #$00
		!Loop:
			jsr Random.get
			and #$1f
			cmp #24
			bcs !Loop-
			sta STARXY + 1, x
			tay
			lda TABLES.ScreenRowLSB, y
			sta STARS, x
			lda TABLES.ScreenRowMSB, y
			sta STARS + 1, x
			lda TABLES.ColRowLSB, y
			sta STARCOLS, x
			lda TABLES.ColRowMSB, y
			sta STARCOLS + 1, x
		!:
			jsr Random.get
			and #$3f
			cmp #36
			bcs !-
			adc #$02
			sta STARXY, x
			adc STARS, x
			sta STARS, x
			sta STARCOLS, x
			bcc !+
			inc STARS + 1,x
			inc STARCOLS + 1,x
		!:
			inx
			inx
			cpx #[MAX_STARS * 2]
			bne !Loop-

			.for(var i =0; i< 8; i++) {
				lda #[pow(2,i)]
				sta $cbc4 + i * 8
			}			
			rts 
	}

	DrawStars: {
			stx SelfMod

			clc
			ldx #$00
		!Loop:
			lda STARXY + 1, x
			cmp #12
		SelfMod:
			bcc !Skip+
			clc
			lda (STARS, x)
			bne !Skip+
			lda MAP.Hscroll
			adc #120
			sta (STARS, x)
			lda #$01
			sta (STARCOLS, x)

		!Skip:
			inx
			inx
			cpx #[MAX_STARS * 2]
			bne !Loop-
			rts
	}

	ClearStars: {
			clc
			ldx #$00
		!Loop:
			lda (STARS, x)
			cmp #128
			bcs !Skip+
			lda #$00
			sta (STARS, x)
			lda #$0d
			sta (STARCOLS, x)

		!Skip:
			inx
			inx
			cpx #[MAX_STARS * 2]
			bne !Loop-
			rts
	}



	CheckForHighscore: {
			lda #$00
			sta HighscoreAcheived

			ldx #$00
		!:
			lda [SCREEN + 24 * 40 + 7], x
			cmp Hiscore + 21, x
			bcc !Exit+
			beq !Next+
			bcs !Achieved+
		!Next:
			inx
			cpx #$07
			bne !-
			jmp !Exit+

		!Achieved:
			lda #$01
			sta HighscoreAcheived	
			ldx #$00
		!:
			lda [SCREEN + 24 * 40 + 7], x
			sta Hiscore + 21, x
			inx
			cpx #$07
			bne !-
		!Exit:
			rts
	}

	StopSounds: {
			lda #$00
			sta $d404
			sta $d40b
			sta $d412
			rts

	}


MessageCols:
	.byte $0b,$0b,$0c,$0c,$0f,$0f
	.fill 28, 1
	.byte $0f,$0f,$0c,$0c,$0b,$0b
MessageText:
	.fill 40, 0
	.fill 3, 31
	.text " luna "
	.fill 3, 31
	.text "   for the doublesidedgames halloween competition 2019..."
	.text " coded by shallan,"
	.text " sound by stepz,"
	.text " art by shallan, furroy, and monstersgoboom... "
	.fill 3, 31
	.text " thanks to hayesmaker for the idea to enter..."
	.text " to richmondmike for the sfx conversions..."
	.text " and to akmafin for the terrible joke production... "
	.fill 3, 31
	.text " written mostly on a marathon 13 hour stream with only some bug fixing and final polish added before submission..."
	.text " huge thanks to everyone who came along and watched the stream and a shoutout to all the regular viewers subscribers and patreons... "
	.fill 3, 31
	.text " long thankyou list incoming* apologies if i have missed anyone..."
	.text " thanks to "
	.text " abridgewater, airjuri, am0k0kad1s, andymagicknight, artionictv,"
	.text " aruseus, babagamingofficial, blackwaht226, br1ydon, c64-television,"
	.text " cashinitgaming, coconut-81, colinvella75, colt45rpm, deetle, derpzerker,"
	.text " dogemandoge, domedagspoeten, domfx, drmiztlur, drzingo, evilface-jord,"
	.text " fanskap-sthlm, fox-maccloud, fredmsloniker, gunstarrhero, harrylongbone,"
	.text " illmidus, jakobwesthoff, jb-denmark, jost80, jtgans, klaykree,"
	.text " mastahblastah, maverick-twitch-, mbdr-, mochijump, mondoshawan22, mrg8472,"
	.text " mrkola, mrlovepickle, mrmaru, muppetinthecorner, nettotibode46ce, newsroomcool,"
	.text " panostrak, phexpt, pigravity, preachervip, princephaze101, qoostewin, raycatwhodat,"
	.text " robopond, rustygames, sakrac,"
	.text " sm--f, stacbats, stokerc64, thalamusdigital, thamness, tinspin, tombyte,"
	.text " vittoriorebecchi, vonmillhausen, warcried, waschbenzin, xgeotrk, zephyr-wrangler,"
	.text " zhorky, zorchenhimer "
	.fill 3, 31
	.byte $ff



//Asset Imports
* = music.location "Music"
    .fill music.size, music.getData(i)

* = $c400
	HUDDATA:
	.import binary "../assets/hud.bin"
	HUDCOLORS:
	.byte 1,2,2,2,2,2,3,7,7,7,7,7,7,7,1
	.byte 2,2,2,2,2,3,5,5,5,5,5,5,5,5,5
	.byte 1,2,2,2,2,3,7,7,7,1
	CHARCOLORS:
	.import binary "../assets/colors.bin"
	INTROMAP:
	.import binary "../assets/intro.bin"
* = $c800
	.import binary "../assets/font.bin"

* =	$d000
	.import binary "../assets/sprites.bin"	