
		ORG	0000h

START:		MOV	P0,#00h
		SETB	80h
		SETB	81h
		SETB	82h
		SETB	83h
		SETB	84h
		SETB	85h
		SETB	86h
		SETB	87h
		SETB	C
		CLR	C
		MOV	20h,#0FFh
		MOV	C,00h
		CLR	C
		ORL	C,00h
		ANL	C,00h
		CLR	00h
		ANL	C,00h
		NOP
		AJMP	AA
		NOP
AA:
		LJMP	BB
		NOP
BB:
		MOV	A,#5Ah
		RR	A
		RR	A
		INC	A
		INC	10h
		MOV	R0,#10h
		INC	@R0
		MOV	R1,#10h
		INC	@R1
		INC	R0
		INC	R1
		INC	R2
		INC	R3
		INC	R4
		INC	R5
		INC	R6
		INC	R7

		JBC	00h,CC
		NOP
		MOV	20h,#0FFh
		JBC	00h,CC
CC:		ACALL	TESTCALL
		LCALL	TESTCALL
		RRC	A
		DEC	A
		DEC	10h
		DEC	@R0
		DEC	@R1
		DEC	R0
		DEC	R1
		DEC	R2
		DEC	R3
		DEC	R4
		DEC	R5
		DEC	R6
		DEC	R7

		JB	00h,DD
;		AJMP	$cad
;		RET
		NOP
DD:		RL	A
		ADD	A,#10h
		ADD	A,10h
		ADD	A,@R0
		ADD	A,@R1
		ADD	A,R0
		ADD	A,R1
		ADD	A,R2
		ADD	A,R3
		ADD	A,R4
		ADD	A,R5
		ADD	A,R6
		ADD	A,R7

		JNB	00h,EE
;		ACALL	$cad
;		RETI
		NOP
EE:		RLC	A
		ADDC	A,#10h
		ADDC	A,10h
		ADDC	A,@R0
		ADDC	A,@R1
		ADDC	A,R0
		ADDC	A,R1
		ADDC	A,R2
		ADDC	A,R3
		ADDC	A,R4
		ADDC	A,R5
		ADDC	A,R6
		ADDC	A,R7

		SETB	C
		JC	FF
		NOP
;		AJMP	$cad
FF:		ORL	10h,A
		ORL	10h,#0Fh
		ORL	A,#0Fh
		ORL	A,10h
		ORL	A,@R0
		ORL	A,@R1
		ORL	A,R0
		ORL	A,R1
		ORL	A,R2
		ORL	A,R3
		ORL	A,R4
		ORL	A,R5
		ORL	A,R6
		ORL	A,R7

		CLR	C
		JNC	GG
;		ACALL	$cad
GG:		ANL	10h,A
		ANL	10h,#0Fh
		ANL	A,#0Fh
		ANL	A,10h
		ANL	A,@R0
		ANL	A,@R1
		ANL	A,R0
		ANL	A,R1
		ANL	A,R2
		ANL	A,R3
		ANL	A,R4
		ANL	A,R5
		ANL	A,R6
		ANL	A,R7

		JZ	HH
;		AJMP	$cad
HH:		XRL	10h,A
		XRL	10h,#0Fh
		XRL	A,0FFh
		XRL	A,10h
		XRL	A,@R0
		XRL	A,@R1
		XRL	A,R0
		XRL	A,R1
		XRL	A,R2
		XRL	A,R3
		XRL	A,R4
		XRL	A,R5
		XRL	A,R6
		XRL	A,R7

		JNZ	II
;		ACALL	$cad
II:		ORL	C,00h
		MOV	A,#01h
		MOV	DPTR,#0002h
;		JMP	@A+DPTR
		MOV	A,#11h
		MOV	10h,#12h
		MOV	@R0,#11h
		MOV	@R1,#11h
		MOV	R0,#11h
		MOV	R1,#11h
		MOV	R2,#11h
		MOV	R3,#11h
		MOV	R4,#11h
		MOV	R5,#11h
		MOV	R6,#11h
		MOV	R7,#11h

;-------------------------------------------------------

		SJMP	$+3
		NOP
		AJMP	$+3
		NOP
		ANL	C,00h
		MOVC	A,@A+PC
		MOV	A,#100
		MOV	B,#4
		DIV	AB
		MOV	10h,11h
		MOV	10h,@R0
		MOV	10h,@R1
		MOV	10h,R0
		MOV	10h,R1
		MOV	10h,R2
		MOV	10h,R3
		MOV	10h,R4
		MOV	10h,R5
		MOV	10h,R6
		MOV	10h,R7

		MOV	DPTR,#1234h
;		ACALL	$cad
		MOV	00h,C
		MOVC	A,@A+DPTR
		SUBB	A,#10h
		SUBB	A,10h
		SUBB	A,@R0
		SUBB	A,@R1
		SUBB	A,R0
		SUBB	A,R1
		SUBB	A,R2
		SUBB	A,R3
		SUBB	A,R4
		SUBB	A,R5
		SUBB	A,R6
		SUBB	A,R7

		ORL	C,00h
;		AJMP	$cad
		MOV	C,00h
		INC	DPTR
		MOV	A,#5
		MOV	B,#6
		MUL	AB
		MOV	@R0,10h
		MOV	@R1,10h
		MOV	R0,10h
		MOV	R1,10h
		MOV	R2,10h
		MOV	R3,10h
		MOV	R4,10h
		MOV	R5,10h
		MOV	R6,10h
		MOV	R7,10h

		ANL	C,10h
;		ACALL	$cad
		CPL	10h
		CPL	C
		CJNE	A,#10h,II1
II1:		CJNE	A,10h,II2
II2:		CJNE	@R0,#10h,II3
II3:		CJNE	@R1,#10h,II4
II4:		CJNE	R0,#10h,II5
II5:		CJNE	R1,#10h,II6
II6:		CJNE	R2,#10h,II7
II7:		CJNE	R3,#10h,II8
II8:		CJNE	R4,#10h,II9
II9:		CJNE	R5,#10h,II10
II10:		CJNE	R6,#10h,II11
II11:		CJNE	R7,#10h,II12
II12:

;-------------------------------------------------------

		PUSH	10h
;		AJMP	$cad
		CLR	00h
		CLR	C
		SWAP	A
		XCH	A,10h
		XCH	A,@R0
		XCH	A,@R1
		XCH	A,R0
		XCH	A,R1
		XCH	A,R2
		XCH	A,R3
		XCH	A,R4
		XCH	A,R5
		XCH	A,R6
		XCH	A,R7

		POP	10h
;		ACALL_$cad
		SETB	00h
		SETB	C
		DA	A
		DJNZ	10h,$
		XCHD	A,@R0
		XCHD	A,@R1
		DJNZ	R0,$
		DJNZ	R1,$
		DJNZ	R2,$
		DJNZ	R3,$
		DJNZ	R4,$
		DJNZ	R5,$
		DJNZ	R6,$
		DJNZ	R7,$

		MOVX	A,@DPTR
;		AJMP	$cad
		MOVX	A,@R0
		MOVX	A,@R1
		CLR	A
		MOV	A,10h
		MOV	A,@R0
		MOV	A,@R1
		MOV	A,R0
		MOV	A,R1
		MOV	A,R2
		MOV	A,R3
		MOV	A,R4
		MOV	A,R5
		MOV	A,R6
		MOV	A,R7

		MOV	A,#12h
		MOVX	@DPTR,A
;		ACALL	$cad
		MOVX	@R0,A
		MOVX	@R1,A
		CPL	A
		MOV	10h,A
		MOV	@R0,A
		MOV	@R1,A
		MOV	R0,A
		MOV	R1,A
		MOV	R2,A
		MOV	R3,A
		MOV	R4,A
		MOV	R5,A
		MOV	R6,A
		MOV	R7,A

;-------------------------------------------------------
		CLR	A
		MOV	DPTR,#8000h
TIMING:		ACALL	WAITASEC
		INC	A
		SJMP	TIMING

TESTCALL:	NOP
		NOP
		RET


;------------------------------------------------------------------
;Wait loop. Waits 1 second
;------------------------------------------------------------------
WAITASEC:	MOV	R7,#0F9h
		MOV	R6,#51
		MOV	R5,#16
WAITASEC1:	MOVX	@DPTR,A
		MOVX	A,@DPTR
		DJNZ	R7,WAITASEC1
		DJNZ	R6,WAITASEC1
		DJNZ	R5,WAITASEC1
		RET

TSTDATA:	DB 11h,22h,33h,44h

		END
