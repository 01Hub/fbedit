.486
.model flat, stdcall  ; 32 bit memory model
option casemap :none  ; case sensitive

include RadASM.inc
include Misc.asm
include IniFile.asm
include Tools.asm

.code

MakeMdiCldWin proc lpClass:DWORD,ID:DWORD
	LOCAL	hWin:HWND
	LOCAL	hEdt:DWORD
	LOCAL	ws:DWORD
	LOCAL	rect:RECT
	LOCAL	iNbr:DWORD

	xor		eax,eax
	mov		rect.left,eax
	mov		rect.top,eax
	mov		rect.right,eax
	mov		rect.bottom,eax
;	mov		REdPos,0
;	invoke ProSetPos,addr rect
;	mov		iNbr,eax
	mov		eax,ID
;	mov		MdiID,eax
	mov		ws,MDIS_ALLCHILDSTYLES or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
;	.if eax==ID_DIALOG
;		mov		ws,MDIS_ALLCHILDSTYLES or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or WS_VSCROLL or WS_HSCROLL
;	.endif
	.if da.win.fcldmax
		or		ws,WS_MAXIMIZE
	.endif
	invoke CreateWindowEx,WS_EX_MDICHILD or WS_EX_CLIENTEDGE,lpClass,NULL,ws,rect.left,rect.top,rect.right,rect.bottom,ha.hClient,NULL,ha.hInstance,NULL
	mov		hWin,eax
;	invoke SetWindowLong,hWin,0,ID			;ID_EDIT, ID_EDITTXT, ID_DIALOG
;	invoke SetWindowLong,hWin,4,0			;SplittMode, hMem
;	invoke SetWindowLong,hWin,16,iNbr		;Project file ID
;	.if ID==ID_EDIT || ID==ID_EDITTXT
;		invoke GetWindowLong,hWin,GWL_USERDATA
;		mov		hEdt,eax
;		mov		edx,iNbr
;		.if edx
;			or		edx,80000000h
;			invoke ConvBookMark,edx,hEdt
;		.endif
;	.endif
;	invoke ProSetTrv,hWin
	mov		eax,hWin
	ret

MakeMdiCldWin endp

WndProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL   cc:CLIENTCREATESTRUCT
	LOCAL	rect:RECT
	LOCAL	ps:PAINTSTRUCT

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,hWin
		mov		ha.hWnd,eax
		invoke CreateWindowEx,0,addr szStaticClassName,NULL,WS_CHILD or WS_VISIBLE or SS_ETCHEDHORZ or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,4096,2,hWin,NULL,ha.hInstance,addr cc
		mov		ha.hDiv1,eax
		invoke CreateWindowEx,0,addr szStaticClassName,NULL,WS_CHILD or WS_VISIBLE or SS_ETCHEDHORZ or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,30,4096,2,hWin,NULL,ha.hInstance,addr cc
		mov		ha.hDiv2,eax
		;Create fonts
		invoke DoFonts
		;Create image lists
		invoke DoImageList
		;ToolBars
		invoke DoToolBar
		;ReBar
		invoke DoReBar
		;Statusbar
		invoke DoStatus
		;Mdi Client
		mov		cc.hWindowMenu,1
		mov		cc.idFirstChild,ID_FIRSTCHILD
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,addr szMdiClientClassName,NULL,WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_HSCROLL or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,hWin,NULL,ha.hInstance,addr cc
		mov     ha.hClient,eax
		;Menu
		invoke LoadMenu,ha.hInstance,IDR_MENU
		mov		ha.hMenu,eax
;		invoke SetMenu,hWin,ha.hMenu
		invoke SendMessage,ha.hClient,WM_MDISETMENU,ha.hMenu,0
		invoke SendMessage,ha.hClient,WM_MDIREFRESHMENU,0,0
		invoke DrawMenuBar,hWin
		invoke CreateTools
		invoke SendMessage,ha.hFileBrowser,FBM_SETPATH,TRUE,addr da.szAppPath
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movsx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED || edx==1
			.if eax==IDM_FILE_NEW
				invoke MakeMdiCldWin,addr szEditCldClassName,ID_EDIT
				;invoke SetWindowText,hMdiCld,addr NewFile
				;invoke TabToolAdd,hMdiCld,offset NewFile-1
			.elseif eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.else
				jmp		ExDef
			.endif
		.endif
	.elseif eax==WM_CLOSE
;		.if fProject
;			invoke CloseProject
;			.if eax
;				xor eax,eax
;				ret
;			.endif
;		.else
;			invoke UpdateAll,IDM_FILE_CLOSEFILE
;			invoke GetActive
;			.if hMdiCld
;				xor		eax,eax
;				ret
;			.endif
;		.endif
;		invoke KillTimer,hWin,200
;		invoke DllProc,hWin,AIM_CLOSE,wParam,lParam,RAM_CLOSE
;		.if nF1
;			invoke WinHelp,hWin,addr F1,HELP_QUIT,NULL
;		.endif
;		.if nCF1
;			invoke WinHelp,hWin,addr CF1,HELP_QUIT,NULL
;		.endif
;		.if nSF1
;			invoke WinHelp,hWin,addr SF1,HELP_QUIT,NULL
;		.endif
;		.if nCSF1
;			invoke WinHelp,hWin,addr CSF1,HELP_QUIT,NULL
;		.endif
;		mov		edx,offset MenuData
;	  @@:
;		push	edx
;		mov		al,(MENU ptr [edx]).param
;		or		al,al
;		je		@f
;		.if al=='H'
;			mov		eax,(MENU ptr [edx]).ncalls
;			.if eax
;				invoke WinHelp,hWin,addr (MENU ptr [edx]).cmnd,HELP_QUIT,NULL
;			.endif
;		.endif
;		pop		edx
;		add		edx,sizeof MENU
;		jmp		@b
;	  @@:
;		invoke SaveRecentFiles
;		invoke iniWinSavePos
;		invoke DestroyWindow,hTlt
		invoke PutWinPos
		jmp		ExDef
	.elseif eax==WM_DESTROY
;		invoke DestroyWindow,hDivLine
;		invoke DestroyWindow,hDivider
;		invoke DestroyWindow,hOutBtn1
;		invoke DestroyWindow,hOutBtn2
;		invoke DestroyWindow,hOutBtn3
;		invoke DestroyWindow,hToolTip
;		invoke DestroyWindow,hToolBar
;		invoke DestroyWindow,hPrpTbrCode
;		invoke DestroyWindow,hPbrTbr
;		invoke DestroyWindow,hOut
;		invoke DestroyWindow,hPbr
;		invoke DestroyWindow,hPrp
;		invoke DestroyWindow,hInfEdt
;		invoke DestroyWindow,hInf
;		invoke DestroyWindow,hTlb
;		invoke DestroyWindow,hLBU
;		invoke DestroyWindow,hLBS
;		invoke iniDestroySubMenu
;		invoke DestroyMenu,hMenu
;		invoke DestroyMenu,hToolMenu
;		invoke DeleteObject,hBrTlt
;		invoke DeleteObject,hBrPrp
;		invoke DeleteObject,hBrInfo
;		invoke DeleteObject,hBrDlg
;		invoke DeleteObject,hGridBr
;		invoke ImageList_Destroy,hTbrIml
;		invoke ImageList_Destroy,hTypeIml
;		invoke ImageList_Destroy,hBoxIml
		invoke PostQuitMessage,NULL
		jmp		ExDef
	.elseif eax==WM_MOUSEMOVE
		invoke SendMessage,ha.hTool,TLM_MOUSEMOVE,0,lParam
	.elseif eax==WM_LBUTTONDOWN
		invoke SendMessage,ha.hTool,TLM_LBUTTONDOWN,0,lParam
	.elseif eax==WM_LBUTTONUP
		invoke SendMessage,ha.hTool,TLM_LBUTTONUP,0,lParam
	.elseif eax==WM_PAINT
		invoke BeginPaint,hWin,addr ps
		invoke SendMessage,ha.hTool,TLM_PAINT,0,0
		invoke EndPaint,hWin,addr ps
	.elseif eax==WM_SIZE
		;Size rebar
		.if lParam
			invoke GetClientRect,hWin,addr rect
			invoke MoveWindow,ha.hReBar,0,2,rect.right,rect.bottom,TRUE
;			invoke UpdateWindow,ha.hReBar
;			invoke UpdateWindow,ha.hTbrFile
		.endif
		invoke GetWindowRect,ha.hReBar,addr rect
		mov		esi,rect.bottom
		sub		esi,rect.top
		add		esi,2
		invoke MoveWindow,ha.hDiv2,0,esi,4096,2,TRUE
		add		esi,2
		;Size StatusBar
		xor		ebx,ebx
		.if da.win.fSbr
			invoke MoveWindow,ha.hStatus,0,0,0,0,FALSE
;			invoke UpdateWindow,ha.hStatus
			invoke GetWindowRect,ha.hStatus,addr rect
			mov		ebx,rect.bottom
			sub		ebx,rect.top
		.endif
		;Size tool windows
		invoke GetClientRect,hWin,addr rect
		add		rect.top,esi
		sub		rect.bottom,ebx
		invoke SendMessage,ha.hTool,TLM_SIZE,0,addr rect
		invoke InvalidateRect,ha.hProjectBrowser,NULL,TRUE
		invoke InvalidateRect,ha.hFileBrowser,NULL,TRUE
;		invoke UpdateWindow,ha.hClient
;		invoke UpdateWindow,hWin
	.elseif eax==WM_NOTIFY
		mov		esi,lParam
		.if [esi].NMHDR.code==RBN_HEIGHTCHANGE
			invoke SendMessage,hWin,WM_SIZE,0,0
		.elseif [esi].NMHDR.code==TCN_SELCHANGE
			mov		eax,[esi].NMHDR.hwndFrom
			.if eax==ha.hTabProject
				invoke SendMessage,ha.hTabProject,TCM_GETCURSEL,0,0
				.if eax
					invoke ShowWindow,ha.hProjectBrowser,SW_SHOWNA
					invoke ShowWindow,ha.hFileBrowser,SW_HIDE
				.else
					invoke ShowWindow,ha.hFileBrowser,SW_SHOWNA
					invoke ShowWindow,ha.hProjectBrowser,SW_HIDE
				.endif
			.endif
		.endif
	.elseif eax==WM_TOOLSIZE
		mov		eax,wParam
		mov		esi,lParam
		.if eax==ha.hToolProject
			invoke MoveWindow,ha.hTabProject,0,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
			sub		[esi].RECT.bottom,24
			sub		[esi].RECT.right,4
			invoke MoveWindow,ha.hFileBrowser,2,22,[esi].RECT.right,[esi].RECT.bottom,TRUE
			invoke MoveWindow,ha.hProjectBrowser,2,22,[esi].RECT.right,[esi].RECT.bottom,TRUE
		.elseif eax==ha.hToolProperties
			invoke MoveWindow,ha.hProperties,0,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
		.endif
	.else
  ExDef:
		invoke DefFrameProc,hWin,ha.hClient,uMsg,wParam,lParam
		ret
	.endif
  Ex:
	xor     eax,eax
	ret

WndProc endp

EditChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hEdt:HWND
	LOCAL	rect:RECT
	LOCAL	ws:DWORD
	LOCAL	chrg:CHARRANGE

	mov		eax,uMsg
	.if eax==WM_CREATE
	.elseif eax==WM_SIZE
		mov		eax,wParam
		.if eax==SIZE_MAXIMIZED
			mov		da.win.fcldmax,TRUE
		.elseif eax==SIZE_RESTORED || eax==SIZE_MINIMIZED
			mov		da.win.fcldmax,FALSE
		.endif
	.elseif eax==WM_WINDOWPOSCHANGED
	.elseif eax==WM_MDIACTIVATE
	.elseif eax==WM_CLOSE
	.elseif eax==WM_NOTIFY
	.elseif eax==WM_COMMAND
	.elseif eax==WM_MOVE
	.elseif eax==WM_DESTROY
	.elseif eax==WM_ERASEBKGND
	.endif
	invoke DefMDIChildProc,hWin,uMsg,wParam,lParam
	ret

EditChildProc endp


WinMain proc hInst:DWORD,hPrevInst:DWORD,CmdLine:DWORD,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	invoke LoadIcon,hInst,IDI_MDIICO
	mov		ha.hIcon,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		ha.hCursor,eax
	invoke LoadCursor,hInst,IDC_SPLICURV
	mov		ha.hSplitCurV,eax
	invoke LoadCursor,hInst,IDC_SPLICURH
	mov		ha.hSplitCurH,eax
	invoke RtlZeroMemory,addr wc,sizeof WNDCLASSEX
	;Mdi Frame
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,NULL
	mov		eax,hInst
	mov		wc.hInstance,eax
	mov		wc.hbrBackground,NULL;COLOR_BTNFACE+1
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szMdiClassName
	mov		eax,ha.hIcon
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	mov		eax,ha.hCursor
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
;	;Full screen
;	mov		wc.cbSize,sizeof WNDCLASSEX
;	mov		wc.style,CS_HREDRAW or CS_VREDRAW
;	mov		wc.lpfnWndProc,offset FullScreenProc
;	mov		wc.cbClsExtra,NULL
;	mov		wc.cbWndExtra,NULL
;	m2m		wc.hInstance,hInst
;	mov		wc.hbrBackground,COLOR_BTNFACE+1
;	mov		wc.lpszMenuName,NULL
;	mov		wc.lpszClassName,offset FullScreenClassName
;	m2m		wc.hIcon,hIcon
;	m2m		wc.hCursor,hCursor
;	m2m		wc.hIconSm,hIcon
;	invoke RegisterClassEx,addr wc
	;Mdi Edit Child
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset EditChildProc
	mov		wc.cbClsExtra,NULL
	;GWL_USERDATA=hEdit,GWL_ID>=ID_FIRSTCHILD
	;0=ID_EDIT or ID_EDITTXT, 4=, 8=, 12=Changed since last property update
	;16=Project file ID, 20=Overwrite, 28=hRadMem
	mov		wc.cbWndExtra,32
	mov		eax,hInst
	mov		wc.hInstance,eax
	mov		wc.hbrBackground,COLOR_BTNFACE+1;NULL
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szEditCldClassName
	mov		eax,ha.hIcon
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	mov		eax,ha.hCursor
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
;	;Mdi Dialog Child
;	mov		wc.cbSize,sizeof WNDCLASSEX
;	mov		wc.style,CS_HREDRAW or CS_VREDRAW
;	mov		wc.lpfnWndProc,offset DialogChildProc
;	mov		wc.cbClsExtra,NULL
;	;GWL_USERDATA=hDialog,GWL_ID>=ID_FIRSTCHILD
;	;0=ID_DIALOG, 4=hMem, 8=ReadOnly
;	;16=Pfoject file ID, 20=ScrollX
;	;24=ScrollY, 28=hRadMem
;	mov		wc.cbWndExtra,32
;	m2m		wc.hInstance,hInstance
;	mov		wc.hbrBackground,NULL
;	mov		wc.lpszMenuName,NULL
;	mov		wc.lpszClassName,offset DialogCldClassName
;	m2m		wc.hIcon,hIcon
;	m2m		wc.hCursor,hCursor
;	m2m		wc.hIconSm,hIcon
;	invoke RegisterClassEx,addr wc
;	;Mdi HexEd Child
;	mov		wc.cbSize,sizeof WNDCLASSEX
;	mov		wc.style,CS_HREDRAW or CS_VREDRAW
;	mov		wc.lpfnWndProc,offset HexEdChildProc
;	mov		wc.cbClsExtra,NULL
;	;GWL_USERDATA=hHexEd,GWL_ID>=ID_FIRSTCHILD
;	;0=ID_EDITHEX, 4=, 8=, 12=
;	;16=Pfoject file ID, 20=, 28=hRadMem
;	mov		wc.cbWndExtra,32
;	m2m		wc.hInstance,hInstance
;	mov		wc.hbrBackground,COLOR_BTNFACE+1;NULL
;	mov		wc.lpszMenuName,NULL
;	mov		wc.lpszClassName,offset HexEdCldClassName
;	m2m		wc.hIcon,hIcon
;	m2m		wc.hCursor,hCursor
;	m2m		wc.hIconSm,hIcon
;	invoke RegisterClassEx,addr wc
;	;Tool windows
;	mov		wc.cbSize,sizeof WNDCLASSEX
;	mov		wc.style,CS_HREDRAW or CS_VREDRAW
;	mov		wc.lpfnWndProc,offset ToolWndProc
;	mov		wc.cbClsExtra,NULL
;	mov		wc.cbWndExtra,NULL
;	m2m		wc.hInstance,hInst
;	mov		wc.hbrBackground,NULL
;	mov		wc.lpszMenuName,NULL
;	mov		wc.lpszClassName,offset szToolClass
;	m2m		wc.hIcon,NULL
;	m2m		wc.hCursor,hCursor
;	m2m		wc.hIconSm,NULL
;	invoke RegisterClassEx,addr wc
;	;Tool child windows
;	mov		wc.cbSize,sizeof WNDCLASSEX
;	mov		wc.style,CS_HREDRAW or CS_VREDRAW
;	mov		wc.lpfnWndProc,offset ToolCldProc
;	mov		wc.cbClsExtra,NULL
;	mov		wc.cbWndExtra,NULL
;	m2m		wc.hInstance,hInst
;	mov		wc.hbrBackground,COLOR_BTNFACE+1
;	mov		wc.lpszMenuName,NULL
;	mov		wc.lpszClassName,offset szToolCldClass
;	m2m		wc.hIcon,NULL
;	m2m		wc.hCursor,hCursor
;	m2m		wc.hIconSm,NULL
;	invoke RegisterClassEx,addr wc
;	;Dialog Edit Window
;	mov		wc.cbSize,sizeof WNDCLASSEX
;	mov		wc.style,CS_HREDRAW or CS_VREDRAW
;	mov		wc.lpfnWndProc,offset EditDlgProc
;	mov		wc.cbClsExtra,NULL
;	mov		wc.cbWndExtra,NULL
;	m2m		wc.hInstance,hInst
;	mov		wc.hbrBackground,NULL
;	mov		wc.lpszMenuName,NULL
;	mov		wc.lpszClassName,offset DlgEditClass
;	m2m		wc.hIcon,NULL
;	m2m		wc.hCursor,hCursor
;	m2m		wc.hIconSm,NULL
;	invoke RegisterClassEx,addr wc
;	;Folder User control
;	mov		wc.cbSize,sizeof WNDCLASSEX
;	mov		wc.style,CS_HREDRAW or CS_VREDRAW
;	mov		wc.lpfnWndProc,offset UdcProc
;	mov		wc.cbClsExtra,NULL
;	mov		wc.cbWndExtra,NULL
;	push	hInstance
;	pop		wc.hInstance
;	mov		wc.hbrBackground,NULL
;	mov		wc.lpszMenuName,NULL
;	mov		wc.lpszClassName,offset UdcClassName
;	invoke LoadIcon,NULL,IDI_APPLICATION
;	mov		wc.hIcon,eax
;	mov		wc.hIconSm,eax
;	invoke LoadCursor,NULL,IDC_ARROW
;	mov		wc.hCursor,eax
;	invoke RegisterClassEx,addr wc
;	;Splash screen
;	mov		wc.cbSize,sizeof WNDCLASSEX
;	mov		wc.style,CS_HREDRAW or CS_VREDRAW
;	mov		wc.lpfnWndProc,offset SplashProc
;	mov		wc.cbClsExtra,NULL
;	mov		wc.cbWndExtra,NULL
;	push	hInstance
;	pop		wc.hInstance
;	mov		wc.hbrBackground,NULL
;	mov		wc.lpszMenuName,NULL
;	mov		wc.lpszClassName,offset SplashClassName
;	mov		wc.hIcon,NULL
;	mov		wc.hIconSm,NULL
;	invoke LoadCursor,NULL,IDC_ARROW
;	mov		wc.hCursor,eax
;	invoke RegisterClassEx,addr wc
;
;	mov		wc.cbSize,sizeof WNDCLASSEX
;	mov		wc.style,CS_HREDRAW or CS_VREDRAW
;	mov		wc.lpfnWndProc,offset DesignDummyProc
;	mov		wc.cbClsExtra,NULL
;	mov		wc.cbWndExtra,NULL
;	push	hInstance
;	pop		wc.hInstance
;	mov		wc.hbrBackground,NULL
;	mov		wc.lpszMenuName,NULL
;	mov		wc.lpszClassName,offset DlgEditDummyClass
;	mov		wc.hIcon,NULL
;	mov		wc.hIconSm,NULL
;	invoke LoadCursor,NULL,IDC_ARROW
;	mov		wc.hCursor,eax
;	invoke RegisterClassEx,addr wc
	invoke InstallRACodeComplete,ha.hInstance,FALSE
	invoke InstallFileBrowser,ha.hInstance,FALSE
	invoke RAHexEdInstall,ha.hInstance,FALSE
	invoke InstallProjectBrowser,ha.hInstance,FALSE
	invoke InstallRAProperty,ha.hInstance,FALSE
	invoke ResEdInstall,ha.hInstance,FALSE
	invoke InstallRATools,ha.hInstance,FALSE
	invoke GetModuleFileName,ha.hInstance,addr da.szAppPath,sizeof da.szAppPath
	invoke strlen,addr da.szAppPath
	.while da.szAppPath[eax]!='\'
		dec		eax
	.endw
	mov		da.szAppPath[eax],0
	invoke strcpy,addr da.szRadASMIni,addr da.szAppPath
	invoke strcat,addr da.szRadASMIni,addr szBS
	invoke strcat,addr da.szRadASMIni,addr szIniFile
	invoke GetWinPos
	mov     eax,WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
	mov		edx,WS_EX_LEFT or WS_EX_ACCEPTFILES
	.if da.win.ftopmost
		or		edx,WS_EX_TOPMOST
	.endif
	invoke CreateWindowEx,edx,addr szMdiClassName,addr DisplayName,eax,da.win.x,da.win.y,da.win.wt,da.win.ht,NULL,NULL,hInst,NULL
	mov     ha.hWnd,eax
	mov     eax,SW_SHOWNORMAL
	.if da.win.fmax
		mov     eax,SW_SHOWMAXIMIZED
	.endif
	invoke ShowWindow,ha.hWnd,eax
	invoke UpdateWindow,ha.hWnd
;	invoke ShowSplash
;	;Get command line filename
;	mov		eax,CommandLine
;	.if byte ptr [eax]
;		invoke OpenCommandLine,CommandLine
;	.elseif ProMenuID && fAutoLoadPro
;		invoke SendMessage,hWnd,WM_COMMAND,ProMenuID,0
;	.endif
	.while TRUE
		invoke GetMessage,addr msg,0,0,0
	  .break .if !eax
;		invoke IsDialogMessage,hSearch,addr msg
;		.if !eax
;			invoke IsDialogMessage,hGoTo,addr msg
;			.if !eax
;				invoke IsDialogMessage,hSniplet,addr msg
;				.if !eax
;					invoke TranslateAccelerator,hWnd,hAccel,addr msg
;					.if !eax
						invoke TranslateMessage,addr msg
						invoke DispatchMessage,addr msg
;					.endif
;				.endif
;			.endif
;		.endif
	.endw
	mov   eax,msg.wParam
	ret

WinMain endp

start:
	invoke GetModuleHandle,NULL
	mov		ha.hInstance,eax
	mov		osvi.dwOSVersionInfoSize,sizeof OSVERSIONINFO
	invoke GetVersionEx,offset osvi
	.if osvi.dwPlatformId == VER_PLATFORM_WIN32_NT
		mov		fNT,TRUE
	.endif
	invoke GetCommandLine
	mov		CommandLine,eax
	;Get command line filename
	invoke PathGetArgs,CommandLine
	mov		CommandLine,eax
	invoke WinMain,ha.hInstance,NULL,CommandLine,SW_SHOWDEFAULT

	invoke ExitProcess,0

end start
