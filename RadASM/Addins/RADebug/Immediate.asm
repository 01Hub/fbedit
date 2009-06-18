.const

; Commands
szImmDump						db 'DUMP',0
szImmVars						db 'VARS',0
szImmTypes						db 'TYPES',0
szImmCls						db 'CLS',0
szImmWatch						db 'WATCH',0

szImmLocal						db 0Dh,'LOCAL: ',0

.code

ParseBuff proc uses esi edi,lpBuff:DWORD

	mov		esi,lpBuff
	mov		edi,esi
	.if byte ptr [esi]=='>'
		inc		esi
	.endif
	.while TRUE
		mov		al,[esi]
		.if al!=VK_SPACE && al!=VK_TAB
			mov		[edi],al
			inc		edi
		.endif
		.break .if !al
		inc		esi
	.endw
	ret

ParseBuff endp

ParseWatch proc uses ebx esi edi,lpList:DWORD

	mov		edi,offset szWatchList
	invoke RtlZeroMemory,edi,sizeof szWatchList
	mov		esi,lpList
	.while byte ptr [esi]
		call	SkipWhiteSpace
		call	AddWatchVar
	.endw
;	mov		edi,offset szWatchList
;	.while byte ptr [edi]
;		PrintStringByAddr edi
;		invoke lstrlen,edi
;		lea		edi,[edi+eax+1]
;	.endw
	ret

AddWatchVar:
	xor		ecx,ecx
	.while byte ptr [esi] && byte ptr [esi]!=','
		mov		al,[esi]
		.if al!=VK_SPACE && al!=VK_TAB
			inc		ecx
			mov		[edi],al
			inc		edi
		.endif
		inc		esi
	.endw
	.if byte ptr [esi]==','
		inc		esi
	.endif
	.if ecx
		inc		edi
	.endif
	retn

SkipWhiteSpace:
	.while byte ptr [esi]==VK_SPACE || byte ptr [esi]==VK_TAB
		inc		esi
	.endw
	retn

ParseWatch endp

Immediate proc uses ebx esi edi,hWin:HWND
	LOCAL	chrg:CHARRANGE
	LOCAL	buffer[256]:BYTE
	LOCAL	val:DWORD
	LOCAL	tmpvar:VAR

	invoke SendMessage,hWin,EM_EXGETSEL,0,addr chrg
	invoke SendMessage,hWin,EM_LINEFROMCHAR,chrg.cpMin,0
	mov		edx,eax
	mov		word ptr buffer,255
	invoke SendMessage,hWin,EM_GETLINE,edx,addr buffer
	mov		buffer[eax],0
	invoke SendMessage,hWin,EM_REPLACESEL,FALSE,addr szCR
	invoke ParseBuff,addr buffer
	invoke lstrcmpi,addr buffer,addr szImmDump
	.if !eax
		invoke ClearBreakPointsAll
		mov		esi,400000h
		.while TRUE
			invoke ReadProcessMemory,dbg.hdbghand,esi,addr buffer,16,NULL
			.break .if !eax
			invoke DumpLine,hOut3,esi,addr buffer,16
			add		esi,16
		.endw
		invoke SetBreakPointsAll
		jmp		Ex
	.endif
	invoke lstrcmpi,addr buffer,addr szImmTypes
	.if !eax
		mov		esi,dbg.hMemType
		xor		ebx,ebx
		.while ebx<dbg.inxtype
			invoke wsprintf,addr outbuffer,addr szType,addr [esi].DEBUGTYPE.szName,[esi].DEBUGTYPE.nSize
			invoke PutStringOut,addr outbuffer,hOut3
			lea		esi,[esi+sizeof DEBUGTYPE]
			inc		ebx
		.endw
		jmp		Ex
	.endif
	invoke lstrcmpi,addr buffer,addr szImmVars
	.if !eax
		mov		esi,dbg.hMemSymbol
		mov		ecx,dbg.inxsymbol
		.while ecx
			push	ecx
			.if [esi].DEBUGSYMBOL.nType=='d'
				mov		edi,[esi].DEBUGSYMBOL.lpType
				.if edi
					invoke lstrcpy,addr outbuffer,addr [edi+sizeof DEBUGVAR]
					invoke lstrlen,addr [edi+sizeof DEBUGVAR]
					invoke lstrcat,addr outbuffer,addr [edi+eax+1+sizeof DEBUGVAR]
					invoke PutStringOut,addr outbuffer,hOut3
				.endif
			.elseif [esi].DEBUGSYMBOL.nType=='p'
				invoke lstrcpy,addr outbuffer,addr [esi].DEBUGSYMBOL.szName
				mov		edi,[esi].DEBUGSYMBOL.lpType
				.if edi
					mov		ebx,offset szSpace
					lea		edi,[edi+sizeof DEBUGVAR]
					.while byte ptr [edi]
						invoke lstrcat,addr outbuffer,ebx
						invoke lstrcat,addr outbuffer,edi
						invoke lstrlen,edi
						lea		edi,[edi+eax+1]
						invoke lstrcat,addr outbuffer,edi
						invoke lstrlen,edi
						lea		edi,[edi+eax+1]
						lea		edi,[edi+sizeof DEBUGVAR]
						mov		ebx,offset szComma
					.endw
					mov		ebx,offset szImmLocal
					lea		edi,[edi+sizeof DEBUGVAR+2]
					.while byte ptr [edi]
						invoke lstrcat,addr outbuffer,ebx
						invoke lstrcat,addr outbuffer,edi
						invoke lstrlen,edi
						lea		edi,[edi+eax+1]
						invoke lstrcat,addr outbuffer,edi
						invoke lstrlen,edi
						lea		edi,[edi+eax+1]
						lea		edi,[edi+sizeof DEBUGVAR]
						mov		ebx,offset szComma
					.endw
				.endif
				invoke PutStringOut,addr outbuffer,hOut3
			.endif
			pop		ecx
			lea		esi,[esi+sizeof DEBUGSYMBOL]
			dec		ecx
		.endw
		jmp		Ex
	.endif
	invoke lstrcmpi,addr buffer,addr szImmCls
	.if !eax
		invoke SetWindowText,hOut3,addr szNULL
		jmp		Ex
	.endif
	invoke strcmpin,addr buffer,addr szImmWatch,5
	.if !eax
		invoke ParseWatch,addr buffer[5]
		jmp		Ex
	.endif
	.if buffer=='?'
		invoke GetVarVal,addr buffer[1],dbg.prevline,TRUE
		.if eax
			invoke PutStringOut,addr outbuffer,hOut3
		.else
			invoke PutStringOut,addr szImmNotFound,hOut3
		.endif
		jmp		Ex
	.endif
	xor ebx,ebx
	.while buffer[ebx]
		.if buffer[ebx]=='='
			mov		buffer[ebx],0
			inc		ebx
			invoke GetVarAdr,addr buffer,dbg.prevline
			.if eax
				push	eax
				invoke RtlMoveMemory,addr tmpvar,addr var,sizeof VAR
				invoke GetVarVal,addr buffer[ebx],dbg.prevline,FALSE
				push	eax
				mov		eax,var.Value
				mov		val,eax
				invoke RtlMoveMemory,addr var,addr tmpvar,sizeof VAR
				pop		edx
				pop		eax
			.endif
			.if (eax=='d' || eax=='P' || eax=='L') && edx
				; GLOBAL, PROC Parameter or LOCAL
				invoke WriteProcessMemory,dbg.hdbghand,var.Address,addr val,var.nSize,0
				invoke GetVarVal,addr buffer,dbg.prevline,TRUE
				invoke PutStringOut,addr outbuffer,hOut3
			.elseif eax=='R' && edx
				; REGISTER
				mov		eax,var.Address
				mov		eax,[eax]
				mov		edx,var.nSize
				.if edx==2
					mov		ax,word ptr val
				.elseif edx==1
					mov		al,byte ptr val
				.elseif edx==3
					mov		ah,byte ptr val
				.else
					mov		eax,val
				.endif
				mov		edx,var.Address
				mov		[edx],eax
				mov		ebx,dbg.lpthread
				invoke SetThreadContext,[ebx].DEBUGTHREAD.htread,addr dbg.context
				invoke ShowContext
				invoke GetVarVal,addr buffer,dbg.prevline,TRUE
				invoke PutStringOut,addr outbuffer,hOut3
			.else
				invoke PutStringOut,addr szImmNotFound,hOut3
			.endif
			jmp		Ex
		.endif
		inc		ebx
	.endw
	.if buffer
		invoke PutStringOut,addr szImmUnknown,hOut3
	.endif
  Ex:
	invoke ImmPrompt
	ret

Immediate endp

ImmediateProc proc hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_CHAR
		.if dbg.hDbgThread && dbg.fHandled
			mov		eax,wParam
			.if eax==VK_RETURN
				invoke Immediate,hOut3
				xor		eax,eax
				ret
			.endif
		.endif
	.endif
	invoke CallWindowProc,lpOldOutProc3,hWin,uMsg,wParam,lParam
	ret

ImmediateProc endp
