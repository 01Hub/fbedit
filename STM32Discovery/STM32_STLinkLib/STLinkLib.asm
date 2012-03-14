.586
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include STLinkLib.inc

.code

;########################################################################

FindBlock proc uses ebx,hWin:HWND

	xor		ebx,ebx
	mov		eax,hWin
	.while ebx<sizeof ST_LINK*16
		.if eax==STLink.hWnd[ebx]
			mov		eax,ebx
			jmp		Ex
		.elseif !STLink.hWnd[ebx]
			mov		eax,hWin
			mov		STLink.hWnd[ebx],eax
			mov		eax,ebx
			jmp		Ex
		.endif
		lea		ebx,[ebx+sizeof ST_LINK]
	.endw
	mov		eax,-1
  Ex:
	ret

FindBlock endp

LoadSTLinkUSBDriver proc uses ebx,hWin:HWND

	invoke FindBlock,hWin
	.if eax==-1
;***
		xor		eax,eax
		ret
	.endif
	mov		ebx,eax
	inc eax
	invoke LoadLibrary,addr szSTLinkUSBDriverDll
	.if eax
		mov		STLink.hModule[ebx],eax
		invoke GetProcAddress,STLink.hModule[ebx],addr szSTMass_Enum_Reenumerate
		or		eax,eax
		jz		ExErr
		mov		STLink.lpSTMass_Enum_Reenumerate[ebx],eax
		invoke GetProcAddress,STLink.hModule[ebx],addr szSTMass_Enum_GetNbDevices
		or		eax,eax
		jz		ExErr
		mov		STLink.lpSTMass_Enum_GetNbDevices[ebx],eax
		invoke GetProcAddress,STLink.hModule[ebx],addr szSTMass_Enum_GetDevice
		or		eax,eax
		jz		ExErr
		mov		STLink.lpSTMass_Enum_GetDevice[ebx],eax
		invoke GetProcAddress,STLink.hModule[ebx],addr szSTMass_GetDeviceInfo
		or		eax,eax
		jz		ExErr
		mov		STLink.lpSTMass_GetDeviceInfo[ebx],eax
		invoke GetProcAddress,STLink.hModule[ebx],addr szSTMass_OpenDevice
		or		eax,eax
		jz		ExErr
		mov		STLink.lpSTMass_OpenDevice[ebx],eax
		invoke GetProcAddress,STLink.hModule[ebx],addr szSTMass_CloseDevice
		or		eax,eax
		jz		ExErr
		mov		STLink.lpSTMass_CloseDevice[ebx],eax
		invoke GetProcAddress,STLink.hModule[ebx],addr szSTMass_SendCommand
		or		eax,eax
		jz		ExErr
		mov		STLink.lpSTMass_SendCommand[ebx],eax
		mov		eax,TRUE
	.else
		invoke MessageBox,hWin,addr szErrLoadDll,addr szError,MB_OK or MB_ICONERROR
		xor		eax,eax
	.endif
	ret

ExErr:
	invoke MessageBox,hWin,addr szErrProcAddress,addr szError,MB_OK or MB_ICONERROR
	invoke FreeLibrary,STLink.hModule[ebx]
	xor		eax,eax
	mov		STLink.hModule[ebx],eax
	pop		ebx
	ret

LoadSTLinkUSBDriver endp

SendCommend proc uses ebx,hWin:HWND,cmnd:DWORD,subcmnd:DWORD,rdadr:DWORD,rdbytes:DWORD,wradr:DWORD,y:DWORD

	;Setup command
	invoke FindBlock,hWin
	.if eax==-1
;***
		xor		eax,eax
		ret
	.endif
	mov		ebx,eax
	invoke RtlZeroMemory,addr STLink.STLinkCmnd[ebx],sizeof ST_LINKCMND
	mov		STLink.STLinkCmnd.cmd0[ebx],0Ah
	mov		eax,cmnd
	mov		STLink.STLinkCmnd.cmd1[ebx],al
	mov		eax,subcmnd
	mov		STLink.STLinkCmnd.cmd2[ebx],al
	mov		eax,rdadr
	mov		STLink.STLinkCmnd.rdadr[ebx],eax
	mov		eax,rdbytes
	mov		STLink.STLinkCmnd.rdbytes[ebx],eax
	.if !(cmnd==0F2h && (subcmnd==0Dh || subcmnd==08h))
		mov		STLink.STLinkCmnd.x[ebx],0100h
	.endif
	mov		eax,wradr
	mov		STLink.STLinkCmnd.wradr[ebx],eax
	mov		eax,y
	mov		STLink.STLinkCmnd.y[ebx],eax
	mov		STLink.STLinkCmnd.z[ebx],0Eh
	push	1388h
	lea		eax,STLink.STLinkCmnd[ebx]
	push	eax
	push	STLink.hFile[ebx]
	push	STLink.hDevice[ebx]
	call	STLink.lpSTMass_SendCommand[ebx]
	ret

SendCommend endp

STLinkConnect proc uses ebx,hWin:HWND

	invoke FindBlock,hWin
	.if eax==-1
;***
		xor		eax,eax
		ret
	.endif
	mov		ebx,eax
  Retry:
	.if !STLink.hModule[ebx]
		invoke LoadSTLinkUSBDriver,hWin
	.endif
	.if STLink.hModule[ebx]
		call STLink.lpSTMass_Enum_Reenumerate[ebx]
		call STLink.lpSTMass_Enum_GetNbDevices[ebx]
		or		eax,eax
		jz		ExErr
		lea		eax,STLink.hDevice[ebx]
		push	eax
		push	0
		call STLink.lpSTMass_Enum_GetDevice[ebx]
		or		eax,eax
		jz		ExErr
		lea		eax,STLink.hFile[ebx]
		push	eax
		push	STLink.hDevice[ebx]
		call STLink.lpSTMass_OpenDevice[ebx]
		or		eax,eax
		jz		ExErr
		invoke SendCommend,hWin,0F5h,000h,000000000h,0000h,addr STLink.buff2[ebx],02h
		cmp		eax,1
		jnz		ExErr
		movzx	eax,word ptr STLink.buff2[ebx]
		.if !eax
			invoke SendCommend,hWin,0F3h,007h,000000000h,0000h,addr STLink.buff2[ebx],00h
			cmp		eax,1
			jnz		ExErr
		.endif
		invoke SendCommend,hWin,0F2h,030h,0000000A3h,0000h,addr STLink.buff2[ebx],02h
		cmp		eax,1
		jnz		ExErr
	.endif
	ret

ExErr:
	invoke MessageBox,hWin,addr szErrNotConnected,addr szError,MB_ABORTRETRYIGNORE or MB_ICONERROR
	push	eax
	.if STLink.hDevice[ebx]
		push	STLink.hFile[ebx]
		push	STLink.hDevice[ebx]
		call	STLink.lpSTMass_CloseDevice[ebx]
	.endif
	.if STLink.hModule[ebx]
		invoke FreeLibrary,STLink.hModule[ebx]
	.endif
	xor		eax,eax
	mov		STLink.hFile[ebx],eax
	mov		STLink.hDevice[ebx],eax
	mov		STLink.hModule[ebx],eax
	pop		eax
	.if eax==IDRETRY
		jmp		Retry
	.endif
	ret

STLinkConnect endp

STLinkDisconnect proc uses ebx,hWin:HWND

	invoke FindBlock,hWin
	.if eax==-1
;***
		xor		eax,eax
		ret
	.endif
	mov		ebx,eax
	.if STLink.hDevice[ebx]
		push	STLink.hFile[ebx]
		push	STLink.hDevice[ebx]
		call	STLink.lpSTMass_CloseDevice[ebx]
		mov		STLink.hFile[ebx],0
		mov		STLink.hDevice[ebx],0
	.endif
	.if STLink.hModule[ebx]
		invoke FreeLibrary,STLink.hModule[ebx]
		mov		STLink.hModule[ebx],0
	.endif
	ret

STLinkDisconnect endp

STLinkReset proc uses ebx,hWin:HWND

	invoke FindBlock,hWin
	.if eax==-1
;***
		xor		eax,eax
		ret
	.endif
	mov		ebx,eax
  Retry:
	mov		dword ptr STLink.buff2[ebx],0FFFFFFFFh
	invoke SendCommend,hWin,0F2h,007h,0E000ED0Ch,4,addr STLink.buff2[ebx],4
	invoke SendCommend,hWin,0F2h,03Bh,00000000h,0000h,addr STLink.buff2[ebx],02h
	mov		dword ptr STLink.buff2[ebx],005FA0004h
	invoke SendCommend,hWin,0F2h,008h,0E000ED0Ch,0004h,addr STLink.buff2[ebx],04h
	invoke SendCommend,hWin,0F2h,03Bh,00000000h,0000h,addr STLink.buff2[ebx],02h
	invoke SendCommend,hWin,0F2h,036h,0E000EDF0h,0000h,addr STLink.buff2[ebx],08h
	invoke SendCommend,hWin,0F2h,035h,0E000EDF0h,0A05F0003h,addr STLink.buff2[ebx],02h
	invoke SendCommend,hWin,0F2h,036h,0E000EDF0h,0000h,addr STLink.buff2[ebx],08h
	invoke SendCommend,hWin,0F2h,03Ah,000000000h,0000h,addr STLink.buff2[ebx],05Ch
	mov		dword ptr STLink.buff2[ebx],01FFFF800h
	invoke SendCommend,hWin,0F2h,007h,01FFFF800h,4,addr STLink.buff2[ebx],4
	invoke SendCommend,hWin,0F2h,03Bh,00000000h,0000h,addr STLink.buff2[ebx],02h
	invoke SendCommend,hWin,0F2h,035h,0E000EDF0h,0A05F0001h,addr STLink.buff2[ebx],02h
	ret

ExErr:
	invoke MessageBox,hWin,addr szErrNotConnected,addr szError,MB_ABORTRETRYIGNORE or MB_ICONERROR
	.if eax==IDRETRY
		jmp		Retry
	.endif
	push	eax
	.if STLink.hDevice[ebx]
		push	STLink.hFile[ebx]
		push	STLink.hDevice[ebx]
		call	STLink.lpSTMass_CloseDevice[ebx]
	.endif
	.if STLink.hModule[ebx]
		invoke FreeLibrary,STLink.hModule[ebx]
	.endif
	xor		eax,eax
	mov		STLink.hFile[ebx],eax
	mov		STLink.hDevice[ebx],eax
	mov		STLink.hModule[ebx],eax
	pop		eax
	ret

STLinkReset endp

STLinkRead proc uses ebx,hWin:HWND,rdadr:DWORD,wradr:DWORD,nBytes:DWORD

	invoke FindBlock,hWin
	.if eax==-1
;***
		xor		eax,eax
		ret
	.endif
	mov		ebx,eax
  Retry:
	.if !STLink.hDevice[ebx]
		jmp		ExErr
	.endif
	.while nBytes>MAX_RDBLOCK
		invoke SendCommend,hWin,0F2h,007h,rdadr,MAX_RDBLOCK,wradr,MAX_RDBLOCK
		cmp		eax,1
		jnz		ExErr
		sub		nBytes,MAX_RDBLOCK
		add		rdadr,MAX_RDBLOCK
		add		wradr,MAX_RDBLOCK
	.endw
	.if nBytes
		invoke SendCommend,hWin,0F2h,007h,rdadr,nBytes,wradr,nBytes
		cmp		eax,1
		jnz		ExErr
	.endif
	invoke SendCommend,hWin,0F2h,03Bh,00000000h,0000h,addr STLink.buff2[ebx],02h
	cmp		eax,1
	jnz		ExErr
	ret

ExErr:
	invoke MessageBox,hWin,addr szErrNotConnected,addr szError,MB_ABORTRETRYIGNORE or MB_ICONERROR
	.if eax==IDRETRY
		jmp		Retry
	.endif
	push	eax
	.if STLink.hDevice[ebx]
		push	STLink.hFile[ebx]
		push	STLink.hDevice[ebx]
		call	STLink.lpSTMass_CloseDevice[ebx]
	.endif
	.if STLink.hModule[ebx]
		invoke FreeLibrary,STLink.hModule[ebx]
	.endif
	xor		eax,eax
	mov		STLink.hFile[ebx],eax
	mov		STLink.hDevice[ebx],eax
	mov		STLink.hModule[ebx],eax
	pop		eax
	ret

STLinkRead endp

STLinkWrite proc uses ebx,hWin:HWND,wradr:DWORD,rdadr:DWORD,nBytes:DWORD

	invoke FindBlock,hWin
	.if eax==-1
;***
		xor		eax,eax
		ret
	.endif
	mov		ebx,eax
  Retry:
	.if !STLink.hDevice[ebx]
		jmp		ExErr
	.endif
	.while nBytes>MAX_WRBLOCK
		invoke SendCommend,hWin,0F2h,00Dh,wradr,MAX_WRBLOCK,rdadr,MAX_WRBLOCK
		cmp		eax,1
		jnz		ExErr
		sub		nBytes,MAX_WRBLOCK
		add		rdadr,MAX_WRBLOCK
		add		wradr,MAX_WRBLOCK
	.endw
	.if nBytes
		invoke SendCommend,hWin,0F2h,00Dh,wradr,nBytes,rdadr,nBytes
		cmp		eax,1
		jnz		ExErr
	.endif
	invoke SendCommend,hWin,0F2h,03Bh,000000000h,000000000h,addr STLink.buff2[ebx],0002h
	cmp		eax,1
	jnz		ExErr
	ret

ExErr:
	invoke MessageBox,hWin,addr szErrNotConnected,addr szError,MB_ABORTRETRYIGNORE or MB_ICONERROR
	.if eax==IDRETRY
		jmp		Retry
	.endif
	push	eax
	.if STLink.hDevice[ebx]
		push	STLink.hFile[ebx]
		push	STLink.hDevice[ebx]
		call	STLink.lpSTMass_CloseDevice[ebx]
	.endif
	.if STLink.hModule[ebx]
		invoke FreeLibrary,STLink.hModule[ebx]
	.endif
	xor		eax,eax
	mov		STLink.hFile[ebx],eax
	mov		STLink.hDevice[ebx],eax
	mov		STLink.hModule[ebx],eax
	pop		eax
	ret

STLinkWrite endp

;########################################################################

end
