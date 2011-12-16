

LCDBUFF		equ	40h
CLOCKFLAG	bit	00h

;RESET:***********************************************
		ORG	0000h
		LJMP	START
;IE0IRQ:**********************************************
		ORG	0003h
		RETI
;TF0IRQ:**********************************************
		ORG	000Bh
		LJMP	CLOCK
;IE1IRQ:**********************************************
		ORG	0013h
		RETI
;TF1IRQ:**********************************************
		ORG	001Bh
		RETI
;RITIIRQ:*********************************************
		ORG	0023h
		RETI
;TF2EXF2IRQ:******************************************
		ORG	002Bh
		RETI
;*****************************************************

START:		ACALL	LCDCLEARBUFF
		ACALL	LCDINIT
		ACALL	LCDCLEAR
		ACALL	CLOCKSHOW
		MOV	TMOD,#02h	;8 bit auto reload
		MOV	TL0,#255-200	
		MOV	TH0,#256-200	;100us intervall
		MOV	IE,#82h		;Enable timer 0 interrupt
		MOV	R7,#100
		MOV	R6,#100
		MOV	TCON,#10h	;Start timer 0
START1:		JNB	CLOCKFLAG,START2
		CLR	CLOCKFLAG
		ACALL	CLOCKINC
		ACALL	CLOCKSHOW
START2:		SJMP	START1		;Enter endless loop

CLOCKINC:	MOV	A,R2
		ADD	A,#01h
		DA	A
		MOV	R2,A
		CJNE	A,#60h,CLOCKINCEX
		MOV	R2,#00h
		MOV	A,R3
		ADD	A,#01h
		DA	A
		MOV	R3,A
		CJNE	A,#60h,CLOCKINCEX
		MOV	R3,#00h
		MOV	A,R4
		ADD	A,#01h
		DA	A
		MOV	R4,A
		CJNE	A,#24h,CLOCKINCEX
		MOV	R4,#00h
CLOCKINCEX:	RET

CLOCKSHOW:	MOV	A,#04h
		ACALL	LCDSETADR
		MOV	R0,#LCDBUFF
		MOV	A,R4		;Hours
		SWAP	A
		ANL	A,#0Fh
		ORL	A,#30h
		MOV	@R0,A
		INC	R0
		MOV	A,R4		;Hours
		ANL	A,#0Fh
		ORL	A,#30h
		MOV	@R0,A
		INC	R0
		MOV	@R0,#':'
		INC	R0
		MOV	A,R3		;Minutes
		SWAP	A
		ANL	A,#0Fh
		ORL	A,#30h
		MOV	@R0,A
		INC	R0
		MOV	A,R3		;Minutes
		ANL	A,#0Fh
		ORL	A,#30h
		MOV	@R0,A
		INC	R0
		MOV	@R0,#':'
		INC	R0
		MOV	A,R2		;Seconds
		SWAP	A
		ANL	A,#0Fh
		ORL	A,#30h
		MOV	@R0,A
		INC	R0
		MOV	A,R2		;Seconds
		ANL	A,#0Fh
		ORL	A,#30h
		MOV	@R0,A
		MOV	R0,#LCDBUFF
		MOV	R5,#8
		ACALL	LCDPRINTSTR
		RET

CLOCK:		DJNZ	R7,CLOCKEX
		MOV	R7,#100
		DJNZ	R6,CLOCKEX
		MOV	R6,#100
		SETB	CLOCKFLAG
CLOCKEX:	RETI

;------------------------------------------------------------------
;LCD Output.
;------------------------------------------------------------------
LCDDELAY:	PUSH	07h
		MOV	R7,#00h
		DJNZ	R7,$
		POP	07h
		RET

;A contains nibble, ACC.4 contains RS
LCDNIBOUT:	SETB	ACC.5				;E
		MOV	P2,A
		CLR	P2.5				;Negative edge on E
		RET

;A contains byte
LCDCMDOUT:	PUSH	ACC
		SWAP	A				;High nibble first
		ANL	A,#0Fh
		ACALL	LCDNIBOUT
		POP	ACC
		ANL	A,#0Fh
		ACALL	LCDNIBOUT
		ACALL	LCDDELAY			;Wait for BF to clear
		RET

;A contains byte
LCDCHROUT:	PUSH	ACC
		SWAP	A				;High nibble first
		ANL	A,#0Fh
		SETB	ACC.4				;RS
		ACALL	LCDNIBOUT
		POP	ACC
		ANL	A,#0Fh
		SETB	ACC.4				;RS
		ACALL	LCDNIBOUT
		ACALL	LCDDELAY			;Wait for BF to clear
		RET

LCDCLEAR:	MOV	A,#00000001b
		ACALL	LCDCMDOUT
		MOV	R7,#00h
LCDCLEAR1:	ACALL	LCDDELAY
		DJNZ	R7,LCDCLEAR1
		RET

;A contais address
LCDSETADR:	ORL	A,#10000000b
		ACALL	LCDCMDOUT
		RET

LCDPRINTSTR:	MOV	A,@R0
		ACALL	LCDCHROUT
		INC	R0
		DJNZ	R5,LCDPRINTSTR
		RET

LCDINIT:	MOV	A,#00000011b			;Function set
		ACALL	LCDNIBOUT
		ACALL	LCDDELAY			;Wait for BF to clear
		MOV	A,#00101000b
		ACALL	LCDCMDOUT
		MOV	A,#00101000b
		ACALL	LCDCMDOUT
		MOV	A,#00001100b			;Display ON/OFF
		ACALL	LCDCMDOUT
		ACALL	LCDCLEAR			;Clear
		MOV	A,#00000110b			;Cursor direction
		ACALL	LCDCMDOUT
		RET

LCDCLEARBUFF:	MOV	R0,#LCDBUFF
		MOV	R7,#10h
		MOV	A,#20H
LCDCLEARBUFF1:	MOV	@R0,A
		INC	R0
		DJNZ	R7,LCDCLEARBUFF1
		RET
		END
