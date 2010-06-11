
.const

szfpskipline				db 	10,7,'program'
							db	10,4,'uses'
							db	0,0,0

szfpword1					db	10,8,'function'
							db	11,9,'procedure'
							db	12,4,'type'
							db	13,5,'const'
							db	14,3,'var'
							db	15,5,'begin'
							db	16,3,'end'
							db	0,0,0

szfpword2					db	10,6,'record'
							db	11,5,'array'
							db	12,2,'to'
							db	0,0,0

szfpcomment					db '{',0
szfpstring					db '"',"'",0,0

.code

FpDestroyString proc lpMem:DWORD

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

FpDestroyString endp

FpDestroyCmntBlock proc uses esi,lpMem:DWORD,lpCharTab:DWORD

	mov		esi,lpMem
  @@:
	invoke SearchMemDown,esi,addr szfpcomment,FALSE,FALSE,lpCharTab
	.if eax
		mov		esi,eax
		.while eax>lpMem
			.break .if byte ptr [eax-1]==VK_RETURN || byte ptr [eax-1]==0Ah
			dec		eax
		.endw
		mov		ecx,dword ptr szfpstring
		mov		edx,'//'
		.while eax<esi
			.if byte ptr [eax]==cl || byte ptr [eax]==ch
				;String
				invoke FpDestroyString,eax
				mov		esi,eax
				jmp		@b
			.elseif word ptr [eax]==dx
				;Comment
				invoke DestroyToEol,eax
				mov		esi,eax
				jmp		@b
			.endif
			inc		eax
		.endw
		.while byte ptr [esi]!='}' && byte ptr [esi]
			mov		al,[esi]
			.if al!=VK_RETURN && al!=0Ah
				mov		byte ptr [esi],' '
			.endif
			inc		esi
		.endw
		.if byte ptr [esi]=='}'
			mov		byte ptr [esi],' '
		.endif
		jmp		@b
	.endif
	ret

FpDestroyCmntBlock endp

FpDestroyCommentsStrings proc uses esi,lpMem:DWORD

	mov		esi,lpMem
	mov		ecx,'//'
	mov		edx,dword ptr szfpstring
	.while byte ptr [esi]
		.if word ptr [esi]==cx
			invoke DestroyToEol,esi
			mov		esi,eax
		.elseif byte ptr [esi]==dl || byte ptr [esi]==dh
			invoke FpDestroyString,esi
			mov		esi,eax
			mov		ecx,'//'
			mov		edx,dword ptr szfpstring
		.elseif byte ptr [esi]==VK_TAB
			mov		byte ptr [esi],VK_SPACE
		.else
			inc		esi
		.endif
	.endw
	ret

FpDestroyCommentsStrings endp

FpPreParse proc uses esi,lpMem:DWORD,lpCharTab:DWORD

	invoke FpDestroyCmntBlock,lpMem,lpCharTab
	invoke FpDestroyCommentsStrings,lpMem
	ret

FpPreParse endp

FpIsWord proc uses ebx esi edi,lpWord:DWORD,lenWord:DWORD,lpList:DWORD

	mov		esi,lpList
	mov		edi,lenWord
	.while byte ptr [esi]
		movzx	ebx,byte ptr [esi+1]
		.if ebx==edi
			invoke strcmpin,addr [esi+2],lpWord,edi
			.if !eax
				movzx	eax,byte ptr [esi]
				jmp		Ex
			.endif
		.endif
		lea		esi,[esi+ebx+2]
	.endw
	xor		eax,eax
  Ex:
	ret

FpIsWord endp

FpParseFile proc uses ebx esi edi,nOwner:DWORD,lpMem:DWORD
	LOCAL	len1:DWORD
	LOCAL	lpword1:DWORD
	LOCAL	len2:DWORD
	LOCAL	lpword2:DWORD
	LOCAL	lendt:DWORD
	LOCAL	lpdt:DWORD
	LOCAL	nnest:DWORD
	LOCAL	lenname[8]:DWORD
	LOCAL	lpname[8]:DWORD
	LOCAL	narray:DWORD
	LOCAL	lpCharTab:DWORD
	LOCAL	npos:DWORD
	LOCAL	nline:DWORD
	LOCAL	ntype:DWORD

	mov		eax,[ebx].RAPROPERTY.lpchartab
	mov		lpCharTab,eax
	mov		esi,lpMem
	invoke FpPreParse,esi,lpCharTab
	mov		npos,0
	mov		ntype,0
	.while byte ptr [esi]
		mov		eax,npos
		mov		nline,eax
		call	GetWord
		.if ecx
			mov		len1,ecx
			mov		lpword1,esi
			lea		esi,[esi+ecx]
			invoke FpIsWord,lpword1,len1,offset szfpskipline
			.if eax
				; Skip line
				.while byte ptr [esi] && byte ptr [esi]!=';'
					.if byte ptr [esi]==VK_RETURN
						inc		npos
					.endif
					inc		esi
				.endw
				jmp		NxtLine
			.endif
			invoke FpIsWord,lpword1,len1,offset szfpword1
			.if eax
				mov		ntype,eax
			.elseif ntype
				mov		eax,ntype
				.if eax==10
					;Function
				.elseif eax==11
					;Procedure
				.elseif eax==12
					;Type
				.elseif eax==13
					;Const
					call	GetWord
					.if !ecx
						.if byte ptr [esi]==':'
							;Skip datatype
							inc		esi
							call	GetWord
							lea		esi,[esi+ecx]
							call	SkipSpc
						.endif
						.if byte ptr [esi]=='='
							inc		esi
							Call	_Const
						.endif
					.endif
				.elseif eax==14
					;Var
					call	GetWord
					.if !ecx
						.if byte ptr [esi]==':'
							call	_DataType
							Call	_Data
						.elseif byte ptr [esi]==','
							call	_DataType
							call	_Data
							inc		esi
							jmp		Nxt
						.endif
					.endif
				.endif
			.endif
;			call	GetWord
;			.if ecx
;				mov		len2,ecx
;				mov		lpword2,esi
;				lea		esi,[esi+ecx]
;				invoke FpIsWord,lpword1,len1,offset szfpword1
;				.if eax
;					.if eax==10
;						; Proc
;						call	_Proc
;						jmp		Nxt
;					.elseif eax==11
;						; Struc, Union
;						call	_Struct
;						jmp		Nxt
;					.endif
;				.endif
;				invoke FpIsWord,lpword2,len2,offset szfpword2
;				.if eax
;					.if eax==10
;						; const equ 10
;						call	_Const
;						jmp		Nxt
;					.endif
;				.endif
;				invoke FpIsWord,lpword2,len2,offset szfpdatatypes
;				.if eax
;					.if eax>=10 && eax<=12
;						; data db ?, data byte ?, data rb 10, data rs RECT,10
;						call	_Data
;						jmp		Nxt
;					.endif
;				.endif
;			.elseif byte ptr [esi]==':'
;				; label:
;				call	_Label
;			.endif
		.endif
	  NxtLine:
		call	SkipLine
	  Nxt:
	.endw
	ret

SkipLine:
	xor		eax,eax
	.while byte ptr [esi] && byte ptr [esi]!=VK_RETURN
		inc		esi
	.endw
	.if byte ptr [esi]==VK_RETURN
		inc		npos
		inc		esi
		.if byte ptr [esi]==0Ah
			inc		esi
		.endif
	.endif
	retn

SkipSpc:
	.while byte ptr [esi]==VK_SPACE
		inc		esi
	.endw
	retn

GetWord:
	call	SkipSpc
	.if byte ptr [esi]==VK_RETURN
		inc		esi
		.if byte ptr [esi]==0Ah
			inc		esi
		.endif
	.endif
	mov		edx,lpCharTab
	xor		ecx,ecx
	dec		ecx
  @@:
	inc		ecx
	movzx	eax,byte ptr [esi+ecx]
	cmp		byte ptr [eax+edx],1
	je		@b
	retn

SaveWord1:
	push	ebx
	xor		ecx,ecx
	mov		ebx,lpword1
	.while ecx<len1
		mov		al,[ebx+ecx]
		mov		[edi+ecx],al
		inc		ecx
	.endw
	mov		dword ptr [edi+ecx],0
	lea		edi,[edi+ecx+1]
	pop		ebx
	retn

SaveWord2:
	push	ebx
	xor		ecx,ecx
	mov		ebx,lpword2
	.while ecx<len2
		mov		al,[ebx+ecx]
		mov		[edi+ecx],al
		inc		ecx
	.endw
	mov		dword ptr [edi+ecx],0
	lea		edi,[edi+ecx+1]
	pop		ebx
	retn

;SkipBrace:
;	xor		eax,eax
;	dec		eax
;SkipBrace1:
;	.while byte ptr [esi]==VK_SPACE
;		inc		esi
;	.endw
;	mov		al,[esi]
;	inc		esi
;	.if al=='('
;		push	eax
;		mov		ah,')'
;		jmp		SkipBrace1
;	.elseif al=='{'
;		push	eax
;		mov		ah,'}'
;		jmp		SkipBrace1
;	.elseif al=='['
;		push	eax
;		mov		ah,']'
;		jmp		SkipBrace1
;	.elseif al=='<'
;		push	eax
;		mov		ah,'>'
;		jmp		SkipBrace1
;	.elseif al=='"'
;		push	eax
;		mov		ah,'"'
;		jmp		SkipBrace1
;	.elseif al=="'"
;		push	eax
;		mov		ah,"'"
;		jmp		SkipBrace1
;	.elseif al==ah
;		pop		eax
;	.elseif ah==0FFh
;		dec		esi
;		retn
;	.elseif al==VK_RETURN || al==0
;		dec		esi
;		pop		eax
;	.endif
;	jmp		SkipBrace1
;
;;ConvDataType:
;;	push	esi
;;	mov		esi,offset szFpDataConv
;;	.if lendt==2
;;		.while byte ptr [esi]
;;			invoke strcmpin,esi,lpdt,2
;;			.if !eax
;;				lea		esi,[esi+3]
;;				mov		lpdt,esi
;;				invoke strlen,esi
;;				mov		lendt,eax
;;				jmp		ExConvDataType
;;			.endif
;;			invoke strlen,esi
;;			lea		esi,[esi+eax+1]
;;			invoke strlen,esi
;;			lea		esi,[esi+eax+1]
;;		.endw
;;	.elseif lendt==4 || lendt==5 || lendt==6
;;		.while byte ptr [esi]
;;			lea		esi,[esi+3]
;;			invoke strcmpin,esi,lpdt,lendt
;;			.if !eax
;;				mov		lpdt,esi
;;				jmp		ExConvDataType
;;			.endif
;;			invoke strlen,esi
;;			lea		esi,[esi+eax+1]
;;		.endw
;;	.endif
;;  ExConvDataType:
;;	pop		esi
;;	retn
;
;ArraySize:
;	call	SkipSpc
;	push	ebx
;	mov		ebx,offset buff1[8192]
;	mov		word ptr [ebx-1],0
;	mov		word ptr buff1[4096-1],0
;	mov		narray,0
;	.while TRUE
;		mov		al,[esi]
;		.if al=='"' || al=="'"
;			inc		esi
;			.while al!=[esi] && byte ptr [esi]!=VK_RETURN && byte ptr [esi]
;				inc		esi
;				inc		narray
;			.endw
;			.if al==[esi]
;				inc		esi
;			.endif
;			mov		al,[esi]
;		.elseif al=='<'
;			call	SkipBrace
;			inc		narray
;		.endif
;		mov		ah,[ebx-1]
;		.if al==' ' || al=='+' || al=='-' || al=='*' || al=='/' || al=='(' || al==')' || al==','
;			.if ah==' ' || (al==',' && ah==',')
;				dec		ebx
;			.endif
;		.endif
;		.if al==' '
;			.if ah=='+' || ah=='-' || ah=='*' || ah=='/' || ah=='(' || ah==')' || ah==','
;				mov		al,ah
;				dec		ebx
;			.endif
;		.endif
;		.if al==',' || al==VK_RETURN || !al
;			.if byte ptr [ebx-1]
;				inc		narray
;			.endif
;			mov		ebx,offset buff1[8192]
;			mov		byte ptr [ebx],0
;		  .break .if al==VK_RETURN || !al
;		.else
;			mov		[ebx],al
;			inc		ebx
;		.endif
;		inc		esi
;	.endw
;	mov		byte ptr [ebx],0
;	pop		ebx
;	.if narray>1 || (byte ptr buff1[4096] && narray)
;		.if byte ptr buff1[4096]
;			invoke strcat,addr buff1[4096],addr szAdd
;		.endif
;		invoke DwToAscii,narray,addr buff1[8192+1024]
;		invoke strcat,addr buff1[4096],addr buff1[8192+1024]
;	.endif
;	retn
;
;AddParam:
;	call	GetWord
;	.if ecx
;		mov		len1,ecx
;		mov		lpword1,esi
;		lea		esi,[esi+ecx]
;		push	ecx
;		invoke strcpyn,edi,lpword1,addr [ecx+1]
;		pop		ecx
;		lea		edi,[edi+ecx]
;		call	SkipSpc
;		.if byte ptr [esi]=='['
;			.while byte ptr [esi] && byte ptr [esi-1]!=']'
;				mov		al,[esi]
;				mov		[edi],al
;				inc		esi
;				inc		edi
;			.endw
;			call	SkipSpc
;		.endif
;		mov		byte ptr [edi],':'
;		inc		edi
;		.if byte ptr [esi]==':'
;			inc		esi
;			call	GetWord
;			mov		lendt,ecx
;			mov		lpdt,esi
;			lea		esi,[esi+ecx]
;;			call	ConvDataType
;			mov		ecx,lendt
;			push	ecx
;			invoke strcpyn,edi,lpdt,addr [ecx+1]
;			pop		ecx
;			lea		edi,[edi+ecx]
;			mov		byte ptr [edi],','
;			inc		edi
;		.else
;			invoke strcpy,edi,addr szDword[1]
;			lea		edi,[edi+5]
;			mov		byte ptr [edi],','
;			inc		edi
;		.endif
;		jmp		AddParam
;	.elseif byte ptr [esi]==','
;		inc		esi
;		jmp		AddParam
;	.endif
;	retn
;
;_Proc:
;	mov		edi,offset szname
;	call	SaveWord2
;	mov		buff1,0
;	mov		buff2,0
;	.while byte ptr [esi]
;		call	SkipLine
;		call	GetWord
;		.if ecx
;			mov		len1,ecx
;			mov		lpword1,esi
;			lea		esi,[esi+ecx]
;			invoke FpIsWord,lpword1,len1,offset szfpinproc
;			.if eax==10
;				;arg
;				mov		edi,offset buff1
;				invoke strlen,edi
;				lea		edi,[edi+eax]
;				call	AddParam
;			.elseif eax==11
;				;local
;				mov		edi,offset buff2
;				invoke strlen,edi
;				lea		edi,[edi+eax]
;				call	AddParam
;			.elseif eax==12
;				;endp
;				.break
;			.elseif eax==13
;				;uses
;			.endif
;		.endif
;	.endw
;	invoke strlen,addr buff1
;	.if byte ptr buff1[eax-1]==','
;		mov		byte ptr buff1[eax-1],0
;	.endif
;	invoke strlen,addr buff2
;	.if byte ptr buff2[eax-1]==','
;		mov		byte ptr buff2[eax-1],0
;	.endif
;	;Name
;	mov		edi,offset szname
;	invoke strlen,edi
;	lea		edi,[edi+eax+1]
;	;Parameters
;	invoke strcpy,edi,addr buff1
;	invoke strlen,edi
;	lea		edi,[edi+eax+1]
;	;Return type
;	mov		byte ptr [edi],0
;	inc		edi
;	;Locals
;	invoke strcpy,edi,addr buff2
;	mov		edx,'p'
;	invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,4
;	retn
;
;_Label:
;	mov		edi,offset szname
;	call	SaveWord1
;	mov		edx,'l'
;	invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,1
;	retn
;
_Const:
	mov		edi,offset szname
	call	SaveWord1
	call	SkipSpc
	.while byte ptr [esi] && byte ptr [esi]!=VK_RETURN && byte ptr [esi]!=';'
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
	.if byte ptr [edi-1]==VK_SPACE
		dec		edi
	.endif
	mov		byte ptr [edi],0
	mov		edx,'c'
	invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
	retn

;SaveStructNest:
;	push	ebx
;	xor		ebx,ebx
;	.while ebx<nnest
;		.if lpname[ebx*4]
;			mov		eax,lenname[ebx*4]
;			invoke strcpyn,edi,lpname[ebx*4],addr [eax+1]
;			add		edi,lenname[ebx*4]
;			mov		byte ptr [edi],'.'
;			inc		edi
;		.endif
;		inc		ebx
;	.endw
;	pop		ebx
;	retn
;
;SaveStructItems:
;	xor		eax,eax
;	xor		ecx,ecx
;	mov		nnest,eax
;	.while ecx<8
;		mov		lenname[ecx*4],eax
;		mov		lpname[ecx*4],eax
;		inc		ecx
;	.endw
;	.while byte ptr [esi]
;		call	SkipLine
;		call	GetWord
;		.if ecx
;			mov		len1,ecx
;			mov		lpword1,esi
;			lea		esi,[esi+ecx]
;			invoke FpIsWord,lpword1,len1,addr szfpinstruct
;			.if eax
;				.if eax==10
;					; union, struc, struct
;					call	GetWord
;					.if ecx
;						; named
;						mov		edx,nnest
;						mov		lenname[edx*4],ecx
;						mov		lpname[edx*4],esi
;						lea		esi,[esi+ecx]
;					.endif
;					inc		nnest
;				.elseif eax==11
;					; endu, ends
;					dec		nnest
;					.if SIGN?
;						.break
;					.endif
;					mov		ecx,nnest
;					mov		lenname[ecx*4],0
;					mov		lpname[ecx*4],0
;				.endif
;			.else
;				; struct item
;				call	SaveStructNest
;				; item name
;				call	SaveWord1
;				dec		edi
;				call	GetWord
;				mov		lendt,ecx
;				mov		lpdt,esi
;				lea		esi,[esi+ecx]
;				invoke FpIsWord,lpdt,lendt,addr szfpinstructitem
;				.if eax==10
;					; item rs RECT,2
;					call	GetWord
;					mov		lendt,ecx
;					mov		lpdt,esi
;					lea		esi,[esi+ecx]
;					call	SkipSpc
;					.if byte ptr [esi]==','
;						inc		esi
;						call	GetWord
;						mov		len1,ecx
;						mov		lpword1,esi
;						lea		esi,[esi+ecx]
;						mov		byte ptr [edi],'['
;						inc		edi
;						call	SaveWord1
;						mov		byte ptr [edi-1],']'
;					.endif
;					; item datatype
;					mov		byte ptr [edi],':'
;					inc		edi
;;					call	ConvDataType
;					mov		eax,lendt
;					invoke strcpyn,edi,lpdt,addr [eax+1]
;					add		edi,lendt
;					mov		byte ptr [edi],','
;					inc		edi
;				.elseif eax==11
;					; item RB 10
;					call	GetWord
;					mov		len1,ecx
;					mov		lpword1,esi
;					lea		esi,[esi+ecx]
;					mov		byte ptr [edi],'['
;					inc		edi
;					call	SaveWord1
;					mov		byte ptr [edi-1],']'
;					mov		byte ptr [edi],':'
;					inc		edi
;;					call	ConvDataType
;					mov		eax,lendt
;					invoke strcpyn,edi,lpdt,addr [eax+1]
;					add		edi,lendt
;					mov		byte ptr [edi],','
;					inc		edi
;				.elseif !eax
;					; item datatype ?
;					mov		byte ptr [edi],':'
;					inc		edi
;;					call	ConvDataType
;					mov		eax,lendt
;					invoke strcpyn,edi,lpdt,addr [eax+1]
;					add		edi,lendt
;					mov		byte ptr [edi],','
;					inc		edi
;				.endif
;			.endif
;		.endif
;	.endw
;	.if byte ptr [edi-1]==','
;		dec		edi
;	.endif
;	mov		byte ptr [edi],0
;	retn
;
;_Struct:
;	mov		edi,offset szname
;	call	SaveWord2
;	call	SaveStructItems
;	mov		edx,'s'
;	invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
;	retn
;
_DataType:
	push	esi
	push	npos
	.while byte ptr [esi] && byte ptr [esi]!=':'
		inc		esi
	.endw
	.if byte ptr [esi]==':'
		inc		esi
		call	GetWord
		.if ecx
			mov		lpdt,esi
			mov		lendt,ecx
			pop		npos
			pop		esi
			mov		eax,TRUE
			retn
		.endif
	.endif
	pop		npos
	pop		esi
	xor		eax,eax
	retn

_Data:
	mov		edi,offset szname
	call	SaveWord1
	mov		byte ptr [edi-1],':'
	mov		eax,lendt
	invoke strcpyn,edi,lpdt,addr [eax+1]
	mov		edx,'d'
	invoke AddWordToWordList,edx,nOwner,nline,npos,addr szname,2
	retn

FpParseFile endp
