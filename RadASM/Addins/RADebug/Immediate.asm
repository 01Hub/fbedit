
.const

; Commands
szImmHelp						db 'Help',0
szImmDump						db 'Dump',0
szImmMemdump					db 'Memdump',0
szImmVars						db 'Vars',0
szImmTypes						db 'Types',0
szImmCls						db 'Cls',0
szImmWatch						db 'Watch',0

szImmLocal						db 0Dh,'LOCAL: ',0

szHelp							db 'Immediate window (Output window #3):',0Dh,0Ah
								db '-----------------------------------------------------------------------------',0Dh,0Ah
								db 'NOTE!',0Dh,0Ah
								db 'Commands ,registers and hex values are case insensitive.',0Dh,0Ah
								db 'Variables are case sensitive.',0Dh,0Ah
								db 'To inspect or change a proc parameter or local variable it must',0Dh,0Ah
								db 'be in the current scope.',0Dh,0Ah
								db 0Dh,0Ah
								db 'o Simple math.',0Dh,0Ah
								db '  - Functions: +, -, *, /, SHL, SHR, AND, OR and XOR.',0Dh,0Ah
								db '  - Example: ?(((eax+1) SHL 2)*4) AND 0FFFFh',0Dh,0Ah
								db 'o Inspect variable or register.',0Dh,0Ah
								db '  - ?MyVar to show info about a variable local or parameter.',0Dh,0Ah
								db '  - ?MyVar(inx) to show an array element. Index is zero based.',0Dh,0Ah
								db '    (inx) can be any expression.',0Dh,0Ah
								db '  - ?Z:MyZString to show a ZString. Use Z:MyZString(inx) to start',0Dh,0Ah
								db '    at an offset. (inx) can be any expression.',0Dh,0Ah
								db '  - ?reg To show a register (reg: eax, ebx ...).',0Dh,0Ah
								db '  - ?123 or ?0A5Fh to convert a number to hex and decimal.',0Dh,0Ah
								db 'o Change variable or register.',0Dh,0Ah
								db '  - MyVar=ebx+2 to change the variable MyVar.',0Dh,0Ah
								db '  - reg=4AB0h to change a register (reg: eax, ebx ...).',0Dh,0Ah
								db 'o Commands.',0Dh,0Ah
								db '  - Help, or /H or /?',0Dh,0Ah
								db '    Shows this help screen.',0Dh,0Ah
								db '  - Dump',0Dh,0Ah
								db '    Shows a hex dump of the exe.',0Dh,0Ah
								db '  - Dump MyStruct',0Dh,0Ah
								db '    Shows a hex dump of an array, structure or union.',0Dh,0Ah
								db '  - Memdump Address,Count',0Dh,0Ah
								db '    Shows a memory dump. Address and Count can be any expression.',0Dh,0Ah
								db '  - Vars',0Dh,0Ah
								db '    Shows a list of all variables.',0Dh,0Ah
								db '  - Types',0Dh,0Ah
								db '    Show a list of all types.',0Dh,0Ah
								db '  - Watch var1,Z:MyZStr,....,var8',0Dh,0Ah
								db '    Adds a watch to specified variables.',0Dh,0Ah
								db '    To clear the watch list, type Watch without any variable list.',0Dh,0Ah
								db '  - Cls',0Dh,0Ah
								db '    Clears the immediate window.',0

.code

ParseBuff proc uses esi edi,lpBuff:DWORD

	mov		esi,lpBuff
	mov		edi,esi
	.if byte ptr [esi]=='>'
		inc		esi
	.endif
	.while byte ptr [esi]==VK_SPACE || byte ptr [esi]==VK_TAB
		inc		esi
	.endw
	.while TRUE
		mov		al,[esi]
		mov		[edi],al
		inc		edi
		.break .if !al
		inc		esi
	.endw
	ret

ParseBuff endp

ParseWatch proc uses ebx esi edi,lpList:DWORD

	mov		edi,offset szWatchList
	invoke RtlZeroMemory,edi,sizeof szWatchList
	xor		edx,edx
	mov		esi,lpList
	.while byte ptr [esi] && edx<8
		call	AddWatchVar
	.endw
	ret

AddWatchVar:
	xor		ecx,ecx
	.while byte ptr [esi] && byte ptr [esi]!=','
		mov		al,[esi]
		mov		[edi],al
		inc		ecx
		inc		edi
		inc		esi
	.endw
	.if byte ptr [esi]==','
		inc		esi
	.endif
	.if ecx
		inc		edi
	.endif
	retn

ParseWatch endp

SaveWatch proc uses esi edi,lpWatch:DWORD

	mov		esi,lpWatch
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
	mov		eax,lpData
	invoke WritePrivateProfileString,addr szImmWatch,addr szImmWatch,lpWatch,[eax].ADDINDATA.lpProject
	ret

SaveWatch endp

LoadWatch proc
	LOCAL	buffer[256]:BYTE

	mov		eax,lpData
	invoke GetPrivateProfileString,addr szImmWatch,addr szImmWatch,addr szNULL,addr buffer,sizeof buffer,[eax].ADDINDATA.lpProject
	invoke ParseWatch,addr buffer
	ret

LoadWatch endp

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
	mov		eax,dword ptr buffer
	and		eax,0FFFFFFh
	.if eax=='H/' || eax=='h/' || eax=='?/'
		invoke PutStringOut,addr szHelp,hOut3
		jmp		Ex
	.endif
	invoke strcmpi,addr buffer,addr szImmHelp
	.if !eax
		invoke PutStringOut,addr szHelp,hOut3
		jmp		Ex
	.endif
	invoke strcmpi,addr buffer,addr szImmDump
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
	invoke strcmpin,addr buffer,addr szImmDump,4
	.if !eax
		invoke GetVarAdr,addr buffer[4],dbg.prevline
		.if eax
			mov		eax,var.nSize
			mov		edx,var.nArray
			mul		edx
			mov		edi,eax
			mov		esi,var.Address
			.while edi>=16
				invoke ReadProcessMemory,dbg.hdbghand,esi,addr buffer,16,NULL
				.if eax
					invoke DumpLine,hOut3,esi,addr buffer,16
				.endif
				sub		edi,16
				add		esi,16
			.endw
			.if edi
				invoke ReadProcessMemory,dbg.hdbghand,esi,addr buffer,edi,NULL
				.if eax
					invoke DumpLine,hOut3,esi,addr buffer,edi
				.endif
			.endif
		.endif
		jmp		Ex
	.endif
	invoke strcmpin,addr buffer,addr szImmMemdump,7
	.if !eax
		xor		edi,edi
		lea		esi,buffer[7]
		.while byte ptr [esi]
			.if byte ptr [esi]==','
				lea		edi,[esi+1]
				mov		byte ptr [esi],0
				.break
			.endif
			inc		esi
		.endw
		.if edi
			invoke DoMath,addr buffer[7]
			.if eax
				mov		esi,var.Value
				invoke DoMath,edi
				.if eax
					mov		edi,var.Value
					.while edi
						.if edi>=16
							invoke ReadProcessMemory,dbg.hdbghand,esi,addr buffer,16,NULL
							.break .if !eax
							invoke DumpLine,hOut3,esi,addr buffer,16
							add		esi,16
							sub		edi,16
						.else
							invoke ReadProcessMemory,dbg.hdbghand,esi,addr buffer,edi,NULL
							.break .if !eax
							invoke DumpLine,hOut3,esi,addr buffer,edi
							.break
						.endif
					.endw
					xor		ebx,ebx
				.else
					mov		ebx,TRUE
				.endif
			.else
				mov		ebx,TRUE
			.endif
		.else
			invoke wsprintf,offset outbuffer,addr szSyntaxError,addr szError
			mov		ebx,TRUE
		.endif
		.if ebx
			invoke PutStringOut,addr outbuffer,hOut3
		.endif
		jmp		Ex
	.endif
	invoke strcmpi,addr buffer,addr szImmTypes
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
	invoke strcmpi,addr buffer,addr szImmVars
	.if !eax
		mov		esi,dbg.hMemSymbol
		mov		ecx,dbg.inxsymbol
		.while ecx
			push	ecx
			.if [esi].DEBUGSYMBOL.nType=='d'
				mov		edi,[esi].DEBUGSYMBOL.lpType
				.if edi
					invoke strcpy,addr outbuffer,addr [edi+sizeof DEBUGVAR]
					invoke strlen,addr [edi+sizeof DEBUGVAR]
					invoke strcat,addr outbuffer,addr [edi+eax+1+sizeof DEBUGVAR]
					invoke PutStringOut,addr outbuffer,hOut3
				.endif
			.elseif [esi].DEBUGSYMBOL.nType=='p'
				invoke strcpy,addr outbuffer,addr [esi].DEBUGSYMBOL.szName
				mov		edi,[esi].DEBUGSYMBOL.lpType
				.if edi
					mov		ebx,offset szSpace
					lea		edi,[edi+sizeof DEBUGVAR]
					.while byte ptr [edi]
						invoke strcat,addr outbuffer,ebx
						invoke strcat,addr outbuffer,edi
						invoke strlen,edi
						lea		edi,[edi+eax+1]
						invoke strcat,addr outbuffer,edi
						invoke strlen,edi
						lea		edi,[edi+eax+1]
						lea		edi,[edi+sizeof DEBUGVAR]
						mov		ebx,offset szComma
					.endw
					mov		ebx,offset szImmLocal
					lea		edi,[edi+sizeof DEBUGVAR+2]
					.while byte ptr [edi]
						invoke strcat,addr outbuffer,ebx
						invoke strcat,addr outbuffer,edi
						invoke strlen,edi
						lea		edi,[edi+eax+1]
						invoke strcat,addr outbuffer,edi
						invoke strlen,edi
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
	invoke strcmpi,addr buffer,addr szImmCls
	.if !eax
		invoke SetWindowText,hOut3,addr szNULL
		jmp		Ex
	.endif
	invoke strcmpin,addr buffer,addr szImmWatch,5
	.if !eax
		invoke SaveWatch,addr buffer[5]
		invoke ParseWatch,addr buffer[5]
		.if szWatchList
			invoke WatchVars
			ret
		.endif
		jmp		Ex
	.endif
	.if buffer=='?'
		movzx	eax,word ptr buffer[1]
		.if eax==':z' || eax==';Z'
			invoke GetVarVal,addr buffer[3],dbg.prevline,TRUE
		.else
			invoke DoMath,addr buffer[1]
		.endif
		invoke PutStringOut,addr outbuffer,hOut3
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
				invoke wsprintf,addr outbuffer,addr szImmNotFound,addr buffer
				invoke PutStringOut,addr outbuffer,hOut3
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
