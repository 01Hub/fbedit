
CCTYPE_NONE				equ 0
CCTYPE_PROC				equ 1
CCTYPE_TOOLTIP			equ 2
CCTYPE_CONST			equ 3
CCTYPE_ALL				equ 4
CCTYPE_STRUCT			equ 5

.const

szCCInvoke				db 'INVOKE',0
szCCPp					db 'Pp',0
szCCp					db 'p',0
szCCC					db 'C',0
szCCAll					db 'WScds',0
szCCSs					db 'Ss',0
szCCd					db 'd',0
szCCAssume				db 'assume ',0

.data?

lpOldCCProc				dd ?
ccchrg					CHARRANGE <?>
cctype					dd ?
ccinprogress			dd ?
cclist					db 16384 dup(?)

.code

CodeCompleteProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_CHAR
		mov		eax,wParam
		.if eax==VK_TAB || eax==VK_RETURN
			invoke SendMessage,hREd,WM_CHAR,VK_TAB,0
			jmp		Ex
		.elseif eax==VK_ESCAPE
			invoke ShowWindow,hWin,SW_HIDE
			jmp		Ex
		.endif
	.elseif eax==WM_LBUTTONDBLCLK
		invoke SendMessage,hREd,WM_CHAR,VK_TAB,0
		jmp		Ex
	.endif
	invoke CallWindowProc,lpOldCCProc,hWin,uMsg,wParam,lParam
  Ex:
	ret

CodeCompleteProc endp

CreateCodeComplete proc

	invoke CreateWindowEx,NULL,addr szCCLBClassName,NULL,WS_CHILD or WS_BORDER or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or STYLE_USEIMAGELIST,0,0,0,0,hWnd,NULL,hInstance,0
	mov		hCCLB,eax
	invoke SetWindowLong,hCCLB,GWL_WNDPROC,offset CodeCompleteProc
	mov		lpOldCCProc,eax
	invoke CreateWindowEx,NULL,addr szCCTTClassName,NULL,WS_POPUP or WS_BORDER or WS_CLIPSIBLINGS or WS_CLIPCHILDREN,0,0,0,0,hWnd,NULL,hInstance,0
	mov		hCCTT,eax
	invoke SendMessage,hTab,WM_GETFONT,0,0
	push	eax
	invoke SendMessage,hCCLB,WM_SETFONT,eax,FALSE
	pop		eax
	invoke SendMessage,hCCTT,WM_SETFONT,eax,FALSE
	ret

CreateCodeComplete endp

AddList proc uses esi edi,lpList:DWORD,lpWord:DWORD,nImg:DWORD
	LOCAL	nCount:DWORD

	mov		nCount,0
	mov		esi,lpList
	mov		edi,offset cclist
	.while byte ptr [esi]
		call	Filter
		.if !eax
			push	edi
			.while byte ptr [esi] && byte ptr [esi]!=','
				mov		al,[esi]
				mov		[edi],al
				inc		esi
				inc		edi
			.endw
			mov		byte ptr [edi],0
			inc		edi
			pop		eax
			invoke SendMessage,hCCLB,CCM_ADDITEM,nImg,eax
			inc		nCount
		.else
			.while byte ptr [esi] && byte ptr [esi]!=','
				inc		esi
			.endw
		.endif
		.if byte ptr [esi]
			inc		esi
		.endif
	.endw
	mov		eax,nCount
	ret

Filter:
	mov		edx,lpWord
	mov		ecx,esi
  @@:
	mov		al,[edx]
	.if al==VK_SPACE || al==VK_TAB || al==','
		xor		al,al
	.endif
	.if al
		mov		ah,[ecx]
		.if al>='a' && al<='z'
			and		al,5Fh
		.endif
		.if ah>='a' && ah<='z'
			and		ah,5Fh
		.endif
		inc		edx
		inc		ecx
		sub		al,ah
		je		@b
	.endif
	movsx	eax,al
	retn

AddList endp

IsWordReg proc lpWord:DWORD

	invoke strlen,lpWord
	.if eax==3
		mov		eax,lpWord
		mov		eax,[eax]
		and		eax,5F5F5Fh
		.if eax=='RTP'
			mov		eax,2
		.elseif eax=='XAE'
			mov		eax,1
		.elseif eax=='XBE'
			mov		eax,1
		.elseif eax=='XCE'
			mov		eax,1
		.elseif eax=='XDE'
			mov		eax,1
		.elseif eax=='ISE'
			mov		eax,1
		.elseif eax=='IDE'
			mov		eax,1
		.elseif eax=='PBE'
			mov		eax,1
		.elseif eax=='PSE'
			mov		eax,1
		.elseif eax=='RTP'
			mov		eax,1
		.else
			xor		eax,eax
		.endif
	.else
		xor		eax,eax
	.endif
	ret

IsWordReg endp

IsWordStruct proc uses esi,lpWord:DWORD

	invoke SendMessage,hProperty,PRM_FINDFIRST,offset szCCSs,lpWord
	.while TRUE
		.break .if !eax
		mov		esi,eax
		invoke strcmp,esi,lpWord
		.if !eax
			mov		eax,esi
			ret
		.endif
		invoke SendMessage,hProperty,PRM_FINDNEXT,0,0
	.endw
	ret

IsWordStruct endp

IsWordLocalStruct proc uses esi edi,lpLocal:DWORD,lpWord:DWORD,lpBuff:DWORD

	mov		eax,lpBuff
	mov		byte ptr [eax],0
	mov		edi,lpWord
	mov		esi,lpLocal
	; Skip proc name
	invoke strlen,esi
	lea		esi,[esi+eax+1]
	; Point to parameters
	invoke strcpy,lpBuff,edi
	invoke SendMessage,hProperty,PRM_FINDITEMDATATYPE,lpBuff,esi
	mov		eax,lpBuff
	.if !byte ptr [eax]
		; Skip proc parameters
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		; Skip return type
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		; Point to local
		invoke strcpy,lpBuff,edi
		invoke SendMessage,hProperty,PRM_FINDITEMDATATYPE,lpBuff,esi
	.endif
	mov		eax,lpBuff
	movzx	eax,byte ptr [eax]
	ret

IsWordLocalStruct endp

IsWordDataStruct proc uses esi edi,lpWord:DWORD,lpBuff:DWORD

	invoke SendMessage,hProperty,PRM_FINDFIRST,offset szCCd,lpWord
	.while TRUE
		.break .if !eax
		mov		esi,eax
		invoke strcmp,esi,lpWord
		.if !eax
			invoke strlen,esi
			lea		esi,[esi+eax+1]
			invoke strcpy,lpBuff,esi
			mov		eax,esi
			.break
		.endif
		invoke SendMessage,hProperty,PRM_FINDNEXT,0,0
	.endw
	ret

IsWordDataStruct endp

IsStructItemStruct proc uses esi edi,lpStruct:DWORD,lpItem:DWORD
	LOCAL	buffer[256]:BYTE

	mov		buffer,0
	invoke SendMessage,hProperty,PRM_FINDFIRST,offset szCCSs,lpStruct
	.while TRUE
		.break .if !eax
		mov		esi,eax
		invoke strcmp,esi,lpStruct
		.if !eax
			invoke strlen,esi
			lea		esi,[esi+eax+1]
			invoke strcpy,addr buffer,lpItem
			invoke SendMessage,hProperty,PRM_FINDITEMDATATYPE,addr buffer,esi
			.if buffer
				invoke strcpy,lpStruct,addr buffer
			.endif
			movzx	eax,buffer
			.break
		.endif
		invoke SendMessage,hProperty,PRM_FINDNEXT,0,0
	.endw
	ret

IsStructItemStruct endp

UpdateApiList proc uses ebx esi edi,lpWord:DWORD,lpApiType:DWORD
	LOCAL	nCount:DWORD
	LOCAL	nWords:DWORD
	LOCAL	buffer[256]:BYTE
	LOCAL	isinproc:ISINPROC
	LOCAL	lpLineWord:DWORD
	LOCAL	lpReg:DWORD
	LOCAL	ccft:FINDTEXTEX

	mov		nCount,0
	mov		edi,hCCLB
	invoke SendMessage,edi,CCM_CLEAR,0,0
	invoke SendMessage,edi,WM_SETREDRAW,FALSE,0
	mov		eax,lpWord
	mov		edx,lpApiType
	.if cctype==CCTYPE_STRUCT
		; rect.left
		; [edx].RECT.left
		; RECT.left[edx]
		; [edx][RECT.left]
		; [edx + RECT.left]
		; [edx.RECT.left]
		; (RECT ptr [edx]).left
		; assume edx:ptr RECT
		; [edx].left
		mov		esi,offset LineTxt
		mov		edi,esi
		xor		edx,edx
		mov		nWords,edx
		mov		lpReg,edx
		.while byte ptr [esi]
			mov		al,[esi]
			.if al==VK_SPACE || al==VK_TAB || al==','
				.if !edx
					mov		edi,offset LineTxt
					mov		nWords,0
				.elseif byte ptr [edi-1]
					inc		nWords
					mov		byte ptr [edi],0
					inc		edi
				.endif
			.elseif al=='('
				inc		edx
				.if byte ptr [edi-1]
					inc		nWords
					mov		byte ptr [edi],0
					inc		edi
				.endif
			.elseif al==')'
				inc		edx
				.if byte ptr [edi-1]
					inc		nWords
					mov		byte ptr [edi],0
					inc		edi
				.endif
			.elseif al=='['
				inc		edx
				.if byte ptr [edi-1]
					inc		nWords
					mov		byte ptr [edi],0
					inc		edi
				.endif
			.elseif al==']'
				inc		edx
				.if byte ptr [edi-1]
					inc		nWords
					mov		byte ptr [edi],0
					inc		edi
				.endif
			.elseif al=='+'
				inc		edx
				.if byte ptr [edi-1]
					inc		nWords
					mov		byte ptr [edi],0
					inc		edi
				.endif
			.elseif al=='.'
				.if byte ptr [edi-1]
					inc		nWords
					mov		byte ptr [edi],0
					inc		edi
				.endif
			.else
				mov		[edi],al
				inc		edi
			.endif
			inc		esi
		.endw
		mov		word ptr [edi],0
		.if byte ptr [edi-1]
			inc		nWords
		.endif
		.if nWords
			mov		lpLineWord,0
			mov		buffer,0
			mov		edi,offset LineTxt
			.while byte ptr [edi]
				invoke IsWordReg,edi
				.if eax==1
					; reg
					mov		lpReg,edi
				.elseif eax==2
					; ptr
				.else
					.if !lpLineWord
						mov		lpLineWord,edi
					.endif
					invoke IsWordStruct,edi
					.break .if eax
				.endif
				invoke strlen,edi
				lea		edi,[edi+eax+1]
				xor		eax,eax
			.endw
			.if eax
				; [edx].RECT.left
				; RECT.left[edx]
				; [edx][RECT.left]
				; [edx + RECT.left]
				; [edx.RECT.left]
				; (RECT ptr [edx]).left
				invoke strcpy,addr buffer,edi
			.elseif lpLineWord && !lpReg
				;LOCAL rect:RECT
				; rect.left
				mov		edi,lpLineWord
				mov		eax,nLastLine
				mov		isinproc.nLine,eax
				mov		eax,hREd
				mov		isinproc.nOwner,eax
				mov		isinproc.lpszType,offset szCCp
				invoke SendMessage,hProperty,PRM_ISINPROC,0,addr isinproc
				.if eax
					mov		edx,eax
					invoke IsWordLocalStruct,edx,edi,addr buffer
				.endif
				.if !eax
					; rect	RECT <>
					; rect.left
					invoke IsWordDataStruct,edi,addr buffer
				.endif
			.elseif lpReg
				; assume edx:ptr RECT
				; [edx].left
				invoke SendMessage,hREd,EM_EXGETSEL,0,addr ccft.chrg
				mov		ccft.chrg.cpMax,0
				invoke strcpy,addr buffer,offset szCCAssume
				invoke strcat,addr buffer,lpReg
				lea		eax,buffer
				mov		ccft.lpstrText,eax
			  @@:
				invoke SendMessage,hREd,EM_FINDTEXTEX,FR_IGNOREWHITESPACE,addr ccft
				.if eax!=-1
					invoke SendMessage,hREd,REM_ISCHARPOS,ccft.chrgText.cpMax,0
					.if eax
						mov		eax,ccft.chrgText.cpMin
						dec		eax
						mov		ccft.chrg.cpMin,eax
						jmp		@b
					.endif
					invoke SendMessage,hREd,EM_LINEFROMCHAR,ccft.chrgText.cpMin,0
					mov		edx,eax
					invoke SendMessage,hREd,EM_GETLINE,edx,addr buffer
					mov		buffer[eax],0
					xor		eax,eax
					.while buffer[eax] && buffer[eax]!=':'
						inc		eax
					.endw
					.if buffer[eax]!=':'
						jmp		@b
					.endif
					inc		eax
					.while buffer[eax] && (buffer[eax]==VK_SPACE || buffer[eax]==VK_TAB)
						inc		eax
					.endw
					.if !buffer[eax]
						jmp		@b
					.endif
					mov		edx,dword ptr buffer[eax]
					and		edx,5F5F5Fh
					.if edx!='RTP'
						jmp		@b
					.endif
					add		eax,3
					.while buffer[eax] && (buffer[eax]==VK_SPACE || buffer[eax]==VK_TAB)
						inc		eax
					.endw
					lea		esi,buffer[eax]
					lea		edi,buffer
					.while TRUE
						movzx	eax,byte ptr [esi]
						invoke IsCharAlphaNumeric,eax
						.break .if !eax && byte ptr [esi]!='_'
						mov		al,[esi]
						mov		[edi],al
						inc		esi
						inc		edi
					.endw
					mov		byte ptr [edi],0
					mov		edi,lpReg
				.else
					; [edx].RECT
					mov		buffer,0
					mov		edi,hCCLB
					invoke SendMessage,hProperty,PRM_FINDFIRST,offset szCCSs,lpWord
					.while TRUE
						.break .if !eax
						push	eax
						invoke SendMessage,hProperty,PRM_FINDGETTYPE,0,0
						.if eax=='S'
							mov		ecx,4
						.else
							mov		ecx,5
						.endif
						pop		edx
						invoke SendMessage,edi,CCM_ADDITEM,ecx,edx
						inc		nCount
						invoke SendMessage,hProperty,PRM_FINDNEXT,0,0
					.endw
				.endif
			.endif
			.if buffer
				invoke strlen,edi
				inc		eax
				lea		edi,[edi+eax]
				.while byte ptr [edi]
					invoke IsWordReg,edi
					.if !eax
						invoke IsStructItemStruct,addr buffer,edi
						.break .if eax
						invoke strlen,edi
						lea		edi,[edi+eax+1]
						xor		eax,eax
					.else
						invoke strlen,edi
						lea		edi,[edi+eax+1]
					.endif
				.endw
				.if eax
					invoke IsWordStruct,addr buffer
					.if eax
						push	eax
						invoke strlen,eax
						pop		edx
						lea		edx,[edx+eax+1]
						invoke AddList,edx,lpWord,15
						mov		nCount,eax
					.endif
				.endif
			.endif
		.endif
	.elseif byte ptr [eax] || cctype==CCTYPE_ALL
		invoke SendMessage,hProperty,PRM_FINDFIRST,lpApiType,lpWord
		.while TRUE
			.break .if !eax
			push	eax
			invoke SendMessage,hProperty,PRM_FINDGETTYPE,0,0
			xor		ecx,ecx
			.if eax=='p'
				mov		ecx,1
			.elseif eax=='W'
				mov		ecx,2
			.elseif eax=='c'
				mov		ecx,3
			.elseif eax=='d'
				mov		ecx,14
			.elseif eax=='S'
				mov		ecx,4
			.elseif eax=='s'
				mov		ecx,5
			.endif
			pop		edx
			invoke SendMessage,edi,CCM_ADDITEM,ecx,edx
			inc		nCount
			invoke SendMessage,hProperty,PRM_FINDNEXT,0,0
		.endw
		.if cctype==CCTYPE_ALL
			mov		eax,nLastLine
			mov		isinproc.nLine,eax
			mov		eax,hREd
			mov		isinproc.nOwner,eax
			mov		isinproc.lpszType,offset szCCp
			invoke SendMessage,hProperty,PRM_ISINPROC,0,addr isinproc
			.if eax
				mov		esi,eax
				mov		ebx,offset cclist
				; Skip proc name and point to parameters
				invoke strlen,esi
				lea		esi,[esi+eax+1]
				.if byte ptr [esi]
					push	esi
					invoke strcpy,addr tmpbuff,esi
					invoke strcat,addr tmpbuff,addr szComma
					mov		esi,offset tmpbuff
					mov		edx,esi
					.while byte ptr [esi]
						.if byte ptr [esi]==','
							mov		byte ptr [esi],0
							call Filter
							.if !eax
								invoke strcpy,ebx,edx
								invoke SendMessage,edi,CCM_ADDITEM,8,ebx
								invoke strlen,ebx
								lea		ebx,[ebx+eax+1]
								inc		nCount
							.endif
							lea		edx,[esi+1]
						.endif
						inc		esi
					.endw
					pop		esi
				.endif
				; Skip return type
				invoke strlen,esi
				lea		esi,[esi+eax+1]
				; Point to locals
				invoke strlen,esi
				lea		esi,[esi+eax+1]
				invoke strcpy,addr tmpbuff,esi
				invoke strcat,addr tmpbuff,addr szComma
				mov		esi,offset tmpbuff
				mov		edx,esi
				.while byte ptr [esi]
					.if byte ptr [esi]==','
						mov		byte ptr [esi],0
						call Filter
						.if !eax
							invoke strcpy,ebx,edx
							invoke SendMessage,edi,CCM_ADDITEM,9,ebx
							invoke strlen,ebx
							lea		ebx,[ebx+eax+1]
							inc		nCount
						.endif
						lea		edx,[esi+1]
					.endif
					inc		esi
				.endw
			.endif
		.endif
	.endif
	mov		edi,hCCLB
	.if nCount
		.if cctype!=CCTYPE_STRUCT
			invoke SendMessage,edi,CCM_SORT,FALSE,0
		.endif
		invoke SendMessage,edi,CCM_SETCURSEL,0,0
	.endif
	invoke SendMessage,edi,WM_SETREDRAW,TRUE,0
	mov		eax,nCount
	ret

Filter:
	push	edx
	mov		ecx,lpWord
  @@:
	mov		al,[ecx]
	.if al
		mov		ah,[edx]
		.if al>='a' && al<='z'
			and		al,5Fh
		.endif
		.if ah>='a' && ah<='z'
			and		ah,5Fh
		.endif
		inc		edx
		inc		ecx
		sub		al,ah
		je		@b
	.endif
	movsx	eax,al
	pop		edx
	retn

UpdateApiList endp

UpdateApiConstList proc uses esi edi,lpApi:DWORD,lpWord:DWORD,lpCPos:DWORD

	invoke SendMessage,hCCLB,CCM_CLEAR,0,0
	invoke SendMessage,hProperty,PRM_FINDFIRST,addr szCCC,lpApi
	.if eax
		mov		esi,eax
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		mov		eax,lpWord
	  @@:
		.while (byte ptr [eax]==VK_SPACE || byte ptr [eax]==VK_TAB) && eax<lpCPos
			inc		eax
		.endw
		mov		lpWord,eax
		.while byte ptr [eax] && byte ptr [eax]!=',' && eax<lpCPos
			.if byte ptr [eax]==VK_SPACE || byte ptr [eax]==VK_TAB
				jmp		@b
			.endif
			inc		eax
		.endw
		invoke AddList,esi,lpWord,2
		.if eax
			invoke SendMessage,edi,CCM_SORT,FALSE,0
			invoke SendMessage,hCCLB,CCM_SETCURSEL,0,0
			mov		eax,lpWord
		.endif
		ret
	.endif
	xor		eax,eax
	ret

UpdateApiConstList endp

UpdateApiToolTip proc uses esi edi,lpWord:DWORD
	LOCAL	tt:TOOLTIP

	mov		eax,lpWord
	.if byte ptr [eax]
		invoke RtlZeroMemory,addr tt,sizeof TOOLTIP
		mov		tt.lpszType,offset szCCPp
		mov		eax,lpWord
		mov		tt.lpszLine,eax
		invoke SendMessage,hProperty,PRM_GETTOOLTIP,FALSE,addr tt
		.if tt.lpszApi
			invoke strlen,tt.lpszApi
			add		eax,tt.lpszApi
			inc		eax
			mov		edx,tt.lpszApi
			mov		ecx,tt.nPos
			jmp		Ex
		.endif
	.endif
	xor		eax,eax
	xor		ecx,ecx
	xor		edx,edx
  Ex:
	ret

UpdateApiToolTip endp

IsLineInvoke proc uses ebx,cpline:DWORD

	mov		edx,offset LineTxt
	mov		ebx,cpline
	call	SkipWhiteSpace
	mov		ecx,offset szCCInvoke
	dec		ecx
	dec		edx
	inc		ebx
  @@:
	inc		ecx
	inc		edx
	dec		ebx
	je		@f
	mov		al,[ecx]
	.if al
		mov		ah,[edx]
		.if ah>='a' && ah<='z'
			and		ah,5Fh
		.endif
		sub		al,ah
		je		@b
	.endif
	movsx	eax,al
	.if !eax
		call	SkipWhiteSpace
		mov		eax,edx
		sub		eax,offset LineTxt
	.else
  @@:
		xor		eax,eax
	.endif
	ret

SkipWhiteSpace:
	.while (byte ptr [edx]==VK_TAB || byte ptr [edx]==VK_SPACE) && ebx
		inc		edx
		dec		ebx
	.endw
	retn

IsLineInvoke endp

ApiListBox proc uses esi edi,lpRASELCHANGE:DWORD
	LOCAL	rect:RECT
	LOCAL	pt:POINT
	LOCAL	tti:TTITEM
	LOCAL	cpline:DWORD
	LOCAL	buffer[256]:BYTE

	mov		esi,lpRASELCHANGE
	mov		eax,[esi].RASELCHANGE.chrg.cpMin
	mov		edx,[esi].RASELCHANGE.cpLine
	mov		ccchrg.cpMin,edx
	mov		ccchrg.cpMax,eax
	sub		eax,edx
	mov		cpline,eax
	inc		eax
	mov		edx,[esi].RASELCHANGE.lpLine
	lea		edx,[edx+sizeof CHARS]
	invoke strcpyn,offset LineTxt,edx,eax
	.if cctype==CCTYPE_ALL
		invoke SendMessage,hREd,REM_GETWORD,sizeof buffer,addr buffer
		invoke strlen,addr buffer
		mov		edx,ccchrg.cpMax
		sub		edx,eax
		mov		ccchrg.cpMin,edx
		invoke UpdateApiList,addr buffer,offset szCCAll
		.if eax
			call	ShowList
		.endif
	.elseif cctype==CCTYPE_STRUCT
		invoke SendMessage,hREd,REM_GETWORD,sizeof buffer,addr buffer
		invoke strlen,addr buffer
		mov		edx,cpline
		sub		edx,eax
		mov		byte ptr LineTxt[edx-1],0
		mov		edx,ccchrg.cpMax
		sub		edx,eax
		mov		ccchrg.cpMin,edx
		invoke UpdateApiList,addr buffer,offset szCCSs
		.if eax
			call	ShowList
		.else
			call	HideAll
		.endif
	.else
		invoke IsLineInvoke,cpline
		.if eax
			add		ccchrg.cpMin,eax
			lea		esi,LineTxt[eax]
			invoke UpdateApiList,esi,offset szCCPp
			.if eax
				mov		cctype,CCTYPE_PROC
				call	ShowList
			.else
				invoke ShowWindow,hCCLB,SW_HIDE
				mov		cctype,CCTYPE_NONE
				lea		edx,buffer
				xor		ecx,ecx
				push	esi
				.while byte ptr [esi]
					mov		al,[esi]
					.if !ecx || al==','
						.if al==','
							inc		ecx
						.endif
						mov		[edx],al
						inc		edx
					.endif
					inc		esi
				.endw
				pop		esi
				mov		byte ptr [edx],0
				invoke UpdateApiToolTip,addr buffer
				.if eax
					mov		cctype,CCTYPE_TOOLTIP
					mov		tti.lpszRetType,0
					mov		tti.lpszDesc,0
					mov		tti.novr,0
					mov		tti.nsel,0
					mov		tti.nwidth,0
					mov		tti.lpszApi,edx
					mov		tti.lpszParam,eax
					mov		tti.nitem,ecx
					inc		ecx
					invoke DwToAscii,ecx,addr buffer
					invoke strcat,addr buffer,tti.lpszApi
					mov		eax,cpline
					add		eax,offset LineTxt
					sub		eax,esi
					xor		ecx,ecx
					xor		edx,edx
					.while edx<eax
						.if byte ptr [esi+edx]=="'"
							inc		edx
							.while edx<eax && byte ptr [esi+edx]!="'"
								inc		edx
							.endw
						.elseif byte ptr [esi+edx]=='"'
							inc		edx
							.while edx<eax && byte ptr [esi+edx]!='"'
								inc		edx
							.endw
						.elseif byte ptr [esi+edx]==','
							inc		ecx
							lea		edi,[esi+edx+1]
						.endif
						inc		edx
					.endw
					mov		eax,cpline
					add		eax,offset LineTxt
					invoke UpdateApiConstList,addr buffer,edi,eax
					.if eax
						mov		cctype,CCTYPE_CONST
						mov		edi,eax
						sub		edi,offset LineTxt
						mov		esi,lpRASELCHANGE
						add		edi,[esi].RASELCHANGE.cpLine
						mov		ccchrg.cpMin,edi
						mov		eax,[esi].RASELCHANGE.chrg.cpMin
						sub		eax,[esi].RASELCHANGE.cpLine
						.while byte ptr LineTxt[eax] && byte ptr LineTxt[eax]!=VK_SPACE && byte ptr LineTxt[eax]!=VK_TAB && byte ptr LineTxt[eax]!=','
							inc		eax
						.endw
						add		eax,[esi].RASELCHANGE.cpLine
						mov		ccchrg.cpMax,eax
						call	ShowList
					.else
						mov		cctype,CCTYPE_TOOLTIP
						invoke ShowWindow,hCCLB,SW_HIDE
						invoke GetCaretPos,addr pt
						invoke ClientToScreen,hREd,addr pt
						add		pt.y,20
						invoke SendMessage,hCCTT,TTM_SETITEM,0,addr tti
						sub		pt.x,eax
						invoke SetWindowPos,hCCTT,HWND_TOP,pt.x,pt.y,0,0,SWP_NOACTIVATE or SWP_NOSIZE
						invoke ShowWindow,hCCTT,SW_SHOWNA
						invoke InvalidateRect,hCCTT,NULL,TRUE
					.endif
				.else
					call	HideAll
				.endif
			.endif
		.else
			call	HideAll
		.endif
	.endif
	ret

HideAll:
	mov		cctype,CCTYPE_NONE
	invoke ShowWindow,hCCTT,SW_HIDE
	invoke ShowWindow,hCCLB,SW_HIDE
	retn

ShowList:
	invoke ShowWindow,hCCTT,SW_HIDE
	invoke GetCaretPos,addr pt
	invoke ClientToScreen,hREd,addr pt
	invoke ScreenToClient,hWnd,addr pt
	invoke GetClientRect,hWnd,addr rect
	mov		eax,pt.y
	add		eax,150+20
	.if eax>rect.bottom
		sub		pt.y,155
	.else
		add		pt.y,20
	.endif
	invoke SetWindowPos,hCCLB,HWND_TOP,pt.x,pt.y,200,150,SWP_SHOWWINDOW or SWP_NOACTIVATE
	invoke ShowWindow,hCCLB,SW_SHOWNA
	retn

ApiListBox endp
