.386
.model flat, stdcall
option casemap :none   ; case sensitive

include masmParse.inc

.code

PrintWord proc lpWord:DWORD,l:DWORD

	pushad
	mov		esi,lpWord
	mov		ecx,l
	mov		al,byte ptr [esi+ecx]
	push	eax
	mov		byte ptr [esi+ecx],0
	PrintStringByAddr esi
	pop		eax
	mov		ecx,l
	mov		byte ptr [esi+ecx],al
	popad
	ret

PrintWord endp

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

strcpyn proc uses esi edi,lpDest:DWORD,lpSource:DWORD,len:DWORD

	mov		esi,lpSource
	xor		ecx,ecx
	mov		edi,lpDest
	mov		edx,len
	dec		edx
  @@:
	mov		al,[esi+ecx]
	.if sdword ptr ecx>=edx
		xor		al,al
	.endif
	mov		[edi+ecx],al
	inc		ecx
	or		al,al
	jne		@b
	ret

strcpyn endp

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

SearchMem proc uses ebx ecx edx esi edi,hMem:DWORD,lpFind:DWORD,fMCase:DWORD,fWWord:DWORD,lpCharTab:DWORD

	mov		cl,byte ptr fWWord
	mov		ch,byte ptr fMCase
	mov		edi,hMem
	dec		edi
	mov		esi,lpFind
  Nx:
	xor		edx,edx
	inc		edi
	dec		edx
  Mr:
	inc		edx
	mov		al,[edi+edx]
	mov		ah,[esi+edx]
	.if ah && al
		cmp		al,ah
		je		Mr
		.if !ch
			;Try other case (upper/lower)
			movzx	ebx,ah
			add		ebx,lpCharTab
			cmp		al,[ebx+256]
			je		Mr
		.endif
		jmp		Nx					;Test next char
	.else
		.if !ah
			or		cl,cl
			je		@f
			;Whole word
			movzx	eax,al
			add		eax,lpCharTab
			mov		al,[eax]
			dec		al
			je		Nx				;Not found yet
			lea		eax,[edi-1]
			.if eax>=hMem
				movzx	eax,byte ptr [eax]
				add		eax,lpCharTab
				mov		al,[eax]
				dec		al
				je		Nx			;Not found yet
			.endif
		  @@:
			mov		eax,edi			;Found, return pos in eax
		.else
			xor		eax,eax			;Not found
		.endif
	.endif
	ret

SearchMem endp

SearchType proc uses esi,lpType:DWORD

	mov		esi,lpData
	mov		esi,[esi].ADDINDATA.lpWordList
	.while [esi].PROPERTIES.nSize
		movzx	eax,[esi].PROPERTIES.nType
		.if eax=='T' || eax=='t' || eax=='S' || eax=='s'
			call	Compare
			je		@f
		.endif
		mov		eax,[esi].PROPERTIES.nSize
		lea		esi,[esi+eax+sizeof PROPERTIES]
	.endw
  @@:
	ret

Compare:
	lea		edx,[esi+sizeof PROPERTIES]
	mov		ecx,lpType
  @@:
	mov		al,[ecx]
	mov		ah,[edx]
	inc		ecx
	inc		edx
	.if al>='a' && al<='z'
		and		al,5Fh
	.endif
	.if al>='a' && al<='z'
		and		al,5Fh
	.endif
	sub		al,ah
	jne		@f
	cmp		al,ah
	jne		@b
  @@:
	retn

SearchType endp

IsWord proc lpSrc:DWORD,nLen:DWORD,lpWord:DWORD,lpCharTab:DWORD

	invoke strlen,lpWord
	.if eax==nLen
		push	esi
		push	edi
		mov		esi,lpSrc
		mov		edi,lpWord
		mov		edx,lpCharTab
		xor		ecx,ecx
		xor		eax,eax
		inc		eax
		.while ecx<nLen
			movzx	eax,byte ptr [esi+ecx]
			.if al==[edi+ecx]
				xor		eax,eax
			.else
				movzx	eax,byte ptr [edx+eax+256]
				.if al==[edi+ecx]
					xor		eax,eax
				.else
					.break
				.endif
			.endif
			inc		ecx
		.endw
		pop		edi
		pop		esi
		.if !eax
			inc		eax
		.else
			xor		eax,eax
		.endif
	.else
		xor		eax,eax
	.endif
	ret

IsWord endp

DestroyToEol proc lpMem:DWORD

	mov		eax,lpMem
	.while byte ptr [eax]!=0 && byte ptr [eax]!=0Dh
		mov		byte ptr [eax],20h
		inc		eax
	.endw
	ret

DestroyToEol endp

DestroyString proc lpMem:DWORD

	mov		eax,lpMem
	movzx	ecx,byte ptr [eax]
	mov		ch,cl
	inc		eax
	.while byte ptr [eax]!=0 && byte ptr [eax]!=VK_RETURN
		mov		dx,[eax]
		.if dx==cx
			mov		word ptr [eax],'  '
			lea		eax,[eax+2]
		.else
			inc		eax
			.break .if dl==cl
			mov		byte ptr [eax-1],20h
		.endif
	.endw
	ret

DestroyString endp

DestroyCmntBlock proc uses esi,lpMem:DWORD,lpCharTab:DWORD

	mov		esi,lpMem
  @@:
	invoke SearchMem,esi,addr szcomment,FALSE,TRUE,lpCharTab
	.if eax
		mov		esi,eax
		.while eax>lpMem
			.break .if byte ptr [eax-1]==VK_RETURN || byte ptr [eax-1]==0Ah
			dec		eax
		.endw
		mov		ecx,dword ptr szstring
		mov		edx,';'
		.while eax<esi
			.if byte ptr [eax]==cl || byte ptr [eax]==ch
				;String
				invoke DestroyString,eax
				mov		esi,eax
				jmp		@b
			.elseif byte ptr [eax]==dl
				;Comment
				inc		eax
				invoke DestroyToEol,eax
				mov		esi,eax
				jmp		@b
			.endif
			inc		eax
		.endw
		lea		esi,[esi+7]
		.while byte ptr [esi]==VK_SPACE || byte ptr [esi]==VK_TAB
			inc		esi
		.endw
		mov		ah,[esi]
		.if ah!=VK_RETURN && ah!=0Ah
			mov		byte ptr [esi],' '
		.endif
		.while ah!=byte ptr [esi] && byte ptr [esi+1]
			mov		al,[esi]
			.if al!=VK_RETURN && al!=0Ah
				mov		byte ptr [esi],' '
			.endif
			inc		esi
		.endw
		mov		al,[esi]
		.if al!=VK_RETURN && al!=0Ah
			mov		byte ptr [esi],' '
			inc		esi
		.endif
		jmp		@b
	.endif
	ret

DestroyCmntBlock endp

DestroyCommentsStrings proc uses esi,lpMem:DWORD

	mov		esi,lpMem
	mov		ecx,';'
	mov		edx,dword ptr szstring
	.while byte ptr [esi]
		.if byte ptr [esi]==cl
			invoke DestroyToEol,esi
			mov		esi,eax
		.elseif byte ptr [esi]==dl || byte ptr [esi]==dh
			invoke DestroyString,esi
			mov		esi,eax
			mov		ecx,';'
			mov		edx,dword ptr szstring
		.elseif byte ptr [esi]==VK_TAB
			mov		byte ptr [esi],VK_SPACE
		.else
			inc		esi
		.endif
	.endw
	ret

DestroyCommentsStrings endp

PreParse proc uses esi,lpMem:DWORD,lpCharTab:DWORD

	invoke DestroyCmntBlock,lpMem,lpCharTab
	invoke DestroyCommentsStrings,lpMem
	ret

PreParse endp

SkipScope proc

	xor		eax,eax
	xor		ecx,ecx
SkipScope1:
	mov		al,[esi]
	or		al,al
	je		@f
	inc		esi
	.if al==ah
		dec		ecx
		retn
	.elseif al=='['
		push	eax
		inc		ecx
		mov		ah,']'
		call	SkipScope1
		pop		eax
	.elseif al=='('
		push	eax
		inc		ecx
		mov		ah,')'
		call	SkipScope1
		pop		eax
	.elseif al=='{'
		; Begin / End
		push	eax
		inc		ecx
		mov		ah,'}'
		call	SkipScope1
		pop		eax
	.elseif al=='"' || al=="'"
		; String
		inc		ecx
		.while al!=[esi] && byte ptr [esi]
			inc		esi
		.endw
		.if al==[esi]
			inc		esi
			dec		ecx
		.endif
	.elseif word ptr [esi]=='//'
		; Comment
		.while byte ptr [esi]!=VK_RETURN && byte ptr [esi]
			inc		esi
		.endw
		.if byte ptr [esi]==VK_RETURN
			inc		esi
			.if byte ptr [esi]==0Ah
				inc		esi
			.endif
		.endif
	.endif
	or		ecx,ecx
	jne		SkipScope1
  @@:
	ret

SkipScope endp

FindInFile proc uses esi edi,nInx:DWORD,lpMem:DWORD,lpFind1:DWORD,lpFind2:DWORD,lpCharTab:DWORD
	LOCAL	nLine:DWORD
	LOCAL	lpPos:DWORD

	mov		nLine,-1
	mov		esi,lpMem
;	.if nInx==0
;		; Function
;		invoke strcpy,offset buffer1,lpFind2
;		mov		edi,offset buffer1
;		invoke strlen,edi
;		mov		dword ptr [edi+eax],0
;		.while byte ptr [edi]
;			.if byte ptr [edi]==' ' || byte ptr [edi]==','
;				mov		byte ptr [edi],0
;			.endif
;			inc		edi
;		.endw
;	  @@:
;		invoke SearchMem,esi,lpFind1,TRUE,TRUE,lpCharTab
;		.if eax
;			mov		esi,eax
;			mov		edi,eax
;			.while byte ptr [edi]
;				.if byte ptr [edi]==';'
;					inc		esi
;					jmp		@b
;				.elseif byte ptr [edi]=='{'
;					call	CopyLine
;					or		edx,edx
;					jne		@b
;					mov		edi,offset buffer1
;					invoke SearchMem,offset buffer,edi,TRUE,TRUE,lpCharTab
;					or		eax,eax
;					je		@b
;					call	GetLineNo
;					.break
;				.endif
;				inc		edi
;			.endw
;		.endif
;	.elseif nInx==1
;		; Constant
;	  @@:
;		invoke SearchMem,esi,offset szDefine,FALSE,TRUE,lpCharTab
;		.if eax
;			mov		esi,eax
;			call	CopyLine
;			or		edx,edx
;			jne		@b
;			invoke SearchMem,offset buffer,lpFind1,TRUE,TRUE,lpCharTab
;			or		eax,eax
;			je		@b
;			call	GetLineNo
;		.endif
;	.elseif nInx==2
;		; Data
;	  @@:
;		invoke SearchMem,esi,lpFind2,FALSE,TRUE,lpCharTab
;		.if eax
;			mov		esi,eax
;			call	CopyLine
;			or		edx,edx
;			jne		@b
;			invoke SearchMem,offset buffer,lpFind1,TRUE,TRUE,lpCharTab
;			or		eax,eax
;			je		@b
;			call	GetLineNo
;		.endif
;	.elseif nInx==5
;		; Struct
;	  @@:
;		invoke SearchMem,esi,offset szStruct,FALSE,TRUE,lpCharTab
;		.if !eax
;			invoke SearchMem,esi,offset szUnion,FALSE,TRUE,lpCharTab
;		.endif
;		.if eax
;			mov		esi,eax
;			call	CopyLine
;			or		edx,edx
;			jne		@b
;			mov		esi,lpPos
;			.while byte ptr [esi]!='{' && byte ptr [esi]
;				inc		esi
;			.endw
;			.if byte ptr [esi]=='{'
;				call	SkipScope
;				.if !ecx
;					.while byte ptr [esi]!=0Dh
;						mov		al,[esi]
;						mov		[edi],al
;						inc		esi
;						inc		edi
;					.endw
;					mov		byte ptr [edi],0
;					invoke SearchMem,offset buffer,lpFind1,TRUE,TRUE,lpCharTab
;					or		eax,eax
;					je		@b
;					mov		esi,lpPos
;					call	GetLineNo
;				.endif
;			.endif
;		.endif
;	.endif
;	mov		eax,nLine
;	mov		edx,lpPos
	ret

GetLineStart:
	.while esi>lpMem
		mov		al,[esi]
		.if al=='(' || al=='/' || al=='"' || al=="'"
			inc		edx
		.endif
		.break .if byte ptr [esi-1]==0Dh || byte ptr [esi-1]==0Ah
		dec		esi
	.endw
	mov		lpPos,esi
	retn

CopyLine:
	xor		edx,edx
	call	GetLineStart
	mov		edi,offset buffer
	.while byte ptr [esi]!=0Dh
		mov		al,[esi]
		mov		[edi],al
		inc		esi
		inc		edi
	.endw
	mov		byte ptr [edi],0
	retn

GetLineNo:
	xor		ecx,ecx
	mov		eax,esi
	mov		esi,lpMem
	.while esi<eax
		.if byte ptr [esi]==VK_RETURN
			inc		ecx
		.endif
		inc		esi
		mov		nLine,ecx
	.endw
	retn

FindInFile endp

ParseFile proc uses ebx esi edi,iNbr:DWORD,lpMem:DWORD,lpAddProperty:DWORD,lpCharTab:DWORD
	LOCAL	len1:DWORD
	LOCAL	lpword1:DWORD

	mov		esi,lpMem
	.while byte ptr [esi]
		call	GetWrd
		.if ecx
			mov		len1,ecx
			mov		lpword1,esi
			call	_Skip
			or		eax,eax
			jne		Nxt
		.endif
	  Nxt:
		call	SkipLine
	.endw
	ret

SkipLine:
	.while byte ptr [esi] && byte ptr [esi]!=VK_RETURN
		inc		esi
	.endw
	.if byte ptr [esi]==VK_RETURN
		inc		esi
	.endif
	.if byte ptr [esi]==0Ah
		inc		esi
	.endif
	retn

SkipSpc:
	.while byte ptr [esi]==VK_SPACE
		inc		esi
	.endw
	xor		ecx,ecx
	.if byte ptr [esi]=='\' || byte ptr [esi]==','
		inc		ecx
		.while byte ptr [esi+ecx]==VK_SPACE
			inc		ecx
		.endw
		.if byte ptr [esi+ecx]==VK_RETURN
			lea		esi,[esi+ecx+1]
			.if byte ptr [esi]==0Ah
				inc		esi
			.endif
			jmp		SkipSpc
		.endif
	.endif
	retn

GetWrd:
	call	SkipSpc
	mov		edx,lpCharTab
	xor		ecx,ecx
	dec		ecx
  @@:
	inc		ecx
	movzx	eax,byte ptr [esi+ecx]
	cmp		byte ptr [eax+edx],1
	je		@b
	cmp		eax,'+'
	je		@b
	cmp		eax,'-'
	je		@b
	cmp		eax,'#'
	je		@b
	retn

_Skip:
	mov		ebx,offset szskiplinefirstword
	mov		edi,len1
	.while byte ptr [ebx]
		movzx	eax,byte ptr [ebx]
		.if eax==edi
			invoke strcmpin,esi,addr [ebx+1],edi
			.if !eax
				mov		eax,TRUE
				retn
			.endif
			mov		eax,edi
		.endif
		lea		ebx,[ebx+eax+1]
	.endw
	xor		eax,eax
	retn

ParseFile endp

FindProcPos proc uses esi edi,lpMem:DWORD,lpPos:DWORD,lpCharTab:DWORD

	xor		eax,eax
	mov		lpFunSt,eax
	mov		lpFunEn,eax
	mov		eax,lpPos
	mov		lpFunPos,eax
	invoke ParseFile,0,lpMem,NULL,lpCharTab
	mov		esi,lpFunSt
	.if esi>lpMem
		.while byte ptr [esi-1]!=VK_RETURN && esi>lpMem
			dec		esi
		.endw
		mov		lpFunSt,esi
	.endif
	mov		eax,lpFunPos
	.if eax>=lpFunSt && eax<=lpFunEn
		mov		eax,lpFunSt
	.else
		xor		eax,eax
	.endif
	mov		lpFunPos,0
	ret

FindProcPos endp

FindLocal proc uses esi,hMem:DWORD,lpProcName:DWORD,lpMSt:DWORD,lpWord:DWORD,lpCharTab:DWORD

	mov		esi,lpData
	mov		esi,[esi].ADDINDATA.lpWordList
	.while [esi].PROPERTIES.nSize
		movzx	eax,[esi].PROPERTIES.nType
		.if eax=='p'
			call	Compare
			je		@f
		.endif
		mov		eax,[esi].PROPERTIES.nSize
		lea		esi,[esi+eax+sizeof PROPERTIES]
	.endw
  @@:
	lea		esi,[esi+sizeof PROPERTIES]
	invoke strlen,esi
	lea		esi,[esi+eax+1]
	invoke SearchMem,esi,lpWord,TRUE,TRUE,lpCharTab
	.if !eax
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		invoke SearchMem,esi,lpWord,TRUE,TRUE,lpCharTab
	.endif
	.if eax
		invoke SearchMem,hMem,lpWord,TRUE,TRUE,lpCharTab
	.endif
	ret

Compare:
	lea		edx,[esi+sizeof PROPERTIES]
	mov		ecx,lpProcName
  @@:
	mov		al,[ecx]
	mov		ah,[edx]
	inc		ecx
	inc		edx
	sub		al,ah
	jne		@f
	cmp		al,ah
	jne		@b
  @@:
	retn

FindLocal endp

InstallDll proc uses ebx,hWin:DWORD,fOpt:DWORD

	mov		ebx,hWin
	;Get pointer to handles struct
	invoke SendMessage,ebx,AIM_GETHANDLES,0,0
	mov		lpHandles,eax
	;Get pointer to procs struct
	invoke SendMessage,ebx,AIM_GETPROCS,0,0
	mov		lpProcs,eax
	;Get pointer to data struct
	invoke SendMessage,ebx,AIM_GETDATA,0,0
	mov		lpData,eax
	ret

InstallDll endp

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	.if reason==DLL_PROCESS_ATTACH
	.elseif reason==DLL_PROCESS_DETACH
	.endif
	mov     eax,TRUE
	ret

DllEntry Endp

End DllEntry
