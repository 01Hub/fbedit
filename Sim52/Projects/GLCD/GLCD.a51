
; The processor clock speed is 24MHz.
; Cycle time is .500uS.
; Demo software to display a bit-mapped
; graphic on a 240x128 graphics display
; with a T6963C LCD controller.

PB_CD	BIT	P1.0
PB_R	BIT	P1.1
PB_W	BIT	P1.2
PB_RST	BIT	P1.3

	ORG	0000h
	LJMP	START		;program start

	ORG	0100h
START:
	; Initialize the T6963C
	CLR	PB_RST		;hardware reset
	NOP
	NOP
	NOP
	NOP
	SETB	PB_RST
	MOV	DPTR,#MSGI1	;initialization bytes
	LCALL	MSGC
	; Start of regular program
	; Display graphic
	MOV	DPTR,#MSGI2	;set auto mode
	LCALL	MSGC
	MOV	DPTR,#MSG1	;display graphic
	LCALL	MSGD
	SJMP	$		;infinite loop

;*************************************************
;SUBROUTINES
; MSGC sends the data pointed to by
; the DPTR to the graphics module
; as a series of commands with
; two parameters each.
MSGC:
	MOV	R0,#2		;# of data bytes
MSGC2:
	CLR	A
	MOVC	A,@A+DPTR	;get byte
	CJNE	A,#0A1h,MSGC3	;done?
	RET

MSGC3:
	MOV	R1,A
	LCALL	WRITED		;send it
	INC	DPTR
	DJNZ	R0,MSGC2
	CLR	A
	MOVC	A,@A+DPTR	;get command
	MOV	R1,A
	LCALL	WRITEC		;send command
	SJMP	MSGC		;next command

; MSGD sends the data pointed to by
; the DPTR to the graphics module.
MSGD:
	CLR	A
	MOVC	A,@A+DPTR	;get byte
	CJNE	A,#0A1h,MSGD1	;done?
	RET

MSGD1:
	MOV	R1,A
	LCALL	WRITED		;send data
	INC	DPTR
	SJMP	MSGD

; WRITEC sends the byte in R1 to a
; graphics module as a command.
WRITEC:
	LCALL	STATUS		;display ready?
	SETB	PB_CD		;c/d = 1
WRITEC1:
	MOV	P2,R1		;get data
	CLR	PB_W		;strobe it
	SETB	PB_W
	RET

; WRITED sends the byte in R1 to the
; graphics module as data.
WRITED:
	LCALL	STATUS		;display ready?
	CLR	PB_CD		;c/d = 0
	SJMP	WRITEC1

; STATUS check to see that the graphic
; display is ready. It won't return
; until it is.
STATUS:
	SETB	PB_CD		;c/d=1
	MOV	P2,#0FFh	;P2 to input
	MOV	R3,#0Bh		;status bits mask
STAT1:
	CLR	PB_R		;read it
	MOV	A,P2
	SETB	PB_R
	ANL	A,R3		;status OK?
	CLR	C
	SUBB	A,R3
	JNZ	STAT1
	RET

;************************************************
; TABLES AND DATA
; Initialization bytes for 240x128
MSGI1:
	DB	80h,07h,40h	;text home address
	DB	1Eh,00h,41h	;text area
	DB	00h,00h,42h	;graphic home address
	DB	1Eh,00h,43h	;graphic area
	DB	00h,00h,81h	;mode set
	DB	00h,00h,24h	;address pointer set
	DB	00h,00h,98h	;display mode set
	DB	0A1h

MSGI2:
	DB	00,00,0b0h	;auto mode
	DB	0A1h

;240x128 Bitmap graphic data
;Only the first 8 bytes are shown here
;The real graphic consists of 240/8*128=3840 bytes
;of binary data.
MSG1:
	DB	00h,00h,00h,00h,00h,00h,00h,00h
	DB	0A1h

	END
