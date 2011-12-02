
		ORG	0000h

		NOP
		AJMP	AA
		NOP
AA:		LJMP	BB
		NOP
BB:		MOV	A,#5Ah
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

		SJMP	$

TESTCALL:	NOP
		NOP
		RET

		END
