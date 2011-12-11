
.code

DecToBin proc uses ebx esi,lpStr:DWORD
	LOCAL	fNeg:DWORD

    mov     esi,lpStr
    mov		fNeg,FALSE
    mov		al,[esi]
    .if al=='-'
		inc		esi
		mov		fNeg,TRUE
    .endif
    xor     eax,eax
  @@:
    cmp     byte ptr [esi],30h
    jb      @f
    cmp     byte ptr [esi],3Ah
    jnb     @f
    mov     ebx,eax
    shl     eax,2
    add     eax,ebx
    shl     eax,1
    xor     ebx,ebx
    mov     bl,[esi]
    sub     bl,30h
    add     eax,ebx
    inc     esi
    jmp     @b
  @@:
	.if fNeg
		neg		eax
	.endif
    ret

DecToBin endp

BinToDec proc dwVal:DWORD,lpAscii:DWORD
	LOCAL	buffer[8]:BYTE

	mov		dword ptr buffer,'d%'
	invoke wsprintf,lpAscii,addr buffer,dwVal
	ret

BinToDec endp

GetItemInt proc uses esi edi,lpBuff:DWORD,nDefVal:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		invoke DecToBin,edi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		.if byte ptr [esi]==','
			inc		esi
		.endif
		push	eax
		invoke lstrcpy,edi,esi
		pop		eax
	.else
		mov		eax,nDefVal
	.endif
	ret

GetItemInt endp

PutItemInt proc uses esi edi,lpBuff:DWORD,nVal:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	mov		byte ptr [esi+eax],','
	invoke BinToDec,nVal,addr [esi+eax+1]
	ret

PutItemInt endp

GetItemStr proc uses esi edi,lpBuff:DWORD,lpDefVal:DWORD,lpResult:DWORD,ccMax:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		lea		eax,[esi+1]
		sub		eax,edi
		.if eax>ccMax
			mov		eax,ccMax
		.endif
		invoke lstrcpyn,lpResult,edi,eax
		.if byte ptr [esi]
			inc		esi
		.endif
		invoke lstrcpy,edi,esi
	.else
		invoke lstrcpyn,lpResult,lpDefVal,ccMax
	.endif
	ret

GetItemStr endp

PutItemStr proc uses esi,lpBuff:DWORD,lpStr:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	mov		byte ptr [esi+eax],','
	invoke lstrcpy,addr [esi+eax+1],lpStr
	ret

PutItemStr endp

;'"Str,Str","Str",1,2','Str',1
GetItemQuotedStr proc uses esi edi,lpBuff:DWORD,lpDefVal:DWORD,lpResult:DWORD,ccMax:DWORD

	mov		esi,lpBuff
	.if byte ptr [esi]=="'"
		mov		edi,esi
		inc		esi
		.while byte ptr [esi] && byte ptr [esi]!="'"
			inc		esi
		.endw
		.if byte ptr [esi]=="'"
			inc		esi
		.endif
		lea		eax,[esi+1]
		sub		eax,edi
		.if eax>ccMax
			mov		eax,ccMax
			lea		eax,[eax+2]
		.endif
		invoke lstrcpyn,lpResult,addr [edi+1],addr [eax-2]
		.if byte ptr [esi]
			inc		esi
		.endif
		invoke lstrcpy,edi,esi
	.elseif byte ptr [esi]
		invoke GetItemStr,lpBuff,lpDefVal,lpResult,ccMax
	.else
		invoke lstrcpyn,lpResult,lpDefVal,ccMax
	.endif
	ret

GetItemQuotedStr endp

PutItemQuotedStr proc uses esi,lpBuff:DWORD,lpStr:DWORD

	mov		esi,lpBuff
	invoke lstrlen,esi
	lea		esi,[esi+eax]
	mov		word ptr [esi],"',"
	invoke lstrcpy,addr [esi+2],lpStr
	invoke lstrlen,esi
	mov		word ptr [esi+eax],"'"
	ret

PutItemQuotedStr endp

LoadSettings proc
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	rect:RECT
	LOCAL	fMax:DWORD

	invoke GetPrivateProfileString,addr szIniConfig,addr szIniPos,NULL,addr buffer,sizeof buffer,addr szIniFile
	invoke GetItemInt,addr buffer,10
	mov		rect.left,eax
	invoke GetItemInt,addr buffer,10
	mov		rect.top,eax
	invoke GetItemInt,addr buffer,800
	mov		rect.right,eax
	invoke GetItemInt,addr buffer,600
	mov		rect.bottom,eax
	invoke GetItemInt,addr buffer,0
	mov		fMax,eax
	invoke MoveWindow,addin.hWnd,rect.left,rect.top,rect.right,rect.bottom,FALSE
	.if fMax
		invoke ShowWindow,addin.hWnd,SW_SHOWMAXIMIZED
	.else
		invoke ShowWindow,addin.hWnd,SW_SHOWNORMAL
	.endif
	invoke GetPrivateProfileString,addr szIniConfig,addr szIniClock,NULL,addr buffer,sizeof buffer,addr szIniFile
	invoke GetItemInt,addr buffer,2500
	mov		ComputerClock,eax
	invoke GetItemInt,addr buffer,24000000
	mov		MCUClock,eax
	invoke GetItemInt,addr buffer,200
	mov		RefreshRate,eax
	invoke SetTiming
	ret

LoadSettings endp

SaveSettings proc
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	fMax:DWORD

	invoke IsZoomed,addin.hWnd
	mov		fMax,eax
	mov		eax,WinRect.left
	sub		WinRect.right,eax
	mov		eax,WinRect.top
	sub		WinRect.bottom,eax
	mov		buffer,0
	invoke PutItemInt,addr buffer,WinRect.left
	invoke PutItemInt,addr buffer,WinRect.top
	invoke PutItemInt,addr buffer,WinRect.right
	invoke PutItemInt,addr buffer,WinRect.bottom
	invoke PutItemInt,addr buffer,fMax
	invoke WritePrivateProfileString,addr szIniConfig,addr szIniPos,addr buffer[1],addr szIniFile
	mov		buffer,0
	invoke PutItemInt,addr buffer,ComputerClock
	invoke PutItemInt,addr buffer,MCUClock
	invoke PutItemInt,addr buffer,RefreshRate
	invoke WritePrivateProfileString,addr szIniConfig,addr szIniClock,addr buffer[1],addr szIniFile
	ret

SaveSettings endp
