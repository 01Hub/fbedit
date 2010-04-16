.code

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

DecToBin proc lpStr:DWORD
	LOCAL	fNeg:DWORD

    push    ebx
    push    esi
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
    pop     esi
    pop     ebx
    ret

DecToBin endp

BinToDec proc dwVal:DWORD,lpAscii:DWORD
	LOCAL	buffer[8]:BYTE

	mov		dword ptr buffer,'d%'
	invoke wsprintf,lpAscii,addr buffer,dwVal
	ret

;    push    ebx
;    push    ecx
;    push    edx
;    push    esi
;    push    edi
;	mov		eax,dwVal
;	mov		edi,lpAscii
;	or		eax,eax
;	jns		pos
;	mov		byte ptr [edi],'-'
;	neg		eax
;	inc		edi
;  pos:      
;	mov		ecx,429496730
;	mov		esi,edi
;  @@:
;	mov		ebx,eax
;	mul		ecx
;	mov		eax,edx
;	lea		edx,[edx*4+edx]
;	add		edx,edx
;	sub		ebx,edx
;	add		bl,'0'
;	mov		[edi],bl
;	inc		edi
;	or		eax,eax
;	jne		@b
;	mov		byte ptr [edi],al
;	.while esi<edi
;		dec		edi
;		mov		al,[esi]
;		mov		ah,[edi]
;		mov		[edi],al
;		mov		[esi],ah
;		inc		esi
;	.endw
;    pop     edi
;    pop     esi
;    pop     edx
;    pop     ecx
;    pop     ebx
;    ret

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
		invoke strcpy,edi,esi
		pop		eax
	.else
		mov		eax,nDefVal
	.endif
	ret

GetItemInt endp

PutItemInt proc uses esi edi,lpBuff:DWORD,nVal:DWORD

	mov		esi,lpBuff
	invoke strlen,esi
	mov		byte ptr [esi+eax],','
	invoke BinToDec,nVal,addr [esi+eax+1]
	ret

PutItemInt endp

GetItemStr proc uses esi edi,lpBuff:DWORD,lpDefVal:DWORD,lpResult

	mov		esi,lpBuff
	.if byte ptr [esi]
		mov		edi,esi
		.while byte ptr [esi] && byte ptr [esi]!=','
			inc		esi
		.endw
		lea		eax,[esi+1]
		sub		eax,edi
		invoke strcpyn,lpResult,edi,eax
		.if byte ptr [esi]
			inc		esi
		.endif
		invoke strcpy,edi,esi
	.else
		invoke strcpy,lpResult,lpDefVal
	.endif
	ret

GetItemStr endp

PutItemStr proc uses esi,lpBuff:DWORD,lpStr:DWORD

	mov		esi,lpBuff
	invoke strlen,esi
	mov		byte ptr [esi+eax],','
	invoke strcpy,addr [esi+eax+1],lpStr
	ret

PutItemStr endp

UpdateAll proc uses ebx esi edi,nFunction:DWORD,lParam:DWORD
	LOCAL	nInx:DWORD
	LOCAL	tci:TC_ITEM

	invoke SendMessage,ha.hTab,TCM_GETITEMCOUNT,0,0
	mov		nInx,eax
	mov		tci.imask,TCIF_PARAM
	.while nInx
		dec		nInx
		invoke SendMessage,ha.hTab,TCM_GETITEM,nInx,addr tci
		.if eax
			mov		ebx,tci.lParam
			mov		eax,nFunction
			.if eax==UAM_ISOPEN
				invoke lstrcmpi,lParam,addr [ebx].TABMEM.filename
				.if !eax
					mov		eax,[ebx].TABMEM.hwnd
					jmp		Ex
				.endif
			.elseif eax==UAM_ISOPENACTIVATE
				invoke lstrcmpi,lParam,addr [ebx].TABMEM.filename
				.if !eax
					invoke SendMessage,ha.hTab,TCM_SETCURSEL,nInx,0
					invoke TabToolActivate
					mov		eax,[ebx].TABMEM.hwnd
					jmp		Ex
				.endif
			.elseif eax==UAM_ISRESOPEN
				invoke GetWindowLong,[ebx].TABMEM.hedt,GWL_ID
				.if eax==ID_EDITRES
					mov		eax,[ebx].TABMEM.hwnd
					jmp		Ex
				.endif
			.elseif eax==UAM_SAVEALL
				mov		eax,[ebx].TABMEM.hwnd
				.if eax!=lParam
					invoke GetWindowLong,[ebx].TABMEM.hedt,GWL_ID
					.if eax==ID_EDITCODE
						invoke SendMessage,[ebx].TABMEM.hedt,EM_GETMODIFY,0,0
					.elseif eax==ID_EDITTEXT
						invoke SendMessage,[ebx].TABMEM.hedt,EM_GETMODIFY,0,0
					.elseif eax==ID_EDITHEX
						invoke SendMessage,[ebx].TABMEM.hedt,EM_GETMODIFY,0,0
					.elseif eax==ID_EDITRES
						invoke SendMessage,[ebx].TABMEM.hedt,PRO_GETMODIFY,0,0
					.elseif eax==ID_EDITUSER
						xor		eax,eax
					.endif
					.if eax
						.if lParam
							invoke WantToSave,[ebx].TABMEM.hwnd
							.if eax
								xor		eax,eax
								jmp		Ex
							.endif
						.else
							invoke SaveTheFile,[ebx].TABMEM.hwnd
						.endif
					.endif
				.endif
			.elseif eax==UAM_CLOSEALL
				mov		eax,[ebx].TABMEM.hwnd
				.if eax!=lParam
					invoke GetWindowLong,[ebx].TABMEM.hedt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT || eax==ID_EDITHEX
						invoke SendMessage,[ebx].TABMEM.hedt,EM_SETMODIFY,FALSE,0
					.elseif eax==ID_EDITRES
						invoke SendMessage,[ebx].TABMEM.hedt,PRO_SETMODIFY,FALSE,0
					.elseif eax==ID_EDITUSER
						xor		eax,eax
					.endif
					invoke SendMessage,[ebx].TABMEM.hwnd,WM_CLOSE,0,0
				.endif
			.endif
		.endif
	.endw
	mov		eax,-1
  Ex:
	ret

UpdateAll endp

IsFileType proc uses ebx esi edi,lpFileType:DWORD,lpFileTypes:DWORD

	mov		esi,lpFileTypes
	mov		edi,lpFileType
	.while TRUE
		xor		ecx,ecx
		.while byte ptr [edi+ecx]
			mov		al,[edi+ecx]
			mov		ah,[esi+ecx]
			.if al>='a' && al<='z'
				and		al,5Fh
			.endif
			.if ah>='a' && ah<='z'
				and		ah,5Fh
			.endif
			.break .if al!=ah
			inc		ecx
		.endw
		.if !byte ptr [edi+ecx]
			mov		eax,TRUE
			jmp		Ex
		.endif
		inc		esi
		.while byte ptr [esi]!='.'
			inc		esi
		.endw
		.break .if !byte ptr [esi+1]
	.endw
	xor		eax,eax
  Ex:
	ret

IsFileType endp

ParseEdit proc uses edi,hWin:HWND,pid:DWORD
	LOCAL	hMem:HGLOBAL

	.if da.fProject
		.if !pid
			jmp		Ex
		.endif
		mov		edi,pid
	.else
		mov		edi,hWin
	.endif
	invoke SendMessage,ha.hProperty,PRM_DELPROPERTY,edi,0
	invoke SendMessage,hWin,WM_GETTEXTLENGTH,0,0
	inc		eax
	push	eax
	add		eax,64
	and		eax,0FFFFFFE0h
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
	mov		hMem,eax
	pop		eax
	invoke SendMessage,hWin,WM_GETTEXT,eax,hMem
	invoke SendMessage,ha.hProperty,PRM_PARSEFILE,edi,hMem
	invoke GlobalFree,hMem
	invoke SendMessage,ha.hProperty,PRM_REFRESHLIST,0,0
  Ex:
	ret

ParseEdit endp

ShowPos proc nLine:DWORD,nPos:DWORD
	LOCAL	buffer[64]:BYTE

	mov		edx,nLine
	inc		edx
	invoke BinToDec,edx,addr buffer[4]
	mov		dword ptr buffer,' :nL'
	invoke strlen,addr buffer
	mov		dword ptr buffer[eax],'soP '
	mov		dword ptr buffer[eax+4],' :'
	mov		edx,nPos
	inc		edx
	invoke BinToDec,edx,addr buffer[eax+6]
	invoke SendMessage,ha.hStatus,SB_SETTEXT,0,addr buffer
	ret

ShowPos endp

IndentComment proc uses esi,hWin:HWND,nChr:DWORD,fN:DWORD
	LOCAL	ochr:CHARRANGE
	LOCAL	chr:CHARRANGE
	LOCAL	LnSt:DWORD
	LOCAL	LnEn:DWORD
	LOCAL	buffer[32]:BYTE

	invoke SendMessage,hWin,WM_SETREDRAW,FALSE,0
	invoke SendMessage,hWin,REM_LOCKUNDOID,TRUE,0
	.if fN
		mov		eax,nChr
		mov		dword ptr buffer[0],eax
	.endif
	invoke SendMessage,hWin,EM_EXGETSEL,0,addr ochr
	invoke SendMessage,hWin,EM_EXGETSEL,0,addr chr
	invoke SendMessage,hWin,EM_HIDESELECTION,TRUE,0
	invoke SendMessage,hWin,EM_EXLINEFROMCHAR,0,chr.cpMin
	mov		LnSt,eax
	mov		eax,chr.cpMax
	dec		eax
	invoke SendMessage,hWin,EM_EXLINEFROMCHAR,0,eax
	mov		LnEn,eax
  nxt:
	mov		eax,LnSt
	.if eax<=LnEn
		invoke SendMessage,hWin,EM_LINEINDEX,LnSt,0
		mov		chr.cpMin,eax
		inc		LnSt
		.if fN
			; Indent / Comment
			mov		chr.cpMax,eax
			invoke SendMessage,hWin,EM_EXSETSEL,0,addr chr
			invoke SendMessage,hWin,EM_REPLACESEL,TRUE,addr buffer
			invoke strlen,addr buffer
			add		ochr.cpMax,eax
			jmp		nxt
		.else
			; Outdent / Uncomment
			invoke SendMessage,hWin,EM_LINEINDEX,LnSt,0
			mov		chr.cpMax,eax
			invoke SendMessage,hWin,EM_EXSETSEL,0,addr chr
			invoke SendMessage,hWin,EM_GETSELTEXT,0,addr tmpbuff
			mov		esi,offset tmpbuff
			xor		eax,eax
			mov		al,[esi]
			.if eax==nChr
				inc		esi
				invoke SendMessage,hWin,EM_REPLACESEL,TRUE,esi
				dec		ochr.cpMax
			.elseif nChr==09h
				mov		ecx,da.edtopt.tabsize
				dec		esi
			  @@:
				inc		esi
				mov		al,[esi]
				cmp		al,' '
				jne		@f
				loop	@b
				inc		esi
			  @@:
				.if al==09h
					inc		esi
					dec		ecx
				.endif
				mov		eax,da.edtopt.tabsize
				sub		eax,ecx
				sub		ochr.cpMax,eax
				invoke SendMessage,hWin,EM_REPLACESEL,TRUE,esi
			.endif
			jmp		nxt
		.endif
	.endif
	invoke SendMessage,hWin,EM_EXSETSEL,0,addr ochr
	invoke SendMessage,hWin,EM_HIDESELECTION,FALSE,0
	invoke SendMessage,hWin,EM_SCROLLCARET,0,0
	invoke SendMessage,hWin,REM_LOCKUNDOID,FALSE,0
	invoke SendMessage,hWin,WM_SETREDRAW,TRUE,0
	invoke SendMessage,hWin,REM_REPAINT,0,0
	ret

IndentComment endp

EnableMenu proc uses ebx esi edi,hMnu:HMENU,nPos:DWORD
	LOCAL	chrg:CHARRANGE

	mov		ebx,ha.hEdt
	xor		esi,esi
	.if ebx
		invoke GetWindowLong,ebx,GWL_ID
		mov		esi,eax
	.endif
	push	0
	push	0
	mov		eax,nPos
	.if eax==0
		;File
		push	ebx
		push	IDM_FILE_REOPEN
		push	ebx
		push	IDM_FILE_CLOSE
		push	ebx
		push	IDM_FILE_SAVE
		push	ebx
		push	IDM_FILE_SAVEAS
		push	ebx
		push	IDM_FILE_SAVEALL
		.if esi==ID_EDITCODE || esi==ID_EDITTEXT
			push	TRUE
		.else
			push	FALSE
		.endif
		push	IDM_FILE_PRINT
	.elseif eax==1
		;Edit
		.if !ebx
			;No edit window open
			xor		eax,eax
			push	eax
			push	IDM_EDIT_UNDO
			push	eax
			push	IDM_EDIT_REDO
			push	eax
			push	IDM_EDIT_PASTE
			push	eax
			push	IDM_EDIT_CUT
			push	eax
			push	IDM_EDIT_COPY
			push	eax
			push	IDM_EDIT_DELETE
			push	eax
			push	IDM_EDIT_SELECTALL
			push	eax
			push	IDM_EDIT_FIND
			push	eax
			push	IDM_EDIT_REPLACE
			push	eax
			push	IDM_EDIT_INDENT
			push	eax
			push	IDM_EDIT_OUTDENT
			push	eax
			push	IDM_EDIT_COMMENT
			push	eax
			push	IDM_EDIT_UNCOMMENT
			push	eax
			push	IDM_EDIT_TOGGLEBM
			push	eax
			push	IDM_EDIT_NEXTBM
			push	eax
			push	IDM_EDIT_PREVBM
			push	eax
			push	IDM_EDIT_CLEARBM
		.else
			.if esi==ID_EDITCODE || esi==ID_EDITTEXT || esi==ID_EDITHEX
				invoke SendMessage,ebx,EM_CANUNDO,0,0
				push	eax
				push	IDM_EDIT_UNDO
				invoke SendMessage,ebx,EM_CANREDO,0,0
				push	eax
				push	IDM_EDIT_REDO
				invoke SendMessage,ebx,EM_CANPASTE,CF_TEXT,0
				push	eax
				push	IDM_EDIT_PASTE
				invoke SendMessage,ebx,EM_EXGETSEL,0,addr chrg
				mov		eax,chrg.cpMax
				sub		eax,chrg.cpMin
				push	eax
				push	IDM_EDIT_CUT
				push	eax
				push	IDM_EDIT_COPY
				push	eax
				push	IDM_EDIT_DELETE
				push	TRUE
				push	IDM_EDIT_SELECTALL
				push	TRUE
				push	IDM_EDIT_FIND
				push	TRUE
				push	IDM_EDIT_REPLACE
				push	eax
				push	IDM_EDIT_INDENT
				push	eax
				push	IDM_EDIT_OUTDENT
				push	eax
				push	IDM_EDIT_COMMENT
				push	eax
				push	IDM_EDIT_UNCOMMENT
				push	TRUE
				push	IDM_EDIT_TOGGLEBM
				.if esi==ID_EDITHEX
					invoke SendMessage,ebx,HEM_ANYBOOKMARKS,0,0
				.else
					invoke SendMessage,ebx,REM_NXTBOOKMARK,-1,3
					inc		eax
				.endif
				push	eax
				push	IDM_EDIT_NEXTBM
				push	eax
				push	IDM_EDIT_PREVBM
				push	eax
				push	IDM_EDIT_CLEARBM
			.elseif esi==ID_EDITRES
				invoke SendMessage,ebx,DEM_CANUNDO,0,0
				push	eax
				push	IDM_EDIT_UNDO
				invoke SendMessage,ebx,DEM_CANREDO,0,0
				push	eax
				push	IDM_EDIT_REDO
				invoke SendMessage,ebx,DEM_CANPASTE,CF_TEXT,0
				push	eax
				push	IDM_EDIT_PASTE
				invoke SendMessage,ebx,DEM_ISSELECTION,0,0
				push	eax
				push	IDM_EDIT_CUT
				push	eax
				push	IDM_EDIT_COPY
				push	eax
				push	IDM_EDIT_DELETE
				invoke SendMessage,ebx,PRO_GETSELECTED,0,0
				.if eax==TPE_DIALOG
					mov		eax,TRUE
					xor		eax,eax
				.else
					xor		eax,eax
				.endif
				push	eax
				push	IDM_EDIT_SELECTALL
				xor		eax,eax
				push	eax
				push	IDM_EDIT_FIND
				push	eax
				push	IDM_EDIT_REPLACE
				push	eax
				push	IDM_EDIT_INDENT
				push	eax
				push	IDM_EDIT_OUTDENT
				push	eax
				push	IDM_EDIT_COMMENT
				push	eax
				push	IDM_EDIT_UNCOMMENT
				push	eax
				push	IDM_EDIT_TOGGLEBM
				push	eax
				push	IDM_EDIT_NEXTBM
				push	eax
				push	IDM_EDIT_PREVBM
				push	eax
				push	IDM_EDIT_CLEARBM
			.elseif esi==ID_EDITUSER
			.endif
		.endif
	.elseif eax==2
		;View
	.elseif eax==3
		;Format
		.if esi==ID_EDITRES
			mov		eax,TRUE
			push	eax
			push	IDM_FORMAT_LOCK
			push	eax
			push	IDM_FORMAT_SHOW
			push	eax
			push	IDM_FORMAT_SNAP
			invoke SendMessage,ebx,DEM_GETMEM,DEWM_DIALOG,0
			push	eax
			push	IDM_FORMAT_INDEX
			invoke SendMessage,ebx,DEM_ISSELECTION,0,0
			push	eax
			push	IDM_FORMAT_CENTERHORIZONTAL
			push	eax
			push	IDM_FORMAT_CENTERVERTICAL
			.if eax!=2
				xor		eax,eax
			.endif
			push	eax
			push	IDM_FORMAT_ALIGNLEFT
			push	eax
			push	IDM_FORMAT_ALIGNCENTER
			push	eax
			push	IDM_FORMAT_ALIGNRIGHT
			push	eax
			push	IDM_FORMAT_ALIGNTOP
			push	eax
			push	IDM_FORMAT_ALIGNMIDDLE
			push	eax
			push	IDM_FORMAT_ALIGNBOTTOM
			push	eax
			push	IDM_FORMAT_SIZEWIDTH
			push	eax
			push	IDM_FORMAT_SIZEHEIGHT
			push	eax
			push	IDM_FORMAT_SIZEBOTH
			invoke SendMessage,ebx,DEM_ISFRONT,0,0
			xor		eax,TRUE
			push	eax
			push	IDM_FORMAT_FRONT
			invoke SendMessage,ebx,DEM_ISBACK,0,0
			xor		eax,TRUE
			push	eax
			push	IDM_FORMAT_BACK
		.else
			xor		eax,eax
			push	eax
			push	IDM_FORMAT_LOCK
			push	eax
			push	IDM_FORMAT_FRONT
			push	eax
			push	IDM_FORMAT_BACK
			push	eax
			push	IDM_FORMAT_SHOW
			push	eax
			push	IDM_FORMAT_SNAP
			push	eax
			push	IDM_FORMAT_ALIGNLEFT
			push	eax
			push	IDM_FORMAT_ALIGNCENTER
			push	eax
			push	IDM_FORMAT_ALIGNRIGHT
			push	eax
			push	IDM_FORMAT_ALIGNTOP
			push	eax
			push	IDM_FORMAT_ALIGNMIDDLE
			push	eax
			push	IDM_FORMAT_ALIGNBOTTOM
			push	eax
			push	IDM_FORMAT_SIZEWIDTH
			push	eax
			push	IDM_FORMAT_SIZEHEIGHT
			push	eax
			push	IDM_FORMAT_SIZEBOTH
			push	eax
			push	IDM_FORMAT_CENTERHORIZONTAL
			push	eax
			push	IDM_FORMAT_CENTERVERTICAL
			push	eax
			push	IDM_FORMAT_INDEX
		.endif
	.elseif eax==4
		;Project
		mov		eax,TRUE
		push	eax
		push	IDM_PROJECT_NEW
		push	eax
		push	IDM_PROJECT_OPEN
		mov		eax,da.fProject
		push	eax
		push	IDM_PROJECT_CLOSE
		push	eax
		push	IDM_PROJECT_ADDFILE
		push	eax
		push	IDM_PROJET_ADDEXISTING
		push	eax
		push	IDM_PROJECT_ADDOPEN
		push	eax
		push	IDM_PROJECT_ADDALLOPEN
		push	eax
		push	IDM_PROJECT_ADDGROUP
		push	eax
		push	IDM_PROJECT_REMOVEFILE
		push	eax
		push	IDM_PROJECT_REMOVEGROUP
		push	eax
		push	IDM_PROJECT_OPTION
	.elseif eax==5
		;Resource
		xor		eax,eax
		.if esi==ID_EDITRES
			mov		eax,TRUE
		.endif
		push	eax
		push	IDM_RESOURCE_ADDDIALOG
		push	eax
		push	IDM_RESOURCE_ADDMENU
		push	eax
		push	IDM_RESOURCE_ADDACCELERATOR
		push	eax
		push	IDM_RESOURCE_ADDVERSION
		push	eax
		push	IDM_RESOURCE_ADDSTRING
		push	eax
		push	IDM_RESOURCE_ADDMANIFEST
		push	eax
		push	IDM_RESOURCE_ADDRCDATA
		push	eax
		push	IDM_RESOURCE_ADDTOLBAR
		push	eax
		push	IDM_RESOURCE_LANGUAGE
		push	eax
		push	IDM_RESOURCE_INCLUDE
		push	eax
		push	IDM_RESOURCE_RESOURCE
		push	eax
		push	IDM_RESOURCE_NAMES
		push	eax
		push	IDM_RESOURCE_EXPORT
		invoke SendMessage,ebx,PRO_GETSELECTED,0,0
		.if eax<=1
			xor		eax,eax
		.endif
		push	eax
		push	IDM_RESOURCE_REMOVE
		invoke SendMessage,ebx,PRO_CANUNDO,0,0
		push	eax
		push	IDM_RESOURCE_UNDO
	.elseif eax==6
		;Make
	.elseif eax==7
		;Debug
	.elseif eax==8
		;Tools
	.elseif eax==9
		;Window
		xor		eax,eax
		.if ebx
			mov		eax,TRUE
		.endif
		push	eax
		push	IDM_WINDOW_CLOSE
		push	eax
		push	IDM_WINDOW_CLOSEALL
		push	eax
		push	IDM_WINDOW_CLOSEALLBUT
		push	eax
		push	IDM_WINDOW_HORIZONTAL
		push	eax
		push	IDM_WINDOW_VERTICAL
		push	eax
		push	IDM_WIDDOW_CASCADE
		push	eax
		push	IDM_WINDOW_ICONS
		push	eax
		push	IDM_WINDOW_MAXIMIZE
		push	eax
		push	IDM_WINDOW_RESTORE
		push	eax
		push	IDM_WINDOW_MINIMIZE
	.elseif eax==10
		;Option
	.elseif eax==11
		;Help
	.endif
	.while TRUE
		pop		edx
		pop		eax
		.break .if !edx
		.if eax
			mov		eax,MF_BYCOMMAND or MF_ENABLED
		.else
			mov		eax,MF_BYCOMMAND or MF_GRAYED
		.endif
		invoke EnableMenuItem,hMnu,edx,eax
	.endw
	ret

EnableMenu endp

EnableToolBar proc uses ebx esi edi
	LOCAL	chrg:CHARRANGE

	mov		ebx,ha.hEdt
	xor		esi,esi
	.if ebx
		invoke GetWindowLong,ebx,GWL_ID
		mov		esi,eax
	.endif
	push	0
	push	0
	push	0
	.if !ebx
		;No edit window open
		xor		eax,eax
		;File toolbar
		mov		edi,ha.hTbrFile
		push	eax
		push	IDM_FILE_SAVE
		push	edi
		push	eax
		push	IDM_FILE_SAVEALL
		push	edi
		push	eax
		push	IDM_FILE_PRINT
		push	edi
		;Edit1 toolbar
		mov		edi,ha.hTbrEdit1
		push	eax
		push	IDM_EDIT_UNDO
		push	edi
		push	eax
		push	IDM_EDIT_REDO
		push	edi
		push	eax
		push	IDM_EDIT_PASTE
		push	edi
		push	eax
		push	IDM_EDIT_CUT
		push	edi
		push	eax
		push	IDM_EDIT_COPY
		push	edi
		push	eax
		push	IDM_EDIT_DELETE
		push	edi
		push	eax
		push	IDM_EDIT_FIND
		push	edi
		push	eax
		push	IDM_EDIT_REPLACE
		push	edi
		;Edit2 toolbar
		mov		edi,ha.hTbrEdit2
		push	eax
		push	IDM_EDIT_INDENT
		push	edi
		push	eax
		push	IDM_EDIT_OUTDENT
		push	edi
		push	eax
		push	IDM_EDIT_COMMENT
		push	edi
		push	eax
		push	IDM_EDIT_UNCOMMENT
		push	edi
		push	eax
		push	IDM_EDIT_TOGGLEBM
		push	edi
		push	eax
		push	IDM_EDIT_NEXTBM
		push	edi
		push	eax
		push	IDM_EDIT_PREVBM
		push	edi
		push	eax
		push	IDM_EDIT_CLEARBM
		push	edi
	.elseif
		mov		eax,TRUE
		;File toolbar
		mov		edi,ha.hTbrFile
		push	eax
		push	IDM_FILE_SAVE
		push	edi
		push	eax
		push	IDM_FILE_SAVEALL
		push	edi
		.if esi==ID_EDITCODE || esi==ID_EDITTEXT || esi==ID_EDITHEX
			;File toolbar
			mov		edi,ha.hTbrFile
			mov		eax,TRUE
			.if esi==ID_EDITHEX
				xor		eax,eax
			.endif
			push	eax
			push	IDM_FILE_PRINT
			push	edi
			;Edit1 toolbar
			mov		edi,ha.hTbrEdit1
			invoke SendMessage,ebx,EM_CANUNDO,0,0
			push	eax
			push	IDM_EDIT_UNDO
			push	edi
			invoke SendMessage,ebx,EM_CANREDO,0,0
			push	eax
			push	IDM_EDIT_REDO
			push	edi
			invoke SendMessage,ebx,EM_CANPASTE,CF_TEXT,0
			push	eax
			push	IDM_EDIT_PASTE
			push	edi
			invoke SendMessage,ebx,EM_EXGETSEL,0,addr chrg
			mov		eax,chrg.cpMax
			sub		eax,chrg.cpMin
			push	eax
			push	IDM_EDIT_CUT
			push	edi
			push	eax
			push	IDM_EDIT_COPY
			push	edi
			push	eax
			push	IDM_EDIT_DELETE
			push	edi
			mov		eax,TRUE
			push	eax
			push	IDM_EDIT_FIND
			push	edi
			push	eax
			push	IDM_EDIT_REPLACE
			push	edi
			;Edit2 toolbar
			mov		edi,ha.hTbrEdit2
			push	TRUE
			push	IDM_EDIT_TOGGLEBM
			push	edi
			.if esi==ID_EDITHEX
				invoke SendMessage,ebx,HEM_ANYBOOKMARKS,0,0
			.else
				invoke SendMessage,ebx,REM_NXTBOOKMARK,-1,3
				inc		eax
			.endif
			push	eax
			push	IDM_EDIT_NEXTBM
			push	edi
			push	eax
			push	IDM_EDIT_PREVBM
			push	edi
			push	eax
			push	IDM_EDIT_CLEARBM
			push	edi
			.if esi==ID_EDITHEX
				xor		eax,eax
			.else
				invoke SendMessage,ebx,EM_EXGETSEL,0,addr chrg
				mov		eax,chrg.cpMax
				sub		eax,chrg.cpMin
			.endif
			push	eax
			push	IDM_EDIT_INDENT
			push	edi
			push	eax
			push	IDM_EDIT_OUTDENT
			push	edi
			push	eax
			push	IDM_EDIT_COMMENT
			push	edi
			push	eax
			push	IDM_EDIT_UNCOMMENT
			push	edi
		.elseif esi==ID_EDITRES
			;File toolbar
			mov		edi,ha.hTbrFile
			push	FALSE
			push	IDM_FILE_PRINT
			push	edi
			;Edit1 toolbar
			mov		edi,ha.hTbrEdit1
			invoke SendMessage,ebx,DEM_CANUNDO,0,0
			push	eax
			push	IDM_EDIT_UNDO
			push	edi
			invoke SendMessage,ebx,DEM_CANREDO,0,0
			push	eax
			push	IDM_EDIT_REDO
			push	edi
			invoke SendMessage,ebx,DEM_CANPASTE,0,0
			push	eax
			push	IDM_EDIT_PASTE
			push	edi
			invoke SendMessage,ebx,DEM_ISSELECTION,0,0
			push	eax
			push	IDM_EDIT_CUT
			push	edi
			push	eax
			push	IDM_EDIT_COPY
			push	edi
			push	eax
			push	IDM_EDIT_DELETE
			push	edi
			xor		eax,eax
			push	eax
			push	IDM_EDIT_FIND
			push	edi
			push	eax
			push	IDM_EDIT_REPLACE
			push	edi
			;Edit2 toolbar
			xor		eax,eax
			mov		edi,ha.hTbrEdit2
			push	eax
			push	IDM_EDIT_TOGGLEBM
			push	edi
			push	eax
			push	IDM_EDIT_NEXTBM
			push	edi
			push	eax
			push	IDM_EDIT_PREVBM
			push	edi
			push	eax
			push	IDM_EDIT_CLEARBM
			push	edi
			push	eax
			push	IDM_EDIT_INDENT
			push	edi
			push	eax
			push	IDM_EDIT_OUTDENT
			push	edi
			push	eax
			push	IDM_EDIT_COMMENT
			push	edi
			push	eax
			push	IDM_EDIT_UNCOMMENT
			push	edi
		.endif
	.endif
	.while TRUE
		pop		ecx
		pop		edx
		pop		eax
		.break .if !edx
		invoke SendMessage,ecx,TB_ENABLEBUTTON,edx,eax
	.endw
	ret

EnableToolBar endp

