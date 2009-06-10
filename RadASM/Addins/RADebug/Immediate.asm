.const

szImmDump						db 'DUMP',0
szImmNotFound					db 'Variable not found.',0
szImmUnknown					db 'Unknown command.',0

.code

ParseBuff proc uses esi edi,lpBuff:DWORD

	mov		esi,lpBuff
	mov		edi,esi
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
	.if buffer=='?'
		invoke GetVarVal,addr buffer[1],dbg.prevline,TRUE
		.if eax
			invoke PutStringOut,addr outbuffer,hOut3
		.else
			invoke PutStringOut,addr szImmNotFound,hOut3
		.endif
	.else
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
		.else
			invoke PutStringOut,addr szImmUnknown,hOut3
		.endif
	.endif
  Ex:
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
