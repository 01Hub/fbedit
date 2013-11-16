.386
.model flat,stdcall
option casemap:none

include x86_BlueTooth.inc

.code

EditProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	data:DWORD

	mov		eax,uMsg
	.if eax==WM_CHAR
		mov		eax,wParam
		.if (eax>=20h && eax<=7Fh) || eax==0Dh
			or		eax,00010000h
			mov		data,eax
			invoke STLinkWrite,hWnd,STM32_Data,addr data,4
		.endif
	.endif
	invoke CallWindowProc,lpOldEditProc,hWin,uMsg,wParam,lParam
	ret

EditProc endp

WndProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	status:DWORD
	LOCAL	head:DWORD
	LOCAL	buffer[256]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
		invoke STLinkConnect,hWin
		.if eax==IDABORT
			invoke SendMessage,hWin,WM_CLOSE,0,0
		.else
			mov		fSTLink,eax
			.if fSTLink && fSTLink!=IDIGNORE
				;invoke STLinkReset,hWnd
			.endif
		.endif
		invoke GetDlgItem,hWin,IDC_EDTSEND
		invoke SetWindowLong,eax,GWL_WNDPROC,offset EditProc
		mov		lpOldEditProc,eax
		invoke SetTimer,hWin,1000,50,NULL
	.elseif eax==WM_TIMER
		invoke STLinkRead,hWin,STM32_Data+4,addr status,4
		invoke SetDlgItemInt,hWin,IDC_STCBYTESSENDT,status,FALSE
		invoke STLinkRead,hWin,STM32_Data+8,addr status,4
		invoke SetDlgItemInt,hWin,IDC_STCBYTESREC,status,FALSE
		invoke STLinkRead,hWin,STM32_Data+16,addr head,4
		mov		ebx,tail
		mov		edi,STM32_Data+20
		.while ebx!=head
			lea		esi,[edi+ebx]
			and		esi,0FFFFFFFCh
			invoke STLinkRead,hWin,esi,addr buffer,4
			mov		edx,ebx
			and		edx,03h
			movzx	eax,buffer[edx]
			.if eax==0Dh
				mov		ah,0Ah
			.endif
			mov		dword ptr buffer,eax
			invoke SendDlgItemMessage,hWin,IDC_EDTRECEIVE,EM_REPLACESEL,FALSE,addr buffer
			inc		ebx
			and		ebx,01FFh
		.endw
		mov		tail,ebx
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax==IDM_FILE_TEST
invoke STLinkRead,hWin,STM32_Data,addr status,4
mov eax,status
PrintHex eax
invoke STLinkRead,hWin,STM32_Data+4,addr status,4
mov eax,status
PrintHex eax
invoke STLinkRead,hWin,STM32_Data+8,addr status,4
mov eax,status
PrintHex eax
invoke STLinkRead,hWin,STM32_Data+12,addr status,4
mov eax,status
PrintHex eax
invoke STLinkRead,hWin,STM32_Data+16,addr status,4
mov eax,status
PrintHex eax
			.elseif eax==IDM_HELP_ABOUT
				invoke ShellAbout,hWin,addr AppName,addr AboutMsg,NULL
			.endif
		.endif
;	.elseif eax==WM_SIZE
	.elseif eax==WM_CLOSE
		.if fSTLink && fSTLink!=IDIGNORE
			invoke STLinkDisconnect,hWnd
		.endif
		invoke KillTimer,hWin,1000
		invoke DestroyWindow,hWin
	.elseif uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

WndProc endp

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,IDM_MENU
	mov		wc.lpszClassName,offset ClassName
	invoke LoadIcon,NULL,IDI_APPLICATION
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_DIALOG,NULL,addr WndProc,NULL
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke TranslateMessage,addr msg
		invoke DispatchMessage,addr msg
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke GetCommandLine
	invoke InitCommonControls
	mov		CommandLine,eax
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke ExitProcess,eax

end start
