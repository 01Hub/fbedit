;*****************************************************
;Interrupt vectors.
;-----------------------------------------------------
;RESET			0000
;IE0			0003
;TF0			000B
;IE1			0013
;TF1			001B
;RI & TI		0023
;TF2 & EXF2		002B
;-----------------------------------------------------
;*****************************************************
;PORT 1
;-----------------------------------------------------
;P1.0			OUT:	+5V On	
;P1.1			OUT:	RST
;P1.2			OUT:	SCK
;P1.3			OUT:	MISO
;P1.4			IN:		MOSI
;P1.5
;P1.6
;P1.7
;-----------------------------------------------------
;*****************************************************
;RAM Locations
;-----------------------------------------------------
;20				Interrupt flags
;21
;22
;23
;24
;25				Rom byte to be verified
;26				Number of pages
;27				PROGROM Action
;28				PROGROM Size
;29             PROGROM Mode
;2A
;2B
;2C
;2D				DPL save
;2E				DPH save
;2F				Number of verify errors
;30-3F
;40-4F			Buffer
;50-7F			Stack
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
				ORG		0000
RESET:			AJMP	$START
;*****************************************************
				ORG		0003
IE0IRQ:			JB		$00,$01				;$20.0
				RETI
				LJMP	$2003
;*****************************************************
				ORG		000B
TF0IRQ:			JB		$01,$01				;$20.1
				RETI
				LJMP	$200B
;*****************************************************
				ORG		0013
IE1IRQ:			JB		$02,$01				;$20.2
				RETI
				LJMP	$2013
;*****************************************************
				ORG		001B
TF1IRQ:			JB		$03,$01				;$20.3
				RETI
				LJMP	$201B
;*****************************************************
				ORG		0023
RITIIRQ:		JB		$04,$01				;$20.4
				RETI
				LJMP	$2023
;*****************************************************
				ORG		002B
TF2EXF2IRQ:		JB		$05,$01				;$20.5
				RETI
				LJMP	$202B
;*****************************************************

				ORG		0040

START:			MOV		PSW,#00
				MOV		IE,#00				;Disable all int's
				MOV		SP,#4F				;Init stack pointer. The stack is 48 bytes
				MOV		TMOD,#22			;T0/T1=8 Bit auto reload
				MOV		TH0,#1A				;256-230
				MOV		TL0,#1A
				MOV		TH1,#0FD			;256-11059000/(384*9600) (#0FF=57600)
				MOV		TL1,#0FD
				MOV		PCON,#80			;Double baudrate
				MOV		SCON,#76			;Serial Port Mode 1 (8 Bit)
											;SM0=l
											;SM1=h
											;SM2=h
											;REN=h
											;TB8=h
											;RB8=l
											;TI=h
											;RI=l
				MOV		$20,#00				;RAM int routines ($00-$05,$20.0-$20.5)
				MOV		$27,#01				;Action
				MOV		$28,#01				;Size
				MOV		$29,#01				;Mode
				MOV		TCON,#50			;T0/T1=On
				MOV		R0,#00
				MOV		DPTR,#2000
				MOV		R1,#00
START1:			DJNZ	R0,$START1
				DJNZ	R1,$START1
				CLR		SCON.0
START2:			ACALL	$HELPMENU
START3:			ACALL	$PRNTCRLF
				MOV		A,#3E
				ACALL	$TXBYTE
START4:			ACALL	$RXBYTE
				CJNE	A,#41,$START5
				;Address input
				ACALL	$PRNTCMND
				ACALL	$ADRINPUT
				SJMP	$START3
START5:			CJNE	A,#44,$START6
				;Dump
				ACALL	$PRNTCMND
				ACALL	$DUMP
				SJMP	$START2
START6:			CJNE	A,#45,$START7
				;Enter hex
				ACALL	$PRNTCMND
				ACALL	$ENTERHEX
				SJMP	$START2
START7:			CJNE	A,#47,$START8
				;Go
				ACALL	$PRNTCMND
				ACALL	$GO
				SJMP	$START2
START8:			CJNE	A,#48,$START9
				;Help
				ACALL	$PRNTCMND
				SJMP	$START2
START9:			CJNE	A,#49,$START10
				;Internal memory
				ACALL	$PRNTCMND
				ACALL	$MEMDUMP
				SJMP	$START3
START10:		CJNE	A,#4C,$START11
				;Load
				ACALL	$PRNTCMND
				ACALL	$LOAD
				SJMP	$START3
START11:		CJNE	A,#50,$START12
				;Program ROM
				ACALL	$PRNTCMND
				ACALL	$EPROM
				SJMP	$START2
START12:		CJNE	A,#52,$START13
				;Run
				ACALL	$PRNTCMND
				ACALL	$RUN
				SJMP	$START2
START13:		CJNE	A,#0D,$START4
				;CR
				SJMP	$START3

;RS232 Functions
;------------------------------------------------------------------

PRNTSTR:		MOV		$2D,DPL
				MOV		$2E,DPH
				POP		DPH
				POP		DPL
PRNTSTR1:		CLR		A
				MOVC	A,@A+DPTR
				INC		DPTR
				JZ		$PRNTSTR2
				ACALL	$TXBYTE
				SJMP	$PRNTSTR1
PRNTSTR2:		PUSH	DPL
				PUSH	DPH
				MOV		DPL,$2D
				MOV		DPH,$2E
				RET

PRNTCMND:		ACALL	$TXBYTE
				ACALL	$PRNTCRLF
				RET

PRNTCRLF:		MOV		A,#0D
				ACALL	$TXBYTE
				MOV		A,#0A
				ACALL	$TXBYTE
				RET

HEXOUT:			PUSH	ACC
				SWAP	A
				ACALL	$HEXOUT1
				POP		ACC
HEXOUT1:		ANL		A,#0F
				CLR		C
				SUBB	A,#0A
				JC		$HEXOUT2
				ADD		A,#07
HEXOUT2:		ADD		A,#3A
				ACALL	$TXBYTE
				RET

HEXDPTR:		MOV		A,DPH
				ACALL	$HEXOUT
				MOV		A,DPL
				ACALL	$HEXOUT
				MOV		A,#20
				ACALL	$TXBYTE
				RET

HEXINPBYTE:		ACALL	$HEXINP
				JC		$HEXINPBYTE1
				SWAP	A
				MOV		R3,A
				ACALL	$HEXINP
				JC		$HEXINPBYTE1
				ADD		A,R3
HEXINPBYTE1:	RET

HEXINP:			ACALL	$HEXINP2
				JC		$HEXINP1
				PUSH	ACC
				MOV		A,R2
				ACALL	$TXBYTE
				POP		ACC
HEXINP1:		RET

HEXINP2:		ACALL	$RXBYTE
				CJNE	A,#9F,$HEXINP3		;Esc
				SETB	C
				RET
HEXINP3:		CJNE	A,#0D,$HEXINP4		;Cr
				SETB	C
				RET
HEXINP4:		MOV		R2,A
				CJNE	A,#3A,$00
				JNC		$HEXINP5
				CJNE	A,#30,$00
				JC		$HEXINP2
				SUBB	A,#30
				RET
HEXINP5:		CJNE	A,#47,$00
				JNC		$HEXINP2
				CJNE	A,#41,$00
				JC		$HEXINP2
				SUBB	A,#37
				RET

INPDPTR:		ACALL	$HEXDPTR
				ACALL	$HEXINPBYTE
				JC		$INPDPTR1
				MOV		DPH,A
				ACALL	$HEXINPBYTE
				JC		$INPDPTR1
				MOV		DPL,A
INPDPTR1:		ACALL	$PRNTCRLF
				RET

RX16BYTES:		PUSH	$01
				MOV		A,#05
				ACALL	$TXBYTE
				MOV		R0,#40
				MOV		R1,#10
RX16BYTES1:		ACALL	$RXBYTE
				MOV		@R0,A
				INC		R0
				DJNZ	R1,$RX16BYTES1
				POP		$01
				MOV		R0,#40
				RET

RXBYTE:			JNB		SCON.0,$RXBYTE
				CLR		SCON.0
				MOV		A,SBUF
				RET

TXBYTE:			JNB		SCON.1,$TXBYTE
				CLR		SCON.1
				MOV		SBUF,A
				RET

;Functions
;------------------------------------------------------------------

HELPMENU:		ACALL	$PRNTSTR
				DB		0E
				DB		'A Address input',0D,0A
				DB		'D Dump as hex',0D,0A
				DB		'E Enter hex',0D,0A
				DB		'G Go (Load and Run)',0D,0A
				DB		'H Help',0D,0A
				DB		'I Internal memory dump',0D,0A
				DB		'L Load cmd file',0D,0A
				DB		'P Program ROM',0D,0A
				DB		'R Run',0D,0A,00
				RET

ADRINPUT:		ACALL	$INPDPTR
				RET

DUMP:			PUSH	DPL
				PUSH	DPH
				PUSH	$02
				PUSH	$03
DUMP1:			MOV		R3,#10
DUMP2:			MOV		R2,#10
				ACALL	$HEXDPTR
DUMP3:			MOVX	A,@DPTR
				ACALL	$HEXOUT
				MOV		A,#20
				ACALL	$TXBYTE
				INC		DPTR
				DJNZ	R2,$DUMP3
				ACALL	$PRNTCRLF
				DJNZ	R3,$DUMP2
				ACALL	$PRNTCRLF
				ACALL	$RXBYTE
				CJNE	A,#9F,$DUMP1			;Esc
				POP		$03
				POP		$02
				POP		DPH
				POP		DPL
				RET

ENTERHEX:		PUSH	DPL
				PUSH	DPH
ENTERHEX1:		ACALL	$HEXDPTR
				ACALL	$HEXINPBYTE
				JC		$ENTERHEX2
				MOVX	@DPTR,A
				INC		DPTR
				ACALL	$PRNTCRLF
				SJMP	$ENTERHEX1
ENTERHEX2:		POP		DPH
				POP		DPL
				RET

MEMDUMP:		PUSH	$00
				MOV		R0,#00
MEMDUMP1:		CLR		A
				ACALL	$HEXOUT
				MOV		A,R0
				ACALL	$HEXOUT
				MOV		A,#20
				ACALL	$TXBYTE
MEMDUMP2:		MOV		A,@R0
				ACALL	$HEXOUT
				MOV		A,#20
				ACALL	$TXBYTE
				INC		R0
				MOV		A,R0
				ANL		A,#0F
				JNZ		$MEMDUMP2
				ACALL	$PRNTCRLF
				MOV		A,R0
				XRL		A,#80
				JNZ		$MEMDUMP1
				POP		$00
				RET

LOAD:			PUSH	DPL
				PUSH	DPH
				PUSH	$00
				PUSH	$03
				MOV		R3,#80
LOAD1:			ACALL	$RX16BYTES				;Read 16 bytes from cmd file
				ACALL	$HEXDPTR
LOAD2:			MOV		A,@R0
				MOVX	@DPTR,A
				ACALL	$HEXOUT
				MOV		A,#20
				ACALL	$TXBYTE
				INC		DPTR
				INC		R0
				MOV		A,R0
				XRL		A,#50
				JNZ		$LOAD2					;Not 16 bytes yet
				ACALL	$PRNTCRLF
				DJNZ	R3,$LOAD1				;Not 2K yet
				MOV		A,#06
				ACALL	$TXBYTE					;End read 16 bytes from cmd file
				POP		$03
				POP		$00
				POP		DPH
				POP		DPL
				RET

GO:				ACALL	$LOAD
RUN:			CLR		A
				JMP		@A+DPTR

;ROM menu selection
;------------------------------------------------------------------

EPROM:			ACALL	$ROMMENU
				CJNE	A,#94,$EPROMEXIT
				ACALL	$ROMINSERT
				JC		$EPROM
				LCALL	$ROMINIT				;Turn on VCC, pull RST high and init programming mode
				JC		$EPROM					;Initialisation failed
				MOV		A,$27
				DEC		A
				JNZ		$EPROM2
				;Test erased
				ACALL	$ROMWAIT
				MOV		A,$29
				DEC		A
				JNZ		$EPROM1
				ACALL	$BM_ROMERASED
				SJMP	$EPROM
EPROM1:			ACALL	$PM_ROMERASED
				SJMP	$EPROM
EPROM2:			DEC		A
				JNZ		$EPROM3
				;Dump to hex file
				ACALL	$ROMWAIT
				MOV		A,$29
				DEC		A
				JNZ		$EPROM21
				ACALL	$BM_ROMDUMPF
				SJMP	$EPROM
EPROM21:		ACALL	$PM_ROMDUMPF
				SJMP	$EPROM
EPROM3:			DEC		A
				JNZ		$EPROM4
				;Dump to screen
				MOV		A,$29
				DEC		A
				JNZ		$EPROM31
				ACALL	$BM_ROMDUMPS
				SJMP	$EPROM
EPROM31:		ACALL	$PM_ROMDUMPS
				SJMP	$EPROM
EPROM4:			DEC		A
				JNZ		$EPROM5
				;Verify
				ACALL	$ROMWAIT
				MOV		A,$29
				DEC		A
				JNZ		$EPROM41
				ACALL	$BM_ROMVERIFY
				SJMP	$EPROM
EPROM41:		LCALL	$PM_ROMVERIFY
				SJMP	$EPROM
EPROM5:			;Program
				ACALL	$ROMWAIT
				MOV		A,$29
				DEC		A
				JNZ		$EPROM51
				ACALL	$BM_ROMPROG
				SJMP	$EPROM
EPROM51:		LCALL	$PM_ROMPROG
				SJMP	$EPROM
EPROMEXIT:		RET

ROMMENU:		ACALL	$PRNTSTR
				DB		0E
				DB		'   ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿  ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿  ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',0D,0A
				DB		'   ³  Action       ³  ³  EEPROM size  ³  ³  Mode         ³',0D,0A
				DB		'   ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´  ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´  ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',0D,0A
				DB		'   ³  Test erased  ³  ³  4K           ³  ³  Byte         ³',0D,0A
				DB		'   ³  Filedump     ³  ³  8K           ³  ³  Page         ³',0D,0A
				DB		'   ³  Screendump   ³  ³  16K          ³  ³               ³',0D,0A
				DB		'   ³  Verify       ³  ³  32K          ³  ³               ³',0D,0A
				DB		'   ³  Program      ³  ³  64K          ³  ³               ³',0D,0A
				DB		'   ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',0D,0A
				DB		00
				MOV		R0,#28
				ACALL	$MENUSET
				INC		R0
				ACALL	$MENUSET
				MOV		R0,#27
				ACALL	$MENUXP
				RET

MENUXP:			ACALL	$MENUSET
				MOV		A,#08
				LCALL	$TXBYTE
				LCALL	$RXBYTE
				CJNE	A,#9A,$MENUXP1
				MOV		A,@R0
				DEC		A
				JZ		$MENUXP
				MOV		A,#20
				LCALL	$TXBYTE
				DEC		@R0
				SJMP	$MENUXP
MENUXP1:		CJNE	A,#9B,$MENUXP2
				MOV		A,@R0
				SUBB	A,#05
				JZ		$MENUXP
				MOV		A,#20
				LCALL	$TXBYTE
				INC		@R0
				SJMP	$MENUXP
MENUXP2:		CJNE	A,#9C,$MENUYP1
				MOV		A,R0
				SUBB	A,#29
				JZ		$MENUXP
				INC		R0
				SJMP	$MENUXP
MENUYP1:		CJNE	A,#9D,$MENUYP2
				MOV		A,R0
				SUBB	A,#27
				JZ		$MENUXP
				DEC		R0
				SJMP	$MENUXP
MENUYP2:		CJNE	A,#9F,$MENUYP3			;Esc
				RET
MENUYP3:		CJNE	A,#94,$MENUXP			;Insert
				RET

MENUSET:		MOV		A,#0B
				LCALL	$TXBYTE
				MOV		A,@R0
				ADD		A,#22
				LCALL	$TXBYTE
				MOV		A,R0
				SUBB	A,#27
				MOV		B,#13
				MUL		AB
				ADD		A,#24
				LCALL	$TXBYTE
				MOV		A,#0FB					;û
				LCALL	$TXBYTE
				RET

;------------------------------------------------------------------

ROMINSERT:		LCALL	$ROMOFF
				ACALL	$PRNTSTR
				DB		0B,2A,23,'Insert ',00
				MOV		A,$28
				DEC		A
				JNZ		$ROMINSERT1
				ACALL	$PRNTSTR
				DB		'4K',00
				MOV		$26,#10					;16 Pages
ROMINSERT1:		DEC		A
				JNZ		$ROMINSERT2
				ACALL	$PRNTSTR
				DB		'8K',00
				MOV		$26,#20					;32 Pages
ROMINSERT2:		DEC		A
				JNZ		$ROMINSERT3
				ACALL	$PRNTSTR
				DB		'16K',00
				MOV		$26,#40					;64 Pages
ROMINSERT3:		DEC		A
				JNZ		$ROMINSERT4
				ACALL	$PRNTSTR
				DB		'32K',00
				MOV		$26,#80					;128 Pages
ROMINSERT4:		DEC		A
				JNZ		$ROMINSERT5
				ACALL	$PRNTSTR
				DB		'64K',00
				MOV		$26,#00					;256 Pages
ROMINSERT5:		ACALL	$PRNTSTR
				DB		' device and strike <Enter> ',00
				ACALL	$RXBYTE
				CJNE	A,#9F,$ROMINSERT6		;Esc
				SETB	C
				RET
ROMINSERT6:		ACALL	$PRNTSTR
				DB		0B,2A,23,'                                       '
				DB		0D,00
				CLR		C
				RET

ROMWAIT:		ACALL	$PRNTSTR
				DB		0B,2A,23,'Wait ...',00
				RET


;Byte mode
;------------------------------------------------------------------

BM_ROMERASED:	LCALL	$BM_ROMRDBYTE			;Read a byte from ROM
				CJNE	A,#0FF,$BM_ROMERASED1	;Not erased
				INC		DPTR					;Next address
				MOV		A,DPL
				JNZ		$BM_ROMERASED			;Jump if more bytes in this page
				MOV		A,DPH
				CJNE	A,$26,$BM_ROMERASED		;Jump if more pages
				LCALL	$ROMOFF					;Set RST low and turn off VCC
				RET
BM_ROMERASED1:	LCALL	$ROMOFF					;Set RST low and turn off VCC
				ACALL	$PRNTSTR
				DB		0B,2A,23,'Byte at ',00
				MOV		A,DPH
				ACALL	$HEXOUT					;High address
				MOV		A,DPL
				ACALL	$HEXOUT					;Low address
				ACALL	$PRNTSTR
				DB		' not erased <Enter> ',00
				ACALL	$RXBYTE					;Wait for keypress
				RET

BM_ROMDUMPF:	MOV		A,#03
				ACALL	$TXBYTE					;Init write to file
BM_ROMDUMPF1:	LCALL	$BM_ROMRDBYTE			;Read a byte from ROM
				ACALL	$HEXOUT					;Output as hex
				MOV		A,#20
				ACALL	$TXBYTE					;Output a space
				INC		DPTR
				MOV		A,DPL
				ANL		A,#0F
				JNZ		$BM_ROMDUMPF2			;Still on same line
				ACALL	$PRNTCRLF				;Output CRLF
BM_ROMDUMPF2:	MOV		A,DPL
				JNZ		$BM_ROMDUMPF1			;Jump if more bytes in this page
				MOV		A,DPH
				CJNE	A,$26,$BM_ROMDUMPF1		;Jump if more pages
				MOV		A,#04
				ACALL	$TXBYTE					;End write to file
				LCALL	$ROMOFF					;Set RST low and turn off VCC
BM_ROMDUMPF3:	RET

BM_ROMDUMPS:	LCALL	$BM_ROMRDBYTE			;Read a byte from ROM
				ACALL	$HEXOUT					;Output as hex
				MOV		A,#20
				ACALL	$TXBYTE					;Output a space
				INC		DPTR					;Next ROM address
				MOV		A,DPL
				ANL		A,#0F
				JNZ		$BM_ROMDUMPS1			;Jump if still on same line
				ACALL	$PRNTCRLF				;Output CRLF
BM_ROMDUMPS1:	MOV		A,DPL
				JNZ		$BM_ROMDUMPS			;Jump if more bytes in this page
				ACALL	$PRNTCRLF				;Output CRLF
				ACALL	$RXBYTE					;Wait for a keypress
				CJNE	A,#9F,$BM_ROMDUMPS2
				SJMP	$BM_ROMDUMPS3
BM_ROMDUMPS2:	MOV		A,DPH
				CJNE	A,$26,$BM_ROMDUMPS		;Jump if more pages
BM_ROMDUMPS3:	LCALL	$ROMOFF					;Set RST low and turn off VCC
				RET

BM_ROMVERIFY:	PUSH	$00						;Save R0
				MOV		$2F,#00					;Number of errors
				ACALL	$RX16BYTES				;Read 16 bytes from cmd file. R0 points to start of 16 byte buffer
BM_ROMVERIFY1:	MOV		$25,@R0					;Get byte from buffer
				LCALL	$BM_ROMRDBYTE			;Read a byte from ROM
				CJNE	A,$25,$BM_ROMVERIFY4	;Compare and jump if not equal
BM_ROMVERIFY2:	INC		R0						;Increment buffer pointer
				MOV		A,R0
				CJNE	A,#50,$BM_ROMVERIFY3	;Jump if not last byte in buffer
				ACALL	$RX16BYTES				;Read 16 bytes from cmd file. R0 points to start of 16 byte buffer
BM_ROMVERIFY3:	INC		DPTR					;Next ROM address
				MOV		A,DPL
				JNZ		$BM_ROMVERIFY1			;Jump if still on same page
				MOV		A,DPH
				CJNE	A,$26,$BM_ROMVERIFY1	;Jump if more pages
				LCALL	$ROMOFF					;Set RST low and turn off VCC
				MOV		A,#06
				ACALL	$TXBYTE					;End read 16 bytes from cmd file
				POP		$00						;Restore R0
				RET
BM_ROMVERIFY4:	LCALL	$ROMVERIFYERR
				JNC		$BM_ROMVERIFY2			;Jump if less than 16 errors
				LCALL	$ROMOFF					;Set RST low and turn off VCC
				MOV		A,#06
				ACALL	$TXBYTE					;End read 16 bytes from cmd file
				ACALL	$RXBYTE					;Wait for a keypress
				POP		$00						;Restore R0
				RET

BM_ROMPROG:
				RET

;Page mode
;------------------------------------------------------------------

PM_ROMERASED:	MOV		A,#30
				LCALL	$ISPCOMM				;Init read page mode
				MOV		A,DPH
				LCALL	$ISPCOMM				;Send high address
PM_ROMERASED1:	CLR		A
				LCALL	$ISPCOMM				;Get byte from ROM
				CJNE	A,#0FF,$PM_ROMERASED2	;Jump if not erased
				INC		DPTR
				MOV		A,DPL
				JNZ		$PM_ROMERASED1			;Jump if more bytes on this page
				MOV		A,DPH
				CJNE	A,$26,$PM_ROMERASED		;Jump if more pagees
				LCALL	$ROMOFF					;Set RST low and turn off VCC
				RET
PM_ROMERASED2:	LCALL	$ROMOFF					;Set RST low and turn off VCC
				ACALL	$PRNTSTR
				DB		0B,2A,23,'Byte at ',00
				MOV		A,DPH
				ACALL	$HEXOUT					;Output high address as hex
				MOV		A,DPL
				ACALL	$HEXOUT					;Output low address as hex
				ACALL	$PRNTSTR
				DB		' not erased <Enter> ',00
				ACALL	$RXBYTE					;Wait for a keypress
				RET

PM_ROMDUMPF:	MOV		A,#03
				ACALL	$TXBYTE					;Init Output to hex file
PM_ROMDUMPF1:	MOV		A,#30
				LCALL	$ISPCOMM				;Init read page mode
				MOV		A,DPH
				LCALL	$ISPCOMM				;Send high address
PM_ROMDUMPF2:	CLR		A
				LCALL	$ISPCOMM				;Get byte from ROM
				ACALL	$HEXOUT					;Output as hex
				MOV		A,#20
				ACALL	$TXBYTE					;Output a space
				INC		DPTR
				MOV		A,DPL
				ANL		A,#0F
				CJNE	A,#00,$PM_ROMDUMPF3		;Jump if more bytes in this line
				ACALL	$PRNTCRLF				;Output CRLF
				MOV		A,DPL
				JNZ		$PM_ROMDUMPF2			;Jump if more bytes in this page
PM_ROMDUMPF3:	MOV		A,DPH
				CJNE	A,$26,$PM_ROMDUMPF1		;Jump if more pages
				MOV		A,#04
				ACALL	$TXBYTE					;End Output to hex file
				LCALL	$ROMOFF					;Set RST low and turn off VCC
				RET

PM_ROMDUMPS:	MOV		A,#30
				LCALL	$ISPCOMM				;Init read page mode
				MOV		A,DPH
				LCALL	$ISPCOMM				;Send high address
PM_ROMDUMPS1:	CLR		A
				LCALL	$ISPCOMM				;Get byte from ROM
				ACALL	$HEXOUT					;Output as hex
				MOV		A,#20
				ACALL	$TXBYTE					;Output a space
				INC		DPTR
				MOV		A,DPL
				ANL		A,#0F
				JNZ		$PM_ROMDUMPS2			;Jump if still on same line
				ACALL	$PRNTCRLF				;Output CRLF
				MOV		A,DPL
				JNZ		$PM_ROMDUMPS1			;Jump if more bytes on this page
				ACALL	$PRNTCRLF				;Output CRLF
				ACALL	$RXBYTE					;Wait for a keypress
				CJNE	A,#9F,$PM_ROMDUMPS2
				SJMP	$PM_ROMDUMPS3			;Esc pressed
PM_ROMDUMPS2:	MOV		A,DPH
				CJNE	A,$26,$PM_ROMDUMPS		;Jump if more pages
PM_ROMDUMPS3:	LCALL	$ROMOFF					;Set RST low and turn off VCC
				RET

PM_ROMVERIFY:	PUSH	$00						;Save R0
				MOV		$2F,#00					;Number of errors
				LCALL	$RX16BYTES				;Read 16 bytes from cmd file. R0 points to start of 16 byte buffer
PM_ROMVERIFY1:	MOV		A,#30
				LCALL	$ISPCOMM				;Init read page mode
				MOV		A,DPH
				LCALL	$ISPCOMM				;Send high address
PM_ROMVERIFY2:	MOV		$25,@R0					;Get byte from buffer
				CLR		A
				LCALL	$ISPCOMM				;Get byte from ROM
				CJNE	A,$25,$PM_ROMVERIFY5	;Compare and jump if not equal
PM_ROMVERIFY3:	INC		R0						;Increment buffer pointer
				MOV		A,R0
				CJNE	A,#50,$PM_ROMVERIFY4	;Jump if not last byte in buffer
				LCALL	$RX16BYTES				;Read 16 bytes from cmd file. R0 points to start of 16 byte buffer
PM_ROMVERIFY4:	INC		DPTR
				MOV		A,DPL
				JNZ		$PM_ROMVERIFY2			;Jump if still on same page
				MOV		A,DPH
				CJNE	A,$26,$PM_ROMVERIFY1	;Jump if more pages
				LCALL	$ROMOFF					;Set RST low and turn off VCC
				MOV		A,#06
				LCALL	$TXBYTE					;End read 16 bytes from cmd file
				POP		$00						;Restore R0
				RET
PM_ROMVERIFY5:	LCALL	$ROMVERIFYERR
				JNC		$PM_ROMVERIFY3			;Jump if less than 16 errors
				LCALL	$ROMOFF					;Set RST low and turn off VCC
				MOV		A,#06
				LCALL	$TXBYTE					;End read 16 bytes from cmd file
				LCALL	$RXBYTE					;Wait for keypress
				POP		$00						;Restore R0
				RET

PM_ISERASED:	MOV		DPTR,#0000
				MOV		$2F,#00
PM_ISERASED1:	MOV		A,#30
				LCALL	$ISPCOMM				;Init read page mode
				MOV		A,DPH
				LCALL	$ISPCOMM				;Send high address
PM_ISERASED2:	CLR		A
				LCALL	$ISPCOMM				;Get byte from ROM
				INC		A
				ORL		$2F,A
				INC		DPTR
				MOV		A,DPL
				JNZ		$PM_ISERASED2			;Jump if more bytes on this page
				MOV		A,$2F
				JNZ		$PM_ISERASED3
				MOV		A,DPH
				CJNE	A,$26,$PM_ISERASED1		;Jump if more pagees
PM_ISERASED3:	CLR		C
				MOV		A,$2F
				JZ		$PM_ISERASED4
				SETB	C
PM_ISERASED4:	RET

PM_ROMPROG:		LCALL	$PM_ISERASED			;Check if chip is erased
				JNC		$PM_ROMPROG1
				MOV		A,#0AC
				LCALL	$ISPCOMM				;Init chip erase byte 1
				MOV		A,#80
				LCALL	$ISPCOMM				;Init chip erase byte 2
				CLR		A
				LCALL	$ISPCOMM				;Init chip erase byte 3
				CLR		A
				LCALL	$ISPCOMM				;Init chip erase byte 4
				CLR		A
				LCALL	$WAIT					;Wait 256 ms
				CLR		A
				LCALL	$WAIT					;Wait 256 ms
				CLR		A
				LCALL	$WAIT					;Wait 256 ms
				LCALL	$PM_ISERASED
				JNC		$PM_ROMPROG1
				LCALL	$ROMOFF					;Set RST low and turn off VCC
				LCALL	$PRNTSTR
				DB		0B,2A,23,'Could not erase chip <Enter> ',00
				LCALL	$RXBYTE					;Wait for keypress
				RET
PM_ROMPROG1:	PUSH	$00
				MOV		DPTR,#0000
				LCALL	$RX16BYTES				;Read 16 bytes from cmd file. R0 points to start of 16 byte buffer
PM_ROMPROG2:	MOV		A,#40
				LCALL	$ISPCOMM				;Init byte programming mode
				MOV		A,DPH
				LCALL	$ISPCOMM				;Send high address
				MOV		A,DPL
				LCALL	$ISPCOMM				;Send low address
				MOV		A,@R0
				MOV		$25,A					;Get byte from buffer
				LCALL	$ISPCOMM				;Send byte to be programmed
				MOV		A,#10
				LCALL	$WAIT					;Wait 1mS
				LCALL	$BM_ROMRDBYTE			;Read a byte from ROM
				CJNE	A,$25,$PM_ROMPROG4		;Compare and jump if not equal
				INC		R0
				MOV		A,R0
				CJNE	A,#50,$PM_ROMPROG3
				LCALL	$RX16BYTES				;Read 16 bytes from cmd file. R0 points to start of 16 byte buffer
PM_ROMPROG3:	INC		DPTR
				MOV		A,DPL
				JNZ		$PM_ROMPROG2			;Jump if still on same page
				MOV		A,#2E
				LCALL	$TXBYTE
				MOV		A,DPH
				CJNE	A,$26,$PM_ROMPROG2		;Jump if more pages
				LCALL	$ROMOFF					;Set RST low and turn off VCC
				MOV		A,#06
				LCALL	$TXBYTE					;End read 16 bytes from cmd file
				POP		$00
				RET
PM_ROMPROG4:	PUSH	ACC
				LCALL	$ROMOFF					;Set RST low and turn off VCC
				MOV		A,#06
				LCALL	$TXBYTE					;End read 16 bytes from cmd file
				LCALL	$PRNTSTR
				DB		0B,2A,23,'Error at ',00
				MOV		A,DPH
				LCALL	$HEXOUT					;High address
				MOV		A,DPL
				LCALL	$HEXOUT					;Low address
				MOV		A,#20
				LCALL	$TXBYTE
				MOV		A,$25
				LCALL	$HEXOUT					;Byte from .cmd file
				MOV		A,#20
				LCALL	$TXBYTE
				POP		ACC
				LCALL	$HEXOUT					;Byte read from ROM
				LCALL	$RXBYTE					;Wait for a keypress
				POP		$00						;Restore R0
				RET

;Wait functions
;------------------------------------------------------------------

WAIT100:		PUSH	$07						;Save R7
				MOV		R7,#2E
WAIT1001:		DJNZ	R7,$WAIT1001			;Wait loop, 100uS
				POP		$07						;Restore R7
				RET

WAIT:			XCH		A,R7
WAIT1:			ACALL	$WAIT100
				DJNZ	R7,$WAIT1
				XCH		A,R7
				RET

;Control functions
;------------------------------------------------------------------

;IN A, OUT A
ISPCOMM:		PUSH	$07
				PUSH	$02
				MOV		R2,#08
ISPCOMM1:		RLC		A
				MOV		P1.3,C					;MISO
				MOV		C,P1.4					;MOSI
				XCH		A,R7
				RLC		A
				XCH		A,R7
				SETB	P1.2					;SCK H
				CLR		P1.2					;SCK L
				DJNZ	R2,$ISPCOMM1
				MOV		A,R7
				POP		$02
				POP		$07
				RET

ROMON:			SETB	P1.0					;+5V On
				MOV		A,#0A
				ACALL	$WAIT					;Wait 1mS
				SETB	P1.1					;RST H
				MOV		A,#0A
				ACALL	$WAIT					;Wait 1mS
				RET

ROMOFF:			CLR		P1.1					;RST L
				MOV		A,#01
				ACALL	$WAIT					;Wait 100uS
				MOV		P1,#10					;+5V Off, P1.4 As Input
				MOV		A,#0A
				LCALL	$WAIT					;Wait 1mS
				RET

ROMINITPGM:		MOV		A,#0AC
				LCALL	$ISPCOMM
				MOV		A,#53
				LCALL	$ISPCOMM
				MOV		A,#00
				LCALL	$ISPCOMM
				MOV		A,#00
				LCALL	$ISPCOMM
				CJNE	A,#69,$ROMINITPGM1
				RET
ROMINITPGM1:	LCALL	$PRNTSTR
				DB		0B,2A,23,'Initialisation Error <Enter> ',00
				LCALL	$RXBYTE
				SETB	C
				RET

ROMINIT:		MOV		DPTR,#0000				;DPTR holds ROM address
				LCALL	$ROMON					;Turn on VCC and pull RST high
				LCALL	$ROMINITPGM
				JNC		$ROMINIT1
				LCALL	$ROMOFF					;Init programming failed
				SETB	C
ROMINIT1:		RET

BM_ROMRDBYTE:	MOV		A,#20
				LCALL	$ISPCOMM
				MOV		A,DPH
				LCALL	$ISPCOMM
				MOV		A,DPL
				LCALL	$ISPCOMM
				MOV		A,#00
				LCALL	$ISPCOMM
				RET

ROMVERIFYERR:	PUSH	ACC
				LCALL	$PRNTSTR
				DB		0D,'   Error at ',00
				MOV		A,DPH
				LCALL	$HEXOUT
				MOV		A,DPL
				LCALL	$HEXOUT
				MOV		A,#20
				LCALL	$TXBYTE
				MOV		A,$25
				LCALL	$HEXOUT
				MOV		A,#20
				LCALL	$TXBYTE
				POP		ACC
				LCALL	$HEXOUT
				LCALL	$PRNTCRLF
				INC		$2F
				MOV		A,$2F
				CJNE	A,#10,$00
				CPL		C
				RET

;------------------------------------------------------------------

				ORG		2000					;Fill up 2764
