.386
.model flat,stdcall
option casemap:none

include Data.inc
include ..\RATools.inc
include Tools.asm

.code

InstallRATools proc public hInst:HINSTANCE,fGlobal:DWORD
	LOCAL	wc:WNDCLASSEX

	;Create a windowclass for the user control
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
	.if fGlobal
		mov		wc.style,CS_HREDRAW or CS_VREDRAW or CS_GLOBALCLASS or CS_DBLCLKS
	.endif
	mov		wc.lpfnWndProc,offset ControlProc
	mov		eax,hInst
	mov		hInstance,eax
	mov		wc.hInstance,eax
	mov		eax,NULL
	mov		wc.cbClsExtra,eax
	mov		wc.cbWndExtra,4
	mov		wc.hbrBackground,eax
	mov		wc.lpszMenuName,eax
	mov		wc.lpszClassName,offset szToolClassName
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc

	;Tool windows
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset ToolWndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,NULL
	mov		eax,hInst
	mov		wc.hInstance,eax
	mov		wc.hbrBackground,NULL
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szToolClass
	mov		wc.hIcon,NULL
	mov		wc.hIconSm,NULL
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	;Tool child windows
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset ToolCldProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,NULL
	m2m		wc.hInstance,hInst
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szToolCldClass
	mov		wc.hIcon,NULL
	mov		wc.hIconSm,NULL
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	ret

InstallRATools endp

UnInstallRATools proc public

	ret

UnInstallRATools endp

;--------------------------------------------------------------------------------

ControlProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hTL:HWND

	mov		eax,uMsg
	.if eax==WM_CREATE
	.elseif eax==TLM_INIT
		mov		eax,lParam
		mov		hWnd,eax
		invoke ToolMessage,0,TLM_INIT,0
	.elseif eax==TLM_CREATE
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,addr szToolCldClass,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,hWnd,0,hInstance,0
		mov		hTL,eax
	    invoke ToolMessage,hTL,TLM_CREATE,lParam
    	mov     eax,hTL
    	jmp		Ex
	.elseif eax==TLM_DOCKING
	    invoke ToolMessage,lParam,TLM_DOCKING,0
	.elseif eax==TLM_HIDE
	.elseif eax==TLM_MOUSEMOVE
	.elseif eax==TLM_LBUTTONDOWN
	.elseif eax==TLM_LBUTTONUP
	.elseif eax==TLM_PAINT
	.elseif eax==TLM_SIZE
		invoke ToolMessage,0,TLM_SIZE,lParam
	.elseif eax==TLM_REDRAW
	.elseif eax==TLM_CAPTION
		invoke ToolMsgAll,TLM_CAPTION,0,0
	.elseif eax==TLM_ADJUSTRECT
	.elseif eax==TLM_GET_VISIBLE
	.elseif eax==TLM_GET_STRUCT
	.elseif eax==TLM_SETTBR
	.elseif eax==TLM_GET_DOCKED
	.elseif eax==TLM_MOVETEST
	.endif
	invoke DefWindowProc,hWin,uMsg,wParam,lParam
  Ex:
	ret

ControlProc endp


IFDEF DLL
	include RAToolsDll.asm
ENDIF

end
