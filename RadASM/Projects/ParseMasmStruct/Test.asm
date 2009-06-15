
;TSTSUB struct DWORD
;	a		BYTE ?
;	b		DWORD ?
;TSTSUB ends
;
;TST struct DWORD
;	a		BYTE ?
;	b		DWORD ?
;	tstsub	TSTSUB <>
;TST ends
;
TST struct DWORD
	a		DWORD ?
	b		BYTE ?
	struct tstsub
		a		BYTE ?
		b		DWORD ?
	ends
TST ends

;TST struct DWORD
;	a		BYTE ?
;	b		DWORD ?
;	cc		DWORD ?
;	aa		BYTE ?
;TST ends
