IDD_TOOLBAR						equ 2600
IDC_EDTTOOLBAR					equ 1003
;IDC_EDTTBRID					equ 1002
;IDC_EDTTBRNAME					equ 1001
;IDC_EDTTBRWIDTH					equ 1004
;IDC_EDTTBRHEIGHT				equ 1006

.data

szToolbarName		db 'IDR_TOOLBAR',0
deftoolbar			TOOLBARMEM	<,1,16,15>
					db 0

.code

ExportToolbarNames proc uses esi edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*16
	mov     edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	;#define
    .if [esi].TOOLBARMEM.szname && [esi].TOOLBARMEM.value
		invoke SaveStr,edi,addr szDEFINE
		add		edi,eax
		mov		al,' '
		stosb
		invoke SaveStr,edi,addr [esi].TOOLBARMEM.szname
		add		edi,eax
		mov		al,' '
		stosb
		invoke ResEdBinToDec,[esi].TOOLBARMEM.value,edi
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

ExportToolbarNames endp

ExportToolbar proc uses esi edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16*1024
	mov		edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	;Name or ID
    .if [esi].TOOLBARMEM.szname
    	invoke strcpy,edi,addr [esi].TOOLBARMEM.szname
	.else
		invoke ResEdBinToDec,[esi].TOOLBARMEM.value,edi
	.endif
	invoke strlen,edi
	add		edi,eax
	mov		al,' '
	stosb
   	invoke strcpy,edi,offset szTOOLBAR
	invoke strlen,edi
	add		edi,eax
	mov		al,' '
	stosb
	invoke ResEdBinToDec,[esi].TOOLBARMEM.ccx,edi
	invoke strlen,edi
	add		edi,eax
	mov		al,','
	stosb
	invoke ResEdBinToDec,[esi].TOOLBARMEM.ccy,edi
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
	lea		edx,[esi+sizeof TOOLBARMEM]
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

ExportToolbar endp

ToolbarEditProc proc uses esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[256]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		esi,lParam
		.if [esi].PROJECT.hmem
			mov		edi,[esi].PROJECT.hmem
		.else
			invoke GetFreeProjectitemID,TPE_TOOLBAR
			mov		edi,offset deftoolbar
			mov		[edi].TOOLBARMEM.value,eax
			invoke strcpy,addr [edi].TOOLBARMEM.szname,addr szToolbarName
			invoke GetUnikeName,addr [edi].TOOLBARMEM.szname
		.endif
		invoke SetWindowLong,hWin,GWL_USERDATA,esi
;		invoke SendDlgItemMessage,hWin,IDC_EDTTBRNAME,EM_LIMITTEXT,MaxName-1,0
;		invoke SetDlgItemText,hWin,IDC_EDTTBRNAME,addr [edi].TOOLBARMEM.szname
;		invoke SendDlgItemMessage,hWin,IDC_EDTTBRID,EM_LIMITTEXT,5,0
;		invoke SetDlgItemInt,hWin,IDC_EDTTBRID,[edi].TOOLBARMEM.value,TRUE
mov		lpResType,offset szTOOLBAR
lea		eax,[edi].TOOLBARMEM.szname
mov		lpResName,eax
lea		eax,[edi].TOOLBARMEM.value
mov		lpResID,eax
lea		eax,[edi].TOOLBARMEM.ccx
mov		lpResWidth,eax
lea		eax,[edi].TOOLBARMEM.ccy
mov		lpResHeight,eax
;		invoke SendDlgItemMessage,hWin,IDC_EDTTBRWIDTH,EM_LIMITTEXT,3,0
;		invoke SetDlgItemInt,hWin,IDC_EDTTBRWIDTH,[edi].TOOLBARMEM.ccx,TRUE
;		invoke SendDlgItemMessage,hWin,IDC_EDTTBRHEIGHT,EM_LIMITTEXT,3,0
;		invoke SetDlgItemInt,hWin,IDC_EDTTBRHEIGHT,[edi].TOOLBARMEM.ccy,TRUE
		invoke SetDlgItemText,hWin,IDC_EDTTOOLBAR,addr [edi+sizeof TOOLBARMEM]
		invoke PropertyList,-6
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
					invoke SendMessage,hRes,PRO_ADDITEM,TPE_TOOLBAR,FALSE
				.endif
				mov		[eax].PROJECT.changed,TRUE
				mov		esi,[eax].PROJECT.hmem
;				invoke GetDlgItemText,hWin,IDC_EDTRCDNAME,addr [esi].TOOLBARMEM.szname,MaxName
;				invoke GetDlgItemInt,hWin,IDC_EDTTBRID,NULL,FALSE
;				mov		[esi].TOOLBARMEM.value,eax
;				invoke GetDlgItemInt,hWin,IDC_EDTTBRWIDTH,NULL,FALSE
;				mov		[esi].TOOLBARMEM.ccx,eax
;				invoke GetDlgItemInt,hWin,IDC_EDTTBRHEIGHT,NULL,FALSE
;				mov		[esi].TOOLBARMEM.ccy,eax
				invoke GetDlgItemText,hWin,IDC_EDTTOOLBAR,addr [esi+sizeof TOOLBARMEM],64*1024
				invoke GetWindowLong,hWin,GWL_USERDATA
				mov		edi,eax
				invoke GetProjectItemName,edi,addr buffer
				invoke SetProjectItemName,edi,addr buffer
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

ToolbarEditProc endp
