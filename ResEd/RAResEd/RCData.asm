IDD_RCDATA					equ 2500
IDC_EDTRCDATA					equ 1003
IDC_EDTRCDID						equ 1002
IDC_EDTRCDNAME					equ 1001

.data

szRcdataName		db 'IDR_RCDATA',0
defrcdata			RCDATAMEM	<,1>
					db 0

.code

ExportRCDataNames proc uses esi edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*16
	mov     edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	;#define
    .if [esi].RCDATAMEM.szname && [esi].RCDATAMEM.value
		invoke SaveStr,edi,addr szDEFINE
		add		edi,eax
		mov		al,' '
		stosb
		invoke SaveStr,edi,addr [esi].RCDATAMEM.szname
		add		edi,eax
		mov		al,' '
		stosb
		invoke ResEdBinToDec,[esi].RCDATAMEM.value,edi
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

ExportRCDataNames endp

ExportRCData proc uses esi edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16*1024
	mov		edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	;Name or ID
    .if [esi].RCDATAMEM.szname
    	invoke lstrcpy,edi,addr [esi].RCDATAMEM.szname
	.else
		invoke ResEdBinToDec,[esi].RCDATAMEM.value,edi
	.endif
	invoke lstrlen,edi
	add		edi,eax
	mov		al,' '
	stosb
   	invoke lstrcpy,edi,offset szRCDATA
	invoke lstrlen,edi
	add		edi,eax
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
	lea		edx,[esi+sizeof RCDATAMEM]
	.while byte ptr [edx]
		mov		al,[edx]
		mov		[edi],al
		inc		edi
		inc		edx
	.endw
	.if byte ptr [edi-1]!=0Ah
		mov		al,0Dh
		stosb
		mov		al,0Ah
		stosb
	.endif
	invoke SaveStr,edi,addr szEND
	add		edi,eax
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

ExportRCData endp

RCDataEditProc proc uses esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[256]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		esi,lParam
		.if [esi].PROJECT.hmem
			mov		edi,[esi].PROJECT.hmem
		.else
			invoke GetFreeProjectitemID,TPE_RCDATA
			mov		edi,offset defrcdata
			mov		[edi].RCDATAMEM.value,eax
			invoke lstrcpy,addr [edi].RCDATAMEM.szname,addr szRcdataName
			invoke GetUnikeName,addr [edi].RCDATAMEM.szname
		.endif
		invoke SetWindowLong,hWin,GWL_USERDATA,esi
		invoke SendDlgItemMessage,hWin,IDC_EDTRCDNAME,EM_LIMITTEXT,MaxName-1,0
		invoke SetDlgItemText,hWin,IDC_EDTRCDNAME,addr [edi].RCDATAMEM.szname
		invoke SendDlgItemMessage,hWin,IDC_EDTRCDID,EM_LIMITTEXT,5,0
		invoke SetDlgItemInt,hWin,IDC_EDTRCDID,[edi].RCDATAMEM.value,TRUE
		invoke SetDlgItemText,hWin,IDC_EDTRCDATA,addr [edi+sizeof RCDATAMEM]
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
					invoke SendMessage,hRes,PRO_ADDITEM,TPE_RCDATA,FALSE
				.endif
				mov		[eax].PROJECT.changed,TRUE
				mov		esi,[eax].PROJECT.hmem
				invoke GetDlgItemText,hWin,IDC_EDTRCDNAME,addr [esi].RCDATAMEM.szname,MaxName
				invoke GetDlgItemInt,hWin,IDC_EDTRCDID,NULL,FALSE
				mov		[esi].RCDATAMEM.value,eax
				invoke GetDlgItemText,hWin,IDC_EDTRCDATA,addr [esi+sizeof RCDATAMEM],64*1024
				invoke GetWindowLong,hWin,GWL_USERDATA
				mov		edi,eax
				invoke GetProjectItemName,edi,addr buffer
				invoke SetProjectItemName,edi,addr buffer
				invoke SendMessage,hWin,WM_CLOSE,NULL,TRUE
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

RCDataEditProc endp
