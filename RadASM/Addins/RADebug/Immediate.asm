.const

szImmDump						db 'DUMP',0
szImmNotFound					db 'Variable not found.',0
szImmUnknown					db 'Unknown command.',0

.code

GetImmediateVal proc lpVal:DWORD

	ret

GetImmediateVal endp

Immediate proc uses ebx esi edi,hWin:HWND
	LOCAL	chrg:CHARRANGE
	LOCAL	buffer[256]:BYTE
	LOCAL	val:DWORD

	invoke SendMessage,hWin,EM_EXGETSEL,0,addr chrg
	invoke SendMessage,hWin,EM_LINEFROMCHAR,chrg.cpMin,0
	mov		edx,eax
	mov		word ptr buffer,255
	invoke SendMessage,hWin,EM_GETLINE,edx,addr buffer
	mov		buffer[eax],0
	invoke SendMessage,hWin,EM_REPLACESEL,FALSE,addr szCR
	.if buffer=='?'
		invoke GetVarVal,addr buffer[1],dbg.prevline,TRUE
		.if eax
			invoke PutStringOut,addr outbuffer,hOut3
		.else
			invoke PutStringOut,addr szImmNotFound,hOut3
		.endif
	.else
		xor ecx,ecx
		.while buffer[ecx]
			.if buffer[ecx]=='='
				mov		buffer[ecx],0
				push	ecx
				invoke GetVarAdr,addr buffer,dbg.prevline
				pop		ecx
				.if eax=='d' || eax=='P' || eax=='L'
					; GLOBAL, PROC Parameter or LOCAL
					invoke DecToBin,addr buffer[ecx+1]
					mov		val,eax
					invoke WriteProcessMemory,dbg.hdbghand,var.Address,addr val,var.nSize,0
					invoke GetVarVal,addr buffer,dbg.prevline,TRUE
					invoke PutStringOut,addr outbuffer,hOut3
				.elseif eax=='R'
					; REGISTER
					invoke DecToBin,addr buffer[ecx+1]
					mov		val,eax
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
				.else
					invoke PutStringOut,addr szImmNotFound,hOut3
				.endif
				jmp		Ex
			.endif
			inc		ecx
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
		.if dbg.hDbgThread
			mov		eax,wParam
			.if eax==VK_RETURN
				invoke Immediate,hOut3
				xor		eax,eax
				ret
			.endif
		.endif
	.endif
	invoke CallWindowProc,lpOldEditProc,hWin,uMsg,wParam,lParam
	ret

ImmediateProc endp
