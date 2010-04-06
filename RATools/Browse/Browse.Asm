.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Browse.inc

.code

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax
	invoke LoadLibrary,addr szRATools
	mov		hLib,eax
    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke FreeLibrary,hLib
	invoke ExitProcess,0

;########################################################################

DlgProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	pt:POINT
	LOCAL	dck:DOCKING

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_TOOL
		mov		hTool,eax
		invoke SendMessage,hTool,TLM_INIT,0,hWin
		mov		dck.ID,1
		mov		dck.Caption,offset szRATools
		mov		dck.Visible,TRUE
		mov		dck.Docked,TRUE
		mov		dck.Position,TL_RIGHT
		mov		dck.IsChild,FALSE
		mov		dck.DockWidth,150
		mov		dck.DockHeight,100
		mov		dck.FloatRect.left,0
		mov		dck.FloatRect.top,0
		mov		dck.FloatRect.right,200
		mov		dck.FloatRect.bottom,300
		invoke SendMessage,hTool,TLM_CREATE,0,addr dck
		mov		hTL1,eax
		invoke SendMessage,hTool,TLM_CAPTION,0,0
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==1002
				invoke SendMessage,hTool,TLM_DOCKING,0,hTL1
			.endif
		.endif
	.elseif eax==WM_NOTIFY
	.elseif eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		invoke SendMessage,hTool,TLM_SIZE,0,addr rect
		invoke SendMessage,hTool,TLM_CAPTION,0,0
;		invoke MoveWindow,hTool,0,0,rect.right,rect.bottom,TRUE
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
