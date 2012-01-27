
; The processor clock speed is 24MHz.
; Cycle time is .500uS.
; Demo software to display a menu
; on a 240x128 graphics LCD display
; with a T6963C LCD controller.

PB_CD		BIT	P1.0
PB_R		BIT	P1.1
PB_W		BIT	P1.2
PB_RST		BIT	P1.3
P_DATA		EQU	P2
CHARSLINE	EQU	40
GRPHOME		EQU	0000h
TXTHOME		EQU	1000h
CGRHOME		EQU	2000h

MNUDEF		EQU	40h
NMNUDEF		EQU	10
MNUSEL		EQU	MNUDEF+0
MNUOFS		EQU	MNUDEF+1
MNUX		EQU	MNUDEF+2
MNUY		EQU	MNUDEF+3
MNUWT		EQU	MNUDEF+4
MNUHT		EQU	MNUDEF+5
MNUITEMWT	EQU	MNUDEF+6
MNUITEMS	EQU	MNUDEF+7
MNUTXTL		EQU	MNUDEF+8
MNUTXTH		EQU	MNUDEF+9
LASTKEY		EQU	MNUDEF+10

MNUX1		EQU	0
MNUY1		EQU	1
MNUWT1		EQU	10
MNUHT1		EQU	5

		ORG	0000h
		AJMP	START		;program start

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
		MOV	R6,#0
		MOV	R7,#0
		MOV	DPTR,#HEADER
		ACALL	PRINTLINE
		MOV	DPTR,#MNUDEF1
		ACALL	MNUINIT
		ACALL	MNUPRINT
START1:		ACALL	GETKEY
		JZ	START1
		CJNE	A,#01h,START3
		;Up
		MOV	A,MNUSEL
		JZ	START1
		ACALL	MNUCLRSEL
		DEC	MNUSEL
		MOV	A,MNUSEL
		CJNE	A,MNUOFS,$+3
		JNC	START2
		DEC	MNUOFS
		ACALL	MNUTXT
		ACALL	MNUSCROLL
START2:		ACALL	MNUSETSEL
START3:		CJNE	A,#02h,START5
		;Down
		MOV	A,MNUSEL
		INC	A
		CLR	C
		SUBB	A,MNUITEMS
		JZ	START1
		ACALL	MNUCLRSEL
		INC	MNUSEL
		MOV	A,MNUSEL
		CLR	C
		SUBB	A,MNUOFS
		CJNE	A,MNUHT,$+3
		JC	START4
		INC	MNUOFS
		ACALL	MNUTXT
		ACALL	MNUSCROLL
START4:		ACALL	MNUSETSEL
START5:		SJMP	START1

GETKEY:		MOV	R7,#00h
		MOV	A,P1
		ANL	A,#0F0h
		XRL	A,#0F0h
		JZ	GETKEY2
		MOV	R7,#04h
GETKEY1:	RLC	A
		JC	GETKEY2
		DEC	R7
		SJMP	GETKEY1
GETKEY2:	MOV	A,R7
		CJNE	A,LASTKEY,GETKEY3
		CLR	A
		RET
GETKEY3:	MOV	LASTKEY,A
		RET

MNUINIT:	MOV	R7,#NMNUDEF
		MOV	R0,#MNUDEF
MNUINIT1:	CLR	A
		MOVC	A,@A+DPTR	;get byte
		MOV	@R0,A
		INC	DPTR
		INC	R0
		DJNZ	R7,MNUINIT1
		RET

MNUPRINT:	ACALL	MNUFRAME
		ACALL	MNUTXT
		ACALL	MNUSCROLL
		ACALL	MNUSETSEL
		RET

MNUFRAME:	MOV	R4,MNUWT
		MOV	R5,MNUHT
		MOV	R6,MNUX
		MOV	R7,MNUY
		MOV	A,#80h
		ACALL	PRINTCHR
		INC	R6
MNUFRAME1:	MOV	A,#81h
		ACALL	PRINTCHR
		INC	R6
		DJNZ	R4,MNUFRAME1
		MOV	A,#82h
		ACALL	PRINTCHR
		MOV	R4,MNUWT
		MOV	R6,MNUX
		INC	R7
MNUFRAME2:	MOV	A,#83h
		ACALL	PRINTCHR
		MOV	A,R6
		ADD	A,R4
		MOV	R6,A
		INC	R6
		MOV	A,#83h
		ACALL	PRINTCHR
		MOV	R6,MNUX
		INC	R7
		DJNZ	R5,MNUFRAME2
		MOV	A,#85h
		ACALL	PRINTCHR
		INC	R6
MNUFRAME3:	MOV	A,#81h
		ACALL	PRINTCHR
		INC	R6
		DJNZ	R4,MNUFRAME3
		MOV	A,#84h
		ACALL	PRINTCHR
		RET

MNUTXT:		MOV	DPL,MNUTXTL
		MOV	DPH,MNUTXTH
		MOV	A,MNUOFS
		MOV	B,MNUITEMWT
		MUL	AB
		ADD	A,DPL
		MOV	DPL,A
		MOV	A,B
		ADDC	A,DPH
		MOV	DPH,A
		MOV	R5,MNUHT
		MOV	R6,MNUX
		INC	R6
		INC	R6
		MOV	R7,MNUY
		INC	R7
MNUTXT1:	PUSH	AR6
		MOV	R4,MNUITEMWT
MNUTXT2:	CLR	A
		MOVC	A,@A+DPTR	;get byte
		CLR	C
		SUBB	A,#20h
		ACALL	PRINTCHR
		INC	DPTR
		INC	R6
		DJNZ	R4,MNUTXT2
		POP	AR6
		INC	R7
		DJNZ	R5,MNUTXT1
		RET

MNUSCROLL:	MOV	R3,MNUSEL
		MOV	R5,MNUHT
		MOV	A,MNUX
		ADD	A,MNUITEMWT
		ADD	A,#3
		MOV	R6,A
		MOV	R7,MNUY
		INC	R7
		MOV	A,MNUOFS
		JZ	MNUSCROLL2
		MOV	R3,A
MNUSCROLL1:	MOV	A,#86h
		ACALL	PRINTCHR
		INC	R7
		DEC	R5
		DJNZ	R3,MNUSCROLL1
MNUSCROLL2:	MOV	A,#87h
		ACALL	PRINTCHR
		INC	R7
		DEC	R5
		MOV	A,MNUHT
		ADD	A,#03h
		SUBB	A,MNUITEMS
		MOV	R4,A
		JZ	MNUSCROLL4
MNUSCROLL3:	MOV	A,#88h
		ACALL	PRINTCHR
		INC	R7
		DEC	R5
		DJNZ	R4,MNUSCROLL3
MNUSCROLL4:	MOV	A,#89h
		ACALL	PRINTCHR
		INC	R7
		DEC	R5
		MOV	A,R5
		JZ	MNUSCROLL6
MNUSCROLL5:	MOV	A,#86h
		ACALL	PRINTCHR
		INC	R7
		DJNZ	R5,MNUSCROLL5
MNUSCROLL6:	RET

MNUCLRSEL:	MOV	R5,MNUITEMWT
		INC	R5
		INC	R5
		MOV	R6,MNUX
		INC	R6
		MOV	A,MNUSEL
		ADD	A,MNUY
		SUBB	A,MNUOFS
		INC	A
		MOV	R7,A
		CLR	A
		ACALL	SETTEXTMODE
		RET

MNUSETSEL:	MOV	R5,MNUITEMWT
		INC	R5
		INC	R5
		MOV	R6,MNUX
		INC	R6
		MOV	A,MNUSEL
		ADD	A,MNUY
		SUBB	A,MNUOFS
		INC	A
		MOV	R7,A
		MOV	A,#0Dh
		ACALL	SETTEXTMODE
		RET

;*************************************************

;Send bytes @DPTR as a series of commands, two data bytes and one command byte.
;Terminate if first data byte is 0FFh
SENDCOMMANDS:	CLR	A
		MOVC	A,@A+DPTR	;get byte
		CJNE	A,#0FFh,SENDCOMMANDS1
		RET
SENDCOMMANDS1:	ACALL	WRITEDATA
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
		MOV	R7,#8*10	;10 characters to be defined
SETCGRAM1:	CLR	A
		MOVC	A,@A+DPTR	;get byte
		INC	DPTR
		ACALL	WRITEDATA
		DJNZ	R7,SETCGRAM1
		MOV	A,#0B2h		;Auto Reset
		ACALL	WRITECOMMAND
		RET

;Convert text pos in R7:R6 to ram offset
POSTOTXTADP:	PUSH	AR6
		PUSH	AR7
		MOV	B,#CHARSLINE	;Number of characters on each line
		MOV	A,R7
		MUL	AB
		ADD	A,R6
		MOV	R6,A
		MOV	A,B
		ADDC	A,#00h
		MOV	R7,A
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
		POP	AR7
		POP	AR6
		RET

;Convert graphic pos in R7:R6 to ram offset
POSTOGRPADP:	PUSH	AR6
		PUSH	AR7
		MOV	B,#CHARSLINE	;Number of characters on each line
		MOV	A,R7
		MUL	AB
		ADD	A,R6
		MOV	R6,A
		MOV	A,B
		ADDC	A,#00h
		MOV	R7,A
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
		POP	AR7
		POP	AR6
		RET

;A character,R6 X pos, R7 Y pos
PRINTCHR:	PUSH	ACC
		ACALL	POSTOTXTADP
		POP	ACC
		ACALL	WRITEDATA
		MOV	A,#0C4h		;Data Write and Nonvariable ADP
		ACALL	WRITECOMMAND
		RET

;Line data @DPTR,R6 X pos, R7 Y pos
PRINTLINE:	ACALL	POSTOTXTADP
		MOV	A,#0B0h		;Set auto write mode
		ACALL	WRITECOMMAND
PRINTLINE1:	CLR	A
		MOVC	A,@A+DPTR	;get byte
		INC	DPTR
		JZ	PRINTLINE2
		CLR	C
		SUBB	A,#20h
		ACALL	WRITEDATA
		SJMP	PRINTLINE1
PRINTLINE2:	MOV	A,#0B2h		;Auto Reset
		ACALL	WRITECOMMAND
		RET


;R6 pos, R7 line, R5 number of characters, A mode
SETTEXTMODE:	PUSH	ACC
		ACALL	POSTOGRPADP
		MOV	A,#0B0h		;Set auto write mode
		ACALL	WRITECOMMAND
		POP	ACC
SETTEXTMODE1:	ACALL	WRITEDATA
		DJNZ	R5,SETTEXTMODE1
		MOV	A,#0B2h		;Auto Reset
		ACALL	WRITECOMMAND
		RET
		RET

;*************************************************

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
STATUS1:	CLR	PB_R		;read it
		MOV	A,P_DATA
		SETB	PB_R
		ANL	A,#0Bh		;status OK?
		CLR	C
		SUBB	A,#0Bh
		JNZ	STATUS1
		POP	ACC
		RET

;*************************************************

; Initialization bytes for 240x128
MSGINIT:	DB	00h,10h,40h		;text home address
		DB	CHARSLINE,00h,41h	;text area
		DB	00h,00h,42h		;graphic home address
		DB	CHARSLINE,00h,43h	;graphic area
		DB	00h,00h,84h		;mode set. Text Attribute mode
		DB	04h,00h,22h		;offset register set, CG RAM area at 2000h to 27FFh
		DB	00h,00h,94h		;display mode set. Text on, Graphic off, Cursor off, Blink off
		DB	0FFh

MSGCLS:		DB	00h,00h,24h		;address pointer set
		DB	00h,00h,0B0h		;auto write mode
		DB	0FFh

MSGCGRAM:	DB	00h,24h,24h		;CG RAM address pointer set, character code 80h to 85h
		DB	00h,00h,0B0h		;auto write mode
		DB	0FFh

CGRAM:		;80h left upper corner
		DB	000000b
		DB	000000b
		DB	000000b
		DB	001111b
		DB	001111b
		DB	001100b
		DB	001100b
		DB	001100b
		;81h horizontal line
		DB	000000b
		DB	000000b
		DB	000000b
		DB	111111b
		DB	111111b
		DB	000000b
		DB	000000b
		DB	000000b
		;82h right upper corner
		DB	000000b
		DB	000000b
		DB	000000b
		DB	111100b
		DB	111100b
		DB	001100b
		DB	001100b
		DB	001100b
		;83h vertical line
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001100b
		;84h right lower corner
		DB	001100b
		DB	001100b
		DB	001100b
		DB	111100b
		DB	111100b
		DB	000000b
		DB	000000b
		DB	000000b
		;85h right lower corner
		DB	001100b
		DB	001100b
		DB	001100b
		DB	001111b
		DB	001111b
		DB	000000b
		DB	000000b
		DB	000000b
		;86h scroll bar
		DB	101010b
		DB	010101b
		DB	101010b
		DB	010101b
		DB	101010b
		DB	010101b
		DB	101010b
		DB	010101b
		;87h scroll pos top
		DB	111111b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		;88h scroll pos middle
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		;89h scroll pos bottom
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	100001b
		DB	111111b

HEADER:		DB	'Device Programmer',0

			;MNUSEL,MNUOFS,MNUX,MNUY,MNUWT,MNUHT,MNUITEMWT,MNUITEMS,MNUTXTL,MNUTXTH
MNUDEF1:	DB	00h,00h,MNUX1,MNUY1,MNUWT1,MNUHT1,07h,06h,LOW MENU1,HIGH MENU1

MENU1:		DB	'AT89S52'
		DB	'8751   '
		DB	'2764   '
		DB	'27128  '
		DB	'27256  '
		DB	'27512  '

		END
