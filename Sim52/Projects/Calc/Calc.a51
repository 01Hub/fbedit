
LCDBUFF		equ	40h		;40h-4Fh 16 byte buffer
LASTCHR		equ	50h		;Holds the last key pressed
FUNCTION	equ	51h		;Holds function +,-,* or /
NOENTRY		bit	00h
CCE		bit	01h		;If set then C

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

START:		CLR	CCE
		MOV	FUNCTION,#'+'
		ACALL	LCDINIT
		ACALL	LCDCLEAR
START0:		ACALL	LCDCLEARBUFF
		MOV	4Fh,#'0'
		ACALL	LCDSHOW
		SETB	NOENTRY
START1:		ACALL	PSCANKEYB
		JZ	START1
		CJNE	A,#'C',START2
		JB	CCE,START		;CE/C pressed twice
		SETB	CCE
		SJMP	START0
START2:		CLR	CCE
		CJNE	A,#'+',START3
		MOV	FUNCTION,A
		SETB	NOENTRY
		SJMP	START1
START3:		CJNE	A,#'-',START4
		MOV	FUNCTION,A
		SETB	NOENTRY
		SJMP	START1
START4:		CJNE	A,#'*',START5
		MOV	FUNCTION,A
		SETB	NOENTRY
		SJMP	START1
START5:		CJNE	A,#'/',START6
		MOV	FUNCTION,A
		SETB	NOENTRY
		SJMP	START1
START6:		JB	NOENTRY,START10
		ACALL	LCDSCROLL
		ACALL	LCDSHOW
		SJMP	START1
START10:	PUSH	ACC
		ACALL	LCDCLEARBUFF
		MOV	4Fh,#'0'
		POP	ACC
		CJNE	A,#'.',START11
		MOV	4Eh,#'0'
START11:	CJNE	A,#'0',START12
		MOV	4Fh,#'0'
		ACALL	LCDSHOW
		SJMP	START1
START12:	MOV	4Fh,A
		ACALL	LCDSHOW
		CLR	NOENTRY
		SJMP	START1

LCDSCROLL:	PUSH	ACC
		MOV	R0,#LCDBUFF
		MOV	R1,#LCDBUFF+1
		MOV	R7,#15
LCDSCROLL1:	MOV	A,@R1
		MOV	@R0,A
		INC	R0
		INC	R1
		DJNZ	R7,LCDSCROLL1
		POP	ACC
		MOV	@R0,A
		RET

LCDSHOW:	CLR	A
		ACALL	LCDSETADR
		MOV	R7,#16
		MOV	R0,#LCDBUFF
		ACALL	LCDPRINTSTR
		RET

PSCANKEYB:	MOV	R7,#04h
		MOV	R6,#0Eh
		MOV	R5,#00h
PSCANKEYB1:	MOV	A,P1
		ANL	A,#0F0h
		ORL	A,R6
		MOV	P1,A
		MOV	A,P1
		ANL	A,#0F0h
		CJNE	A,#0F0h,PSCANKEYB2
		;Next column
		MOV	A,R6
		SETB	C
		RLC	A
		ANL	A,#0Fh
		MOV	R6,A
		;Wait loop
		DJNZ	R5,$
		DJNZ	R7,PSCANKEYB1
		;No keys down
		CLR	A
		SJMP	PSCANKEYB5
		;A key is down, find column and row
PSCANKEYB2:	MOV	R5,#04h
PSCANKEYB3:	DEC	R5		;Row
		RLC	A
		JC	PSCANKEYB3
		MOV	A,R6
		MOV	R6,#0FFh	;Column
PSCANKEYB4:	INC	R6
		RRC	A
		JC	PSCANKEYB4
		;Convert column and row to a character
		MOV	A,R5
		RL	A
		RL	A
		ORL	A,R6
		MOV	DPTR,#KEYS
		MOVC	A,@A+DPTR
		CJNE	A,LASTCHR,PSCANKEYB5
		;Previous key not released yet
		CLR	A
		SJMP	PSCANKEYB6
PSCANKEYB5:	MOV	LASTCHR,A
PSCANKEYB6:	PUSH	ACC
		MOV	A,P1
		ORL	A,#0Fh
		MOV	P1,A
		POP	ACC
		RET

MMSCANKEYB:	MOV	R7,#04h
		MOV	R6,#0Eh
		MOV	R5,#00h
		MOV	DPTR,#8000h
MMSCANKEYB1:	MOVX	A,@DPTR
		ANL	A,#0F0h
		ORL	A,R6
		MOVX	@DPTR,A
		MOV	A,P1
MOV 51h,A
		ANL	A,#0F0h
		CJNE	A,#0F0h,MMSCANKEYB2
		;Next column
		MOV	A,R6
		SETB	C
		RLC	A
		ANL	A,#0Fh
		MOV	R6,A
		;Wait loop
		DJNZ	R5,$
		DJNZ	R7,MMSCANKEYB1
		;No keys down
		CLR	A
		SJMP	MMSCANKEYB5
		;A key is down, find column and row
MMSCANKEYB2:	MOV	R5,#04h
MMSCANKEYB3:	DEC	R5		;Row
		RLC	A
		JC	MMSCANKEYB3
		MOV	A,R6
		MOV	R6,#0FFh	;Column
MMSCANKEYB4:	INC	R6
		RRC	A
		JC	MMSCANKEYB4
		;Convert column and row to a character
		MOV	A,R5
		RL	A
		RL	A
		ORL	A,R6
		MOV	DPTR,#KEYS
		MOVC	A,@A+DPTR
		CJNE	A,LASTCHR,MMSCANKEYB5
		;Previous key not released yet
		CLR	A
		SJMP	MMSCANKEYB6
MMSCANKEYB5:	MOV	LASTCHR,A
MMSCANKEYB6:	MOV	DPTR,#8000h
		PUSH	ACC
		MOVX	A,@DPTR
		ORL	A,#0Fh
		MOVX	@DPTR,A
		POP	ACC
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

$include	(FP52INT.a51)

		END
