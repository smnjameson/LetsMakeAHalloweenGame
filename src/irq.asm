.label MAIN_SPLIT = $f2
IRQ: {
	init: {

			//Interupts
			lda #$7f
			sta $dc0d
			sta $dd0d

			lda $d01a
			ora #$01
			sta $d01a

			lda #<IRQEntry1
			sta $fffe
			lda #>IRQEntry1
			sta $ffff

			lda #<NMI
			sta $fffa
			lda #>NMI
			sta $fffb

			lda #$f2
			sta $d012
			lda $d011
			and #$7f
			sta $d011

			asl $d019

			cli
			rts
		NMI:
			rti
	}

	IRQEntry0: {
			:StoreState()

			inc ZP_COUNTER
			inc ZP_GAMELOOP_FLAG


			lda #<IRQEntry1
			sta $fffe
			lda #>IRQEntry1
			sta $ffff
			lda #$f2
			sta $d012
			lda $d011
			and #$7f
			sta $d011


			asl $d019
			:RestoreState()			
			rti
	}

	IRQEntry1: {
			:StoreState()

			ldx #$05
		!:
			dex
			bne !-

			//Turn Off MC, On 40 columns, No scroll
			lda IntroActive
			beq !+
			lda $d016
			and #$07
			ora #$c0
			jmp !Skip+
		!:
			lda #$c8
		!Skip:
			sta $d016





			lda IntroActive
			beq !+

			inc ZP_COUNTER
			inc ZP_GAMELOOP_FLAG
		!:
			lda #<IntroIRQ3
			sta $fffe
			lda #>IntroIRQ3
			sta $ffff
			lda #$30
			sta $d012
			lda $d011
			and #$7f
			sta $d011
			
			asl $d019
			:RestoreState()			
			rti

		!:

			lda #$fc 
			cmp $d012 
			bne *-3
			
			jsr MAP.AdvanceMap
			lda MAP.Hscroll
			and #$07
			ora #$d0
			sta $d016

			

			lda #<IRQEntry0
			sta $fffe
			lda #>IRQEntry0
			sta $ffff
			lda #$e2
			sta $d012
			lda $d011
			and #$7f
			sta $d011

			asl $d019
			:RestoreState()			
			rti
	}

	IntroIRQ1: {
			:StoreState()	


			lda #$d8
			sta $d016

			lda #<IntroIRQ2
			sta $fffe
			lda #>IntroIRQ2
			sta $ffff
			lda #$b2
			sta $d012
			lda $d011
			and #$7f
			sta $d011

			asl $d019
			:RestoreState()			
			rti	
	}


	IntroIRQ3: {
			:StoreState()	
			lda IntroActive
			beq !+

			lda #$c8
			sta $d016

			lda #$3b
			cmp $d012
			bne *-03
		!:
			lda MAP.Hscroll
			and #$07
			ora #$d0
			sta $d016
			
			lda IntroActive
			beq !+

			lda #<IntroIRQ1
			sta $fffe
			lda #>IntroIRQ1
			sta $ffff
			lda #$62
			sta $d012
			lda $d011
			and #$7f
			sta $d011

			asl $d019
			:RestoreState()			
			rti	

		!:

			lda #<IRQEntry0
			sta $fffe
			lda #>IRQEntry0
			sta $ffff
			lda #$d2
			sta $d012
			lda $d011
			and #$7f
			sta $d011

			asl $d019
			:RestoreState()			
			rti		
	}

	IntroIRQ2: {
			:StoreState()	

			lda MAP.Hscroll
			and #$07
			ora #$d0
			sta $d016
			
			lda #<IRQEntry1
			sta $fffe
			lda #>IRQEntry1
			sta $ffff
			lda #MAIN_SPLIT
			sta $d012
			lda $d011
			and #$7f
			sta $d011

			asl $d019
			:RestoreState()			
			rti	
	}

}

.macro StoreState() {
			pha
			txa 
			pha 
			tya 
			pha
}

.macro RestoreState() {
			pla
			tay
			pla
			tax 
			pla
}