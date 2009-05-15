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

	invoke CreateFile,lpFileName,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		mov		eax,hWin
		.if eax==hRes
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
			mov		hMem,eax
			invoke SendMessage,hResEd,PRO_EXPORT,0,hMem
			invoke lstrlen,hMem
			mov		nSize,eax
			invoke WriteFile,hFile,hMem,nSize,addr nSize,NULL
			invoke SendMessage,hResEd,PRO_SETMODIFY,FALSE,0
			invoke GlobalFree,hMem
			.if nmeexp.fAuto
				invoke SendMessage,hResEd,PRO_EXPORTNAMES,1,hOut
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
		invoke lstrcpy,offset tmpbuff,offset szSaveFileFail
		invoke lstrcat,offset tmpbuff,lpFileName
		invoke MessageBox,hWnd,offset tmpbuff,offset szAppName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
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

SaveEditAs proc hWin:DWORD,lpFileName:DWORD
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	;Zero out the ofn struct
    invoke RtlZeroMemory,addr ofn,sizeof ofn
	;Setup the ofn struct
	mov		ofn.lStructSize,sizeof ofn
	push	hWnd
	pop		ofn.hwndOwner
	push	hInstance
	pop		ofn.hInstance
	mov		ofn.lpstrFilter,NULL
	invoke lstrcpy,addr buffer,addr FileName
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
			invoke lstrcpy,offset FileName,addr buffer
			invoke SetWinCaption,offset FileName
			invoke TabToolGetInx,hWin
			invoke TabToolSetText,eax,offset FileName
			mov		eax,FALSE
		.endif
	.else
		mov		eax,TRUE
	.endif
	ret

SaveEditAs endp

SaveEdit proc hWin:DWORD,lpFileName:DWORD

	;Check if filrname is (Untitled)
	invoke lstrcmp,lpFileName,offset szNewFile
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

	invoke SendMessage,hWin,EM_GETMODIFY,0,0
	.if eax
		invoke lstrcpy,addr buffer,offset szWannaSave
		invoke lstrcat,addr buffer,lpFileName
		mov		ax,'?'
		mov		word ptr buffer1,ax
		invoke lstrcat,addr buffer,addr buffer1
		invoke MessageBox,hWnd,addr buffer,offset szAppName,MB_YESNOCANCEL or MB_ICONQUESTION
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
		;Copy buffer to FileName
		invoke lstrcpy,offset FileName,lpFileName
		;Set word group
		invoke lstrlen,offset FileName
		mov		ebx,15
		.if eax>3
			mov		esi,eax
			xor		ebx,ebx
			invoke lstrcmpi,addr [esi+offset FileName-4],offset szFtAsm
			.if eax
				invoke lstrcmpi,addr [esi+offset FileName-4],offset szFtInc
				.if eax
					invoke lstrcmpi,addr [esi+offset FileName-3],offset szFtRc
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
		invoke SetWinCaption,offset FileName
		.if !ebx
			invoke ParseEdit,hWin
		.endif
		mov		eax,FALSE
	.else
		invoke lstrcpy,offset tmpbuff,offset szOpenFileFail
		invoke lstrcat,offset tmpbuff,lpFileName
		invoke MessageBox,hWnd,offset tmpbuff,offset szAppName,MB_OK or MB_ICONERROR
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
		;Copy buffer to FileName
		invoke lstrcpy,offset FileName,lpFileName
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
		invoke SetWinCaption,offset FileName
		mov		eax,FALSE
	.else
		invoke lstrcpy,offset tmpbuff,offset szOpenFileFail
		invoke lstrcat,offset tmpbuff,lpFileName
		invoke MessageBox,hWnd,offset tmpbuff,offset szAppName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadHexFile endp

IsFileResource proc lpFile:DWORD

	invoke lstrlen,lpFile
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

IsFileCodeFile proc lpFile:DWORD

	invoke lstrlen,lpFile
	mov		edx,lpFile
	lea		edx,[edx+eax-4]
	mov		edx,[edx]
	and		edx,05f5F5Fffh
	xor		eax,eax
	.if edx=='MSA.' || edx=='CNI.'
		inc		eax
	.endif
	ret

IsFileCodeFile endp

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
		invoke SendMessage,hResEd,PRO_OPEN,lpFileName,hMem
		mov		eax,TRUE
	.else
		invoke lstrcpy,offset tmpbuff,offset szOpenFileFail
		invoke lstrcat,offset tmpbuff,lpFileName
		invoke MessageBox,hWnd,offset tmpbuff,offset szAppName,MB_OK or MB_ICONERROR
		mov		eax,TRUE
	.endif
	ret

LoadRCFile endp

OpenEditFile proc uses esi,lpFileName:DWORD,fType:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	fCtrl:DWORD

	invoke lstrcpy,addr buffer,lpFileName
	invoke CharUpper,addr buffer
	xor		eax,eax
	.if fType==0
		invoke GetKeyState,VK_CONTROL
		and		eax,80h
		.if !eax
			invoke lstrlen,addr buffer
			mov		eax,dword ptr buffer[eax-4]
			.if eax=='EXE.' || eax=='TAB.' || eax=='MOC.'
				invoke WinExec,lpFileName,SW_SHOWNORMAL
				ret
			.endif
			xor		eax,eax
		.endif
	.endif
	mov		fCtrl,eax
	invoke lstrcpy,offset FileName,lpFileName
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
					invoke WantToSave,hREd,offset FileName
					.if !eax
						invoke LoadRCFile,lpFileName
						.if eax
							invoke TabToolGetInx,hREd
							invoke TabToolSetText,eax,lpFileName
							invoke SetWinCaption,lpFileName
							invoke lstrcpy,offset FileName,lpFileName
						.endif
					.endif
				.else
					invoke LoadRCFile,lpFileName
					.if eax
						invoke ShowWindow,hREd,SW_HIDE
						mov		eax,hRes
						mov		hREd,eax
						invoke TabToolAdd,hREd,lpFileName
						invoke SendMessage,hWnd,WM_SIZE,0,0
						invoke ShowWindow,hREd,SW_SHOW
						invoke SetWinCaption,lpFileName
						invoke lstrcpy,offset FileName,lpFileName
					.endif
				.endif
			.else
				invoke LoadCursor,0,IDC_WAIT
				invoke SetCursor,eax
				invoke lstrlen,addr buffer
				mov		eax,dword ptr buffer[eax-4]
				.if (fType==0 || fType==IDC_RAE) && eax!='EXE.' && eax!='MOC.' && eax!='JBO.' && eax!='SER.' && eax!='BIL.' && eax!='PMB.' && eax!='OCI.' && eax!='GPJ.' && eax!='INA.' && eax!='IVA.' && eax!='GNP.' && eax!='RUC.'
					invoke CreateRAEdit
					invoke TabToolAdd,hREd,offset FileName
					invoke LoadEditFile,hREd,offset FileName
					invoke SendMessage,hREd,REM_LINENUMBERWIDTH,32,0
					invoke IsFileCodeFile,offset FileName
					.if eax
						invoke SendMessage,hREd,REM_SETCOMMENTBLOCKS,addr szCmntStart,addr szCmntEnd
						invoke SendMessage,hREd,REM_SETBLOCKS,0,0
					.endif
					mov		eax,edopt.hiliteline
					.if eax
						mov		eax,2
					.endif
					invoke SendMessage,hREd,REM_HILITEACTIVELINE,0,eax
				.else
					invoke CreateRAHexEd
					invoke TabToolAdd,hREd,offset FileName
					invoke LoadHexFile,hREd,offset FileName
				.endif
				invoke TabToolSetChanged,hREd,FALSE
				invoke LoadCursor,0,IDC_ARROW
				invoke SetCursor,eax
			.endif
		.else
			invoke lstrcpy,offset tmpbuff,offset szOpenFileFail
			invoke lstrcat,offset tmpbuff,lpFileName
			invoke MessageBox,hWnd,offset tmpbuff,offset szAppName,MB_OK or MB_ICONERROR
		.endif
	.endif
	invoke SetFocus,hREd
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
	push	hWnd
	pop		ofn.hwndOwner
	push	hInstance
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
	push	hWnd
	pop		ofn.hwndOwner
	push	hInstance
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

MakeSession proc

	mov		byte ptr tmpbuff,0
	invoke UpdateAll,SAVE_SESSION
	invoke lstrlen,addr tmpbuff
	.if eax
		mov		byte ptr tmpbuff[eax-1],0
	.endif
	invoke lstrcpy,addr LineTxt,addr tmpbuff
	invoke SendMessage,hTab,TCM_GETCURSEL,0,0
	mov		edx,eax
	invoke DwToAscii,edx,addr tmpbuff
	invoke lstrcat,addr tmpbuff,addr szComma
	invoke lstrcat,addr tmpbuff,addr LineTxt
	ret

MakeSession endp

WriteSessionFile proc lpszFile:DWORD

	invoke SendMessage,hBrowse,FBM_GETPATH,0,addr tmpbuff
	invoke WritePrivateProfileString,addr szSession,addr szFolder,addr tmpbuff,lpszFile
	invoke MakeSession
	invoke WritePrivateProfileString,addr szSession,addr szSession,addr tmpbuff,lpszFile
	invoke WritePrivateProfileString,addr szSession,addr szMainFile,addr MainFile,lpszFile
	invoke WritePrivateProfileString,addr szSession,addr szCompileRC,addr CompileRC,lpszFile
	invoke WritePrivateProfileString,addr szSession,addr szAssemble,addr Assemble,lpszFile
	invoke WritePrivateProfileString,addr szSession,addr szLink,addr Link,lpszFile
	invoke lstrcpy,addr szSessionFile,lpszFile
	ret

WriteSessionFile endp

AskSaveSessionFile proc

	.if byte ptr szSessionFile
		invoke lstrcpy,addr tmpbuff,addr szSaveSession
		invoke lstrcat,addr tmpbuff,addr szSessionFile
		invoke MessageBox,hWnd,addr tmpbuff,addr szSession,MB_YESNOCANCEL or MB_ICONEXCLAMATION
		.if eax==IDYES
			invoke WriteSessionFile,addr szSessionFile
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
	push	hWnd
	pop		ofn.hwndOwner
	push	hInstance
	pop		ofn.hInstance
	mov		ofn.lpstrFilter,NULL
	mov		ofn.lpstrFilter,offset MESFilterString
	invoke lstrcpy,addr buffer,addr szSessionFile
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

RestoreSession proc uses esi edi,fReg:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	nInx:DWORD
	LOCAL	nLn:DWORD
	LOCAL	chrg:CHARRANGE

	mov		esi,offset tmpbuff
	.if fReg && byte ptr [esi]
		call	GetItem
		invoke lstrcpy,addr szSessionFile,addr buffer
	.endif
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
				.if sdword ptr nLn<=-2
					mov		eax,nLn
					neg		eax
					sub		eax,2
					mov		nLn,eax
					invoke OpenEditFile,addr buffer,IDC_HEX
				.elseif sdword ptr nLn==-1
					invoke OpenEditFile,addr buffer,IDC_RES
				.else
					invoke OpenEditFile,addr buffer,IDC_RAE
				.endif
				mov		eax,hREd
				.if nLn!=-1 && eax!=hRes
					invoke SendMessage,hREd,EM_LINEINDEX,nLn,0
					mov		chrg.cpMin,eax
					mov		chrg.cpMax,eax
					invoke SendMessage,hREd,EM_EXSETSEL,0,addr chrg
					invoke SendMessage,hREd,EM_SCROLLCARET,0,0
					invoke SendMessage,hREd,REM_VCENTER,0,0
					invoke SendMessage,hREd,EM_SCROLLCARET,0,0
				.endif
			.endif
		.endif
	.endw
	.if sdword ptr nInx>=0
		invoke SendMessage,hTab,TCM_SETCURSEL,nInx,0
		invoke TabToolActivate
		invoke SetFocus,hREd
	.endif
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

	invoke GetPrivateProfileString,addr szSession,addr szFolder,addr szNULL,addr tmpbuff,sizeof tmpbuff,lpszFile
	invoke SendMessage,hBrowse,FBM_SETPATH,TRUE,addr tmpbuff
	invoke GetPrivateProfileString,addr szSession,addr szSession,addr szNULL,addr tmpbuff,sizeof tmpbuff,lpszFile
	invoke RestoreSession,FALSE
	invoke GetPrivateProfileString,addr szSession,addr szMainFile,addr szNULL,addr MainFile,sizeof MainFile,lpszFile
	invoke GetPrivateProfileString,addr szSession,addr szCompileRC,addr szNULL,addr CompileRC,sizeof CompileRC,lpszFile
	invoke GetPrivateProfileString,addr szSession,addr szAssemble,addr szNULL,addr Assemble,sizeof Assemble,lpszFile
	invoke GetPrivateProfileString,addr szSession,addr szLink,addr szNULL,addr Link,sizeof Link,lpszFile
	invoke lstrcpy,addr szSessionFile,lpszFile
	ret

ReadSessionFile endp

OpenSessionFile proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE

	;Zero out the ofn struct
	invoke RtlZeroMemory,addr ofn,sizeof ofn
	;Setup the ofn struct
	mov		ofn.lStructSize,sizeof ofn
	push	hWnd
	pop		ofn.hwndOwner
	push	hInstance
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
		mov		nTabInx,-1
		invoke UpdateAll,WM_CLOSE
		.if !eax
			invoke AskSaveSessionFile
			.if !eax
				invoke CloseNotify
				invoke UpdateAll,CLOSE_ALL
				invoke ReadSessionFile,addr buffer
			.endif
		.endif
	.endif
	ret

OpenSessionFile endp

SetCurDir proc lpFileName:DWORD,fFileBrowse:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke lstrcpy,addr buffer,lpFileName
	invoke lstrlen,addr buffer
	.while byte ptr buffer[eax]!='\' && eax
		dec		eax
	.endw
	mov		buffer[eax],0
	invoke SetCurrentDirectory,addr buffer
	.if fFileBrowse
		invoke SendMessage,hBrowse,FBM_SETPATH,TRUE,addr buffer
	.endif
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
			invoke lstrlen,addr buffer
			lea		eax,buffer[eax-4]
			mov		eax,[eax]
			and		eax,05F5F5FFFh
			.if eax=='SEM.'
				invoke ReadSessionFile,addr buffer
			.else
				invoke OpenEditFile,addr buffer,0
			.endif
		.endif
	.endw
	ret

OpenCommandLine endp
