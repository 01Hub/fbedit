
IDD_XPMANIFEST					equ 2000
IDC_EDTXPID						equ 1001
IDC_EDTXPNAME					equ 1000
IDC_EDTXPMANIFEST				equ 1002
IDC_EDTXPFILE					equ 1003
IDC_BTNXPFILE					equ 1004

.data

szManifestName		db 'IDR_XPMANIFEST',0
defxpmanifest		XPMANIFESTMEM	<,1,"xpmanifest.xml">
					db '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',0Dh,0Ah
					db '<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">',0Dh,0Ah
					db '<assemblyIdentity',0Dh,0Ah
					db 09h,'version="1.0.0.0"',0Dh,0Ah
					db 09h,'processorArchitecture="X86"',0Dh,0Ah
					db 09h,'name="Company.Product.Name"',0Dh,0Ah
					db 09h,'type="win32"',0Dh,0Ah
					db '/>',0Dh,0Ah
					db '<description></description>',0Dh,0Ah
					db '<dependency>',0Dh,0Ah
					db 09h,'<dependentAssembly>',0Dh,0Ah
					db 09h,09h,'<assemblyIdentity',0Dh,0Ah
					db 09h,09h,09h,'type="win32"',0Dh,0Ah
					db 09h,09h,09h,'name="Microsoft.Windows.Common-Controls"',0Dh,0Ah
					db 09h,09h,09h,'version="6.0.0.0"',0Dh,0Ah
					db 09h,09h,09h,'processorArchitecture="X86"',0Dh,0Ah
					db 09h,09h,09h,'publicKeyToken="6595b64144ccf1df"',0Dh,0Ah
					db 09h,09h,09h,'language="*"',0Dh,0Ah
					db 09h,09h,'/>',0Dh,0Ah
					db 09h,'</dependentAssembly>',0Dh,0Ah
					db '</dependency>',0Dh,0Ah
					db '</assembly>',0

.code

ExportXPManifestNames proc uses esi edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*16
	mov     edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	;#define
    .if [esi].XPMANIFESTMEM.szname && [esi].XPMANIFESTMEM.value
		invoke SaveStr,edi,addr szDEFINE
		add		edi,eax
		mov		al,' '
		stosb
		invoke SaveStr,edi,addr [esi].XPMANIFESTMEM.szname
		add		edi,eax
		mov		al,' '
		stosb
		invoke ResEdBinToDec,[esi].XPMANIFESTMEM.value,edi
		invoke lstrlen,edi
		lea		edi,[edi+eax]
		mov		al,0Dh
		stosb
		mov		al,0Ah
		stosb
	.endif
	mov		ax,0A0Dh
	stosw
	mov		al,0
	stosb
	pop		eax
	ret

ExportXPManifestNames endp

ExportXPManifest proc uses esi edi,hMem:DWORD
	LOCAL	hFile:DWORD
	LOCAL	nBytes:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16*1024
	mov		edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	;Name or ID
    .if [esi].XPMANIFESTMEM.szname
    	invoke lstrcpy,edi,addr [esi].XPMANIFESTMEM.szname
	.else
		invoke ResEdBinToDec,[esi].XPMANIFESTMEM.value,edi
	.endif
	invoke lstrlen,edi
	add		edi,eax
	mov		al,' '
	stosb
	invoke SaveStr,edi,addr szMANIFEST
	add		edi,eax
	lea		eax,[esi].XPMANIFESTMEM.szfilename
	.if byte ptr [esi].XPMANIFESTMEM.szfilename
		;Save as file
		mov		al,' '
		stosb
		mov		al,'"'
		stosb
		xor		ecx,ecx
		.while byte ptr [esi+ecx].XPMANIFESTMEM.szfilename
			mov		al,[esi+ecx].XPMANIFESTMEM.szfilename
			.if al=='\'
				mov		al,'/'
			.endif
			mov		[edi],al
			inc		ecx
			inc		edi
		.endw
		mov		al,'"'
		stosb
		invoke lstrcpy,addr buffer,addr szProjectPath
		invoke lstrcat,addr buffer,addr szBS
		invoke lstrcat,addr buffer,addr [esi].XPMANIFESTMEM.szfilename
		invoke CreateFile,addr buffer,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
		.if eax!=INVALID_HANDLE_VALUE
			mov		hFile,eax
			invoke lstrlen,addr [esi+sizeof XPMANIFESTMEM]
			mov		edx,eax
			invoke WriteFile,hFile,addr [esi+sizeof XPMANIFESTMEM],edx,addr nBytes,NULL
			invoke CloseHandle,hFile
		.endif
	.else
		mov		al,0Dh
		stosb
		mov		al,0Ah
		stosb
		invoke SaveStr,edi,addr szBEGIN
		add		edi,eax
		mov		al,0Dh
		stosb
		mov		al,0Ah
		stosb
		mov		al,'"'
		stosb
		lea		edx,[esi+sizeof XPMANIFESTMEM]
		.while byte ptr [edx]
			mov		al,[edx]
			.if al=='"'
				mov		[edi],al
				inc		edi
			.endif
			mov		[edi],al
			inc		edi
			inc		edx
		.endw
		mov		al,'"'
		stosb
		mov		al,0Dh
		stosb
		mov		al,0Ah
		stosb
		invoke SaveStr,edi,addr szEND
		add		edi,eax
	.endif
	mov		al,0Dh
	stosb
	mov		al,0Ah
	stosb
	mov		al,0Dh
	stosb
	mov		al,0Ah
	stosb
	mov		byte ptr [edi],0
	pop		eax
	ret

ExportXPManifest endp

XPManifestEditProc proc uses esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	ofn:OPENFILENAME

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		esi,lParam
		.if [esi].PROJECT.hmem
			mov		edi,[esi].PROJECT.hmem
		.else
			invoke GetFreeProjectitemID,TPE_XPMANIFEST
			mov		edi,offset defxpmanifest
			mov		[edi].XPMANIFESTMEM.value,eax
			invoke lstrcpy,addr [edi].XPMANIFESTMEM.szname,addr szManifestName
			invoke GetUnikeName,addr [edi].XPMANIFESTMEM.szname
		.endif
		invoke SetWindowLong,hWin,GWL_USERDATA,esi
		invoke SendDlgItemMessage,hWin,IDC_EDTXPNAME,EM_LIMITTEXT,MaxName-1,0
		invoke SetDlgItemText,hWin,IDC_EDTXPNAME,addr [edi].XPMANIFESTMEM.szname
		invoke SendDlgItemMessage,hWin,IDC_EDTXPID,EM_LIMITTEXT,5,0
		invoke SetDlgItemInt,hWin,IDC_EDTXPID,[edi].XPMANIFESTMEM.value,TRUE
		invoke SendDlgItemMessage,hWin,IDC_EDTXPFILE,EM_LIMITTEXT,MAX_PATH,0
		invoke SetDlgItemText,hWin,IDC_EDTXPFILE,addr [edi].XPMANIFESTMEM.szfilename
		invoke SetDlgItemText,hWin,IDC_EDTXPMANIFEST,addr [edi+sizeof XPMANIFESTMEM]
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				xor		esi,esi
				invoke GetWindowLong,hWin,GWL_USERDATA
				.if eax
					mov		esi,[eax].PROJECT.hmem
				.endif
				.if !esi
					invoke SendMessage,hPrj,PRO_ADDITEM,TPE_XPMANIFEST,FALSE
				.endif
				mov		[eax].PROJECT.changed,TRUE
				mov		esi,[eax].PROJECT.hmem
				invoke GetDlgItemText,hWin,IDC_EDTXPNAME,addr [esi].XPMANIFESTMEM.szname,MaxName
				invoke GetDlgItemInt,hWin,IDC_EDTXPID,NULL,FALSE
				mov		[esi].XPMANIFESTMEM.value,eax
				invoke GetDlgItemText,hWin,IDC_EDTXPFILE,addr [esi].XPMANIFESTMEM.szfilename,MAX_PATH
				invoke GetDlgItemText,hWin,IDC_EDTXPMANIFEST,addr [esi+sizeof XPMANIFESTMEM],8192
				invoke GetWindowLong,hWin,GWL_USERDATA
				mov		esi,eax
				invoke GetProjectItemName,esi,addr buffer
				invoke SetProjectItemName,esi,addr buffer
				invoke SendMessage,hWin,WM_CLOSE,NULL,TRUE
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNXPFILE
				;Setup the ofn struct
				invoke RtlZeroMemory,addr ofn,sizeof ofn
				mov		ofn.lStructSize,sizeof ofn
				mov		eax,offset szFilterManifest
				mov		ofn.lpstrFilter,eax
				invoke GetDlgItemText,hWin,IDC_EDTXPFILE,addr buffer,sizeof buffer
				push	hWin
				pop		ofn.hwndOwner
				push	hInstance
				pop		ofn.hInstance
				mov		ofn.lpstrInitialDir,offset szProjectPath
				lea		eax,buffer
				mov		ofn.lpstrFile,eax
				mov		ofn.nMaxFile,sizeof buffer
				mov		ofn.lpstrDefExt,NULL
				mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
				;Show the Open dialog
				invoke GetOpenFileName,addr ofn
				.if eax
					invoke RemoveProjectPath,addr buffer
					invoke SetDlgItemText,hWin,IDC_EDTXPFILE,eax
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

XPManifestEditProc endp
