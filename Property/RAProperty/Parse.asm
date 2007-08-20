
.code

SearchMemDown proc uses ebx ecx edx esi edi,hMem:DWORD,lpFind:DWORD,fMCase:DWORD,fWWord:DWORD,lpCharTab:DWORD

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

SearchMemDown endp

SearchMemUp proc uses ebx ecx edx esi edi,hMem:DWORD,lpFind:DWORD,fMCase:DWORD,fWWord:DWORD,lpCharTab:DWORD

	mov		cl,byte ptr fWWord
	mov		ch,byte ptr fMCase
	mov		edi,hMem
	.while byte ptr [edi]
		inc		edi
	.endw
	mov		esi,lpFind
  Nx:
	xor		edx,edx
	dec		edi
	dec		edx
	.if edi<hMem
		; Not found
		xor		eax,eax
		ret
	.endif
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
			je		@f				;Found
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

SearchMemUp endp

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
	mov		byte ptr [eax],20h
	inc		eax
	.while byte ptr [eax]!=0 && byte ptr [eax]!=0Dh
		mov		dx,[eax]
		.if dl==cl && dh==cl
			mov		byte ptr [eax],20h
			inc		eax
			mov		byte ptr [eax],20h
			inc		eax
		.else
			mov		byte ptr [eax],20h
			inc		eax
			.break .if dl==cl
		.endif
	.endw
	ret

DestroyString endp

DestroyCmntBlock proc uses esi,lpMem:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	fbyte:DWORD

	mov		fbyte,0
	mov		esi,lpMem
	invoke lstrcpy,addr buffer,addr [ebx].RAPROPERTY.defgen.szCmntBlockSt
	invoke strlen,addr buffer
	.if eax
		dec		eax
		.if byte ptr buffer[eax]=='+'
			mov		byte ptr buffer[eax],0
			.if byte ptr buffer[eax-1]==' '
				dec		eax
				mov		byte ptr buffer[eax],0
			.endif
			mov		fbyte,eax
		.endif
	  @@:
		invoke SearchMemDown,esi,addr buffer,FALSE,TRUE,[ebx].RAPROPERTY.lpchartab
		.if eax
			mov		esi,eax
			mov		ecx,dword ptr [ebx].RAPROPERTY.defgen.szCmntChar
;			dec		eax
			.while eax>lpMem
				.break .if byte ptr [eax-1]==0Dh || byte ptr [eax-1]==0Ah
				dec		eax
			.endw
			mov		ecx,dword ptr [ebx].RAPROPERTY.defgen.szString
			mov		edx,dword ptr [ebx].RAPROPERTY.defgen.szCmntChar
			.while eax<esi
				.if byte ptr [eax]==cl || byte ptr [eax]==ch
					;String
					invoke DestroyString,eax
					mov		esi,eax
					jmp		@b
				.elseif (byte ptr [eax]==cl && ch==0) || word ptr [eax]==dx
					;Comment
					invoke DestroyToEol,eax
					mov		esi,eax
					jmp		@b
				.endif
				inc		eax
			.endw
			.if fbyte
				add		esi,fbyte
				.while byte ptr [esi]==' ' || byte ptr [esi]==VK_TAB
					inc		esi
				.endw
				mov		ah,[esi]
				.if ah!=0Dh && ah!=0Ah
					mov		byte ptr [esi],' '
				.endif
				.while ah!=byte ptr [esi] && byte ptr [esi+1]
					mov		al,[esi]
					.if al!=0Dh && al!=0Ah
						mov		byte ptr [esi],' '
					.endif
					inc		esi
				.endw
				mov		al,[esi]
				.if al!=0Dh && al!=0Ah
					mov		byte ptr [esi],' '
					inc		esi
				.endif
				jmp		@b
			.else
				invoke SearchMemDown,esi,addr [ebx].RAPROPERTY.defgen.szCmntBlockEn,FALSE,TRUE,[ebx].RAPROPERTY.lpchartab
				.if eax
					mov		edx,eax
					.if [ebx].RAPROPERTY.defgen.szCmntBlockEn[1]
						inc		edx
					.endif
					.while esi<=edx
						mov		al,[esi]
						.if al!=0Dh && al!=0Ah
							mov		byte ptr [esi],' '
						.endif
						inc		esi
					.endw
					jmp		@b
				.endif
			.endif
		.endif
	.endif
	ret

DestroyCmntBlock endp

DestroyCommentsStrings proc uses esi,lpMem:DWORD

	mov		esi,lpMem
	mov		ecx,dword ptr [ebx].RAPROPERTY.defgen.szCmntChar
	mov		edx,dword ptr [ebx].RAPROPERTY.defgen.szString
	.while byte ptr [esi]
		.if (byte ptr [esi]==cl && !ch)
			invoke DestroyToEol,esi
			mov		esi,eax
		.elseif (byte ptr [esi]==cl && byte ptr [esi+1]==ch)
			invoke DestroyToEol,esi
			mov		esi,eax
		.elseif byte ptr [esi]==dl || byte ptr [esi]==dh
			push	ecx
			push	edx
			invoke DestroyString,esi
			mov		esi,eax
			pop		edx
			pop		ecx
		.else
			inc		esi
		.endif
	.endw
	ret

DestroyCommentsStrings endp

PreParse proc uses esi,lpMem:DWORD

	invoke DestroyCmntBlock,lpMem
	invoke DestroyCommentsStrings,lpMem
	ret

PreParse endp

SkipLine proc lpMem:DWORD,lpnpos:DWORD

	mov		eax,lpMem
	movzx	ecx,byte ptr [ebx].RAPROPERTY.defgen.szLineCont
	.while byte ptr [eax] && byte ptr [eax]!=0Dh
		.if cl==byte ptr [eax] && byte ptr [eax+1]==0Dh
			mov		edx,lpnpos
			inc		dword ptr [edx]
			.if byte ptr [eax+2]==0Ah
				inc		eax
			.endif
			inc		eax
		.endif
		inc		eax
	.endw
	.if byte ptr [eax]==0Dh
		inc		eax
	.endif
	.if byte ptr [eax]==0Ah
		inc		eax
	.endif
	ret

SkipLine endp

GetWord proc uses esi,lpMem:DWORD,lpnpos:DWORD

	mov		edx,lpMem
	movzx	ecx,byte ptr [ebx].RAPROPERTY.defgen.szLineCont
	.while byte ptr [edx]==VK_SPACE || byte ptr [edx]==VK_TAB || (cl==byte ptr [edx] && byte ptr [edx+1]==0Dh)
		.if cl==byte ptr [edx]
			mov		eax,lpnpos
			inc		dword ptr [eax]
			.if byte ptr [edx+2]==0Ah
				inc		edx
			.endif
			inc		edx
		.endif
		inc		edx
	.endw
	xor		ecx,ecx
	mov		esi,[ebx].RAPROPERTY.lpchartab
  @@:
	movzx	eax,byte ptr [edx+ecx]
	.if byte ptr [esi+eax]==CT_CHAR || eax=='.'
		inc		ecx
		jmp		@b
	.endif
	ret

GetWord endp

Compare proc uses esi,lpWord1:DWORD,lpWord2:DWORD,len:DWORD

	mov		esi,lpWord1
	mov		edx,lpWord2
	mov		ecx,len
	.while ecx
		dec		ecx
		mov		al,[esi+ecx]
		mov		ah,[edx+ecx]
		.if al>='A' && al<='Z'
			or		al,20h
		.endif
		.if ah>='A' && ah<='Z'
			or		ah,20h
		.endif
		sub		al,ah
		.break .if !ZERO?
	.endw
	mov		ecx,len
	movsx	eax,al
	ret

Compare endp

WhatIsIt proc uses esi,lpWord1:DWORD,len1:DWORD,lpWord2:DWORD,len2:DWORD

	mov		esi,[ebx].RAPROPERTY.lpdeftype
  @@:
	movzx	eax,[esi].DEFTYPE.nType
	.if eax
		movzx	ecx,[esi].DEFTYPE.len
		.if eax==TYPE_NAMEFIRST
			.if ecx==len2
				invoke Compare,lpWord2,addr [esi].DEFTYPE.szWord,ecx
				or		eax,eax
				je		Ex
			.endif
		.elseif eax==TYPE_OPTNAMEFIRST
			.if ecx==len2
				invoke Compare,lpWord2,addr [esi].DEFTYPE.szWord,ecx
				or		eax,eax
				je		Ex
			.endif
			.if ecx==len1
				invoke Compare,lpWord1,addr [esi].DEFTYPE.szWord,ecx
				or		eax,eax
				je		Ex
			.endif
		.elseif eax==TYPE_NAMESECOND
			.if ecx==len1 && len2!=0
				invoke Compare,lpWord1,addr [esi].DEFTYPE.szWord,ecx
				or		eax,eax
				je		Ex
			.endif
		.elseif eax==TYPE_OPTNAMESECOND
			.if ecx==len1
				invoke Compare,lpWord1,addr [esi].DEFTYPE.szWord,ecx
				or		eax,eax
				je		Ex
			.endif
		.elseif eax==TYPE_TWOWORDS
			.if ecx==len1
				invoke Compare,lpWord1,addr [esi].DEFTYPE.szWord,ecx
				or		eax,eax
				.if ZERO?
					mov		eax,ecx
					movzx	ecx,[esi+eax].DEFTYPE.szWord
					.if ecx==len2
						invoke Compare,lpWord2,addr [esi+eax+1].DEFTYPE.szWord,ecx
						or		eax,eax
						je		Ex
					.endif
				.endif
			.endif
		.elseif eax==TYPE_ONEWORD
			.if ecx==len1
				invoke Compare,lpWord1,addr [esi].DEFTYPE.szWord,ecx
				or		eax,eax
				je		Ex
			.endif
		.endif
		add		esi,sizeof DEFTYPE
		jmp		@b
	.endif
	ret
  Ex:
	mov		eax,esi
	ret

WhatIsIt endp

;PrintWord proc lpWord,len
;	
;	pushad
;	mov		edx,lpWord
;	mov		ecx,len
;	mov		al,[edx+ecx]
;	mov		byte ptr [edx+ecx],0
;	PrintStringByAddr edx
;	mov		[edx+ecx],al
;	popad
;	ret
;
;PrintWord endp

IsIgnore proc uses ecx esi,nType:DWORD,len:DWORD,lpWord:DWORD

	mov		esi,[ebx].RAPROPERTY.lpignore
	.if esi
	  @@:
		mov		al,byte ptr nType
		mov		ah,byte ptr len
		.if ax==word ptr [esi]
			invoke Compare,addr [esi+2],lpWord,len
			.if eax
				movzx	eax,byte ptr [esi+1]
				lea		esi,[esi+eax+3]
				jmp		@b
			.endif
			inc		eax
			jmp		Ex
		.elseif word ptr [esi]
			movzx	eax,byte ptr [esi+1]
			lea		esi,[esi+eax+3]
			jmp		@b
		.endif
	.endif
	xor		eax,eax
  Ex:
	ret

IsIgnore endp

IsWord proc uses ecx esi,nType:DWORD,len:DWORD,lpWord:DWORD

	mov		esi,[ebx].RAPROPERTY.lpignore
	.if esi
	  @@:
		mov		al,byte ptr nType
		mov		ah,byte ptr len
		.if ax==word ptr [esi]
			invoke Compare,addr [esi+2],lpWord,len
			.if eax
				movzx	eax,byte ptr [esi+1]
				lea		esi,[esi+eax+3]
				jmp		@b
			.endif
			inc		eax
			jmp		Ex
		.elseif word ptr [esi]
			movzx	eax,byte ptr [esi+1]
			lea		esi,[esi+eax+3]
			jmp		@b
		.endif
	.endif
	xor		eax,eax
  Ex:
	ret

IsWord endp

ParseFile proc uses esi edi,nOwner:DWORD,lpMem:DWORD
	LOCAL	lpword1:DWORD
	LOCAL	len1:DWORD
	LOCAL	lpword2:DWORD
	LOCAL	len2:DWORD
	LOCAL	lpdef:DWORD
	LOCAL	npos:DWORD
	LOCAL	nline:DWORD
	LOCAL	lpdatatype:DWORD
	LOCAL	lendatatype:DWORD
	LOCAL	rpnmespc:DWORD
	LOCAL	rpwithblock[4]:DWORD
	LOCAL	nNest:DWORD
	LOCAL	fPtr:DWORD
	LOCAL	fRetType:DWORD

	mov		npos,0
	mov		rpnmespc,-1
	mov		rpwithblock[0],-1
	mov		rpwithblock[4],-1
	mov		rpwithblock[8],-1
	mov		rpwithblock[12],-1
	mov		esi,lpMem
	.while byte ptr [esi]
		mov		eax,npos
		mov		nline,eax
		mov		fPtr,0
		mov		fRetType,0
	  Nxtwrd:
		invoke GetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			invoke IsIgnore,IGNORE_LINEFIRSTWORD,ecx,esi
			.if eax
				jmp		Nxt
			.endif
			invoke IsIgnore,IGNORE_FIRSTWORD,ecx,esi
			.if eax
				lea		esi,[esi+ecx]
				jmp		Nxtwrd
			.endif
			invoke IsIgnore,IGNORE_FIRSTWORDTWOWORDS,ecx,esi
			.if eax
				lea		esi,[esi+ecx]
				invoke GetWord,esi,addr npos
				mov		esi,edx
				lea		esi,[esi+ecx]
				jmp		Nxtwrd
			.endif
			mov		lpword1,esi
			mov		len1,ecx
			lea		esi,[esi+ecx]
			mov		lpdatatype,0
			mov		fPtr,0
		  Nxtwrd1:
			invoke GetWord,esi,addr npos
			mov		esi,edx
			.if ecx
				invoke IsIgnore,IGNORE_LINESECONDWORD,ecx,esi
				.if eax
					jmp		Nxt
				.endif
				invoke IsIgnore,IGNORE_SECONDWORD,ecx,esi
				.if eax
					lea		esi,[esi+ecx]
					jmp		Nxtwrd1
				.endif
				invoke IsIgnore,IGNORE_PTR,ecx,esi
				.if eax
					lea		esi,[esi+ecx]
					inc		fPtr
					jmp		Nxtwrd1
				.endif
				invoke IsIgnore,IGNORE_SECONDWORDTWOWORDS,ecx,esi
				.if eax
					lea		esi,[esi+ecx]
					invoke GetWord,esi,addr npos
					mov		esi,edx
					lea		esi,[esi+ecx]
					jmp		Nxtwrd1
				.endif
				invoke IsIgnore,IGNORE_DATATYPEINIT,ecx,esi
				.if eax
					lea		esi,[esi+ecx]
					invoke GetWord,esi,addr npos
					mov		esi,edx
					mov		lpdatatype,esi
					mov		lendatatype,ecx
					lea		esi,[esi+ecx]
					jmp		Nxtwrd1
				.endif
			.elseif byte ptr [esi]=='*'
				inc		esi
				invoke GetWord,esi,addr npos
				mov		esi,edx
				lea		esi,[esi+ecx]
				jmp		Nxtwrd1
			.endif
			mov		lpword2,esi
			mov		len2,ecx
			lea		esi,[esi+ecx]
			invoke WhatIsIt,lpword1,len1,lpword2,len2
			.if eax
				mov		lpdef,eax
				movzx	edx,[eax].DEFTYPE.nDefType
				movzx	eax,[eax].DEFTYPE.nType
				mov		edi,offset szname
				.if edx==DEFTYPE_PROC
					call	ParseProc
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,4
					.endif
				.elseif edx==DEFTYPE_MACRO
					call	ParseMacro
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
					.endif
				.elseif edx==DEFTYPE_CONSTRUCTOR
					call	ParseConstructor
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,4
					.endif
				.elseif edx==DEFTYPE_DESTRUCTOR
					call	ParseDestructor
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,4
					.endif
				.elseif edx==DEFTYPE_PROPERTY
					call	ParseProperty
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,4
					.endif
				.elseif edx==DEFTYPE_OPERATOR
					call	ParseOperator
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,4
					.endif
				.elseif edx==DEFTYPE_DATA
					call	ParseData
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
					.endif
					call	SkipToComma
					.if byte ptr [esi]==','
						inc		esi
						jmp		Nxtwrd1
					.endif
				.elseif edx==DEFTYPE_CONST
					call	ParseConst
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
					.endif
					call	SkipToComma
					.if byte ptr [esi]==','
						inc		esi
						jmp		Nxtwrd1
					.elseif byte ptr [esi]=='='
						inc		esi
						call	SkipToComma
						.if byte ptr [esi]==','
							inc		esi
							jmp		Nxtwrd1
						.endif
					.endif
				.elseif edx==DEFTYPE_STRUCT
					call	ParseStruct
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
					.endif
				.elseif edx==DEFTYPE_TYPE
				.elseif edx==DEFTYPE_NAMESPACE
					call	ParseNameSpace
					.if eax
						mov		eax,[ebx].RAPROPERTY.rpfree
						mov		rpnmespc,eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,-1,addr szname,1
					.endif
				.elseif edx==DEFTYPE_ENDNAMESPACE
					.if rpnmespc!=-1
						mov		edx,[ebx].RAPROPERTY.lpmem
						add		edx,rpnmespc
						mov		eax,npos
						mov		[edx].PROPERTIES.nEnd,eax
						mov		rpnmespc,-1
					.endif
				.elseif edx==DEFTYPE_ENUM
					call	ParseEnum
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
					.endif
				.elseif edx==DEFTYPE_WITHBLOCK
					call	ParseWithBlock
					.if eax
						mov		eax,rpwithblock[8]
						mov		rpwithblock[12],eax
						mov		eax,rpwithblock[4]
						mov		rpwithblock[8],eax
						mov		eax,rpwithblock[0]
						mov		rpwithblock[4],eax
						mov		eax,[ebx].RAPROPERTY.rpfree
						mov		rpwithblock,eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,-1,addr szname,1
					.endif
				.elseif edx==DEFTYPE_ENDWITHBLOCK
					.if rpwithblock!=-1
						mov		edx,[ebx].RAPROPERTY.lpmem
						add		edx,rpwithblock
						mov		eax,npos
						mov		[edx].PROPERTIES.nEnd,eax
						mov		eax,rpwithblock[4]
						mov		rpwithblock[0],eax
						mov		eax,rpwithblock[8]
						mov		rpwithblock[4],eax
						mov		eax,rpwithblock[12]
						mov		rpwithblock[8],eax
						mov		rpwithblock[12],-1
					.endif
				.endif
			.endif
		.endif
	  Nxt:
		invoke SkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
	.endw
	ret

AddNamespace:
	push	eax
	.if rpnmespc!=-1
		mov		edx,[ebx].RAPROPERTY.lpmem
		add		edx,rpnmespc
		invoke lstrcpy,edi,addr [edx+sizeof PROPERTIES]
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		word ptr [edi],'.'
		inc		edi
	.endif
	pop		eax
	retn

SaveName:
	mov		edx,edi
	.if eax==TYPE_NAMEFIRST
		mov		eax,len1
		inc		eax
		lea		edi,[edx+eax]
		invoke lstrcpyn,edx,lpword1,eax
	.elseif eax==TYPE_NAMESECOND || eax==TYPE_OPTNAMESECOND
		mov		eax,len2
		inc		eax
		lea		edi,[edx+eax]
		invoke lstrcpyn,edx,lpword2,eax
	.endif
	retn

SkipBrace:
	xor		eax,eax
	dec		eax
SkipBrace1:
	.while byte ptr [esi]==VK_SPACE || byte ptr [esi]==VK_TAB
		inc		esi
	.endw
	mov		al,[esi]
	inc		esi
	.if al=='('
		push	eax
		mov		ah,')'
		jmp		SkipBrace1
	.elseif al=='{'
		push	eax
		mov		ah,'}'
		jmp		SkipBrace1
	.elseif al=='['
		push	eax
		mov		ah,']'
		jmp		SkipBrace1
	.elseif al=='"'
		push	eax
		mov		ah,'"'
		jmp		SkipBrace1
	.elseif al==ah
		pop		eax
	.elseif ah==0FFh
		dec		esi
		retn
	.elseif al==VK_RETURN || al==0
		dec		esi
		pop		eax
	.endif
	jmp		SkipBrace1

SkipToComma:
	.while byte ptr [esi]==VK_SPACE || byte ptr [esi]==VK_TAB
		inc		esi
	.endw
	.while byte ptr [esi] && byte ptr [esi]!=0Dh && byte ptr [esi]!=',' && byte ptr [esi]!='='
		call	SkipBrace
		.if byte ptr [esi] && byte ptr [esi]!=0Dh && byte ptr [esi]!=',' && byte ptr [esi]!='='
			inc		esi
		.endif
	.endw
	retn

SkipSpc:
	.while byte ptr [esi]==VK_SPACE || byte ptr [esi]==VK_TAB
		inc		esi
	.endw
	retn

ParseWithBlock:
	call	SaveName
	xor		eax,eax
	inc		eax
	retn

ParseEnum:
	call	AddNamespace
	call	SaveName
	.while byte ptr [esi]
		invoke SkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
		invoke GetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			mov		lpword1,esi
			mov		len1,ecx
			lea		esi,[esi+ecx]
			invoke GetWord,esi,addr npos
			mov		esi,edx
			.if ecx
				mov		lpword2,esi
				mov		len2,ecx
				lea		esi,[esi+ecx]
				invoke WhatIsIt,lpword1,len1,lpword2,len2
				.if eax
					movzx	eax,[eax].DEFTYPE.nDefType
					.if eax==DEFTYPE_ENDENUM
						mov		byte ptr [edi],0
						retn
					.endif
				.endif
			.endif
			.if byte ptr [edi]==','
				inc		edi
			.endif
			mov		eax,len1
			inc		eax
			invoke lstrcpyn,edi,lpword1,eax
			add		edi,len1
			mov		word ptr [edi],','
		.endif
	.endw
	xor		eax,eax
	retn

ParseNameSpace:
	call	SaveName
	xor		eax,eax
	inc		eax
	retn

ParseMacro:
	call	AddNamespace
	call	SaveName
  @@:
	invoke GetWord,esi,addr npos
	mov		esi,edx
	.if !ecx
		.if byte ptr [esi]==',' || byte ptr [esi]=='('
			inc		esi
			jmp		@b
		.endif
	.else
		mov		lpword1,esi
		mov		len1,ecx
		lea		esi,[esi+ecx]
		mov		edx,edi
		mov		eax,len1
		inc		eax
		lea		edi,[edx+eax]
		invoke lstrcpyn,edx,lpword1,eax
		mov		byte ptr [edi],','
		inc		edi
		call	SkipToComma
		.if byte ptr [esi]==','
			inc		esi
			jmp		@b
		.endif
	.endif
	.if byte ptr [edi-1]==','
		dec		edi
	.endif
	mov		word ptr [edi],0
	.while byte ptr [esi]
		invoke SkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
		invoke GetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			mov		lpword1,esi
			mov		len1,ecx
			mov		lpword2,esi
			mov		len2,ecx
			lea		esi,[esi+ecx]
			invoke WhatIsIt,lpword1,len1,lpword2,len2
			.if eax
				movzx	eax,[eax].DEFTYPE.nDefType
				.if eax==DEFTYPE_ENDMACRO
					retn
				.endif
			.endif
		.endif
	.endw
	xor		eax,eax
	retn

ParseConstructor:
	call	AddNamespace
	call	SaveName
	call	SaveParam
	.while byte ptr [esi]
		mov		fPtr,0
		invoke SkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
		invoke GetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			mov		lpword1,esi
			mov		len1,ecx
			lea		esi,[esi+ecx]
			call	NxtWordProc
			.if eax
				retn
			.endif
		.endif
	.endw
	xor		eax,eax
	retn

ParseDestructor:
	call	AddNamespace
	call	SaveName
	call	SaveParam
	.while byte ptr [esi]
		mov		fPtr,0
		invoke SkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
		invoke GetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			mov		lpword1,esi
			mov		len1,ecx
			lea		esi,[esi+ecx]
			call	NxtWordProc
			.if eax
				retn
			.endif
		.endif
	.endw
	xor		eax,eax
	retn

ParseProperty:
	call	AddNamespace
	call	SaveName
	call	SaveParam
	.while byte ptr [esi]
		mov		fPtr,0
		invoke SkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
		invoke GetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			mov		lpword1,esi
			mov		len1,ecx
			lea		esi,[esi+ecx]
			call	NxtWordProc
			.if eax
				retn
			.endif
		.endif
	.endw
	xor		eax,eax
	retn

ParseOperator:
	call	AddNamespace
	mov		edx,edi
	.if eax==TYPE_NAMEFIRST
		mov		eax,len1
		inc		eax
		lea		edi,[edx+eax]
		invoke lstrcpyn,edx,lpword1,eax
	.elseif eax==TYPE_NAMESECOND
		mov		eax,len2
		inc		eax
		lea		edi,[edx+eax]
		invoke lstrcpyn,edx,lpword2,eax
	.elseif eax==TYPE_OPTNAMESECOND
		mov		edx,lpword2
	  @@:
		mov		al,[edx]
		.if al!=0 && al!=VK_SPACE && al!=VK_TAB && al!=VK_RETURN && al !='('
			mov		[edi],al
			inc		edx
			inc		edi
			jmp		@b
		.endif
		mov		byte ptr [edi],0
		inc		edi
		mov		esi,edx
	.endif
	call	SaveParam
	.while byte ptr [esi]
		mov		fPtr,0
		invoke SkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
		invoke GetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			mov		lpword1,esi
			mov		len1,ecx
			lea		esi,[esi+ecx]
			call	NxtWordProc
			.if eax
				retn
			.endif
		.endif
	.endw
	xor		eax,eax
	retn

ParseProc:
	call	AddNamespace
	call	SaveName
	call	SaveParam
	.while byte ptr [esi]
		mov		fPtr,0
		invoke SkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
		invoke GetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			mov		lpword1,esi
			mov		len1,ecx
			lea		esi,[esi+ecx]
			call	NxtWordProc
			.if eax
				retn
			.endif
		.endif
	.endw
	xor		eax,eax
	retn

NxtWordProc:
	invoke GetWord,esi,addr npos
	mov		esi,edx
	.if ecx
		mov		lpword2,esi
		mov		len2,ecx
		lea		esi,[esi+ecx]
		invoke IsIgnore,IGNORE_PTR,len2,lpword2
		.if eax
			inc		fPtr
			jmp		NxtWordProc
		.endif
		invoke WhatIsIt,lpword1,len1,lpword2,len2
		.if eax
			movzx	edx,[eax].DEFTYPE.nDefType
			.if edx==DEFTYPE_ENDPROC
				.if byte ptr [edi-1]==','
					dec		edi
				.endif
				mov		byte ptr [edi],0
				xor		eax,eax
				inc		eax
				retn
			.elseif edx==DEFTYPE_LOCALDATA
				movzx	edx,[eax].DEFTYPE.nDefType
				movzx	eax,[eax].DEFTYPE.nType
				call	ParseParamData
				mov		byte ptr [edi],','
				inc		edi
			.elseif edx==DEFTYPE_DATA
				push	eax
				invoke IsIgnore,IGNORE_DATATYPEINIT,len2,lpword2
				.if eax
					pop		eax
					invoke GetWord,esi,addr npos
					mov		esi,edx
					mov		lpdatatype,esi
					mov		lendatatype,ecx
					lea		esi,[esi+ecx]
					jmp		NxtWordProc
				.endif
				pop		eax
				movzx	edx,[eax].DEFTYPE.nDefType
				movzx	eax,[eax].DEFTYPE.nType
				call	ParseParamData
				mov		byte ptr [edi],','
				inc		edi
				call	SkipToComma
				.if byte ptr [esi]==','
					inc		esi
					jmp		NxtWordProc
				.endif
				mov		lpdatatype,0
			.elseif edx==DEFTYPE_WITHBLOCK
				push	eax
				push	edi
				movzx	eax,[eax].DEFTYPE.nType
				call	ParseWithBlock
				pop		edi
				pop		edx
				.if eax
					movzx	ecx,[edx].DEFTYPE.Def
					mov		eax,rpwithblock[8]
					mov		rpwithblock[12],eax
					mov		eax,rpwithblock[4]
					mov		rpwithblock[8],eax
					mov		eax,rpwithblock[0]
					mov		rpwithblock[4],eax
					mov		eax,[ebx].RAPROPERTY.rpfree
					mov		rpwithblock,eax
					invoke AddWordToWordList,ecx,nOwner,npos,-1,edi,1
				.endif
			.elseif edx==DEFTYPE_ENDWITHBLOCK
				.if rpwithblock!=-1
					mov		edx,[ebx].RAPROPERTY.lpmem
					add		edx,rpwithblock
					mov		eax,npos
					mov		[edx].PROPERTIES.nEnd,eax
					mov		eax,rpwithblock[4]
					mov		rpwithblock[0],eax
					mov		eax,rpwithblock[8]
					mov		rpwithblock[4],eax
					mov		eax,rpwithblock[12]
					mov		rpwithblock[8],eax
					mov		rpwithblock[12],-1
				.endif
			.endif
		.endif
	.elseif byte ptr [esi]=='*'
		inc		esi
		invoke GetWord,esi,addr npos
		mov		esi,edx
		lea		esi,[esi+ecx]
		jmp		NxtWordProc
	.endif
	xor		eax,eax
	retn

SaveParam:
	invoke GetWord,esi,addr npos
	mov		esi,edx
	.if !ecx
		.if byte ptr [esi]==',' || byte ptr [esi]=='('
			inc		esi
			jmp		SaveParam
		.elseif byte ptr [esi]==')'
			mov		byte ptr [edi],0
			inc		edi
			jmp		RetType
		.endif
	.else
		invoke IsIgnore,IGNORE_PROCPARAM,ecx,esi
		.if eax
			lea		esi,[esi+ecx]
			jmp		SaveParam
		.endif
		mov		lpword1,esi
		mov		len1,ecx
		lea		esi,[esi+ecx]
		mov		eax,TYPE_NAMEFIRST
		call	ParseParamData
		mov		byte ptr [edi],','
		inc		edi
		call	SkipSpc
		.if byte ptr [esi]==')'
		  RetType:
			inc		esi
			invoke GetWord,esi,addr npos
			mov		esi,edx
			.if ecx
				invoke IsIgnore,IGNORE_DATATYPEINIT,ecx,esi
				.if eax
					lea		esi,[esi+ecx]
				.endif
				invoke GetWord,esi,addr npos
				mov		esi,edx
				.if ecx
					dec		edi
					mov		word ptr [edi],0
					inc		edi
					mov		edx,edi
					lea		edi,[edi+ecx]
					mov		eax,esi
					lea		esi,[esi+ecx]
					inc		ecx
					invoke lstrcpyn,edx,eax,ecx
					inc		fRetType
				  @@:
					invoke GetWord,esi,addr npos
					mov		esi,edx
					invoke IsIgnore,IGNORE_PTR,ecx,esi
					.if eax
						lea		esi,[esi+ecx]
						invoke lstrcpyn,edi,addr szPtr,5
						lea		edi,[edi+4]
						jmp		@b
					.endif
				.endif
			.endif
		.else
			call	SkipToComma
			.if byte ptr [esi]==','
				inc		esi
				jmp		SaveParam
			.endif
		.endif
	.endif
	.if byte ptr [edi-1]==','
		dec		edi
	.endif
	.if !fRetType
		mov		word ptr [edi],0
		inc		edi
	.endif
	mov		word ptr [edi],0
	inc		edi
	retn

ParseData:
	call	AddNamespace
	call	SaveName
ParseData1:
	call	SkipBrace
	invoke GetWord,esi,addr npos
	mov		esi,edx
	invoke IsIgnore,IGNORE_DATATYPEINIT,ecx,esi
	.if eax
		mov		fPtr,0
		lea		esi,[esi+ecx]
		invoke GetWord,esi,addr npos
		mov		esi,edx
		mov		lpdatatype,esi
		mov		lendatatype,ecx
		lea		esi,[esi+ecx]
	  @@:
		invoke GetWord,esi,addr npos
		mov		esi,edx
		invoke IsIgnore,IGNORE_PTR,ecx,esi
		.if eax
			lea		esi,[esi+ecx]
			inc		fPtr
			jmp		@b
		.endif
	.endif
	.if lpdatatype
		mov		eax,lendatatype
		inc		eax
		invoke lstrcpyn,edi,lpdatatype,eax
		add		edi,lendatatype
		.if fPtr
			push	fPtr
		  @@:
			invoke lstrcpyn,edi,addr szPtr,5
			lea		edi,[edi+4]
			dec		fPtr
			jne		@b
			pop		fPtr
		.endif
	.else
		invoke lstrcpy,edi,addr szInteger
		lea		edi,[edi+sizeof szInteger]
	.endif
	mov		byte ptr [edi],0
	xor		eax,eax
	inc		eax
	retn

ParseParamData:
	call	SaveName
	dec		edi
ParseParamData1:
	invoke GetWord,esi,addr npos
	mov		esi,edx
	.if !ecx
		.if byte ptr [esi]=='('
			call	SkipBrace
			jmp		ParseParamData1
		.endif
	.endif
	invoke IsIgnore,IGNORE_DATATYPEINIT,ecx,esi
	.if eax
		lea		esi,[esi+ecx]
		invoke GetWord,esi,addr npos
		mov		esi,edx
		mov		lpdatatype,esi
		mov		lendatatype,ecx
		lea		esi,[esi+ecx]
	  @@:
		invoke GetWord,esi,addr npos
		mov		esi,edx
		invoke IsIgnore,IGNORE_PTR,ecx,esi
		.if eax
			lea		esi,[esi+ecx]
			inc		fPtr
			jmp		@b
		.endif
	.endif
	.if lpdatatype
		mov		byte ptr [edi],':'
		inc		edi
		mov		edx,edi
		mov		eax,lendatatype
		lea		edi,[edi+eax]
		inc		eax
		invoke lstrcpyn,edx,lpdatatype,eax
	.else
		mov		byte ptr [edi],':'
		inc		edi
		invoke lstrcpy,edi,addr szInteger
		lea		edi,[edi+sizeof szInteger-1]
	.endif
	.if fPtr
	  @@:
		invoke lstrcpyn,edi,addr szPtr,5
		lea		edi,[edi+4]
		dec		fPtr
		jne		@b
	.endif
	mov		byte ptr [edi],0
	xor		eax,eax
	inc		eax
	retn

ParseConst:
	call	AddNamespace
	call	SaveName
	mov		byte ptr [edi],0
	xor		eax,eax
	inc		eax
	retn

ParseStruct:
	mov		nNest,1
	call	AddNamespace
	call	SaveName
	invoke GetWord,esi,addr npos
	mov		esi,edx
	.if ecx
		invoke IsIgnore,IGNORE_STRUCTTHIRDWORD,ecx,esi
		.if eax
			xor		eax,eax
			retn
		.endif
	.endif
	mov		byte ptr [edi],0
	.while byte ptr [esi]
		invoke SkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
	  ParseStruct1:
		invoke GetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			invoke IsIgnore,IGNORE_STRUCTITEMFIRSTWORD,ecx,esi
			.if eax
				; As Integer x
				lea		esi,[esi+ecx]
				invoke GetWord,esi,addr npos
				mov		esi,edx
				mov		lpword2,esi
				mov		len2,ecx
				lea		esi,[esi+ecx]
			  @@:
				invoke GetWord,esi,addr npos
				mov		esi,edx
				.if !ecx
					.if byte ptr [esi]=='*'
						inc		esi
						invoke GetWord,esi,addr npos
						mov		esi,edx
						lea		esi,[esi+ecx]
						jmp		@b
					.endif
				.endif
				invoke IsIgnore,IGNORE_PTR,ecx,esi
				.if eax
					; ptr
					inc		fPtr
					lea		esi,[esi+ecx]
					jmp		@b
				.endif
				mov		lpword1,esi
				mov		len1,ecx
				lea		esi,[esi+ecx]
				jmp		ParseStruct3
			.endif
			invoke IsIgnore,IGNORE_STRUCTITEMINIT,ecx,esi
			.if eax
				; Declare MySub 
				lea		esi,[esi+ecx]
				invoke GetWord,esi,addr npos
				mov		esi,edx
				mov		lpword2,esi
				mov		len2,ecx
				lea		esi,[esi+ecx]
				invoke GetWord,esi,addr npos
				mov		esi,edx
				mov		lpword1,esi
				xor		ecx,ecx
				.while byte ptr [esi]!=VK_SPACE && byte ptr [esi]!=VK_TAB && byte ptr [esi]!=VK_RETURN && byte ptr [esi]!='('
					inc		esi
					inc		ecx
				.endw
				mov		len1,ecx
				jmp		ParseStruct3
			.else
				mov		lpword1,esi
				mov		len1,ecx
				lea		esi,[esi+ecx]
			.endif
		  ParseStruct2:
			invoke GetWord,esi,addr npos
			mov		esi,edx
			.if byte ptr [esi]=='('
				; MyItem(0 To 7) As Integer
				.while byte ptr [esi] && byte ptr [esi]!=0Dh && byte ptr [esi]!=')'
					inc		esi
				.endw
				.if byte ptr [esi]==')'
					inc		esi
				.endif
				jmp		ParseStruct2
			.endif
			.if ecx
				invoke IsIgnore,IGNORE_STRUCTITEMSECONDWORD,ecx,esi
				.if eax
					; As Integer
					lea		esi,[esi+ecx]
					invoke GetWord,esi,addr npos
					mov		esi,edx
					mov		lpword2,esi
					mov		len2,ecx
					lea		esi,[esi+ecx]
				  @@:
					invoke GetWord,esi,addr npos
					mov		esi,edx
					invoke IsIgnore,IGNORE_PTR,ecx,esi
					.if eax
						; ptr
						inc		fPtr
						lea		esi,[esi+ecx]
						jmp		@b
					.endif
					jmp		ParseStruct3
				.endif
			.endif
			mov		lpword2,esi
			mov		len2,ecx
			lea		esi,[esi+ecx]
			invoke WhatIsIt,lpword1,len1,lpword2,len2
			.if eax
				movzx	eax,[eax].DEFTYPE.nDefType
				.if eax==DEFTYPE_ENDSTRUCT
					dec		nNest
					.if ZERO?
						mov		byte ptr [edi],0
						retn
					.endif
				.elseif eax==DEFTYPE_STRUCT
					inc		nNest
				.endif
			.else
	  		  ParseStruct3:
				.if byte ptr [edi]==','
					inc		edi
				.endif
				mov		eax,len1
				inc		eax
				invoke lstrcpyn,edi,lpword1,eax
				add		edi,len1
				mov		word ptr [edi],':'
				inc		edi
				mov		eax,len2
				inc		eax
				invoke lstrcpyn,edi,lpword2,eax
				add		edi,len2
				.if fPtr
				  @@:
					invoke lstrcpyn,edi,addr szPtr,5
					lea		edi,[edi+4]
					dec		fPtr
					jne		@b
				.endif
				mov		word ptr [edi],','
				call	SkipToComma
				.if byte ptr [esi]==','
					inc		esi
					invoke GetWord,esi,addr npos
					mov		esi,edx
					.if ecx
						mov		lpword1,esi
						mov		len1,ecx
						lea		esi,[esi+ecx]
						jmp		ParseStruct3
					.endif
				.endif
			.endif
		.endif
	.endw
	xor		eax,eax
	retn

ParseFile endp
