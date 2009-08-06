
.const

szMComment			db 'comment',0
szMString			db '"',"'",0,0

.code

MDestroyString proc lpMem:DWORD

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

MDestroyString endp

MDestroyCmntBlock proc uses esi,lpMem:DWORD

	mov		esi,lpMem
  @@:
	invoke SearchMemDown,esi,addr szMComment,FALSE,TRUE,[ebx].RAPROPERTY.lpchartab
	.if eax
		mov		esi,eax
		.while eax>lpMem
			.break .if byte ptr [eax-1]==VK_RETURN || byte ptr [eax-1]==0Ah
			dec		eax
		.endw
		mov		ecx,dword ptr szMString
		mov		edx,';'
		.while eax<esi
			.if byte ptr [eax]==cl || byte ptr [eax]==ch
				;String
				invoke MDestroyString,eax
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

MDestroyCmntBlock endp

MDestroyCommentsStrings proc uses esi,lpMem:DWORD

	mov		esi,lpMem
	mov		ecx,';'
	mov		edx,dword ptr szMString
	.while byte ptr [esi]
		.if byte ptr [esi]==cl
			invoke DestroyToEol,esi
			mov		esi,eax
		.elseif byte ptr [esi]==dl || byte ptr [esi]==dh
			invoke MDestroyString,esi
			mov		esi,eax
			mov		ecx,';'
			mov		edx,dword ptr szMString
		.elseif byte ptr [esi]==VK_TAB
			mov		byte ptr [esi],VK_SPACE
		.else
			inc		esi
		.endif
	.endw
	ret

MDestroyCommentsStrings endp

MPreParse proc uses esi,lpMem:DWORD

	invoke MDestroyCmntBlock,lpMem
	invoke MDestroyCommentsStrings,lpMem
	ret

MPreParse endp

MSkipLine proc uses esi,lpMem:DWORD,lpnpos:DWORD

	mov		eax,lpMem
	mov 	ecx,'\'
	mov		esi,[ebx].RAPROPERTY.lpchartab
	.while byte ptr [eax] && byte ptr [eax]!=VK_RETURN
		.if cl==byte ptr [eax]
			inc		eax
			.while byte ptr [eax]==VK_SPACE
				inc		eax
			.endw
			.if byte ptr [eax]==VK_RETURN
				mov		edx,lpnpos
				inc		dword ptr [edx]
				.if byte ptr [eax+1]==0Ah
					inc		eax
				.endif
			.endif
		.endif
		inc		eax
	.endw
	.if byte ptr [eax]==VK_RETURN
		inc		eax
	.endif
	.if byte ptr [eax]==0Ah
		inc		eax
	.endif
	ret

MSkipLine endp

MGetWord proc uses esi,lpMem:DWORD,lpnpos:DWORD

	mov		edx,lpMem
	mov		ecx,'\'
	mov		esi,[ebx].RAPROPERTY.lpchartab
	.while byte ptr [edx]==VK_SPACE || (cl==byte ptr [edx] && (byte ptr [edx+1]==VK_RETURN || byte ptr [edx+1]==VK_SPACE))
		.if cl==byte ptr [edx]
			.while byte ptr [edx+1]==VK_SPACE
				inc		edx
			.endw
			.break .if byte ptr [edx+1]!=VK_RETURN
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
  @@:
	movzx	eax,byte ptr [edx+ecx]
	.if byte ptr [esi+eax]==CT_CHAR || eax=='.'
		inc		ecx
		jmp		@b
	.endif
	ret

MGetWord endp

MGetWordSkip proc uses esi,lpMem:DWORD,lpnpos:DWORD

	mov		edx,lpMem
	mov		ecx,'\'
	.while byte ptr [edx]==VK_SPACE || (cl==byte ptr [edx] && (byte ptr [edx+1]==VK_RETURN || byte ptr [edx+1]==VK_SPACE))
		.if cl==byte ptr [edx]
			.while byte ptr [edx+1]==VK_SPACE
				inc		edx
			.endw
			.break .if byte ptr [edx+1]!=VK_RETURN
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
	.elseif eax=='('
		.while byte ptr [edx+ecx] && byte ptr [edx+ecx]!=VK_RETURN && byte ptr [edx+ecx]!=')'
			inc		ecx
		.endw
		.if byte ptr [edx+ecx]==')'
			inc		ecx
		.endif
		jmp		@b
	.endif
	ret

MGetWordSkip endp

MWhatIsIt proc uses esi,lpWord1:DWORD,len1:DWORD,lpWord2:DWORD,len2:DWORD

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
;		.elseif eax==TYPE_TWOWORDS
;			.if ecx==len1
;				invoke Compare,lpWord1,addr [esi].DEFTYPE.szWord,ecx
;				or		eax,eax
;				.if ZERO?
;					mov		eax,ecx
;					movzx	ecx,[esi+eax].DEFTYPE.szWord
;					.if ecx==len2
;						invoke Compare,lpWord2,addr [esi+eax+1].DEFTYPE.szWord,ecx
;						or		eax,eax
;						je		Ex
;					.endif
;				.endif
;			.endif
;		.elseif eax==TYPE_ONEWORD
;			.if ecx==len1
;				invoke Compare,lpWord1,addr [esi].DEFTYPE.szWord,ecx
;				or		eax,eax
;				je		Ex
;			.endif
		.endif
		add		esi,sizeof DEFTYPE
		jmp		@b
	.endif
	ret
  Ex:
	mov		eax,esi
	ret

MWhatIsIt endp

MIsIgnore proc uses ecx esi,nType:DWORD,len:DWORD,lpWord:DWORD

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

MIsIgnore endp

MIsWord proc uses ecx esi,nType:DWORD,len:DWORD,lpWord:DWORD

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

MIsWord endp

MFixUnknown proc uses ebx esi edi

	mov		esi,[ebx].RAPROPERTY.lpmem
	.if esi
		add		esi,[ebx].RAPROPERTY.rpproject
		.while [esi].PROPERTIES.nSize
			.if [esi].PROPERTIES.nType=='U'
				mov		edi,[ebx].RAPROPERTY.lpmem
				.while [edi].PROPERTIES.nSize
					movzx	eax,[edi].PROPERTIES.nType
					.if eax=='S' || eax=='T' || eax=='s'
						call	CompareIt
						.if !eax
							mov		[esi].PROPERTIES.nType,'d'
							.break
						.endif
					.endif
					mov		eax,[edi].PROPERTIES.nSize
					lea		edi,[edi+eax+sizeof PROPERTIES]
				.endw
			.endif
			mov		eax,[esi].PROPERTIES.nSize
			lea		esi,[esi+eax+sizeof PROPERTIES]
		.endw
	.endif
	ret

CompareIt:
	lea		ecx,[esi+sizeof PROPERTIES]
	lea		edx,[edi+sizeof PROPERTIES]
	.while byte ptr [ecx]
		inc		ecx
	.endw
	inc		ecx
	xor		eax,eax
	.while TRUE
		mov		al,[ecx]
		mov		ah,[edx]
		.break .if !al || !ah
		sub		al,ah
		.break .if al
		inc		ecx
		inc		edx
	.endw
	retn

MFixUnknown endp

MParseFile proc uses ebx esi edi,nOwner:DWORD,lpMem:DWORD
	LOCAL	lpword1:DWORD
	LOCAL	len1:DWORD
	LOCAL	lpword2:DWORD
	LOCAL	len2:DWORD
	LOCAL	lpdef:DWORD
	LOCAL	npos:DWORD
	LOCAL	nline:DWORD
	LOCAL	lpdatatype:DWORD
	LOCAL	lendatatype:DWORD
	LOCAL	lpdatatype2:DWORD
	LOCAL	lendatatype2:DWORD
	LOCAL	nNest:DWORD
	LOCAL	fPtr:DWORD
	LOCAL	fParam:DWORD
	LOCAL	endtype:DWORD
	LOCAL	narray:DWORD

	mov		npos,0
	mov		esi,lpMem
	.while byte ptr [esi]
		mov		eax,npos
		mov		nline,eax
		mov		fPtr,0
		mov		fParam,0
		mov		lpdatatype,0
		mov		lpdatatype2,0
	  Nxtwrd:
		invoke MGetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			invoke MIsIgnore,IGNORE_LINEFIRSTWORD,ecx,esi
			.if eax
				jmp		Nxt
			.endif
			mov		lpword1,esi
			mov		len1,ecx
			lea		esi,[esi+ecx]
			mov		lpdatatype,0
			mov		lpdatatype2,0
			mov		fPtr,0
			invoke MGetWord,esi,addr npos
			mov		esi,edx
			.if byte ptr [esi]==':'
				inc		ecx
			.endif
			mov		lpword2,esi
			mov		len2,ecx
			lea		esi,[esi+ecx]
			invoke MWhatIsIt,lpword1,len1,lpword2,len2
			.if eax
				mov		lpdef,eax
				movzx	edx,[eax].DEFTYPE.nDefType
				movzx	eax,[eax].DEFTYPE.nType
				mov		edi,offset szname
				.if edx==DEFTYPE_PROC
					mov		endtype,DEFTYPE_ENDPROC
					call	ParseProc
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,4
					.endif
				.elseif edx==DEFTYPE_LABEL
					call	ParseLabel
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,1
					.endif
				.elseif edx==DEFTYPE_MACRO
					call	ParseMacro
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
					.endif
				.elseif edx==DEFTYPE_DATA
					call	ParseData
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
					.endif
				.elseif edx==DEFTYPE_CONST
					call	ParseConst
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
					.endif
				.elseif edx==DEFTYPE_STRUCT
					call	ParseStruct
					.if eax
						mov		edx,lpdef
						movzx	edx,[edx].DEFTYPE.Def
						invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
					.endif
				.elseif edx==DEFTYPE_TYPE
				.endif
			.else
				mov		edi,offset szname
				call	ParseUnknown
				.if eax
					mov		edx,'U'
					invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
				.endif
			.endif
		.endif
	  Nxt:
		invoke SkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
	.endw
	invoke MFixUnknown
	ret

SaveName:
	mov		edx,edi
	.if eax==TYPE_NAMEFIRST
		mov		eax,len1
		inc		eax
		lea		edi,[edx+eax]
		invoke strcpyn,edx,lpword1,eax
	.elseif eax==TYPE_NAMESECOND || eax==TYPE_OPTNAMESECOND
		mov		eax,len2
		inc		eax
		lea		edi,[edx+eax]
		invoke strcpyn,edx,lpword2,eax
	.endif
	retn

SkipBrace:
	xor		eax,eax
	dec		eax
SkipBrace1:
	.while byte ptr [esi]==VK_SPACE
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
	.elseif al=='<'
		push	eax
		mov		ah,'>'
		jmp		SkipBrace1
	.elseif al=='"'
		push	eax
		mov		ah,'"'
		jmp		SkipBrace1
	.elseif al=="'"
		push	eax
		mov		ah,"'"
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
	.while byte ptr [esi]==VK_SPACE
		inc		esi
	.endw
	.while byte ptr [esi] && byte ptr [esi]!=VK_RETURN && byte ptr [esi]!=','
		call	SkipBrace
		.if byte ptr [esi] && byte ptr [esi]!=VK_RETURN && byte ptr [esi]!=','
			inc		esi
		.endif
	.endw
	retn

SkipSpc:
	.while byte ptr [esi]==VK_SPACE
		inc		esi
	.endw
	retn

ConvDataType:
	push	esi
	mov		esi,offset szMasmDataConv
	.if lendatatype==2
		.while byte ptr [esi]
			invoke strcmpin,esi,lpdatatype,2
			.if !eax
				lea		esi,[esi+3]
				mov		lpdatatype,esi
				invoke strlen,esi
				mov		lendatatype,eax
				jmp		ExConvDataType
			.endif
			invoke strlen,esi
			lea		esi,[esi+eax+1]
			invoke strlen,esi
			lea		esi,[esi+eax+1]
		.endw
	.elseif lendatatype==4 || lendatatype==5 || lendatatype==6
		.while byte ptr [esi]
			lea		esi,[esi+3]
			invoke strcmpin,esi,lpdatatype,lendatatype
			.if !eax
				mov		lpdatatype,esi
				jmp		ExConvDataType
			.endif
			invoke strlen,esi
			lea		esi,[esi+eax+1]
		.endw
	.endif
  ExConvDataType:
	pop		esi
	retn

ArraySize:
	call	SkipSpc
	push		ebx
	mov		ebx,offset szname[16384]
	mov		word ptr [ebx-1],0
	mov		word ptr szname[8192-1],0
	mov		narray,0
	.while TRUE
		mov		al,[esi]
		.if al=='"' || al=="'"
			inc		esi
			.while al!=[esi] && byte ptr [esi]!=VK_RETURN && byte ptr [esi]
				inc		esi
				inc		narray
			.endw
			.if al==[esi]
				inc		esi
			.endif
			mov		al,[esi]
		.elseif al=='<'
			call	SkipBrace
			inc		narray
		.endif
		mov		ah,[ebx-1]
		.if al==' ' || al=='+' || al=='-' || al=='*' || al=='/' || al=='(' || al==')' || al==','
			.if ah==' ' || (al==',' && ah==',')
				dec		ebx
			.endif
		.endif
		.if al==' '
			.if ah=='+' || ah=='-' || ah=='*' || ah=='/' || ah=='(' || ah==')' || ah==','
				mov		al,ah
				dec		ebx
			.endif
		.endif
		.if al=='d' || al=='D'
			.if byte ptr [esi+1]=='u' || byte ptr [esi+1]=='U'
				.if byte ptr [esi+2]=='p' || byte ptr [esi+2]=='P'
					.if byte ptr [esi+3]==' ' || byte ptr [esi+3]=='('
						add		esi,3
						call	SkipSpc
						.if byte ptr [esi]=='('
							call	SkipBrace
						.endif
						call	SkipSpc
						.if byte ptr szname[8192]
							invoke strcat,offset szname[8192],offset szAdd
						.endif
						mov		byte ptr [ebx-1],0
						invoke strcat,offset szname[8192],offset szname[16384]
						mov		al,[esi]
					.endif
				.endif
			.endif
		.endif
		.if al==',' || al==VK_RETURN || !al
			.if byte ptr [ebx-1]
				inc		narray
			.endif
			mov		ebx,offset szname[16384]
			mov		byte ptr [ebx],0
		  .break .if al==VK_RETURN || !al
		.else
			mov		[ebx],al
			inc		ebx
		.endif
		inc		esi
	.endw
	mov		byte ptr [ebx],0
	pop		ebx
	.if narray>1 || (byte ptr szname[8192] && narray)
		.if byte ptr szname[8192]
			invoke strcat,addr szname[8192],addr szAdd
		.endif
		invoke DwToAscii,narray,addr szname[16384+1024]
		invoke strcat,addr szname[8192],addr szname[16384+1024]
	.endif
	retn

ParseMacro:
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
		invoke strcpyn,edx,lpword1,eax
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
		invoke MSkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
		invoke MGetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			mov		lpword1,esi
			mov		len1,ecx
			mov		lpword2,esi
			mov		len2,ecx
			lea		esi,[esi+ecx]
			invoke MWhatIsIt,lpword1,len1,lpword2,len2
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

ParseUnknown:
	mov		szname,0
	.if len1 && len2
		invoke MGetWord,esi,addr npos
		mov		esi,edx
		xor		eax,eax
		.if byte ptr [esi] && byte ptr [esi]!=VK_RETURN
			mov		eax,TYPE_NAMEFIRST
			call	SaveName
			call	ArraySize
			.if byte ptr szname[8192]
				mov		byte ptr [edi-1],'['
				invoke strcpy,edi,addr szname[8192]
				invoke strlen,edi
				lea		edi,[edi+eax]
				mov		byte ptr [edi],']'
				inc		edi
				mov		byte ptr [edi],0
				inc		edi
			.endif
			mov		byte ptr [edi-1],':'
			mov		eax,TYPE_NAMESECOND
			call	SaveName
			mov		eax,TYPE_NAMESECOND
			call	SaveName
			mov		eax,TRUE
		.endif
	.else
		xor		eax,eax
	.endif
	retn

ParseLabel:
	call	SaveName
	xor		eax,eax
	inc		eax
	retn

ParseProc:
	call	SaveName
	call	SaveParam
	; Return type
	mov		byte ptr [edi],0
	inc		edi
	call	SaveLocal
	retn

NxtWordProc:
	invoke MGetWord,esi,addr npos
	mov		esi,edx
	.if ecx
		mov		lpword2,esi
		mov		len2,ecx
		lea		esi,[esi+ecx]
		invoke MIsIgnore,IGNORE_PTR,len2,lpword2
		.if eax
			inc		fPtr
			jmp		NxtWordProc
		.endif
		invoke MWhatIsIt,lpword1,len1,lpword2,len2
		.if eax
			movzx	edx,[eax].DEFTYPE.nDefType
			.if edx==endtype
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
			.endif
		.endif
	.endif
	xor		eax,eax
	retn

SaveParam:
	invoke MGetWord,esi,addr npos
	mov		esi,edx
	.if ecx
		invoke MIsIgnore,IGNORE_PROCPARAM,ecx,esi
		.if eax
			lea		esi,[esi+ecx]
			jmp		SaveParam
		.endif
	.endif
SaveParam1:
	invoke MGetWord,esi,addr npos
	mov		esi,edx
	.if !ecx
		.if byte ptr [esi]==','
			inc		esi
			jmp		SaveParam1
		.elseif byte ptr [esi]!=VK_RETURN
			inc		esi
			jmp		SaveParam1
		.endif
	.else
		invoke MIsIgnore,IGNORE_PROCPARAM,ecx,esi
		.if eax
			lea		esi,[esi+ecx]
			jmp		SaveParam1
		.endif
		mov		lpword1,esi
		mov		len1,ecx
		lea		esi,[esi+ecx]
		mov		eax,TYPE_NAMEFIRST
		call	ParseParamData
		mov		byte ptr [edi],','
		inc		edi
		call	SkipSpc
		call	SkipToComma
		.if byte ptr [esi]==','
			inc		esi
			jmp		SaveParam1
		.endif
	.endif
	.if byte ptr [edi-1]==','
		dec		edi
	.endif
	mov		dword ptr [edi],0
	inc		edi
	retn

SaveLocal:
	.while byte ptr [esi]
		mov		fPtr,0
		invoke MSkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
		invoke MGetWord,esi,addr npos
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

ParseParamData:
	call	SaveName
	dec		edi
ParseParamData1:
	invoke MGetWord,esi,addr npos
	mov		esi,edx
	.if !ecx
		.if byte ptr [esi]=='['
			push	esi
			.while byte ptr [esi] && byte ptr [esi-1]!=']'
				mov		al,[esi]
				.if al!=VK_SPACE
					mov		[edi],al
					inc		edi
				.elseif byte ptr [edi-1]!=VK_SPACE
					mov		[edi],al
					inc		edi
				.endif
				inc		esi
			.endw
			pop		esi
			call	SkipBrace
			jmp		ParseParamData1
		.elseif byte ptr [esi]==':'
			inc		esi
		.endif
	.endif
  @@:
	lea		esi,[esi+ecx]
	invoke MGetWord,esi,addr npos
	mov		esi,edx
	invoke MIsIgnore,IGNORE_PTR,ecx,esi
	.if eax
		push	ecx
		.if !fPtr
			mov		byte ptr [edi],':'
			inc		edi
		.endif
		invoke strcpy,edi,addr szMasmPtr
		lea		edi,[edi+sizeof szMasmPtr-1]
		inc		fPtr
		pop		ecx
		jmp		@b
	.endif
	mov		lpdatatype,esi
	mov		lendatatype,ecx
	lea		esi,[esi+ecx]
  @@:
	invoke MGetWord,esi,addr npos
	mov		esi,edx
	invoke MIsIgnore,IGNORE_PTR,ecx,esi
	.if eax
		lea		esi,[esi+ecx]
		invoke strcpy,edi,addr szPtr
		lea		edi,[edi+sizeof szPtr-1]
	.endif
	.if lpdatatype
		.if !fPtr
			mov		byte ptr [edi],':'
			inc		edi
		.endif
		call	ConvDataType
		mov		edx,edi
		mov		eax,lendatatype
		lea		edi,[edi+eax]
		inc		eax
		invoke strcpyn,edx,lpdatatype,eax
		.if lpdatatype2
			mov		byte ptr [edi],'['
			inc		edi
			mov		edx,edi
			mov		eax,lendatatype2
			lea		edi,[edi+eax]
			inc		eax
			invoke strcpyn,edx,lpdatatype2,eax
			mov		byte ptr [edi],']'
			inc		edi
			mov		lpdatatype2,0
		.endif
	.else
		.if !fPtr
			mov		byte ptr [edi],':'
			inc		edi
		.endif
		invoke strcpy,edi,addr szDword
		lea		edi,[edi+sizeof szDword-1]
	.endif
	mov		fPtr,0
	mov		byte ptr [edi],0
	xor		eax,eax
	inc		eax
	retn

ParseData:
	call	SaveName
ParseData1:
	mov		eax,lpword2
	mov		lpdatatype,eax
	mov		eax,len2
	mov		lendatatype,eax
	; Check for mov	dword ptr [eax],1
	invoke MGetWord,esi,addr npos
	mov		esi,edx
	invoke MIsIgnore,IGNORE_PTR,ecx,esi
	.if eax
		xor		eax,eax
		retn
	.endif
	call	ConvDataType
	call	ArraySize
	.if byte ptr szname[8192]
		mov		byte ptr [edi-1],'['
		invoke strcpy,edi,addr szname[8192]
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		byte ptr [edi],']'
		inc		edi
		mov		byte ptr [edi],0
		inc		edi
	.endif
	.if lpdatatype
		mov		byte ptr [edi-1],':'
		mov		eax,lendatatype
		inc		eax
		invoke strcpyn,edi,lpdatatype,eax
		add		edi,lendatatype
		mov		byte ptr [edi],0
		inc		edi
		mov		eax,lendatatype
		inc		eax
		invoke strcpyn,edi,lpdatatype,eax
		add		edi,lendatatype
	.else
		dec		edi
		invoke strcpy,edi,addr szDword
		lea		edi,[edi+sizeof szDword]
		mov		byte ptr [edi],0
		inc		edi
		invoke strcpy,edi,addr szDword
		lea		edi,[edi+sizeof szDword]
	.endif
	mov		byte ptr [edi],0
	xor		eax,eax
	inc		eax
	retn

ParseConst:
	call	SaveName
	invoke MGetWord,esi,addr npos
	mov		esi,edx
	.if ecx
		.while TRUE
			mov		al,[esi]
			.if !al || al==VK_RETURN
				.break
			.endif
			mov		ah,[edi-1]
			.if al==' ' || al=='+' || al=='-' || al=='*' || al=='/' || al=='(' || al==')'
				.if ah==' '
					dec		edi
				.endif
			.endif
			.if al==' '
				.if ah=='+' || ah=='-' || ah=='*' || ah=='/' || ah=='(' || ah==')'
					mov		al,ah
					dec		edi
				.endif
			.endif
			mov		[edi],al
			inc		edi
			inc		esi
		.endw
	.endif
	.if byte ptr [edi-1]==' '
		dec		edi
	.endif
	mov		byte ptr [edi],0
	xor		eax,eax
	inc		eax
	retn

ParseStruct:
	mov		byte ptr szstructnest,0
	mov		nNest,1
	call	SaveName
	mov		byte ptr [edi],0
	.while byte ptr [esi]
		invoke MSkipLine,esi,addr npos
		inc		npos
		mov		esi,eax
	  ParseStruct1:
		invoke MGetWord,esi,addr npos
		mov		esi,edx
		.if ecx
			mov		lpword1,esi
			mov		len1,ecx
			lea		esi,[esi+ecx]
		  ParseStruct2:
			invoke MGetWord,esi,addr npos
			mov		esi,edx
			mov		lpword2,esi
			mov		len2,ecx
			lea		esi,[esi+ecx]
			invoke MWhatIsIt,lpword1,len1,lpword2,len2
			.if eax
				movzx	eax,[eax].DEFTYPE.nDefType
				.if eax==DEFTYPE_ENDSTRUCT
					mov		byte ptr szstructnest,0
					dec		nNest
					.if ZERO?
						mov		byte ptr [edi],0
						retn
					.endif
				.elseif eax==DEFTYPE_STRUCT
					.if len2!=0
						mov		eax,len2
						inc		eax
						invoke strcpyn,offset szstructnest,lpword2,eax
						invoke strcat,offset szstructnest,offset szDot
					.else
						mov		byte ptr szstructnest,0
					.endif
					inc		nNest
				.elseif eax==DEFTYPE_DATA
					jmp		ParseStruct3
				.endif
			.else
	  		  ParseStruct3:
				.if byte ptr [edi]==','
					inc		edi
				.endif
				.if byte ptr szstructnest
					invoke strcpy,edi,offset szstructnest
					invoke strlen,edi
					lea		edi,[edi+eax]
				.endif
				mov		eax,len1
				inc		eax
				invoke strcpyn,edi,lpword1,eax
				add		edi,len1

				call	ArraySize
				.if byte ptr szname[8192]
					mov		byte ptr [edi],'['
					inc		edi
					invoke strcpy,edi,addr szname[8192]
					invoke strlen,edi
					lea		edi,[edi+eax]
					mov		byte ptr [edi],']'
					inc		edi
				.endif

				mov		word ptr [edi],':'
				inc		edi
				mov		eax,lpword2
				mov		lpdatatype,eax
				mov		eax,len2
				mov		lendatatype,eax
				call	ConvDataType
				mov		edx,edi
				mov		eax,lendatatype
				lea		edi,[edi+eax]
				inc		eax
				invoke strcpyn,edx,lpdatatype,eax
				mov		word ptr [edi],','
			.endif
		.endif
	.endw
	xor		eax,eax
	retn

MParseFile endp
