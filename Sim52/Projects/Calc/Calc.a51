
LCDBUFF		equ	40h		;40h-4Fh 16 byte buffer

;RESET:***********************************************
		ORG	0000h
		LJMP	START		;RESET:
;IE0IRQ:**********************************************
		ORG	0003h
		RETI			;IE0IRQ:
;TF0IRQ:**********************************************
		ORG	000Bh
		RETI			;TF0IRQ:
;IE1IRQ:**********************************************
		ORG	0013h
		RETI			;IE1IRQ:
;TF1IRQ:**********************************************
		ORG	001Bh
		RETI			;TF1IRQ:
;RITIIRQ:*********************************************
		ORG	0023h
		RETI			;RITIIRQ:
;TF2EXF2IRQ:******************************************
		ORG	002Bh
		RETI			;TF2EXF2IRQ:
;*****************************************************

START:		ACALL	LCDCLEARBUFF
		ACALL	LCDINIT
		ACALL	LCDCLEAR
		MOV	4Fh,#'0'
		ACALL	LCDSHOW
START1:		ACALL	SCANKEYBOARD
		JZ	START1
		CJNE	A,#'C',START2
		ACALL	LCDCLEARBUFF
		MOV	4Fh,#'0'
		ACALL	LCDSHOW
		SJMP	START1
START2:		PUSH	ACC
		MOV	R0,#LCDBUFF
		MOV	R1,#LCDBUFF+1
		MOV	R7,#15
START3:		MOV	A,@R1
		MOV	@R0,A
		INC	R0
		INC	R1
		DJNZ	R7,START3
		POP	ACC
		MOV	@R0,A
		ACALL	LCDSHOW
START4:		ACALL	SCANKEYBOARD
		JNZ	START4
		SJMP	START1

LCDSHOW:	CLR	A
		ACALL	LCDSETADR
		MOV	R7,#16
		MOV	R0,#LCDBUFF
		ACALL	LCDPRINTSTR
		RET

SCANKEYBOARD:	MOV	R7,#04h
		MOV	R6,#0FEh
SCANKEYBOARD1:	MOV	P1,R6
		MOV	A,P1
		ANL	A,#0F0h
		CJNE	A,#0F0h,SCANKEYBOARD2
		MOV	A,R6
		SETB	C
		RLC	A
		MOV	R6,A
		DJNZ	R7,SCANKEYBOARD1
		;No keys down
		CLR	A
		RET
SCANKEYBOARD2:	MOV	R5,#04h
SCANKEYBOARD3:	DEC	R5		;Row
		RLC	A
		JC	SCANKEYBOARD3
		MOV	A,R6
		MOV	R6,#0FFh	;Column
SCANKEYBOARD4:	INC	R6
		RRC	A
		JC	SCANKEYBOARD4
		MOV	A,R5
		RL	A
		RL	A
		ORL	A,R6
		MOV	DPTR,#KEYS
		MOVC	A,@A+DPTR
		RET

KEYS:		DB	'789+'
		DB	'456-'
		DB	'123*'
		DB	'C0./'

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
		DJNZ	R7,LCDPRINTSTR
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
