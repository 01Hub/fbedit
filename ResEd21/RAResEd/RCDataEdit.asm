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
		invoke strlen,edi
		lea		edi,[edi+eax]
		mov		al,0Dh
		stosb
		mov		al,0Ah
		stosb
	.endif
;	mov		ax,0A0Dh
;	stosw
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
    	invoke strcpy,edi,addr [esi].RCDATAMEM.szname
	.else
		invoke ResEdBinToDec,[esi].RCDATAMEM.value,edi
	.endif
	invoke strlen,edi
	add		edi,eax
	mov		al,' '
	stosb
   	invoke strcpy,edi,offset szRCDATA
	invoke strlen,edi
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

SaveRCDataEdit proc uses ebx esi edi, hWin:HWND
	LOCAL	buffer[256]:BYTE

	invoke GetWindowLong,hWin,GWL_USERDATA
	mov		ebx,eax
	.if !ebx
		invoke SendMessage,hRes,PRO_ADDITEM,TPE_RCDATA,FALSE
		mov		ebx,eax
		invoke RtlMoveMemory,[ebx].PROJECT.hmem,offset defrcdata,sizeof RCDATAMEM+1
	.endif
	push	ebx
	mov		esi,[ebx].PROJECT.hmem
	invoke GetDlgItemText,hWin,IDC_EDTRCDATA,addr [esi+sizeof RCDATAMEM],64*1024
	invoke GetProjectItemName,ebx,addr buffer
	invoke SetProjectItemName,ebx,addr buffer
	pop		eax
	ret

SaveRCDataEdit endp

RCDataEditProc proc uses esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		esi,lParam
		invoke SetWindowLong,hWin,GWL_USERDATA,esi
		.if !esi
			mov		edi,offset defrcdata
			invoke GetFreeProjectitemID,TPE_RCDATA
			mov		[edi].RCDATAMEM.value,eax
			invoke strcpy,addr [edi].RCDATAMEM.szname,addr szRcdataName
			invoke GetUnikeName,addr [edi].RCDATAMEM.szname
			invoke SaveRCDataEdit,hWin
			mov		esi,eax
			invoke SetWindowLong,hWin,GWL_USERDATA,esi
		.endif
		mov		edi,[esi].PROJECT.hmem
		mov		lpResType,offset szRCDATA
		lea		eax,[edi].RCDATAMEM.szname
		mov		lpResName,eax
		lea		eax,[edi].RCDATAMEM.value
		mov		lpResID,eax
		invoke SetDlgItemText,hWin,IDC_EDTRCDATA,addr [edi+sizeof RCDATAMEM]
		invoke PropertyList,-2
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke SaveRCDataEdit,hWin
				invoke SendMessage,hRes,PRO_SETMODIFY,TRUE,0
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
				invoke PropertyList,0
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
