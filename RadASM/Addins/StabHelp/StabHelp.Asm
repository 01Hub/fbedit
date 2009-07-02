.486
.model flat,stdcall
option casemap:none

include StabHelp.inc

.code

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	mov		eax,hInst
	mov		hInstance,eax
	mov		eax,TRUE
	ret

DllEntry Endp

; String handling
strcpy proc uses esi edi,lpDest:DWORD,lpSource:DWORD

	mov		esi,lpSource
	xor		ecx,ecx
	mov		edi,lpDest
  @@:
	mov		al,[esi+ecx]
	mov		[edi+ecx],al
	inc		ecx
	or		al,al
	jne		@b
	ret

strcpy endp

strcpyn proc uses esi edi,lpDest:DWORD,lpSource:DWORD,nLen:DWORD

	mov		esi,lpSource
	mov		edx,nLen
	dec		edx
	xor		ecx,ecx
	mov		edi,lpDest
  @@:
	.if sdword ptr ecx<edx
		mov		al,[esi+ecx]
		mov		[edi+ecx],al
		inc		ecx
		or		al,al
		jne		@b
	.else
		mov		byte ptr [edi+ecx],0
	.endif
	ret

strcpyn endp

strcat proc uses esi edi,lpDest:DWORD,lpSource:DWORD

	xor		eax,eax
	xor		ecx,ecx
	dec		eax
	mov		edi,lpDest
  @@:
	inc		eax
	cmp		[edi+eax],cl
	jne		@b
	mov		esi,lpSource
	lea		edi,[edi+eax]
  @@:
	mov		al,[esi+ecx]
	mov		[edi+ecx],al
	inc		ecx
	or		al,al
	jne		@b
	ret

strcat endp

strlen proc uses esi,lpSource:DWORD

	xor		eax,eax
	dec		eax
	mov		esi,lpSource
  @@:
	inc		eax
	cmp		byte ptr [esi+eax],0
	jne		@b
	ret

strlen endp

strcmp proc uses esi edi,lpStr1:DWORD,lpStr2:DWORD

	mov		esi,lpStr1
	mov		edi,lpStr2
	xor		ecx,ecx
	dec		ecx
  @@:
	inc		ecx
	mov		al,[esi+ecx]
	sub		al,[edi+ecx]
	jne		@f
	cmp		al,[esi+ecx]
	jne		@b
  @@:
	cbw
	cwde
	ret

strcmp endp

strcmpn proc uses esi edi,lpStr1:DWORD,lpStr2:DWORD,nCount:DWORD

	mov		esi,lpStr1
	mov		edi,lpStr2
	xor		ecx,ecx
	dec		ecx
  @@:
	inc		ecx
	cmp		ecx,nCount
	je		@f
	mov		al,[esi+ecx]
	sub		al,[edi+ecx]
	jne		@f
	cmp		al,[esi+ecx]
	jne		@b
  @@:
	cbw
	cwde
	ret

strcmpn endp

strcmpi proc uses esi edi,lpStr1:DWORD,lpStr2:DWORD

	mov		esi,lpStr1
	mov		edi,lpStr2
	xor		ecx,ecx
	dec		ecx
  @@:
	inc		ecx
	mov		al,[esi+ecx]
	mov		ah,[edi+ecx]
	.if al>='a' && al<='z'
		and		al,5Fh
	.endif
	.if ah>='a' && ah<='z'
		and		ah,5Fh
	.endif
	sub		al,ah
	jne		@f
	cmp		al,[esi+ecx]
	jne		@b
  @@:
	cbw
	cwde
	ret

strcmpi endp

strcmpin proc uses esi edi,lpStr1:DWORD,lpStr2:DWORD,nCount:DWORD

	mov		esi,lpStr1
	mov		edi,lpStr2
	xor		ecx,ecx
	dec		ecx
  @@:
	inc		ecx
	cmp		ecx,nCount
	je		@f
	mov		al,[esi+ecx]
	mov		ah,[edi+ecx]
	.if al>='a' && al<='z'
		and		al,5Fh
	.endif
	.if ah>='a' && ah<='z'
		and		ah,5Fh
	.endif
	sub		al,ah
	jne		@f
	cmp		al,[esi+ecx]
	jne		@b
  @@:
	cbw
	cwde
	ret

strcmpin endp

; Numbers
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

SymInitialize proc hProcess:HANDLE,UserSearchPath:LPSTR,fInvadeProcess:BOOL

	mov		eax,hProcess
	mov		hProcessDbg,eax
	mov		eax,TRUE
	ret

SymInitialize endp

SymLoadModule proc uses ebx esi,hProcess:HANDLE,hFileOpt:HANDLE,ImageName:LPSTR,ModuleName:LPSTR,BaseOfDll:DWORD,SizeOfDll:DWORD
	LOCAL	hFile:HANDLE
	LOCAL	dwBytesRead:DWORD
	LOCAL	buffer[32]:BYTE

	invoke CreateFile,ImageName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke GetFileSize,hFile,NULL
		mov		ebx,eax
		inc		ebx
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,ebx
		mov		hMemFile,eax
		invoke ReadFile,hFile,hMemFile,ebx,addr dwBytesRead,NULL
		invoke CloseHandle,hFile
		mov		esi,hMemFile
		movzx	ebx,word ptr [esi+86h]
		mov		nHeaders,ebx
		lea		esi,[esi+178h]
		.while ebx
			invoke strcpyn,addr buffer,addr [esi].SECTIONHEADER.sName,9
			invoke strcmp,addr buffer,addr szSecStab
			.if !eax
				mov		eax,[esi].SECTIONHEADER.PointerToRawData
				mov		rpstab,eax
			.endif
			invoke strcmp,addr buffer,addr szSecStabstr
			.if !eax
				mov		eax,[esi].SECTIONHEADER.PointerToRawData
				mov		rpstabs,eax
			.endif
			lea		esi,[esi+sizeof SECTIONHEADER]
			dec		ebx
		.endw
		mov		eax,TRUE
	.else
		xor		eax,eax
	.endif
	ret

SymLoadModule endp

SymGetModuleInfo proc uses ebx,hProcess:HANDLE,dwAddr:DWORD,ModuleInfo:DWORD;PIMAGEHLP_MODULE

	mov		ebx,ModuleInfo
	mov		eax,SymPdb
	mov		[ebx].IMAGEHLP_MODULE.SymType1,eax
	mov		eax,TRUE
	ret

SymGetModuleInfo endp

SourceExist proc uses esi,lpName:DWORD

	mov		esi,offset source
	.while byte ptr [esi]
		invoke strcmpi,esi,lpName
		.if !eax
			jmp		Ex
		.endif
		invoke strlen,esi
		lea		esi,[esi+eax+1]
	.endw
	invoke strcpy,esi,lpName
	mov		eax,esi
  Ex:
	ret

SourceExist endp

SymEnumTypes proc uses ebx esi edi,hProcess:HANDLE,BaseOfDll:ULONG64,EnumTypesCallback:DWORD,UserContext:DWORD
	LOCAL	szname[128]:BYTE
	LOCAL	src:SYMBOL_INFO

	invoke RtlZeroMemory,addr src,sizeof SYMBOL_INFO
	mov		esi,rpstab
	add		esi,hMemFile
	movzx	ebx,[esi].STAB.nline
	.while ebx
		movzx	eax,[esi].STAB.code
		movzx	edx,[esi].STAB.nline
		mov		edi,rpstabs
		add		edi,hMemFile
		add		edi,[esi].STAB.stabs
		.if eax==128 && !edx
			mov		src.SizeOfStruct,sizeof SYMBOL_INFO
			lea		edx,src.szName
			xor		ecx,ecx
			.while byte ptr [edi]!=':' && byte ptr [edi]
				mov		al,[edi]
				mov		[edx+ecx],al
				inc		ecx
				inc		edi
			.endw
			mov		byte ptr [edx+ecx],0
			mov		src.NameLen,ecx
			mov		src.MaxNameLen,32
			inc		edi
			.if word ptr [edi]=='tT'
				add		edi,2
			.elseif byte ptr [edi]=='t'
				inc		edi
			.endif
			invoke DecToBin,edi
			mov		src.TypeIndex,eax
			.while byte ptr [edi-1]!='=' && byte ptr [edi]
				inc		edi
			.endw
			.if byte ptr [edi]=='s'
				inc		edi
				invoke DecToBin,edi
				mov		src.nSize,eax
				mov		eax,dword ptr BaseOfDll
				mov		dword ptr src.ModBase,eax
				mov		eax,dword ptr BaseOfDll[4]
				mov		dword ptr src.ModBase[4],eax
				mov		eax,src.TypeIndex
				mov		edx,sizeof VARTYPE
				mul		edx
				lea		edi,[eax+offset vartype]
				invoke strcpy,addr [edi].VARTYPE.szName,addr src.szName
				mov		eax,src.nSize
				mov		[edi].VARTYPE.nSize,eax
				push	UserContext
				push	src.nSize
				lea		eax,src
				push	eax
				call	EnumTypesCallback
;			.elseif byte ptr [edi]=='r'
;				inc		edi
;				invoke DecToBin,edi
;				.if eax==1
;				.elseif eax==2
;				.elseif eax==3
;				.elseif eax==4
;				.elseif eax==5
;				.elseif eax==6
;				.elseif eax==7
;				.endif
			.endif
		.endif
		lea		esi,[esi+sizeof STAB]
		dec		ebx
	.endw
	mov		eax,TRUE
	ret

SymEnumTypes endp

SymEnumerateSymbols proc hProcess:HANDLE,BaseOfDll:DWORD,EnumSymbolsCallback:DWORD,UserContext:DWORD
	LOCAL	szname[128]:BYTE
	LOCAL	src:SYMBOL_INFO
	LOCAL	fproc:DWORD

	invoke RtlZeroMemory,addr src,sizeof SYMBOL_INFO
	mov		src.SizeOfStruct,sizeof SYMBOL_INFO+127
	mov		esi,rpstab
	add		esi,hMemFile
	movzx	ebx,[esi].STAB.nline
	mov		fproc,FALSE
	.while ebx
		movzx	eax,[esi].STAB.code
		movzx	edx,[esi].STAB.nline
		mov		edi,rpstabs
		add		edi,hMemFile
		add		edi,[esi].STAB.stabs
		.if eax==40
			; Global
			call	GetName
			inc		edi
			.if byte ptr [edi]=='S'
				inc		edi
				invoke DecToBin,edi
				mov		src.TypeIndex,eax
				mov		edx,sizeof VARTYPE
				mul		edx
				lea		edi,[eax+offset vartype]
				mov		eax,[edi].VARTYPE.nSize
				.if !eax
					dec		eax
				.endif
				mov		src.nSize,eax
				push	UserContext
				push	src.nSize
				push	[esi].STAB.ad
				lea		eax,src.szName
				push	eax
				call	EnumSymbolsCallback
			.endif
		.elseif eax==36
			; Proc
			xor		ecx,ecx
			.while byte ptr [edi+ecx-1]!=':' && byte ptr [edi+ecx]
				inc		ecx
			.endw
			.if byte ptr [edi+ecx]=='F'
				call	GetName
				mov		fproc,TRUE
			.endif
		.elseif eax==160
			; Param or Local
			mov		eax,[edi]
			.if dword ptr [edi]=='user' && word ptr [edi+4]=='tl'
				mov		eax,[esi].STAB.ad
				neg		eax
				mov		UserContext,eax
			.endif
		.elseif eax==224
			; Block end
			.if fproc
				mov		fproc,FALSE
				mov		eax,[esi].STAB.ad
				mov		src.nSize,eax
				push	UserContext
				push	src.nSize
				push	dword ptr src.Address
				lea		eax,src.szName
				push	eax
				call	EnumSymbolsCallback
			.endif
		.endif
		lea		esi,[esi+sizeof STAB]
		dec		ebx
	.endw
	mov		eax,TRUE
	ret

GetName:
	lea		edx,src.szName
	xor		ecx,ecx
	.while byte ptr [edi]!=':' && byte ptr [edi]
		mov		al,[edi]
		mov		[edx+ecx],al
		inc		ecx
		inc		edi
	.endw
	mov		byte ptr [edx+ecx],0
	mov		src.NameLen,ecx
	mov		src.MaxNameLen,128
	mov		eax,[esi].STAB.ad
	mov		dword ptr src.Address,eax
	mov		eax,dword ptr BaseOfDll
	mov		dword ptr src.ModBase,eax
	mov		eax,dword ptr BaseOfDll[4]
	mov		dword ptr src.ModBase[4],eax
	retn

SymEnumerateSymbols endp

SymEnumSourceFiles proc uses ebx esi edi,hProcess:HANDLE,BaseOfDll:ULONG64,pMask:DWORD,EnumSourcesCallback:DWORD,UserContext:DWORD
	LOCAL	src:SOURCEFILE

	mov		esi,rpstab
	add		esi,hMemFile
	movzx	ebx,[esi].STAB.nline
	mov		dword ptr source,0
	.while ebx
		movzx	eax,[esi].STAB.code
		movzx	edx,[esi].STAB.nline
		mov		edi,rpstabs
		add		edi,hMemFile
		add		edi,[esi].STAB.stabs
		.if eax==100 || eax==132
			invoke SourceExist,edi
			.if eax
				mov		eax,dword ptr BaseOfDll
				mov		dword ptr src.ModBase,eax
				mov		eax,dword ptr BaseOfDll[4]
				mov		dword ptr src.ModBase[4],eax
				mov		src.FileName,edi
				push	UserContext
				lea		eax,src
				push	eax
				call	EnumSourcesCallback
			.endif
		.endif
		lea		esi,[esi+sizeof STAB]
		dec		ebx
	.endw
	mov		eax,TRUE
	ret

SymEnumSourceFiles endp

SymEnumSourceLines proc hProcess:HANDLE,BaseOfDll:ULONG64,Obj:DWORD,File:DWORD,Line:DWORD,Flags:DWORD,EnumLinesCallback:DWORD,UserContext:DWORD
	LOCAL	src:SRCCODEINFO
	LOCAL	procad:DWORD

	mov		esi,rpstab
	add		esi,hMemFile
	movzx	ebx,[esi].STAB.nline
	.while ebx
		movzx	eax,[esi].STAB.code
		.if eax==132
			mov		edi,rpstabs
			add		edi,hMemFile
			add		edi,[esi].STAB.stabs
		.elseif eax==36
			mov		eax,[esi].STAB.ad
			mov		procad,eax
		.elseif eax==68
			mov		src.SizeOfStruct,sizeof SRCCODEINFO
			mov		src.Key,0
			mov		eax,dword ptr BaseOfDll
			mov		dword ptr src.ModBase,eax
			mov		eax,dword ptr BaseOfDll[4]
			mov		dword ptr src.ModBase[4],eax
			mov		src.Obj,0
			invoke strcpy,addr src.FileName,edi
			movzx	eax,[esi].STAB.nline
			mov		src.LineNumber,eax
			mov		eax,[esi].STAB.ad
			add		eax,procad
			mov		src.Address,eax
			movzx	edx,[esi].STAB.nline
			push	UserContext
			lea		eax,src
			push	eax
			call	EnumLinesCallback
		.endif
		lea		esi,[esi+sizeof STAB]
		dec		ebx
	.endw
	mov		eax,TRUE
	ret

SymEnumSourceLines endp

SymUnloadModule proc hProcess:HANDLE,BaseOfDll:DWORD

	invoke GlobalFree,hMemFile
	mov		hMemFile,0
	mov		eax,TRUE
	ret

SymUnloadModule endp

SymCleanup proc hProcess:HANDLE

	mov		eax,TRUE
	ret

SymCleanup endp

End DllEntry
