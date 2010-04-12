.486
.model flat, stdcall  ; 32 bit memory model
option casemap :none  ; case sensitive

include RadASM.inc
include Misc.asm
include IniFile.asm
include Tools.asm
include TabTool.asm
include FileIO.asm

.code

MakeMdiCldWin proc lpClass:DWORD,ID:DWORD
	LOCAL	rect:RECT

	xor		eax,eax
	mov		rect.left,eax
	mov		rect.top,eax
	mov		rect.right,eax
	mov		rect.bottom,eax
	mov		eax,ID
	mov		mdiID,eax
	mov		eax,MDIS_ALLCHILDSTYLES or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
	.if da.win.fcldmax
		or		eax,WS_MAXIMIZE
	.endif
	mov		edx,WS_EX_MDICHILD
	.if ID!=ID_EDITRES
		mov		edx,WS_EX_CLIENTEDGE or WS_EX_MDICHILD
	.endif
	invoke CreateWindowEx,edx,lpClass,NULL,eax,rect.left,rect.top,rect.right,rect.bottom,ha.hClient,NULL,ha.hInstance,NULL
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
		invoke CreateWindowEx,0,addr szStaticClassName,NULL,WS_CHILD or WS_VISIBLE or SS_ETCHEDHORZ or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,hWin,NULL,ha.hInstance,0
		mov		ha.hDiv1,eax
		invoke CreateWindowEx,0,addr szStaticClassName,NULL,WS_CHILD or WS_VISIBLE or SS_ETCHEDHORZ or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,hWin,NULL,ha.hInstance,0
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
				invoke strcpy,addr da.FileName,addr szNewFile
				invoke MakeMdiCldWin,addr szEditCldClassName,ID_EDITCODE
			.elseif eax==IDM_FILE_OPEN
				invoke OpenEditFile
			.elseif eax==IDM_FILE_CLOSE
				.if ha.hMdi
					invoke SendMessage,ha.hMdi,WM_CLOSE,0,0
				.endif
			.elseif eax==IDM_FILE_SAVE
				.if ha.hMdi
					invoke SaveTheFile,ha.hMdi
				.endif
			.elseif eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax==IDM_VIEW_TBFILE
				invoke HideToolBar,1
			.elseif eax==IDM_VIEW_TBEDIT
				invoke HideToolBar,2
			.elseif eax==IDM_VIEW_TBBOOKMARK
				invoke HideToolBar,3
			.elseif eax==IDM_VIEW_TBVIEW
				invoke HideToolBar,4
			.elseif eax==IDM_VIEW_TBMAKE
				invoke HideToolBar,5
			.elseif eax==IDM_VIEW_TBBUILD
				invoke HideToolBar,6
			.elseif eax==IDM_VIEW_STATUSBAR
				xor		da.win.fView,VIEW_STATUSBAR
				invoke SendMessage,hWin,WM_SIZE,0,0
				mov		ebx,SW_HIDE
				test	da.win.fView,VIEW_STATUSBAR
				.if !ZERO?
					mov		ebx,SW_SHOWNA
				.endif
				invoke ShowWindow,ha.hStatus,ebx
			.elseif eax==IDM_VIEW_PROJECT
				invoke SendMessage,ha.hTool,TLM_HIDE,0,ha.hToolProject
			.elseif eax==IDM_VIEW_OUTPUT
				invoke SendMessage,ha.hTool,TLM_HIDE,0,ha.hToolOutput
			.elseif eax==IDM_VIEW_PROPERTIES
				invoke SendMessage,ha.hTool,TLM_HIDE,0,ha.hToolProperties
			.elseif eax==IDM_VIEW_TAB
				invoke SendMessage,ha.hTool,TLM_HIDE,0,ha.hToolTab
			.else
				jmp		ExDef
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke PutWinPos
		invoke SaveTools
		invoke SaveReBar
		jmp		ExDef
	.elseif eax==WM_DESTROY
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
		invoke MoveWindow,ha.hDiv1,0,0,4096,2,TRUE
		;Size rebar
		.if lParam
			invoke GetClientRect,hWin,addr rect
			invoke MoveWindow,ha.hReBar,0,2,rect.right,rect.bottom,TRUE
		.endif
		invoke GetWindowRect,ha.hReBar,addr rect
		mov		esi,rect.bottom
		sub		esi,rect.top
		.if esi
			add		esi,2
		.endif
		invoke MoveWindow,ha.hDiv2,0,esi,4096,2,TRUE
		add		esi,2
		;Size StatusBar
		xor		ebx,ebx
		test	da.win.fView,VIEW_STATUSBAR
		.if !ZERO?
			invoke MoveWindow,ha.hStatus,0,0,0,0,FALSE
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
	.elseif eax==WM_NOTIFY
		mov		esi,lParam
		mov		eax,[esi].NMHDR.hwndFrom
		.if [esi].NMHDR.code==RBN_HEIGHTCHANGE && eax==ha.hReBar
			invoke SendMessage,hWin,WM_SIZE,0,0
		.elseif [esi].NMHDR.code==TCN_SELCHANGE
			.if eax==ha.hTabProject
				invoke SendMessage,ha.hTabProject,TCM_GETCURSEL,0,0
				.if eax
					invoke ShowWindow,ha.hProjectBrowser,SW_SHOWNA
					invoke ShowWindow,ha.hFileBrowser,SW_HIDE
				.else
					invoke ShowWindow,ha.hFileBrowser,SW_SHOWNA
					invoke ShowWindow,ha.hProjectBrowser,SW_HIDE
				.endif
			.elseif eax==ha.hTabOutput
				invoke SendMessage,ha.hTabOutput,TCM_GETCURSEL,0,0
				.if eax
					invoke ShowWindow,ha.hImmediate,SW_SHOWNA
					invoke ShowWindow,ha.hOutput,SW_HIDE
				.else
					invoke ShowWindow,ha.hOutput,SW_SHOWNA
					invoke ShowWindow,ha.hImmediate,SW_HIDE
				.endif
			.endif
		.elseif [esi].NMHDR.code==FBN_DBLCLICK && eax==ha.hFileBrowser
			invoke OpenTheFile,[esi].FBNOTIFY.lpfile
		.endif
	.elseif eax==WM_TOOLSIZE
		mov		eax,wParam
		mov		esi,lParam
		.if eax==ha.hToolProject
			invoke MoveWindow,ha.hTabProject,0,0,[esi].RECT.right,20,TRUE
			sub		[esi].RECT.bottom,20
			invoke MoveWindow,ha.hFileBrowser,0,20,[esi].RECT.right,[esi].RECT.bottom,TRUE
			invoke MoveWindow,ha.hProjectBrowser,0,20,[esi].RECT.right,[esi].RECT.bottom,TRUE
		.elseif eax==ha.hToolProperties
			invoke MoveWindow,ha.hProperties,0,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
		.elseif eax==ha.hToolOutput
			invoke MoveWindow,ha.hTabOutput,0,0,20,[esi].RECT.bottom,TRUE
			sub		[esi].RECT.right,20
			invoke MoveWindow,ha.hOutput,20,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
			invoke MoveWindow,ha.hImmediate,20,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
		.elseif eax==ha.hToolTab
			invoke MoveWindow,ha.hTab,0,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
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

MdiChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hEdt:HWND
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,mdiID
		.if eax==ID_EDITCODE
			invoke CreateWindowEx,0,addr szRAEditClass,NULL,WS_CHILD or WS_VISIBLE,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,REM_SETFONT,0,addr ha.racf
		.elseif eax==ID_EDITTEXT
			invoke CreateWindowEx,0,addr szRAEditClass,NULL,WS_CHILD or WS_VISIBLE or STYLE_NOCOLLAPSE or STYLE_NOHILITE,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,REM_SETFONT,0,addr ha.ratf
		.elseif eax==ID_EDITHEX
			invoke CreateWindowEx,0,addr szRAHexEdClassName,NULL,WS_CHILD or WS_VISIBLE,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,HEM_SETFONT,0,addr ha.rahf
		.elseif eax==ID_EDITRES
			invoke CreateWindowEx,0,addr szResEdClass,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,DEM_SETSIZE,0,addr da.winres
			invoke SendMessage,hEdt,WM_SETFONT,ha.hToolFont,FALSE
		.elseif eax==ID_EDITUSER
			mov		hEdt,0
		.endif
		invoke SetWindowLong,hWin,GWL_USERDATA,hEdt
		invoke SetWindowText,hWin,addr da.FileName
		invoke TabToolAdd,hWin,addr da.FileName
		xor		eax,eax
		jmp		Ex
	.elseif eax==WM_SIZE
		mov		eax,wParam
		.if eax==SIZE_MAXIMIZED
			mov		da.win.fcldmax,TRUE
		.elseif eax==SIZE_RESTORED || eax==SIZE_MINIMIZED
			mov		da.win.fcldmax,FALSE
		.endif
		invoke GetWindowLong,hWin,GWL_USERDATA
		mov		hEdt,eax
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,hEdt,0,0,rect.right,rect.bottom,TRUE
	.elseif eax==WM_WINDOWPOSCHANGED
	.elseif eax==WM_MDIACTIVATE
		mov		eax,hWin
		.if eax==lParam
			;Activate
			invoke TabToolGetInx,hWin
			invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
			invoke TabToolActivate
		.else
			;Deactivate
			mov		ha.hMdi,0
			mov		ha.hEdt,0
			mov		da.FileName,0
		.endif
	.elseif eax==WM_CLOSE
		invoke WantToSave,hWin
		.if !eax
			invoke GetWindowLong,hWin,GWL_USERDATA
			mov		hEdt,eax
			invoke GetWindowLong,hEdt,GWL_ID
			.if eax==ID_EDITCODE
			.elseif eax==ID_EDITTEXT
			.elseif eax==ID_EDITHEX
			.elseif eax==ID_EDITRES
				invoke SendMessage,hEdt,DEM_GETSIZE,0,addr da.winres
				invoke SendMessage,hEdt,PRO_CLOSE,0,0
			.endif
			invoke TabToolDel,hWin
		.else
			xor		eax,eax
			jmp		Ex
		.endif
	.elseif eax==WM_NOTIFY
		mov		esi,lParam
		mov		eax,wParam
		.if eax==ID_EDITCODE
			.if [esi].NMHDR.code==EN_SELCHANGE
				.if [esi].RASELCHANGE.seltyp==SEL_OBJECT
				.elseif[esi].RASELCHANGE.seltyp==SEL_TEXT
					;Get TABMEM
					invoke GetWindowLong,[esi].NMHDR.hwndFrom,GWL_USERDATA
					mov		ebx,eax
					.if [esi].RASELCHANGE.fchanged && ![ebx].TABMEM.fchanged
						invoke GetParent,[esi].NMHDR.hwndFrom
						invoke TabToolSetChanged,eax,TRUE
					.endif
				.endif
			.endif
		.elseif eax==ID_EDITTEXT
		.elseif eax==ID_EDITHEX
		.elseif eax==ID_EDITRES
		.elseif eax==ID_EDITUSER
		.endif
	.elseif eax==WM_COMMAND
	.elseif eax==WM_MOVE
	.elseif eax==WM_DESTROY
	.elseif eax==WM_ERASEBKGND
	.endif
	invoke DefMDIChildProc,hWin,uMsg,wParam,lParam
  Ex:
	ret

MdiChildProc endp

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
	;Mdi Child
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset MdiChildProc
	mov		wc.cbClsExtra,NULL
	;GWL_USERDATA=hEdit,GWL_ID>=ID_FIRSTCHILD
	mov		wc.cbWndExtra,0
	mov		eax,hInst
	mov		wc.hInstance,eax
	mov		wc.hbrBackground,NULL;COLOR_BTNFACE+1
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szEditCldClassName
	mov		eax,ha.hIcon
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	mov		eax,ha.hCursor
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
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
	invoke InstallRACodeComplete,ha.hInstance,FALSE
	invoke InstallFileBrowser,ha.hInstance,FALSE
	invoke InstallProjectBrowser,ha.hInstance,FALSE
	invoke InstallRAProperty,ha.hInstance,FALSE
	invoke InstallRATools,ha.hInstance,FALSE
	invoke InstallRAEdit,ha.hInstance,FALSE
	invoke RAHexEdInstall,ha.hInstance,FALSE
	invoke ResEdInstall,ha.hInstance,FALSE
	invoke GridInstall,ha.hInstance,FALSE
	invoke GetModuleFileName,ha.hInstance,addr da.szAppPath,sizeof da.szAppPath
	invoke strlen,addr da.szAppPath
	.while da.szAppPath[eax]!='\'
		dec		eax
	.endw
	mov		da.szAppPath[eax],0
	invoke strcpy,addr da.szRadASMIni,addr da.szAppPath
	invoke strcat,addr da.szRadASMIni,addr szBS
	invoke strcat,addr da.szRadASMIni,addr szInifile
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
