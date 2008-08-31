
IDD_DLGKEYWORDS		equ 4000
IDC_LSTKWCOLORS		equ 4001
IDC_LSTKWACTIVE		equ 4014
IDC_LSTKWHOLD		equ 4013
IDC_LSTCOLORS		equ 4015
IDC_BTNKWAPPLY		equ 4002

IDC_BTNHOLD			equ 4009
IDC_BTNACTIVE		equ 4008
IDC_EDTKW			equ 4012
IDC_BTNADD			equ 4011
IDC_BTNDEL			equ 4010

IDC_CHKBOLD			equ 4004
IDC_CHKITALIC		equ 4003
IDC_CHKRCFILE		equ 4005
IDC_SPNTABSIZE		equ 4017
IDC_EDTTABSIZE		equ 4018
IDC_CHKEXPAND		equ 4019
IDC_CHKAUTOINDENT	equ 4020
IDC_CHKLINENUMBER	equ 4007
IDC_CHKHILITELINE	equ 4021
IDC_CHKHILITECMNT	equ 4026
IDC_CHKSESSION		equ 4006

IDC_BTNCODEFONT		equ 4024
IDC_STCCODEFONT		equ 4022
IDC_BTNLNRFONT		equ 4025
IDC_STCLNRFONT		equ 4023

szColors			db 'Back',0
					db 'Text',0
					db 'Selected back',0
					db 'Selected text',0
					db 'Comments',0
					db 'Strings',0
					db 'Operators',0
					db 'Comments back',0
					db 'Active line back',0
					db 'Indent markers',0
					db 'Selection bar',0
					db 'Selection bar pen',0
					db 'Line numbers',0
					db 'Numbers & hex',0
					db 'Tools Back',0
					db 'Tools Text',0
					db 'Dialog Back',0
					db 'Dialog Text',0
					db 0
szCustColors		db 'CustColors',0

.data?

nKWInx				dd ?
CustColors			dd 16 dup(?)
hCFnt				dd ?
hLFnt				dd ?

.code

SetKeyWordList proc uses esi edi,hWin:HWND,idLst:DWORD,nInx:DWORD
	LOCAL	hMem:DWORD
	LOCAL	buffer[64]:BYTE

	mov		eax,nInx
	mov		nKWInx,eax
	invoke SendDlgItemMessage,hWin,idLst,LB_RESETCONTENT,0,0
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16384
	mov		hMem,eax
	invoke MakeKey,offset szGroup,nInx,addr buffer
	mov		lpcbData,16384
	invoke RegQueryValueEx,hReg,addr buffer,0,addr lpType,hMem,addr lpcbData
	mov		eax,hMem
	mov		al,[eax]
	mov		esi,nInx
	.if !al && esi<16
		lea		esi,kwofs[esi*4]
		mov		esi,[esi]
	.else
		mov		esi,hMem
	.endif
	dec		esi
  Nxt:
	inc		esi
	mov		al,[esi]
	or		al,al
	je		Ex
	cmp		al,VK_SPACE
	je		Nxt
	lea		edi,buffer
  @@:
	mov		al,[esi]
	.if al==VK_SPACE || !al
		mov		byte ptr [edi],0
		invoke SendDlgItemMessage,hWin,idLst,LB_ADDSTRING,0,addr buffer
		dec		esi
		jmp		Nxt
	.endif
	mov		[edi],al
	inc		esi
	inc		edi
	jmp		@b
  Ex:
	invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETITEMDATA,nInx,0
	.if eax!=LB_ERR
		shr		eax,24
		mov		esi,eax
		mov		eax,BST_UNCHECKED
		test	esi,1
		.if !ZERO?
			mov		eax,BST_CHECKED
		.endif
		invoke CheckDlgButton,hWin,IDC_CHKBOLD,eax
		mov		eax,BST_UNCHECKED
		test	esi,2
		.if !ZERO?
			mov		eax,BST_CHECKED
		.endif
		invoke CheckDlgButton,hWin,IDC_CHKITALIC,eax
		mov		eax,BST_UNCHECKED
		test	esi,10h
		.if !ZERO?
			mov		eax,BST_CHECKED
		.endif
		invoke CheckDlgButton,hWin,IDC_CHKRCFILE,eax
	.endif
	invoke GlobalFree,hMem
	ret

SetKeyWordList endp

SaveKeyWordList proc uses esi edi,hWin:HWND,idLst:DWORD,nInx:DWORD
	LOCAL	hMem:DWORD
	LOCAL	buffer[64]:BYTE

	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16384
	mov		hMem,eax
	mov		edi,eax
	xor		esi,esi
  @@:
	invoke SendDlgItemMessage,hWin,idLst,LB_GETTEXT,esi,edi
	.if eax!=LB_ERR
		invoke lstrlen,edi
		add		edi,eax
		mov		byte ptr [edi],VK_SPACE
		inc		edi
		inc		esi
		jmp		@b
	.endif
	.if edi!=hMem
		mov		byte ptr [edi-1],0
	.endif
	sub		edi,hMem
	invoke MakeKey,offset szGroup,nInx,addr buffer
	invoke RegSetValueEx,hReg,addr buffer,0,REG_SZ,hMem,edi
	invoke GlobalFree,hMem
	ret

SaveKeyWordList endp

DeleteKeyWords proc hWin:HWND,idFrom:DWORD
	LOCAL	nInx:DWORD
	LOCAL	nCnt:DWORD

	invoke SendDlgItemMessage,hWin,idFrom,LB_GETSELCOUNT,0,0
	mov		nCnt,eax
	mov		nInx,0
	.while nCnt
		invoke SendDlgItemMessage,hWin,idFrom,LB_GETSEL,nInx,0
		.if eax
			invoke SendDlgItemMessage,hWin,idFrom,LB_DELETESTRING,nInx,0
			dec		nCnt
			mov		eax,1
		.endif
		xor		eax,1
		add		nInx,eax
	.endw
	ret

DeleteKeyWords endp

MoveKeyWords proc hWin:HWND,idFrom:DWORD,idTo:DWORD
	LOCAL	buffer[64]:BYTE
	LOCAL	nInx:DWORD
	LOCAL	nCnt:DWORD

	invoke SendDlgItemMessage,hWin,idFrom,LB_GETSELCOUNT,0,0
	mov		nCnt,eax
	mov		nInx,0
	.while nCnt
		invoke SendDlgItemMessage,hWin,idFrom,LB_GETSEL,nInx,0
		.if eax
			invoke SendDlgItemMessage,hWin,idFrom,LB_GETTEXT,nInx,addr buffer
			invoke SendDlgItemMessage,hWin,idFrom,LB_DELETESTRING,nInx,0
			invoke SendDlgItemMessage,hWin,idTo,LB_ADDSTRING,0,addr buffer
			dec		nCnt
			mov		eax,1
		.endif
		xor		eax,1
		add		nInx,eax
	.endw
	ret

MoveKeyWords endp

UpdateKeyWords proc uses ebx,hWin:HWND

	xor		ebx,ebx
	.while ebx<16
		invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETITEMDATA,ebx,0
		mov		kwcol[ebx*4],eax
		inc		ebx
	.endw
	invoke RegSetValueEx,hReg,addr szKeyWordColor,0,REG_BINARY,addr kwcol,sizeof kwcol
	invoke SetKeyWords
	invoke UpdateAll,WM_PAINT
	ret

UpdateKeyWords endp

UpdateToolColors proc
	LOCAL	racol:RACOLOR
	LOCAL	rescol:COLOR

	invoke SendMessage,hOut,REM_GETCOLOR,0,addr racol
	mov		eax,col.toolback
	mov		racol.bckcol,eax
	mov		eax,col.tooltext
	mov		racol.txtcol,eax
	invoke SendMessage,hOut,REM_SETCOLOR,0,addr racol
	invoke SendMessage,hBrowse,FBM_SETBACKCOLOR,0,col.toolback
	invoke SendMessage,hBrowse,FBM_SETTEXTCOLOR,0,col.tooltext
	mov		eax,col.dialogback
	mov		rescol.back,eax
	mov		eax,col.dialogtext
	mov		rescol.text,eax
	invoke SendMessage,hResEd,DEM_SETCOLOR,0,addr rescol
	.if hBrBack
		invoke DeleteObject,hBrBack
	.endif
	invoke CreateSolidBrush,col.toolback
	mov		hBrBack,eax
	ret

UpdateToolColors endp

KeyWordsProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	nInx:DWORD
	LOCAL	buffer[256]:BYTE
	LOCAL	rect:RECT
	LOCAL	hBr:DWORD
	LOCAL	cc:CHOOSECOLOR
	LOCAL	cf:CHOOSEFONT
	LOCAL	lf:LOGFONT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	esi
		push	edi
        invoke SendDlgItemMessage,hWin,IDC_SPNTABSIZE,UDM_SETRANGE,0,00010014h		; Set range
        invoke SendDlgItemMessage,hWin,IDC_SPNTABSIZE,UDM_SETPOS,0,edopt.tabsize	; Set default value
		invoke CheckDlgButton,hWin,IDC_CHKEXPAND,edopt.exptabs
		invoke CheckDlgButton,hWin,IDC_CHKAUTOINDENT,edopt.indent
		invoke CheckDlgButton,hWin,IDC_CHKHILITELINE,edopt.hiliteline
		invoke CheckDlgButton,hWin,IDC_CHKHILITECMNT,edopt.hilitecmnt
		invoke CheckDlgButton,hWin,IDC_CHKSESSION,edopt.session
		invoke CheckDlgButton,hWin,IDC_CHKLINENUMBER,edopt.linenumber
		mov		esi,offset szColors
		mov		edi,offset col
	  @@:
		invoke SendDlgItemMessage,hWin,IDC_LSTCOLORS,LB_ADDSTRING,0,esi
		invoke SendDlgItemMessage,hWin,IDC_LSTCOLORS,LB_SETITEMDATA,eax,[edi]
		invoke lstrlen,esi
		add		esi,eax
		inc		esi
		add		edi,4
		mov		al,[esi]
		or		al,al
		jne		@b
		invoke SendDlgItemMessage,hWin,IDC_LSTCOLORS,LB_SETCURSEL,0,0
		mov		edi,offset kwcol
		mov		nInx,0
		.while nInx<16
			invoke MakeKey,offset szGroup,nInx,addr buffer
			invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_ADDSTRING,0,addr buffer
			invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_SETITEMDATA,eax,[edi]
			add		edi,4
			inc		nInx
		.endw
		invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_SETCURSEL,0,0
		invoke SetKeyWordList,hWin,IDC_LSTKWHOLD,10
		invoke SetKeyWordList,hWin,IDC_LSTKWACTIVE,0
		invoke SendDlgItemMessage,hWin,IDC_EDTKW,EM_LIMITTEXT,63,0
		mov		eax,IDC_BTNKWAPPLY
		xor		edx,edx
		call	EnButton
		pop		edi
		pop		esi
		invoke SendDlgItemMessage,hWin,IDC_STCCODEFONT,WM_SETFONT,hFont,FALSE
		invoke SendDlgItemMessage,hWin,IDC_STCLNRFONT,WM_SETFONT,hLnrFont,FALSE
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		mov		edx,eax
		shr		edx,16
		and		eax,0FFFFh
		.if edx==BN_CLICKED
			.if eax==IDOK
				call	Update
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDCANCEL
				.if hCFnt
					invoke DeleteObject,hCFnt
				.endif
				.if hLFnt
					invoke DeleteObject,hLFnt
				.endif
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNKWAPPLY
				call	Update
			.elseif eax==IDC_BTNHOLD
				invoke MoveKeyWords,hWin,IDC_LSTKWACTIVE,IDC_LSTKWHOLD
				mov		eax,IDC_BTNHOLD
				xor		edx,edx
				call	EnButton
				mov		eax,IDC_BTNDEL
				xor		edx,edx
				call	EnButton
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_BTNACTIVE
				invoke MoveKeyWords,hWin,IDC_LSTKWHOLD,IDC_LSTKWACTIVE
				mov		eax,IDC_BTNACTIVE
				xor		edx,edx
				call	EnButton
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_BTNADD
				invoke GetDlgItemText,hWin,IDC_EDTKW,addr buffer,64
				invoke SendDlgItemMessage,hWin,IDC_LSTKWACTIVE,LB_ADDSTRING,0,addr buffer
				mov		buffer,0
				invoke SetDlgItemText,hWin,IDC_EDTKW,addr buffer
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_BTNDEL
				invoke DeleteKeyWords,hWin,IDC_LSTKWACTIVE
				mov		eax,IDC_BTNHOLD
				xor		edx,edx
				call	EnButton
				mov		eax,IDC_BTNDEL
				xor		edx,edx
				call	EnButton
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_CHKBOLD
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETCURSEL,0,0
				push	eax
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETITEMDATA,eax,0
				pop		edx
				xor		eax,01000000h
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_SETITEMDATA,edx,eax
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_CHKITALIC
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETCURSEL,0,0
				push	eax
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETITEMDATA,eax,0
				pop		edx
				xor		eax,02000000h
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_SETITEMDATA,edx,eax
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_CHKRCFILE
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETCURSEL,0,0
				push	eax
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETITEMDATA,eax,0
				pop		edx
				xor		eax,10000000h
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_SETITEMDATA,edx,eax
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_CHKEXPAND
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_CHKAUTOINDENT
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_CHKHILITELINE
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_CHKHILITECMNT
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_CHKSESSION
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_CHKLINENUMBER
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.elseif eax==IDC_BTNCODEFONT
				mov		edx,hCFnt
				.if !edx
					mov		edx,hFont
				.endif
				invoke GetObject,edx,sizeof lf,addr lf
				invoke RtlZeroMemory,addr cf,sizeof cf
				mov		cf.lStructSize,sizeof cf
				mov		eax,hWin
				mov		cf.hwndOwner,eax
				lea		eax,lf
				mov		cf.lpLogFont,eax
				mov		cf.Flags,CF_SCREENFONTS or CF_INITTOLOGFONTSTRUCT
				invoke ChooseFont,addr cf
				.if eax
					invoke CreateFontIndirect,addr lf
					mov     hCFnt,eax
					invoke SendDlgItemMessage,hWin,IDC_STCCODEFONT,WM_SETFONT,hCFnt,TRUE
					mov		eax,IDC_BTNKWAPPLY
					mov		edx,TRUE
					call	EnButton
				.endif
			.elseif eax==IDC_BTNLNRFONT
				mov		edx,hLFnt
				.if !edx
					mov		edx,hLnrFont
				.endif
				invoke GetObject,edx,sizeof lf,addr lf
				invoke RtlZeroMemory,addr cf,sizeof cf
				mov		cf.lStructSize,sizeof cf
				mov		eax,hWin
				mov		cf.hwndOwner,eax
				lea		eax,lf
				mov		cf.lpLogFont,eax
				mov		cf.Flags,CF_SCREENFONTS or CF_INITTOLOGFONTSTRUCT
				invoke ChooseFont,addr cf
				.if eax
					invoke CreateFontIndirect,addr lf
					mov     hLFnt,eax
					invoke SendDlgItemMessage,hWin,IDC_STCLNRFONT,WM_SETFONT,hLFnt,TRUE
					mov		eax,IDC_BTNKWAPPLY
					mov		edx,TRUE
					call	EnButton
				.endif
			.endif
		.elseif edx==EN_CHANGE
			.if eax==IDC_EDTKW
				invoke SendDlgItemMessage,hWin,IDC_EDTKW,WM_GETTEXTLENGTH,0,0
				.if eax
					mov		eax,TRUE
				.endif
				mov		edx,eax
				mov		eax,IDC_BTNADD
				call	EnButton
			.elseif eax==IDC_EDTTABSIZE
				mov		eax,IDC_BTNKWAPPLY
				mov		edx,TRUE
				call	EnButton
			.endif
		.elseif edx==LBN_SELCHANGE
			.if eax==IDC_LSTKWCOLORS
				invoke SaveKeyWordList,hWin,IDC_LSTKWACTIVE,nKWInx
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETCURSEL,0,0
				invoke SetKeyWordList,hWin,IDC_LSTKWACTIVE,eax
				invoke GetDlgItem,hWin,IDC_BTNHOLD
				invoke EnableWindow,eax,FALSE
				invoke GetDlgItem,hWin,IDC_BTNDEL
				invoke EnableWindow,eax,FALSE
			.elseif eax==IDC_LSTKWACTIVE
				invoke SendDlgItemMessage,hWin,IDC_LSTKWACTIVE,LB_GETSELCOUNT,0,0
				.if eax
					mov		eax,TRUE
				.endif
				push	eax
				mov		edx,eax
				mov		eax,IDC_BTNHOLD
				call	EnButton
				pop		edx
				mov		eax,IDC_BTNDEL
				call	EnButton
			.elseif eax==IDC_LSTKWHOLD
				invoke SendDlgItemMessage,hWin,IDC_LSTKWHOLD,LB_GETSELCOUNT,0,0
				.if eax
					mov		eax,TRUE
				.endif
				mov		edx,eax
				mov		eax,IDC_BTNACTIVE
				call	EnButton
			.endif
		.elseif edx==LBN_DBLCLK
			.if eax==IDC_LSTKWCOLORS
				mov		cc.lStructSize,sizeof CHOOSECOLOR
				mov		eax,hWin
				mov		cc.hwndOwner,eax
				mov		eax,hInstance
				mov		cc.hInstance,eax
				mov		cc.lpCustColors,offset CustColors
				mov		cc.Flags,CC_FULLOPEN or CC_RGBINIT
				mov		cc.lCustData,0
				mov		cc.lpfnHook,0
				mov		cc.lpTemplateName,0
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETITEMDATA,eax,0
				push	eax
				;Mask off group/font
				and		eax,0FFFFFFh
				mov		cc.rgbResult,eax
				invoke ChooseColor,addr cc
				pop		ecx
				.if eax
					push	ecx
					invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_GETCURSEL,0,0
					pop		ecx
					mov		edx,cc.rgbResult
					;Group/Font
					and		ecx,0FF000000h
					or		edx,ecx
					invoke SendDlgItemMessage,hWin,IDC_LSTKWCOLORS,LB_SETITEMDATA,eax,edx
					invoke GetDlgItem,hWin,IDC_LSTKWCOLORS
					invoke InvalidateRect,eax,NULL,FALSE
					mov		eax,IDC_BTNKWAPPLY
					mov		edx,TRUE
					call	EnButton
				.endif
			.elseif eax==IDC_LSTKWACTIVE
				invoke SendDlgItemMessage,hWin,IDC_LSTKWACTIVE,LB_GETCURSEL,0,0
				.if eax!=LB_ERR
					mov		edx,eax
					invoke SendDlgItemMessage,hWin,IDC_LSTKWACTIVE,LB_GETTEXT,edx,addr buffer
					invoke SetDlgItemText,hWin,IDC_EDTKW,addr buffer
				.endif
			.elseif eax==IDC_LSTKWHOLD
				invoke SendDlgItemMessage,hWin,IDC_LSTKWHOLD,LB_GETCURSEL,0,0
				.if eax!=LB_ERR
					mov		edx,eax
					invoke SendDlgItemMessage,hWin,IDC_LSTKWHOLD,LB_GETTEXT,edx,addr buffer
					invoke SetDlgItemText,hWin,IDC_EDTKW,addr buffer
				.endif
			.elseif eax==IDC_LSTCOLORS
				mov		cc.lStructSize,sizeof CHOOSECOLOR
				mov		eax,hWin
				mov		cc.hwndOwner,eax
				mov		eax,hInstance
				mov		cc.hInstance,eax
				mov		cc.lpCustColors,offset CustColors
				mov		cc.Flags,CC_FULLOPEN or CC_RGBINIT
				mov		cc.lCustData,0
				mov		cc.lpfnHook,0
				mov		cc.lpTemplateName,0
				invoke SendDlgItemMessage,hWin,IDC_LSTCOLORS,LB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_LSTCOLORS,LB_GETITEMDATA,eax,0
				push	eax
				;Mask off font
				and		eax,0FFFFFFh
				mov		cc.rgbResult,eax
				invoke ChooseColor,addr cc
				pop		ecx
				.if eax
					push	ecx
					invoke SendDlgItemMessage,hWin,IDC_LSTCOLORS,LB_GETCURSEL,0,0
					pop		ecx
					mov		edx,cc.rgbResult
					;Font
					and		ecx,0FF000000h
					or		edx,ecx
					invoke SendDlgItemMessage,hWin,IDC_LSTCOLORS,LB_SETITEMDATA,eax,edx
					invoke GetDlgItem,hWin,IDC_LSTCOLORS
					invoke InvalidateRect,eax,NULL,FALSE
					mov		eax,IDC_BTNKWAPPLY
					mov		edx,TRUE
					call	EnButton
				.endif
			.endif
		.endif
	.elseif eax==WM_DRAWITEM
		push	esi
		mov		esi,lParam
		assume esi:ptr DRAWITEMSTRUCT
		test	[esi].itemState,ODS_SELECTED
		.if ZERO?
			push	COLOR_WINDOW
			mov		eax,COLOR_WINDOWTEXT
		.else
			push	COLOR_HIGHLIGHT
			mov		eax,COLOR_HIGHLIGHTTEXT
		.endif
		invoke GetSysColor,eax
		invoke SetTextColor,[esi].hdc,eax
		pop		eax
		invoke GetSysColor,eax
		invoke SetBkColor,[esi].hdc,eax
		invoke ExtTextOut,[esi].hdc,0,0,ETO_OPAQUE,addr [esi].rcItem,NULL,0,NULL
		mov		eax,[esi].rcItem.left
		inc		eax
		mov		rect.left,eax
		add		eax,25
		mov		rect.right,eax
		mov		eax,[esi].rcItem.top
		inc		eax
		mov		rect.top,eax
		mov		eax,[esi].rcItem.bottom
		dec		eax
		mov		rect.bottom,eax
		mov		eax,[esi].itemData
		and		eax,0FFFFFFh
		invoke CreateSolidBrush,eax
		mov		hBr,eax
		invoke FillRect,[esi].hdc,addr rect,hBr
		invoke DeleteObject,hBr
		invoke GetStockObject,BLACK_BRUSH
		invoke FrameRect,[esi].hdc,addr rect,eax
		invoke SendMessage,[esi].hwndItem,LB_GETTEXT,[esi].itemID,addr buffer
		invoke lstrlen,addr buffer
		mov		edx,[esi].rcItem.left
		add		edx,30
		invoke TextOut,[esi].hdc,edx,[esi].rcItem.top,addr buffer,eax
		assume esi:nothing
		pop		esi
	.elseif eax==WM_CLOSE
		mov		hCFnt,0
		mov		hLFnt,0
		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

EnButton:
	push	edx
	invoke GetDlgItem,hWin,eax
	pop		edx
	invoke EnableWindow,eax,edx
	retn

Update:
	invoke GetDlgItem,hWin,IDC_BTNKWAPPLY
	invoke IsWindowEnabled,eax
	.if eax
		mov		eax,IDC_BTNKWAPPLY
		xor		edx,edx
		call	EnButton
		invoke SaveKeyWordList,hWin,IDC_LSTKWACTIVE,nKWInx
		invoke SaveKeyWordList,hWin,IDC_LSTKWHOLD,16
		invoke UpdateKeyWords,hWin
		invoke GetDlgItemInt,hWin,IDC_EDTTABSIZE,NULL,FALSE
		mov		edopt.tabsize,eax
		invoke IsDlgButtonChecked,hWin,IDC_CHKEXPAND
		mov		edopt.exptabs,eax
		invoke IsDlgButtonChecked,hWin,IDC_CHKAUTOINDENT
		mov		edopt.indent,eax
		invoke IsDlgButtonChecked,hWin,IDC_CHKHILITELINE
		mov		edopt.hiliteline,eax
		invoke IsDlgButtonChecked,hWin,IDC_CHKHILITECMNT
		mov		edopt.hilitecmnt,eax
		invoke IsDlgButtonChecked,hWin,IDC_CHKSESSION
		mov		edopt.session,eax
		invoke IsDlgButtonChecked,hWin,IDC_CHKLINENUMBER
		mov		edopt.linenumber,eax
		push	edi
		mov		edi,offset col
		xor		eax,eax
	  @@:
		push	eax
		invoke SendDlgItemMessage,hWin,IDC_LSTCOLORS,LB_GETITEMDATA,eax,0
		mov		[edi],eax
		pop		eax
		inc		eax
		add		edi,4
		cmp		edi,offset col+sizeof col
		jc		@b
		pop		edi
		.if hCFnt
			invoke DeleteObject,hFont
			invoke DeleteObject,hIFont
			invoke GetObject,hCFnt,sizeof lfnt,offset lfnt
			mov		eax,hCFnt
			mov     hFont,eax
			mov		lfnt.lfItalic,TRUE
			invoke CreateFontIndirect,offset lfnt
			mov     hIFont,eax
			mov		lfnt.lfItalic,FALSE
;			invoke UpdateAll,WM_SETFONT
			invoke RegSetValueEx,hReg,addr szCodeFont,0,REG_BINARY,addr lfnt,sizeof lfnt
			mov		hCFnt,0
		.endif
		.if hLFnt
			invoke DeleteObject,hLnrFont
			invoke GetObject,hLFnt,sizeof lfntlnr,offset lfntlnr
			mov		eax,hLFnt
			mov     hLnrFont,eax
;			invoke UpdateAll,WM_SETFONT
			invoke RegSetValueEx,hReg,addr szLnrFont,0,REG_BINARY,addr lfntlnr,sizeof lfntlnr
			mov		hLFnt,0
		.endif
		invoke UpdateAll,WM_SETFONT
		invoke UpdateToolColors
		invoke RegSetValueEx,hReg,addr szEditOpt,0,REG_BINARY,addr edopt,sizeof edopt
		invoke RegSetValueEx,hReg,addr szColor,0,REG_BINARY,addr col,sizeof col
		invoke RegSetValueEx,hReg,addr szCustColors,0,REG_BINARY,addr CustColors,sizeof CustColors
	.endif
	retn

KeyWordsProc endp
