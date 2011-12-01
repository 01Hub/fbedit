
		ORG	0000h

		MOV	SP,#80h
		MOV	R7,#5Ah
		PUSH	07h
		MOV	R7,#33h
		POP	07h
		SJMP	$
		END
