
;RESET:***********************************************
		ORG	0000h
;		LJMP	TESTINT0INT1	;RESET:
		LJMP	TESTTMR0TMR1	;RESET:
;IE0IRQ:**********************************************
		ORG	0003h
		MOV	A,#00h
		ACALL	WAITASEC
		RETI			;IE0IRQ:
;TF0IRQ:**********************************************
		ORG	000Bh
		MOV	A,#00h
		ACALL	WAIT
		RETI			;TF0IRQ:
;IE1IRQ:**********************************************
		ORG	0013h
		MOV	A,#01h
		ACALL	WAITASEC
		RETI			;IE1IRQ:
;TF1IRQ:**********************************************
		ORG	001Bh
		MOV	A,#01h
		ACALL	WAIT
		RETI			;TF1IRQ:
;RITIIRQ:*********************************************
		ORG	0023h
		NOP
		NOP
		RETI			;RITIIRQ:
;TF2EXF2IRQ:******************************************
		ORG	002Bh
		NOP
		NOP
		RETI			;TF2EXF2IRQ:
;*****************************************************

TESTTMR0TMR1:	MOV	TMOD,#11h	;16 bit
		MOV	IE,#8Ah
		SETB	TR0
		SETB	TR1
		SJMP	$

TESTINT0INT1:	MOV	IE,#85h
		SJMP	$

WAIT:		MOV	R7,#00h
		MOV	R6,#10h
WAIT1:		DJNZ	R7,WAIT1
		DJNZ	R6,WAIT1
		RET
;------------------------------------------------------------------
;Wait loop. Waits 1 second
;------------------------------------------------------------------
WAITASEC:	MOV	R7,#0F9h
		MOV	R6,#51
		MOV	R5,#16
WAITASEC1:	DJNZ	R7,WAITASEC1
		DJNZ	R6,WAITASEC1
		DJNZ	R5,WAITASEC1
		MOV	A,#0FFh
		RET

TSTDATA:	DB 11h,22h,33h,44h

		END
