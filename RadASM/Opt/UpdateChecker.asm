
IDD_DLGCHECK_UPDATE			equ 8000
IDC_STCVERSION				equ 1001

.const

szFmtVersion					db 'Your current version:',9,'%s',13,'Version at sourceforge:',9,'%s',0
szINetErr4						db 'Could not find:',13,10
szUrlVersion					db 'https://fbedit.svn.sourceforge.net/svnroot/fbedit/RadASM/ReleaseVersion.txt',0

szINetErr1						db 'InternetOpen failed.',0
szINetErr2						db 'InternetOpenUrl failed.',0
szINetErr3						db 'InternetReadFile failed',0

.code

InternetReadTheFile proc hWin:HWND,lpUrl:DWORD,hMem:HGLOBAL,nBytes:DWORD
	LOCAL	hInternet:HANDLE
	LOCAL	hUrl:HANDLE
	LOCAL	contextid:DWORD
	LOCAL	dwread:DWORD

	invoke InternetOpen,addr AppName,INTERNET_OPEN_TYPE_DIRECT,0,0,0
	.if eax
		mov		hInternet,eax
		invoke InternetOpenUrl,hInternet,lpUrl,0,0,INTERNET_FLAG_RELOAD,addr contextid
		.if eax
			mov		hUrl,eax
			invoke InternetReadFile,hUrl,hMem,nBytes,addr dwread
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
PrintDec eax
	ret

InternetReadTheFile endp

UpdateCheckerProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
	invoke RtlZeroMemory,addr tempbuff,sizeof tempbuff
		invoke InternetReadTheFile,hWin,addr szUrlVersion,addr tempbuff,1023
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
				invoke wsprintf,addr tempbuff[1024],addr szFmtVersion,addr AppName,addr tempbuff
				lea		eax,tempbuff[1024]
			.endif
		.endif
		invoke SetDlgItemText,hWin,IDC_STCVERSION,eax
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK

			.elseif eax==IDCANCEL
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

UpdateCheckerProc endp
