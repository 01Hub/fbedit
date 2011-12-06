.386
.model flat,stdcall
option casemap:none

include Sim52.inc
include Terminal.asm
include Sim52Core.asm
include Sim52Parse.asm

.code

HexToBin proc lpStr:DWORD

	push	esi
	xor		eax,eax
	xor		edx,edx
	mov		esi,lpStr
  @@:
	shl		eax,4
	add		eax,edx
	movzx	edx,byte ptr [esi]
	.if edx>='0' && edx<='9'
		sub		edx,'0'
		inc		esi
		jmp		@b
	.elseif  edx>='A' && edx<='F'
		sub		edx,'A'-10
		inc		esi
		jmp		@b
	.elseif  edx>='a' && edx<='f'
		sub		edx,'a'-10
		inc		esi
		jmp		@b
	.endif
	pop		esi
	ret

HexToBin endp

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
	invoke SendMessage,hGrd,GM_GETROWCOUNT,0,0
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

EditProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_CHAR
		mov		eax,wParam
		.if (eax>='0' && eax<='9') || (eax>='A' && eax<='F') || (eax>='a' && eax<='f') || eax==VK_BACK
			invoke CallWindowProc,lpOldEditProc,hWin,uMsg,wParam,lParam
		.else
			xor		eax,eax
		.endif
	.else
		invoke CallWindowProc,lpOldEditProc,hWin,uMsg,wParam,lParam
	.endif
	ret

EditProc endp

TabStatusProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[32]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_EDTPC,EM_LIMITTEXT,4,0
		invoke SendDlgItemMessage,hWin,IDC_EDTDPTR,EM_LIMITTEXT,4,0
		invoke SendDlgItemMessage,hWin,IDC_EDTACC,EM_LIMITTEXT,2,0
		invoke SendDlgItemMessage,hWin,IDC_EDTB,EM_LIMITTEXT,2,0
		invoke SendDlgItemMessage,hWin,IDC_EDTSP,EM_LIMITTEXT,2,0
		invoke SendDlgItemMessage,hWin,IDC_EDTR0,EM_LIMITTEXT,2,0
		invoke SendDlgItemMessage,hWin,IDC_EDTR1,EM_LIMITTEXT,2,0
		invoke SendDlgItemMessage,hWin,IDC_EDTR2,EM_LIMITTEXT,2,0
		invoke SendDlgItemMessage,hWin,IDC_EDTR3,EM_LIMITTEXT,2,0
		invoke SendDlgItemMessage,hWin,IDC_EDTR4,EM_LIMITTEXT,2,0
		invoke SendDlgItemMessage,hWin,IDC_EDTR5,EM_LIMITTEXT,2,0
		invoke SendDlgItemMessage,hWin,IDC_EDTR6,EM_LIMITTEXT,2,0
		invoke SendDlgItemMessage,hWin,IDC_EDTR7,EM_LIMITTEXT,2,0
		push	0
		push	IDC_EDTPC
		push	IDC_EDTDPTR
		push	IDC_EDTACC
		push	IDC_EDTB
		push	IDC_EDTSP
		push	IDC_EDTR0
		push	IDC_EDTR1
		push	IDC_EDTR2
		push	IDC_EDTR3
		push	IDC_EDTR4
		push	IDC_EDTR5
		push	IDC_EDTR6
		mov		eax,IDC_EDTR7
		.while eax
			invoke GetDlgItem,hWin,eax
			invoke SetWindowLong,eax,GWL_WNDPROC,offset EditProc
			mov		lpOldEditProc,eax
			pop		eax
		.endw
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax>=IDC_IMGP && eax<=IDC_IMGCY
				;PSW
				sub		eax,IDC_IMGP
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr[SFR_PSW],al
				mov		Refresh,1
			.elseif eax>=IDC_IMGP0_0 && eax<=IDC_IMGP0_7
				;P0
				sub		eax,IDC_IMGP0_0
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr[SFR_P0],al
				mov		Refresh,1
			.elseif eax>=IDC_IMGP1_0 && eax<=IDC_IMGP1_7
				;P1
				sub		eax,IDC_IMGP1_0
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr[SFR_P1],al
				mov		Refresh,1
			.elseif eax>=IDC_IMGP2_0 && eax<=IDC_IMGP2_7
				;P2
				sub		eax,IDC_IMGP2_0
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr[SFR_P2],al
				mov		Refresh,1
			.elseif eax>=IDC_IMGP3_0 && eax<=IDC_IMGP3_7
				;P3
				sub		eax,IDC_IMGP3_0
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr[SFR_P3],al
				mov		Refresh,1
			.elseif eax==IDC_BTNRESET
				mov		TotalCycles,0
				invoke SetDlgItemInt,hWin,IDC_STCCYCLES,TotalCycles,FALSE
			.endif
		.elseif edx==EN_KILLFOCUS
			mov		ebx,eax
			invoke GetDlgItemText,hWin,ebx,addr buffer,sizeof buffer
			mov		dword ptr buffer[16],'0000'
			invoke lstrlen,addr buffer
			mov		edx,4
			sub		edx,eax
			.if ebx==IDC_EDTPC || ebx==IDC_EDTDPTR
				invoke lstrcpy,addr buffer[edx+16],addr buffer
				invoke HexToBin,addr buffer[16]
				.if ebx==IDC_EDTPC
					mov		PC,eax
				.elseif ebx==IDC_EDTDPTR
					mov		word ptr Sfr[SFR_DPL],ax
					mov		Refresh,1
				.endif
			.else
				invoke lstrcpy,addr buffer[edx+16],addr buffer
				invoke HexToBin,addr buffer[16]
				.if ebx==IDC_EDTACC
					mov		Sfr[SFR_ACC],al
					mov		Refresh,1
				.elseif ebx==IDC_EDTB
					mov		Sfr[SFR_B],al
					mov		Refresh,1
				.elseif ebx==IDC_EDTSP
					mov		Sfr[SFR_SP],al
					mov		Refresh,1
				.elseif ebx>=IDC_EDTR0 && ebx<=IDC_EDTR7
					sub		ebx,IDC_EDTR0
					mov		edx,ViewBank
					mov		Ram[ebx+edx*8],al
					mov		Refresh,1
				.endif
			.endif
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
			mov		Refresh,1
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabStatusProc endp

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
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax>=IDC_IMGBIT00 && eax<=IDC_IMGBIT7F
				sub		eax,IDC_IMGBIT00
				mov		ebx,eax
				and		eax,07h
				shr		ebx,3
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Ram[ebx+20h],al
				mov		Refresh,1
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabBitProc endp

TabSfrProc proc uses ebx esi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		esi,offset SfrData
		.while [esi].SFRMAP.ad
			invoke SendDlgItemMessage,hWin,IDC_CBOSFR,CB_ADDSTRING,0,addr [esi].SFRMAP.nme
			invoke SendDlgItemMessage,hWin,IDC_CBOSFR,CB_SETITEMDATA,eax,[esi].SFRMAP.ad
			lea		esi,[esi+sizeof SFRMAP]
		.endw
		invoke SendDlgItemMessage,hWin,IDC_CBOSFR,CB_SETCURSEL,0,0
		invoke UpdateSelSfr,hWin
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==CBN_SELCHANGE
			mov		Refresh,1
		.elseif edx==BN_CLICKED
			.if eax>=IDC_IMGSFRBIT0 && eax<=IDC_IMGSFRBIT7
				push	eax
				invoke GetSfrPtr,hWin
				mov		ebx,[eax].SFRMAP.ad
				pop		eax
				sub		eax,IDC_IMGSFRBIT0
				mov		ecx,eax
				mov		eax,1
				shl		eax,cl
				xor		Sfr[ebx],al
				mov		Refresh,1
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabSfrProc endp

TabXRamProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabXRamProc endp

TabCodeProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabCodeProc endp

WndProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	tci:TC_ITEM
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	tid:DWORD
	LOCAL	hef:HEFONT
	LOCAL	col:COLUMN

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		invoke GetDlgItem,hWin,IDC_TBRSIM52
		invoke DoToolBar,hInstance,eax
		; Create font and set it to list box
		invoke CreateFontIndirect,addr Courier_New_9
		mov		hLstFont,eax
		invoke EnableDisable
		invoke GetMenu,hWin
		mov		hMenu,eax
		mov		tci.imask,TCIF_TEXT
		mov		tci.lpReserved1,0
		mov		tci.lpReserved2,0
		mov		tci.iImage,-1
		mov		tci.lParam,0
		mov		tci.pszText,offset szTabStatus
		invoke SendDlgItemMessage,hWin,IDC_TABSTATUS,TCM_INSERTITEM,0,addr tci
		invoke GetDlgItem,hWin,IDC_TABSTATUS
		mov		ebx,eax
		invoke CreateDialogParam,hInstance,IDD_DLGTABSTATUS,ebx,addr TabStatusProc,0
		mov		hTabDlgStatus,eax

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
		mov		eax,hLstFont
		mov		hef.hFont,eax
		mov		hef.hLnrFont,eax
		;Create the tab dialogs
		invoke CreateDialogParam,hInstance,IDD_DLGTABRAM,ebx,addr TabRamProc,0
		mov		hTabDlg[0],eax
		invoke SendDlgItemMessage,hTabDlg[0],IDC_UDCHEXRAM,HEM_SETFONT,0,addr hef
		invoke CreateDialogParam,hInstance,IDD_DLGTABBIT,ebx,addr TabBitProc,0
		mov		hTabDlg[4],eax
		invoke CreateDialogParam,hInstance,IDD_DLGTABSFR,ebx,addr TabSfrProc,0
		mov		hTabDlg[8],eax
		invoke SendDlgItemMessage,hTabDlg[8],IDC_UDCHEXSFR,HEM_SETFONT,0,addr hef
		invoke CreateDialogParam,hInstance,IDD_DLGTABXRAM,ebx,addr TabXRamProc,0
		mov		hTabDlg[12],eax
		invoke SendDlgItemMessage,hTabDlg[12],IDC_UDCHEXXRAM,HEM_SETFONT,0,addr hef
		invoke CreateDialogParam,hInstance,IDD_DLGTABCODE,ebx,addr TabCodeProc,0
		mov		hTabDlg[16],eax
		invoke SendDlgItemMessage,hTabDlg[16],IDC_UDCHEXCODE,HEM_SETFONT,0,addr hef

		invoke SendDlgItemMessage,hTabDlg[8],IDC_UDCHEXSFR,HEM_SETOFFSET,128,0
		invoke Reset
		invoke SetTimer,hWin,1000,200,NULL
		invoke LoadAccelerators,hInstance,IDR_ACCEL1
		mov		hAccel,eax
		invoke GetDlgItem,hWin,IDC_GRDCODE
		mov		hGrd,eax
		invoke SendMessage,hGrd,WM_SETFONT,hLstFont,0
		invoke ImageList_Create,16,16,ILC_COLOR24,1,0
		mov		hIml,eax
		invoke ImageList_Add,hIml,hBmpRedLed,NULL
		;Add Break Point column
		mov		col.colwt,16
		mov		col.lpszhdrtext,NULL;offset szAddress
		mov		col.halign,GA_ALIGN_LEFT
		mov		col.calign,GA_ALIGN_LEFT
		mov		col.ctype,TYPE_IMAGE
		mov		col.ctextmax,0
		mov		col.lpszformat,0
		mov		eax,hIml
		mov		col.himl,eax
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col

		;Add Label column
		mov		col.colwt,100
		mov		col.lpszhdrtext,offset szLabel
		mov		col.halign,GA_ALIGN_LEFT
		mov		col.calign,GA_ALIGN_LEFT
		mov		col.ctype,TYPE_EDITTEXT
		mov		col.ctextmax,31
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col

		;Add Code column
		mov		col.colwt,212
		mov		col.lpszhdrtext,offset szCode
		mov		col.halign,GA_ALIGN_LEFT
		mov		col.calign,GA_ALIGN_LEFT
		mov		col.ctype,TYPE_EDITTEXT
		mov		col.ctextmax,63
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col

	.elseif eax==WM_TIMER
		.if Refresh
			invoke UpdateStatus
			invoke UpdatePorts
			invoke UpdateRegisters
			invoke SendDlgItemMessage,hTabDlg[0],IDC_UDCHEXRAM,HEM_SETMEM,256,addr Ram
			invoke UpdateBits
			invoke SendDlgItemMessage,hTabDlg[8],IDC_UDCHEXSFR,HEM_SETMEM,128,addr Sfr[128]
			invoke SendDlgItemMessage,hTabDlg[12],IDC_UDCHEXXRAM,HEM_SETMEM,65535,addr XRam
			invoke SendDlgItemMessage,hTabDlg[16],IDC_UDCHEXCODE,HEM_SETMEM,65535,addr Code
			invoke SetDlgItemInt,hWin,IDC_STCCYCLES,TotalCycles,FALSE
			invoke UpdateSelSfr,hTabDlg[8]
			dec		Refresh
		.endif
	.elseif eax==WM_NOTIFY
		mov		eax,wParam
		.if eax==IDC_TABVIEW
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
		.elseif eax==IDC_GRDCODE
			mov		ebx,lParam
			mov		eax,[ebx].NMHDR.code
			.if eax==GN_IMAGECLICK
				invoke SendMessage,hWin,WM_COMMAND,IDM_DEBUG_TOGGLE,hGrd
			.endif
		.endif
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED || edx==1
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
					mov		eax,hBmpGreenLed
					mov		StatusLed,eax
					invoke SendDlgItemMessage,hWnd,IDC_IMGSTATUS,STM_SETIMAGE,IMAGE_BITMAP,eax
					invoke SetFocus,hGrd
				.endif
			.elseif eax==IDM_SEARCH_FIND
			.elseif eax==IDM_VIEW_TERMINAL
				invoke CreateDialogParam,hInstance,IDD_DLGTERMINAL,hWin,addr TerminalProc,0
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
					and		State,-1 xor SIM52_BREAKPOINT
				.endif
			.elseif eax==IDM_DEBUG_STOP
				mov		State,STATE_STOP
			.elseif eax==IDM_DEBUG_STEP_INTO
				.if State & STATE_THREAD
					or		State,STATE_STEP_INTO or STATE_PAUSE
					and		State,-1 xor SIM52_BREAKPOINT
				.else
					mov		State,STATE_THREAD or STATE_RUN or STATE_PAUSE or STATE_STEP_INTO
					invoke CreateThread,NULL,0,addr CoreThread,0,0,addr tid
					invoke CloseHandle,eax
				.endif
			.elseif eax==IDM_DEBUG_STEP_OVER
				.if State & STATE_THREAD
					or		State,STATE_STEP_OVER or STATE_PAUSE
					and		State,-1 xor SIM52_BREAKPOINT
				.else
					mov		State,STATE_THREAD or STATE_RUN or STATE_PAUSE or STATE_STEP_OVER
					invoke CreateThread,NULL,0,addr CoreThread,0,0,addr tid
					invoke CloseHandle,eax
				.endif
			.elseif eax==IDM_DEBUG_RUN_TO_CURSOR
				invoke SendMessage,hGrd,GM_GETCURROW,0,0
				.if eax!=LB_ERR
					invoke FindLbInx,eax
					movzx	eax,[eax].MCUADDR.mcuaddr
					mov		CursorAddr,eax
					.if State & STATE_THREAD
						or		State,STATE_RUN_TO_CURSOR or STATE_PAUSE
						and		State,-1 xor SIM52_BREAKPOINT
					.else
						mov		State,STATE_THREAD or STATE_RUN or STATE_PAUSE or STATE_RUN_TO_CURSOR
						invoke CreateThread,NULL,0,addr CoreThread,0,0,addr tid
						invoke CloseHandle,eax
					.endif
				.endif
			.elseif eax==IDM_DEBUG_TOGGLE
				invoke SendMessage,hGrd,GM_GETCURROW,0,0
				.if eax!=LB_ERR
					invoke ToggleBreakPoint,eax
				.endif
			.elseif eax==IDM_DEBUG_CLEAR
				invoke ClearBreakPoints
			.elseif eax==IDM_HELP_ABOUT
				invoke ShellAbout,hWin,addr AppName,addr AboutMsg,NULL
			.endif
		.endif
	.elseif eax==WM_INITMENUPOPUP
		invoke SendMessage,hGrd,GM_GETROWCOUNT,0,0
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
		.if hMemAddr
			invoke GlobalFree,hMemAddr
		.endif
		invoke DeleteObject,hLstFont
		invoke ImageList_Destroy,hIml
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
	invoke LoadBitmap,hInstance,IDB_LEDGRAY
	mov		hBmpGrayLed,eax
	invoke LoadBitmap,hInstance,IDB_LEDGREEN
	mov		hBmpGreenLed,eax
	invoke LoadBitmap,hInstance,IDB_LEDRED
	mov		hBmpRedLed,eax
	invoke Reset
	invoke CreateDialogParam,hInstance,IDD_SIM52,NULL,addr WndProc,NULL
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd

	push	0
	push	0
	push	AM_SHOW
	push	hWnd
	invoke GetProcAddress,hLCDDll,1
	call	eax

	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke IsDialogMessage,hTabDlgStatus,addr msg
		.if !eax
			invoke TranslateAccelerator,hWnd,hAccel,addr msg
			.if !eax
				invoke TranslateMessage,addr msg
				invoke DispatchMessage,addr msg
			.endif
		.endif
	.endw
	invoke DeleteObject,hBmpGrayLed
	invoke DeleteObject,hBmpGreenLed
	invoke DeleteObject,hBmpRedLed
	mov		eax,msg.wParam
	ret

WinMain endp

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke GetCommandLine
	invoke InitCommonControls
	mov		CommandLine,eax
	invoke RAHexEdInstall,hInstance,FALSE
	invoke GridInstall,hInstance,FALSE
	invoke LoadLibrary,addr szLCDDll
	mov		hLCDDll,eax
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke FreeLibrary,hLCDDll
	invoke GridUnInstall
	invoke RAHexEdUnInstall
	invoke ExitProcess,eax

end start
