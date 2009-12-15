;#########################################################################
; Assembler directives

.486
.model flat,stdcall
option casemap:none

;#########################################################################
; Include file

include UpdateChecker.inc

.code

; set initial folder in browser
BrowseCallbackProc proc hwnd:DWORD,uMsg:UINT,lParam:LPARAM,lpCBData:DWORD

	mov eax,uMsg
	.if eax==BFFM_INITIALIZED
		invoke PostMessage,hwnd,BFFM_SETSELECTION,TRUE,lpCBData
	.endif
	xor eax, eax
	ret

BrowseCallbackProc endp

BrowseFolder proc hWin:HWND,nID:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		bri.pidlRoot,0
	mov		bri.pszDisplayName,0
	xor		eax,eax
	mov		bri.lpszTitle,eax
	mov		bri.ulFlags,BIF_RETURNONLYFSDIRS or BIF_STATUSTEXT 
	mov		bri.lpfn,BrowseCallbackProc
	; get path   
	invoke SendDlgItemMessage,hWin,nID,WM_GETTEXT,sizeof buffer,addr buffer
	lea		eax,buffer
	mov		bri.lParam,eax 
	mov		bri.iImage,0
	invoke SHBrowseForFolder,offset bri
	.if !eax
		jmp		GetOut
	.endif
	mov		edx,eax
	invoke SHGetPathFromIDList,edx,addr buffer
	; set new path back to edit
	invoke SetDlgItemText,hWin,nID,addr buffer
  GetOut:
	ret

BrowseFolder endp

InternetDownloadFile proc uses ebx,hWin:HWND
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE
	LOCAL	hInternet:HANDLE
	LOCAL	hUrl:HANDLE
	LOCAL	contextid:DWORD
	LOCAL	dwsize:DWORD
	LOCAL	dwread:DWORD
	LOCAL	dwindex:DWORD
	LOCAL	hFile:HANDLE
	LOCAL	nRetry:DWORD

	xor		eax,eax
	mov		nRetry,eax
	mov		hFile,eax
	invoke InternetOpen,addr AppName,INTERNET_OPEN_TYPE_DIRECT,0,0,0
	.if eax
		mov		hInternet,eax
		invoke lstrcpy,addr buffer1,addr szUrlFile
		invoke lstrcat,addr buffer1,addr szDLFileName
		invoke InternetOpenUrl,hInternet,addr buffer1,0,0,INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE,addr contextid
		.if eax
			mov		hUrl,eax
			mov		dwread,4
			invoke HttpQueryInfo,hUrl,HTTP_QUERY_CONTENT_LENGTH or HTTP_QUERY_FLAG_NUMBER,addr dwsize,addr dwread,addr dwindex
			.if eax
				mov		ebx,dwsize
				invoke wsprintf,addr buffer1,addr szFmtFilesize,ebx
				invoke SetDlgItemText,hWin,IDC_STCFILESIZE,addr buffer1
				shr		ebx,8
				shl		ebx,16
				invoke SendDlgItemMessage,hWin,IDC_PGB1,PBM_SETRANGE,0,ebx
				xor		ebx,ebx
				.while ebx<dwsize
					.if fDLCancel
						dec		fDLCancel
						mov		eax,-4
						.break
					.endif
					invoke InternetReadFile,hUrl,addr buffer1,256,addr dwread
					.if eax
						mov		eax,dwread
						.if !eax
							; Reconnect
							invoke InternetCloseHandle,hUrl
							mov		hUrl,0
							invoke InternetCloseHandle,hInternet
							mov		hInternet,0
							invoke InternetOpen,addr AppName,INTERNET_OPEN_TYPE_DIRECT,0,0,0
							.if eax
								mov		hInternet,eax
								invoke lstrcpy,addr buffer1,addr szUrlFile
								invoke lstrcat,addr buffer1,addr szDLFileName
								invoke InternetOpenUrl,hInternet,addr buffer1,0,0,INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE,addr contextid
								.if eax
									mov		hUrl,eax
								.endif
							.endif
						.else
							add		ebx,eax
							.if !hFile
								; Create the file
								invoke lstrcpy,addr buffer,addr szDLPath
								invoke lstrcat,addr buffer,addr szBackSlash
								invoke lstrcat,addr buffer,addr szDLFileName
								invoke CreateFile,addr buffer,GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
								.if eax!=INVALID_HANDLE_VALUE
									mov		hFile,eax
								.else
									mov		eax,-5
									.break
								.endif
							.endif
							invoke WriteFile,hFile,addr buffer1,dwread,addr dwread,NULL
							mov		eax,ebx
							shr		eax,8
							invoke SendDlgItemMessage,hWin,IDC_PGB1,PBM_SETPOS,eax,0
							xor		eax,eax
						.endif
					.else
						inc		nRetry
						.if nRetry>10
							mov		eax,-3
							.break
						.endif
					.endif
				.endw
				.if hFile
					push	eax
					invoke CloseHandle,hFile
					pop		eax
				.endif
			.else
				mov		eax,-3
			.endif
			.if hUrl
				push	eax
				invoke InternetCloseHandle,hUrl
				pop		eax
			.endif
		.else
			mov		eax,-2
		.endif
		.if hInternet
			push	eax
			invoke InternetCloseHandle,hInternet
			pop		eax
		.endif
	.else
		mov		eax,-1
	.endif
	mov		nDLThread,eax
	invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
	ret

InternetDownloadFile endp

DownloadProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	tid:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke lstrcpy,addr buffer,addr szDownloading
		invoke lstrcat,addr buffer,addr szDLFileName
		invoke SetDlgItemText,hWin,IDC_STCDOWNLOADING,addr buffer
		invoke CreateThread,NULL,NULL,addr InternetDownloadFile,hWin,NORMAL_PRIORITY_CLASS,addr tid
		mov		hDLThread,eax
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				inc		fDLCancel
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,nDLThread
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DownloadProc endp

InternetDownload proc hWin:HWND,lpFileName:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		fDLCancel,0
	invoke lstrcpy,addr szDLFileName,lpFileName
	push	0
	push	offset DownloadProc
	push	hWin
	push	IDD_DLGDOWNLOAD
	push	hInstance
	mov		edx,lpProc
	call	[edx].ADDINPROCS.lpModalDialog
	.if !eax
		invoke wsprintf,addr buffer,addr szFmtDownloaded,lpFileName,addr szSuccess
	.elseif eax==-4
		invoke wsprintf,addr buffer,addr szFmtDownloaded,lpFileName,addr szCanceled
		inc		nDLErrors
	.else
		invoke wsprintf,addr buffer,addr szFmtDownloaded,lpFileName,addr szFailed
		inc		nDLErrors
	.endif
	invoke GetDlgItemText,hWin,IDC_EDTVERSION,addr tempbuff,1024
	invoke lstrcat,addr tempbuff,addr buffer
	invoke SetDlgItemText,hWin,IDC_EDTVERSION,addr tempbuff
	ret

InternetDownload endp

InternetGetVersion proc lpUrl:DWORD,lpBuff:DWORD,nBytes:DWORD
	LOCAL	hInternet:HANDLE
	LOCAL	hUrl:HANDLE
	LOCAL	contextid:DWORD
	LOCAL	dwread:DWORD
	LOCAL	dwindex:DWORD

	invoke InternetOpen,addr AppName,INTERNET_OPEN_TYPE_DIRECT,0,0,0
	.if eax
		mov		hInternet,eax
		invoke InternetOpenUrl,hInternet,lpUrl,0,0,INTERNET_FLAG_RELOAD,addr contextid
		.if eax
			mov		hUrl,eax
			mov		dwread,256
			invoke HttpQueryInfo,hUrl,HTTP_QUERY_CONTENT_LENGTH or HTTP_QUERY_FLAG_NUMBER,lpBuff,addr dwread,addr dwindex
			invoke InternetReadFile,hUrl,lpBuff,nBytes,addr dwread
			.if eax
				invoke InternetCloseHandle,hUrl
				mov		eax,dwread
			.else
				invoke InternetCloseHandle,hUrl
				mov		eax,-3
			.endif
		.else
			mov		eax,-2
		.endif
		push	eax
		invoke InternetCloseHandle,hInternet
		pop		eax
	.else
		mov		eax,-1
	.endif
	ret

InternetGetVersion endp

IsFoderEmpty proc
	LOCAL	wfd:WIN32_FIND_DATA
	LOCAL	hWfd:HANDLE
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke lstrcpy,addr buffer,addr szDLPath
	invoke lstrcat,addr buffer,addr szAllFiles
	invoke FindFirstFile,addr buffer,addr wfd
	.if eax!=INVALID_HANDLE_VALUE
		mov		hWfd,eax
		.while eax
			lea		eax,wfd.cFileName
			.if word ptr [eax]!='.' && word ptr [eax]!='..'
				invoke FindClose,hWfd
				xor		eax,eax
				ret
			.endif
			invoke FindNextFile,hWfd,addr wfd
		.endw
		invoke FindClose,hWfd
		mov		eax,TRUE
	.endif
	ret

IsFoderEmpty endp

DeleteFiles proc hWin:HWND
	LOCAL	sfo:SHFILEOPSTRUCT
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke lstrcpy,addr buffer,addr szDLPath
	invoke lstrcat,addr buffer,addr szAllFiles
	mov		eax,hWin
	mov		sfo.hwnd,eax
	mov		sfo.wFunc,FO_DELETE
	lea		eax,buffer
	mov		sfo.pFrom,eax
	mov		sfo.pTo,NULL
	mov		sfo.fFlags,FOF_NOERRORUI or	FOF_SILENT or FOF_ALLOWUNDO
	mov		sfo.fAnyOperationsAborted,0
	mov		sfo.lpszProgressTitle,offset AppName
	mov		sfo.hNameMappings,NULL
	invoke SHFileOperation,ADDR	sfo
	mov		eax,sfo.fAnyOperationsAborted
	ret

DeleteFiles endp


CreateFolder proc uses ebx esi,hWin:HWND

	mov		esi,offset szDLPath
	invoke RtlZeroMemory,esi,sizeof szDLPath
	invoke GetDlgItemText,hWin,IDC_EDTDLPATH,esi,sizeof szDLPath
	invoke GetFileAttributes,esi
	.if eax!=INVALID_HANDLE_VALUE
		; Folder exist
		invoke IsFoderEmpty
		.if !eax
			; Folder is not empty
			invoke wsprintf,addr tempbuff,addr szFmtErrNotEmpty,addr szDLPath
			invoke MessageBox,hWin,addr tempbuff,addr AppName,MB_YESNO or MB_ICONQUESTION
			.if eax==IDYES
				; Delete files
				invoke DeleteFiles,hWin
				.if eax
					xor		eax,eax
				.else
					mov		eax,TRUE
				.endif
			.else
				xor		eax,eax
			.endif
		.else
			; Folder is empty
			mov		eax,TRUE
		.endif
	.else
		; Folder does not exist, create it.
		invoke lstrlen,esi
		mov		ebx,eax
		.while ebx
			.if byte ptr [esi+ebx]=='\'
				mov		byte ptr [esi+ebx],0
				invoke GetFileAttributes,esi
				.if eax!=INVALID_HANDLE_VALUE
					; Path exist
					.while byte ptr [esi+ebx+1]
						mov		byte ptr [esi+ebx],'\'
						invoke CreateDirectory,esi,0
						.while byte ptr [esi+ebx]
							inc		ebx
						.endw
					.endw
					.break
				.endif
			.endif
			dec		ebx
		.endw
		mov		eax,TRUE
	.endif
	ret

CreateFolder endp

CreateTheFile proc uses ebx esi,lpFileName:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke lstrcpy,addr buffer,addr szDLPath
	invoke lstrcat,addr buffer,addr szBackSlash
	invoke lstrcat,addr buffer,lpFileName
	invoke lstrlen,addr buffer
	push	eax
	.while eax
		dec		eax
		.if byte ptr buffer[eax]=='/'
			mov		byte ptr buffer[eax],'\'
		.endif
	.endw
	pop		eax
	.while eax && byte ptr buffer[eax]!='\'
		dec		eax
	.endw
	.if byte ptr buffer[eax]=='\'
		mov		word ptr buffer[eax],0
		call	MakeFolder
		invoke lstrcpy,addr buffer,addr szDLPath
		invoke lstrcat,addr buffer,addr szBackSlash
		invoke lstrcat,addr buffer,lpFileName
		invoke CreateFile,addr buffer,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	.else
		mov		eax,INVALID_HANDLE_VALUE
	.endif
	ret

MakeFolder:
	lea		esi,buffer
	invoke GetFileAttributes,esi
	.if eax==INVALID_HANDLE_VALUE
		invoke lstrlen,esi
		mov		ebx,eax
		.while ebx
			.if byte ptr [esi+ebx]=='\'
				mov		byte ptr [esi+ebx],0
				invoke GetFileAttributes,esi
				.if eax!=INVALID_HANDLE_VALUE
					; Path exist
					.while byte ptr [esi+ebx+1]
						mov		byte ptr [esi+ebx],'\'
						invoke CreateDirectory,esi,0
						.while byte ptr [esi+ebx]
							inc		ebx
						.endw
					.endw
					.break
				.endif
			.endif
			dec		ebx
		.endw
	.endif
	retn

CreateTheFile endp

UnZip proc uses esi,hWin:HWND,lpFileName:DWORD
	LOCAL	hz:DWORD
	LOCAL	fi:unz_file_info
	LOCAL	filename_inzip[MAX_PATH]:BYTE
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	hMem:HGLOBAL
	LOCAL	hFile:HANDLE
	LOCAL	dwwrite:DWORD

	mov		esi,offset szDLPath
	invoke RtlZeroMemory,esi,sizeof szDLPath
	invoke GetDlgItemText,hWin,IDC_EDTDLPATH,esi,sizeof szDLPath
	invoke lstrcpy,addr buffer,addr szDLPath
	invoke lstrcat,addr buffer,addr szBackSlash
	invoke lstrcat,addr buffer,lpFileName
	invoke SendDlgItemMessage,hWin,IDC_EDTVERSION,EM_REPLACESEL,0,addr buffer
	invoke SendDlgItemMessage,hWin,IDC_EDTVERSION,EM_REPLACESEL,0,addr szCRLF
	invoke unzOpen,addr buffer
	.if eax
		mov		hz,eax
		invoke unzGoToFirstFile,hz
		.while !eax
			invoke unzGetCurrentFileInfo,hz,addr fi,addr filename_inzip,sizeof filename_inzip,NULL,0,NULL,0
			.if !eax
				invoke SendDlgItemMessage,hWin,IDC_EDTVERSION,EM_REPLACESEL,0,addr filename_inzip
				invoke SendDlgItemMessage,hWin,IDC_EDTVERSION,EM_REPLACESEL,0,addr szCRLF
				invoke unzOpenCurrentFile,hz
				.if !eax
					invoke GlobalAlloc,GMEM_FIXED,fi.uncompressed_size
					mov		hMem,eax
					invoke unzReadCurrentFile,hz,hMem,fi.uncompressed_size
					.if eax==fi.uncompressed_size
						invoke CreateTheFile,addr filename_inzip
						.if eax!=INVALID_HANDLE_VALUE
							mov		hFile,eax
							invoke WriteFile,hFile,hMem,fi.uncompressed_size,addr dwwrite,NULL
							invoke CloseHandle,hFile
						.endif
						invoke GlobalFree,hMem
						invoke unzCloseCurrentFile,hz
						invoke unzGoToNextFile,hz
					.endif
				.endif
			.endif
		.endw
		invoke unzClose,hz
		invoke DeleteFile,addr buffer
		invoke SendDlgItemMessage,hWin,IDC_EDTVERSION,EM_REPLACESEL,0,addr szCRLF
	.endif
	ret

UnZip endp

UpdateCheckerProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,lpData
		invoke lstrcpy,addr szDLPath,[eax].ADDINDATA.lpLoadPath
		invoke lstrcat,addr szDLPath,addr szTemp
		invoke SetDlgItemText,hWin,IDC_EDTDLPATH,addr szDLPath
		invoke CheckDlgButton,hWin,IDC_CHKGETIDE,BST_CHECKED
		invoke CheckDlgButton,hWin,IDC_CHKGETASM,BST_CHECKED
		invoke CheckDlgButton,hWin,IDC_CHKGETHLL,BST_CHECKED
		invoke CheckDlgButton,hWin,IDC_CHKGETLNG,BST_CHECKED
		invoke CheckDlgButton,hWin,IDC_CHKGETHLP,BST_CHECKED
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke RtlZeroMemory,addr tempbuff,sizeof tempbuff
				invoke InternetGetVersion,addr szUrlVersion,addr tempbuff,1023
				.if eax==-1
					mov		eax,offset szINetErr1
				.elseif eax==-2
					mov		eax,offset szINetErr2
				.elseif eax==-3
					mov		eax,offset szINetErr3
				.else
					.if word ptr tempbuff=='!<'
						mov		eax,offset szINetErr4
					.else
						mov		eax,IDC_CHKGETIDE
						call	Enable
						mov		eax,IDC_CHKGETASM
						call	Enable
						mov		eax,IDC_CHKGETHLL
						call	Enable
						mov		eax,IDC_CHKGETLNG
						call	Enable
						mov		eax,IDC_CHKGETHLP
						call	Enable
						mov		eax,IDC_EDTDLPATH
						call	Enable
						mov		eax,IDC_BTNDLPATH
						call	Enable
						invoke GetDlgItem,hWin,IDOK
						invoke ShowWindow,eax,SW_HIDE
						invoke GetDlgItem,hWin,IDC_BTNDOWNLOAD
						invoke ShowWindow,eax,SW_SHOW
						mov		edx,lpData
						invoke wsprintf,addr tempbuff[1024],addr szFmtVersion,[edx].ADDINDATA.lpszAppName,addr tempbuff
						lea		eax,tempbuff[1024]
					.endif
				.endif
				invoke SetDlgItemText,hWin,IDC_EDTVERSION,eax
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNDLPATH
				invoke BrowseFolder,hWin,IDC_EDTDLPATH
			.elseif eax==IDC_BTNDOWNLOAD
				mov		nDLErrors,0
				invoke CreateFolder,hWin
				.if eax
					invoke SetDlgItemText,hWin,IDC_EDTVERSION,0
					invoke IsDlgButtonChecked,hWin,IDC_CHKGETIDE
					.if eax
						invoke InternetDownload,hWin,addr szIDEFile
					.endif
					invoke IsDlgButtonChecked,hWin,IDC_CHKGETASM
					.if eax
						invoke InternetDownload,hWin,addr szASMFile
					.endif
					invoke IsDlgButtonChecked,hWin,IDC_CHKGETHLL
					.if eax
						invoke InternetDownload,hWin,addr szHLLFile
					.endif
					invoke IsDlgButtonChecked,hWin,IDC_CHKGETLNG
					.if eax
						invoke InternetDownload,hWin,addr szLNGFile
					.endif
					invoke IsDlgButtonChecked,hWin,IDC_CHKGETHLP
					.if eax
						invoke InternetDownload,hWin,addr szHLPFile
					.endif
					.if !nDLErrors
						invoke GetDlgItem,hWin,IDC_BTNDOWNLOAD
						invoke ShowWindow,eax,SW_HIDE
						invoke GetDlgItem,hWin,IDC_BTNUPDATE
						invoke ShowWindow,eax,SW_SHOW
						mov		eax,IDC_CHKGETIDE
						call	Disable
						mov		eax,IDC_CHKGETASM
						call	Disable
						mov		eax,IDC_CHKGETHLL
						call	Disable
						mov		eax,IDC_CHKGETLNG
						call	Disable
						mov		eax,IDC_CHKGETHLP
						call	Disable
						mov		eax,IDC_EDTDLPATH
						call	Disable
						mov		eax,IDC_BTNDLPATH
						call	Disable
					.endif
				.endif
			.elseif eax==IDC_BTNUPDATE
				invoke SetDlgItemText,hWin,IDC_EDTVERSION,0
				invoke IsDlgButtonChecked,hWin,IDC_CHKGETIDE
				.if eax
					invoke UnZip,hWin,addr szIDEFile
				.endif
				invoke IsDlgButtonChecked,hWin,IDC_CHKGETASM
				.if eax
					invoke UnZip,hWin,addr szASMFile
				.endif
				invoke IsDlgButtonChecked,hWin,IDC_CHKGETHLL
				.if eax
					invoke UnZip,hWin,addr szHLLFile
				.endif
				invoke IsDlgButtonChecked,hWin,IDC_CHKGETLNG
				.if eax
					invoke UnZip,hWin,addr szLNGFile
				.endif
				invoke IsDlgButtonChecked,hWin,IDC_CHKGETHLP
				.if eax
					invoke UnZip,hWin,addr szHLPFile
				.endif
				invoke SendDlgItemMessage,hWin,IDC_EDTVERSION,EM_REPLACESEL,0,addr szDone
				invoke GetDlgItem,hWin,IDC_BTNUPDATE
				invoke ShowWindow,eax,SW_HIDE
				invoke SetDlgItemText,hWin,IDCANCEL,addr szClose
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

Enable:
	invoke GetDlgItem,hWin,eax
	invoke EnableWindow,eax,TRUE
	retn

Disable:
	invoke GetDlgItem,hWin,eax
	invoke EnableWindow,eax,FALSE
	retn

UpdateCheckerProc endp

;#########################################################################
; Common AddIn Procedures

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	mov		eax,hInst
	mov		hInstance, eax
	mov		eax,TRUE
	ret

DllEntry Endp

; Export this proc (it is autoexported if MakeDef is enabled with option 2)
InstallDll proc uses ebx,hWin:DWORD,fOpt:DWORD
	LOCAL	mnui:MENUITEMINFO

	mov		ebx,hWin
	;Get pointer to handles struct
	invoke SendMessage,ebx,AIM_GETHANDLES,0,0
	mov		lpHandles,eax
	;Get pointer to proc struct
	invoke SendMessage,ebx,AIM_GETPROCS,0,0
	mov		lpProc,eax
	;Get pointer to data struct
	invoke SendMessage,ebx,AIM_GETDATA,0,0	
	mov		lpData,eax
	; Allocate a new menu id
	invoke SendMessage,ebx,AIM_GETMENUID,0,0
	mov		IDAddIn,eax
	mov		mnui.cbSize,sizeof MENUITEMINFO
	mov		mnui.fMask,MIIM_ID or MIIM_TYPE
	mov		mnui.fType,MFT_STRING
	mov		eax,IDAddIn
	mov		mnui.wID,eax
	mov		mnui.dwTypeData,offset szMenuCheck
	mov		mnui.cch,10
	;Insert our menuitem
	mov		edx,[lpHandles]
	invoke InsertMenuItem,(ADDINHANDLES ptr [edx]).hMenu,44022,FALSE,addr mnui
	; Messages to hook into
	mov		eax,RAM_COMMAND OR RAM_CLOSE OR RAM_MENUREBUILD
	; ECX and EDX must be null before we return
	xor		ecx,ecx
	xor		edx,edx
	ret

InstallDll Endp

; Export this proc (it is autoexported if MakeDef is enabled with option 2)
DllProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==AIM_COMMAND
		mov		eax,wParam
		movzx	edx,ax
		shr		eax, 16
		.if edx==IDAddIn && eax==BN_CLICKED
			; Your addin has been selected
			push	0
			push	offset UpdateCheckerProc
			push	hWin
			push	IDD_DLGCHECK_UPDATE
			push	hInstance
			mov		edx,lpProc
			call	[edx].ADDINPROCS.lpModalDialog
		.endif
	.elseif eax==AIM_CLOSE
		;
	.elseif eax==AIM_MENUREBUILD
		;
	.endif
	mov		eax,FALSE
	ret

DllProc Endp

;#########################################################################

End DllEntry
