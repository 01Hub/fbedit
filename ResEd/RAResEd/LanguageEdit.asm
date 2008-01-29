IDD_LANGUAGE		equ 1800
IDC_CBOLANG			equ 5001
IDC_CBOSUBLANG		equ 5002

.data?

nLang				dd ?
nSubLang			dd ?

.code

SaveLanguage proc uses esi edi,lpLang:DWORD,lpRCMem:DWORD

	mov		esi,lpLang
	mov		edi,lpRCMem
	invoke SaveStr,edi,offset szLANGUAGE
	add		edi,eax
	mov		al,' '
	stosb
	mov		eax,[esi].LANGUAGEMEM.lang
	invoke SaveVal,eax,TRUE
	mov		eax,[esi].LANGUAGEMEM.sublang
	invoke SaveVal,eax,FALSE
	mov		ax,0A0Dh
	stosw
	mov		eax,edi
	sub		eax,lpRCMem
	ret

SaveLanguage endp

ExportLanguage proc uses edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4096
	mov		edi,eax
	invoke GlobalLock,edi
	push	edi
	invoke SaveLanguage,hMem,edi
	add		edi,eax
	mov		ax,0A0Dh
	stosw
	mov		byte ptr [edi],0
	pop		eax
	ret

ExportLanguage endp

LanguageEditProc proc uses ebx esi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	nInx:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		esi,lParam
		.if [esi].PROJECT.hmem
			mov		edx,[esi].PROJECT.hmem
			mov		eax,[edx].LANGUAGEMEM.lang
			mov		nLang,eax
			mov		eax,[edx].LANGUAGEMEM.sublang
			mov		nSubLang,eax
		.else
			xor		eax,eax
			mov		nLang,eax
			mov		nSubLang,eax
		.endif
		invoke SetWindowLong,hWin,GWL_USERDATA,esi
		call	GetLang
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_GETITEMDATA,eax,0
				mov		nLang,eax
				invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_GETITEMDATA,eax,0
				mov		nSubLang,eax
				xor		esi,esi
				invoke GetWindowLong,hWin,GWL_USERDATA
				.if eax
					mov		esi,[eax].PROJECT.hmem
				.endif
				.if !esi
					invoke SendMessage,hRes,PRO_ADDITEM,TPE_LANGUAGE,FALSE
				.endif
				mov		[eax].PROJECT.changed,TRUE
				mov		esi,[eax].PROJECT.hmem
				mov		eax,nLang
				mov		[esi].LANGUAGEMEM.lang,eax
				mov		eax,nSubLang
				mov		[esi].LANGUAGEMEM.sublang,eax
				invoke SendMessage,hWin,WM_CLOSE,NULL,TRUE
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,FALSE
			.endif
		.elseif edx==CBN_SELCHANGE
			.if eax==IDC_CBOLANG
				invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_GETITEMDATA,eax,0
				mov		nLang,eax
				mov		nSubLang,0
				.if eax
					mov		nSubLang,1
				.endif
				call	GetLang
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,lParam
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

GetLang:
	mov		nInx,0
	invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_RESETCONTENT,0,0
	invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_RESETCONTENT,0,0
	mov		esi,offset langdef
  @@:
	invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_ADDSTRING,0,addr [esi+4]
	mov		ebx,[esi]
	shr		ebx,16
	.if ebx==nLang
		push	eax
		invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_SETCURSEL,eax,0
		pop		eax
	.endif
	invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_SETITEMDATA,eax,ebx
	lea		esi,[esi+4]
	invoke strlen,esi
	lea		esi,[esi+eax+1]
	.while dword ptr [esi]<10000h && byte ptr [esi+4]
		.if ebx==nLang
			invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_ADDSTRING,0,addr [esi+4]
			mov		edx,[esi]
			.if edx==nSubLang
				push	eax
				invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_SETCURSEL,eax,0
				pop		eax
			.endif
			invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_SETITEMDATA,eax,[esi]
		.endif
		lea		esi,[esi+4]
		invoke strlen,esi
		lea		esi,[esi+eax+1]
	.endw
	.if byte ptr [esi+4]
		jmp		@b
	.endif
	retn

LanguageEditProc endp

;Used by dialog, menu, accelerator and stringtable
LanguageEditProc2 proc uses ebx esi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	nInx:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		esi,lParam
		mov		eax,[esi].LANGUAGEMEM.lang
		mov		nLang,eax
		mov		eax,[esi].LANGUAGEMEM.sublang
		mov		nSubLang,eax
		invoke SetWindowLong,hWin,GWL_USERDATA,esi
		call	GetLang
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_GETITEMDATA,eax,0
				mov		nLang,eax
				invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_GETITEMDATA,eax,0
				mov		nSubLang,eax
				invoke GetWindowLong,hWin,GWL_USERDATA
				mov		esi,eax
				mov		eax,nLang
				mov		[esi].LANGUAGEMEM.lang,eax
				mov		eax,nSubLang
				mov		[esi].LANGUAGEMEM.sublang,eax
				invoke SendMessage,hWin,WM_CLOSE,NULL,TRUE
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,FALSE
			.endif
		.elseif edx==CBN_SELCHANGE
			.if eax==IDC_CBOLANG
				invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_GETCURSEL,0,0
				invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_GETITEMDATA,eax,0
				mov		nLang,eax
				mov		nSubLang,0
				.if eax
					mov		nSubLang,1
				.endif
				call	GetLang
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,lParam
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

GetLang:
	mov		nInx,0
	invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_RESETCONTENT,0,0
	invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_RESETCONTENT,0,0
	mov		esi,offset langdef
  @@:
	invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_ADDSTRING,0,addr [esi+4]
	mov		ebx,[esi]
	shr		ebx,16
	.if ebx==nLang
		push	eax
		invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_SETCURSEL,eax,0
		pop		eax
	.endif
	invoke SendDlgItemMessage,hWin,IDC_CBOLANG,CB_SETITEMDATA,eax,ebx
	lea		esi,[esi+4]
	invoke strlen,esi
	lea		esi,[esi+eax+1]
	.while dword ptr [esi]<10000h && byte ptr [esi+4]
		.if ebx==nLang
			invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_ADDSTRING,0,addr [esi+4]
			mov		edx,[esi]
			.if edx==nSubLang
				push	eax
				invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_SETCURSEL,eax,0
				pop		eax
			.endif
			invoke SendDlgItemMessage,hWin,IDC_CBOSUBLANG,CB_SETITEMDATA,eax,[esi]
		.endif
		lea		esi,[esi+4]
		invoke strlen,esi
		lea		esi,[esi+eax+1]
	.endw
	.if byte ptr [esi+4]
		jmp		@b
	.endif
	retn

LanguageEditProc2 endp
