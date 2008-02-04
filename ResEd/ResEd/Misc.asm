.code

xGlobalAlloc proc fFlags:DWORD,nSize:DWORD

	invoke GlobalAlloc,fFlags,nSize
	.if !eax
		invoke MessageBox,hWnd,addr szMemFail,addr szAppName,MB_OK or MB_ICONERROR
		xor		eax,eax
	.endif
	ret

xGlobalAlloc endp

DwToAscii proc uses ebx esi edi,dwVal:DWORD,lpAscii:DWORD

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
	ret

DwToAscii endp

MakeKey proc lpszStr:DWORD,nInx:DWORD,lpszKey:DWORD

	invoke lstrcpy,lpszKey,lpszStr
	invoke lstrlen,lpszKey
	add		eax,lpszKey
	invoke DwToAscii,nInx,eax
	ret

MakeKey endp

ParseCmnd proc uses esi edi,lpStr:DWORD,lpCmnd:DWORD,lpParam:DWORD

	mov		esi,lpStr
	call	SkipSpc
	mov		edi,lpCmnd
	mov		al,[esi]
	.if al=='"'
		inc		esi
		call	CopyQuoted
	.else
		call	CopyToSpace
	.endif
	call	SkipSpc
	mov		edi,lpParam
	mov		al,[esi]
	.if al=='"'
		inc		esi
		call	CopyQuoted
	.else
		call	CopyAll
	.endif
	ret

SkipSpc:
	.while byte ptr [esi]==' '
		inc		esi
	.endw
	retn

CopyQuoted:
	mov		al,[esi]
	.if al
		inc		esi
		.if al!='"'
			.if al=='$'
				call	CopyPro
			.else
				mov		[edi],al
				inc		edi
				jmp		CopyQuoted
			.endif
		.endif
		xor		al,al
	.endif
	mov		[edi],al
	retn

CopyToSpace:
	mov		al,[esi]
	.if al
		inc		esi
		.if al!=' '
			.if al=='$'
				call	CopyPro
			.else
				mov		[edi],al
				inc		edi
				jmp		CopyToSpace
			.endif
		.endif
		xor		al,al
	.endif
	mov		[edi],al
	retn

CopyAll:
	mov		al,[esi]
	.if al
		inc		esi
		.if al=='$'
			call	CopyPro
		.else
			mov		[edi],al
			inc		edi
			jmp		CopyAll
		.endif
		xor		al,al
	.endif
	mov		[edi],al
	retn

CopyPro:
	push	esi
	mov		esi,offset ProjectFileName
	.while al!='.' && al
		mov		al,[esi]
		.if al!='.' && al
			mov		[edi],al
			inc		esi
			inc		edi
		.endif
	.endw
	pop		esi
	.while byte ptr [esi]
		mov		al,[esi]
		.if al!='"'
			mov		[edi],al
		.endif
		inc		esi
		inc		edi
	.endw
	xor		al,al
	mov		[edi],al
	retn

ParseCmnd endp

SetupMenu proc uses ebx esi edi,hSubMnu:HMENU
	LOCAL	nPos:DWORD
	LOCAL	mii:MENUITEMINFO
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		nPos,0
	mov		mii.cbSize,sizeof MENUITEMINFO
	mov		mii.fMask,MIIM_DATA or MIIM_ID or MIIM_SUBMENU or MIIM_TYPE
  @@:
	lea		eax,buffer
	mov		word ptr [eax],0
	mov		mii.dwTypeData,eax
	mov		mii.cch,sizeof buffer
	invoke GetMenuItemInfo,hSubMnu,nPos,TRUE,addr mii
	.if eax
		mov		edi,offset mnubuff
		add		edi,mnupos
		mov		mii.dwItemData,edi
		test	mii.fType,MFT_SEPARATOR
		.if ZERO?
			invoke SendMessage,hTbr,TB_COMMANDTOINDEX,mii.wID,0
			.if sdword ptr eax>=0
				invoke SendMessage,hTbr,TB_GETBITMAP,mii.wID,0
				inc		eax
				mov		[edi].MENUDATA.img,eax
			.endif
			mov		[edi].MENUDATA.tpe,0
			mov		eax,mii.fType
			and		eax,7Fh
			.if eax==MFT_STRING
				lea		esi,buffer
				mov		ecx,sizeof MENUDATA
				xor		edx,edx
				.while byte ptr [esi]
					mov		al,[esi]
					.if al==VK_TAB
						mov		al,0
						inc		edx
					.endif
					mov		[edi+ecx],al
					inc		ecx
					inc		esi
				.endw
				mov		al,0
				mov		[edi+ecx],al
				inc		ecx
				mov		[edi+ecx],al
				inc		ecx
				add		mnupos,ecx
			.else
				mov		[edi].MENUDATA.img,0
				mov		[edi].MENUDATA.tpe,0
				mov		word ptr [edi+sizeof MENUDATA],0
				add		mnupos,sizeof MENUDATA+2
			.endif
		.else
			; Separator
			mov		[edi].MENUDATA.img,0
			mov		[edi].MENUDATA.tpe,1
			add		mnupos,sizeof MENUDATA
		.endif
		or		mii.fType,MFT_OWNERDRAW
		invoke SetMenuItemInfo,hSubMnu,nPos,TRUE,addr mii
		.if mii.hSubMenu
			invoke SetupMenu,mii.hSubMenu
		.endif
		inc		nPos
		jmp		@b
	.endif
	ret

SetupMenu endp

MakeMenuBitmap proc wt:DWORD,nColor:DWORD
	LOCAL	hBmp:HBITMAP
	LOCAL	hOldBmp:HBITMAP
	LOCAL	hDC:HDC
	LOCAL	mDC:HDC
	LOCAL	hDeskTop:HWND

	invoke GetDesktopWindow
	mov		hDeskTop,eax
	invoke GetDC,hDeskTop
	mov		hDC,eax
	invoke CreateCompatibleDC,hDC
	mov		mDC,eax
	invoke CreateCompatibleBitmap,hDC,600,8
	mov		hBmp,eax
	invoke ReleaseDC,hDeskTop,hDC
	invoke SelectObject,mDC,hBmp
	mov		hOldBmp,eax
	xor		ebx,ebx
	.while ebx<8
		xor		edi,edi
		mov		esi,nColor
		.while edi<wt
			invoke SetPixel,mDC,edi,ebx,esi
			sub		esi,040404h
			inc		edi
		.endw
		.while edi<600
			invoke SetPixel,mDC,edi,ebx,0FFFFFFh
			inc		edi
		.endw
		inc		ebx
	.endw
	invoke SelectObject,mDC,hOldBmp
	invoke DeleteDC,mDC
	mov		eax,hBmp
	ret

MakeMenuBitmap endp

CoolMenu proc
	LOCAL	MInfo:MENUINFO
	LOCAL	nInx:DWORD
	LOCAL	hBmp:HBITMAP
	LOCAL	hBr:HBRUSH
	LOCAL	ncm:NONCLIENTMETRICS

	; Get menu font
	mov		ncm.cbSize,sizeof NONCLIENTMETRICS
	invoke SystemParametersInfo,SPI_GETNONCLIENTMETRICS,sizeof NONCLIENTMETRICS,addr ncm,0
	invoke CreateFontIndirect,addr ncm.lfMenuFont
	mov		hMnuFont,eax
	invoke MakeMenuBitmap,23,0FFCEBEh
	mov		hBmp,eax
	invoke CreatePatternBrush,hBmp
	mov		hMenuBrushA,eax
	mov		MInfo.hbrBack,eax
	invoke DeleteObject,hBmp
	mov		MInfo.cbSize,SizeOf MENUINFO
	mov		MInfo.fmask,MIM_BACKGROUND or MIM_APPLYTOSUBMENUS
	invoke MakeMenuBitmap,20,0FFCEBEh-0C0C0Ch
	mov		hBmp,eax
	invoke CreatePatternBrush,hBmp
	mov		hMenuBrushB,eax
	invoke DeleteObject,hBmp
	mov		nInx,0
  @@:
	invoke GetSubMenu,hMnu,nInx
	.if eax
		mov		edx,eax
		push	eax
		invoke SetupMenu,eax
		pop		edx
		invoke SetMenuInfo,edx,addr MInfo
		inc		nInx
		jmp		@b
	.endif
	mov		nInx,0
  @@:
	invoke GetSubMenu,hContextMenu,nInx
	.if eax
		push	eax
		invoke SetupMenu,eax
		pop		edx
		invoke SetMenuInfo,edx,addr MInfo
		inc		nInx
		jmp		@b
	.endif
	ret

CoolMenu endp

