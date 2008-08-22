.code

DwToAscii proc uses ebx esi edi,dwVal:DWORD,lpAscii:DWORD

	mov		eax,dwVal
	mov		edi,lpAscii
	or		eax,eax
	jns		pos
	mov		byte ptr [edi],'-'
	neg		eax
	inc		edi
  pos:      
	mov		ecx,429496730
	mov		esi,edi
  @@:
	mov		ebx,eax
	mul		ecx
	mov		eax,edx
	lea		edx,[edx*4+edx]
	add		edx,edx
	sub		ebx,edx
	add		bl,'0'
	mov		[edi],bl
	inc		edi
	or		eax,eax
	jne		@b
	mov		byte ptr [edi],al
	.while esi<edi
		dec		edi
		mov		al,[esi]
		mov		ah,[edi]
		mov		[edi],al
		mov		[esi],ah
		inc		esi
	.endw
	ret

DwToAscii endp

DoToolBar proc hInst:DWORD,hToolBar:HWND
	LOCAL	tbab:TBADDBITMAP

	;Set toolbar struct size
	invoke SendMessage,hToolBar,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0
	;Set toolbar bitmap
	push	hInst
	pop		tbab.hInst
	mov		tbab.nID,IDB_TBRBMP
	invoke SendMessage,hToolBar,TB_ADDBITMAP,15,addr tbab
	;Set toolbar buttons
	invoke SendMessage,hToolBar,TB_ADDBUTTONS,ntbrbtns,offset tbrbtns
	mov		eax,hToolBar
	ret

DoToolBar endp

SetWinCaption proc lpFileName:DWORD
	LOCAL	buffer[sizeof szAppName+3+MAX_PATH]:BYTE
	LOCAL	buffer1[4]:BYTE

	;Add filename to windows caption
	invoke lstrcpy,addr buffer,offset szAppName
	mov		eax,' - '
	mov		dword ptr buffer1,eax
	invoke lstrcat,addr buffer,addr buffer1
	invoke lstrcat,addr buffer,lpFileName
	invoke SetWindowText,hWnd,addr buffer
	ret

SetWinCaption endp

SetFormat proc hWin:HWND
	LOCAL	rafnt:RAFONT

	mov		eax,hFont
	mov		rafnt.hFont,eax
	mov		eax,hIFont
	mov		rafnt.hIFont,eax
	mov		eax,hLnrFont
	mov		rafnt.hLnrFont,eax
	;Set fonts
	invoke SendMessage,hWin,REM_SETFONT,0,addr rafnt
	;Set tab width & expand tabs
	invoke SendMessage,hWin,REM_TABWIDTH,edopt.tabsize,edopt.exptabs
	;Set autoindent
	invoke SendMessage,hWin,REM_AUTOINDENT,0,edopt.indent
	;Set number of lines mouse wheel will scroll
	;NOTE! If you have mouse software installed, set to 0
	invoke SendMessage,hWin,REM_MOUSEWHEEL,3,0
	;Set selection bar width
;	invoke SendMessage,hWin,REM_SELBARWIDTH,20,0
	;Set linenumber width
;	invoke SendMessage,hWin,REM_LINENUMBERWIDTH,40,0
	ret

SetFormat endp

ShowPos proc nLine:DWORD,nPos:DWORD
	LOCAL	buffer[64]:BYTE

	mov		edx,nLine
	inc		edx
	invoke DwToAscii,edx,addr buffer[4]
	mov		dword ptr buffer,' :nL'
	invoke lstrlen,addr buffer
	mov		dword ptr buffer[eax],'soP '
	mov		dword ptr buffer[eax+4],' :'
	mov		edx,nPos
	inc		edx
	invoke DwToAscii,edx,addr buffer[eax+6]
	invoke SetDlgItemText,hWnd,IDC_SBR,addr buffer
	ret

ShowPos endp

RemoveFileExt proc lpFileName:DWORD

	invoke lstrlen,lpFileName
	mov		edx,lpFileName
	.while eax
		dec		eax
		.if byte ptr [edx+eax]=='.'
			mov		byte ptr [edx+eax],0
			.break
		.endif
	.endw
	ret

RemoveFileExt endp

RemoveFileName proc lpFileName:DWORD

	invoke lstrlen,lpFileName
	mov		edx,lpFileName
	.while eax
		dec		eax
		.if byte ptr [edx+eax]=='\'
			mov		byte ptr [edx+eax+1],0
			.break
		.endif
	.endw
	ret

RemoveFileName endp

MakeKey proc lpszStr:DWORD,nInx:DWORD,lpszKey:DWORD

	invoke lstrcpy,lpszKey,lpszStr
	invoke lstrlen,lpszKey
	add		eax,lpszKey
	invoke DwToAscii,nInx,eax
	ret

MakeKey endp

SetKeyWords proc uses esi edi
	LOCAL	hMem:DWORD
	LOCAL	nInx:DWORD
	LOCAL	buffer[64]:BYTE

	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,65536*4
	mov		hMem,eax
	invoke SetHiliteWords,0,0
	mov		nInx,0
	.while nInx<16
		invoke RtlZeroMemory,hMem,65536*4
		invoke MakeKey,offset szGroup,nInx,addr buffer
		mov		lpcbData,65536*4
		invoke RegQueryValueEx,hReg,addr buffer,0,addr lpType,hMem,addr lpcbData
		mov		ecx,hMem
		mov		edx,nInx
		shl		edx,2
		.if !byte ptr [ecx]
			mov		ecx,kwofs[edx]
		.endif
		invoke SetHiliteWords,kwcol[edx],ecx
		inc		nInx
	.endw
;	invoke RtlZeroMemory,hMem,65536*4
	mov		esi,hApiCallMem
	mov		edi,hMem
	.while byte ptr [esi]
		mov		byte ptr [edi],'^'
		inc		edi
		invoke lstrcpy,edi,esi
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
		lea		edi,[edi+eax]
		mov		byte ptr [edi],' '
		inc		edi
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,kwcol[15*4],hMem
	invoke GlobalFree,hMem
	ret

SetKeyWords endp

IndentComment proc uses esi,nChr:DWORD,fN:DWORD
	LOCAL	ochr:CHARRANGE
	LOCAL	chr:CHARRANGE
	LOCAL	LnSt:DWORD
	LOCAL	LnEn:DWORD
	LOCAL	buffer[32]:BYTE

	invoke SendMessage,hREd,WM_SETREDRAW,FALSE,0
	invoke SendMessage,hREd,REM_LOCKUNDOID,TRUE,0
	.if fN
		mov		eax,nChr
		mov		dword ptr buffer[0],eax
	.endif
	invoke SendMessage,hREd,EM_EXGETSEL,0,addr ochr
	invoke SendMessage,hREd,EM_EXGETSEL,0,addr chr
	invoke SendMessage,hREd,EM_HIDESELECTION,TRUE,0
	invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,chr.cpMin
	mov		LnSt,eax
	mov		eax,chr.cpMax
	dec		eax
	invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,eax
	mov		LnEn,eax
  nxt:
	mov		eax,LnSt
	.if eax<=LnEn
		invoke SendMessage,hREd,EM_LINEINDEX,LnSt,0
		mov		chr.cpMin,eax
		inc		LnSt
		.if fN
			mov		chr.cpMax,eax
			invoke SendMessage,hREd,EM_EXSETSEL,0,addr chr
			invoke SendMessage,hREd,EM_REPLACESEL,TRUE,addr buffer
			invoke lstrlen,addr buffer
			add		ochr.cpMax,eax
			jmp		nxt
		.else
			invoke SendMessage,hREd,EM_LINEINDEX,LnSt,0
			mov		chr.cpMax,eax
			invoke SendMessage,hREd,EM_EXSETSEL,0,addr chr
			invoke SendMessage,hREd,EM_GETSELTEXT,0,addr LineTxt
			mov		esi,offset LineTxt
			xor		eax,eax
			mov		al,[esi]
			.if eax==nChr
				inc		esi
				invoke SendMessage,hREd,EM_REPLACESEL,TRUE,esi
				dec		ochr.cpMax
			.elseif nChr==09h
				mov		ecx,edopt.tabsize
				dec		esi
			  @@:
				inc		esi
				mov		al,[esi]
				cmp		al,' '
				jne		@f
				loop	@b
				inc		esi
			  @@:
				.if al==09h
					inc		esi
					dec		ecx
				.endif
				mov		eax,edopt.tabsize
				sub		eax,ecx
				sub		ochr.cpMax,eax
				invoke SendMessage,hREd,EM_REPLACESEL,TRUE,esi
			.endif
			jmp		nxt
		.endif
	.endif
	invoke SendMessage,hREd,EM_EXSETSEL,0,addr ochr
	invoke SendMessage,hREd,EM_HIDESELECTION,FALSE,0
	invoke SendMessage,hREd,EM_SCROLLCARET,0,0
	invoke SendMessage,hREd,REM_LOCKUNDOID,FALSE,0
	invoke SendMessage,hREd,WM_SETREDRAW,TRUE,0
	invoke SendMessage,hREd,REM_REPAINT,0,0
	ret

IndentComment endp

GetSelText proc lpBuff:DWORD
	LOCAL	chrg:CHARRANGE

	invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
	mov		eax,chrg.cpMax
	sub		eax,chrg.cpMin
	.if eax && eax<256
		invoke SendMessage,hREd,EM_GETSELTEXT,0,lpBuff
	.endif
	ret

GetSelText endp

ParseCmnd proc uses esi edi,lpStr:DWORD,lpCmnd:DWORD,lpParam:DWORD

	mov		esi,lpStr
	call	SkipSpc
	mov		edi,lpCmnd
	mov		al,[esi]
	.if al=='"'
		inc		esi
		call	CopyQuoted
	.else
		call	CopyToSpace
	.endif
	call	SkipSpc
	mov		edi,lpParam
	mov		al,[esi]
	.if al=='"'
		inc		esi
		call	CopyQuoted
	.else
		call	CopyAll
	.endif
	ret

SkipSpc:
	.while byte ptr [esi]==' '
		inc		esi
	.endw
	retn

CopyQuoted:
	mov		al,[esi]
	.if al
		inc		esi
		.if al!='"'
			.if al=='$'
				call	CopyPro
			.else
				mov		[edi],al
				inc		edi
				jmp		CopyQuoted
			.endif
		.endif
		xor		al,al
	.endif
	mov		[edi],al
	retn

CopyToSpace:
	mov		al,[esi]
	.if al
		inc		esi
		.if al!=' '
			.if al=='$'
				call	CopyPro
			.else
				mov		[edi],al
				inc		edi
				jmp		CopyToSpace
			.endif
		.endif
		xor		al,al
	.endif
	mov		[edi],al
	retn

CopyAll:
	mov		al,[esi]
	.if al
		inc		esi
		.if al=='$'
			call	CopyPro
		.else
			mov		[edi],al
			inc		edi
			jmp		CopyAll
		.endif
		xor		al,al
	.endif
	mov		[edi],al
	retn

CopyPro:
	push	esi
	mov		esi,offset FileName
	.while al!='.' && al
		mov		al,[esi]
		.if al!='.' && al
			mov		[edi],al
			inc		esi
			inc		edi
		.endif
	.endw
	pop		esi
	.while byte ptr [esi]
		mov		al,[esi]
		.if al!='"'
			mov		[edi],al
		.endif
		inc		esi
		inc		edi
	.endw
	xor		al,al
	mov		[edi],al
	retn

ParseCmnd endp
