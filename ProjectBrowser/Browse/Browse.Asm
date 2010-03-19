.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Browse.inc

.code

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax
	invoke LoadLibrary,addr szRAProject
	mov		hLib,eax
    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke FreeLibrary,hLib
	invoke ExitProcess,0

;########################################################################

DlgProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
;PrintText "WM_INITDIALOG"
		invoke GetDlgItem,hWin,IDC_RAP
		mov		hPbr,eax
		invoke SendMessage,hPbr,RPBM_SETPATH,0,addr pbpath
		;Clear PBFILEEXT array
		invoke SendMessage,hPbr,RPBM_ADDFILEEXT,0,0
		mov		esi,offset pbfileext
		xor		edi,edi
		.while [esi].PBFILEEXT.id
			invoke SendMessage,hPbr,RPBM_ADDFILEEXT,edi,esi
			inc		edi
			lea		esi,[esi+sizeof PBFILEEXT]
		.endw
		;Clear PBITEM array
		invoke SendMessage,hPbr,RPBM_ADDITEM,0,0
		mov		esi,offset pbitems
		xor		edi,edi
		.while [esi].PBITEM.id
			invoke SendMessage,hPbr,RPBM_ADDITEM,edi,esi
			inc		edi
			lea		esi,[esi+sizeof PBITEM]
		.endw
		invoke SendMessage,hPbr,RPBM_SETGROUPING,TRUE,RPBG_GROUPS
;PrintText "WM_INITDIALOG"
	.elseif eax==WM_COMMAND

	.elseif eax==WM_NOTIFY
		mov		esi,lParam
		mov		eax,[esi].NMHDR.hwndFrom
		.if eax==hPbr
			mov		eax,[esi].NMHDR.code
			.if eax==RPBN_DBLCLICK
				mov		esi,[esi].PBNOTIFY.lpPBITEM
lea		eax,[esi].PBITEM.szitem
PrintStringByAddr eax
			.endif
		.endif
	.elseif eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,hPbr,0,0,rect.right,rect.bottom,TRUE
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

end start
