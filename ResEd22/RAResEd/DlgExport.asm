.data

szNOTStyle			db 'NOT WS_VISIBLE|',0
szNOTStyleHex		db 'NOT 0x10000000|',0
szDupTab			db 0Dh,0Ah,'Duplicate TabIndex',0
szMissTab			db 0Dh,0Ah,'Missing TabIndex',0


.code

SaveCtlSize proc uses ebx edx esi
;	LOCAL	rect:RECT
;	LOCAL	bux:DWORD
;	LOCAL	buy:DWORD
;	LOCAL	fNoChange:DWORD

	assume esi:ptr DIALOG
;	mov		eax,[esi].dux
;	or		eax,[esi].duy
;	or		eax,[esi].duccx
;	or		eax,[esi].duccy
;	mov		fNoChange,eax
;	mov		eax,[esi].ntype
;	.if !eax
;		mov		rect.left,eax
;		mov		rect.top,eax
;		mov		rect.right,eax
;		mov		rect.bottom,eax
;		.if ![esi].DIALOG.ntype
;			invoke AdjustWindowRectEx,addr rect,[esi].style,FALSE,[esi].exstyle
;		.endif
;		mov		eax,[esi].ccx
;		sub		eax,rect.right
;		add		eax,rect.left
;		mov		rect.right,eax
;		mov		rect.left,0		
;		mov		eax,[esi].ccy
;		sub		eax,rect.bottom
;		add		eax,rect.top
;		mov		rect.bottom,eax
;		mov		rect.top,0		
;	.else
;		push	[esi].ccx
;		pop		rect.right
;		push	[esi].ccy
;		pop		rect.bottom
;	.endif
;	invoke GetDialogBaseUnits
;	mov		edx,eax
;	and		eax,0FFFFh
;	mov		bux,eax
;	shr		edx,16
;	mov		buy,edx
;
;	mov		eax,[esi].x
;	shl		eax,2
;	mov		ebx,dfntwt
;	imul	ebx
;	cdq
;	mov		ebx,bux
;	idiv	ebx
;	cdq
;	mov		ebx,fntwt
;	idiv	ebx
;	.if fNoChange
		mov		eax,[esi].dux
;	.endif
	invoke SaveVal,eax,TRUE

;	mov		eax,[esi].y
;	shl		eax,3
;	mov		ebx,dfntht
;	mul		ebx
;	cdq
;	mov		ebx,buy
;	idiv	ebx
;
;	cdq
;	mov		ebx,fntht
;	idiv	ebx
;	.if fNoChange
		mov		eax,[esi].duy
;	.endif
	invoke SaveVal,eax,TRUE

;	mov		eax,rect.right
;	shl		eax,2+9
;	mov		ebx,dfntwt
;	mul		ebx
;	xor		edx,edx
;	mov		ebx,bux
;	idiv	ebx
;
;	xor		edx,edx
;	mov		ebx,fntwt
;	idiv	ebx
;	shr		eax,9
;	.if fNoChange
		mov		eax,[esi].duccx
;	.endif
	invoke SaveVal,eax,TRUE

;	mov		eax,rect.bottom
;	shl		eax,3+9
;	mov		ebx,dfntht
;	mul		ebx
;	xor		edx,edx
;	mov		ebx,buy
;	idiv	ebx
;	xor		edx,edx
;	mov		ebx,fntht
;	idiv	ebx
;	shr		eax,9
;	.if fNoChange
		mov		eax,[esi].duccy
;	.endif
	invoke SaveVal,eax,FALSE
	assume esi:nothing
	ret

SaveCtlSize endp

SaveType proc uses edx esi edi

	invoke GetTypePtr,[esi].DIALOG.ntype
	mov		edx,eax
	invoke SaveStr,edi,[edx].TYPES.lprc
	ret

SaveType endp

SaveName proc uses esi edi
	LOCAL	buffer[16]:BYTE

	assume esi:ptr DIALOG
	mov		al,[esi].idname
	.if al
		invoke SaveStr,edi,addr [esi].idname
	.else
		invoke ResEdBinToDec,[esi].id,addr buffer
		invoke SaveStr,edi,addr buffer
	.endif
	assume esi:nothing
	ret

SaveName endp

SaveDefine proc
	LOCAL	buffer[16]:BYTE

	assume esi:ptr DIALOG
	;Is ctl deleted
	mov		eax,[esi].hwnd
	.if eax!=-1
		mov		al,[esi].idname
		.if al && [esi].id
			invoke strcmpi,addr [esi].idname,addr szIDOK
			.if eax
				invoke strcmpi,addr [esi].idname,addr szIDCANCEL
				.if eax
					invoke strcmpi,addr [esi].idname,addr szIDC_STATIC
					.if !eax
						invoke GetWindowLong,hRes,GWL_STYLE
						test	eax,DES_DEFIDC_STATIC
						.if !ZERO?
							invoke GetWindowLong,hPrj,0
							mov		edx,eax
							push	eax
							invoke FindName,edx,addr szIDC_STATIC
							pop		edx
							.if !eax
								invoke AddName,edx,addr szIDC_STATIC,addr szIDC_STATICValue
							.endif
						.endif
						xor		eax,eax
					.endif
				.endif
			.endif
			.if eax
				invoke SaveStr,edi,addr szDEFINE
				add		edi,eax
				mov		al,' '
				stosb
				invoke SaveStr,edi,addr [esi].idname
				add		edi,eax
				mov		al,' '
				stosb
				invoke ResEdBinToDec,[esi].id,addr buffer
				invoke SaveStr,edi,addr buffer
				add		edi,eax
				mov		ax,0A0Dh
				stosw
			.endif
		.endif
	.endif
	assume esi:nothing
	ret

SaveDefine endp

SaveCaption proc

	assume esi:ptr DIALOG
	mov		al,22h
	stosb
	lea		edx,[esi].caption
  @@:
	mov		al,[edx]
	.if al=='"'
		mov		[edi],al
		inc		edi
	.endif
	mov		[edi],al
	inc		edx
	inc		edi
	or		al,al
	jne		@b
	dec		edi
	mov		al,22h
	stosb
	assume esi:nothing
	ret

SaveCaption endp

SaveClass proc
	LOCAL	lpclass:DWORD

	assume esi:ptr DIALOG
	invoke GetTypePtr,[esi].ntype
	push	(TYPES ptr [eax]).lpclass
	pop		lpclass

	mov		al,22h
	stosb
	invoke SaveStr,edi,lpclass
	add		edi,eax
	mov		al,22h
	stosb
	assume esi:nothing
	ret

SaveClass endp

SaveUDCClass proc

	assume esi:ptr DIALOG

	mov		al,22h
	stosb
	invoke SaveStr,edi,addr [esi].class
	add		edi,eax
	mov		al,22h
	stosb
	assume esi:nothing
	ret

SaveUDCClass endp

SaveDlgClass proc

	mov		al,[esi].DLGHEAD.class
	.if al
		invoke SaveStr,edi,addr szCLASS
		add		edi,eax
		mov		al,' '
		stosb
		mov		al,22h
		stosb
		invoke SaveStr,edi,addr [esi].DLGHEAD.class
		add		edi,eax
		mov		al,22h
		stosb
		mov		ax,0A0Dh
		stosw
	.endif
	ret

SaveDlgClass endp

SaveDlgFont proc
	LOCAL	buffer[512]:BYTE
	LOCAL	val:DWORD

	mov		al,[esi].DLGHEAD.font
	.if al
		invoke SaveStr,edi,addr szFONT
		add		edi,eax
		mov		al,' '
		stosb
		push	[esi].DLGHEAD.fontsize
		pop		val
		invoke ResEdBinToDec,val,addr buffer
		invoke SaveStr,edi,addr buffer
		add		edi,eax
		mov		al,','
		stosb
		mov		al,22h
		stosb
		invoke SaveStr,edi,addr [esi].DLGHEAD.font
		add		edi,eax
		mov		ax,',"'
		stosw
		movzx	eax,[esi].DLGHEAD.weight
		mov		val,eax
		invoke ResEdBinToDec,val,addr buffer
		invoke SaveStr,edi,addr buffer
		add		edi,eax
		mov		al,','
		stosb
		movzx	eax,[esi].DLGHEAD.italic
		mov		val,eax
		invoke ResEdBinToDec,val,addr buffer
		invoke SaveStr,edi,addr buffer
		add		edi,eax
		invoke GetWindowLong,hRes,GWL_STYLE
		test	eax,DES_BORLAND
		.if ZERO?
			movzx	eax,[esi].DLGHEAD.charset
			mov		val,eax
			mov		al,','
			stosb
			invoke ResEdBinToDec,val,addr buffer
			invoke SaveStr,edi,addr buffer
			add		edi,eax
		.endif
		mov		ax,0A0Dh
		stosw
	.endif
	ret

SaveDlgFont endp

SaveDlgMenu proc

	mov		al,[esi].DLGHEAD.menuid
	.if al
		invoke SaveStr,edi,addr szMENU
		add		edi,eax
		mov		al,' '
		stosb
		invoke SaveStr,edi,addr [esi].DLGHEAD.menuid
		add		edi,eax
		mov		ax,0A0Dh
		stosw
	.endif
	ret

SaveDlgMenu endp

SaveStyle proc uses ebx esi,nStyle:DWORD,nType:DWORD,fComma:DWORD
	LOCAL	nst:DWORD
	LOCAL	ncount:DWORD
	LOCAL	npos:DWORD

	.if fStyleHex
		invoke SaveHexVal,nStyle,fComma
	.else
		mov		nst,0
		mov		ncount,0
		mov		[npos],edi
		push	edi
		mov		dword ptr namebuff,0
		mov		ebx,offset types
		mov		eax,nType
		.while eax!=[ebx].RSTYPES.ctlid && [ebx].RSTYPES.ctlid!=-1
			lea		ebx,[ebx+sizeof RSTYPES]
		.endw
		.if byte ptr [ebx].RSTYPES.style1
			lea		esi,[ebx].RSTYPES.style1
			call	AddStyles
		.endif
		.if byte ptr [ebx].RSTYPES.style2
			lea		esi,[ebx].RSTYPES.style2
			call	AddStyles
		.endif
		.if byte ptr [ebx].RSTYPES.style3
			lea		esi,[ebx].RSTYPES.style3
			call	AddStyles
		.endif
		pop		edi
		invoke strcpy,edi,offset namebuff+1
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		eax,nst
		.if eax!=nStyle
			.if ncount
				mov		byte ptr [edi],'|'
				inc		edi
			.endif
			xor		eax,nStyle
			invoke SaveHexVal,eax,fComma
		.elseif fComma
			mov		al,','
			stosb
		.endif
	.endif
	ret

Compare:
	xor		eax,eax
	xor		ecx,ecx
	.while byte ptr [esi+ecx]
		mov		al,[esi+ecx]
		sub		al,[edi+ecx+8]
		.break .if eax
		inc		ecx
	.endw
	retn

AddStyles:
	.if [ebx].RSTYPES.ctlid
		mov		edi,offset srtstyledef
	.else
		mov		edi,offset srtstyledefdlg
	.endif
	mov		edx,nStyle
	.while dword ptr [edi]
		push	edi
		mov		edi,[edi]
		push	edx
		call	Compare
		pop		edx
		.if !eax
			mov		eax,edx
			and		eax,[edi+4]
			.if eax==[edi] && eax
				xor		ecx,ecx
				.if nType==1
					push	eax
					push	edx
					invoke IsNotStyle,addr [edi+8],offset editnot
					mov		ecx,eax
					pop		edx
					pop		eax
				.elseif nType==22
					push	eax
					push	edx
					invoke IsNotStyle,addr [edi+8],offset richednot
					mov		ecx,eax
					pop		edx
					pop		eax
				.endif
				.if !ecx
					or		nst,eax
					inc		ncount
					xor		edx,eax
					push	edx
					invoke strcat,offset namebuff,offset szOR
					invoke strcat,offset namebuff,addr [edi+8]
					pop		edx
				.endif
			.endif
		.endif
		pop		edi
		lea		edi,[edi+4]
	.endw
	retn

SaveStyle endp

SaveExStyle proc uses ebx esi,nExStyle:DWORD
	LOCAL	buffer1[8]:BYTE
	LOCAL	nst:DWORD
	LOCAL	ncount:DWORD
	LOCAL	npos:DWORD

	.if fStyleHex
		invoke SaveHexVal,nExStyle,FALSE
	.else
		mov		nst,0
		mov		ncount,0
		mov		[npos],edi
		mov		dword ptr buffer1,'E_SW'
		mov		dword ptr buffer1[4],'_X'
		push	edi
		mov		dword ptr namebuff,0
		lea		esi,buffer1
		call	AddStyles
		pop		edi
		invoke strcpy,edi,offset namebuff+1
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		eax,nst
		.if eax!=nExStyle
			.if ncount
				mov		byte ptr [edi],'|'
				inc		edi
			.endif
			xor		eax,nExStyle
			invoke SaveHexVal,eax,FALSE
		.endif
	.endif
	ret

Compare:
	xor		eax,eax
	xor		ecx,ecx
	.while byte ptr [esi+ecx]
		mov		al,[esi+ecx]
		sub		al,[edi+ecx+8]
		.break .if eax
		inc		ecx
	.endw
	retn

AddStyles:
	mov		edi,offset srtexstyledef
	mov		edx,nExStyle
	.while dword ptr [edi]
		push	edi
		mov		edi,[edi]
		push	edx
		call	Compare
		pop		edx
		.if !eax
			mov		eax,edx
			and		eax,[edi+4]
			.if eax==[edi] && eax
				or		nst,eax
				inc		ncount
				xor		edx,eax
				push	edx
				invoke strcat,offset namebuff,offset szOR
				invoke strcat,offset namebuff,addr [edi+8]
				pop		edx
			.endif
		.endif
		pop		edi
		lea		edi,[edi+4]
	.endw
	retn

SaveExStyle endp

SaveCtl proc uses ebx esi edi
	LOCAL	buffer[512]:BYTE

	assume esi:ptr DIALOG
	;Is ctl deleted
	mov		eax,[esi].hwnd
	.if eax!=-1
		mov		eax,[esi].ntype
		.if eax==0
			;Dialog
			invoke SaveName
			add		edi,eax
			mov		al,' '
			stosb
			invoke SaveType
			add		edi,eax
			mov		al,' '
			stosb
			invoke SaveCtlSize
			mov		edx,[esi].helpid
			.if edx
				mov		al,','
				stosb
				invoke ResEdBinToDec,edx,addr buffer
				invoke SaveStr,edi,addr buffer
				add		edi,eax
			.endif
			mov		eax,0A0Dh
			stosw
			mov		al,[esi].caption
			.if al
				invoke SaveStr,edi,addr szCAPTION
				add		edi,eax
				mov		al,20h
				stosb
				invoke SaveCaption
				mov		ax,0A0Dh
				stosw
			.endif
			;These are stored in DLGHEAD
			sub		esi,sizeof DLGHEAD
			invoke SaveDlgFont
			invoke SaveDlgClass
			mov		eax,esi
			.if byte ptr [eax].DLGHEAD.menuid
				invoke SaveDlgMenu
			.endif
			add		esi,sizeof DLGHEAD
			;This is stored in DLGHEAD
			sub		esi,sizeof DLGHEAD
			mov		eax,esi
			.if [eax].DLGHEAD.lang || [eax].DLGHEAD.sublang
				invoke SaveLanguage,addr [eax].DLGHEAD.lang,edi
				add		edi,eax
			.endif
			add		esi,sizeof DLGHEAD
			invoke SaveStr,edi,addr szSTYLE
			add		edi,eax
			mov		al,' '
			stosb
			mov		eax,[esi].style
			and		eax,dwNOTStyle
			xor		eax,dwNOTStyle
			.if eax
				.if fStyleHex
					invoke SaveStr,edi,addr szNOTStyleHex
				.else
					invoke SaveStr,edi,addr szNOTStyle
				.endif
				add		edi,eax
			.endif
			invoke SaveStyle,[esi].style,[esi].ntype,FALSE
			mov		ax,0A0Dh
			stosw
			.if [esi].exstyle
				invoke SaveStr,edi,addr szEXSTYLE
				add		edi,eax
				mov		al,' '
				stosb
				invoke SaveExStyle,[esi].exstyle
				mov		ax,0A0Dh
				stosw
			.endif
			invoke SaveStr,edi,addr szBEGIN
			add		edi,eax
			mov		ax,0A0Dh
			stosw
		.elseif eax==23
			;UserDefinedControl
			mov		ax,'  '
			stosw
			invoke SaveType
			add		edi,eax
			mov		al,' '
			stosb
			;Caption
			invoke SaveCaption
			mov		al,','
			stosb
			invoke SaveName
			add		edi,eax
			mov		al,','
			stosb
			;Class
			invoke SaveUDCClass
			mov		al,','
			stosb
			mov		eax,[esi].style
			and		eax,dwNOTStyle
			xor		eax,dwNOTStyle
			.if eax
				invoke SaveStr,edi,addr szNOTStyle
				add		edi,eax
			.endif
			invoke SaveStyle,[esi].style,[esi].ntype,TRUE
			invoke SaveCtlSize
			.if [esi].exstyle || [esi].helpid
				mov		al,','
				stosb
				.if [esi].exstyle
					invoke SaveExStyle,[esi].exstyle
				.endif
				.if [esi].helpid
					mov		al,','
					stosb
					invoke ResEdBinToDec,[esi].helpid,addr buffer
					invoke SaveStr,edi,addr buffer
					add		edi,eax
				.endif
			.endif
			mov		ax,0A0Dh
			stosw
		.else
			;Control
			push	eax
			mov		ax,'  '
			stosw
			invoke SaveType
			add		edi,eax
			mov		al,' '
			stosb
			pop		eax
			.if eax==17 || eax==27
				.if byte ptr [esi].caption=='#'
					; "#100"
					invoke SaveCaption
				.elseif  byte ptr [esi].caption>='0' && byte ptr [esi].caption<='9'
					; 100
					invoke SaveStr,edi,addr [esi].caption
					add		edi,eax
				.else
					xor		ebx,ebx
					.if byte ptr [esi].caption
						invoke GetWindowLong,hPrj,0
						invoke GetTypeMem,eax,TPE_RESOURCE
						.if [eax].PROJECT.hmem
							push	edi
							mov		edi,[eax].PROJECT.hmem
							.while byte ptr [edi].RESOURCEMEM.szname || [edi].RESOURCEMEM.value
								invoke strcmp,addr [edi].RESOURCEMEM.szname,addr [esi].caption
								.if !eax
									.if [edi].RESOURCEMEM.value
										; IDI_ICON
										pop		edi
										invoke SaveStr,edi,addr [esi].caption
										add		edi,eax
										push	edi
									.else
										; "IDI_ICON"
										pop		edi
										invoke SaveCaption
										push	edi
									.endif
									inc		ebx
									.break
								.endif
								add		edi,sizeof RESOURCEMEM
							.endw
							pop		edi
						.endif
					.endif
					.if !ebx
						invoke SaveCaption
					.endif
				.endif
			.else
				invoke SaveCaption
			.endif
			mov		al,','
			stosb
			invoke SaveName
			add		edi,eax
			mov		al,','
			stosb
			invoke SaveClass
			mov		al,','
			stosb
			mov		eax,[esi].style
			and		eax,dwNOTStyle
			xor		eax,dwNOTStyle
			.if eax
				.if fStyleHex
					invoke SaveStr,edi,addr szNOTStyleHex
				.else
					invoke SaveStr,edi,addr szNOTStyle
				.endif
				add		edi,eax
			.endif
			invoke SaveStyle,[esi].style,[esi].ntype,TRUE
			invoke SaveCtlSize
			.if [esi].exstyle || [esi].helpid
				mov		al,','
				stosb
				.if [esi].exstyle
					invoke SaveExStyle,[esi].exstyle
				.endif
				.if [esi].helpid
					mov		al,','
					stosb
					invoke ResEdBinToDec,[esi].helpid,addr buffer
					invoke SaveStr,edi,addr buffer
					add		edi,eax
				.endif
			.endif
			mov		ax,0A0Dh
			stosw
		.endif
	.endif
	mov		eax,edi
	assume esi:nothing
	ret

SaveCtl endp

ExportDialogNames proc uses ebx esi edi,hMem:DWORD

	mov		esi,hMem
	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
	mov		edi,eax
	invoke GlobalLock,edi
	push	edi
	.if [esi].DLGHEAD.ftextmode
		invoke SendMessage,[esi].DLGHEAD.hred,EM_GETMODIFY,0,0
		.if eax
			invoke GetWindowLong,hPrj,0
			mov		ebx,eax
			.while esi!=[ebx].PROJECT.hmem
				add		ebx,sizeof PROJECT
			.endw
			mov		[ebx].PROJECT.hmem,0
			push	[esi].DLGHEAD.hred
			push	[esi].DLGHEAD.ftextmode
			invoke SaveToMem,[esi].DLGHEAD.hred,edi
			invoke GetWindowLong,hPrj,0
			invoke ParseRCMem,edi,eax
			.if fParseError
				.if [ebx].PROJECT.hmem
					invoke GlobalUnlock,[ebx].PROJECT.hmem
					invoke GlobalFree,[ebx].PROJECT.hmem
				.endif
				mov		[ebx].PROJECT.hmem,esi
				pop		eax
				pop		eax
			.else
				invoke GetWindowLong,hDEd,DEWM_MEMORY
				.if eax==esi
;					invoke DestroySizeingRect
					invoke DestroyWindow,[esi+sizeof DLGHEAD].DIALOG.hwnd
;					.if [esi].DLGHEAD.hfont
;						invoke DeleteObject,[esi].DLGHEAD.hfont
;						mov		[esi].DLGHEAD.hfont,0
;					.endif
					invoke SetWindowLong,hDEd,DEWM_MEMORY,0
					invoke SetWindowLong,hDEd,DEWM_DIALOG,0
					invoke SetWindowLong,hDEd,DEWM_PROJECT,0
					invoke GlobalUnlock,esi
					invoke GlobalFree,esi
;					invoke CreateDlg,hDEd,ebx,TRUE
				.endif
				mov		esi,[ebx].PROJECT.hmem
				mov		hMem,esi
				pop		[esi].DLGHEAD.ftextmode
				pop		[esi].DLGHEAD.hred
				invoke SendMessage,[esi].DLGHEAD.hred,EM_SETMODIFY,FALSE,0
			.endif
		.endif
	.endif
	mov		esi,hMem
	add		esi,sizeof DLGHEAD
  @@:
	invoke SaveDefine
	add		esi,size DIALOG
	mov		eax,[esi]
	or		eax,eax
	jne		@b
	mov		byte ptr [edi],0
	pop		eax
	ret

ExportDialogNames endp

VerifyTebIndex proc uses esi,hMem:DWORD
	LOCAL	tab[1024]:BYTE
	LOCAL	maxtab:DWORD
	LOCAL	szerr[256]:BYTE

	mov		maxtab,-1
	invoke RtlZeroMemory,addr tab,sizeof tab
	mov		esi,hMem
	add		esi,sizeof DLGHEAD
	invoke strcpy,addr szerr,addr [esi].DIALOG.idname
	add		esi,sizeof DIALOG
	.while [esi].DIALOG.hwnd
		.if [esi].DIALOG.hwnd!=-1
			mov		eax,[esi].DIALOG.tab
			.if sdword ptr eax>maxtab
				mov		maxtab,eax
			.endif
			inc		byte ptr tab[eax]
		.endif
		add		esi,sizeof DIALOG
	.endw
	.if maxtab!=-1
		xor		ecx,ecx
		.while ecx<=maxtab
			push	ecx
			.if byte ptr tab[ecx]>1
				invoke strcat,addr szerr,addr szDupTab
				invoke MessageBox,hDEd,addr szerr,addr szToolTip,MB_ICONERROR or MB_OK
				pop		ecx
				.break
			.elseif byte ptr tab[ecx]==0
				invoke strcat,addr szerr,addr szMissTab
				invoke MessageBox,hDEd,addr szerr,addr szToolTip,MB_ICONERROR or MB_OK
				pop		ecx
				.break
			.endif
			pop		ecx
			inc		ecx
		.endw
	.endif
	ret

VerifyTebIndex endp

ExportDialog proc uses esi edi,hRdMem:DWORD
	LOCAL	hWrMem:DWORD
	LOCAL	nTab:DWORD
	LOCAL	nMiss:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
	mov		hWrMem,eax
	invoke GlobalLock,hWrMem
	mov		esi,hRdMem
	invoke VerifyTebIndex,esi
	mov		dlgps,10
	mov		dlgfn,0
;	invoke CreateDialogIndirectParam,hInstance,offset dlgdata,hDEd,offset TestProc,0
	invoke DestroyWindow,eax
	push	fntwt
	pop		dfntwt
	push	fntht
	pop		dfntht
	mov		eax,[esi].DLGHEAD.fontsize
	mov		dlgps,ax
	pushad
	lea		esi,[esi].DLGHEAD.font
	mov		edi,offset dlgfn
	xor		eax,eax
	mov		ecx,32
  @@:
	lodsb
	stosw
	loop	@b
	popad
;	invoke CreateDialogIndirectParam,hInstance,offset dlgdata,hDEd,offset TestProc,0
	invoke DestroyWindow,eax
	mov		edi,hWrMem
	mov		esi,hRdMem
	add		esi,sizeof DLGHEAD
	invoke SaveCtl
	mov		edi,eax
	add		esi,sizeof DIALOG
	mov		nTab,0
	mov		nMiss,0
  @@:
	invoke FindTab,nTab,hRdMem
	.if eax
		mov		esi,edx
		invoke SaveCtl
		mov		edi,eax
		inc		nTab
		mov		nMiss,0
		jmp		@b
	.else
		.if nMiss<10
			inc		nMiss
			inc		nTab
			jmp		@b
		.endif
	.endif
	invoke SaveStr,edi,addr szEND
	add		edi,eax
	mov		eax,0A0Dh
	stosw
	stosd
	mov		eax,hWrMem
	ret

ExportDialog endp

