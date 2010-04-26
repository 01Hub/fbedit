.code

StreamInProc proc hFile:DWORD,pBuffer:DWORD,NumBytes:DWORD,pBytesRead:DWORD

	invoke ReadFile,hFile,pBuffer,NumBytes,pBytesRead,0
	xor		eax,1
	ret

StreamInProc endp

StreamOutProc proc hFile:DWORD,pBuffer:DWORD,NumBytes:DWORD,pBytesWritten:DWORD

	invoke WriteFile,hFile,pBuffer,NumBytes,pBytesWritten,0
	xor		eax,1
	ret

StreamOutProc endp

GetTheFileType proc uses esi,lpFileName:DWORD
	LOCAL	ftpe[256]:BYTE

	mov		esi,lpFileName
	invoke strlen,esi
	.while byte ptr [esi+eax]!='.' && eax
		dec		eax
	.endw
	.if byte ptr [esi+eax]=='.'
		invoke strcpy,addr ftpe,addr [esi+eax]
		invoke strcat,addr ftpe,addr szDot
		invoke IsFileType,addr ftpe,addr da.szCodeFiles
		.if eax
			mov		eax,ID_EDITCODE
			jmp		Ex
		.endif
		invoke IsFileType,addr ftpe,addr da.szTextFiles
		.if eax
			mov		eax,ID_EDITTEXT
			jmp		Ex
		.endif
		invoke IsFileType,addr ftpe,addr da.szHexFiles
		.if eax
			mov		eax,ID_EDITHEX
			jmp		Ex
		.endif
		invoke IsFileType,addr ftpe,addr da.szResourceFiles
		.if eax
			mov		eax,ID_EDITRES
			jmp		Ex
		.endif
		invoke IsFileType,addr ftpe,addr da.szProjectFiles
		.if eax
			mov		eax,ID_PROJECT
			jmp		Ex
		.endif
		mov		eax,ID_EDITTEXT
	.else
		mov		eax,ID_EDITTEXT
	.endif
  Ex:
	ret

GetTheFileType endp

LoadTextFile proc uses ebx esi,hWin:DWORD,lpFileName:DWORD
    LOCAL   hFile:HANDLE
	LOCAL	editstream:EDITSTREAM

	;Open the file
	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke SendMessage,hWin,WM_SETTEXT,0,addr szNULL
		;stream the text into the RAEdit control
		mov		eax,hFile
		mov		editstream.dwCookie,eax
		mov		editstream.pfnCallback,offset StreamInProc
		invoke SendMessage,hWin,EM_STREAMIN,SF_TEXT,addr editstream
		invoke CloseHandle,hFile
		invoke SendMessage,hWin,EM_SETMODIFY,FALSE,0
		invoke SendMessage,hWin,REM_SETCHANGEDSTATE,FALSE,0
		mov		da.nLastPropLine,-1
		mov		eax,FALSE
	.else
		invoke strcpy,offset tmpbuff,offset szOpenFileFail
		invoke strcat,offset tmpbuff,lpFileName
		invoke MessageBox,ha.hWnd,offset tmpbuff,offset DisplayName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadTextFile endp

LoadHexFile proc uses ebx esi,hWin:DWORD,lpFileName:DWORD
    LOCAL   hFile:HANDLE
	LOCAL	editstream:EDITSTREAM

	;Open the file
	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		;stream the text into the RAHexEd control
		mov		eax,hFile
		mov		editstream.dwCookie,eax
		mov		editstream.pfnCallback,offset StreamInProc
		invoke SendMessage,hWin,EM_STREAMIN,SF_TEXT,addr editstream
		invoke CloseHandle,hFile
		invoke SendMessage,hWin,EM_SETMODIFY,FALSE,0
		mov		eax,FALSE
	.else
		invoke strcpy,offset tmpbuff,offset szOpenFileFail
		invoke strcat,offset tmpbuff,lpFileName
		invoke MessageBox,ha.hWnd,offset tmpbuff,offset DisplayName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadHexFile endp

LoadResFile proc uses ebx esi,hWin:DWORD,lpFileName:DWORD
    LOCAL   hFile:HANDLE
	LOCAL	hMem:HGLOBAL
	LOCAL	dwRead:DWORD

	;Open the file
	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke GetFileSize,hFile,NULL
		push	eax
		inc		eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
		mov     hMem,eax
		invoke GlobalLock,hMem
		pop		edx
		invoke ReadFile,hFile,hMem,edx,addr dwRead,NULL
		invoke CloseHandle,hFile
		invoke SendMessage,hWin,PRO_OPEN,lpFileName,hMem
		mov		eax,FALSE
	.else
		invoke strcpy,offset tmpbuff,offset szOpenFileFail
		invoke strcat,offset tmpbuff,lpFileName
		invoke MessageBox,ha.hWnd,offset tmpbuff,offset DisplayName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadResFile endp

OpenTheFile proc uses ebx esi edi,lpFileName:DWORD,ID:DWORD
	LOCAL	chrg:CHARRANGE
	LOCAL	hEdt:HWND
	LOCAL	fi:FILEINFO

	xor		edi,edi
	invoke GetFileAttributes,lpFileName
	.if eax!=INVALID_HANDLE_VALUE
		.if ID
			mov		eax,ID
		.else
			invoke GetTheFileType,lpFileName
			.if eax==ID_EDITRES
				invoke GetKeyState,VK_CONTROL
				test	eax,80h
				.if !ZERO?
					;Open resource file as code file
					mov		eax,ID_EDITCODE
				.else
					mov		eax,ID_EDITRES
				.endif
			.endif
		.endif
		.if eax==ID_EDITCODE
			invoke strcpy,addr da.szFileName,lpFileName
			invoke MakeMdiCldWin,ID_EDITCODE
			mov		edi,eax
			invoke GetWindowLong,edi,GWL_USERDATA
			mov		hEdt,eax
			invoke GetTheFileType,lpFileName
			.if eax==ID_EDITRES
				;Resource file as code file
				invoke SendMessage,hEdt,REM_SETWORDGROUP,0,1
			.endif
			invoke LoadTextFile,hEdt,lpFileName
			invoke SendMessage,hEdt,REM_SETBLOCKS,0,0
			invoke SendMessage,hEdt,REM_SETCOMMENTBLOCKS,addr da.szCmntStart,addr da.szCmntEnd
		.elseif eax==ID_EDITTEXT
			invoke strcpy,addr da.szFileName,lpFileName
			invoke MakeMdiCldWin,ID_EDITTEXT
			mov		edi,eax
			invoke GetWindowLong,edi,GWL_USERDATA
			mov		hEdt,eax
			invoke LoadTextFile,hEdt,lpFileName
		.elseif eax==ID_EDITHEX
			invoke strcpy,addr da.szFileName,lpFileName
			invoke MakeMdiCldWin,ID_EDITHEX
			mov		edi,eax
			invoke GetWindowLong,edi,GWL_USERDATA
			mov		hEdt,eax
			invoke LoadHexFile,hEdt,lpFileName
		.elseif eax==ID_EDITRES
			invoke UpdateAll,UAM_ISRESOPEN,0
			.if eax==-1
				invoke strcpy,addr da.szFileName,lpFileName
				invoke MakeMdiCldWin,ID_EDITRES
				mov		edi,eax
				invoke GetWindowLong,edi,GWL_USERDATA
				mov		hEdt,eax
				invoke LoadResFile,hEdt,lpFileName
			.else
				invoke TabToolGetInx,eax
				push	eax
				invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
				invoke TabToolActivate
				mov		edi,ha.hMdi
				invoke SendMessage,ha.hEdt,PRO_CLOSE,0,0
				invoke LoadResFile,ha.hEdt,lpFileName
				pop		eax
				invoke TabToolSetText,eax,lpFileName
				invoke SetWinCaption,edi,lpFileName
				invoke TabToolActivate
			.endif
		.elseif eax==ID_EDITUSER
		.elseif eax==ID_PROJECT
			;Check version
			invoke GetPrivateProfileInt,addr szIniVersion,addr szIniVersion,0,lpFileName
			.if eax<3000
				invoke MessageBox,ha.hWnd,addr szProjectVersion,addr DisplayName,MB_OK or MB_ICONERROR
			.else
				invoke CloseProject
				.if eax
					invoke strcpy,addr da.szProjectFile,lpFileName
					invoke strcpy,addr da.szProjectPath,addr da.szProjectFile
					invoke strlen,addr da.szProjectPath
					.while da.szProjectPath[eax]!='\' && eax
						dec		eax
					.endw
					mov		da.szProjectPath[eax],0
					mov		da.fProject,TRUE
					;Assembler
					invoke GetPrivateProfileString,addr szIniSession,addr szIniAssembler,NULL,addr da.szAssembler,sizeof da.szAssembler,addr da.szProjectFile
					.if !eax
						mov		dword ptr da.szAssembler,'msam'
						mov		dword ptr da.szAssembler[4],0
					.endif
					invoke OpenAssembler
					invoke GetProjectFiles
				.endif
			.endif
		.elseif eax==ID_EXTERNAL
		.endif
		.if edi
			invoke TabToolSetChanged,edi,FALSE
			.if da.fProject
				invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,0,lpFileName
				.if eax
					mov		esi,eax
					invoke GetFileInfo,[esi].PBITEM.id,addr szIniProject,addr da.szProjectFile,addr fi
					.if eax
						invoke GetWindowLong,hEdt,GWL_USERDATA
						mov		ebx,eax
						mov		eax,fi.pid
						mov		[ebx].TABMEM.pid,eax
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
				.endif
			.endif
		.endif
	.endif
	mov		eax,edi
	ret

OpenTheFile endp

OpenEditFile proc ID:DWORD
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE

	;Zero out the ofn struct
	invoke RtlZeroMemory,addr ofn,sizeof ofn
	;Setup the ofn struct
	mov		ofn.lStructSize,sizeof ofn
	push	ha.hWnd
	pop		ofn.hwndOwner
	push	ha.hInstance
	pop		ofn.hInstance
	.if ID==ID_EDITHEX
		mov		ofn.lpstrFilter,offset da.szANYString
	.elseif ID==ID_PROJECT
		mov		ofn.lpstrFilter,offset da.szPROString
	.else
		mov		ofn.lpstrFilter,offset da.szALLString
	.endif
	mov		buffer[0],0
	lea		eax,buffer
	mov		ofn.lpstrFile,eax
	mov		ofn.nMaxFile,sizeof buffer
	mov		ofn.lpstrDefExt,NULL
	invoke GetCurrentDirectory,sizeof buffer1,addr buffer1
	lea		eax,buffer1
	mov		ofn.lpstrInitialDir,eax
	mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
	;Show the Open dialog
	invoke GetOpenFileName,addr ofn
	.if eax
		invoke UpdateAll,UAM_ISOPENACTIVATE,addr buffer
		.if eax==-1
			invoke OpenTheFile,addr buffer,ID
		.endif
	.endif
	ret

OpenEditFile endp

SaveTextFile proc hWin:DWORD,lpFileName:DWORD
	LOCAL	hFile:HANDLE
	LOCAL	editstream:EDITSTREAM

	invoke CreateFile,lpFileName,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		;stream the text to the file
		mov		eax,hFile
		mov		editstream.dwCookie,eax
		mov		editstream.pfnCallback,offset StreamOutProc
		invoke SendMessage,hWin,EM_STREAMOUT,SF_TEXT,addr editstream
		invoke CloseHandle,hFile
		;Set the modify state to false
		invoke SendMessage,hWin,EM_SETMODIFY,FALSE,0
		invoke GetWindowLong,hWin,GWL_ID
		.if eax==ID_EDITCODE
;			invoke SaveBreakpoints,hWin
;			invoke SaveBookMarks,hWin
;			invoke SaveCollapse,hWin
		.endif
		invoke SendMessage,hWin,REM_SETCHANGEDSTATE,TRUE,0
		invoke GetParent,hWin
		invoke TabToolSetChanged,eax,FALSE
   		mov		eax,FALSE
	.endif
	ret

SaveTextFile endp

SaveHexFile proc hWin:DWORD,lpFileName:DWORD
	LOCAL	hFile:HANDLE
	LOCAL	editstream:EDITSTREAM

	invoke CreateFile,lpFileName,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		;stream the text to the file
		mov		eax,hFile
		mov		editstream.dwCookie,eax
		mov		editstream.pfnCallback,offset StreamOutProc
		invoke SendMessage,hWin,EM_STREAMOUT,SF_TEXT,addr editstream
		invoke CloseHandle,hFile
		;Set the modify state to false
		invoke SendMessage,hWin,EM_SETMODIFY,FALSE,0
		invoke GetParent,hWin
		invoke TabToolSetChanged,eax,FALSE
   		mov		eax,FALSE
	.endif
	ret

SaveHexFile endp

SaveResFile proc hWin:DWORD,lpFileName:DWORD
	LOCAL	hFile:HANDLE
	LOCAL	hMem:HGLOBAL
	LOCAL	nSize:DWORD

	invoke CreateFile,lpFileName,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
		mov		hMem,eax
		invoke SendMessage,hWin,PRO_EXPORT,0,hMem
		invoke strlen,hMem
		mov		nSize,eax
		invoke WriteFile,hFile,hMem,nSize,addr nSize,NULL
		invoke CloseHandle,hFile
		invoke SendMessage,hWin,PRO_SETMODIFY,FALSE,0
		invoke GlobalFree,hMem
		invoke GetParent,hWin
		invoke TabToolSetChanged,eax,FALSE
   		mov		eax,FALSE
	.endif
	ret

SaveResFile endp

SaveTheFile proc uses ebx,hWin:HWND
	LOCAL	hEdt:HWND

	invoke GetWindowLong,hWin,GWL_USERDATA
	mov		hEdt,eax
	invoke GetWindowLong,hEdt,GWL_USERDATA
	mov		ebx,eax
	invoke GetWindowLong,hEdt,GWL_ID
	.if eax==ID_EDITCODE
		invoke SaveTextFile,hEdt,addr [ebx].TABMEM.filename
	.elseif eax==ID_EDITTEXT
		invoke SaveTextFile,hEdt,addr [ebx].TABMEM.filename
	.elseif eax==ID_EDITHEX
		invoke SaveHexFile,hEdt,addr [ebx].TABMEM.filename
	.elseif eax==ID_EDITRES
		invoke SaveResFile,hEdt,addr [ebx].TABMEM.filename
	.elseif eax==ID_EDITUSER
		xor		eax,eax
	.endif
	ret

SaveTheFile endp

WantToSave proc uses ebx,hWin:HWND
	LOCAL	hEdt:HWND

	invoke GetWindowLong,hWin,GWL_USERDATA
	mov		hEdt,eax
	invoke GetWindowLong,hEdt,GWL_USERDATA
	mov		ebx,eax
	invoke GetWindowLong,hEdt,GWL_ID
	.if eax==ID_EDITCODE
		invoke SendMessage,hEdt,EM_GETMODIFY,0,0
	.elseif eax==ID_EDITTEXT
		invoke SendMessage,hEdt,EM_GETMODIFY,0,0
	.elseif eax==ID_EDITHEX
		invoke SendMessage,hEdt,EM_GETMODIFY,0,0
	.elseif eax==ID_EDITRES
		invoke SendMessage,hEdt,PRO_GETMODIFY,0,0
	.elseif eax==ID_EDITUSER
		xor		eax,eax
	.endif
	.if eax
		invoke TabToolGetInx,[ebx].TABMEM.hwnd
		invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
		invoke TabToolActivate
		invoke strcpy,addr tmpbuff,offset szWannaSave
		invoke strcat,addr tmpbuff,addr [ebx].TABMEM.filename
		invoke strlen,addr tmpbuff
		mov		word ptr tmpbuff[eax],'?'
		invoke MessageBox,ha.hWnd,addr tmpbuff,offset DisplayName,MB_YESNOCANCEL or MB_ICONQUESTION
		.if eax==IDYES
			invoke SaveTheFile,hWin
		.elseif eax==IDNO
		    mov		eax,FALSE
		.else
		    mov		eax,TRUE
		.endif
	.endif
	ret

WantToSave endp

UpdateFileName proc hWin:DWORD,lpFileName:DWORD
	LOCAL	hEdt:HWND

	invoke GetWindowLong,hWin,GWL_USERDATA
	mov		hEdt,eax
	invoke GetWindowLong,hEdt,GWL_USERDATA
	mov		ebx,eax
	invoke GetWindowLong,hEdt,GWL_ID
	.if eax==ID_EDITCODE
		invoke SaveTextFile,hEdt,lpFileName
	.elseif eax==ID_EDITTEXT
		invoke SaveTextFile,hEdt,lpFileName
	.elseif eax==ID_EDITHEX
		invoke SaveHexFile,hEdt,lpFileName
	.elseif eax==ID_EDITRES
		invoke SaveResFile,hEdt,lpFileName
	.elseif eax==ID_EDITUSER
		xor		eax,eax
	.endif
	.if !eax
		;The file was saved
		invoke TabToolGetInx,hWin
		invoke TabToolSetText,eax,lpFileName
		invoke SetWinCaption,hWin,lpFileName
;		.if da.fProject
;			invoke SendMessage,ha.hPbr,RPBM_FINDITEM,0,lpFileName
;			.if eax
;				invoke lstrcpy,addr [eax].PBITEM.szitem,addr buffer
;				invoke SendMessage,ha.hPbr,RPBM_SETGROUPING,TRUE,RPBG_NOCHANGE
;			.endif
;		.endif
		mov		eax,FALSE
	.endif
	ret

UpdateFileName endp

SaveFileAs proc hWin:DWORD,lpFileName:DWORD
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	;Zero out the ofn struct
    invoke RtlZeroMemory,addr ofn,sizeof ofn
	;Setup the ofn struct
	mov		ofn.lStructSize,sizeof ofn
	push	hWin
	pop		ofn.hwndOwner
	push	ha.hInstance
	pop		ofn.hInstance
	mov		ofn.lpstrFilter,NULL
	invoke strcpy,addr buffer,lpFileName
	lea		eax,buffer
	mov		ofn.lpstrFile,eax
	mov		ofn.nMaxFile,sizeof buffer
	invoke GetWindowLong,hWin,GWL_USERDATA
	invoke GetWindowLong,eax,GWL_ID
	.if eax==ID_EDITCODE || eax==ID_EDITTEXT
;		mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT or OFN_EXPLORER or OFN_ENABLETEMPLATE or OFN_ENABLEHOOK
		mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT or OFN_EXPLORER
;		mov		ofn.lpTemplateName,IDD_DLGSAVEUNICODE
;		mov		ofn.lpfnHook,offset UnicodeProc
;		invoke SendMessage,hWin,REM_GETUNICODE,0,0
;		mov		fUnicode,eax
	.else
;		xor		eax,eax
;		mov		fUnicode,eax
		mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT or OFN_EXPLORER
	.endif
    mov		ofn.lpstrDefExt,NULL
    ;Show save as dialog
	invoke GetSaveFileName,addr ofn
	.if eax
		invoke UpdateFileName,hWin,addr buffer
	.else
		mov		eax,TRUE
	.endif
	ret

SaveFileAs endp

Init proc
	LOCAL	buffer[MAX_PATH]:BYTE

	xor		eax,eax
	.if da.edtopt.fopt & EDTOPT_SESSION
		;Check Session Project
		invoke GetPrivateProfileString,addr szIniSession,addr szIniProject,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
		.if eax
			;Check if project file exists
			invoke GetFileAttributes,addr buffer
			.if eax==INVALID_HANDLE_VALUE
				xor		eax,eax
			.else
				;Check version
				invoke GetPrivateProfileInt,addr szIniVersion,addr szIniVersion,0,addr buffer
				.if eax<3000
					invoke MessageBox,ha.hWnd,addr szProjectVersion,addr DisplayName,MB_OK or MB_ICONERROR
				.else
					invoke OpenTheFile,addr buffer,ID_PROJECT
				.endif
			.endif
		.else
			;Session Assembler
			invoke GetPrivateProfileString,addr szIniSession,addr szIniAssembler,NULL,addr da.szAssembler,sizeof da.szAssembler,addr da.szRadASMIni
			.if !eax
				mov		dword ptr da.szAssembler,'msam'
				mov		dword ptr da.szAssembler[4],0
			.endif
			invoke OpenAssembler
			invoke GetSessionFiles
		.endif
	.endif
	ret

Init endp

