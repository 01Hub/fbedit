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
	invoke GetPrivateProfileString,addr szIniResource,addr szIniOption,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemInt,addr buffer,3
	mov		da.resopt.gridx,eax
	invoke GetItemInt,addr buffer,3
	mov		da.resopt.gridy,eax
	invoke GetItemInt,addr buffer,RESOPT_GRID or RESOPT_SNAP
	mov		da.resopt.fopt,eax
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
		invoke WritePrivateProfileString,addr szIniWin,addr szIniPos,addr buffer[1],addr da.szRadASMIni
	.endif
	;Resource editor
	mov		buffer,0
	invoke PutItemInt,addr buffer,da.winres.htpro
	invoke PutItemInt,addr buffer,da.winres.wtpro
	invoke PutItemInt,addr buffer,da.winres.wttbx
	invoke PutItemInt,addr buffer,da.winres.ptstyle.x
	invoke PutItemInt,addr buffer,da.winres.ptstyle.y
	invoke WritePrivateProfileString,addr szIniWin,addr szIniPosRes,addr buffer[1],addr da.szRadASMIni
	mov		buffer,0
	invoke PutItemInt,addr buffer,da.resopt.gridx
	invoke PutItemInt,addr buffer,da.resopt.gridy
	invoke PutItemInt,addr buffer,da.resopt.fopt
	invoke WritePrivateProfileString,addr szIniResource,addr szIniOption,addr buffer[1],addr da.szRadASMIni
	ret

PutWinPos endp

GetProjectAssembler proc

	;Assembler
	invoke GetPrivateProfileString,addr szIniSession,addr szIniAssembler,NULL,addr da.szAssembler,sizeof da.szAssembler,addr da.szProject
	.if !eax
		mov		dword ptr da.szAssembler,'msam'
	.endif
	ret

GetProjectAssembler endp

GetSessionAssembler proc

	;Assembler
	invoke GetPrivateProfileString,addr szIniSession,addr szIniAssembler,NULL,addr da.szAssembler,sizeof da.szAssembler,addr da.szRadASMIni
	.if !eax
		mov		dword ptr da.szAssembler,'msam'
	.endif
	ret

GetSessionAssembler endp

GetProjectFiles proc uses ebx esi edi
	LOCAL	fi:FILEINFO
	LOCAL	pbi:PBITEM
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	chrg:CHARRANGE
	LOCAL	hEdt:HWND

	;File browser path
	invoke GetPrivateProfileString,addr szIniProject,addr szIniPath,addr da.szAppPath,addr da.szFBPath,sizeof da.szFBPath,addr da.szProject
	;Check if path exist
	invoke GetFileAttributes,addr da.szFBPath
	.if eax==INVALID_HANDLE_VALUE
		invoke strcpy,addr da.szFBPath,addr da.szProjectPath
	.endif
	invoke SendMessage,ha.hFileBrowser,FBM_SETPATH,TRUE,addr da.szFBPath
	;Get groups
	invoke GetPrivateProfileString,addr szIniProject,addr szIniGroup,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szProject
	.if eax
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETGROUPING,FALSE,RPBG_GROUPS
		invoke RtlZeroMemory,addr pbi,sizeof PBITEM
		invoke GetItemInt,addr tmpbuff,0
		.if sdword ptr eax>0
			invoke SendMessage,ha.hProjectBrowser,RPBM_SETGROUPING,FALSE,eax
		.endif
		xor		ebx,ebx
		.while tmpbuff
			invoke GetItemInt,addr tmpbuff,0
			mov		pbi.id,eax
			invoke GetItemInt,addr tmpbuff,0
			mov		pbi.idparent,eax
			invoke GetItemInt,addr tmpbuff,0
			mov		pbi.expanded,eax
			invoke GetItemStr,addr tmpbuff,addr szNULL,addr pbi.szitem
			invoke SendMessage,ha.hProjectBrowser,RPBM_ADDITEM,ebx,addr pbi
			inc		ebx
		.endw
		;Get files
		mov		esi,1
		.while esi<100
			invoke GetFileInfo,esi,addr szIniProject,addr da.szProject,addr fi
			.if eax
				invoke RtlZeroMemory,addr pbi,sizeof PBITEM
				mov		pbi.id,esi
				mov		eax,fi.idparent
				mov		pbi.idparent,eax
				invoke strcpy,addr pbi.szitem,addr fi.filename
				mov		eax,fi.ID
				mov		pbi.lParam,eax
				invoke GetFileAttributes,addr pbi.szitem
				.if eax!=INVALID_HANDLE_VALUE
					invoke SendMessage,ha.hProjectBrowser,RPBM_ADDITEM,ebx,addr pbi
					inc		ebx
				.endif
			.endif
			inc		esi
		.endw
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETGROUPING,TRUE,RPBG_GROUPS
		invoke SetProjectTab,1
		;Get open files
		mov		dword ptr buffer,'0F'
		invoke GetPrivateProfileString,addr szIniProject,addr buffer,addr szNULL,addr buffer,sizeof buffer,addr da.szProject
		.if eax
			push	da.win.fcldmax
			mov		da.win.fcldmax,FALSE
			;Selected tab
			invoke GetItemInt,addr buffer,0
			push	eax
			.while buffer
				invoke GetItemInt,addr buffer,0
				.if eax
					invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,eax,0
					.if eax
						invoke OpenTheFile,addr [eax].PBITEM.szitem,[eax].PBITEM.lParam
					.endif
				.endif
			.endw
			pop		eax
			invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
			.if eax==-1
				invoke SendMessage,ha.hTab,TCM_SETCURSEL,0,0
			.endif
			.if eax!=-1
				mov		eax,TRUE
			.else
				xor		eax,eax
			.endif
			pop		da.win.fcldmax
		.endif
	.endif
	ret

GetProjectFiles endp

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
			mov		eax,TRUE
		.else
			xor		eax,eax
		.endif
	.else
		xor		eax,eax
	.endif
	ret

GetSessionFiles endp

SaveProjectItem proc nInx:DWORD
	LOCAL	fi:FILEINFO
	LOCAL	buffer[8]:BYTE

	invoke SetFileInfo,nInx,addr fi
	.if eax
		mov		tmpbuff,0
		invoke PutItemInt,addr tmpbuff,fi.idparent
		invoke PutItemInt,addr tmpbuff,fi.ID
		invoke PutItemInt,addr tmpbuff,fi.rect.left
		invoke PutItemInt,addr tmpbuff,fi.rect.top
		invoke PutItemInt,addr tmpbuff,fi.rect.right
		invoke PutItemInt,addr tmpbuff,fi.rect.bottom
		invoke PutItemInt,addr tmpbuff,fi.nline
		invoke PutItemStr,addr tmpbuff,addr fi.filename
		mov		buffer,'F'
		invoke BinToDec,fi.pid,addr buffer[1]
		invoke WritePrivateProfileString,addr szIniProject,addr buffer,addr tmpbuff[1],addr da.szProject
	.endif
	ret

SaveProjectItem endp

PutProject proc uses ebx esi edi
	LOCAL	tci:TC_ITEM
	LOCAL	fi:FILEINFO
	LOCAL	buffer[8]:BYTE

	mov		dword ptr buffer,0
	invoke WritePrivateProfileSection,addr szIniSession,addr buffer,addr da.szRadASMIni
	;Project
	invoke WritePrivateProfileString,addr szIniSession,addr szIniProject,addr da.szProject,addr da.szRadASMIni
	;File browser path
	invoke WritePrivateProfileString,addr szIniProject,addr szIniPath,addr da.szFBPath,addr da.szProject
	;Project groups
	mov		tmpbuff,0
	;Update expanded flags
	invoke SendMessage,ha.hProjectBrowser,RPBM_GETEXPAND,0,0
	;Get selected grouping
	invoke SendMessage,ha.hProjectBrowser,RPBM_GETGROUPING,0,0
	invoke PutItemInt,addr tmpbuff,eax
	;Get groups
	xor		ebx,ebx
	.while TRUE
		invoke SendMessage,ha.hProjectBrowser,RPBM_GETITEM,ebx,0
		.break .if !eax
		mov		esi,eax
		.break .if ![esi].PBITEM.id
		.if sdword ptr [esi].PBITEM.id<0
			invoke PutItemInt,addr tmpbuff,[esi].PBITEM.id
			invoke PutItemInt,addr tmpbuff,[esi].PBITEM.idparent
			invoke PutItemInt,addr tmpbuff,[esi].PBITEM.expanded
			invoke PutItemStr,addr tmpbuff,addr [esi].PBITEM.szitem
		.endif
		inc		ebx
	.endw
	invoke WritePrivateProfileString,addr szIniProject,addr szIniGroup,addr tmpbuff[1],addr da.szProject
	;Get open project files
	mov		dword ptr tmpbuff,0
	.if ha.hMdi
		invoke ShowWindow,ha.hClient,SW_HIDE
		mov		eax,da.win.fcldmax
		push	eax
		.if eax
			invoke SendMessage,ha.hClient,WM_MDIRESTORE,ha.hMdi,0
		.endif
		invoke SendMessage,ha.hTab,TCM_GETCURSEL,0,0
		invoke PutItemInt,addr tmpbuff,eax
		xor		ebx,ebx
		.while TRUE
			mov		tci.imask,TCIF_PARAM
			invoke SendMessage,ha.hTab,TCM_GETITEM,ebx,addr tci
			.break .if !eax
			mov		esi,tci.lParam
			mov		eax,[esi].TABMEM.pid
			.if eax
				invoke PutItemInt,addr tmpbuff,eax
			.endif
			inc		ebx
		.endw
		pop		da.win.fcldmax
		invoke ShowWindow,ha.hClient,SW_SHOWNA
	.endif
	mov		dword ptr buffer,'0F'
	invoke WritePrivateProfileString,addr szIniProject,addr buffer,addr tmpbuff[1],addr da.szProject
	ret

PutProject endp

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

DeleteDuplicates proc uses esi edi,lpszType:DWORD
	LOCAL	nCount:DWORD

	invoke SendMessage,ha.hProperty,PRM_GETSORTEDLIST,lpszType,addr nCount
	mov		esi,eax
	push	esi
	xor		ecx,ecx
	mov		edi,offset szNULL
	.while ecx<nCount
		push	ecx
		invoke strcmp,edi,[esi]
		.if !eax
			mov		eax,[esi]
			lea		eax,[eax-sizeof PROPERTIES]
			mov		[eax].PROPERTIES.nType,255
		.else
			mov		edi,[esi]
		.endif
		pop		ecx
		inc		ecx
		lea		esi,[esi+4]
	.endw
	pop		esi
	invoke GlobalFree,esi
	invoke SendMessage,ha.hProperty,PRM_COMPACTLIST,FALSE,0
	ret

DeleteDuplicates endp

GetCodeComplete proc uses ebx esi edi
	LOCAL	buffer[256]:BYTE
	LOCAL	apifile[MAX_PATH]:BYTE

	invoke GetPrivateProfileString,addr szIniCodeComplete,addr szIniTrig,NULL,addr da.szCCTrig,sizeof da.szCCTrig,addr da.szAssemblerIni
	invoke GetPrivateProfileString,addr szIniCodeComplete,addr szIniInc,NULL,addr da.szCCInc,sizeof da.szCCInc,addr da.szAssemblerIni
	invoke GetPrivateProfileString,addr szIniCodeComplete,addr szIniLib,NULL,addr da.szCCLib,sizeof da.szCCLib,addr da.szAssemblerIni

	invoke GetPrivateProfileString,addr szIniCodeComplete,addr szIniApi,NULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
	.while tmpbuff
		invoke GetItemStr,addr tmpbuff,addr szNULL,addr buffer
		movzx	ebx,buffer
		invoke GetItemStr,addr tmpbuff,addr szNULL,addr buffer
		.if ebx && buffer
			invoke strcpy,addr apifile,addr da.szAppPath
			invoke strcat,addr apifile,addr szBSApiBS
			invoke strcat,addr apifile,addr buffer
			invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYFILE,ebx,addr apifile
		.endif
	.endw
	;Add 'C' list to 'W' list
	mov		dword ptr buffer,'C'
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[1]
	.while eax
		mov		esi,eax
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		invoke strcpy,offset tmpbuff,esi
		mov		eax,2 shl 8 or 'W'
		invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYLIST,eax,offset tmpbuff
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	;Add 'M' list to 'W' list
	mov		dword ptr buffer,'M'
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[1]
	.while eax
		mov		esi,eax
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		.while byte ptr [esi]
			.if byte ptr [esi]=='['
				inc		esi
				mov		edi,offset tmpbuff
				.while byte ptr [esi]!=']'
					mov		al,[esi]
					mov		[edi],al
					inc		esi
					inc		edi
				.endw
				mov		byte ptr [edi],0
				mov		eax,2 shl 8 or 'W'
				invoke SendMessage,ha.hProperty,PRM_ADDPROPERTYLIST,eax,offset tmpbuff
			.endif
			inc		esi
		.endw
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	;Delete duplicates
	mov		dword ptr buffer,'W'
	invoke DeleteDuplicates,addr buffer
	ret

GetCodeComplete endp

GetKeywords proc uses esi edi
	LOCAL	hMem:HGLOBAL
	LOCAL	buffer[16]:BYTE
	LOCAL	nInx:DWORD

	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,65536*8
	mov		hMem,eax
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
	;Add api calls to Group#15
	invoke RtlZeroMemory,hMem,65536*8
	mov		dword ptr buffer,'P'
	mov		edi,hMem
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[2]
	.while eax
		mov		byte ptr [edi],'^'
		inc		edi
		invoke strcpy,edi,eax
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		byte ptr [edi],' '
		inc		edi
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,da.radcolor.kwcol[15*4],hMem
	;Add api constants to Group#14
	invoke RtlZeroMemory,hMem,65536*8
	mov		dword ptr buffer,'C'
	mov		edi,hMem
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[2]
	mov		esi,eax
	.while esi
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		mov		byte ptr [edi],'^'
		inc		edi
		.while byte ptr [esi]
			mov		al,[esi]
			.if al==','
				mov		byte ptr [edi],' '
				inc		edi
				mov		al,'^'
			.endif
			mov		[edi],al
			inc		esi
			inc		edi
		.endw
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
		mov		esi,eax
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,da.radcolor.kwcol[14*4],hMem
	;Add api words to Group#14
	invoke RtlZeroMemory,hMem,65536*8
	mov		dword ptr buffer,'W'
	mov		edi,hMem
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[2]
	.while eax
		mov		byte ptr [edi],'^'
		inc		edi
		invoke strcpy,edi,eax
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		byte ptr [edi],' '
		inc		edi
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,da.radcolor.kwcol[14*4],hMem
	;Add api structs to Group#13
	invoke RtlZeroMemory,hMem,65536*8
	mov		dword ptr buffer,'S'
	mov		edi,hMem
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[2]
	.while eax
		mov		byte ptr [edi],'^'
		inc		edi
		invoke strcpy,edi,eax
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		byte ptr [edi],' '
		inc		edi
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,da.radcolor.kwcol[13*4],hMem
	;Add api types to Group#12
	invoke RtlZeroMemory,hMem,65536*8
	mov		dword ptr buffer,'T'
	mov		edi,hMem
	invoke SendMessage,ha.hProperty,PRM_FINDFIRST,addr buffer,addr buffer[2]
	.while eax
		mov		cl,[eax]
		mov		ch,cl
		and		cl,5Fh
		.if cl==ch
			;Case sensitive
			mov		byte ptr [edi],'^'
			inc		edi
		.endif
		invoke strcpy,edi,eax
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		byte ptr [edi],' '
		inc		edi
		invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
	.endw
	mov		byte ptr [edi],0
	invoke SetHiliteWords,da.radcolor.kwcol[12*4],hMem
	invoke GlobalFree,hMem
	ret

GetKeywords endp

