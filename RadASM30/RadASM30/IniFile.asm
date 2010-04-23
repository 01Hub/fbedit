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
	.if eax<100
		mov		eax,100
	.endif
	mov		da.win.ccwt,eax
	invoke GetItemInt,addr buffer,150
	.if eax<100
		mov		eax,100
	.endif
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
	invoke GetWindowRect,ha.hCC,addr rect
	mov		eax,rect.right
	sub		eax,rect.left
	mov		edx,rect.bottom
	sub		edx,rect.top
	.if eax>10 && edx>10
		mov		da.win.ccwt,eax
		mov		da.win.ccht,edx
		invoke PutItemInt,addr buffer,da.win.ccwt
		invoke PutItemInt,addr buffer,da.win.ccht
	.endif
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

GetResource proc uses ebx esi edi
	LOCAL	buffer[32]:BYTE

	invoke GetPrivateProfileString,addr szIniResource,addr szIniOption,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemInt,addr buffer,3
	mov		da.resopt.gridx,eax
	invoke GetItemInt,addr buffer,3
	mov		da.resopt.gridy,eax
	invoke GetItemInt,addr buffer,RESOPT_GRID or RESOPT_SNAP
	mov		da.resopt.fopt,eax
	;Custom controls
	xor		ebx,ebx
	mov		edi,offset da.resopt.custctrl
	.while ebx<32
		invoke BinToDec,ebx,addr buffer
		invoke GetPrivateProfileString,addr szIniCustCtrl,addr buffer,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szRadASMIni
		.if eax
			invoke GetItemStr,addr tmpbuff,addr szNULL,addr [edi].CUSTCTRL.szFileName
			invoke GetItemQuotedStr,addr tmpbuff,addr szNULL,addr [edi].CUSTCTRL.szStyleMask
			lea		edi,[edi+sizeof CUSTCTRL]
		.endif
		inc		ebx
	.endw
	;Custom resource types
	xor		ebx,ebx
	mov		edi,offset da.resopt.custtype
	.while ebx<32
		invoke BinToDec,ebx,addr buffer
		invoke GetPrivateProfileString,addr szIniCustType,addr buffer,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szRadASMIni
		.if eax
			invoke GetItemStr,addr tmpbuff,addr szNULL,addr [edi].RARSTYPE.sztype
			invoke GetItemInt,addr tmpbuff,0
			mov		[edi].RARSTYPE.nid,eax
			invoke GetItemQuotedStr,addr tmpbuff,addr szNULL,addr [edi].RARSTYPE.szext
			invoke GetItemStr,addr tmpbuff,addr szNULL,addr [edi].RARSTYPE.szedit
			lea		edi,[edi+sizeof RARSTYPE]
		.endif
		inc		ebx
	.endw
	;Custom styles
	xor		ebx,ebx
	mov		edi,offset da.resopt.custstyle
	.while ebx<64
		invoke BinToDec,ebx,addr buffer
		invoke GetPrivateProfileString,addr szIniCustStyle,addr buffer,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szRadASMIni
		.if eax
			invoke GetItemStr,addr tmpbuff,addr szNULL,addr [edi].CUSTSTYLE.szStyle
			invoke GetItemInt,addr tmpbuff,0
			mov		[edi].CUSTSTYLE.nValue,eax
			invoke GetItemInt,addr tmpbuff,0
			mov		[edi].CUSTSTYLE.nMask,eax
			lea		edi,[edi+sizeof CUSTSTYLE]
		.endif
		inc		ebx
	.endw
	ret

GetResource endp

PutResource proc

	mov		tmpbuff,0
	invoke PutItemInt,addr tmpbuff,da.resopt.gridx
	invoke PutItemInt,addr tmpbuff,da.resopt.gridy
	invoke PutItemInt,addr tmpbuff,da.resopt.fopt
	invoke WritePrivateProfileString,addr szIniResource,addr szIniOption,addr tmpbuff[1],addr da.szRadASMIni
	ret

PutResource endp

GetSessionFiles proc uses ebx edi
	LOCAL	fi:FILEINFO
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	chrg:CHARRANGE
	LOCAL	hEdt:HWND

	;File browser path
	invoke GetPrivateProfileString,addr szIniSession,addr szIniPath,addr da.szAppPath,addr da.szFBPath,sizeof da.szFBPath,addr da.szRadASMIni
	invoke GetFileAttributes,addr da.szFBPath
	;Check if path exist
	.if eax==INVALID_HANDLE_VALUE
		invoke strcpy,addr da.szFBPath,addr da.szAppPath
	.endif
	invoke SendMessage,ha.hFileBrowser,FBM_SETPATH,TRUE,addr da.szFBPath
	mov		ebx,1
	push	da.win.fcldmax
	mov		da.win.fcldmax,FALSE
	.while ebx<100
		invoke GetFileInfo,ebx,addr szIniSession,addr da.szRadASMIni,addr fi
		.break .if !eax
		invoke GetFileAttributes,addr fi.filename
		.if eax!=INVALID_HANDLE_VALUE
			invoke OpenTheFile,addr fi.filename,fi.ID
			mov		edi,eax
			invoke GetWindowLong,edi,GWL_USERDATA
			mov		hEdt,eax
			invoke MoveWindow,edi,fi.rect.left,fi.rect.top,fi.rect.right,fi.rect.bottom,TRUE
			invoke UpdateWindow,edi
			.if fi.ID==ID_EDITCODE || fi.ID==ID_EDITTEXT
				invoke SendMessage,hEdt,EM_LINEINDEX,fi.nline,0
				mov		chrg.cpMin,eax
				mov		chrg.cpMax,eax
				invoke SendMessage,hEdt,EM_EXSETSEL,0,addr chrg
				invoke SendMessage,hEdt,REM_VCENTER,0,0
				invoke SendMessage,hEdt,EM_SCROLLCARET,0,0
			.endif
		.endif
		inc		ebx
	.endw
	pop		da.win.fcldmax
	.if ebx>1
		mov		dword ptr buffer,'0F'
		invoke GetPrivateProfileInt,addr szIniSession,addr buffer,0,addr da.szRadASMIni
		invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
		.if eax==-1
			invoke SendMessage,ha.hTab,TCM_SETCURSEL,0,0
		.endif
		.if eax!=-1
			invoke TabToolActivate
			.if da.win.fcldmax
				invoke SendMessage,ha.hClient,WM_MDIMAXIMIZE,ha.hMdi,0
			.endif
		.else
			xor		eax,eax
		.endif
	.else
		xor		eax,eax
	.endif
	ret

GetSessionFiles endp

PutSession proc uses ebx
	LOCAL	fi:FILEINFO
	LOCAL	buffer[8]:BYTE

	mov		dword ptr buffer,0
	invoke WritePrivateProfileSection,addr szIniSession,addr buffer,addr da.szRadASMIni
	;Assembler
	invoke WritePrivateProfileString,addr szIniSession,addr szIniAssembler,addr da.szAssembler,addr da.szRadASMIni
	;File browser path
	invoke WritePrivateProfileString,addr szIniSession,addr szIniPath,addr da.szFBPath,addr da.szRadASMIni
	.if ha.hMdi
		;Files
		invoke ShowWindow,ha.hClient,SW_HIDE
		;Current tab
		invoke SendMessage,ha.hTab,TCM_GETCURSEL,0,0
		invoke BinToDec,eax,addr tmpbuff
		mov		dword ptr buffer,'0F'
		invoke WritePrivateProfileString,addr szIniSession,addr buffer,addr tmpbuff,addr da.szRadASMIni
		;Open files
		mov		eax,da.win.fcldmax
		push	eax
		.if eax
			invoke SendMessage,ha.hClient,WM_MDIRESTORE,ha.hMdi,0
		.endif
		xor		ebx,ebx
		.while ebx<100
			mov		tmpbuff,0
			invoke SetFileInfo,ebx,addr fi
			.break .if !eax
			invoke PutItemInt,addr tmpbuff,fi.ID
			invoke PutItemInt,addr tmpbuff,fi.rect.left
			invoke PutItemInt,addr tmpbuff,fi.rect.top
			invoke PutItemInt,addr tmpbuff,fi.rect.right
			invoke PutItemInt,addr tmpbuff,fi.rect.bottom
			invoke PutItemInt,addr tmpbuff,fi.nline
			invoke PutItemStr,addr tmpbuff,addr fi.filename
			inc		ebx
			mov		buffer,'F'
			invoke BinToDec,ebx,addr buffer[1]
			invoke WritePrivateProfileString,addr szIniSession,addr buffer,addr tmpbuff[1],addr da.szRadASMIni
		.endw
		pop		da.win.fcldmax
		invoke ShowWindow,ha.hClient,SW_SHOWNA
	.endif
	ret

PutSession endp

