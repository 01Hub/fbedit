.code

GetWinPos proc
	LOCAL	buffer[MAX_PATH]:BYTE

	;Main window
	invoke GetPrivateProfileString,addr szIniWin,addr szIniPos,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemInt,addr buffer,10
	mov		da.win.x,eax
	invoke GetItemInt,addr buffer,10
	mov		da.win.y,eax
	invoke GetItemInt,addr buffer,780
	mov		da.win.wt,eax
	invoke GetItemInt,addr buffer,580
	mov		da.win.ht,eax
	invoke GetItemInt,addr buffer,0
	mov		da.win.fmax,eax
	invoke GetItemInt,addr buffer,0
	mov		da.win.ftopmost,eax
	invoke GetItemInt,addr buffer,0
	mov		da.win.fcldmax,eax
	invoke GetItemInt,addr buffer,VIEW_STATUSBAR
	mov		da.win.fView,eax
	invoke GetItemInt,addr buffer,200
	mov		da.win.ccwt,eax
	invoke GetItemInt,addr buffer,150
	mov		da.win.ccht,eax
	;Resource editor
	invoke GetPrivateProfileString,addr szIniWin,addr szIniPosRes,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemInt,addr buffer,200
	mov		da.winres.htpro,eax
	invoke GetItemInt,addr buffer,200
	mov		da.winres.wtpro,eax
	invoke GetItemInt,addr buffer,55
	mov		da.winres.wttbx,eax
	invoke GetItemInt,addr buffer,50
	mov		da.winres.ptstyle.x,eax
	invoke GetItemInt,addr buffer,50
	mov		da.winres.ptstyle.y,eax
	ret

GetWinPos endp

PutWinPos proc
	LOCAL	buffer[256]:BYTE
	LOCAL	rect:RECT

	;Main window
	mov		buffer,0
	invoke IsZoomed,ha.hWnd
	mov 	da.win.fmax,eax
	.if !eax
		invoke IsIconic,ha.hWnd
		.if !eax
			invoke GetWindowRect,ha.hWnd,addr rect
			mov		eax,rect.left
			mov		da.win.x,eax
			mov		eax,rect.top
			mov		da.win.y,eax
			mov		eax,rect.right
			sub		eax,rect.left
			mov		da.win.wt,eax
			mov		eax,rect.bottom
			sub		eax,rect.top
			mov		da.win.ht,eax
		.endif
	.endif
	invoke PutItemInt,addr buffer,da.win.x
	invoke PutItemInt,addr buffer,da.win.y
	invoke PutItemInt,addr buffer,da.win.wt
	invoke PutItemInt,addr buffer,da.win.ht
	invoke PutItemInt,addr buffer,da.win.fmax
	invoke PutItemInt,addr buffer,da.win.ftopmost
	invoke PutItemInt,addr buffer,da.win.fcldmax
	invoke PutItemInt,addr buffer,da.win.fView
	invoke PutItemInt,addr buffer,da.win.ccwt
	invoke PutItemInt,addr buffer,da.win.ccht
	invoke WritePrivateProfileString,addr szIniWin,addr szIniPos,addr buffer[1],addr da.szRadASMIni
	;Resource editor
	mov		buffer,0
	invoke PutItemInt,addr buffer,da.winres.htpro
	invoke PutItemInt,addr buffer,da.winres.wtpro
	invoke PutItemInt,addr buffer,da.winres.wttbx
	invoke PutItemInt,addr buffer,da.winres.ptstyle.x
	invoke PutItemInt,addr buffer,da.winres.ptstyle.y
	invoke WritePrivateProfileString,addr szIniWin,addr szIniPosRes,addr buffer[1],addr da.szRadASMIni
	ret

PutWinPos endp

GetSession proc

	;File browser path
	invoke GetPrivateProfileString,addr szIniSession,addr szIniPath,addr da.szAppPath,addr da.szFBPath,sizeof da.szFBPath,addr da.szRadASMIni
	invoke SendMessage,ha.hFileBrowser,FBM_SETPATH,TRUE,addr da.szFBPath
	;Project
	invoke GetPrivateProfileString,addr szIniSession,addr szIniProject,NULL,addr da.szProject,sizeof da.szProject,addr da.szRadASMIni
	.if eax
		;Check if project file exists
		invoke GetFileAttributes,addr da.szProject
		.if eax==INVALID_HANDLE_VALUE
			xor		eax,eax
		.else
			mov		eax,TRUE
		.endif
	.endif
	.if eax
		;Assembler
		invoke GetPrivateProfileString,addr szIniAssembler,addr szIniAssembler,NULL,addr da.szAssembler,sizeof da.szAssembler,addr da.szProject
		mov		da.fProject,TRUE
	.else
		;Assembler
		invoke GetPrivateProfileString,addr szIniSession,addr szIniAssembler,NULL,addr da.szAssembler,sizeof da.szAssembler,addr da.szRadASMIni
		.if !eax
			mov		dword ptr da.szAssembler,'msam'
		.endif
	.endif
	ret

GetSession endp

GetSessionFiles proc uses ebx
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	rect:RECT
	LOCAL	nLine:DWORD
	LOCAL	chrg:CHARRANGE

	mov		ebx,1
	.while ebx<100
		mov		buffer,'F'
		invoke BinToDec,ebx,addr buffer[1]
		invoke GetPrivateProfileString,addr szIniSession,addr buffer,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
		.break .if !eax
		invoke GetItemInt,addr buffer,0
		push	eax
		invoke GetItemInt,addr buffer,0
		mov		rect.left,eax
		invoke GetItemInt,addr buffer,0
		mov		rect.top,eax
		invoke GetItemInt,addr buffer,0
		mov		rect.right,eax
		invoke GetItemInt,addr buffer,0
		mov		rect.bottom,eax
		invoke GetItemInt,addr buffer,0
		mov		nLine,eax
		invoke GetFileAttributes,addr buffer
		pop		edx
		.if eax!=INVALID_HANDLE_VALUE
			push	edx
			invoke OpenTheFile,addr buffer,edx
			pop		edx
			.if edx==ID_EDITCODE || edx==ID_EDITTEXT
				invoke SendMessage,ha.hEdt,EM_LINEINDEX,nLine,0
				mov		chrg.cpMin,eax
				mov		chrg.cpMax,eax
				invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
			.endif
			.if !da.win.fcldmax
				invoke MoveWindow,ha.hMdi,rect.left,rect.top,rect.right,rect.bottom,TRUE
			.endif
		.endif
		inc		ebx
	.endw
	.if ebx>1
		mov		dword ptr buffer,'0F'
		invoke GetPrivateProfileInt,addr szIniSession,addr buffer,0,addr da.szRadASMIni
		invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
		.if eax==-1
			invoke SendMessage,ha.hTab,TCM_SETCURSEL,0,0
		.endif
		.if eax!=-1
			invoke TabToolActivate
		.endif
	.endif
	ret

GetSessionFiles endp

PutSession proc uses ebx esi
	LOCAL	tci:TC_ITEM
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[8]:BYTE
	LOCAL	rect:RECT
	LOCAL	nLine:DWORD
	LOCAL	chrg:CHARRANGE

	mov		dword ptr buffer,0
	invoke WritePrivateProfileSection,addr szIniSession,addr buffer,addr da.szRadASMIni
	;Assembler
	invoke WritePrivateProfileString,addr szIniSession,addr szIniAssembler,addr da.szAssembler,addr da.szRadASMIni
	;File browser path
	invoke WritePrivateProfileString,addr szIniSession,addr szIniPath,addr da.szFBPath,addr da.szRadASMIni
	.if ha.hMdi
		;Current tab
		invoke SendMessage,ha.hTab,TCM_GETCURSEL,0,0
		mov		edx,eax
		invoke BinToDec,edx,addr buffer
		mov		dword ptr buffer1,'0F'
		invoke WritePrivateProfileString,addr szIniSession,addr buffer1,addr buffer,addr da.szRadASMIni
		;Open files
		xor		ebx,ebx
		mov		tci.imask,TCIF_PARAM
		.while ebx<100
			invoke SendMessage,ha.hTab,TCM_GETITEM,ebx,addr tci
			.break .if !eax
			mov		esi,tci.lParam
			.if !da.win.fcldmax
				invoke GetWindowRect,[esi].TABMEM.hwnd,addr rect
				mov		eax,rect.right
				sub		eax,rect.left
				mov		rect.right,eax
				mov		eax,rect.bottom
				sub		eax,rect.top
				mov		rect.bottom,eax
				invoke ScreenToClient,ha.hClient,addr rect
			.else
				mov		eax,CW_USEDEFAULT
				mov		rect.left,eax
				mov		rect.top,eax
				mov		rect.right,eax
				mov		rect.bottom,eax
			.endif
			mov		buffer,0
			mov		nLine,0
			invoke GetWindowLong,[esi].TABMEM.hedt,GWL_ID
			.if eax==ID_EDITCODE || eax==ID_EDITTEXT
				push	eax
				invoke SendMessage,[esi].TABMEM.hedt,EM_EXGETSEL,0,addr chrg
				invoke SendMessage,[esi].TABMEM.hedt,EM_EXLINEFROMCHAR,0,chrg.cpMin
				mov		nLine,eax
				pop		eax
			.endif
			invoke PutItemInt,addr buffer,eax
			invoke PutItemInt,addr buffer,rect.left
			invoke PutItemInt,addr buffer,rect.top
			invoke PutItemInt,addr buffer,rect.right
			invoke PutItemInt,addr buffer,rect.bottom
			invoke PutItemInt,addr buffer,nLine
			invoke PutItemStr,addr buffer,addr [esi].TABMEM.filename
			inc		ebx
			mov		buffer1,'F'
			invoke BinToDec,ebx,addr buffer1[1]
			invoke WritePrivateProfileString,addr szIniSession,addr buffer1,addr buffer[1],addr da.szRadASMIni
		.endw
	.endif
	ret

PutSession endp

GetColors proc uses ebx
	LOCAL	racolor:RACOLOR

	invoke GetPrivateProfileString,addr szIniColors,addr szIniColors,NULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
	.if eax
		xor		ebx,ebx
		.while ebx<sizeof RADCOLOR/4
			invoke GetItemInt,addr tmpbuff,0
			mov		dword ptr da.radcolor[ebx*4],eax
			inc		ebx
		.endw
	.else
		invoke RtlMoveMemory,addr da.radcolor,addr defcol,sizeof RADCOLOR
	.endif
	invoke SendMessage,ha.hOutput,REM_GETCOLOR,0,addr racolor
	mov		eax,da.radcolor.toolback
	mov		racolor.bckcol,eax
	mov		eax,da.radcolor.tooltext
	mov		racolor.txtcol,eax
	invoke SendMessage,ha.hOutput,REM_SETCOLOR,0,addr racolor
	invoke SendMessage,ha.hImmediate,REM_SETCOLOR,0,addr racolor
	invoke SendMessage,ha.hFileBrowser,FBM_SETBACKCOLOR,0,da.radcolor.toolback
	invoke SendMessage,ha.hFileBrowser,FBM_SETTEXTCOLOR,0,da.radcolor.tooltext
	invoke SendMessage,ha.hProjectBrowser,RPBM_SETBACKCOLOR,0,da.radcolor.toolback
	invoke SendMessage,ha.hProjectBrowser,RPBM_SETTEXTCOLOR,0,da.radcolor.tooltext
	invoke SendMessage,ha.hProperty,PRM_SETBACKCOLOR,0,da.radcolor.toolback
	invoke SendMessage,ha.hProperty,PRM_SETTEXTCOLOR,0,da.radcolor.tooltext
	ret

GetColors endp

PutColors proc uses ebx

	mov		tmpbuff,0
	xor		ebx,ebx
	.while ebx<sizeof RADCOLOR/4
		mov		eax,dword ptr da.radcolor[ebx*4]
		invoke PutItemInt,addr tmpbuff,eax
		inc		ebx
	.endw
	invoke WritePrivateProfileString,addr szIniColors,addr szIniColors,addr tmpbuff[1],addr da.szAssemblerIni
	ret

PutColors endp

GetKeywords proc
	LOCAL	buffer[16]:BYTE
	LOCAL	nInx:DWORD

	invoke SetHiliteWords,0,0
	mov		buffer,'C'
	mov		nInx,0
	.while nInx<16
		invoke BinToDec,nInx,addr buffer[1]
		invoke GetPrivateProfileString,addr szIniKeywords,addr buffer,NULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
		.if eax
			mov		eax,nInx
			mov		eax,dword ptr da.radcolor[eax*4]
			invoke SetHiliteWords,eax,addr tmpbuff
		.endif
		inc		nInx
	.endw
	ret

GetKeywords endp

GetAssembler proc

	invoke strcpy,addr da.szAssemblerIni,addr da.szAppPath
	invoke strcat,addr da.szAssemblerIni,addr szBS
	invoke strcat,addr da.szAssemblerIni,addr da.szAssembler
	invoke strcat,addr da.szAssemblerIni,addr szDotIni
	invoke SendMessage,ha.hStatus,SB_SETTEXT,2,addr da.szAssembler
	ret

GetAssembler endp

GetBlockDef proc uses ebx esi edi
	LOCAL	buffer[16]:BYTE

	mov		esi,offset da.rabdstr
	mov		edi,offset da.rabd
	invoke RtlZeroMemory,edi,sizeof da.rabd
	mov		ebx,1
	.while ebx<33
		invoke BinToDec,ebx,addr buffer
		invoke GetPrivateProfileString,addr szIniCodeBlock,addr buffer,NULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
		.break .if !eax
		invoke GetItemStr,addr tmpbuff,addr szNULL,esi
		.if byte ptr [esi]
			mov		[edi].RABLOCKDEF.lpszStart,esi
			invoke strlen,esi
			lea		esi,[esi+eax+1]
		.endif 
		invoke GetItemStr,addr tmpbuff,addr szNULL,esi 
		.if byte ptr [esi]
			mov		[edi].RABLOCKDEF.lpszEnd,esi
			invoke strlen,esi
			lea		esi,[esi+eax+1]
		.endif 
		invoke GetItemStr,addr tmpbuff,addr szNULL,esi 
		.if byte ptr [esi]
			mov		[edi].RABLOCKDEF.lpszNot1,esi
			invoke strlen,esi
			lea		esi,[esi+eax+1]
		.endif 
		invoke GetItemStr,addr tmpbuff,addr szNULL,esi 
		.if byte ptr [esi]
			mov		[edi].RABLOCKDEF.lpszNot2,esi
			invoke strlen,esi
			lea		esi,[esi+eax+1]
		.endif 
		invoke GetItemInt,addr tmpbuff,0
		mov		[edi].RABLOCKDEF.flag,eax
		inc		ebx
		lea		edi,[edi+sizeof RABLOCKDEF]
	.endw
	;Reset block defs
	invoke SendMessage,ha.hOutput,REM_ADDBLOCKDEF,0,0
	mov		esi,offset da.rabd
	.while [esi].RABLOCKDEF.lpszStart
		invoke SendMessage,ha.hOutput,REM_ADDBLOCKDEF,0,esi
		mov		eax,[esi].RABLOCKDEF.lpszStart
		call	TestIt
		mov		eax,[esi].RABLOCKDEF.lpszEnd
		call	TestIt
		lea		esi,[esi+sizeof RABLOCKDEF]
	.endw
	invoke GetPrivateProfileString,addr szIniCodeBlock,addr szIniCmnt,NULL,addr tmpbuff,64,addr da.szAssemblerIni
	invoke GetItemStr,addr tmpbuff,addr szNULL,addr da.szCmntStart
	invoke GetItemStr,addr tmpbuff,addr szNULL,addr da.szCmntEnd
	invoke SendMessage,ha.hOutput,REM_SETCOMMENTBLOCKS,addr da.szCmntStart,addr da.szCmntEnd
	invoke GetPrivateProfileString,addr szIniEdit,addr szIniBraceMatch,NULL,addr da.szBraceMatch,sizeof da.szBraceMatch,addr da.szAssemblerIni
	invoke SendMessage,ha.hOutput,REM_BRACKETMATCH,0,offset da.szBraceMatch
	invoke GetPrivateProfileString,addr szIniEdit,addr szIniOption,NULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
	invoke GetItemInt,addr tmpbuff,4
	mov		da.edtopt.tabsize,eax
	invoke GetItemInt,addr tmpbuff,0
	mov		da.edtopt.exptabs,eax
	invoke GetItemInt,addr tmpbuff,1
	mov		da.edtopt.indent,eax
	invoke GetItemInt,addr tmpbuff,0
	mov		da.edtopt.hiliteline,eax
	invoke GetItemInt,addr tmpbuff,0
	mov		da.edtopt.hilitecmnt,eax
	invoke GetItemInt,addr tmpbuff,1
	mov		da.edtopt.session,eax
	invoke GetItemInt,addr tmpbuff,1
	mov		da.edtopt.linenumber,eax
	ret

TestIt:
	.if eax
		.while byte ptr [eax]
			.if byte ptr [eax]=='|'
				mov		byte ptr [eax],0
			.endif
			inc		eax
		.endw
	.endif
	retn
	ret

GetBlockDef endp

GetParesDef proc
	LOCAL	buffcbo[128]:BYTE
	LOCAL	bufftype[128]:BYTE
	LOCAL	deftype:DEFTYPE
	LOCAL	buffer[256]:BYTE
	LOCAL	defgen:DEFGEN

	invoke SendMessage,ha.hProperty,PRM_RESET,0,0
	invoke GetPrivateProfileInt,addr szIniParse,addr szIniAssembler,0,addr da.szAssemblerIni
	mov		da.nAsm,eax
	invoke SendMessage,ha.hProperty,PRM_SETLANGUAGE,da.nAsm,0
	invoke SendMessage,ha.hProperty,PRM_SETCHARTAB,0,da.lpCharTab
	invoke GetItemStr,addr buffer,addr szNULL,addr defgen.szCmntBlockSt
	invoke GetItemStr,addr buffer,addr szNULL,addr defgen.szCmntBlockEn
	invoke GetItemStr,addr buffer,addr szNULL,addr defgen.szCmntChar
	invoke GetItemStr,addr buffer,addr szNULL,addr defgen.szString
	invoke GetItemStr,addr buffer,addr szNULL,addr defgen.szLineCont
	invoke SendMessage,ha.hProperty,PRM_SETGENDEF,0,addr defgen
	invoke GetPrivateProfileString,addr szIniParse,addr szIniDef,NULL,addr buffer,sizeof buffer,addr da.szAssemblerIni
	invoke GetPrivateProfileString,addr szIniParse,addr szIniType,NULL,addr buffcbo,sizeof buffcbo,addr da.szAssemblerIni
	.if eax
		.while buffcbo
			invoke GetItemStr,addr buffcbo,addr szNULL,addr bufftype
			.if bufftype
				invoke GetPrivateProfileString,addr szIniParse,addr bufftype,NULL,addr buffer,sizeof buffer,addr da.szAssemblerIni
				.while buffer
					invoke GetItemInt,addr buffer,0
					mov		deftype.nType,al
					invoke GetItemInt,addr buffer,0
					mov		deftype.nDefType,al
					invoke GetItemStr,addr buffer,addr szNULL,addr deftype.Def
					invoke GetItemStr,addr buffer,addr szNULL,addr deftype.szWord
					invoke strlen,addr deftype.szWord
					mov		deftype.len,al
					invoke SendMessage,ha.hProperty,PRM_ADDDEFTYPE,0,addr deftype
				.endw
				movzx	edx,deftype.Def
				invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYTYPE,edx,addr bufftype
			.endif
		.endw
		invoke GetPrivateProfileString,addr szIniParse,addr szIniIgnore,NULL,addr buffer,sizeof buffer,addr da.szAssemblerIni
		.while buffer
			invoke GetItemInt,addr buffer,0
			push	eax
			invoke GetItemStr,addr buffer,addr szNULL,addr bufftype
			pop		edx
			.if bufftype
				invoke SendMessage,ha.hProperty,PRM_ADDIGNORE,edx,addr bufftype
			.endif
		.endw
		invoke SendMessage,ha.hProperty,PRM_SELECTPROPERTY,'p',0
	.endif
	ret

GetParesDef endp

