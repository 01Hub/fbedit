
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
	struct TSTSUB
		a		DWORD ?
		b		BYTE ?
	ends
TST ends
;TST struct DWORD
;	a		BYTE ?
;	b		DWORD ?
;	cc		DWORD ?
;	aa		BYTE ?
;TST ends

;PrintDec sizeof TST
;PrintDec TST.TSTSUB.a
;PrintDec TST.TSTSUB.b
;PrintDec TST.bb
;PrintDec TST.cc
