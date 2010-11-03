;ADC VREF=1.342 Volts

;-----------------------------------------------------
;*****************************************************
;RAM Locations
;-----------------------------------------------------
;20				Interrupt flags
;E0-FF			Stack
;-----------------------------------------------------
;*****************************************************
;SCREEN DRIVER
;-----------------------------------------------------
;01				START SEND ROMDATA.HEX FILE
;02				STOP SEND FILE
;03				START RECIEVE ROMDATA.HEX FILE
;04				STOP RECIEVE FILE
;05				START RECIEVE FILE IN 16 BYTE BLOCKS
;06				STOP RECIEVE FILE IN 16 BYTE BLOCKS
;07				BELL
;08				BACK SPACE
;09				TAB
;0A				LF
;0B				LOCATE
;0C				HOME
;0D				CR
;0E				CLS
;0F				MODE
;10				START SEND CMDFILE.CMD FILE
;-----------------------------------------------------
;*****************************************************
;Memory mapped I/O
;-----------------------------------------------------
;8000h Output
;-----------------------------------------------------
;D0		LCD DB4
;D1		LCD DB5
;D2		LCD DB6
;D3		LCD DB7
;D4		LCD RS
;D5		LCD E
;D6
;D7
;-----------------------------------------------------
;8001h Output
;-----------------------------------------------------
;D0		FRQ SEL A | 00 FREQENCY COUNER 01 FUNCTION GEN 
;D1		FRQ SEL B | 10 L/C METER 11 ITERNAL ALE
;D2		FRQ GATE ACTIVE LOW
;D3		FRQ	RESET ACTIVE HIGH
;D4		ADC CS ACTIVE LOW
;D5		ADC CLK HIGH TO LOW TRANSITION
;D6		ADC DIN
;D7
;-----------------------------------------------------
;8000h Input
;-----------------------------------------------------
;D0		ADC DOUT
;D1
;D2
;D3
;D4
;D5
;D6
;D7
;-----------------------------------------------------
;8001h Input
;-----------------------------------------------------
;D0		FRQ LSB
;D1
;D2
;D3
;D4
;D5
;D6
;D7		FRQ MSB
;-----------------------------------------------------
;*****************************************************
;Equates
;-----------------------------------------------------
T2CON			EQU 0C8h
RCAP2L			EQU 0CAh
RCAP2H			EQU 0CBh
TL2				EQU 0CCh
TH2				EQU 0CDh
;-----------------------------------------------------
;*****************************************************

				ORG		2000H

START:			ACALL	LCDINIT
				MOV		A,#41h
				ACALL	LCDCHROUT
				MOV		A,#42h
				ACALL	LCDCHROUT
				MOV		A,#43h
				ACALL	LCDCHROUT
				MOV		A,#44h
				ACALL	LCDCHROUT
				MOV		R0,#10
START1:			MOV		A,#03h
				ACALL	FRQCOUNT
				ACALL	BIN2DEC
				PUSH	00h
				MOV		R0,#34h
				ACALL	PRINTSTR
				POP		00h
				MOV		A,#0Dh
				ACALL	TXBYTE
				MOV		A,#0Ah
				ACALL	TXBYTE
				MOV		A,#03h
				ACALL	ADCONVERT
				DJNZ	R0,START1
				MOV		R1,#00h
				MOV		R2,#40h
START2:			DJNZ	R0,START2
				DJNZ	R1,START2
				DJNZ	R2,START2
				MOV		DPTR,#2000h
				RET

;LCD Output.
;-----------------------------------------------------
LCDDELAY:		PUSH	07h
				MOV		R7,#00h
				DJNZ	R7,$
				POP		07h
				RET

;A CONTAINS NIBBLE
LCDNIBOUT:		CLR		ACC.5				; | negative edge on E
				MOVX	@DPTR,A				; |
				SETB	ACC.5				; | E
				MOVX	@DPTR,A				; |
				CLR		ACC.5				; | negative edge on E
				MOVX	@DPTR,A				; |
				RET

;A CONTAINS BYTE
LCDCMDOUT:		PUSH	ACC
				SWAP	A					;High nibble first
				ANL		A,#0Fh
				CLR		ACC.4				;RS
				ACALL	LCDNIBOUT
				POP		ACC
				ANL		A,#0Fh
				CLR		ACC.4				;RS
				ACALL	LCDNIBOUT
				ACALL	LCDDELAY			; wait for BF to clear
				RET

;A CONTAINS BYTE
LCDCHROUT:		PUSH	DPL
				PUSH	DPH
				MOV		DPTR,#8000h
				PUSH	ACC
				SWAP	A					;High nibble first
				ANL		A,#0Fh
				SETB	ACC.4				;RS
				ACALL	LCDNIBOUT
				POP		ACC
				ANL		A,#0Fh
				SETB	ACC.4				;RS
				ACALL	LCDNIBOUT
				ACALL	LCDDELAY			; wait for BF to clear
				POP		DPH
				POP		DPL
				RET

LCDINIT:		PUSH	DPL
				PUSH	DPH
				MOV		DPTR,#8000h

				;Function set
				MOV		A,#00000010b
				ACALL	LCDNIBOUT
				ACALL	LCDDELAY			; wait for BF to clear

				;Function set
						  ;0010NFXX
				MOV		A,#00101000b
				CLR		C
				ACALL	LCDCMDOUT

				;Function set
						  ;0010NFXX
				MOV		A,#00100000b
				CLR		C
				ACALL	LCDCMDOUT

				;Display ON/OFF
						  ;00001DCB
				MOV		A,#00001110b
				CLR		C
				ACALL	LCDCMDOUT

				;Cursor direction
						  ;00000010
				MOV		A,#00000110b
				CLR		C
				ACALL	LCDCMDOUT

				POP		DPH
				POP		DPL
				RET

;AD Converter. A holds channel 0 to 7.
;-----------------------------------------------------
ADCONVERT:		PUSH	ACC
				PUSH	DPL
				PUSH	DPH
				PUSH	07h
				PUSH	06h
				SETB	ACC.4	;START
				SETB	ACC.3	;SINGLE ENDED
				RL		A
				RL		A
				RL		A
				XCH		A,R7
				CLR		ACC.0	;FRQ SEL
				CLR		ACC.1	;FRQ SEL
				SETB	ACC.2	;D2		FRQ GATE ACTIVE LOW
				SETB	ACC.3	;D3		FRQ	RESET ACTIVE HIGH
				SETB	ACC.4	;D4		ADC CS ACTIVE LOW
				SETB	ACC.5	;D5		ADC CLK HIGH TO LOW TRANSITION
				SETB	ACC.6	;D6		ADC DIN
				SETB	ACC.7	;D7
				MOV		DPTR,#8001h
				MOVX	@DPTR,A
				;CS low
				CLR		ACC.4	;D4		ADC CS ACTIVE LOW
				MOVX	@DPTR,A
				;Clock in channel select and Single/Diff+2 clocks for sample
				MOV		R6,#07h
ADCONVERT1:		XCH		A,R7
				RLC		A
				XCH		A,R7
				MOV		ACC.6,C	;ADC DIN
				CLR		ACC.5
				MOVX	@DPTR,A
				SETB	ACC.5
				MOVX	@DPTR,A
				DJNZ	R6,ADCONVERT1
				MOV		R7,#00h
				;Clock in 5 bits, including null bit
				MOV		R6,#05h
ADCONVERT2:		PUSH	ACC
				MOV		DPTR,#8000h
				MOVX	A,@DPTR
				RRC		A
				XCH		A,R7
				RLC		A
				XCH		A,R7
				MOV		DPTR,#8001h
				POP		ACC
				CLR		ACC.5
				MOVX	@DPTR,A
				SETB	ACC.5
				MOVX	@DPTR,A
				DJNZ	R6,ADCONVERT2
				
				PUSH	ACC
				MOV		A,R7
				ACALL	HEXOUT
				POP		ACC

				MOV		R7,#00h
				;Clock in 8 bits
				MOV		R6,#08h
ADCONVERT3:		MOVX	@DPTR,A
				PUSH	ACC
				MOV		DPTR,#8000h
				MOVX	A,@DPTR
				RRC		A
				XCH		A,R7
				RLC		A
				XCH		A,R7
				MOV		DPTR,#8001h
				POP		ACC
				CLR		ACC.5
				MOVX	@DPTR,A
				SETB	ACC.5
				DJNZ	R6,ADCONVERT3

				MOV		A,R7
				ACALL	HEXOUT
				MOV		A,#0Dh
				ACALL	TXBYTE
				MOV		A,#0Ah
				ACALL	TXBYTE

				POP		06h
				POP		07h
				POP		DPH
				POP		DPL
				POP		ACC
				RET

;Frequency counter. A holds channel 0 to 3.
;-----------------------------------------------------
FRQCOUNT:		PUSH	ACC
				PUSH	DPL
				PUSH	DPH
				SETB	ACC.2	;D2		FRQ GATE ACTIVE LOW
				SETB	ACC.3	;D3		FRQ	RESET ACTIVE HIGH
				SETB	ACC.4	;D4		ADC CS ACTIVE LOW
				SETB	ACC.5	;D5		ADC CLK HIGH TO LOW TRANSITION
				SETB	ACC.6	;D6		ADC DIN
				SETB	ACC.7	;D7
				MOV		DPTR,#8001h
				MOVX	@DPTR,A	;RESET AND GATE OFF
				PUSH	ACC
				MOV		TL0,#00h
				MOV		TH0,#00h
				MOV		A,TMOD
				SETB	ACC.0	;M00
				CLR		ACC.1	;M01
				SETB	ACC.2	;C/T0#
				CLR		ACC.3	;GATE0
				MOV		TMOD,A
				MOV		A,TCON
				SETB	ACC.4	;TR0
				CLR		ACC.5	;TF0
				MOV		TCON,A
				POP		ACC
				CLR		ACC.2	;D2		FRQ GATE ACTIVE LOW
				CLR		ACC.3	;D3		FRQ	RESET ACTIVE HIGH
				MOV		R7,#0FCh
				MOV		R6,#51
				MOV		R5,#16
				MOVX	@DPTR,A	;SELECT INTERNAL ALE,GATE ON(LOW),RESET INACTIVE
				;248+256*50+51=13104
				;(256*256)+256)*15+16=986896
FRQCOUNT1:		DJNZ	R7,FRQCOUNT1
				DJNZ	R6,FRQCOUNT1
				DJNZ	R5,FRQCOUNT1
				SETB	ACC.2	;D2		FRQ GATE ACTIVE LOW
				MOVX	@DPTR,A	;STOP COUNTING
				MOVX	A,@DPTR
				MOV		33h,A
				MOV		A,TL0
				MOV		32h,A
				MOV		A,TH0
				MOV		31h,A
				MOV		30h,#00h
				POP		DPH
				POP		DPL
				POP		ACC
				RET
;RS232 Output / Input
;-----------------------------------------------------
RXBYTE:			JNB		SCON.0,RXBYTE
				CLR		SCON.0
				MOV		A,SBUF
				RET

TXBYTE:			MOV		SBUF,A
TXBYTE1:		JNB		SCON.1,TXBYTE1
				CLR		SCON.1
				RET

PRINTSTR:		MOV		A,@R0
				JZ		PRINTSTR1
				ACALL	TXBYTE
				INC		R0
				SJMP	PRINTSTR
PRINTSTR1:		RET

HEXOUT:			PUSH	ACC
				SWAP	A
				ACALL	HEXOUT1
				POP		ACC
HEXOUT1:		ANL		A,#0Fh
				CLR		C
				SUBB	A,#0Ah
				JC		HEXOUT2
				ADD		A,#07h
HEXOUT2:		ADD		A,#3Ah
				ACALL	TXBYTE
				RET

;Binary to decimal converter
;------------------------------------------------------------------
BIN2DEC:		PUSH	DPL
				PUSH	DPH
				PUSH	00h
				PUSH	02h
				PUSH	03h
				PUSH	04h
				PUSH	05h
				PUSH	06h
				PUSH	07h
				MOV		R0,#30h				;32 Bit binary
				MOV		A,@R0
				MOV		R7,A
				INC		R0
				MOV		A,@R0
				MOV		R6,A
				INC		R0
				MOV		A,@R0
				MOV		R5,A
				INC		R0
				MOV		A,@R0
				MOV		R4,A
				MOV		R0,#34h				;Decimal buffer
				MOV		DPTR,#BINDEC
				MOV		R2,#0Ah
BIN2DEC1:		MOV		R3,#2Fh
BIN2DEC2:		INC		R3
				ACALL	SUBIT
				JNC		BIN2DEC2
				ACALL	ADDIT
				MOV		A,R3
				MOV		@R0,A
				INC		R0
				MOV		A,DPL
				ADD		A,#04h
				MOV		DPL,A
				DJNZ	R2,BIN2DEC1
				CLR		A
				MOV		@R0,A
				POP		07h
				POP		06h
				POP		05h
				POP		04h
				POP		03h
				POP		02h
				POP		00h
				POP		DPH
				POP		DPL
				RET

SUBIT:			MOV		A,#00h
				MOVC	A,@A+DPTR
				XCH		A,R4
				CLR		C
				SUBB	A,R4
				MOV		R4,A
				MOV		A,#01h
				MOVC	A,@A+DPTR
				XCH		A,R5
				SUBB	A,R5
				MOV		R5,A
				MOV		A,#02h
				MOVC	A,@A+DPTR
				XCH		A,R6
				SUBB	A,R6
				MOV		R6,A
				MOV		A,#03h
				MOVC	A,@A+DPTR
				XCH		A,R7
				SUBB	A,R7
				MOV		R7,A
				RET

ADDIT:			MOV		A,#00h
				MOVC	A,@A+DPTR
				ADD		A,R4
				MOV		R4,A
				MOV		A,#01h
				MOVC	A,@A+DPTR
				ADDC	A,R5
				MOV		R5,A
				MOV		A,#02h
				MOVC	A,@A+DPTR
				ADDC	A,R6
				MOV		R6,A
				MOV		A,#03h
				MOVC	A,@A+DPTR
				ADDC	A,R7
				MOV		R7,A
				RET

BINDEC:			DB 000h,0CAh,09Ah,03Bh			;1000000000
				DB 000h,0E1h,0F5h,005h			; 100000000
				DB 080h,096h,098h,000h			;  10000000
				DB 040h,042h,0Fh,0000h			;   1000000
				DB 0A0h,086h,001h,000h			;    100000
				DB 010h,027h,000h,000h			;     10000
				DB 0E8h,003h,000h,000h			;      1000
				DB 064h,000h,000h,000h			;       100
				DB 00Ah,000h,000h,000h			;        10
				DB 001h,000h,000h,000h			;         1

				END
