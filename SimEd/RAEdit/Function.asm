
.code

FindTextDown proc uses ebx esi edi,hMem:DWORD,lpFind:DWORD,len:DWORD,fMC:DWORD,fWW:DWORD,cpMin:DWORD,cpMax:DWORD
	LOCAL	nLine:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,cpMin
	mov		nLine,edx
	mov		ecx,eax
	mov		edx,cpMin
	sub		edx,ecx
	.while edx<cpMax
		call	TstLn
		.break .if eax!=-1
		xor		ecx,ecx
		inc		nLine
	.endw
	ret

TstFind:
	mov		esi,lpFind
	dec		esi
	dec		ecx
  TstFind1:
	inc		esi
	inc		ecx
	mov		al,[esi]
	or		al,al
	je		TstFind2
	mov		ah,[edi+ecx+sizeof CHARS]
	cmp		al,ah
	je		TstFind1
	.if !fMC
		push	edx
		movzx	edx,al
		mov		al,CaseTab[edx]
		pop		edx
		cmp		al,ah
		je		TstFind1
	.endif
	xor		eax,eax
	dec		eax
  TstFind2:
	.if fWW && !al
		.if ecx<=[edi].CHARS.len
			movzx	eax,byte ptr [edi+ecx+sizeof CHARS]
			lea		eax,[eax+offset CharTab]
			mov		al,[eax]
			.if al==CT_CHAR
				xor		eax,eax
				dec		eax
			.else
				xor		eax,eax
			.endif
		.endif
	.endif
	or		al,al
	retn

TstLn:
	mov		edi,nLine
	shl		edi,2
	.if edi<[ebx].EDIT.rpLineFree
		add		edi,[ebx].EDIT.hLine
		mov		edi,[edi].LINE.rpChars
		add		edi,[ebx].EDIT.hChars
	  Nxt:
		mov		eax,len
		add		eax,ecx
		.if eax<=[edi].CHARS.len
			.if fWW && ecx
				movzx	eax,byte ptr [edi+ecx+sizeof CHARS-1]
				.if byte ptr CharTab[eax]==CT_CHAR
					inc		ecx
					jmp		Nxt
				.endif
			.endif
			push	ecx
			call	TstFind
			pop		ecx
			je		Ex
			inc		ecx
			jmp		Nxt
		.else
			mov		eax,-1
			add		edx,[edi].CHARS.len
		.endif
	.else
		mov		eax,-1
		mov		edx,-1
	.endif
	retn
  Ex:
	add		edx,ecx
	mov		eax,edx
	retn

FindTextDown endp

FindTextUp proc uses ebx esi edi,hMem:DWORD,lpFind:DWORD,len:DWORD,fMC:DWORD,fWW:DWORD,cpMin:DWORD,cpMax:DWORD
	LOCAL	nLine:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,cpMax
	mov		nLine,edx
	mov		edx,ecx
	mov		ecx,eax
	.while sdword ptr edx>=cpMin
		call	TstLn
		.break .if eax!=-1
		mov		ecx,eax
		dec		nLine
	.endw
	ret

TstFind:
	mov		esi,lpFind
	dec		esi
	dec		ecx
  TstFind1:
	inc		esi
	inc		ecx
	mov		al,[esi]
	or		al,al
	je		TstFind2
	mov		ah,[edi+ecx+sizeof CHARS]
	cmp		al,ah
	je		TstFind1
	.if !fMC
		push	edx
		movzx	edx,al
		mov		al,CaseTab[edx]
		pop		edx
		cmp		al,ah
		je		TstFind1
	.endif
	xor		eax,eax
	dec		eax
  TstFind2:
	.if fWW && !al
		.if ecx<=[edi].CHARS.len
			movzx	eax,byte ptr [edi+ecx+sizeof CHARS]
			mov		al,CharTab[eax]
			.if al==CT_CHAR
				xor		eax,eax
				dec		eax
			.else
				xor		eax,eax
			.endif
		.endif
	.endif
	or		al,al
	retn

TstLn:
	mov		edi,nLine
	shl		edi,2
	.if edi<[ebx].EDIT.rpLineFree
		add		edi,[ebx].EDIT.hLine
		mov		edi,[edi].LINE.rpChars
		add		edi,[ebx].EDIT.hChars
		.if ecx==-1
			mov		ecx,[edi].CHARS.len
		.endif
		sub		edx,ecx
		sub		ecx,len
	  Nxt:
		.if sdword ptr ecx>=0
			.if fWW && ecx
				movzx	eax,byte ptr [edi+ecx+sizeof CHARS-1]
				.if byte ptr CharTab[eax]==CT_CHAR
					dec		ecx
					jmp		Nxt
				.endif
			.endif
			push	ecx
			call	TstFind
			pop		ecx
			je		Ex
			dec		ecx
			jmp		Nxt
		.else
			mov		eax,-1
		.endif
	.else
		mov		eax,-1
		mov		edx,-1
	.endif
	retn
  Ex:
	mov		eax,edx
	add		eax,ecx
	retn

FindTextUp endp

FindTextEx proc uses ebx esi edi,hMem:DWORD,fFlag:DWORD,lpFindTextEx:DWORD
	LOCAL	lpText:DWORD
	LOCAL	len:DWORD
	LOCAL	fMC:DWORD
	LOCAL	fWW:DWORD

	mov		ebx,hMem
	mov		esi,lpFindTextEx
	mov		eax,[esi].FINDTEXTEX.lpstrText
	mov		lpText,eax
	invoke strlen,eax
	.if eax
		mov		len,eax
		xor		eax,eax
		mov		fMC,eax
		mov		fWW,eax
		test	fFlag,FR_WHOLEWORD
		.if !ZERO?
			inc		fWW
		.endif
		test	fFlag,FR_MATCHCASE
		.if !ZERO?
			inc		fMC
		.endif
		mov		eax,[esi].FINDTEXTEX.chrg.cpMin
		.if eax<[esi].FINDTEXTEX.chrg.cpMax
			;Down
			invoke FindTextDown,ebx,lpText,len,fMC,fWW,[esi].FINDTEXTEX.chrg.cpMin,[esi].FINDTEXTEX.chrg.cpMax
		.elseif eax>[esi].FINDTEXTEX.chrg.cpMax
			;Up
			invoke FindTextUp,ebx,lpText,len,fMC,fWW,[esi].FINDTEXTEX.chrg.cpMax,[esi].FINDTEXTEX.chrg.cpMin
		.else
			mov		eax,-1
		.endif
		.if eax!=-1
			mov		[esi].FINDTEXTEX.chrgText.cpMin,eax
			mov		edx,len
			add		edx,eax
			mov		[esi].FINDTEXTEX.chrgText.cpMax,edx
		.endif
	.else
		mov		eax,-1
	.endif
	ret

FindTextEx endp

IsLine proc uses ebx esi edi,hMem:DWORD,nLine:DWORD,lpszTest:DWORD
	LOCAL	tmpesi:DWORD

	mov		ebx,hMem
	mov		edi,nLine
	shl		edi,2
	mov		esi,lpszTest
	.if edi<=[ebx].EDIT.rpLineFree && byte ptr [esi]
		add		edi,[ebx].EDIT.hLine
		mov		edi,[edi].LINE.rpChars
		add		edi,[ebx].EDIT.hChars
		test	[edi].CHARS.state,STATE_COMMENT
		jne		Nf
		xor		ecx,ecx
		call	SkipSpc
		or		eax,eax
		jne		Nf
	  Nxt:
		mov		ax,[esi]
		.if ah
			.if ax==' $'
				inc		esi
				call	SkipWord
				or		eax,eax
				jne		Nf
				mov		al,[esi]
				.if al==' '
					inc		esi
					call	SkipSpc
					or		eax,eax
					jne		Nf
				.endif
			.elseif ax==' ?'
				add		esi,2
				push	esi
				call	TestWord
				pop		esi
				or		eax,eax
				je		Found
				dec		esi
				call	SkipWord
				or		eax,eax
				jne		Nf
				mov		al,[esi]
				.if al==' '
					inc		esi
					call	SkipSpc
					or		eax,eax
					jne		Nf
				.endif
			.elseif al=='%'
				inc		esi
				call	OptSkipWord
				jmp		Nxt
			.endif
			call	TestWord
			or		eax,eax
			jne		Nf
			xor		edx,edx
		.else
			.while ecx<[edi].CHARS.len
				xor		edx,edx
				cmp		al,[edi+ecx+sizeof CHARS]
				.break .if ZERO?
				dec		edx
				movzx	esi,byte ptr [edi+ecx+sizeof CHARS]
				movzx	esi,byte ptr [esi+offset CharTab]
				.if esi==CT_CMNTCHAR
					.break
				.elseif esi==CT_CMNTDBLCHAR
					movzx	esi,byte ptr [edi+ecx+sizeof CHARS+1]
					movzx	esi,byte ptr [esi+offset CharTab]
					.break .if esi==CT_CMNTDBLCHAR
				.elseif esi==CT_STRING
					call	SkipString
				.endif
				inc		ecx
			.endw
		.endif
	.else
	  Nf:
		xor		edx,edx
		dec		edx
	.endif
	mov		eax,edx
  Found:
	ret

SkipString:
	push	eax
	mov		al,[edi+ecx+sizeof CHARS]
	inc		ecx
	.while ecx<[edi].CHARS.len
		.break .if al==[edi+ecx+sizeof CHARS]
		inc		ecx
	.endw
	pop		eax
	retn

SkipSpc:
	.if ecx<[edi].CHARS.len
		mov		al,[edi+ecx+sizeof CHARS]
		.if al==VK_TAB || al==' ' || al==':'
			inc		ecx
			jmp		SkipSpc
		.elseif al=='"'
			call	SkipString
			.if byte ptr [edi+ecx+sizeof CHARS]=='"'
				inc		ecx
			.endif
			jmp		SkipSpc
		.elseif al==byte ptr bracketcont
			.if byte ptr [edi+ecx+sizeof CHARS+1]==VK_RETURN
				inc		nLine
				mov		edi,nLine
				shl		edi,2
				.if edi<=[ebx].EDIT.rpLineFree
					add		edi,[ebx].EDIT.hLine
					mov		edi,[edi].LINE.rpChars
					add		edi,[ebx].EDIT.hChars
					test	[edi].CHARS.state,STATE_COMMENT
					jne		Nf
					xor		ecx,ecx
					jmp		SkipSpc
				.else
					jmp		Nf
				.endif
			.endif
		.endif
		xor		eax,eax
	.else
		xor		eax,eax
		dec		eax
	.endif
	retn

OptSkipWord:
	push	ecx
	.while ecx<[edi].CHARS.len
		mov		al,[esi]
		inc		esi
		mov		ah,[edi+ecx+sizeof CHARS]
		inc		ecx
		.if al==VK_SPACE && (ah==VK_SPACE || ah==VK_TAB)
			pop		eax
			retn
		.endif
		.if al>='a' && al<='z'
			and		al,5Fh
		.endif
		.if ah>='a' && ah<='z'
			and		ah,5Fh
		.endif
		.if al!=ah
			.while byte ptr [esi-1]!=VK_SPACE
				inc		esi
			.endw
			.break
		.endif
	.endw
	pop		ecx
	retn

SkipWord:
	.if ecx<[edi].CHARS.len
		movzx	eax,byte ptr [edi+ecx+sizeof CHARS]
		.if eax!=VK_TAB && eax!=' ' && eax!=':'
			lea		eax,[eax+offset CharTab]
			mov		al,[eax]
			.if al==CT_CHAR || al==CT_HICHAR
				inc		ecx
				jmp		SkipWord
			.else
				.if al==CT_CMNTCHAR
					mov		ecx,[edi].CHARS.len
				.endif
				xor		eax,eax
				dec		eax
				retn
			.endif
		.endif
		xor		eax,eax
	.else
		xor		eax,eax
		dec		eax
	.endif
	retn

  @@:
	inc		esi
	inc		ecx
	mov		al,[esi]
	.if ecx>=[edi].CHARS.len && al
		xor		eax,eax
		dec		eax
		retn
	.endif
TestWord:
	mov		ax,[esi]
	or		al,al
	je		@f
	.if al==' '
		mov		al,[edi+ecx+sizeof CHARS]
		.if al==' ' || al==VK_TAB
			call	SkipSpc
			dec		ecx
			jmp		@b
		.else
			xor		eax,eax
			dec		eax
			retn
		.endif
	.elseif ax=='$$'
		add		esi,3
		.while ecx<[edi].CHARS.len
			push	esi
			call	TestWord
			.if !eax
				pop		eax
				xor		eax,eax
				retn
			.endif
			pop		esi
			inc		ecx
		.endw
	.elseif ax=='!$'
		add		esi,3
		.while ecx<[edi].CHARS.len
			push	esi
			call	SkipSpc
			call	TestWord
			.if !eax
				call	SkipSpc
				pop		eax
				mov		al,[edi+ecx+sizeof CHARS]
				.if al==VK_RETURN || ecx==[edi].CHARS.len
					xor		eax,eax
				.else
					movzx	eax,al
					lea		eax,[eax+offset CharTab]
					mov		al,[eax]
					.if al==CT_CMNTCHAR
						xor		eax,eax
					.else
						xor		eax,eax
						dec		eax
					.endif
				.endif
				retn
			.endif
			pop		esi
			inc		ecx
		.endw
	.elseif ax=='*/'
		xor		eax,eax
		push	ecx
		movzx	ecx,word ptr [edi+ecx+sizeof CHARS]
		.if cx!='*/'
			dec		eax
		.endif
		pop		ecx
		retn
	.elseif ax=='/*'
		xor		eax,eax
		push	ecx
		movzx	ecx,word ptr [edi+ecx+sizeof CHARS]
		.if cx!='/*'
			dec		eax
		.endif
		pop		ecx
		retn
	.elseif al=='*'
		xor		eax,eax
		push	ecx
		movzx	ecx,byte ptr [edi+ecx+sizeof CHARS]
		movzx	ecx,byte ptr [ecx+offset CharTab]
		.if ecx!=CT_CHAR
			dec		eax
		.endif
		pop		ecx
		retn
	.elseif al=='!'
		.if byte ptr [esi-1]!=' '
			mov		al,[edi+ecx+sizeof CHARS]
			.if al!=' ' && al!=VK_TAB && al!=VK_RETURN
				xor		eax,eax
				dec		eax
				retn
			.endif
		.endif
		call	SkipSpc
		.if ecx==[edi].CHARS.len
			xor		eax,eax
			retn
		.endif
		inc		esi
		mov		tmpesi,esi
		.while TRUE
			push	ecx
			call	TestWord
			pop		edx
			inc		eax
		  .break .if eax
			mov		esi,tmpesi
			mov		ecx,edx
			call	SkipWord
			.if eax
				inc		ecx
			.endif
			call	SkipSpc
			xor		eax,eax
		  .break .if ecx>=[edi].CHARS.len
		.endw
		retn
	.elseif ax==' $'
		call	SkipWord
		call	SkipSpc
		inc		esi
		inc		esi
		jmp		TestWord
	.endif
	mov		ah,[edi+ecx+sizeof CHARS]
	.if al>='a' && al<='z'
		and		al,5Fh
	.endif
	.if ah>='a' && ah<='z'
		and		ah,5Fh
	.endif
	cmp		al,'$'
	je		@f
	cmp		al,ah
	je		@b
	xor		eax,eax
	dec		eax
	retn
  @@:
	.if al=='$'
		xor		eax,eax
		.if ecx<[edi].CHARS.len
			push	ecx
			movzx	ecx,byte ptr [edi+ecx+sizeof CHARS]
			movzx	ecx,byte ptr [ecx+offset CharTab]
			.if ecx==CT_CHAR || ecx==CT_HICHAR
				inc		eax
			.endif
			pop		ecx
		.endif
		dec		eax
	.else
		xor		eax,eax
		.if ecx<[edi].CHARS.len
			push	ecx
			movzx	ecx,byte ptr [edi+ecx+sizeof CHARS]
			movzx	ecx,byte ptr [ecx+offset CharTab]
			.if ecx==CT_CHAR || ecx==CT_HICHAR
				dec		eax
			.endif
			pop		ecx
		.elseif ecx>[edi].CHARS.len
			dec		eax
		.endif
	.endif
	retn

IsLine endp

SetBookMark proc uses ebx,hMem:DWORD,nLine:DWORD,nType:DWORD

	mov		ebx,hMem
	mov		edx,nLine
	shl		edx,2
	xor		eax,eax
	.if edx<[ebx].EDIT.rpLineFree
		add		edx,[ebx].EDIT.hLine
		mov		edx,[edx].LINE.rpChars
		add		edx,[ebx].EDIT.hChars
		mov		eax,nType
		shl		eax,4
		and		eax,STATE_BMMASK
		and		[edx].CHARS.state,-1 xor STATE_BMMASK
		or		[edx].CHARS.state,eax
		inc		nBmid
		test	[edx].CHARS.state,STATE_HIDDEN
		.if ZERO?
			mov		eax,nBmid
			mov		[edx].CHARS.bmid,eax
		.endif
	.endif
	ret

SetBookMark endp

GetBookMark proc uses ebx,hMem:DWORD,nLine:DWORD

	mov		ebx,hMem
	xor		eax,eax
	dec		eax
	mov		edx,nLine
	shl		edx,2
	.if edx<[ebx].EDIT.rpLineFree
		add		edx,[ebx].EDIT.hLine
		mov		edx,[edx].LINE.rpChars
		add		edx,[ebx].EDIT.hChars
		mov		eax,[edx].CHARS.state
		and		eax,STATE_BMMASK
		shr		eax,4
	.endif
	ret

GetBookMark endp

ClearBookMarks proc uses ebx esi edi,hMem:DWORD,nType:DWORD

	mov		ebx,hMem
	and		nType,15
	mov		eax,nType
	shl		eax,4
	xor		edi,edi
	.while edi<[ebx].EDIT.rpLineFree
		mov		edx,edi
		add		edx,[ebx].EDIT.hLine
		mov		edx,[edx].LINE.rpChars
		add		edx,[ebx].EDIT.hChars
		mov		ecx,[edx].CHARS.state
		and		ecx,STATE_BMMASK
		.if eax==ecx
			and		[edx].CHARS.state,-1 xor STATE_BMMASK
			test	[edx].CHARS.state,STATE_HIDDEN
			.if ZERO?
				mov		[edx].CHARS.bmid,0
			.endif
		.endif
		add		edi,sizeof LINE
	.endw
	ret

ClearBookMarks endp

NextBookMark proc uses ebx esi edi,hMem:DWORD,nLine:DWORD,nType:DWORD
	LOCAL	fExpand:DWORD

	mov		ebx,hMem
	mov		eax,nType
	and		nType,15
	and		eax,80000000h
	mov		fExpand,eax
	mov		edi,nLine
	inc		edi
	shl		edi,2
	xor		eax,eax
	dec		eax
	.while edi<[ebx].EDIT.rpLineFree
		mov		edx,edi
		add		edx,[ebx].EDIT.hLine
		mov		edx,[edx].LINE.rpChars
		add		edx,[ebx].EDIT.hChars
		mov		ecx,[edx].CHARS.state
		and		ecx,STATE_BMMASK
		shr		ecx,4
		.if ecx==nType
			mov		eax,edi
			shr		eax,2
			.break
		.endif
		add		edi,sizeof LINE
	.endw
	ret

NextBookMark endp

PreviousBookMark proc uses ebx esi edi,hMem:DWORD,nLine:DWORD,nType:DWORD
	LOCAL	fExpand:DWORD

	mov		ebx,hMem
	mov		eax,nType
	and		nType,15
	and		eax,80000000h
	mov		fExpand,eax
	xor		eax,eax
	dec		eax
	mov		edi,nLine
	dec		edi
	shl		edi,2
	.while sdword ptr edi>=0
	  @@:
		mov		edx,edi
		add		edx,[ebx].EDIT.hLine
		mov		edx,[edx].LINE.rpChars
		add		edx,[ebx].EDIT.hChars
		mov		ecx,[edx].CHARS.state
		and		ecx,STATE_BMMASK
		shr		ecx,4
		.if ecx==nType
			mov		eax,edi
			shr		eax,2
			.break
		.endif
		sub		edi,sizeof LINE
	.endw
	ret

PreviousBookMark endp

LockLine proc uses ebx,hMem:DWORD,nLine:DWORD,fLock:DWORD

	mov		ebx,hMem
	mov		eax,nLine
	shl		eax,2
	.if eax<[ebx].EDIT.rpLineFree
		add		eax,[ebx].EDIT.hLine
		mov		eax,[eax].LINE.rpChars
		add		eax,[ebx].EDIT.hChars
		.if fLock
			or		[eax].CHARS.state,STATE_LOCKED
		.else
			and		[eax].CHARS.state,-1 xor STATE_LOCKED
		.endif
	.endif
	ret

LockLine endp

IsLineLocked proc uses ebx,hMem:DWORD,nLine:DWORD

	mov		ebx,hMem
	xor		eax,eax
	test	[ebx].EDIT.fstyle,STYLE_READONLY
	.if ZERO?
		mov		edx,nLine
		shl		edx,2
		.if edx<[ebx].EDIT.rpLineFree
			add		edx,[ebx].EDIT.hLine
			mov		edx,[edx].LINE.rpChars
			add		edx,[ebx].EDIT.hChars
			mov		eax,[edx].CHARS.state
			and		eax,STATE_LOCKED
		.endif
	.else
		inc		eax
	.endif
	ret

IsLineLocked endp

HideLine proc uses ebx,hMem:DWORD,nLine:DWORD,fHide:DWORD

	mov		ebx,hMem
	mov		eax,nLine
	shl		eax,2
	.if eax<[ebx].EDIT.rpLineFree
		add		eax,[ebx].EDIT.hLine
		mov		eax,[eax].LINE.rpChars
		add		eax,[ebx].EDIT.hChars
		.if fHide
			test	[eax].CHARS.state,STATE_HIDDEN
			.if ZERO?
				mov		ecx,[eax].CHARS.len
				.if byte ptr [eax+ecx+sizeof CHARS-1]==0Dh
					or		[eax].CHARS.state,STATE_HIDDEN
					inc		[ebx].EDIT.nHidden
					call	SetYP
					xor		eax,eax
					inc		eax
					jmp		Ex
				.endif
			.endif
		.else
			test	[eax].CHARS.state,STATE_HIDDEN
			.if !ZERO?
				and		[eax].CHARS.state,-1 xor STATE_HIDDEN
				dec		[ebx].EDIT.nHidden
				call	SetYP
;				invoke GetLineFromYp,ebx,[ebx].EDIT.edta.cpy
;				mov		[ebx].EDIT.edta.topln,eax
;				mov		eax,[ebx].EDIT.edta.cpy
;				mov		[ebx].EDIT.edta.topyp,eax
;				invoke GetCpFromLine,ebx,eax
;				mov		[ebx].EDIT.edta.topcp,eax
;
;				invoke GetLineFromYp,ebx,[ebx].EDIT.edtb.cpy
;				mov		[ebx].EDIT.edtb.topln,eax
;				mov		eax,[ebx].EDIT.edtb.cpy
;				mov		[ebx].EDIT.edtb.topyp,eax
;				invoke GetCpFromLine,ebx,eax
;				mov		[ebx].EDIT.edtb.topcp,eax
;
				xor		eax,eax
				inc		eax
				jmp		Ex
			.endif
		.endif
	.endif
	xor		eax,eax
  Ex:
	ret

SetYP:
	mov		edx,nLine
	xor		eax,eax
	.if edx<[ebx].EDIT.edta.topln
		mov		[ebx].EDIT.edta.topyp,eax
		mov		[ebx].EDIT.edta.topln,eax
		mov		[ebx].EDIT.edta.topcp,eax
	.endif
	.if edx<[ebx].EDIT.edtb.topln
		mov		[ebx].EDIT.edtb.topyp,eax
		mov		[ebx].EDIT.edtb.topln,eax
		mov		[ebx].EDIT.edtb.topcp,eax
	.endif
	retn

HideLine endp

IsLineHidden proc uses ebx,hMem:DWORD,nLine:DWORD

	mov		ebx,hMem
	mov		eax,nLine
	shl		eax,2
	.if eax<[ebx].EDIT.rpLineFree
		add		eax,[ebx].EDIT.hLine
		mov		eax,[eax].LINE.rpChars
		add		eax,[ebx].EDIT.hChars
		mov		eax,[eax].CHARS.state
		and		eax,STATE_HIDDEN
	.else
		xor		eax,eax
	.endif
	ret

IsLineHidden endp

NoBlockLine proc uses ebx,hMem:DWORD,nLine:DWORD,fNoBlock:DWORD

	mov		ebx,hMem
	mov		eax,nLine
	shl		eax,2
	.if eax<[ebx].EDIT.rpLineFree
		add		eax,[ebx].EDIT.hLine
		mov		eax,[eax].LINE.rpChars
		add		eax,[ebx].EDIT.hChars
		.if fNoBlock
			or		[eax].CHARS.state,STATE_NOBLOCK
		.else
			and		[eax].CHARS.state,-1 xor STATE_NOBLOCK
		.endif
	.endif
	ret

NoBlockLine endp

IsLineNoBlock proc uses ebx,hMem:DWORD,nLine:DWORD

	mov		ebx,hMem
	mov		eax,nLine
	shl		eax,2
	.if eax<[ebx].EDIT.rpLineFree
		add		eax,[ebx].EDIT.hLine
		mov		eax,[eax].LINE.rpChars
		add		eax,[ebx].EDIT.hChars
		mov		eax,[eax].CHARS.state
		and		eax,STATE_NOBLOCK
	.else
		xor		eax,eax
	.endif
	ret

IsLineNoBlock endp

GetBlock proc uses ebx esi edi,hMem:DWORD,nLine:DWORD,lpBlockDef:DWORD
	LOCAL	nLines:DWORD
	LOCAL	buffer[256]:BYTE
	LOCAL	nNest:DWORD
	LOCAL	flag:DWORD

	mov		ebx,hMem
	mov		nNest,1
	mov		esi,lpBlockDef
	mov		eax,[esi].RABLOCKDEF.flag
	mov		flag,eax
	mov		esi,[esi].RABLOCKDEF.lpszEnd
	.if esi
		mov		edi,nLine
		shl		edi,2
		add		edi,[ebx].EDIT.hLine
		mov		edi,[edi].LINE.rpChars
		add		edi,[ebx].EDIT.hChars
		xor		ecx,ecx
		call	SkipWhSp
		mov		al,[esi]
		.if al=='$'
			;$ endp
			mov		nNest,0
			lea		edx,buffer
			call	CopyWrd
			mov		byte ptr [edx],' '
			inc		edx
		  @@:
			inc		esi
			mov		al,[esi]
			cmp		al,' '
			je		@b
			invoke lstrcpy,edx,esi
			lea		esi,buffer
			call	TestBlock
		.elseif al=='?'
			;? endp
			mov		nNest,0
			lea		edx,buffer
			call	CopyWrd
			mov		byte ptr [edx],' '
			inc		edx
		  @@:
			inc		esi
			mov		al,[esi]
			cmp		al,' '
			je		@b
			invoke lstrcpy,edx,esi
			push	esi
			lea		esi,buffer
			call	TestBlock
			pop		esi
			.if eax==-1
				call	TestBlock
			.endif
		.else
			push	ecx
			invoke strlen,esi
			pop		ecx
			.if eax
				mov		al,[esi+eax-1]
			.endif
			.if al=='$'
				;endp $
				mov		nNest,0
				lea		edx,buffer
			  @@:
				mov		al,[esi]
				cmp		al,' '
				je		@f
				cmp		al,'$'
				je		@f
				mov		[edx],al
				inc		esi
				inc		edx
				jmp		@b
			  @@:
				mov		byte ptr [edx],' '
				inc		edx
				call	SkipWrd
				call	SkipWhSp
				call	CopyWrd
				lea		esi,buffer
				call	TestBlock
			.else
				;endp
				call TestBlock
			.endif
		.endif
	.else
		mov		nLines,0
		test	flag,BD_SEGMENTBLOCK
		.if !ZERO?
			mov		esi,[ebx].EDIT.rpLineFree
			sub		esi,4
			inc		nLine
			.while TRUE
				mov		edi,nLine
				shl		edi,2
				.break .if edi>=esi
				add		edi,[ebx].EDIT.hLine
				mov		edi,[edi].LINE.rpChars
				add		edi,[ebx].EDIT.hChars
				test	[edi].CHARS.state,STATE_SEGMENTBLOCK
				.break .if !ZERO?
				inc		nLine
				inc		nLines
			.endw
		.else
			test	flag,BD_COMMENTBLOCK
			.if !ZERO?
				mov		esi,[ebx].EDIT.rpLineFree
				sub		esi,4
				inc		nLine
				.while TRUE
					mov		edi,nLine
					shl		edi,2
					.break .if edi>=esi
					add		edi,[ebx].EDIT.hLine
					mov		edi,[edi].LINE.rpChars
					add		edi,[ebx].EDIT.hChars
					test	[edi].CHARS.state,STATE_COMMENT
					.break .if ZERO?
					inc		nLine
					inc		nLines
				.endw
			.endif
		.endif
		mov		eax,nLines
	.endif
	ret

TestBlock:
	mov		nLines,0
	mov		edi,nLine
	.while TRUE
		xor		eax,eax
		dec		eax
		mov		ecx,edi
		shl		ecx,2
		.break .if ecx>[ebx].EDIT.rpLineFree
		.if nNest
			mov		ecx,lpBlockDef
			invoke IsLine,ebx,edi,[ecx].RABLOCKDEF.lpszStart
			.if eax!=-1
				inc		nNest
			.endif
		.endif
		invoke IsLine,ebx,edi,esi
		.if eax!=-1
			cmp		dword ptr nNest,0
			.break .if ZERO?
			dec		nNest
			.break .if ZERO?
			cmp		dword ptr nNest,1
			.break .if ZERO?
		.endif
		inc		edi
		inc		nLines
	.endw
	.if nNest
		dec		nNest
	.endif
	.if nLines
		dec		nLines
	.endif
	.if eax!=-1 && !nNest
		test	flag,BD_INCLUDELAST
		je		@f
		mov		ecx,edi
		inc		ecx
		shl		ecx,2
		cmp		ecx,[ebx].EDIT.rpLineFree
		je		@f
		inc		nLines
	  @@:
		mov		eax,nLines
		test	flag,BD_LOOKAHEAD
		.if !ZERO?
			push	eax
			mov		ecx,edi
			add		ecx,500
			.while edi<ecx
				inc		edi
				mov		eax,edi
				shl		eax,2
				.break .if eax>[ebx].EDIT.rpLineFree
				inc		nLines
				push	ecx
				invoke IsLine,ebx,edi,esi
				.if eax!=-1
					pop		ecx
					pop		eax
					push	nLines
					mov		ecx,edi
					add		ecx,500
					push	ecx
				.endif
				mov		eax,lpBlockDef
				mov		eax,[eax].RABLOCKDEF.lpszStart
				invoke IsLine,ebx,edi,eax
				pop		ecx
				.break .if eax!=-1
			.endw
			pop		eax
		.endif
	.else
		xor		eax,eax
		dec		eax
	.endif
	retn

SkipWhSp:
	dec		ecx
  @@:
	inc		ecx
	cmp		ecx,[edi].CHARS.len
	jnc		@f
	mov		al,[edi+ecx+sizeof CHARS]
	cmp		al,VK_TAB
	je		@b
	cmp		al,' '
	je		@b
  @@:
	retn

SkipWrd:
	dec		ecx
  @@:
	inc		ecx
	cmp		ecx,[edi].CHARS.len
	jnc		@f
	mov		al,[edi+ecx+sizeof CHARS]
	cmp		al,VK_TAB
	je		@f
	cmp		al,' '
	je		@f
	cmp		al,0Dh
	jne		@b
  @@:
	retn

CopyWrd:
  @@:
	cmp		ecx,[edi].CHARS.len
	jnc		@f
	mov		al,[edi+ecx+sizeof CHARS]
	cmp		al,VK_TAB
	je		@f
	cmp		al,' '
	je		@f
	cmp		al,0Dh
	je		@f
	mov		[edx],al
	inc		ecx
	inc		edx
	jmp		@b
  @@:
	mov		byte ptr [edx],0
	retn

GetBlock endp

SetBlocks proc uses ebx esi edi,hMem:DWORD,lpLnrg:DWORD,lpBlockDef:DWORD
	LOCAL	nLine:DWORD

	mov		ebx,hMem
	mov		nLine,0
	mov		eax,lpLnrg
	.if eax
		mov		eax,[eax].LINERANGE.lnMin
		mov		nLine,eax
		mov		eax,[eax].LINERANGE.lnMax
		inc		eax
		inc		eax
	.endif
	dec		eax
	shl		eax,2
	mov		esi,eax
	.if esi>[ebx].EDIT.rpLineFree
		mov		esi,[ebx].EDIT.rpLineFree
	.endif
	dec		nLine
  @@:
	inc		nLine
	mov		edi,nLine
	shl		edi,2
	.if edi<esi
		invoke IsLine,ebx,nLine,offset szInclude
		inc		eax
		jne		@b
		invoke IsLine,ebx,nLine,offset szIncludelib
		inc		eax
		jne		@b
		mov		eax,lpBlockDef
		mov		eax,[eax].RABLOCKDEF.lpszStart
		invoke IsLine,ebx,nLine,eax
		inc		eax
		je		@b
		add		edi,[ebx].EDIT.hLine
		mov		edi,[edi].LINE.rpChars
		add		edi,[ebx].EDIT.hChars
		test	[edi].CHARS.state,STATE_NOBLOCK
		.if !ZERO?
			jmp		@b
		.endif
		inc		nBmid
		mov		eax,nBmid
		mov		[edi].CHARS.bmid,eax
		and		[edi].CHARS.state,-1 xor STATE_BMMASK
		or		[edi].CHARS.state,STATE_BM1
		mov		eax,lpBlockDef
		test	[eax].RABLOCKDEF.flag,BD_SEGMENTBLOCK
		.if !ZERO?
			or		[edi].CHARS.state,STATE_SEGMENTBLOCK
		.else
			and		[edi].CHARS.state,-1 xor STATE_SEGMENTBLOCK
		.endif
		test	[eax].RABLOCKDEF.flag,BD_DIVIDERLINE
		.if !ZERO?
			or		[edi].CHARS.state,STATE_DIVIDERLINE
		.else
			and		[edi].CHARS.state,-1 xor STATE_DIVIDERLINE
		.endif
		test	[eax].RABLOCKDEF.flag,BD_NONESTING
		.if !ZERO?
			invoke GetBlock,ebx,nLine,lpBlockDef
			.if eax!=-1
				add		nLine,eax
				jmp		@b
			.endif
		.endif
		mov		eax,lpBlockDef
		test	[eax].RABLOCKDEF.flag,BD_NOBLOCK
		.if !ZERO?
			invoke GetBlock,ebx,nLine,lpBlockDef
			.if eax!=-1
				mov		edx,nLine
				add		nLine,eax
				.while edx<=nLine
					inc		edx
					mov		edi,edx
					shl		edi,2
					.if edi<esi
						add		edi,[ebx].EDIT.hLine
						mov		edi,[edi].LINE.rpChars
						add		edi,[ebx].EDIT.hChars
						and		[edi].CHARS.state,-1 xor (STATE_BMMASK or STATE_SEGMENTBLOCK or STATE_DIVIDERLINE)
						or		[edi].CHARS.state,STATE_NOBLOCK
					.endif
				.endw
			.endif
		.endif
		jmp		@b
	.endif
	ret

SetBlocks endp

IsBlockDefEqual proc uses esi edi,lpRABLOCKDEF1:DWORD,lpRABLOCKDEF2:DWORD

	mov		esi,lpRABLOCKDEF1
	mov		edi,lpRABLOCKDEF2
	mov		eax,[esi].RABLOCKDEF.flag
	.if eax==[edi].RABLOCKDEF.flag
		mov		eax,[esi].RABLOCKDEF.lpszStart
		mov		edx,[edi].RABLOCKDEF.lpszStart
		.if eax && edx
			invoke lstrcmp,eax,edx
			jne		NotEq
		.elseif (eax && !edx) || (!eax && edx)
			jmp		NotEq
		.endif
		mov		eax,[esi].RABLOCKDEF.lpszEnd
		mov		edx,[edi].RABLOCKDEF.lpszEnd
		.if eax && edx
			invoke lstrcmp,eax,edx
			jne		NotEq
		.elseif (eax && !edx) || (!eax && edx)
			jmp		NotEq
		.endif
		mov		eax,[esi].RABLOCKDEF.lpszNot1
		mov		edx,[edi].RABLOCKDEF.lpszNot1
		.if eax && edx
			invoke lstrcmp,eax,edx
			jne		NotEq
		.elseif (eax && !edx) || (!eax && edx)
			jmp		NotEq
		.endif
		mov		eax,[esi].RABLOCKDEF.lpszNot2
		mov		edx,[edi].RABLOCKDEF.lpszNot2
		.if eax && edx
			invoke lstrcmp,eax,edx
			jne		NotEq
		.elseif (eax && !edx) || (!eax && edx)
			jmp		NotEq
		.endif
	.else
		jmp		NotEq
	.endif
	xor		eax,eax
	inc		eax
	ret
  NotEq:
	xor		eax,eax
	ret

IsBlockDefEqual endp

IsInBlock proc uses ebx esi edi,hMem:DWORD,nLine:DWORD,lpBlockDef:DWORD

	mov		ebx,hMem
	mov		edi,nLine
	mov		esi,lpBlockDef
	mov		esi,[esi].RABLOCKDEF.lpszStart
  @@:
	invoke PreviousBookMark,ebx,edi,1
	mov		edi,eax
	inc		eax
	.if eax
		invoke IsLine,ebx,edi,esi
		inc		eax
		je		@b
		invoke GetBlock,ebx,edi,lpBlockDef
		add		edi,eax
		xor		eax,eax
		.if edi>=nLine
			inc		eax
		.endif
	.endif
	ret

IsInBlock endp

TestBlockStart proc uses ebx esi edi,hMem:DWORD,nLine:DWORD

	mov		ebx,hMem
	mov		esi,nLine
	shl		esi,2
	.if esi<[ebx].EDIT.rpLineFree
		add		esi,[ebx].EDIT.hLine
		mov		esi,[esi]
		add		esi,[ebx].EDIT.hChars
		test	[esi].CHARS.state,STATE_NOBLOCK
		.if ZERO?
			mov		esi,offset blockdefs
			lea		edi,[esi+32*4]
			.while dword ptr [esi]
				mov		eax,[edi].RABLOCKDEF.flag
				shr		eax,16
				.if eax==[ebx].EDIT.nWordGroup
					invoke IsLine,ebx,nLine,[edi].RABLOCKDEF.lpszStart
					.if eax!=-1
						mov		eax,edi
						jmp		Ex
					.endif
				.endif
				mov		edi,dword ptr [esi]
				add		esi,4
			.endw
		.endif
	.endif
	xor		eax,eax
	dec		eax
  Ex:
	ret

TestBlockStart endp

TestBlockEnd proc uses ebx esi edi,hMem:DWORD,nLine:DWORD
	LOCAL	lpSecond:DWORD

	mov		ebx,hMem
	mov		esi,offset blockdefs
	lea		edi,[esi+32*4]
	.while dword ptr [esi]
		mov		lpSecond,0
		.if [edi].RABLOCKDEF.lpszEnd
			invoke strlen,[edi].RABLOCKDEF.lpszEnd
			mov		edx,[edi].RABLOCKDEF.lpszEnd
			lea		eax,[edx+eax+1]
			.if byte ptr [eax]
				mov		lpSecond,eax
			.endif
		.endif
		mov		eax,[edi].RABLOCKDEF.flag
		shr		eax,16
		.if [edi].RABLOCKDEF.lpszEnd && eax==[ebx].EDIT.nWordGroup
			invoke IsLine,ebx,nLine,[edi].RABLOCKDEF.lpszEnd
			.if eax!=-1
				mov		eax,edi
				jmp		Ex
			.elseif lpSecond
				invoke IsLine,ebx,nLine,lpSecond
				.if eax!=-1
					mov		eax,edi
					jmp		Ex
				.endif
			.endif
		.endif
		mov		edi,dword ptr [esi]
		add		esi,4
	.endw
	xor		eax,eax
	dec		eax
  Ex:
	ret

TestBlockEnd endp

CollapseGetEnd proc uses ebx esi edi,hMem:DWORD,nLine:DWORD
	LOCAL	nLines:DWORD
	LOCAL	nNest:DWORD
	LOCAL	nMax:DWORD
	LOCAL	Nest[256]:DWORD

	mov		ebx,hMem
	mov		nLines,0
	mov		nNest,0
	mov		eax,[ebx].EDIT.rpLineFree
	shr		eax,2
	mov		nMax,eax
	mov		edi,nLine
	invoke TestBlockStart,ebx,edi
	.if eax!=-1
		mov		edx,nNest
		mov		Nest[edx*4],eax
		test	[eax].RABLOCKDEF.flag,BD_SEGMENTBLOCK
		.if !ZERO?
			inc		edi
			.while edi<nMax
				mov		esi,edi
				shl		esi,2
				add		esi,[ebx].EDIT.hLine
				mov		esi,[esi]
				add		esi,[ebx].EDIT.hChars
				test	[esi].CHARS.state,STATE_SEGMENTBLOCK
			  .break .if !ZERO?
				inc		edi
			.endw
			mov		eax,edi
			jmp		Ex
		.else
			test	[eax].RABLOCKDEF.flag,BD_COMMENTBLOCK
			.if !ZERO?
				inc		edi
				.while edi<nMax
					mov		esi,edi
					shl		esi,2
					add		esi,[ebx].EDIT.hLine
					mov		esi,[esi]
					add		esi,[ebx].EDIT.hChars
					test	[esi].CHARS.state,STATE_COMMENT
				  .break .if ZERO?
					inc		edi
				.endw
				mov		eax,edi
				jmp		Ex
			.else
				inc		nNest
				inc		edi
				test	[eax].RABLOCKDEF.flag,BD_LOOKAHEAD
				.if !ZERO?
					mov		esi,eax
					mov		eax,edi
					add		eax,500
					.if eax<nMax
						mov		nMax,eax
					.endif
					.while edi<nMax
						invoke IsLine,ebx,edi,[esi].RABLOCKDEF.lpszStart
					  .break .if eax!=-1
						invoke IsLine,ebx,edi,[esi].RABLOCKDEF.lpszEnd
						.if eax!=-1
							mov		nLines,edi
						.endif
						inc		edi
					.endw
					mov		edi,nLines
					mov		eax,edi
					jmp		Ex
				.else
					.while edi<nMax
						invoke TestBlockStart,ebx,edi
						.if eax!=-1
							test	[eax].RABLOCKDEF.flag,BD_SEGMENTBLOCK
							.if ZERO?
								test	[eax].RABLOCKDEF.flag,BD_COMMENTBLOCK
								.if ZERO?
									mov		edx,nNest
									mov		Nest[edx*4],eax
									inc		nNest
								.endif
							.endif
						.else
							invoke TestBlockEnd,ebx,edi
							.if eax!=-1
								mov		edx,nNest
								dec		edx
								.if eax!=Nest[edx*4]
									xor		eax,eax
									dec		eax
									jmp		Ex
								.endif
								dec		nNest
								.if ZERO?
									mov		eax,edi
									jmp		Ex
								.endif
							.endif
						.endif
						inc		edi
					.endw
				.endif
			.endif
		.endif
	.endif
	xor		eax,eax
	dec		eax
  Ex:
	ret

CollapseGetEnd endp

Collapse proc uses ebx esi edi,hMem:DWORD,nLine:DWORD
	LOCAL	nLines:DWORD
	LOCAL	nNest:DWORD
	LOCAL	nMax:DWORD

	mov		ebx,hMem
	mov		nLines,0
	mov		nNest,0
	mov		edi,nLine
	invoke TestBlockStart,ebx,edi
	.if eax!=-1
		mov		esi,eax
		test	[esi].RABLOCKDEF.flag,BD_SEGMENTBLOCK
		.if !ZERO?
			mov		eax,[ebx].EDIT.rpLineFree
			shr		eax,2
			mov		nMax,eax
			invoke SetBookMark,ebx,edi,2
			mov		edx,eax
			inc		edi
			.while edi<nMax
				mov		esi,edi
				shl		esi,2
				add		esi,[ebx].EDIT.hLine
				mov		esi,[esi]
				add		esi,[ebx].EDIT.hChars
				test	[esi].CHARS.state,STATE_SEGMENTBLOCK
			  .break .if !ZERO?
				test	[esi].CHARS.state,STATE_HIDDEN
				.if ZERO?
					or		[esi].CHARS.state,STATE_HIDDEN
					mov		[esi].CHARS.bmid,edx
					inc		[ebx].EDIT.nHidden
				.endif
				inc		edi
			.endw
		.else
			test	[esi].RABLOCKDEF.flag,BD_COMMENTBLOCK
			.if !ZERO?
				mov		eax,[ebx].EDIT.rpLineFree
				shr		eax,2
				mov		nMax,eax
				invoke SetBookMark,ebx,edi,2
				mov		edx,eax
				inc		edi
				.while edi<nMax
					mov		esi,edi
					shl		esi,2
					add		esi,[ebx].EDIT.hLine
					mov		esi,[esi]
					add		esi,[ebx].EDIT.hChars
					test	[esi].CHARS.state,STATE_COMMENT
				  .break .if ZERO?
					test	[esi].CHARS.state,STATE_HIDDEN
					.if ZERO?
						or		[esi].CHARS.state,STATE_HIDDEN
						mov		[esi].CHARS.bmid,edx
						inc		[ebx].EDIT.nHidden
					.endif
					inc		edi
				.endw
			.else
				mov		eax,[ebx].EDIT.rpLineFree
				shr		eax,2
				mov		nMax,eax
				inc		nNest
				inc		edi
				test	[esi].RABLOCKDEF.flag,BD_LOOKAHEAD
				.if !ZERO?
					mov		eax,edi
					add		eax,500
					.if eax<nMax
						mov		nMax,eax
					.endif
					.while edi<nMax
						invoke IsLine,ebx,edi,[esi].RABLOCKDEF.lpszStart
					  .break .if eax!=-1
						invoke IsLine,ebx,edi,[esi].RABLOCKDEF.lpszEnd
						.if eax!=-1
							mov		nLines,edi
						.endif
						inc		edi
					.endw
					test	[esi].RABLOCKDEF.flag,BD_INCLUDELAST
					.if ZERO?
						inc		nLines
					.endif
					mov		edi,nLine
					invoke SetBookMark,ebx,edi,2
					mov		edx,eax
					inc		edi
					.while edi<=nLines
						xor		eax,eax
						dec		eax
						push	edx
						.if [esi].RABLOCKDEF.lpszNot1
							invoke IsLine,ebx,edi,[esi].RABLOCKDEF.lpszNot1
							.if eax==-1
								.if [esi].RABLOCKDEF.lpszNot2
									invoke IsLine,ebx,edi,[esi].RABLOCKDEF.lpszNot2
								.endif
							.endif
						.endif
						pop		edx
						.if eax==-1
							push	edi
							shl		edi,2
							add		edi,[ebx].EDIT.hLine
							mov		edi,[edi]
							add		edi,[ebx].EDIT.hChars
							test	[edi].CHARS.state,STATE_HIDDEN
							.if ZERO?
								or		[edi].CHARS.state,STATE_HIDDEN
								mov		[edi].CHARS.bmid,edx
								inc		[ebx].EDIT.nHidden
							.endif
							pop		edi
						.endif
						inc		edi
					.endw
				.else
					.while edi<nMax
						mov		eax,-1
						test	[esi].RABLOCKDEF.flag,BD_NOBLOCK
						.if ZERO?
							invoke TestBlockStart,ebx,edi
						.endif
						.if eax!=-1
							test	[eax].RABLOCKDEF.flag,BD_SEGMENTBLOCK
							.if ZERO?
								test	[eax].RABLOCKDEF.flag,BD_COMMENTBLOCK
								.if ZERO?
									inc		nNest
								.endif
							.endif
						.else
							invoke TestBlockEnd,ebx,edi
							.if eax!=-1
								dec		nNest
								.if ZERO?
									test	[esi].RABLOCKDEF.flag,BD_INCLUDELAST
									.if ZERO?
										dec		edi
									.endif
									mov		nLines,edi
									mov		edi,nLine
									invoke SetBookMark,ebx,edi,2
									mov		edx,eax
									inc		edi
									.while edi<=nLines
										push	edx
										invoke TestBlockStart,ebx,edi
										.if eax!=-1
											inc		nNest
										.else
											invoke TestBlockEnd,ebx,edi
											.if eax!=-1
												dec		nNest
											.endif
										.endif
										pop		edx
										xor		eax,eax
										dec		eax
										.if !nNest
											push	edx
											.if [esi].RABLOCKDEF.lpszNot1
												invoke IsLine,ebx,edi,[esi].RABLOCKDEF.lpszNot1
												.if eax==-1
													.if [esi].RABLOCKDEF.lpszNot2
														invoke IsLine,ebx,edi,[esi].RABLOCKDEF.lpszNot2
													.endif
												.endif
											.endif
											pop		edx
										.endif
										.if eax==-1
											push	edi
											shl		edi,2
											add		edi,[ebx].EDIT.hLine
											mov		edi,[edi]
											add		edi,[ebx].EDIT.hChars
											test	[edi].CHARS.state,STATE_HIDDEN
											.if ZERO?
												or		[edi].CHARS.state,STATE_HIDDEN
												mov		[edi].CHARS.bmid,edx
												inc		[ebx].EDIT.nHidden
											.endif
											pop		edi
										.endif
										inc		edi
									.endw
									jmp		Ex
								.endif
							.endif
						.endif
						inc		edi
					.endw
				.endif
			.endif
		.endif
	  Ex:
		xor		eax,eax
		mov		edx,nLine
		.if edx<[ebx].EDIT.edta.topln
			mov		[ebx].EDIT.edta.topyp,eax
			mov		[ebx].EDIT.edta.topln,eax
			mov		[ebx].EDIT.edta.topcp,eax
		.endif
		.if edx<[ebx].EDIT.edtb.topln
			mov		[ebx].EDIT.edtb.topyp,eax
			mov		[ebx].EDIT.edtb.topln,eax
			mov		[ebx].EDIT.edtb.topcp,eax
		.endif
		mov		eax,[ebx].EDIT.rpLineFree
		shr		eax,2
		sub		eax,[ebx].EDIT.nHidden
		mov		ecx,[ebx].EDIT.fntinfo.fntht
		mul		ecx
		xor		ecx,ecx
		.if eax<[ebx].EDIT.edta.cpy
			mov		[ebx].EDIT.edta.cpy,eax
			mov		[ebx].EDIT.edta.topyp,ecx
			mov		[ebx].EDIT.edta.topln,ecx
			mov		[ebx].EDIT.edta.topcp,ecx
		.endif
		.if eax<[ebx].EDIT.edtb.cpy
			mov		[ebx].EDIT.edtb.cpy,eax
			mov		[ebx].EDIT.edtb.topyp,ecx
			mov		[ebx].EDIT.edtb.topln,ecx
			mov		[ebx].EDIT.edtb.topcp,ecx
		.endif
	.endif
	ret

Collapse endp

CollapseAll proc uses ebx esi edi,hMem:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,[ebx].EDIT.cpMin
	xor		esi,esi
	mov		edi,[ebx].EDIT.rpLineFree
	shr		edi,2
  @@:
	invoke PreviousBookMark,ebx,edi,1
	.if eax!=-1
		mov		edi,eax
		invoke Collapse,ebx,edi
		.if eax!=-1
			inc		esi
		.endif
		jmp		@b
	.endif
	mov		eax,esi
	ret

CollapseAll endp

Expand proc uses ebx esi edi,hMem:DWORD,nLine:DWORD

	mov		ebx,hMem
	push	[ebx].EDIT.nHidden
	mov		esi,nLine
	xor		eax,eax
	.if esi<[ebx].EDIT.edta.topln
		mov		[ebx].EDIT.edta.topyp,eax
		mov		[ebx].EDIT.edta.topln,eax
		mov		[ebx].EDIT.edta.topcp,eax
	.endif
	.if esi<[ebx].EDIT.edtb.topln
		mov		[ebx].EDIT.edtb.topyp,eax
		mov		[ebx].EDIT.edtb.topln,eax
		mov		[ebx].EDIT.edtb.topcp,eax
	.endif
	shl		esi,2
	cmp		esi,[ebx].EDIT.rpLineFree
	jnb		Ex
	add		esi,[ebx].EDIT.hLine
	mov		ecx,[ebx].EDIT.rpLineFree
	add		ecx,[ebx].EDIT.hLine
	mov		eax,[esi].LINE.rpChars
	add		eax,[ebx].EDIT.hChars
	test	[eax].CHARS.state,STATE_HIDDEN
	jne		Ex
	mov		edi,[esi].LINE.rpChars
	add		edi,[ebx].EDIT.hChars
	mov		eax,[edi].CHARS.state
	and		eax,STATE_BMMASK
	.if eax==STATE_BM2
		mov		eax,[edi].CHARS.state
		and		eax,-1 xor STATE_BMMASK
		or		eax,STATE_BM1
		mov		[edi].CHARS.state,eax
	.elseif eax==STATE_BM8
		mov		eax,[edi].CHARS.state
		and		eax,-1 xor STATE_BMMASK
		mov		[edi].CHARS.state,eax
	.endif
	add		esi,sizeof LINE
	.if esi<ecx
		push	ecx
		mov		eax,esi
		add		eax,(sizeof LINE)*64
		.if eax<ecx
			;Check max 64 lines ahead
			mov		ecx,eax
		.endif
		.while esi<ecx
			mov		edi,[esi].LINE.rpChars
			add		edi,[ebx].EDIT.hChars
			test	[edi].CHARS.state,STATE_HIDDEN
			.break .if !ZERO?
			add		esi,sizeof LINE
		.endw
		pop		ecx
		mov		edi,[esi].LINE.rpChars
		add		edi,[ebx].EDIT.hChars
		test	[edi].CHARS.state,STATE_HIDDEN
		je		Ex
		mov		edx,[edi].CHARS.bmid
		.while esi<ecx
			mov		edi,[esi].LINE.rpChars
			add		edi,[ebx].EDIT.hChars
			.if edx==[edi].CHARS.bmid
				test	[edi].CHARS.state,STATE_HIDDEN
				.if !ZERO?
					and		[edi].CHARS.state,-1 xor STATE_HIDDEN
					dec		[ebx].EDIT.nHidden
				.endif
			.endif
			add		esi,sizeof LINE
		.endw
	.endif
  Ex:
	pop		eax
	sub		eax,[ebx].EDIT.nHidden
	ret

Expand endp

ExpandAll proc uses ebx esi edi,hMem:DWORD

	mov		ebx,hMem
	xor		esi,esi
	xor		edi,edi
	invoke GetBookMark,ebx,edi
  @@:
	.if eax==2
		invoke Expand,ebx,edi
		inc		esi
	.endif
	invoke NextBookMark,ebx,edi,2
	.if eax!=-1
		mov		edi,eax
		mov		eax,2
		jmp		@b
	.endif
	mov		eax,esi
	ret

ExpandAll endp

TestExpand proc uses ebx,hMem:DWORD,nLine:DWORD

	mov		ebx,hMem
	push	[ebx].EDIT.nHidden
  @@:
	invoke IsLineHidden,ebx,nLine
	.if eax
		push	nLine
		.while eax && nLine
			dec		nLine
			invoke IsLineHidden,ebx,nLine
		.endw
		invoke Expand,ebx,nLine
		pop		nLine
		jmp		@b
	.endif
	pop		eax
	.if eax!=[ebx].EDIT.nHidden
		invoke InvalidateEdit,ebx,[ebx].EDIT.edta.hwnd
		invoke InvalidateEdit,ebx,[ebx].EDIT.edtb.hwnd
	.endif
	ret

TestExpand endp

SetCommentBlocks proc uses ebx esi edi,hMem:DWORD,lpStart:DWORD,lpEnd:DWORD
	LOCAL	nLine:DWORD
	LOCAL	fCmnt:DWORD
	LOCAL	cmntchar:DWORD
	LOCAL	fChanged:DWORD

	mov		ebx,hMem
	mov		cmntchar,0
	mov		[ebx].EDIT.ccmntblocks,FALSE
	mov		eax,lpStart
	mov		edx,lpEnd
	.if word ptr [eax]=='*/' && word ptr [edx]=='/*'
		mov		[ebx].EDIT.ccmntblocks,1
	.elseif word ptr [eax]=="'/" && word ptr [edx]=="/'"
		mov		[ebx].EDIT.ccmntblocks,2
	.endif
	mov		al,byte ptr [eax]
	.if al
		mov		ebx,hMem
		xor		ecx,ecx
		mov		nLine,ecx
		mov		fCmnt,ecx
		mov		fChanged,ecx
		mov		edi,[ebx].EDIT.rpLineFree
		shr		edi,2
		.while nLine<edi
			mov		esi,nLine
			shl		esi,2
			add		esi,[ebx].EDIT.hLine
			mov		esi,[esi]
			add		esi,[ebx].EDIT.hChars
			push	[esi].CHARS.state
			.if fCmnt
				.if fCmnt==1
					and		[esi].CHARS.state,-1 xor STATE_COMMENT
					inc		fCmnt
				.else
					or		[esi].CHARS.state,STATE_COMMENT
				.endif
				mov		edx,lpEnd
				call	IsLineEnd
				.if !eax
					mov		fCmnt,0
				.endif
				xor		ecx,ecx
			.else
				mov		edx,lpStart
				call	IsLineStart
				.if !eax
					mov		fCmnt,1
					dec		nLine
				.else
					and		[esi].CHARS.state,-1 xor STATE_COMMENT
				.endif
			.endif
			pop		eax
			.if eax!=[esi].CHARS.state
				inc		fChanged
			.endif
			inc		nLine
		.endw
		.if fChanged
			invoke InvalidateEdit,ebx,[ebx].EDIT.edta.hwnd
			invoke InvalidateEdit,ebx,[ebx].EDIT.edtb.hwnd
		.endif
	.endif
	ret

TestWrd:
	push	ecx
	push	edx
	dec		ecx
	dec		edx
  @@:
	inc		edx
	mov		al,[edx]
	or		al,al
	je		@f
TestWrd1:
	inc		ecx
	mov		ah,[esi+ecx+sizeof CHARS]
	.if al=='+'
		cmp		ah,' '
		je		TestWrd1
		cmp		ah,VK_TAB
		je		TestWrd1
		mov		byte ptr cmntchar,ah
		jmp		@f
	.elseif al=='-'
		mov		al,byte ptr cmntchar
	.endif
	.if al>='a' && al<='z'
		and		al,5Fh
	.endif
	.if ah>='a' && ah<='z'
		and		ah,5Fh
	.endif
	cmp		al,ah
	je		@b
	pop		edx
	pop		ecx
	retn
  @@:
	pop		edx
	pop		eax
	xor		eax,eax
	retn

IsLineStart:
	xor		ecx,ecx
	dec		ecx
	mov		eax,ecx
  @@:
	inc		ecx
	cmp		ecx,[esi].CHARS.len
	je		@f
	mov		al,[esi+ecx+sizeof CHARS]
	cmp		al,' '
	je		@b
	cmp		al,VK_TAB
	je		@b
	.if [ebx].EDIT.ccmntblocks
		.while ecx<[esi].CHARS.len
			call	TestWrd
			inc		ecx
		  .break .if !eax
		.endw
	.else
		call	TestWrd
		inc		ecx
	.endif
  @@:
	retn

IsLineEnd:
	.while ecx<[esi].CHARS.len
		call	TestWrd
		inc		ecx
	  .break .if !eax
	.endw
	retn

SetCommentBlocks endp

IsSelectionLocked proc uses ebx,hMem:DWORD,cpMin:DWORD,cpMax:DWORD
	LOCAL	nLineMax:DWORD

	mov		ebx,hMem
	mov		eax,cpMin
	.if eax>cpMax
		xchg	eax,cpMax
		mov		cpMin,eax
	.endif
	invoke GetCharPtr,ebx,cpMax
	mov		nLineMax,edx
	invoke GetCharPtr,ebx,cpMin
	.while edx<=nLineMax
		push	edx
		invoke IsLineLocked,ebx,edx
		pop		edx
		or		eax,eax
		jne		Ex
		inc		edx
	.endw
  Ex:
	ret

IsSelectionLocked endp


TrimSpace proc uses ebx edi,hMem:DWORD,nLine:DWORD,fLeft:DWORD
	LOCAL	cp:DWORD

	mov		ebx,hMem
	mov		edi,nLine
	invoke GetCpFromLine,ebx,edi
	mov		cp,eax
	shl		edi,2
	xor		edx,edx
	.if edi<[ebx].EDIT.rpLineFree
		add		edi,[ebx].EDIT.hLine
		mov		edi,[edi].LINE.rpChars
		add		edi,[ebx].EDIT.hChars
		mov		edx,[edi].CHARS.len
		.if edx
			.if fLeft
				;Left trim (Not implemented)
			.else
				;Right trim
				push	edx
				mov		al,[edi+edx+sizeof CHARS-1]
				push	eax
				.if al==0Dh
					dec		edx
				.endif
				mov		ecx,edx
			  @@:
				mov		al,[edi+ecx+sizeof CHARS-1]
				.if al==' ' || al==VK_TAB
					dec		ecx
					jne		@b
				.endif
				mov		eax,cp
				add		eax,ecx
				sub		edx,ecx
				push	edx
				lea		edx,[edi+ecx+sizeof CHARS]
				pop		ecx
				push	ecx
				invoke SaveUndo,ebx,UNDO_DELETEBLOCK,eax,edx,ecx

				pop		ecx
			.endif
			sub		[edi].CHARS.len,ecx
			pop		eax
			mov		ecx,[edi].CHARS.len
			.if al==0Dh
				mov		[edi+ecx+sizeof CHARS-1],al
			.endif
			pop		edx
			sub		edx,ecx
		.endif
	.endif
	.if edx
		xor		eax,eax
		mov		[ebx].EDIT.edta.topyp,eax
		mov		[ebx].EDIT.edta.topln,eax
		mov		[ebx].EDIT.edta.topcp,eax
		mov		[ebx].EDIT.edtb.topyp,eax
		mov		[ebx].EDIT.edtb.topln,eax
		mov		[ebx].EDIT.edtb.topcp,eax
		push	edx
		.if ![ebx].EDIT.fChanged
			mov		[ebx].EDIT.fChanged,TRUE
			invoke InvalidateRect,[ebx].EDIT.hsta,NULL,TRUE
		.endif
		invoke GetTopFromYp,ebx,[ebx].EDIT.edta.hwnd,[ebx].EDIT.edta.cpy
		invoke GetTopFromYp,ebx,[ebx].EDIT.edtb.hwnd,[ebx].EDIT.edtb.cpy
		pop		edx
		inc		[ebx].EDIT.nchange
	.endif
	mov		eax,edx
	ret

TrimSpace endp

SkipSpace proc uses ebx esi,hMem:DWORD,cp:DWORD,fLeft:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,cp
	mov		esi,[ebx].EDIT.rpChars
	add		esi,[ebx].EDIT.hChars
	mov		edx,eax
	.if !fLeft
	  @@:
		.if edx<[esi].CHARS.len
			mov		al,[esi+edx+sizeof CHARS]
			.if al==' ' || al==VK_TAB
				inc		edx
				jmp		@b
			.endif
		.endif
	.else
	  @@:
		.if edx
			mov		al,[esi+edx+sizeof CHARS-1]
			.if al==' ' || al==VK_TAB
				dec		edx
				jmp		@b
			.endif
		.endif
	.endif
	mov		eax,[ebx].EDIT.cpLine
	add		eax,edx
	ret

SkipSpace endp

SkipWhiteSpace proc uses ebx esi,hMem:DWORD,cp:DWORD,fLeft:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,cp
	mov		esi,[ebx].EDIT.rpChars
	add		esi,[ebx].EDIT.hChars
	mov		edx,eax
	.if !fLeft
	  @@:
		.if edx<[esi].CHARS.len
			mov		al,[esi+edx+sizeof CHARS]
			invoke IsChar
			.if al!=1
				inc		edx
				jmp		@b
			.endif
		.endif
	.else
	  @@:
		.if edx
			mov		al,[esi+edx+sizeof CHARS]
			invoke IsChar
			.if al!=1
				dec		edx
				jmp		@b
			.endif
		.endif
	.endif
	mov		eax,[ebx].EDIT.cpLine
	add		eax,edx
	ret

SkipWhiteSpace endp

GetWordStart proc uses ebx esi,hMem:DWORD,cp:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,cp
	mov		esi,[ebx].EDIT.rpChars
	add		esi,[ebx].EDIT.hChars
	mov		edx,eax
  @@:
	.if edx
		mov		al,[esi+edx+sizeof CHARS-1]
		invoke IsChar
		.if al==1
			dec		edx
			jmp		@b
		.endif
	.endif
	mov		eax,[ebx].EDIT.cpLine
	add		eax,edx
	ret

GetWordStart endp

GetLineStart proc uses ebx,hMem:DWORD,cp:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,cp
	mov		eax,[ebx].EDIT.cpLine
	ret

GetLineStart endp

GetTabPos proc uses ebx esi,hMem:DWORD,cp:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,cp
	mov		esi,[ebx].EDIT.rpChars
	add		esi,[ebx].EDIT.hChars
	mov		edx,eax
	xor		eax,eax
	xor		ecx,ecx
	.while sdword ptr ecx<edx
		inc		eax
		.if byte ptr [esi+ecx+sizeof CHARS]==VK_TAB || eax==[ebx].EDIT.nTab
			xor		eax,eax
		.endif
		inc		ecx
	.endw
	ret

GetTabPos endp

GetWordEnd proc uses ebx esi,hMem:DWORD,cp:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,cp
	mov		esi,[ebx].EDIT.rpChars
	add		esi,[ebx].EDIT.hChars
	mov		edx,eax
  @@:
	.if edx<[esi].CHARS.len
		mov		al,[esi+edx+sizeof CHARS]
		invoke IsChar
		.if al==1
			inc		edx
			jmp		@b
		.endif
	.endif
	mov		eax,[ebx].EDIT.cpLine
	add		eax,edx
	ret


GetWordEnd endp

GetLineEnd proc uses ebx esi,hMem:DWORD,cp:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,cp
	mov		esi,[ebx].EDIT.rpChars
	add		esi,[ebx].EDIT.hChars
	mov		edx,eax
  @@:
	.if edx<[esi].CHARS.len
		mov		al,[esi+edx+sizeof CHARS]
		invoke IsChar
		.if al==1
			inc		edx
			jmp		@b
		.endif
	.endif
	mov		eax,[ebx].EDIT.cpLine
	add		eax,[esi].CHARS.len
	dec		eax
	.if byte ptr [esi+eax+sizeof CHARS]==VK_RETURN
		dec		eax
	.endif
	ret

GetLineEnd endp

StreamIn proc uses ebx esi edi,hMem:DWORD,lParam:DWORD
	LOCAL	dwRead:DWORD
	LOCAL	hCMem:DWORD
	LOCAL	lastchr:DWORD

	mov		ebx,hMem
	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAXSTREAM
	mov     hCMem,eax
	invoke GlobalLock,hCMem
	xor		edi,edi
	mov		lastchr,edi
  @@:
	mov		esi,lParam
	mov		[esi].EDITSTREAM.dwError,0
	lea		eax,dwRead
	push	eax
	mov		eax,MAXSTREAM
	push	eax
	push	hCMem
	mov		eax,[esi].EDITSTREAM.dwCookie
	push	eax
	mov		eax,[esi].EDITSTREAM.pfnCallback
	call	eax
	or		eax,eax
	jne		@f
	xor		ecx,ecx
	mov		esi,hCMem
	mov		edx,lastchr
	.while ecx<dwRead
		push	ecx
		movzx	eax,byte ptr [esi+ecx]
		.if eax!=0Ah && eax
			push	eax
			invoke InsertChar,ebx,edi,eax
			pop		edx
			inc		edi
		.elseif eax==0Ah && edx!=0Dh
			mov		eax,0Dh
			invoke InsertChar,ebx,edi,eax
			xor		edx,edx
			inc		edi
		.endif
		pop		ecx
		inc		ecx
	.endw
	mov		lastchr,edx
	mov		eax,dwRead
	or		eax,eax
	jne		@b
  @@:
	invoke GlobalUnlock,hCMem
	invoke GlobalFree,hCMem
	mov		[ebx].EDIT.nHidden,0
	ret

StreamIn endp

StreamOut proc uses ebx esi edi,hMem:DWORD,lParam:DWORD
	LOCAL	dwWrite:DWORD
	LOCAL	hCMem:DWORD

	mov		ebx,hMem
	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,MAXSTREAM
	mov     hCMem,eax
	invoke GlobalLock,hCMem
	mov		esi,[ebx].EDIT.hLine
  @@:
	call	FillCMem
	or		ecx,ecx
	je		@f
	mov		edx,lParam
	mov		[edx].EDITSTREAM.dwError,0
	lea		eax,dwWrite
	push	eax
	push	ecx
	push	hCMem
	mov		eax,[edx].EDITSTREAM.dwCookie
	push	eax
	mov		eax,[edx].EDITSTREAM.pfnCallback
	call	eax
	or		eax,eax
	je		@b
  @@:
	invoke GlobalUnlock,hCMem
	invoke GlobalFree,hCMem
	ret

FillCMem:
	xor		ecx,ecx
	xor		edx,edx
	mov		eax,esi
	sub		eax,[ebx].EDIT.hLine
	.if eax<[ebx].EDIT.rpLineFree
		push	esi
		mov		edi,hCMem
		mov		esi,[esi].LINE.rpChars
		add		esi,[ebx].EDIT.hChars
		.while ecx<[esi].CHARS.len
			mov		al,[esi+ecx+sizeof CHARS]
			mov		[edi],al
			inc		ecx
			inc		edi
			.if al==0Dh
				mov		byte ptr [edi],0Ah

				inc		edx
				inc		edi
			.endif
		.endw
		pop		esi
		add		esi,sizeof LINE
	.endif
	add		ecx,edx
	retn


StreamOut endp

SelChange proc uses ebx,hMem:DWORD,nType:DWORD
	LOCAL	sc:RASELCHANGE

	mov		ebx,hMem
	.if [ebx].EDIT.cpbrst!=-1
		mov		[ebx].EDIT.cpbrst,-1
		mov		[ebx].EDIT.cpbren,-1
		invoke InvalidateEdit,ebx,[ebx].EDIT.edta.hwnd
		invoke InvalidateEdit,ebx,[ebx].EDIT.edtb.hwnd
	.endif
	invoke GetCharPtr,hMem,[ebx].EDIT.cpMin
	mov		edx,[ebx].EDIT.ID
	mov		eax,[ebx].EDIT.hwnd
	mov		sc.nmhdr.hwndFrom,eax
	mov		sc.nmhdr.idFrom,edx
	mov		sc.nmhdr.code,EN_SELCHANGE
	test	[ebx].EDIT.nMode,MODE_BLOCK
	.if ZERO?
		mov		eax,[ebx].EDIT.cpMin
		mov		sc.chrg.cpMin,eax
		mov		eax,[ebx].EDIT.cpMax
		mov		sc.chrg.cpMax,eax
	.else
		mov		eax,[ebx].EDIT.cpLine
		add		eax,[ebx].EDIT.blrg.clMin
		mov		sc.chrg.cpMin,eax
		mov		sc.chrg.cpMax,eax
	.endif
	mov		eax,nType
	mov		sc.seltyp,ax
	mov		eax,[ebx].EDIT.line
	mov		sc.line,eax
	mov		eax,[ebx].EDIT.cpLine
	mov		sc.cpLine,eax
	mov		eax,[ebx].EDIT.rpChars
	add		eax,[ebx].EDIT.hChars
	mov		sc.lpLine,eax
	mov		eax,[ebx].EDIT.rpLineFree
	shr		eax,2
	dec		eax
	mov		sc.nlines,eax
	mov		eax,[ebx].EDIT.nHidden
	mov		sc.nhidden,eax
	mov		eax,[ebx].EDIT.nchange
	sub		eax,[ebx].EDIT.nlastchange
	.if eax
		add		[ebx].EDIT.nlastchange,eax
		mov		eax,TRUE
	.endif
	mov		sc.fchanged,eax
	mov		ecx,[ebx].EDIT.nPageBreak
	xor		eax,eax
	.if ecx
		mov		eax,[ebx].EDIT.line
		xor		edx,edx
		div		ecx
	.endif
	mov		sc.npage,eax
	mov		eax,[ebx].EDIT.nWordGroup
	mov		sc.nWordGroup,eax
	.if ![ebx].EDIT.nsplitt
		mov		eax,[ebx].EDIT.cpMin
		mov		[ebx].EDIT.edta.cp,eax
		mov		[ebx].EDIT.edtb.cp,eax
	.endif
	invoke SendMessage,[ebx].EDIT.hpar,WM_NOTIFY,[ebx].EDIT.ID,addr sc
	ret

SelChange endp

AutoIndent proc uses ebx esi,hMem:DWORD
	LOCAL	nLine:DWORD

	mov		ebx,hMem
	invoke GetLineFromCp,ebx,[ebx].EDIT.cpMin
	.if eax
		mov		nLine,eax
		xor		edx,edx
		push	[ebx].EDIT.fOvr
		mov		[ebx].EDIT.fOvr,FALSE
	  @@:
		mov		eax,nLine
		mov		esi,[ebx].EDIT.hLine
		lea		esi,[esi+eax*sizeof LINE-sizeof LINE]
		mov		esi,[esi].LINE.rpChars
		add		esi,[ebx].EDIT.hChars
		.if edx<[esi].CHARS.len
			movzx	eax,byte ptr [esi+edx+sizeof CHARS]
			.if al==' ' || al==VK_TAB
				push	edx
				push	eax
				invoke InsertChar,ebx,[ebx].EDIT.cpMin,eax
				pop		eax
				invoke SaveUndo,ebx,UNDO_INSERT,[ebx].EDIT.cpMin,eax,1
				mov		eax,[ebx].EDIT.cpMin
				inc		eax
				mov		[ebx].EDIT.cpMin,eax
				mov		[ebx].EDIT.cpMax,eax
				pop		edx
				inc		edx
				jmp		@b
			.endif
		.endif
		pop		[ebx].EDIT.fOvr
	.endif
	ret

AutoIndent endp

IsCharPos proc uses ebx esi,hMem:DWORD,cp:DWORD
	LOCAL	nMax:DWORD

	mov		ebx,hMem
	invoke GetCharPtr,ebx,cp
	mov		nMax,eax
	mov		esi,[ebx].EDIT.rpChars
	add		esi,[ebx].EDIT.hChars
	mov		eax,[esi].CHARS.state
	test	eax,STATE_COMMENT
	.if ZERO?
		xor		ecx,ecx
		.while ecx<nMax
			movzx	eax,byte ptr [esi+ecx+sizeof CHARS]
			mov		al,byte ptr [eax+offset CharTab]
			.if al==CT_CMNTCHAR
				mov		eax,2
				jmp		Ex
			.elseif al==CT_CMNTDBLCHAR
				mov		al,byte ptr [esi+ecx+sizeof CHARS]
				mov		ah,byte ptr [esi+ecx+sizeof CHARS+1]
				.if al==ah || ah=='*'
					mov		eax,2
					jmp		Ex
				.endif
			.elseif al==CT_STRING
				mov		al,byte ptr [esi+ecx+sizeof CHARS]
				.while ecx<nMax
					inc		ecx
					.break .if al==byte ptr [esi+ecx+sizeof CHARS]
				.endw
				.if ecx>=nMax
					mov		eax,3
					jmp		Ex
				.endif
			.endif
			inc		ecx
		.endw
		xor		eax,eax
	.else
		;On comment block
		mov		eax,1
	.endif
  Ex:
	ret

IsCharPos endp

BracketMatchRight proc uses ebx esi edi,hMem:DWORD,nChr:DWORD,nMatch:DWORD,cp:DWORD
	LOCAL	nCount:DWORD

	mov		ebx,hMem
	mov		nCount,0
	invoke GetCharPtr,ebx,cp
	mov		edx,eax
	mov		edi,[ebx].EDIT.hChars
	add		edi,[ebx].EDIT.rpChars
	.while edx<=[edi].CHARS.len
		mov		al,byte ptr nMatch
		mov		ah,byte ptr nChr
		mov		cl,byte ptr bracketcont
		mov		ch,byte ptr bracketcont+1
		.if al==byte ptr [edi+edx+sizeof CHARS]
			push	edx
			invoke IsCharPos,ebx,cp
			pop		edx
			.if !eax
				dec		nCount
				.if ZERO?
					mov		eax,edx
					add		eax,[ebx].EDIT.cpLine
					ret
				.endif
			.endif
		.elseif ah==byte ptr [edi+edx+sizeof CHARS]
			push	edx
			invoke IsCharPos,ebx,cp
			pop		edx
			.if !eax
				inc		nCount
			.endif
		.elseif (cl==byte ptr [edi+edx+sizeof CHARS] || ch==byte ptr [edi+edx+sizeof CHARS]) && edx<=[edi].CHARS.len
			.if byte ptr [edi+edx+sizeof CHARS]!=VK_RETURN
				push	edx
				invoke IsCharPos,ebx,cp
				pop		edx
				inc		edx
				inc		cp
				.if !eax
					.while (byte ptr [edi+edx+sizeof CHARS]==VK_SPACE || byte ptr [edi+edx+sizeof CHARS]==VK_TAB) && edx<[edi].CHARS.len
						inc		edx
						inc		cp
					.endw
				.endif
				.if byte ptr [edi+edx+sizeof CHARS]==VK_RETURN
					inc		cp
					mov		eax,cp
					invoke GetCharPtr,ebx,eax
					mov		edx,eax
					mov		edi,[ebx].EDIT.hChars
					add		edi,[ebx].EDIT.rpChars
					xor		edx,edx
				.endif
			.else
				inc		cp
				mov		eax,cp
				invoke GetCharPtr,ebx,eax
				mov		edx,eax
				mov		edi,[ebx].EDIT.hChars
				add		edi,[ebx].EDIT.rpChars
				xor		edx,edx
			.endif
			dec		edx
			dec		cp
		.endif
		inc		edx
		inc		cp
	.endw
	xor		eax,eax
	dec		eax
	ret

BracketMatchRight endp

BracketMatchLeft proc uses ebx esi edi,hMem:DWORD,nChr:DWORD,nMatch:DWORD,cp:DWORD
	LOCAL	nCount:DWORD

	mov		ebx,hMem
	mov		nCount,0
	invoke GetCharPtr,ebx,cp
	mov		edx,eax
	mov		edi,[ebx].EDIT.hChars
	add		edi,[ebx].EDIT.rpChars
	.while sdword ptr edx>=0
		mov		al,byte ptr nMatch
		mov		ah,byte ptr nChr
		.if al==byte ptr [edi+edx+sizeof CHARS]
			push	edx
			invoke IsCharPos,ebx,cp
			pop		edx
			.if !eax
				dec		nCount
				.if ZERO?
					mov		eax,edx
					add		eax,[ebx].EDIT.cpLine
					ret
				.endif
			.endif
		.elseif ah==byte ptr [edi+edx+sizeof CHARS]
			push	edx
			invoke IsCharPos,ebx,cp
			pop		edx
			.if !eax
				inc		nCount
			.endif
		.endif
		.if !edx && [ebx].EDIT.line
			dec		cp
			invoke GetCharPtr,ebx,cp
			mov		edx,eax
			mov		edi,[ebx].EDIT.hChars
			add		edi,[ebx].EDIT.rpChars
			.while (byte ptr [edi+edx+sizeof CHARS]==VK_SPACE || byte ptr [edi+edx+sizeof CHARS]==VK_TAB) && edx!=0
				dec		edx
				dec		cp
			.endw
			push	edx
			invoke IsCharPos,ebx,cp
			pop		edx
			.if !eax
				.if byte ptr bracketcont!=VK_RETURN
					.if edx
						dec		edx
						mov		al,byte ptr [edi+edx+sizeof CHARS]
						.if al!=byte ptr bracketcont && al!=byte ptr bracketcont+1
							.break
						.endif
					.endif
				.endif
			.endif
			inc		cp
			inc		edx
		.endif
		dec		edx
		dec		cp
	.endw
	xor		eax,eax
	dec		eax
	ret

BracketMatchLeft endp

BracketMatch proc uses ebx,hMem:DWORD,nChr:DWORD,cp:DWORD

	mov		ebx,hMem
	.if [ebx].EDIT.cpbrst!=-1 || [ebx].EDIT.cpbren!=-1
		invoke InvalidateEdit,ebx,[ebx].EDIT.edta.hwnd
		invoke InvalidateEdit,ebx,[ebx].EDIT.edtb.hwnd
		xor		eax,eax
		dec		eax
		mov		[ebx].EDIT.cpbrst,eax
		mov		[ebx].EDIT.cpbren,eax
	.endif
	mov		al,byte ptr nChr
	xor		ecx,ecx
	.while byte ptr bracketstart[ecx]
		.if al==bracketstart[ecx]
			push	ecx
			invoke IsCharPos,ebx,cp
			pop		ecx
			or		eax,eax
			jne		Ex
			movzx	eax,byte ptr bracketend[ecx]
			invoke BracketMatchRight,ebx,nChr,eax,cp
			mov		[ebx].EDIT.cpbren,eax
			mov		eax,cp
			mov		[ebx].EDIT.cpbrst,eax
			invoke InvalidateEdit,ebx,[ebx].EDIT.edta.hwnd
			invoke InvalidateEdit,ebx,[ebx].EDIT.edtb.hwnd
			jmp		Ex
		.endif
		inc		ecx
	.endw
	xor		ecx,ecx
	.while byte ptr bracketend[ecx]
		.if al==bracketend[ecx]
			push	ecx
			invoke IsCharPos,ebx,cp
			pop		ecx
			or		eax,eax
			jne		Ex
			movzx	eax,byte ptr bracketstart[ecx]
			invoke BracketMatchLeft,ebx,nChr,eax,cp
			mov		[ebx].EDIT.cpbrst,eax
			mov		eax,cp
			mov		[ebx].EDIT.cpbren,eax
			invoke InvalidateEdit,ebx,[ebx].EDIT.edta.hwnd
			invoke InvalidateEdit,ebx,[ebx].EDIT.edtb.hwnd
			jmp		Ex
		.endif
		inc		ecx
	.endw
  Ex:
	ret

BracketMatch endp
