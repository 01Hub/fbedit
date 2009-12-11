
IDD_DLGCHECK_UPDATE				equ 8000
IDC_STCVERSION					equ 1001
IDC_CHKGETIDE					equ 1002
IDC_CHKGETASM					equ 1003
IDC_CHKGETHLL					equ 1004
IDC_CHKGETLNG					equ 1005
IDC_BTNDOWNLOAD					equ 1008
IDC_EDTDLPATH					equ 1006
IDC_BTNDLPATH					equ 1007

IDD_DLGDOWNLOAD					equ 8100
IDC_STCDOWNLOADING				equ 1001
IDC_STCFILESIZE					equ 1003
IDC_PGB1						equ 1002

.const

szFmtVersion					db 'Your current version:',9,'%s',13,'Version at sourceforge:',9,'%s',0
szINetErr4						db 'Could not find:',13,10
szUrlVersion					db 'https://fbedit.svn.sourceforge.net/svnroot/fbedit/RadASM/ReleaseVersion.txt',0
szUrlFile						db 'https://fbedit.svn.sourceforge.net/svnroot/fbedit/RadASM/ReleaseMake/',0

szDownloading					db 'Downloading: ',0
szFmtFilesize					db 'Filesize: %d bytes',0
;szIDEFile						db 'Release.zip',0
szIDEFile						db 'RadASMIDE.zip',0
szASMFile						db 'Assembly.zip',0
szHLLFile						db 'HighLevel.zip',0
szLNGFile						db 'Language.zip',0

szINetErr1						db 'InternetOpen failed.',0
szINetErr2						db 'InternetOpenUrl failed.',0
szINetErr3						db 'InternetReadFile failed',0

.data?

szDLFileName					db MAX_PATH dup(?)
szDLPath						db MAX_PATH dup(?)

.code

InternetDownloadFile proc uses ebx,hWin:HWND
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE
	LOCAL	hInternet:HANDLE
	LOCAL	hUrl:HANDLE
	LOCAL	contextid:DWORD
	LOCAL	dwsize:DWORD
	LOCAL	dwread:DWORD
	LOCAL	dwindex:DWORD

	invoke strcpy,addr buffer,addr szUrlFile
	invoke strcat,addr buffer,addr szDLFileName

	invoke InternetOpen,addr AppName,INTERNET_OPEN_TYPE_DIRECT,0,0,0
	.if eax
		mov		hInternet,eax
		invoke InternetOpenUrl,hInternet,addr buffer,0,0,INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE,addr contextid
		.if eax
			mov		hUrl,eax
			mov		dwread,4
			invoke HttpQueryInfo,hUrl,HTTP_QUERY_CONTENT_LENGTH or HTTP_QUERY_FLAG_NUMBER,addr dwsize,addr dwread,addr dwindex
			mov		ebx,dwsize
			invoke wsprintf,addr buffer1,addr szFmtFilesize,ebx
			invoke SetDlgItemText,hWin,IDC_STCFILESIZE,addr buffer1
			shr		ebx,8
			shl		ebx,16
			invoke SendDlgItemMessage,hWin,IDC_PGB1,PBM_SETRANGE,0,ebx
			xor		ebx,ebx
			.while ebx<dwsize
				invoke InternetReadFile,hUrl,addr buffer1,256,addr dwread
				.if eax
					mov		eax,dwread
					add		ebx,eax
				.else
					mov		eax,-3
					mov		ebx,-1
				.endif
				mov		eax,ebx
				shr		eax,8
				invoke SendDlgItemMessage,hWin,IDC_PGB1,PBM_SETPOS,eax,0
			.endw
			push	eax
			invoke InternetCloseHandle,hUrl
			pop		eax
		.else
			mov		eax,-2
		.endif
		push	eax
		invoke InternetCloseHandle,hInternet
		pop		eax
	.else
		mov		eax,-1
	.endif
	push	eax
	invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
	pop		eax
	ret

InternetDownloadFile endp

DownloadProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	tid:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke strcpy,addr buffer,addr szDownloading
		invoke strcat,addr buffer,addr szDLFileName
		invoke SetDlgItemText,hWin,IDC_STCDOWNLOADING,addr buffer
		invoke CreateThread,NULL,NULL,addr InternetDownloadFile,hWin,NORMAL_PRIORITY_CLASS,addr tid
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
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

DownloadProc endp

InternetDownload proc hWin:HWND,lpFileName:DWORD

	invoke strcpy,addr szDLFileName,lpFileName
	invoke ModalDialog,hInstance,IDD_DLGDOWNLOAD,hWin,addr DownloadProc,0
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

UpdateCheckerProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke iniGetAppPath,addr buffer
		invoke SetDlgItemText,hWin,IDC_EDTDLPATH,addr buffer
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
						mov		eax,IDC_EDTDLPATH
						call	Enable
						mov		eax,IDC_BTNDLPATH
						call	Enable
						invoke GetDlgItem,hWin,IDOK
						invoke ShowWindow,eax,SW_HIDE
						invoke GetDlgItem,hWin,IDC_BTNDOWNLOAD
						invoke ShowWindow,eax,SW_SHOW
						invoke wsprintf,addr tempbuff[1024],addr szFmtVersion,addr AppName,addr tempbuff
						lea		eax,tempbuff[1024]
					.endif
				.endif
				invoke SetDlgItemText,hWin,IDC_STCVERSION,eax
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNDOWNLOAD
				invoke IsDlgButtonChecked,hWin,IDC_CHKGETIDE
				.if eax
					invoke InternetDownload,hWin,addr szIDEFile
				.endif
				invoke IsDlgButtonChecked,hWin,IDC_CHKGETASM
				.if eax
				.endif
				invoke IsDlgButtonChecked,hWin,IDC_CHKGETHLL
				.if eax
				.endif
				invoke IsDlgButtonChecked,hWin,IDC_CHKGETLNG
				.if eax
				.endif
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

UpdateCheckerProc endp
