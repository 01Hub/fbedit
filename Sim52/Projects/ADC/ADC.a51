
LCDLINE		EQU	40h				;16 Bytes

;RESET:***********************************************
		ORG	0000h
		LJMP	START

START:		ACALL	LCDCLEARBUFF
		ACALL	LCDINIT
		MOV	LCDLINE,#'C'
		MOV	LCDLINE+1,#'H'
START1:		CLR	A
		ACALL	LCDSETADR
		MOV	A,#00h			;CH0
		ACALL	ADCONVERT
		MOV	R6,#00h
		MOV	R7,#00h
		MOV	R0,#LCDLINE+4
		ACALL	BIN2DEC
		MOV	LCDLINE+2,#'0'
		MOV	R7,#10h
		MOV	R0,#LCDLINE
		ACALL	LCDPRINTSTR
		MOV	A,#40h
		ACALL	LCDSETADR
		MOV	A,#01h			;CH1
		ACALL	ADCONVERT
		MOV	R6,#00h
		MOV	R7,#00h
		MOV	R0,#LCDLINE+4
		ACALL	BIN2DEC
		MOV	LCDLINE+2,#'1'
		MOV	R7,#10h
		MOV	R0,#LCDLINE
		ACALL	LCDPRINTSTR
		MOV	R6,#00h
		MOV	R7,#00h
START2:		DJNZ	R6,START2
		DJNZ	R7,START2
		AJMP	START1

;------------------------------------------------------------------
;AD Converter.
;IN:	A holds channel (0 to 7).
;OUT:	R5:R4 Holds 16 Bit result
;-----------------------------------------------------
ADCONVERT:	ORL	A,#18h				;START, SINGLE ENDED
		RL	A
		RL	A
		RL	A
		CLR	P1.0				;CS	LOW
		;Clock in channel select and Single/Diff+2 clocks for sample
		MOV	R7,#07h
ADCONVERT1:	RLC	A
		MOV	P1.2,C				;DIN
		CLR	P1.1				;CLK	LOW
		SETB	P1.1				;CLK	HIGH
		DJNZ	R7,ADCONVERT1
		SETB	P1.2				;DIN	HIGH
		;Clock out 5 bits, including null bit
		CLR	A
		MOV	R7,#05h
ADCONVERT2:	MOV	C,P1.3				;DOUT
		RLC	A
		CLR	P1.1				;CLK	LOW
		SETB	P1.1				;CLK	HIGH
		DJNZ	R7,ADCONVERT2
		MOV	R5,A
		;Clock out 8 bits
		MOV	R7,#08h
		CLR	A
ADCONVERT3:	MOV	C,P1.3				;DOUT
		RLC	A
		CLR	P1.1				;CLK	LOW
		SETB	P1.1				;CLK	HIGH
		DJNZ	R7,ADCONVERT3
		MOV	R4,A
		;CS high
		SETB	P1.0				;CS	HIGH
		RET

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

PRNTCDPTRLCD:	CLR	A
		MOVC	A,@A+DPTR
		JZ	PRNTCDPTRLCD1
		ACALL	LCDCHROUT
		INC	DPTR
		SJMP	PRNTCDPTRLCD
PRNTCDPTRLCD1:	RET

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

LCDCLEARBUFF:	MOV	R0,#LCDLINE
		MOV	R7,#10h
		MOV	A,#20H
LCDCLEARBUFF1:	MOV	@R0,A
		INC	R0
		DJNZ	R7,LCDCLEARBUFF1
		RET

;------------------------------------------------------------------
;Binary to decimal converter
;Converts R7:R6:R5:R4 to decimal pointed to by R0
;Returns with number of digits in A
;------------------------------------------------------------------
BIN2DEC:	PUSH	00h
		MOV	DPTR,#BINDEC
		MOV	R2,#0Ah
BIN2DEC1:	MOV	R3,#2Fh
BIN2DEC2:	INC	R3
		ACALL	SUBIT
		JNC	BIN2DEC2
		ACALL	ADDIT
		MOV	A,R3
		MOV	@R0,A
		INC	R0
		INC	DPTR
		INC	DPTR
		INC	DPTR
		INC	DPTR
		DJNZ	R2,BIN2DEC1
		POP	00h
		;Remove leading zeroes
		MOV	R2,#09h
BIN2DEC3:	MOV	A,@R0
		CJNE	A,#30h,BIN2DEC4
		MOV	@R0,#20h
		INC	R0
		DJNZ	R2,BIN2DEC3
BIN2DEC4:	INC	R2
		MOV	A,R2
		RET

SUBIT:		CLR	A
		MOVC	A,@A+DPTR
		XCH	A,R4
		CLR	C
		SUBB	A,R4
		MOV	R4,A
		MOV	A,#01h
		MOVC	A,@A+DPTR
		XCH	A,R5
		SUBB	A,R5
		MOV	R5,A
		MOV	A,#02h
		MOVC	A,@A+DPTR
		XCH	A,R6
		SUBB	A,R6
		MOV	R6,A
		MOV	A,#03h
		MOVC	A,@A+DPTR
		XCH	A,R7
		SUBB	A,R7
		MOV	R7,A
		RET

ADDIT:		CLR	A
		MOVC	A,@A+DPTR
		ADD	A,R4
		MOV	R4,A
		MOV	A,#01h
		MOVC	A,@A+DPTR
		ADDC	A,R5
		MOV	R5,A
		MOV	A,#02h
		MOVC	A,@A+DPTR
		ADDC	A,R6
		MOV	R6,A
		MOV	A,#03h
		MOVC	A,@A+DPTR
		ADDC	A,R7
		MOV	R7,A
		RET

BINDEC:		DB	000h,0CAh,09Ah,03Bh		;1000000000
		DB	000h,0E1h,0F5h,005h		; 100000000
		DB	080h,096h,098h,000h		;  10000000
		DB	040h,042h,0Fh,0000h		;   1000000
		DB	0A0h,086h,001h,000h		;    100000
		DB	010h,027h,000h,000h		;     10000
		DB	0E8h,003h,000h,000h		;      1000
		DB	064h,000h,000h,000h		;       100
		DB	00Ah,000h,000h,000h		;        10
		DB	001h,000h,000h,000h		;         1

		END
