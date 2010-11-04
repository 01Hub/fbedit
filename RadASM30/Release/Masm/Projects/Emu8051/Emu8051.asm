.386
.model flat,stdcall
option casemap:none

include Emu8051.inc
include Misc.asm
include Terminal.asm
include RS232.asm

.code

MakeToolBar proc uses ebx,hTbr:HWND,lpBtn:DWORD,nBtn:DWORD
	LOCAL	tbab:TBADDBITMAP

	mov		ebx,hTbr
	;Set toolbar struct size
	invoke SendMessage,ebx,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0
	;Set toolbar bitmap
	mov		tbab.hInst,HINST_COMMCTRL
	mov		tbab.nID,IDB_STD_SMALL_COLOR
	invoke SendMessage,ebx,TB_ADDBITMAP,15,addr tbab
	;Set toolbar buttons
	invoke SendMessage,ebx,TB_ADDBUTTONS,nBtn,lpBtn
	mov		eax,ebx
	ret

MakeToolBar endp

WndProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	tid:DWORD
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	msg:MSG
	LOCAL	sbParts[4]:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
		invoke GetDlgItem,hWin,IDC_TBR1
		invoke MakeToolBar,eax,offset tbrbtnsfile,ntbrbtns
		invoke GetDlgItem,hWin,IDC_SCREEN
		mov		hScrn,eax
		invoke GetDlgItem,hWin,IDC_RAE1
		mov		hREd,eax
		invoke CreateFontIndirect,addr Courier_New_12
		mov		hFont,eax
		invoke SendMessage,hScrn,WM_SETFONT,hFont,FALSE
		invoke SetWindowLong,hScrn,GWL_WNDPROC,addr ScreenProc
		mov		lpOldScreenProc,eax
		invoke SendMessage,hREd,WM_SETFONT,hFont,FALSE
		invoke SendMessage,hREd,REM_READONLY,0,TRUE
		invoke ScreenCls
		invoke CreateCaret,hScrn,NULL,BOXWT,BOXHT
		invoke ShowCaret,hScrn
		invoke InitCom
		invoke OpenCom
		.if hCom
			invoke CreateThread,NULL,0,addr DoComm,0,0,addr tid
			mov		hThreadRD,eax
			invoke WriteCom,0Dh
			invoke SetTimer,hWin,1000,10,NULL
		.endif
		mov [sbParts+0],200				; pixels from left
		mov [sbParts+4],400				; pixels from left
		mov [sbParts+8],450				; pixels from left
		mov [sbParts+12],-1				; last part
		invoke SendDlgItemMessage,hWin,IDC_SBR1,SB_SETPARTS,4,addr sbParts
		invoke lstrlen,addr szcmdfilename
		.while sdword ptr eax>=0 && byte ptr szcmdfilename[eax]!='\'
			dec		eax
		.endw
		invoke SendDlgItemMessage,hWin,IDC_SBR1,SB_SETTEXT,0,addr szcmdfilename[eax+1]
		invoke lstrlen,addr szcmdfilename
		.while sdword ptr eax>=0 && byte ptr szromfilename[eax]!='\'
			dec		eax
		.endw
		invoke SendDlgItemMessage,hWin,IDC_SBR1,SB_SETTEXT,1,addr szromfilename[eax+1]
	.elseif eax==WM_TIMER
		.while TRUE
			mov		edx,rdtail
			.break .if edx==rdhead
			movzx	eax,rdbuff[edx]
			inc		edx
			and		edx,sizeof rdbuff-1
			mov		rdtail,edx
			invoke ScreenOut,eax
		.endw
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		and		eax,0FFFFh
		.if eax==IDM_FILE_EXIT
			invoke SendMessage,hWin,WM_CLOSE,0,0
		.elseif eax==IDM_FILE_OPEN
			invoke RtlZeroMemory,addr ofn,sizeof OPENFILENAME
			;Setup the ofn struct
			mov		ofn.lStructSize,sizeof ofn
			push	hWnd
			pop		ofn.hwndOwner
			push	hInstance
			pop		ofn.hInstance
			mov		ofn.lpstrFilter,offset szANYString
			.if !fDebug
				invoke lstrcpy,addr buffer,addr szcmdfilename
			.else
				invoke lstrcpy,addr buffer,addr szlstfilename
			.endif
			lea		eax,buffer
			mov		ofn.lpstrFile,eax
			mov		ofn.nMaxFile,sizeof buffer
			mov		ofn.lpstrDefExt,NULL
			mov		ofn.lpstrInitialDir,0
			mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
			;Show the Open dialog
			invoke GetOpenFileName,addr ofn
			.if eax
				.if !fDebug
					invoke lstrcpy,addr szcmdfilename,addr buffer
					movzx	eax,ofn.nFileOffset
					invoke SendDlgItemMessage,hWin,IDC_SBR1,SB_SETTEXT,0,addr szcmdfilename[eax]
				.else
					invoke lstrcpy,addr szlstfilename,addr buffer
				.endif
			.endif
			.if !fDebug
				invoke SetFocus,hWin
				invoke CreateCaret,hScrn,NULL,BOXWT,BOXHT
				invoke ScreenCaret
				invoke ShowCaret,hScrn
			.else
				invoke LoadLstFile
				invoke SetFocus,hREd
			.endif
		.elseif eax==IDM_FILE_SAVE
			invoke RtlZeroMemory,addr ofn,sizeof OPENFILENAME
			invoke RtlZeroMemory,addr ofn,sizeof OPENFILENAME
			;Setup the ofn struct
			mov		ofn.lStructSize,sizeof ofn
			push	hWnd
			pop		ofn.hwndOwner
			push	hInstance
			pop		ofn.hInstance
			mov		ofn.lpstrFilter,offset szANYString
			invoke lstrcpy,addr buffer,addr szromfilename
			lea		eax,buffer
			mov		ofn.lpstrFile,eax
			mov		ofn.nMaxFile,sizeof buffer
			mov		ofn.lpstrDefExt,NULL
			mov		ofn.lpstrInitialDir,0
			mov		ofn.Flags,OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
			;Show the Save dialog
			invoke GetSaveFileName,addr ofn
			.if eax
				invoke lstrcpy,addr szromfilename,addr buffer
				movzx	eax,ofn.nFileOffset
				invoke SendDlgItemMessage,hWin,IDC_SBR1,SB_SETTEXT,1,addr szromfilename[eax]
			.endif
			invoke SetFocus,hWin
			invoke CreateCaret,hScrn,NULL,BOXWT,BOXHT
			invoke ScreenCaret
			invoke ShowCaret,hScrn
		.elseif eax==IDM_FILE_PRINT
		.elseif eax==IDM_FILE_GO
			invoke WriteCom,'L'
			invoke WriteCom,0Dh
			mov		ebx,100
			.while ebx
				invoke GetMessage,addr msg,NULL,0,0
			  .break .if !eax
				invoke TranslateMessage,addr msg
				invoke DispatchMessage,addr msg
				dec		ebx
			.endw
			.while TRUE
				mov		ebx,100
				.while ebx
					invoke GetMessage,addr msg,NULL,0,0
				  .break .if !eax
					invoke TranslateMessage,addr msg
					invoke DispatchMessage,addr msg
					dec		ebx
				.endw
				mov		edx,wrtail
			  .break .if edx==wrhead
			.endw
			invoke WriteCom,'G'
		.elseif eax==IDM_FILE_INITCOM
			.if hCom
				invoke CloseHandle,hCom
				mov		hCom,0
			.endif
			invoke OpenCom
			.if hCom
				invoke ScreenCls
				invoke WriteCom,0Dh
			.endif
		.elseif eax==IDM_OPTION_COMPORT
			invoke DialogBoxParam,hInstance,IDD_DLGCOMPORT,hWin,addr ComOptionProc,0
		.elseif eax==IDM_FILE_DEBUG
			.if fDebug
				invoke ShowWindow,hScrn,SW_SHOW
				invoke ShowWindow,hREd,SW_HIDE
				invoke CreateCaret,hScrn,NULL,BOXWT,BOXHT
				invoke ShowCaret,hScrn
			.else
				invoke HideCaret,hScrn
				invoke ShowWindow,hREd,SW_SHOW
				invoke ShowWindow,hScrn,SW_HIDE
				invoke SetFocus,hREd
			.endif
			xor		fDebug,1
		.endif
	.elseif eax==WM_CHAR
		.if hCom && !hrdfile && !fDebug
			mov		eax,wParam
			.if eax==1Bh
				;Esc
				mov		eax,9Fh
			.endif
			invoke WriteCom,eax
		.endif
	.elseif eax==WM_KEYDOWN
		.if hCom && !hrdfile && !fDebug
			mov		eax,wParam
			.if eax==VK_RIGHT
				invoke WriteCom,9Ch
			.elseif eax==VK_LEFT
				invoke WriteCom,9Dh
			.elseif eax==VK_DOWN
				invoke WriteCom,9Bh
			.elseif eax==VK_UP
				invoke WriteCom,9Ah
			.elseif eax==VK_INSERT
				invoke WriteCom,94h
			.endif
		.endif
	.elseif eax==WM_SIZE
		invoke MoveWindow,hScrn,0,28,80*BOXWT+4,24*BOXHT+4,TRUE
		invoke MoveWindow,hREd,0,28,80*BOXWT+4,24*BOXHT+4,TRUE
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
	.elseif uMsg==WM_DESTROY
		.if hCom
			mov		fExit,TRUE
			invoke WaitForSingleObject,hThreadRD,3000
			invoke CloseHandle,hThreadRD
			invoke CloseHandle,hCom
			mov		hCom,0
		.endif
		invoke DeleteObject,hFont
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
	invoke InitCommonControls
	invoke InstallRAEdit,hInstance,FALSE
	invoke GetCommandLine
	mov		CommandLine,eax
	;Get command line filename
	invoke PathGetArgs,CommandLine
	mov		CommandLine,eax
	.if byte ptr [eax]
		invoke lstrcpy,addr szcmdfilename,CommandLine
	.else
		invoke lstrcpy,addr szcmdfilename,addr szDefCmdData
	.endif
	invoke lstrcpy,addr szromfilename,addr szDefRomData
	invoke GetModuleFileName,hInstance,addr szapppath,sizeof szapppath
	.while szapppath[eax]!='\' && eax
		dec		eax
	.endw
	mov		szapppath[eax],0
	invoke lstrcpy,addr szinifile,addr szapppath
	invoke lstrcat,addr szinifile,addr szIniFile
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke UnInstallRAEdit
	invoke ExitProcess,eax

end start
