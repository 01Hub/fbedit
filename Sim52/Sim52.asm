.386
.model flat,stdcall
option casemap:none

include Sim52.inc
include Sim52Core.asm
include Sim52Parse.asm

.code

DoToolBar proc hInst:DWORD,hToolBar:HWND
	LOCAL	tbab:TBADDBITMAP

	;Set toolbar struct size
	invoke SendMessage,hToolBar,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0
	;Set toolbar bitmap
	push	hInst
	pop		tbab.hInst
	mov		tbab.nID,IDB_TBRBMP
	invoke SendMessage,hToolBar,TB_ADDBITMAP,9,addr tbab
	;Set toolbar buttons
	invoke SendMessage,hToolBar,TB_ADDBUTTONS,ntbrbtns,addr tbrbtns
	mov		eax,hToolBar
	ret

DoToolBar endp

EnableDisable proc uses ebx

	push	0
	push	IDM_SEARCH_FIND
	push	IDM_DEBUG_RUN
	push	IDM_DEBUG_PAUSE
	push	IDM_DEBUG_STOP
	push	IDM_DEBUG_STEP_INTO
	push	IDM_DEBUG_STEP_OVER
	push	IDM_DEBUG_RUN_TO_CURSOR
	push	IDM_DEBUG_TOGGLE
	push	IDM_DEBUG_CLEAR
	invoke SendDlgItemMessage,hWnd,IDC_LSTCODE,LB_GETCOUNT,0,0
	mov		ebx,eax
	.if eax
		mov		ebx,TRUE
	.endif
	pop		eax
	.while eax
		invoke SendDlgItemMessage,hWnd,IDC_TBRSIM52,TB_ENABLEBUTTON,eax,ebx
		pop		eax
	.endw
	ret
	
EnableDisable endp

TabRamProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabRamProc endp

TabBitProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabBitProc endp

WndProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	tci:TC_ITEM
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	tid:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		invoke GetDlgItem,hWin,IDC_TBRSIM52
		invoke DoToolBar,hInstance,eax
		; Create font and set it to list box
		invoke CreateFontIndirect,addr Courier_New_9
		mov		hLstFont,eax
		invoke SendDlgItemMessage,hWin,IDC_LSTCODE,WM_SETFONT,hLstFont,FALSE
		invoke EnableDisable
		invoke GetMenu,hWin
		mov		hMenu,eax
		mov		tci.imask,TCIF_TEXT
		mov		tci.lpReserved1,0
		mov		tci.lpReserved2,0
		mov		tci.iImage,-1
		mov		tci.lParam,0
		mov		tci.pszText,offset szTabStatus
		invoke SendDlgItemMessage,hWin,IDC_TABSIM52,TCM_INSERTITEM,0,addr tci

		mov		tci.pszText,offset szTabRam
		invoke SendDlgItemMessage,hWin,IDC_TABVIEW,TCM_INSERTITEM,0,addr tci
		mov		tci.pszText,offset szTabBit
		invoke SendDlgItemMessage,hWin,IDC_TABVIEW,TCM_INSERTITEM,1,addr tci
		mov		tci.pszText,offset szTabSfr
		invoke SendDlgItemMessage,hWin,IDC_TABVIEW,TCM_INSERTITEM,2,addr tci
		mov		tci.pszText,offset szTabXRam
		invoke SendDlgItemMessage,hWin,IDC_TABVIEW,TCM_INSERTITEM,3,addr tci
		mov		tci.pszText,offset szTabCode
		invoke SendDlgItemMessage,hWin,IDC_TABVIEW,TCM_INSERTITEM,4,addr tci

		invoke GetDlgItem,hWin,IDC_TABVIEW
		mov		ebx,eax
		;Create the tab dialogs
		invoke CreateDialogParam,hInstance,IDD_DLGTABRAM,ebx,addr TabRamProc,0
		mov		hTabDlg[0],eax
		invoke CreateDialogParam,hInstance,IDD_DLGTABBIT,ebx,addr TabBitProc,0
		mov		hTabDlg[4],eax
		invoke CreateDialogParam,hInstance,IDD_DLGTABSFR,ebx,addr TabBitProc,0
		mov		hTabDlg[8],eax
		invoke CreateDialogParam,hInstance,IDD_DLGTABXRAM,ebx,addr TabBitProc,0
		mov		hTabDlg[12],eax
		invoke CreateDialogParam,hInstance,IDD_DLGTABCODE,ebx,addr TabBitProc,0
		mov		hTabDlg[16],eax

		invoke LoadBitmap,hInstance,IDB_LEDGRAY
		mov		hBmpGrayLed,eax
		invoke LoadBitmap,hInstance,IDB_LEDGREEN
		mov		hBmpGreenLed,eax
		invoke LoadBitmap,hInstance,IDB_LEDRED
		mov		hBmpRedLed,eax
		invoke Reset
		invoke UpdateStatus
		invoke UpdatePorts
		invoke UpdateRegisters
		invoke SetTimer,hWin,1000,200,NULL
	.elseif eax==WM_TIMER
		.if Refresh
			invoke UpdateStatus
			invoke UpdatePorts
			invoke UpdateRegisters
			dec		Refresh
		.endif
	.elseif eax==WM_NOTIFY
		mov		eax,wParam
		.if eax==IDC_UDNBANK
			mov		eax,lParam
			mov		eax,[eax].NM_UPDOWN.iDelta
			neg		eax
			add		eax,ViewBank
			and		eax,3
			mov		ViewBank,eax
			invoke wsprintf,addr buffer,addr szFmtBank,eax
			invoke SetDlgItemText,hWin,IDC_STCBANK,addr buffer
			invoke UpdateRegisters
		.elseif eax==IDC_TABVIEW
			mov		eax,lParam
			mov		eax,[eax].NMHDR.code
			.if eax==TCN_SELCHANGE
				;Tab selection
				invoke SendDlgItemMessage,hWin,IDC_TABVIEW,TCM_GETCURSEL,0,0
				.if eax!=SelTab
					push	eax
					mov		eax,SelTab
					invoke ShowWindow,[hTabDlg+eax*4],SW_HIDE
					pop		eax
					mov		SelTab,eax
					invoke ShowWindow,[hTabDlg+eax*4],SW_SHOWDEFAULT
				.endif
			.endif
		.endif
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax==IDM_FILE_OPEN
				;Zero out the ofn struct
				invoke RtlZeroMemory,addr ofn,sizeof ofn
				;Setup the ofn struct
				mov		ofn.lStructSize,sizeof ofn
				push	hWin
				pop		ofn.hwndOwner
				push	hInstance
				pop		ofn.hInstance
				mov		ofn.lpstrFilter,offset szLSTFilterString
				mov		buffer[0],0
				lea		eax,buffer
				mov		ofn.lpstrFile,eax
				mov		ofn.nMaxFile,sizeof buffer
				mov		ofn.lpstrDefExt,NULL
				mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
				;Show the Open dialog
				invoke GetOpenFileName,addr ofn
				.if eax
					invoke ParseList,addr buffer
					invoke EnableDisable
				.endif
			.elseif eax==IDM_SEARCH_FIND
			.elseif eax==IDM_VIEW_TERMINAL
			.elseif eax==IDM_DEBUG_RUN
				.if State & STATE_THREAD
					mov		State,STATE_THREAD or STATE_RUN
				.else
					mov		State,STATE_THREAD or STATE_RUN
					invoke CreateThread,NULL,0,addr CoreThread,0,0,addr tid
					invoke CloseHandle,eax
				.endif
			.elseif eax==IDM_DEBUG_PAUSE
				.if State & STATE_THREAD
					or		State,STATE_PAUSE
				.endif
			.elseif eax==IDM_DEBUG_STOP
				mov		State,STATE_STOP
			.elseif eax==IDM_DEBUG_STEP_INTO
				.if State & STATE_THREAD
					or		State,STATE_STEP_INTO
				.else
					mov		State,STATE_THREAD or STATE_RUN or STATE_PAUSE or STATE_STEP_INTO
					invoke CreateThread,NULL,0,addr CoreThread,0,0,addr tid
					invoke CloseHandle,eax
				.endif
			.elseif eax==IDM_DEBUG_STEP_OVER
				.if State & STATE_THREAD
					or		State,STATE_STEP_OVER
				.else
					mov		State,STATE_THREAD or STATE_RUN or STATE_PAUSE or STATE_STEP_OVER
					invoke CreateThread,NULL,0,addr CoreThread,0,0,addr tid
					invoke CloseHandle,eax
				.endif
			.elseif eax==IDM_DEBUG_RUN_TO_CURSOR
				invoke SendDlgItemMessage,hWin,IDC_LSTCODE,LB_GETCURSEL,0,0
				.if eax!=LB_ERR
					invoke SendDlgItemMessage,hWin,IDC_LSTCODE,LB_GETITEMDATA,eax,0
					mov		CursorAddr,eax
					.if State & STATE_THREAD
						or		State,STATE_RUN_TO_CURSOR
					.else
						mov		State,STATE_THREAD or STATE_RUN or STATE_PAUSE or STATE_RUN_TO_CURSOR
						invoke CreateThread,NULL,0,addr CoreThread,0,0,addr tid
						invoke CloseHandle,eax
					.endif
				.endif
			.elseif eax==IDM_DEBUG_TOGGLE
			.elseif eax==IDM_DEBUG_CLEAR
			.elseif eax==IDM_HELP_ABOUT
				invoke ShellAbout,hWin,addr AppName,addr AboutMsg,NULL
			.elseif eax>=IDC_IMGP && eax<=IDC_IMGCY
				;PSW
				sub		eax,IDC_IMGP
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr(SFR_PSW),al
				invoke UpdateStatus
			.elseif eax>=IDC_IMGP0_0 && eax<=IDC_IMGP0_7
				;P0
				sub		eax,IDC_IMGP0_0
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr(SFR_P0),al
				invoke UpdatePorts
			.elseif eax>=IDC_IMGP1_0 && eax<=IDC_IMGP1_7
				;P1
				sub		eax,IDC_IMGP1_0
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr(SFR_P1),al
				invoke UpdatePorts
			.elseif eax>=IDC_IMGP2_0 && eax<=IDC_IMGP2_7
				;P2
				sub		eax,IDC_IMGP2_0
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr(SFR_P2),al
				invoke UpdatePorts
			.elseif eax>=IDC_IMGP3_0 && eax<=IDC_IMGP3_7
				;P3
				sub		eax,IDC_IMGP3_0
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr(SFR_P3),al
				invoke UpdatePorts
			.endif
		.endif
	.elseif eax==WM_INITMENUPOPUP
		invoke SendDlgItemMessage,hWin,IDC_LSTCODE,LB_GETCOUNT,0,0
		mov		ebx,MF_BYCOMMAND or MF_GRAYED
		.if eax
			mov		ebx,MF_BYCOMMAND or MF_ENABLED
		.endif
		push	0
		push	IDM_SEARCH_FIND
		push	IDM_DEBUG_RUN
		push	IDM_DEBUG_PAUSE
		push	IDM_DEBUG_STOP
		push	IDM_DEBUG_STEP_INTO
		push	IDM_DEBUG_STEP_OVER
		push	IDM_DEBUG_RUN_TO_CURSOR
		push	IDM_DEBUG_TOGGLE
		push	IDM_DEBUG_CLEAR
		pop		eax
		.while eax
			invoke EnableMenuItem,hMenu,eax,ebx
			pop		eax
		.endw
	.elseif eax==WM_CLOSE
		.if hMemFile
			invoke GlobalFree,hMemFile
		.endif
		.if hMemCode
			invoke GlobalFree,hMemCode
		.endif
		.if hMemAddr
			invoke GlobalFree,hMemAddr
		.endif
		invoke DeleteObject,hLstFont
		invoke DeleteObject,hBmpGrayLed
		invoke DeleteObject,hBmpGreenLed
		invoke DeleteObject,hBmpRedLed
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
	invoke CreateDialogParam,hInstance,IDD_SIM52,NULL,addr WndProc,NULL
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
