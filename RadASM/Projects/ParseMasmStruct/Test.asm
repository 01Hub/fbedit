
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
	b		HWND ?
	a		BYTE ?
	struct tstsub
		a		BYTE ?
		b		WORD ?
	ends
TST ends

;TST struct DWORD
;	a		BYTE ?
;	b		DWORD ?
;	cc		DWORD ?
;	aa		BYTE ?
;TST ends

PrintDec sizeof TST
PrintDec TST.a
PrintDec TST.b
PrintDec TST.tstsub
PrintDec TST.tstsub.a
PrintDec TST.tstsub.b
PrintDec sizeof szOutput
