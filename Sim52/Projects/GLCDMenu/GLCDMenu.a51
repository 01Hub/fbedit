
; The processor clock speed is 24MHz.
; Cycle time is .500uS.
; Demo software to display a bit-mapped
; graphic on a 240x128 graphics display
; with a T6963C LCD controller.

PB_CD		BIT	P1.0
PB_R		BIT	P1.1
PB_W		BIT	P1.2
PB_RST		BIT	P1.3
P_DATA		EQU	P2
CHARSLINE	EQU	30
GRPHOME		EQU	0000h
TXTHOME		EQU	1000h
CGRHOME		EQU	2000h
LASTMNUSELX	EQU	40h
LASTMNUSELY	EQU	40h

		ORG	0000h
		LJMP	START		;program start

		ORG	0100h

START:		; Initialize the T6963C
		CLR	PB_RST		;hardware reset
		NOP
		NOP
		NOP
		NOP
		SETB	PB_RST
		MOV	DPTR,#MSGINIT	;initialization bytes
		ACALL	SENDCOMMANDS
		ACALL	CLS
		ACALL	SETCGRAM
		MOV	DPTR,#MENU1
		MOV	R6,#00h
		MOV	R7,#00h
		ACALL	PRINTMENU
		MOV	R5,#15
		MOV	R6,#1
		MOV	R7,#2
		ACALL	SELECTMENU
		SJMP	$

PRINTMENU:	CLR	A
		MOVC	A,@A+DPTR	;get byte
		INC	A
		JZ	PRINTMENUEX
		DEC	A
		PUSH	6
		PUSH	7
		ACALL	PRINTLINE
		POP	7
		POP	6
		INC	R7
		SJMP	PRINTMENU
PRINTMENUEX:	RET

SELECTMENU:	PUSH	5
		PUSH	6
		PUSH	7
		MOV	R6,LASTMNUSELX
		MOV	R7,LASTMNUSELY
		CLR	A
		ACALL	SETTEXTMODE
		POP	7
		POP	6
		POP	5
		MOV	LASTMNUSELX,R6
		MOV	LASTMNUSELY,R7
		MOV	A,#0Dh
		ACALL	SETTEXTMODE
		RET

;*************************************************

;Send bytes @DPTR as a series of commands, two data bytes and one command byte.
;Terminate if first data byte is 0FFh
SENDCOMMANDS:	CLR	A
		MOVC	A,@A+DPTR	;get byte
		INC	A
		JZ	SENDCOMMANDSEX
		DEC	A
		ACALL	WRITEDATA
		INC	DPTR
		CLR	A
		MOVC	A,@A+DPTR	;get byte
		INC	DPTR
		ACALL	WRITEDATA
		CLR	A
		MOVC	A,@A+DPTR	;get byte
		INC	DPTR
		ACALL	WRITECOMMAND
		SJMP	SENDCOMMANDS
SENDCOMMANDSEX:	RET

;Clear 32K ram
CLS:		MOV	DPTR,#MSGCLS	;Set ADP to 0000h and init auto write mode
		ACALL	SENDCOMMANDS
		MOV	R7,#80h
		MOV	R6,#00h
CLS1:		CLR	A
		ACALL	WRITEDATA
		DJNZ	R6,CLS1
		DJNZ	R7,CLS1
		MOV	A,#0B2h		;Auto Reset
		ACALL	WRITECOMMAND
		RET

SETCGRAM:	MOV	DPTR,#MSGCGRAM	;Set ADP to 2400h and init auto write mode
		ACALL	SENDCOMMANDS
		MOV	DPTR,#CGRAM
		MOV	R7,#8*6		;6 characters to be defined
SETCGRAM1:	CLR	A
		MOVC	A,@A+DPTR	;get byte
		INC	DPTR
		ACALL	WRITEDATA
		DJNZ	R7,SETCGRAM1
		MOV	A,#0B2h		;Auto Reset
		ACALL	WRITECOMMAND
		RET

;Convert text pos in R7:R6 to ram offset
POSTOADP:	MOV	B,#CHARSLINE	;Number of characters on each line
		MOV	A,R7
		MUL	AB
		ADD	A,R6
		MOV	R6,A
		MOV	A,B
		ADDC	A,#00h
		MOV	R7,A
		RET

;Line data @DPTR,R6 pos, R7 line
PRINTLINE:	ACALL	POSTOADP
		MOV	A,#LOW TXTHOME	;Add text home address
		ADD	A,R6
		MOV	R6,A
		MOV	A,#HIGH TXTHOME
		ADDC	A,R7
		MOV	R7,A
		MOV	A,R6		;ADP LSB
		ACALL	WRITEDATA
		MOV	A,R7		;ADP MSB
		ACALL	WRITEDATA
		MOV	A,#24h		;Set address pointer command
		ACALL	WRITECOMMAND
		MOV	A,#0B0h		;Set auto write mode
		ACALL	WRITECOMMAND
PRINTLINE1:	CLR	A
		MOVC	A,@A+DPTR	;get byte
		INC	DPTR
		INC	A
		JZ	PRINTLINEEX
		DEC	A
		ACALL	WRITEDATA
		SJMP	PRINTLINE1
PRINTLINEEX:	MOV	A,#0B2h		;Auto Reset
		ACALL	WRITECOMMAND
		RET

;R6 pos, R7 line, R5 number of characters, A mode
SETTEXTMODE:	PUSH	ACC
		ACALL	POSTOADP
		MOV	A,#LOW GRPHOME	;Add text home address
		ADD	A,R6
		MOV	R6,A
		MOV	A,#HIGH GRPHOME
		ADDC	A,R7
		MOV	R7,A
		MOV	A,R6		;ADP LSB
		ACALL	WRITEDATA
		MOV	A,R7		;ADP MSB
		ACALL	WRITEDATA
		MOV	A,#24h		;Set address pointer command
		ACALL	WRITECOMMAND
		MOV	A,#0B0h		;Set auto write mode
		ACALL	WRITECOMMAND
		POP	ACC
SETTEXTMODE1:	ACALL	WRITEDATA
		DJNZ	R5,SETTEXTMODE1
		MOV	A,#0B2h		;Auto Reset
		ACALL	WRITECOMMAND
		RET
		RET

; WRITECOMMAND sends the byte in A to a
; graphics module as a command.
WRITECOMMAND:	ACALL	STATUS		;display ready?
		SETB	PB_CD		;c/d = 1
		MOV	P_DATA,A	;set data
		CLR	PB_W		;strobe it
		SETB	PB_W
		RET

; WRITEDATA sends the byte in A to the
; graphics module as data.
WRITEDATA:	ACALL	STATUS		;display ready?
		CLR	PB_CD		;c/d = 0
		MOV	P_DATA,A	;set data
		CLR	PB_W		;strobe it
		SETB	PB_W
		RET

; STATUS check to see that the graphic
; display is ready. It won't return
; until it is.
STATUS:		PUSH	ACC
		SETB	PB_CD		;c/d=1
		MOV	P_DATA,#0FFh	;Port to input
		MOV	R3,#0Bh		;status bits mask
STATUS1:	CLR	PB_R		;read it
		MOV	A,P_DATA
		SETB	PB_R
		ANL	A,R3		;status OK?
		CLR	C
		SUBB	A,R3
		JNZ	STATUS1
		POP	ACC
		RET

; Initialization bytes for 240x128
MSGINIT:	DB	00h,10h,40h	;text home address
		DB	1Eh,00h,41h	;text area
		DB	00h,00h,42h	;graphic home address
		DB	1Eh,00h,43h	;graphic area
		DB	00h,00h,84h	;mode set. Text Attribute mode
		DB	04h,00h,22h	;offset register set, CG RAM area at 2000h to 27FFh
		DB	00h,00h,94h	;display mode set. Text on, Graphic off, Cursor off, Blink off
		DB	0FFh

MSGCLS:		DB	00h,00h,24h	;address pointer set
		DB	00h,00h,0B0h	;auto write mode
		DB	0FFh

MSGCGRAM:	DB	00h,24h,24h	;CG RAM address pointer set, character code 80h to 85h
		DB	00h,00h,0B0h	;auto write mode
		DB	0FFh

CGRAM:		;80h
		DB	000000b
		DB	000000b
		DB	000000b
		DB	001111b
		DB	001111b
		DB	001100b
		DB	001100b
		DB	001100b
		;81h
		DB	000000b
		DB	000000b
		DB	000000b
		DB	111111b
		DB	111111b
		DB	000000b
		DB	000000b
		DB	000000b
		;82h
		DB	000000b
		DB	000000b
		DB	000000b
		DB	111100b
		DB	111100b
		DB	001100b
		DB	001100b
		DB	001100b
		;83h
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001100b
		;84h
		DB	001100b
		DB	001100b
		DB	001100b
		DB	111100b
		DB	111100b
		DB	000000b
		DB	000000b
		DB	000000b
		;85h
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001111b
		DB	001111b
		DB	000000b
		DB	000000b
		DB	000000b

MENU1:		DB	024h,045h,056h,049h,043h,045h,000h,050h,052h,04Fh,047h,052h,041h,04Dh,04Dh,045h,052h,0FFh
		DB	080h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,082h,0FFh
		DB	083h,021h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,083h,0FFh
		DB	083h,022h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,083h,0FFh
		DB	083h,023h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,083h,0FFh
		DB	083h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,083h,0FFh
		DB	083h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,083h,0FFh
		DB	085h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,081h,084h,0FFh
		DB	0FFh

		END
