
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

    push    ebx
    push    ecx
    push    edx
    push    esi
    push    edi
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
    pop     edi
    pop     esi
    pop     edx
    pop     ecx
    pop     ebx
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

StreamInProc proc hFile:DWORD,pBuffer:DWORD,NumBytes:DWORD,pBytesRead:DWORD

	invoke ReadFile,hFile,pBuffer,NumBytes,pBytesRead,0
	xor		eax,1
	ret

StreamInProc endp

LoadLstFile proc uses ebx esi
    LOCAL   hFile:HANDLE
	LOCAL	editstream:EDITSTREAM

	;Open the file
	invoke CreateFile,offset szlstfilename,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke SendMessage,hREd,WM_SETTEXT,0,addr szNULL
		;stream the text into the RAEdit control
		mov		eax,hFile
		mov		editstream.dwCookie,eax
		mov		editstream.pfnCallback,offset StreamInProc
		invoke SendMessage,hREd,EM_STREAMIN,SF_TEXT,addr editstream
		invoke CloseHandle,hFile
		invoke SendMessage,hREd,EM_SETMODIFY,FALSE,0
		invoke SendMessage,hREd,REM_SETCHANGEDSTATE,FALSE,0
		mov		eax,FALSE
	.else
		mov		eax,TRUE
	.endif
	ret

LoadLstFile endp

SetDbgLine proc nDbgLine:DWORD

	;Remove previous line
	invoke SendMessage,hREd,REM_SETHILITELINE,SingleStepLine,0
	;Set new line
	mov		eax,nDbgLine
	mov		SingleStepLine,eax
	invoke SendMessage,hREd,REM_SETHILITELINE,SingleStepLine,2
	ret

SetDbgLine endp

;If current line is ACALL, return 2
;If current line is LCALL, return 3
IsLCALLACALL proc
	LOCAL	buffer[256]:BYTE

	mov		word ptr buffer,255
	invoke SendMessage,hREd,EM_GETLINE,SingleStepLine,addr buffer
	mov		buffer[eax],0
	xor		eax,eax
	ret

IsLCALLACALL endp

Find proc lpText:DWORD
	LOCAL	buffer[16]:BYTE
	LOCAL	ft:FINDTEXTEX
	LOCAL	ft2:FINDTEXTEX

	mov		eax,20202020h
	mov		dword ptr buffer,eax
	invoke lstrcpy,addr buffer[4],lpText
	mov		word ptr buffer[8],20h
	mov		ft.chrg.cpMin,0
	mov		ft.chrg.cpMax,-1
	mov		ft2.chrg.cpMax,-1
	lea		eax,buffer
	mov		ft.lpstrText,eax
	mov		ft2.lpstrText,eax
	invoke SendMessage,hREd,EM_FINDTEXTEX,FR_DOWN,addr ft
	.if eax!=-1
		;Check for next occurance
		mov		eax,ft.chrgText.cpMax
		mov		ft2.chrgText.cpMin,eax
		invoke SendMessage,hREd,EM_FINDTEXTEX,FR_DOWN,addr ft
		.if eax!=-1
			mov		eax,ft2.chrgText.cpMin
			mov		ft.chrgText.cpMin,eax
			mov		eax,ft2.chrgText.cpMax
			mov		ft.chrgText.cpMax,eax
		.endif
		invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,addr ft.chrgText.cpMin
		push	eax
		invoke SetDbgLine,eax
		pop		eax
		invoke SendMessage,hREd,EM_LINEINDEX,eax,0
		mov		ft.chrgText.cpMin,eax
		mov		ft.chrgText.cpMax,eax
		invoke SendMessage,hREd,EM_EXSETSEL,0,addr ft.chrgText
;		invoke SendMessage,hREd,REM_VCENTER,0,0
		invoke SendMessage,hREd,EM_SCROLLCARET,0,0
		invoke SendMessage,hREd,EM_EXSETSEL,0,addr ft.chrgText
		mov		eax,TRUE
	.else
		xor		eax,eax
	.endif
	ret

Find endp
