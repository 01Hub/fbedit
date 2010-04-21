.code

AddNewProjectFile proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke SendMessage,ha.hProjectBrowser,RPBM_GETSELECTED,0,0
	.if eax
		;Zero out the ofn struct
	    invoke RtlZeroMemory,addr ofn,sizeof ofn
		;Setup the ofn struct
		mov		ofn.lStructSize,sizeof ofn
		push	ha.hWnd
		pop		ofn.hwndOwner
		push	ha.hInstance
		pop		ofn.hInstance
		mov		ofn.lpstrFilter,offset da.szALLString
		invoke strcpy,addr buffer,addr szNULL
		lea		eax,buffer
		mov		ofn.lpstrFile,eax
		mov		ofn.nMaxFile,sizeof buffer
		mov		ofn.Flags,OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT
	    mov		ofn.lpstrDefExt,offset szNULL
	    mov		ofn.lpstrTitle,offset szAddNewProjectFile
	    ;Show save as dialog
		invoke GetSaveFileName,addr ofn
		.if eax
			invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,0,addr buffer
			.if !eax
				invoke UpdateAll,UAM_ISOPENACTIVATE,addr buffer
				.if eax==-1
					invoke CreateFile,addr buffer,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
					.if eax!=INVALID_HANDLE_VALUE
						invoke CloseHandle,eax
						invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWFILE,0,addr buffer
						invoke OpenTheFile,addr buffer,0
					.endif
				.endif
			.endif
		.endif
	.endif
	ret

AddNewProjectFile endp

AddExistingProjectFiles proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	hMem:HGLOBAL
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	nOpen:DWORD

	mov		nOpen,0
	invoke SendMessage,ha.hProjectBrowser,RPBM_GETSELECTED,0,0
	.if eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8192
		mov		hMem,eax
		mov		esi,eax
		;Zero out the ofn struct
		invoke RtlZeroMemory,addr ofn,sizeof ofn
		;Setup the ofn struct
		mov		ofn.lStructSize,sizeof ofn
		push	ha.hWnd
		pop		ofn.hwndOwner
		push	ha.hInstance
		pop		ofn.hInstance
		mov		ofn.lpstrFilter,offset da.szALLString
		mov		ofn.lpstrFile,esi
		mov		ofn.nMaxFile,8192
		mov		ofn.lpstrDefExt,NULL
		mov		ofn.lpstrInitialDir,offset da.szProjectPath
		mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_ALLOWMULTISELECT or OFN_EXPLORER
	    mov		ofn.lpstrTitle,offset szAddExistingProjectFiles
		;Show the Open dialog
		invoke GetOpenFileName,addr ofn
		.if eax
			invoke strlen,esi
			.if byte ptr [esi+eax+1]
				;Multiselect
				mov		edi,esi
				lea		esi,[esi+eax+1]
				.while byte ptr [esi]
					invoke strcpy,addr buffer,edi
					invoke strcat,addr buffer,addr szBS
					invoke strcat,addr buffer,esi
					invoke UpdateAll,UAM_ISOPENACTIVATE,addr buffer
					.if eax==-1
						invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWFILE,0,addr buffer
						invoke OpenTheFile,addr buffer,0
						invoke GetWindowLong,ha.hEdt,GWL_ID
						.if eax==ID_EDITCODE
							invoke GetWindowLong,ha.hEdt,GWL_USERDATA
							invoke ParseEdit,ha.hMdi,[eax].TABMEM.pid
						.endif
						inc		nOpen
					.endif
					invoke strlen,esi
					lea		esi,[esi+eax+1]
				.endw
			.else
				;Single file
				invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,0,esi
				.if !eax
					invoke UpdateAll,UAM_ISOPENACTIVATE,esi
					.if eax==-1
						invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWFILE,0,esi
						invoke OpenTheFile,esi,0
						invoke GetWindowLong,ha.hEdt,GWL_ID
						.if eax==ID_EDITCODE
							invoke GetWindowLong,ha.hEdt,GWL_USERDATA
							invoke ParseEdit,ha.hMdi,[eax].TABMEM.pid
						.endif
						mov		nOpen,1
					.endif
				.endif
			.endif
		.endif
		invoke GlobalFree,hMem
	.endif
	mov		eax,nOpen
	ret

AddExistingProjectFiles endp

AddOpenProjectFile proc uses ebx

	invoke GetWindowLong,ha.hEdt,GWL_USERDATA
	mov		ebx,eax
	invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,0,addr [ebx].TABMEM.filename
	.if !eax
		invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWFILE,0,addr [ebx].TABMEM.filename
		mov		eax,[eax].PBITEM.id
		mov		[ebx].TABMEM.pid,eax
		invoke GetWindowLong,[ebx].TABMEM.hedt,GWL_ID
		.if eax==ID_EDITCODE
			invoke ParseEdit,[ebx].TABMEM.hwnd,[ebx].TABMEM.pid
		.endif
	.endif
	ret

AddOpenProjectFile endp

AddAllOpenProjectFiles proc uses ebx edi
	LOCAL	tci:TC_ITEM

	xor		edi,edi
	mov		tci.imask,TCIF_PARAM
	.while TRUE
		invoke SendMessage,ha.hTab,TCM_GETITEM,edi,addr tci
		.break .if !eax
		mov		ebx,tci.lParam
		invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,0,addr [ebx].TABMEM.filename
		.if !eax
			invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWFILE,0,addr [ebx].TABMEM.filename
			mov		eax,[eax].PBITEM.id
			mov		[ebx].TABMEM.pid,eax
			invoke GetWindowLong,[ebx].TABMEM.hedt,GWL_ID
			.if eax==ID_EDITCODE
				invoke ParseEdit,[ebx].TABMEM.hwnd,[ebx].TABMEM.pid
			.endif
		.endif
		inc		edi
	.endw
	ret

AddAllOpenProjectFiles endp

OpenProjectItemFile proc uses ebx

	invoke SendMessage,ha.hProjectBrowser,RPBM_GETSELECTED,0,0
	.if eax
		mov		ebx,eax
		invoke UpdateAll,UAM_ISOPENACTIVATE,addr [ebx].PBITEM.szitem
		.if eax==-1
			invoke OpenTheFile,addr [ebx].PBITEM.szitem,0
		.endif
	.endif
	ret

OpenProjectItemFile endp

OpenProjectItemGroup proc uses ebx esi edi

	invoke SendMessage,ha.hProjectBrowser,RPBM_GETSELECTED,0,0
	.if eax
		mov		edi,[eax].PBITEM.id
		xor		esi,esi
		.while TRUE
			invoke SendMessage,ha.hProjectBrowser,RPBM_GETITEM,esi,0
			.break .if !eax
			.if sdword ptr [eax].PBITEM.id>0 && edi==[eax].PBITEM.idparent
				mov		ebx,eax
				invoke UpdateAll,UAM_ISOPENACTIVATE,addr [ebx].PBITEM.szitem
				.if eax==-1
					invoke OpenTheFile,addr [ebx].PBITEM.szitem,0
				.endif
			.endif
			inc		esi
		.endw
	.endif
	ret

OpenProjectItemGroup endp

RemoveProjectFile proc uses ebx

	invoke SendMessage,ha.hProjectBrowser,RPBM_GETSELECTED,0,0
	.if eax
		mov		ebx,eax
		invoke UpdateAll,UAM_ISOPEN,addr [ebx].PBITEM.szitem
		.if eax!=-1
			invoke GetWindowLong,eax,GWL_USERDATA
			invoke GetWindowLong,eax,GWL_USERDATA
			mov		[eax].TABMEM.pid,0
		.endif
		invoke SendMessage,ha.hProperty,PRM_DELPROPERTY,[ebx].PBITEM.id,0
		invoke SendMessage,ha.hProperty,PRM_REFRESHLIST,0,0
		invoke SendMessage,ha.hProjectBrowser,RPBM_DELETEITEM,0,0
	.endif
	ret

RemoveProjectFile endp

GetProjectFiles proc uses ebx esi edi
	LOCAL	fi:FILEINFO
	LOCAL	pbi:PBITEM
	LOCAL	buffer[MAX_PATH]:BYTE

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
			pop		da.win.fcldmax
			invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
			.if eax==-1
				invoke SendMessage,ha.hTab,TCM_SETCURSEL,0,0
			.endif
			.if eax!=-1
				invoke TabToolActivate
				.if da.win.fcldmax
					invoke SendMessage,ha.hClient,WM_MDIMAXIMIZE,ha.hMdi,0
				.endif
			.endif
		.endif
	.endif
	ret

GetProjectFiles endp

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
	LOCAL	buffer[8]:BYTE

	mov		dword ptr buffer,0
	invoke WritePrivateProfileSection,addr szIniSession,addr buffer,addr da.szRadASMIni
	;Project
	invoke WritePrivateProfileString,addr szIniSession,addr szIniProject,addr da.szProject,addr da.szRadASMIni
	;File browser path
	invoke WritePrivateProfileString,addr szIniProject,addr szIniPath,addr da.szFBPath,addr da.szProject
	;Project groups
	mov		tmpbuff,0
	;Refresh expanded flags
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
	;Remove files not longer in project
	mov		ebx,1
	.while ebx<100
		mov		buffer,'F'
		invoke BinToDec,ebx,addr buffer[1]
		invoke GetPrivateProfileString,addr szIniProject,addr buffer,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szProject
		.if eax
			invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,ebx,0
			.if !eax
				;Remove it from project file
				invoke WritePrivateProfileString,addr szIniProject,addr buffer,addr szNULL,addr da.szProject
			.endif
		.endif
		inc		ebx
	.endw
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

CloseProject proc

	invoke UpdateAll,UAM_SAVEALL,TRUE
	.if eax
		.if da.fProject
			invoke PutProject
		.endif
		invoke UpdateAll,UAM_CLOSEALL,0
		invoke SendMessage,ha.hProperty,PRM_DELPROPERTY,0,0
		invoke SendMessage,ha.hProjectBrowser,RPBM_ADDITEM,0,0
		invoke SendMessage,ha.hProjectBrowser,RPBM_SETGROUPING,TRUE,RPBG_NOCHANGE
		invoke SetProjectTab,0
		invoke SendMessage,ha.hProperty,PRM_REFRESHLIST,0,0
		mov		da.fProject,0
		mov		da.szProject,0
		mov		da.szProjectPath,0
		mov		eax,TRUE
	.else
		xor		eax,eax
	.endif
	ret

CloseProject endp

