
CCDEF struct
	ID			dd ?		;Controls uniqe ID
	lptooltip	dd ?		;Pointer to tooltip text
	hbmp		dd ?		;Handle of bitmap
	lpcaption	dd ?		;Pointer to default caption text
	lpname		dd ?		;Pointer to default id-name text
	lpclass		dd ?		;Pointer to class text
	style		dd ?		;Default style
	exstyle		dd ?		;Default ex-style
	flist1		dd ?		;Property listbox 1
	flist2		dd ?		;Property listbox 2
	disable		dd ?		;Disable controls child windows. 0=No, 1=Use method 1, 2=Use method 2
CCDEF ends

.const

szCap				db 0
szName				db 'IDC_CAD',0

STYLE				equ WS_CHILD or WS_VISIBLE or WS_HSCROLL or WS_VSCROLL or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
EXSTYLE				equ WS_EX_CLIENTEDGE

.data

.data

;Create an inited struct. (Used by RadASM >= 1.2.0.5)
ccdef				CCDEF <290,offset szToolTip,0,offset szCap,offset szName,offset CadClass,STYLE,EXSTYLE,11111101000111000000000001000000b,00010000000000011000000000000000b,1>

.code

DllEntry proc public hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	.if reason==DLL_PROCESS_ATTACH
		push	hInst
		pop		hInstance
		invoke RACadInstall,hInstance,TRUE
	.elseif reason==DLL_PROCESS_DETACH
		invoke RACadUnInstall
	.endif
	mov     eax,TRUE
	ret

DllEntry endp

GetDef proc public nInx:DWORD

	mov		eax,nInx
	.if !eax
		;Get the toolbox bitmap
		;RadASM destroys it after use, so you don't have to worry about that.
		invoke LoadBitmap,hInstance,IDB_RACADBUTTON
		mov		ccdef.hbmp,eax
		;Return pointer to inited struct
		mov		eax,offset ccdef
	.else
		xor		eax,eax
	.endif
	ret

GetDef endp

ENDIF

End DllEntry

