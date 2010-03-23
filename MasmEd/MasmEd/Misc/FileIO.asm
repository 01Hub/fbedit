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

SaveFile proc uses ebx,hWin:DWORD,lpFileName:DWORD
	LOCAL	hFile:DWORD
	LOCAL	editstream:EDITSTREAM
	LOCAL	hMem:DWORD
	LOCAL	nSize:DWORD

	invoke GetWindowLong,hWin,GWL_ID
	invoke PostAddinMessage,hWin,AIM_FILESAVE,eax,lpFileName,0,HOOK_FILESAVE
	.if !eax
		invoke CreateFile,lpFileName,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
		.if eax!=INVALID_HANDLE_VALUE
			mov		hFile,eax
			mov		eax,hWin
			.if eax==ha.hRes
				invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
				mov		hMem,eax
				invoke SendMessage,ha.hResEd,PRO_EXPORT,0,hMem
				invoke strlen,hMem
				mov		nSize,eax
				invoke WriteFile,hFile,hMem,nSize,addr nSize,NULL
				invoke SendMessage,ha.hResEd,PRO_SETMODIFY,FALSE,0
				invoke GlobalFree,hMem
				.if nmeexp.fAuto
					invoke SendMessage,ha.hResEd,PRO_EXPORTNAMES,1,ha.hOut
				.endif
			.else
				;stream the text to the file
				mov		eax,hFile
				mov		editstream.dwCookie,eax
				mov		editstream.pfnCallback,offset StreamOutProc
				invoke SendMessage,hWin,EM_STREAMOUT,SF_TEXT,addr editstream
				;Set the modify state to false
				invoke SendMessage,hWin,EM_SETMODIFY,FALSE,0
				invoke GetWindowLong,hWin,GWL_ID
				.if eax==IDC_RAE
					invoke SendMessage,hWin,REM_SETCHANGEDSTATE,TRUE,0
				.endif
			.endif
			invoke CloseHandle,hFile
			invoke TabToolGetMem,hWin
			mov		ebx,eax
			mov		[ebx].TABMEM.nchange,0
			mov		[ebx].TABMEM.fchanged,0
			invoke UpdateFileTime,eax
			invoke TabToolSetChanged,hWin,FALSE
	   		mov		eax,FALSE
		.else
			invoke strcpy,offset tmpbuff,offset szSaveFileFail
			invoke strcat,offset tmpbuff,lpFileName
			invoke MessageBox,ha.hWnd,offset tmpbuff,offset szAppName,MB_OK or MB_ICONERROR
			mov		eax,TRUE
		.endif
	.else
		xor		eax,eax
	.endif
	ret

SaveFile endp

UnicodeProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		.if fUnicode
			invoke CheckDlgButton,hWin,IDC_CHKUNICODE,BST_CHECKED
		.endif
	.elseif eax==WM_COMMAND
		invoke IsDlgButtonChecked,hWin,IDC_CHKUNICODE
		mov		fUnicode,eax
	.endif
	xor		eax,eax
	ret

UnicodeProc endp

UpdateFileName proc hWin:DWORD,lpFileName:DWORD

	invoke strcpy,offset da.FileName,lpFileName
	invoke SetWinCaption,offset da.FileName
	invoke TabToolGetInx,hWin
	invoke TabToolSetText,eax,offset da.FileName
	ret

UpdateFileName endp

SaveEditAs proc hWin:DWORD,lpFileName:DWORD
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke GetWindowLong,hWin,GWL_ID
	invoke PostAddinMessage,hWin,AIM_FILESAVEAS,eax,lpFileName,0,HOOK_FILESAVEAS
	.if !eax
		;Zero out the ofn struct
	    invoke RtlZeroMemory,addr ofn,sizeof ofn
		;Setup the ofn struct
		mov		ofn.lStructSize,sizeof ofn
		push	ha.hWnd
		pop		ofn.hwndOwner
		push	ha.hInstance
		pop		ofn.hInstance
		mov		ofn.lpstrFilter,NULL
		invoke strcpy,addr buffer,addr da.FileName
		lea		eax,buffer
		mov		ofn.lpstrFile,eax
		mov		ofn.nMaxFile,sizeof buffer
		invoke GetWindowLong,hWin,GWL_ID
		.if eax==IDC_RAE
			mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT or OFN_EXPLORER or OFN_ENABLETEMPLATE or OFN_ENABLEHOOK
			mov		ofn.lpTemplateName,IDD_DLGSAVEUNICODE
			mov		ofn.lpfnHook,offset UnicodeProc
			invoke SendMessage,hWin,REM_GETUNICODE,0,0
			mov		fUnicode,eax
		.else
			xor		eax,eax
			mov		fUnicode,eax
			mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT or OFN_EXPLORER
		.endif
	    mov		ofn.lpstrDefExt,NULL
	    ;Show save as dialog
		invoke GetSaveFileName,addr ofn
		.if eax
			invoke GetWindowLong,hWin,GWL_ID
			.if eax!=IDC_RAE
				invoke SendMessage,hWin,REM_SETUNICODE,fUnicode,0
			.endif
			invoke SaveFile,hWin,addr buffer
			.if !eax
				;The file was saved
				invoke UpdateFileName,hWin,addr buffer
				mov		eax,FALSE
			.endif
		.else
			mov		eax,TRUE
		.endif
	.endif
	ret

SaveEditAs endp

SaveEdit proc hWin:DWORD,lpFileName:DWORD

	;Check if filrname is (Untitled)
	invoke strcmp,lpFileName,offset szNewFile
	.if eax
		invoke SaveFile,hWin,lpFileName
	.else
		invoke SaveEditAs,hWin,lpFileName
	.endif
	ret

SaveEdit endp

WantToSave proc hWin:DWORD,lpFileName:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	buffer1[2]:BYTE

	invoke GetWindowLong,hWin,GWL_ID
	.if eax==IDC_USER
		invoke PostAddinMessage,hWin,AIM_GETMODIFY,eax,lpFileName,0,HOOK_GETMODIFY
	.else
		invoke SendMessage,hWin,EM_GETMODIFY,0,0
	.endif
	.if eax
		invoke strcpy,addr buffer,offset szWannaSave
		invoke strcat,addr buffer,lpFileName
		mov		ax,'?'
		mov		word ptr buffer1,ax
		invoke strcat,addr buffer,addr buffer1
		invoke MessageBox,ha.hWnd,addr buffer,offset szAppName,MB_YESNOCANCEL or MB_ICONQUESTION
		.if eax==IDYES
			invoke SaveEdit,hWin,lpFileName
		.elseif eax==IDNO
		    mov		eax,FALSE
		.else
		    mov		eax,TRUE
		.endif
	.endif
	ret

WantToSave endp

LoadEditFile proc uses ebx esi,hWin:DWORD,lpFileName:DWORD
    LOCAL   hFile:DWORD
	LOCAL	editstream:EDITSTREAM
	LOCAL	chrg:CHARRANGE

	;Open the file
	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		;Copy buffer to da.FileName
		invoke strcpy,offset da.FileName,lpFileName
		;Set word group
		invoke strlen,offset da.FileName
		mov		ebx,15
		.if eax>3
			mov		esi,eax
			xor		ebx,ebx
			invoke strcmpi,addr [esi+offset da.FileName-4],offset szFtAsm
			.if eax
				invoke strcmpi,addr [esi+offset da.FileName-4],offset szFtInc
				.if eax
					invoke strcmpi,addr [esi+offset da.FileName-4],offset szFtApi
					.if eax
						invoke strcmpi,addr [esi+offset da.FileName-3],offset szFtRc
						.if !eax
							;RC File
							mov		ebx,2
						.else
							;Unknown file type
							mov		ebx,15
							invoke GetWindowLong,hWin,GWL_STYLE
							or		eax,STYLE_NOHILITE
							invoke SetWindowLong,hWin,GWL_STYLE,eax
						.endif
					.endif
				.endif
			.endif
		.endif
		invoke SendMessage,hWin,REM_SETWORDGROUP,0,ebx
		invoke SendMessage,hWin,WM_SETTEXT,0,addr szNULL
		;stream the text into the RAEdit control
		push	hFile
		pop		editstream.dwCookie
		mov		editstream.pfnCallback,offset StreamInProc
		invoke SendMessage,hWin,EM_STREAMIN,SF_TEXT,addr editstream
		invoke CloseHandle,hFile
		invoke SendMessage,hWin,EM_SETMODIFY,FALSE,0
		invoke SendMessage,hWin,REM_SETCHANGEDSTATE,FALSE,0
		mov		chrg.cpMin,0
		mov		chrg.cpMax,0
		invoke SendMessage,hWin,EM_EXSETSEL,0,addr chrg
		invoke SetWinCaption,offset da.FileName
		.if !ebx
			mov		nLastLine,-1
			mov		nLastPropLine,-1
			.if !da.fProject
;				invoke GetWindowLong,hWin,GWL_USERDATA
				invoke ParseEdit,hWin,0;[eax].TABMEM.pid
			.endif
		.endif
		mov		eax,FALSE
	.else
		invoke strcpy,offset tmpbuff,offset szOpenFileFail
		invoke strcat,offset tmpbuff,lpFileName
		invoke MessageBox,ha.hWnd,offset tmpbuff,offset szAppName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadEditFile endp

LoadHexFile proc uses ebx esi,hWin:DWORD,lpFileName:DWORD
    LOCAL   hFile:DWORD
	LOCAL	editstream:EDITSTREAM
	LOCAL	chrg:CHARRANGE

	;Open the file
	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		;Copy buffer to da.FileName
		invoke strcpy,offset da.FileName,lpFileName
		;stream the text into the RAHexEd control
		push	hFile
		pop		editstream.dwCookie
		mov		editstream.pfnCallback,offset StreamInProc
		invoke SendMessage,hWin,EM_STREAMIN,SF_TEXT,addr editstream
		invoke CloseHandle,hFile
		invoke SendMessage,hWin,EM_SETMODIFY,FALSE,0
		mov		chrg.cpMin,0
		mov		chrg.cpMax,0
		invoke SendMessage,hWin,EM_EXSETSEL,0,addr chrg
		invoke SetWinCaption,offset da.FileName
		mov		eax,FALSE
	.else
		invoke strcpy,offset tmpbuff,offset szOpenFileFail
		invoke strcat,offset tmpbuff,lpFileName
		invoke MessageBox,ha.hWnd,offset tmpbuff,offset szAppName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadHexFile endp

IsFileResource proc lpFile:DWORD

	invoke strlen,lpFile
	mov		edx,lpFile
	lea		edx,[edx+eax-3]
	mov		edx,[edx]
	and		edx,0FF5F5Fffh
	xor		eax,eax
	.if edx=='CR.'
		inc		eax
	.endif
	ret

IsFileResource endp

LoadRCFile proc lpFileName:DWORD
    LOCAL   hFile:DWORD
	LOCAL	hMem:DWORD
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
		invoke SendMessage,ha.hResEd,PRO_OPEN,lpFileName,hMem
		mov		eax,TRUE
	.else
		invoke strcpy,offset tmpbuff,offset szOpenFileFail
		invoke strcat,offset tmpbuff,lpFileName
		invoke MessageBox,ha.hWnd,offset tmpbuff,offset szAppName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadRCFile endp

OpenEditFile proc uses ebx esi,lpFileName:DWORD,fType:DWORD
	LOCAL	buffer[MAX_PATH*2]:BYTE
	LOCAL	fCtrl:DWORD

	invoke strcpy,addr buffer,lpFileName
	invoke CharUpper,addr buffer
	xor		eax,eax
	.if fType==0
		invoke GetKeyState,VK_CONTROL
		and		eax,80h
		.if !eax
			invoke strlen,addr buffer
			mov		eax,dword ptr buffer[eax-4]
			.if eax=='EXE.' || eax=='TAB.' || eax=='MOC.'
				invoke PostAddinMessage,ha.hWnd,AIM_FILEOPEN,IDC_EXECUTE,lpFileName,0,HOOK_FILEOPEN
				.if !eax
					invoke WinExec,lpFileName,SW_SHOWNORMAL
					invoke PostAddinMessage,ha.hWnd,AIM_FILEOPENED,IDC_EXECUTE,lpFileName,0,HOOK_FILEOPENED
				.endif
				ret
			.endif
			xor		eax,eax
		.endif
	.endif
	mov		fCtrl,eax
	invoke strcpy,offset da.FileName,lpFileName
	invoke UpdateAll,IS_OPEN
	.if !eax
		invoke GetFileAttributes,lpFileName
		.if eax!=-1
			xor		eax,eax
			.if fType==0 || fType==IDC_RES
				invoke IsFileResource,lpFileName
			.endif
			.if eax && !fCtrl
				invoke UpdateAll,IS_RESOURCE
				.if eax
					invoke WantToSave,ha.hREd,offset da.FileName
					.if !eax
						invoke PostAddinMessage,ha.hWnd,AIM_FILEOPEN,IDC_RES,lpFileName,0,HOOK_FILEOPEN
						.if !eax
							invoke LoadRCFile,lpFileName
							.if eax
								invoke TabToolGetInx,ha.hREd
								invoke TabToolSetText,eax,lpFileName
								invoke SetWinCaption,lpFileName
								invoke strcpy,offset da.FileName,lpFileName
								invoke AddMRU,offset mrufiles,lpFileName
								invoke ResetMenu
								invoke PostAddinMessage,ha.hWnd,AIM_FILEOPENED,IDC_RES,lpFileName,0,HOOK_FILEOPENED
							.endif
						.endif
					.endif
				.else
					invoke PostAddinMessage,ha.hWnd,AIM_FILEOPEN,IDC_RES,lpFileName,0,HOOK_FILEOPEN
					.if !eax
						invoke LoadRCFile,lpFileName
						.if eax
							invoke ShowWindow,ha.hREd,SW_HIDE
							mov		eax,ha.hRes
							mov		ha.hREd,eax
							invoke TabToolAdd,ha.hREd,lpFileName
							invoke SendMessage,ha.hWnd,WM_SIZE,0,0
							invoke ShowWindow,ha.hREd,SW_SHOW
							invoke SetWinCaption,lpFileName
							invoke strcpy,offset da.FileName,lpFileName
							invoke AddMRU,offset mrufiles,lpFileName
							invoke ResetMenu
							invoke PostAddinMessage,ha.hWnd,AIM_FILEOPENED,IDC_RES,lpFileName,0,HOOK_FILEOPENED
						.endif
					.endif
				.endif
			.else
				invoke strlen,addr buffer
				mov		eax,dword ptr buffer[eax-4]
				.if (fType==0 || fType==IDC_RAE) && eax!='EXE.' && eax!='MOC.' && eax!='JBO.' && eax!='SER.' && eax!='BIL.' && eax!='PMB.' && eax!='OCI.' && eax!='GPJ.' && eax!='INA.' && eax!='IVA.' && eax!='GNP.' && eax!='RUC.' && eax!='SEM.'
					mov		ebx,IDC_RAE
				.elseif eax=='SEM.'
					.if fCtrl
						mov		ebx,IDC_RAE
					.else
						mov		ebx,IDC_MES
					.endif
				.else
					mov		ebx,IDC_HEX
				.endif
				invoke strcpy,addr buffer,lpFileName
				invoke PostAddinMessage,ha.hWnd,AIM_FILEOPEN,ebx,addr buffer,0,HOOK_FILEOPEN
				.if !eax
					invoke LoadCursor,0,IDC_WAIT
					invoke SetCursor,eax
					.if ebx==IDC_MES
						; Session
						mov		nTabInx,-1
						invoke UpdateAll,WM_CLOSE
						.if !eax
							invoke AskSaveSessionFile
							.if !eax
								invoke AddMRU,offset mrusessions,addr buffer
								invoke CloseNotify
								invoke UpdateAll,CLOSE_ALL
								invoke ReadSessionFile,addr buffer
							.endif
						.endif
					.elseif ebx==IDC_RAE
						; Text Edit
						invoke CreateRAEdit
						invoke TabToolAdd,ha.hREd,offset da.FileName
						invoke LoadEditFile,ha.hREd,offset da.FileName
						invoke SendMessage,ha.hREd,REM_LINENUMBERWIDTH,32,0
						invoke IsFileCodeFile,offset da.FileName
						.if eax
							invoke SendMessage,ha.hREd,REM_SETCOMMENTBLOCKS,addr szCmntStart,addr szCmntEnd
							invoke SendMessage,ha.hREd,REM_SETBLOCKS,0,0
							.if fDebugging
								invoke SendMessage,ha.hREd,REM_READONLY,0,TRUE
							.endif
						.endif
						mov		eax,edopt.hiliteline
						.if eax
							mov		eax,2
						.endif
						invoke SendMessage,ha.hREd,REM_HILITEACTIVELINE,0,eax
						invoke TabToolSetChanged,ha.hREd,FALSE
						invoke AddMRU,offset mrufiles,addr buffer
					.else
						; Hex Edit
						invoke CreateRAHexEd
						invoke TabToolAdd,ha.hREd,offset da.FileName
						invoke LoadHexFile,ha.hREd,offset da.FileName
						invoke TabToolSetChanged,ha.hREd,FALSE
						invoke AddMRU,offset mrufiles,addr buffer
					.endif
					invoke ResetMenu
					invoke LoadCursor,0,IDC_ARROW
					invoke SetCursor,eax
					invoke PostAddinMessage,ha.hWnd,AIM_FILEOPENED,ebx,addr buffer,0,HOOK_FILEOPENED
				.else
					invoke AddMRU,offset mrufiles,addr buffer
					invoke ResetMenu
					invoke PostAddinMessage,ha.hWnd,AIM_FILEOPENED,IDC_USER,addr buffer,0,HOOK_FILEOPENED
				.endif
			.endif
		.else
			invoke strcpy,addr buffer,offset szOpenFileFail
			invoke strcat,addr buffer,lpFileName
			invoke MessageBox,ha.hWnd,addr buffer,offset szAppName,MB_OK or MB_ICONERROR
		.endif
	.endif
	.if ha.hREd
		invoke SetFocus,ha.hREd
	.endif
	ret

OpenEditFile endp

OpenEdit proc
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
	mov		ofn.lpstrFilter,offset ALLFilterString
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
		invoke OpenEditFile,addr buffer,0
	.endif
	ret

OpenEdit endp

OpenHex proc
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
	mov		ofn.lpstrFilter,offset ANYFilterString
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
		invoke OpenEditFile,addr buffer,IDC_HEX
	.endif
	ret

OpenHex endp

OpenSessionFile proc
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
	mov		ofn.lpstrFilter,offset MESFilterString
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
		invoke OpenEditFile,addr buffer,IDC_MES
	.endif
	ret

OpenSessionFile endp

MakeSession proc fRegistry:DWORD

	mov		byte ptr tmpbuff,0
	mov		eax,SAVE_SESSIONFILE
	.if fRegistry
		mov		eax,SAVE_SESSIONREGISTRY
	.endif
	invoke UpdateAll,eax
	invoke strlen,addr tmpbuff
	.if eax
		mov		byte ptr tmpbuff[eax-1],0
	.endif
	invoke strcpy,addr LineTxt,addr tmpbuff
	invoke SendMessage,ha.hTab,TCM_GETCURSEL,0,0
	mov		edx,eax
	invoke DwToAscii,edx,addr tmpbuff
	invoke strcat,addr tmpbuff,addr szComma
	invoke strcat,addr tmpbuff,addr LineTxt
	ret

MakeSession endp

WriteSessionFile proc lpszFile:DWORD
	LOCAL	buffer[32]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE
	LOCAL	buffer2[MAX_PATH]:BYTE

	invoke strcpy,addr da.szSessionFile,lpszFile
	invoke SendMessage,ha.hBrowse,FBM_GETPATH,0,addr tmpbuff
	invoke WritePrivateProfileString,addr szSession,addr szFolder,addr tmpbuff,lpszFile
	invoke MakeSession,FALSE
	invoke WritePrivateProfileString,addr szSession,addr szSession,addr tmpbuff,lpszFile
	invoke strcpy,addr buffer1,addr da.szSessionFile
	invoke strlen,addr buffer1
	.while eax && buffer1[eax-1]!='\'
		dec		eax
	.endw
	mov		buffer1[eax],0
	invoke RemovePath,addr da.MainFile,addr buffer1,addr buffer2
	invoke strcpy,addr buffer1,eax
	invoke WritePrivateProfileString,addr szSession,addr szMainFile,addr buffer1,lpszFile
	invoke SendMessage,ha.hCbo,CB_GETCURSEL,0,0
	invoke wsprintf,addr buffer,addr szFmtDec,eax
	invoke WritePrivateProfileString,addr szSession,addr szBuild,addr buffer,lpszFile
	ret

WriteSessionFile endp

AskSaveSessionFile proc

	.if byte ptr da.szSessionFile
		invoke strcpy,addr tmpbuff,addr szSaveSession
		invoke strcat,addr tmpbuff,addr da.szSessionFile
		invoke MessageBox,ha.hWnd,addr tmpbuff,addr szSession,MB_YESNOCANCEL or MB_ICONEXCLAMATION
		.if eax==IDYES
			invoke WriteSessionFile,addr da.szSessionFile
		.elseif eax==IDCANCEL
			mov		eax,TRUE
			ret
		.endif
	.endif
	xor		eax,eax
	ret

AskSaveSessionFile endp

SaveSessionFile proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	;Zero out the ofn struct
    invoke RtlZeroMemory,addr ofn,sizeof ofn
	;Setup the ofn struct
	mov		ofn.lStructSize,sizeof ofn
	push	ha.hWnd
	pop		ofn.hwndOwner
	push	ha.hInstance
	pop		ofn.hInstance
	mov		ofn.lpstrFilter,NULL
	mov		ofn.lpstrFilter,offset MESFilterString
	invoke strcpy,addr buffer,addr da.szSessionFile
	lea		eax,buffer
	mov		ofn.lpstrFile,eax
	mov		ofn.nMaxFile,sizeof buffer
	mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT
    mov		ofn.lpstrDefExt,offset szFtMes
    ;Show save as dialog
	invoke GetSaveFileName,addr ofn
	.if eax
		invoke WriteSessionFile,addr buffer
	.endif
	ret

SaveSessionFile endp

SetProjectGroups proc uses ebx esi edi,lpBuff:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	nInx:DWORD
	LOCAL	pbi:PBITEM

	mov		nInx,0
	invoke RtlZeroMemory,addr pbi,sizeof PBITEM
	mov		esi,lpBuff
	.while byte ptr [esi]
		call	GetItem
		.if buffer
			invoke AsciiToDw,addr buffer
			mov		pbi.id,eax
			call	GetItem
			.if buffer
				invoke AsciiToDw,addr buffer
				mov		pbi.idparent,eax
				call	GetItem
				.if buffer
					invoke AsciiToDw,addr buffer
					mov		pbi.expanded,eax
					call	GetItem
					.if buffer
						invoke lstrcpy,addr pbi.szitem,addr buffer
						invoke SendMessage,ha.hPbr,RPBM_ADDITEM,nInx,addr pbi
						inc		nInx
					.endif
				.endif
			.endif
		.endif
	.endw
	mov		eax,nInx
	ret

GetItem:
	lea		edi,buffer
	.while byte ptr [esi] && byte ptr [esi]!=','
		mov		al,[esi]
		mov		[edi],al
		inc		esi
		inc		edi
	.endw
	.if byte ptr [esi]
		inc		esi
	.endif
	mov		byte ptr [edi],0
	retn

SetProjectGroups endp

SetProjectFiles proc uses ebx esi edi,nInx:DWORD,lpszFile:DWORD
	LOCAL	pbi:PBITEM
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buff[MAX_PATH*2]:BYTE

	invoke RtlZeroMemory,addr pbi,sizeof PBITEM
	mov		edi,1
	.while edi<257
		invoke wsprintf,addr buffer,addr szFmtDec,edi
		invoke GetPrivateProfileString,addr szProject,addr buffer,addr szNULL,addr buff,sizeof buff,lpszFile
		.if eax
			mov		pbi.id,edi
			lea		esi,buff
			call	GetItem
			.if buffer
				invoke AsciiToDw,addr buffer
				mov		pbi.idparent,eax
				call	GetItem
				.if buffer
					invoke SendMessage,ha.hPbr,RPBM_GETPATH,0,0
					invoke lstrcpy,addr buff,eax
					invoke lstrcat,addr buff,addr szBackSlash
					invoke lstrcat,addr buff,addr buffer
					invoke lstrcpy,addr pbi.szitem,addr buff
					invoke SendMessage,ha.hPbr,RPBM_ADDITEM,nInx,addr pbi
					invoke ParseFile,addr pbi.szitem,pbi.id
					inc		nInx
				.endif
			.endif
		.endif
		inc		edi
	.endw
	mov		eax,nInx
	ret

GetItem:
	push	edi
	lea		edi,buffer
	.while byte ptr [esi] && byte ptr [esi]!=','
		mov		al,[esi]
		mov		[edi],al
		inc		esi
		inc		edi
	.endw
	.if byte ptr [esi]
		inc		esi
	.endif
	mov		byte ptr [edi],0
	pop		edi
	retn

SetProjectFiles endp

CreateProject proc uses esi edi,lpszFile:DWORD

	invoke SendMessage,ha.hPbr,RPBM_ADDITEM,0,0
	mov		esi,offset tmpbuff
	invoke strcpy,esi,addr da.szSessionFile
	invoke strlen,esi
	.while eax && byte ptr [esi+eax]!='\'
		dec		eax
	.endw
	mov		byte ptr [esi+eax],0
	invoke SendMessage,ha.hPbr,RPBM_SETPATH,0,addr tmpbuff
	mov		esi,offset szDefProGroups
	invoke strcpy,addr tmpbuff,esi
	mov		edi,offset da.szSessionFile
	invoke strlen,edi
	.while byte ptr [edi+eax]!='\' && eax
		dec		eax
	.endw
	invoke strcat,addr tmpbuff,addr [edi+eax+1]
	invoke strlen,esi
	invoke strcat,addr tmpbuff,addr [esi+eax+1]
	invoke SetProjectGroups,addr tmpbuff
	.if eax
		invoke SendMessage,ha.hPbr,RPBM_SETGROUPING,TRUE,RPBG_GROUPS
		mov		da.fProject,TRUE
		invoke SendMessage,ha.hProperty,PRM_DELPROPERTY,0,0
		invoke SendMessage,ha.hProperty,PRM_REFRESHLIST,0,0
	.endif
	ret

CreateProject endp

OpenProject proc uses esi edi,lpszFile:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		da.fProject,FALSE
	invoke SendMessage,ha.hPbr,RPBM_ADDITEM,0,0
	mov		esi,offset LineTxt
	invoke strcpy,esi,addr da.szSessionFile
	invoke strlen,esi
	.while eax && byte ptr [esi+eax]!='\'
		dec		eax
	.endw
	mov		byte ptr [esi+eax],0
	invoke SendMessage,ha.hPbr,RPBM_SETPATH,0,addr LineTxt
	invoke GetPrivateProfileString,addr szProject,addr szProGroup,addr szNULL,addr LineTxt,sizeof LineTxt,lpszFile
	.if eax
		invoke SetProjectGroups,addr LineTxt
		.if eax
			mov		da.fProject,TRUE
			invoke SetProjectFiles,eax,lpszFile
			invoke SendMessage,ha.hPbr,RPBM_SETGROUPING,TRUE,RPBG_GROUPS
			invoke SendMessage,ha.hTabPbr,TCM_SETCURSEL,1,0
			invoke ShowWindow,ha.hPbr,SW_SHOWNA
			invoke ShowWindow,ha.hBrowse,SW_HIDE
		.endif
	.endif
	ret

OpenProject endp

SaveProject proc uses ebx esi edi,lpszFile:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	path[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE

	mov		eax,lpszFile
	.if byte ptr [eax]
		mov		word ptr tmpbuff,0
		invoke WritePrivateProfileSection,addr szProject,addr tmpbuff,lpszFile
		invoke SendMessage,ha.hPbr,RPBM_GETEXPAND,0,0
		xor		ebx,ebx
		.while TRUE
			invoke SendMessage,ha.hPbr,RPBM_GETITEM,ebx,0
			.if eax
				mov		esi,eax
				.break .if ![esi].PBITEM.id
				.if sdword ptr [esi].PBITEM.id<0
					lea		edi,buffer
					invoke wsprintf,edi,addr szFmtDec,[esi].PBITEM.id
					invoke lstrlen,edi
					lea		edi,[edi+eax]
					mov		word ptr [edi],','
					inc		edi
					invoke wsprintf,edi,addr szFmtDec,[esi].PBITEM.idparent
					invoke lstrlen,edi
					lea		edi,[edi+eax]
					mov		word ptr [edi],','
					inc		edi
					invoke wsprintf,edi,addr szFmtDec,[esi].PBITEM.expanded
					invoke lstrlen,edi
					lea		edi,[edi+eax]
					mov		word ptr [edi],','
					inc		edi
					invoke lstrcpy,edi,addr [esi].PBITEM.szitem
					.if tmpbuff
						invoke lstrcat,addr tmpbuff,addr szComma
					.endif
					invoke lstrcat,addr tmpbuff,addr buffer
				.endif
			.else
				.break
			.endif
			inc		ebx
		.endw
		.if ebx
			invoke WritePrivateProfileString,addr szProject,addr szProGroup,addr tmpbuff,lpszFile
			invoke SendMessage,ha.hPbr,RPBM_GETPATH,0,0
			invoke lstrcpy,addr path,eax
			xor		ebx,ebx
			.while TRUE
				invoke SendMessage,ha.hPbr,RPBM_GETITEM,ebx,0
				.if eax
					mov		esi,eax
					.break .if ![esi].PBITEM.id
					.if sdword ptr [esi].PBITEM.id>0
						mov		edi,offset tmpbuff
						invoke wsprintf,edi,addr szFmtDec,[esi].PBITEM.idparent
						invoke lstrlen,edi
						lea		edi,[edi+eax]
						mov		word ptr [edi],','
						inc		edi
						invoke lstrcpy,addr buffer1,addr [esi].PBITEM.szitem
						invoke RemovePath,addr [esi].PBITEM.szitem,addr path,addr buffer1
						invoke lstrcpy,edi,addr [eax+1]
						invoke wsprintf,addr buffer,addr szFmtDec,[esi].PBITEM.id
						invoke WritePrivateProfileString,addr szProject,addr buffer,addr tmpbuff,lpszFile
					.endif
				.else
					.break
				.endif
				inc		ebx
			.endw
		.endif
	.endif
	ret

SaveProject endp

RestoreSession proc uses esi edi,fReg:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE
	LOCAL	buffer2[MAX_PATH]:BYTE
	LOCAL	nInx:DWORD
	LOCAL	nLn:DWORD
	LOCAL	chrg:CHARRANGE
	LOCAL	fHex:DWORD

	mov		esi,offset tmpbuff
	.if fReg && byte ptr [esi]
		call	GetItem
		.if buffer
			invoke GetFileAttributes,addr buffer
			.if eax==INVALID_HANDLE_VALUE
				jmp		Ex
			.endif
		.endif
		invoke strcpy,addr da.szSessionFile,addr buffer
		.if da.szSessionFile
			invoke OpenProject,addr da.szSessionFile
		.endif
	.endif
	invoke strcpy,addr buffer1,addr da.szSessionFile
	invoke strlen,addr buffer1
	.while eax && buffer1[eax-1]!='\'
		dec		eax
	.endw
	mov		buffer1[eax],0
	mov		nInx,-2
	.while byte ptr [esi]
		call	GetItem
		.if nInx==-2
			.if buffer
				invoke AsciiToDw,addr buffer
				mov		nInx,eax
			.endif
		.else
			invoke AsciiToDw,addr buffer
			mov		nLn,eax
			call	GetItem
			.if buffer
				.if buffer[1]!=':'
					; Relative path
					invoke strcpy,addr buffer2,addr buffer1
					invoke strcat,addr buffer2,addr buffer
					invoke strcpy,addr buffer,addr buffer2
				.endif
				push	ha.hREd
				mov		fHex,FALSE
				.if sdword ptr nLn<=-2
					mov		eax,nLn
					neg		eax
					sub		eax,2
					mov		nLn,eax
					invoke OpenEditFile,addr buffer,IDC_HEX
					mov		fHex,TRUE
				.elseif sdword ptr nLn==-1
					invoke OpenEditFile,addr buffer,IDC_RES
				.else
					invoke OpenEditFile,addr buffer,IDC_RAE
				.endif
				pop		eax
				.if eax!=ha.hREd
					mov		eax,ha.hREd
					.if nLn!=-1 && eax!=ha.hRes
						invoke SendMessage,ha.hREd,EM_LINEINDEX,nLn,0
						mov		chrg.cpMin,eax
						mov		chrg.cpMax,eax
						invoke SendMessage,ha.hREd,EM_EXSETSEL,0,addr chrg
						invoke SendMessage,ha.hREd,EM_SCROLLCARET,0,0
						.if !fHex
							invoke SendMessage,ha.hREd,REM_VCENTER,0,0
							invoke SendMessage,ha.hREd,EM_SCROLLCARET,0,0
						.endif
					.endif
				.endif
			.endif
		.endif
	.endw
	.if sdword ptr nInx>=0
		invoke SendMessage,ha.hTab,TCM_SETCURSEL,nInx,0
		.if eax!=-1
			invoke TabToolActivate
			invoke SetFocus,ha.hREd
		.endif
	.endif
  Ex:
	ret

GetItem:
	lea		edi,buffer
	.while byte ptr [esi] && byte ptr [esi]!=','
		mov		al,[esi]
		mov		[edi],al
		inc		esi
		inc		edi
	.endw
	.if byte ptr [esi]
		inc		esi
	.endif
	mov		byte ptr [edi],0
	retn

RestoreSession endp

ReadSessionFile proc lpszFile:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke strcpy,addr da.szSessionFile,lpszFile
	invoke GetPrivateProfileString,addr szSession,addr szFolder,addr szNULL,addr tmpbuff,sizeof tmpbuff,lpszFile
	invoke SendMessage,ha.hBrowse,FBM_SETPATH,TRUE,addr tmpbuff
	invoke GetPrivateProfileString,addr szSession,addr szSession,addr szNULL,addr tmpbuff,sizeof tmpbuff,lpszFile
	invoke GetPrivateProfileString,addr szSession,addr szMainFile,addr szNULL,addr da.MainFile,sizeof da.MainFile,lpszFile
	.if da.MainFile[1]!=':'
		; Relative path
		invoke strcpy,addr buffer,addr da.szSessionFile
		invoke strlen,addr buffer
		.while eax && buffer[eax-1]!='\'
			dec		eax
		.endw
		mov		buffer[eax],0
		invoke strcat,addr buffer,addr da.MainFile
		invoke strcpy,addr da.MainFile,addr buffer
	.endif
	invoke GetPrivateProfileInt,addr szSession,addr szBuild,0,lpszFile
	invoke SendMessage,ha.hCbo,CB_SETCURSEL,eax,0
	invoke OpenProject,lpszFile
	invoke RestoreSession,FALSE
	.if da.FileName && da.fProject
		invoke SendMessage,ha.hPbr,RPBM_SETSELECTED,0,addr da.FileName
	.endif
	ret

ReadSessionFile endp

SetCurDir proc lpFileName:DWORD,fFileBrowse:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke strcpy,addr buffer,lpFileName
	invoke strlen,addr buffer
	.while byte ptr buffer[eax]!='\' && eax
		dec		eax
	.endw
	mov		buffer[eax],0
	.if fFileBrowse
		invoke SendMessage,ha.hBrowse,FBM_SETPATH,TRUE,addr buffer
	.endif
	invoke SetCurrentDirectory,addr buffer
	ret

SetCurDir endp

OpenCommandLine proc uses ebx,lpCmnd:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		ebx,lpCmnd
	.while byte ptr [ebx]
		.while byte ptr [ebx]==' '
			inc		ebx
		.endw
		lea		edx,buffer
		.if byte ptr [ebx]=='"'
			inc		ebx
			.while byte ptr [ebx]!='"' && byte ptr [ebx]
				mov		al,[ebx]
				mov		[edx],al
				inc		ebx
				inc		edx
			.endw
			inc		ebx
		.else
			.while byte ptr [ebx]!=' ' && byte ptr [ebx]
				mov		al,[ebx]
				mov		[edx],al
				inc		ebx
				inc		edx
			.endw
		.endif
		mov		byte ptr [edx],0
		.if buffer
			invoke OpenEditFile,addr buffer,0
		.endif
	.endw
	ret

OpenCommandLine endp
