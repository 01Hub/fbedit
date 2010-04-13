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

	mov		ebx,1
	.while ebx<100
		invoke BinToDec,ebx,addr buffer
		invoke GetPrivateProfileString,addr szIniSession,addr buffer,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
		.break .if !eax
		invoke GetItemInt,addr buffer,0
		mov		rect.left,eax
		invoke GetItemInt,addr buffer,0
		mov		rect.top,eax
		invoke GetItemInt,addr buffer,0
		mov		rect.right,eax
		invoke GetItemInt,addr buffer,0
		mov		rect.bottom,eax
		invoke OpenTheFile,addr buffer
		.if !da.win.fcldmax
			invoke MoveWindow,ha.hMdi,rect.left,rect.top,rect.right,rect.bottom,TRUE
		.endif
		inc		ebx
	.endw
	.if ebx>1
		mov		dword ptr buffer,'0'
		invoke GetPrivateProfileInt,addr szIniSession,addr buffer,0,addr da.szRadASMIni
		invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
		invoke TabToolActivate
	.endif
	ret

GetSessionFiles endp

PutSession proc uses ebx esi
	LOCAL	tci:TC_ITEM
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[8]:BYTE
	LOCAL	rect:RECT

	mov		dword ptr buffer,0
	invoke WritePrivateProfileSection,addr szIniSession,addr buffer,addr da.szRadASMIni
	;Assembler
	invoke WritePrivateProfileString,addr szIniSession,addr szIniAssembler,addr da.szAssembler,addr da.szRadASMIni
	;File browser path
	invoke WritePrivateProfileString,addr szIniSession,addr szIniPath,addr da.szFBPath,addr da.szRadASMIni
	;Selected tab
	invoke SendMessage,ha.hTab,TCM_GETCURSEL,0,0
	mov		edx,eax
	invoke BinToDec,edx,addr buffer
	mov		dword ptr buffer1,'0'
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
		invoke PutItemInt,addr buffer,rect.left
		invoke PutItemInt,addr buffer,rect.top
		invoke PutItemInt,addr buffer,rect.right
		invoke PutItemInt,addr buffer,rect.bottom
		invoke PutItemStr,addr buffer,addr [esi].TABMEM.filename
		inc		ebx
		invoke BinToDec,ebx,addr buffer1
		invoke WritePrivateProfileString,addr szIniSession,addr buffer1,addr buffer[1],addr da.szRadASMIni
	.endw
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
	invoke SendMessage,ha.hProperties,PRM_SETBACKCOLOR,0,da.radcolor.toolback
	invoke SendMessage,ha.hProperties,PRM_SETTEXTCOLOR,0,da.radcolor.tooltext
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

