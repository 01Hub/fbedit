T2CON		EQU	0C8h
RCAP2L		EQU	0CAh
RCAP2H		EQU	0CBh
TL2		EQU	0CCh
TH2		EQU	0CDh

;RESET:***********************************************
		ORG	0000h
;		LJMP	TESTINT0INT1	;RESET:
;		LJMP	TESTTMR0TMR1	;RESET:
;		LJMP	TESTSUBB
;		LJMP	WAITTEST
		LJMP	TIMER2TEST
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
		INC	R7
		RETI			;TF2EXF2IRQ:
;*****************************************************

WAITTEST:	SETB	ACC.0
		ACALL	WAIT512MS
		CLR	ACC.0
		SJMP	WAITTEST

TIMER2TEST:	MOV	RCAP2L,#0F0h
		MOV	RCAP2H,#0FFh
		MOV	TL2,#0F0h
		MOV	TH2,#0FFh
		SETB	T2CON.1			;Enable timer 2 event on P1.1
		SETB	T2CON.2			;Enable timer 2
		SETB	IE.5
		SETB	IE.7
		JB	RXD,$
		SJMP	$

;------------------------------------------------------------------
;Wait loop. Waits 0.512 seconds
;------------------------------------------------------------------
WAIT512MS:	MOV	R7,#2Bh
		MOV	R6,#0C9h
		MOV	R5,#08
WAIT512MS1:	DJNZ	R7,WAIT512MS1
		DJNZ	R6,WAIT512MS1
		DJNZ	R5,WAIT512MS1
		RET


TESTSUBB:	MOV	A,#10h
		MOV	R4,#04h
TESTSUBB1:	SUBB	A,R4
		SJMP	TESTSUBB1

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
