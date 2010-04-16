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

TimerProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	.if da.fTimer
		dec		da.fTimer
		.if ZERO?
			invoke EnableToolBar
;			invoke MenuEnable
;			xor		eax,eax
;			test	wpos.fView,4
;			.if !ZERO?
;				inc		eax
;			.endif
;			invoke SendMessage,ha.hTbr,TB_CHECKBUTTON,IDM_VIEW_OUTPUT,eax
;			invoke ShowSession
;			invoke ShowProc,nLastLine
;			invoke GetCapture
;			.if !eax
;				invoke UpdateAll,IS_CHANGED,0
;			.else
;				mov		fTimer,1
;			.endif
		.endif
	.endif
	ret

TimerProc endp

CodeCompleteProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_CHAR
		mov		eax,wParam
		.if eax==VK_TAB || eax==VK_RETURN
			invoke SendMessage,ha.hEdt,WM_CHAR,VK_TAB,0
			jmp		Ex
		.elseif eax==VK_ESCAPE
			invoke ShowWindow,hWin,SW_HIDE
			jmp		Ex
		.endif
	.elseif eax==WM_LBUTTONDBLCLK
		invoke SendMessage,ha.hEdt,WM_CHAR,VK_TAB,0
		jmp		Ex
	.elseif eax==WM_SIZE
		invoke GetWindowRect,hWin,addr rect
		mov		eax,rect.right
		sub		eax,rect.left
		mov		edx,rect.bottom
		sub		edx,rect.top
		mov		da.win.ccwt,eax
		mov		da.win.ccht,edx
	.endif
	invoke CallWindowProc,lpOldCCProc,hWin,uMsg,wParam,lParam
  Ex:
	ret

CodeCompleteProc endp

MakeMdiCldWin proc lpClass:DWORD,ID:DWORD
	LOCAL	rect:RECT

	mov		eax,CW_USEDEFAULT
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
	LOCAL	pt:POINT
	LOCAL	ps:PAINTSTRUCT
	LOCAL	chrg:CHARRANGE
	LOCAL	hebmk:HEBMK

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,hWin
		mov		ha.hWnd,eax
		;Load accelerators
		invoke LoadAccelerators,ha.hInstance,IDA_ACCEL
		mov		ha.hAccel,eax
		;Create divider lines
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
		mov		cc.hWindowMenu,0
		mov		cc.idFirstChild,ID_FIRSTCHILD
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,addr szMdiClientClassName,NULL,WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_HSCROLL or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,hWin,NULL,ha.hInstance,addr cc
		mov     ha.hClient,eax
		;Menu
		invoke LoadMenu,ha.hInstance,IDR_MENU
		mov		ha.hMenu,eax
		invoke LoadMenu,ha.hInstance,IDR_CONTEXTMENU
		mov		ha.hContextMenu,eax
		invoke GetSubMenu,ha.hMenu,9
		invoke SendMessage,ha.hClient,WM_MDISETMENU,ha.hMenu,eax
		invoke SendMessage,ha.hClient,WM_MDIREFRESHMENU,0,0
		invoke DrawMenuBar,hWin
		;Create code complete
		invoke CreateWindowEx,NULL,addr szCCLBClassName,NULL,WS_CHILD or WS_SIZEBOX or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or STYLE_USEIMAGELIST,0,0,0,0,ha.hWnd,NULL,ha.hInstance,0
		mov		ha.hCC,eax
;		invoke SetWindowLong,ha.hCC,GWL_WNDPROC,offset CodeCompleteProc
;		mov		lpOldCCProc,eax
		invoke CreateWindowEx,NULL,addr szCCTTClassName,NULL,WS_POPUP or WS_BORDER or WS_CLIPSIBLINGS or WS_CLIPCHILDREN,0,0,0,0,ha.hWnd,NULL,ha.hInstance,0
		mov		ha.hTT,eax
		invoke SendMessage,ha.hCC,WM_SETFONT,ha.hToolFont,FALSE
		invoke SendMessage,ha.hTT,WM_SETFONT,ha.hToolFont,FALSE
		;Create tool windows
		invoke CreateTools
		invoke GetSession
		invoke GetAssembler
		invoke GetColors
		invoke GetKeywords
		invoke GetBlockDef
		invoke GetOption
		invoke GetParesDef
		invoke SendMessage,ha.hFileBrowser,FBM_GETIMAGELIST,0,0
		invoke SendMessage,ha.hTab,TCM_SETIMAGELIST,0,eax
		invoke SetTimer,hWin,200,200,addr TimerProc
		mov		da.fTimer,1
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movsx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED || edx==1
			.if eax==IDM_FILE_NEW
				invoke strcpy,addr da.szFileName,addr szNewFile
				invoke MakeMdiCldWin,addr szEditCldClassName,ID_EDITCODE
			.elseif eax==IDM_FILE_OPEN
				invoke OpenEditFile,0
			.elseif eax==IDM_FILE_OPENHEX
				invoke OpenEditFile,ID_EDITHEX
			.elseif eax==IDM_FILE_REOPEN
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke LoadTextFile,ha.hEdt,addr da.szFileName
						invoke TabToolSetChanged,ha.hMdi,FALSE
					.elseif eax==ID_EDITHEX
						invoke LoadHexFile,ha.hEdt,addr da.szFileName
						invoke TabToolSetChanged,ha.hMdi,FALSE
					.elseif eax==ID_EDITRES
						invoke LoadResFile,ha.hEdt,addr da.szFileName
						invoke TabToolSetChanged,ha.hMdi,FALSE
					.elseif eax==ID_EDITUSER
					.endif
				.endif
			.elseif eax==IDM_FILE_CLOSE
				.if ha.hMdi
					invoke SendMessage,ha.hMdi,WM_CLOSE,0,0
				.endif
			.elseif eax==IDM_FILE_SAVE
				.if ha.hMdi
					invoke SaveTheFile,ha.hMdi
				.endif
			.elseif eax==IDM_FILE_SAVEAS
				.if ha.hMdi
					invoke SaveFileAs,ha.hMdi,addr da.szFileName
				.endif
			.elseif eax==IDM_FILE_SAVEALL
				invoke UpdateAll,UAM_SAVEALL,FALSE
			.elseif eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax==IDM_EDIT_UNDO
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT || eax==ID_EDITHEX
						invoke SendMessage,ha.hEdt,EM_UNDO,0,0
					.elseif eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_UNDO,0,0
					.endif
				.endif
			.elseif eax==IDM_EDIT_REDO
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT || eax==ID_EDITHEX
						invoke SendMessage,ha.hEdt,EM_REDO,0,0
					.elseif eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_REDO,0,0
					.endif
				.endif
			.elseif eax==IDM_EDIT_CUT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT || eax==ID_EDITHEX
						invoke SendMessage,ha.hEdt,WM_CUT,0,0
					.elseif eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_CUT,0,0
					.endif
				.endif
			.elseif eax==IDM_EDIT_COPY
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT || eax==ID_EDITHEX
						invoke SendMessage,ha.hEdt,WM_COPY,0,0
					.elseif eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_COPY,0,0
					.endif
				.endif
			.elseif eax==IDM_EDIT_PASTE
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT || eax==ID_EDITHEX
						invoke SendMessage,ha.hEdt,WM_PASTE,0,0
					.elseif eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_PASTE,0,0
					.endif
				.endif
			.elseif eax==IDM_EDIT_DELETE
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT || eax==ID_EDITHEX
						invoke SendMessage,ha.hEdt,WM_CLEAR,0,0
					.elseif eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_DELETECONTROLS,0,0
					.endif
				.endif
			.elseif eax==IDM_EDIT_SELECTALL
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT || eax==ID_EDITHEX
						mov		chrg.cpMin,0
						mov		chrg.cpMax,-1
						invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
					.elseif eax==ID_EDITRES
						;invoke SendMessage,ha.hEdt,DEM_DELETECONTROLS,0,0
					.endif
				.endif
			.elseif eax==IDM_EDIT_FIND
			.elseif eax==IDM_EDIT_REPLACE
			.elseif eax==IDM_EDIT_INDENT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke IndentComment,ha.hEdt,VK_TAB,TRUE
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_EDIT_OUTDENT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke IndentComment,ha.hEdt,VK_TAB,FALSE
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_EDIT_COMMENT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke IndentComment,ha.hEdt,';',TRUE
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_EDIT_UNCOMMENT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke IndentComment,ha.hEdt,';',FALSE
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_EDIT_TOGGLEBM
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
						invoke SendMessage,ha.hEdt,EM_EXLINEFROMCHAR,0,chrg.cpMin
						mov		ebx,eax
						invoke SendMessage,ha.hEdt,REM_GETBOOKMARK,ebx,0
						.if eax==3
							invoke SendMessage,ha.hEdt,REM_SETBOOKMARK,ebx,0
						.elseif eax==0
							invoke SendMessage,ha.hEdt,REM_SETBOOKMARK,ebx,3
						.endif
					.elseif eax==ID_EDITHEX
						invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
						mov		eax,chrg.cpMin
						shr		eax,5
						invoke SendMessage,ha.hEdt,HEM_TOGGLEBOOKMARK,eax,0
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_EDIT_NEXTBM
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
						invoke SendMessage,ha.hEdt,EM_EXLINEFROMCHAR,0,chrg.cpMin
						mov		ebx,eax
						invoke SendMessage,ha.hEdt,REM_NXTBOOKMARK,ebx,3
						.if eax==-1
							invoke SendMessage,ha.hEdt,REM_NXTBOOKMARK,eax,3
						.endif
						.if eax!=-1
							invoke SendMessage,ha.hEdt,EM_LINEINDEX,eax,0
							mov		chrg.cpMin,eax
							mov		chrg.cpMax,eax
							invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
							invoke SendMessage,ha.hEdt,REM_VCENTER,0,0
							invoke SendMessage,ha.hEdt,EM_SCROLLCARET,0,0
						.endif
					.elseif eax==ID_EDITHEX
						invoke SendMessage,ha.hEdt,HEM_NEXTBOOKMARK,0,addr hebmk
						.if eax
							invoke GetParent,hebmk.hWin
							invoke TabToolGetInx,eax
							invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
							invoke TabToolActivate
							mov		eax,hebmk.nLine
							shl		eax,5
							mov		chrg.cpMin,eax
							mov		chrg.cpMax,eax
							invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
							invoke SendMessage,ha.hEdt,HEM_VCENTER,0,0
							invoke SetFocus,ha.hEdt
						.endif
					.endif
				.endif
			.elseif eax==IDM_EDIT_PREVBM
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
						invoke SendMessage,ha.hEdt,EM_EXLINEFROMCHAR,0,chrg.cpMin
						mov		ebx,eax
						invoke SendMessage,ha.hEdt,REM_PRVBOOKMARK,ebx,3
						.if eax==-1
							invoke SendMessage,ha.hEdt,EM_GETLINECOUNT,0,0
							inc		eax
							invoke SendMessage,ha.hEdt,REM_PRVBOOKMARK,eax,3
						.endif
						.if eax!=-1
							invoke SendMessage,ha.hEdt,EM_LINEINDEX,eax,0
							mov		chrg.cpMin,eax
							mov		chrg.cpMax,eax
							invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
							invoke SendMessage,ha.hEdt,REM_VCENTER,0,0
							invoke SendMessage,ha.hEdt,EM_SCROLLCARET,0,0
						.endif
					.elseif eax==ID_EDITHEX
						invoke SendMessage,ha.hEdt,HEM_PREVIOUSBOOKMARK,0,addr hebmk
						.if eax
							invoke GetParent,hebmk.hWin
							invoke TabToolGetInx,eax
							invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
							invoke TabToolActivate
							mov		eax,hebmk.nLine
							shl		eax,5
							mov		chrg.cpMin,eax
							mov		chrg.cpMax,eax
							invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
							invoke SendMessage,ha.hEdt,HEM_VCENTER,0,0
							invoke SetFocus,ha.hEdt
						.endif
					.endif
				.endif
			.elseif eax==IDM_EDIT_CLEARBM
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke SendMessage,ha.hEdt,REM_CLRBOOKMARKS,0,3
					.elseif eax==ID_EDITHEX
						invoke SendMessage,ha.hEdt,HEM_CLEARBOOKMARKS,0,0
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_VIEW_LOCK
				xor		da.fLockToolbar,TRUE
				invoke LockToolbars
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
			.elseif eax==IDM_FORMAT_LOCK
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ISLOCKED,0,0
						xor		eax,TRUE
						invoke SendMessage,ha.hEdt,DEM_LOCKCONTROLS,0,eax
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_FRONT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_BRINGTOFRONT,0,0
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_BACK
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_SENDTOBACK,0,0
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_SHOW
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke GetWindowLong,ha.hEdt,GWL_STYLE
						xor		eax,DES_GRID
						invoke SetWindowLong,ha.hEdt,GWL_STYLE,eax
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_SNAP
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke GetWindowLong,ha.hEdt,GWL_STYLE
						xor		eax,DES_SNAPTOGRID
						invoke SetWindowLong,ha.hEdt,GWL_STYLE,eax
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_ALIGNLEFT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,ALIGN_LEFT
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_ALIGNCENTER
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,ALIGN_CENTER
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_ALIGNRIGHT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,ALIGN_RIGHT
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_ALIGNTOP
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,ALIGN_TOP
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_ALIGNMIDDLE
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,ALIGN_MIDDLE
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_ALIGNBOTTOM
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,ALIGN_BOTTOM
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_SIZEWIDTH
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,SIZE_WIDTH
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_SIZEHEIGHT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,SIZE_HEIGHT
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_SIZEBOTH
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,SIZE_BOTH
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_CENTERHORIZONTAL
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,ALIGN_DLGHCENTER
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_CENTERVERTICAL
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_ALIGNSIZE,0,ALIGN_DLGVCENTER
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_FORMAT_INDEX
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITRES
						invoke SendMessage,ha.hEdt,DEM_SHOWTABINDEX,0,0
					.endif
					mov		da.fTimer,1
				.endif

			.elseif eax==IDM_PROJECT_NEW
			.elseif eax==IDM_PROJECT_OPEN
			.elseif eax==IDM_PROJECT_CLOSE
			.elseif eax==IDM_PROJECT_ADDFILE
			.elseif eax==IDM_PROJET_ADDEXISTING
			.elseif eax==IDM_PROJECT_ADDOPEN
			.elseif eax==IDM_PROJECT_ADDALLOPEN
			.elseif eax==IDM_PROJECT_ADDGROUP
			.elseif eax==IDM_PROJECT_REMOVEFILE
			.elseif eax==IDM_PROJECT_REMOVEGROUP
			.elseif eax==IDM_PROJECT_OPTION

			.elseif eax==IDM_RESOURCE_ADDDIALOG
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_DIALOG,TRUE
			.elseif eax==IDM_RESOURCE_ADDMENU
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_MENU,TRUE
			.elseif eax==IDM_RESOURCE_ADDACCELERATOR
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_ACCEL,TRUE
			.elseif eax==IDM_RESOURCE_ADDVERSION
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_VERSION,TRUE
			.elseif eax==IDM_RESOURCE_ADDSTRING
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_STRING,TRUE
			.elseif eax==IDM_RESOURCE_ADDMANIFEST
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_XPMANIFEST,TRUE
			.elseif eax==IDM_RESOURCE_ADDRCDATA
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_RCDATA,TRUE
			.elseif eax==IDM_RESOURCE_ADDTOLBAR
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_TOOLBAR,TRUE
			.elseif eax==IDM_RESOURCE_LANGUAGE
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_LANGUAGE,TRUE
			.elseif eax==IDM_RESOURCE_INCLUDE
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_INCLUDE,TRUE
			.elseif eax==IDM_RESOURCE_RESOURCE
				invoke SendMessage,ha.hEdt,PRO_ADDITEM,TPE_RESOURCE,TRUE
			.elseif eax==IDM_RESOURCE_NAMES
				invoke SendMessage,ha.hEdt,PRO_SHOWNAMES,0,ha.hOutput
			.elseif eax==IDM_RESOURCE_EXPORT
				invoke SendMessage,ha.hEdt,PRO_EXPORTNAMES,0,ha.hOutput
			.elseif eax==IDM_RESOURCE_REMOVE
				invoke SendMessage,ha.hEdt,PRO_DELITEM,0,0
			.elseif eax==IDM_RESOURCE_UNDO
				invoke SendMessage,ha.hEdt,PRO_UNDODELETED,0,0

			.elseif eax==IDM_MAKE_COMPILE
			.elseif eax==IDM_MAKE_ASSEMBLE
			.elseif eax==IDM_MAKE_MODULES
			.elseif eax==IDM_MAKE_LINK
			.elseif eax==IDM_MAKE_BUILD
			.elseif eax==IDM_MAKE_GO
			.elseif eax==IDM_MAKE_RUN
			.elseif eax==IDM_MAKE_DEBUG

			.elseif eax==IDM_DEBUG_TOGGLE
			.elseif eax==IDM_DEBUG_CLEAR
			.elseif eax==IDM_DEBUG_RUN
			.elseif eax==IDM_DEBUG_BREAK
			.elseif eax==IDM_DEBUG_STOP
			.elseif eax==IDM_DEBUG_INTO
			.elseif eax==IDM_DEBUG_OVER
			.elseif eax==IDM_DEBUG_CARET
			.elseif eax==IDM_DEBUG_NODEBUG

;			.elseif eax==IDM_WINDOW_CLOSE
;				.if ha.hMdi
;					invoke SendMessage,ha.hMdi,WM_CLOSE,0,0
;				.endif
			.elseif eax==IDM_WINDOW_CLOSEALL
				.if ha.hMdi
					invoke UpdateAll,UAM_SAVEALL,TRUE
					.if eax
						invoke UpdateAll,UAM_CLOSEALL,0
					.endif
				.endif
			.elseif eax==IDM_WINDOW_CLOSEALLBUT
				.if ha.hMdi
					invoke UpdateAll,UAM_SAVEALL,ha.hMdi
					.if eax
						invoke UpdateAll,UAM_CLOSEALL,ha.hMdi
					.endif
				.endif
			.elseif eax==IDM_WINDOW_HORIZONTAL
				.if ha.hMdi
					invoke SendMessage,ha.hClient,WM_MDITILE,MDITILE_HORIZONTAL,0
				.endif
			.elseif eax==IDM_WINDOW_VERTICAL
				.if ha.hMdi
					invoke SendMessage,ha.hClient,WM_MDITILE,MDITILE_VERTICAL,0
				.endif
			.elseif eax==IDM_WIDDOW_CASCADE
				.if ha.hMdi
					invoke SendMessage,ha.hClient,WM_MDICASCADE,0,0
				.endif
			.elseif eax==IDM_WINDOW_ICONS
				.if ha.hMdi
					invoke SendMessage,ha.hClient,WM_MDIICONARRANGE,0,0
				.endif
			.elseif eax==IDM_WINDOW_MAXIMIZE
				.if ha.hMdi
					invoke SendMessage,ha.hClient,WM_MDIMAXIMIZE,ha.hMdi,0
				.endif
			.elseif eax==IDM_WINDOW_RESTORE
				.if ha.hMdi
					invoke SendMessage,ha.hClient,WM_MDIRESTORE,ha.hMdi,0
				.endif
			.elseif eax==IDM_WINDOW_MINIMIZE
				.if ha.hMdi
					invoke ShowWindow,ha.hMdi,SW_MINIMIZE
				.endif
			.else
				jmp		ExDef
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke UpdateAll,UAM_SAVEALL,TRUE
		.if eax
			invoke SendMessage,ha.hFileBrowser,FBM_GETPATH,0,addr da.szFBPath
			invoke SaveTools
			invoke SaveReBar
			invoke PutSession
			invoke PutWinPos
			invoke UpdateAll,UAM_CLOSEALL,0
			jmp		ExDef
		.else
			jmp		Ex
		.endif
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
			invoke UpdateAll,UAM_ISOPENACTIVATE,[esi].FBNOTIFY.lpfile
			.if eax==-1
				invoke OpenTheFile,[esi].FBNOTIFY.lpfile,0
			.endif
		.endif
	.elseif eax==WM_INITMENUPOPUP
		mov		eax,lParam
		mov		edx,eax
		shr		eax,16
		.if !eax
			.if da.win.fcldmax && ha.hEdt
				dec		edx
			.endif
			invoke EnableMenu,wParam,edx
		.endif
	.elseif eax==WM_CONTEXTMENU
		mov		eax,lParam
		.if eax!=-1
			movsx	eax,ax
			mov		pt.x,eax
			mov		eax,lParam
			shr		eax,16
			movsx	eax,ax
			mov		pt.y,eax
		.else
			invoke GetWindowRect,ha.hClient,addr rect
			mov		eax,rect.left
			add		eax,10
			mov		pt.x,eax
			mov		eax,rect.top
			add		eax,10
			mov		pt.y,eax
		.endif
		mov		eax,wParam
		.if eax==ha.hToolProject
PrintText "Pro"
		.elseif eax==ha.hToolProperties
PrintText "Prp"
		.elseif eax==ha.hToolOutput
PrintText "Out"
		.elseif eax==ha.hToolTab
PrintText "Tab"
		.elseif eax==ha.hReBar
PrintText "Rab"
		.else
PrintText "???"
		.endif

;mov eax,ha.hEdt
;PrintHex eax
;mov eax,ha.hClient
;PrintHex eax
;		mov		eax,wParam
;PrintHex wParam
;		.if eax==ha.hEdt
;			mov		eax,1
;			add		eax,da.win.fcldmax
;			invoke GetSubMenu,ha.hMenu,eax
;			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWin,0
;		.endif
	.elseif eax==WM_TOOLSIZE
		mov		eax,wParam
		mov		esi,lParam
		.if eax==ha.hToolProject
			invoke MoveWindow,ha.hTabProject,0,0,[esi].RECT.right,20,TRUE
			sub		[esi].RECT.bottom,20
			invoke MoveWindow,ha.hFileBrowser,0,20,[esi].RECT.right,[esi].RECT.bottom,TRUE
			invoke MoveWindow,ha.hProjectBrowser,0,20,[esi].RECT.right,[esi].RECT.bottom,TRUE
		.elseif eax==ha.hToolProperties
			invoke MoveWindow,ha.hProperty,0,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
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
	LOCAL	pt:POINT
	LOCAL	nBP:DWORD

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,mdiID
		.if eax==ID_EDITCODE
			invoke CreateWindowEx,0,addr szRAEditClass,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or STYLE_DRAGDROP or STYLE_SCROLLTIP or STYLE_HILITECOMMENT or STYLE_AUTOSIZELINENUM,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,REM_SETFONT,0,addr ha.racf
			invoke SendMessage,hEdt,REM_SETCOLOR,0,addr da.radcolor.racol
			invoke SendMessage,hEdt,REM_SETSTYLEEX,STYLEEX_BLOCKGUIDE or STILEEX_LINECHANGED,0
			invoke SendMessage,hEdt,REM_TABWIDTH,da.edtopt.tabsize,da.edtopt.exptabs
			invoke SendMessage,hEdt,REM_AUTOINDENT,0,da.edtopt.indent
			.if da.edtopt.linenumber
				invoke CheckDlgButton,hEdt,-2,TRUE
				invoke SendMessage,hEdt,WM_COMMAND,-2,0
			.endif
		.elseif eax==ID_EDITTEXT
			invoke CreateWindowEx,0,addr szRAEditClass,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or STYLE_DRAGDROP or STYLE_SCROLLTIP or STYLE_NOCOLLAPSE or STYLE_NOHILITE or STYLE_AUTOSIZELINENUM,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,REM_SETFONT,0,addr ha.ratf
			invoke SendMessage,hEdt,REM_SETCOLOR,0,addr da.radcolor.racol
			invoke SendMessage,hEdt,REM_TABWIDTH,da.edtopt.tabsize,da.edtopt.exptabs
			invoke SendMessage,hEdt,REM_AUTOINDENT,0,0
		.elseif eax==ID_EDITHEX
			invoke CreateWindowEx,0,addr szRAHexEdClassName,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,HEM_SETFONT,0,addr ha.rahf
		.elseif eax==ID_EDITRES
			invoke CreateWindowEx,0,addr szResEdClass,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or DES_GRID or DES_SNAPTOGRID or DES_TOOLTIP or DES_STYLEHEX,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,DEM_SETSIZE,0,addr da.winres
			invoke SendMessage,hEdt,WM_SETFONT,ha.hToolFont,FALSE
			invoke SendMessage,hEdt,DEM_SETPOSSTATUS,ha.hStatus,0
		.elseif eax==ID_EDITUSER
			mov		hEdt,0
		.endif
		invoke SetWindowLong,hWin,GWL_USERDATA,hEdt
		invoke SetWindowText,hWin,addr da.szFileName
		invoke TabToolAdd,hWin,addr da.szFileName
		xor		eax,eax
		jmp		Ex
	.elseif eax==WM_SIZE
		mov		eax,hWin
		.if eax==ha.hMdi
			mov		eax,wParam
			.if eax==SIZE_MAXIMIZED
				mov		da.win.fcldmax,TRUE
			.elseif eax==SIZE_RESTORED || eax==SIZE_MINIMIZED
				mov		da.win.fcldmax,FALSE
			.endif
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
			invoke SendMessage,ha.hStatus,SB_SETTEXT,0,addr szNULL
			invoke TabToolGetInx,hWin
			invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
			invoke TabToolActivate
		.elseif eax==wParam
			;Deactivate
			mov		ha.hMdi,0
			mov		ha.hEdt,0
			mov		da.szFileName,0
		.endif
	.elseif eax==WM_CLOSE
		invoke WantToSave,hWin
		.if !eax
			invoke GetWindowLong,hWin,GWL_USERDATA
			mov		hEdt,eax
			invoke GetWindowLong,hEdt,GWL_ID
			.if eax==ID_EDITCODE
				.if !da.fProject
					invoke SendMessage,ha.hProperty,PRM_DELPROPERTY,hEdt,0
					invoke SendMessage,ha.hProperty,PRM_REFRESHLIST,0,0
				.endif
			.elseif eax==ID_EDITTEXT
			.elseif eax==ID_EDITHEX
			.elseif eax==ID_EDITRES
				invoke SendMessage,hEdt,DEM_GETSIZE,0,addr da.winres
				invoke SendMessage,hEdt,PRO_CLOSE,0,0
			.endif
			invoke DestroyWindow,hEdt
			invoke TabToolDel,hWin
		.else
			xor		eax,eax
			jmp		Ex
		.endif
	.elseif eax==WM_NOTIFY
		mov		esi,lParam
		;Get TABMEM
		invoke GetWindowLong,[esi].NMHDR.hwndFrom,GWL_USERDATA
		mov		ebx,eax
		mov		eax,wParam
		.if eax==ID_EDITCODE
			.if [esi].NMHDR.code==EN_SELCHANGE
				mov		eax,[esi].RASELCHANGE.chrg.cpMin
				sub		eax,[esi].RASELCHANGE.cpLine
				invoke ShowPos,[esi].RASELCHANGE.line,eax
				.if [esi].RASELCHANGE.seltyp==SEL_OBJECT
					mov		edi,[esi].RASELCHANGE.line
					invoke SendMessage,[ebx].TABMEM.hedt,REM_GETBOOKMARK,edi,0
					.if eax==1
						;Collapse
						invoke GetKeyState,VK_CONTROL
						test	eax,80h
						.if ZERO?
							invoke SendMessage,[ebx].TABMEM.hedt,REM_COLLAPSE,edi,0
						.else
							invoke SendMessage,[ebx].TABMEM.hedt,REM_GETBLOCKEND,edi,0
							.if eax!=-1
								push	esi
								dec		eax
								mov		esi,edi
								mov		edi,eax
								.while edi>=esi && edi!=-1
									invoke SendMessage,[ebx].TABMEM.hedt,REM_COLLAPSE,edi,0
									invoke SendMessage,[ebx].TABMEM.hedt,REM_PRVBOOKMARK,edi,1
									mov		edi,eax
								.endw
								pop		esi
							.endif
						.endif
					.elseif eax==2
						;Expand
						invoke GetKeyState,VK_CONTROL
						test	eax,80h
						.if ZERO?
							invoke SendMessage,[ebx].TABMEM.hedt,REM_EXPAND,edi,0
						.else
							invoke SendMessage,[ebx].TABMEM.hedt,REM_GETBLOCKEND,edi,0
							.if eax!=-1
								push	esi
								mov		esi,eax
								.while edi<esi
									invoke SendMessage,[ebx].TABMEM.hedt,REM_EXPAND,edi,0
									invoke SendMessage,[ebx].TABMEM.hedt,REM_NXTBOOKMARK,edi,2
									mov		edi,eax
								.endw
								pop		esi
							.endif
						.endif
					.elseif eax==8
						;Expand hidden lines
						invoke SendMessage,[ebx].TABMEM.hedt,REM_EXPAND,edi,0
					.else
						;Clear bookmark
						invoke SendMessage,[ebx].TABMEM.hedt,REM_SETBOOKMARK,edi,0
					.endif
				.elseif[esi].RASELCHANGE.seltyp==SEL_TEXT
					invoke SendMessage,[ebx].TABMEM.hedt,REM_BRACKETMATCH,0,0
					.if [esi].RASELCHANGE.fchanged
						.if ![ebx].TABMEM.fchanged
							invoke TabToolSetChanged,[ebx].TABMEM.hwnd,TRUE
						.endif
						invoke SendMessage,[ebx].TABMEM.hedt,REM_SETCOMMENTBLOCKS,addr da.szCmntStart,addr da.szCmntEnd

						invoke SendMessage,[ebx].TABMEM.hedt,WM_GETTEXTLENGTH,0,0
						.if eax!=da.nLastSize
							push	eax
							sub		eax,da.nLastSize
;							invoke UpdateGoto,ha.hREd,[esi].RASELCHANGE.chrg.cpMin,eax
							pop		da.nLastSize
						.endif
					  OnceMore:
						invoke SendMessage,[ebx].TABMEM.hedt,REM_GETBOOKMARK,da.nLastLine,0
						mov		nBP,eax
						mov		edi,offset da.rabd
						or		eax,-1
						.while [edi].RABLOCKDEF.lpszStart
							mov		edx,[edi].RABLOCKDEF.flag
							shr		edx,16
							.if edx==[esi].RASELCHANGE.nWordGroup
								invoke SendMessage,[ebx].TABMEM.hedt,REM_ISLINE,da.nLastLine,[edi].RABLOCKDEF.lpszStart
								.break .if eax!=-1
							.endif
							lea		edi,[edi+sizeof RABLOCKDEF]
						.endw
						.if eax==-1
							.if nBP==1 || nBP==2
								;Clear bookmark
								.if nBP==2
									invoke SendMessage,[ebx].TABMEM.hedt,REM_EXPAND,da.nLastLine,0
								.endif
								invoke SendMessage,[ebx].TABMEM.hedt,REM_SETBOOKMARK,da.nLastLine,0
								invoke SendMessage,[ebx].TABMEM.hedt,REM_SETDIVIDERLINE,da.nLastLine,FALSE
								invoke SendMessage,[ebx].TABMEM.hedt,REM_SETSEGMENTBLOCK,da.nLastLine,FALSE
							.endif
						.elseif [edi].RABLOCKDEF.lpszStart
							xor		eax,eax
							test	[edi].RABLOCKDEF.flag,BD_NONESTING
							.if !ZERO?
								invoke SendMessage,[ebx].TABMEM.hedt,REM_ISINBLOCK,da.nLastLine,edi
							.endif
							.if !eax
								;Set bookmark
								mov		edx,da.nLastLine
								inc		edx
								invoke SendMessage,[ebx].TABMEM.hedt,REM_ISLINEHIDDEN,edx,0
								.if eax
									invoke SendMessage,[ebx].TABMEM.hedt,REM_SETBOOKMARK,da.nLastLine,2
								.else
									invoke SendMessage,[ebx].TABMEM.hedt,REM_SETBOOKMARK,da.nLastLine,1
								.endif
								mov		edx,[edi].RABLOCKDEF.flag
								and		edx,BD_DIVIDERLINE
								invoke SendMessage,[ebx].TABMEM.hedt,REM_SETDIVIDERLINE,da.nLastLine,edx
								mov		edx,[edi].RABLOCKDEF.flag
								and		edx,BD_SEGMENTBLOCK
								invoke SendMessage,[ebx].TABMEM.hedt,REM_SETSEGMENTBLOCK,da.nLastLine,edx
							.endif
						.endif
						mov		eax,[esi].RASELCHANGE.line
						.if eax>da.nLastLine
							inc		da.nLastLine
							jmp		OnceMore
						.elseif eax<da.nLastLine
							dec		da.nLastLine
							jmp		OnceMore
						.endif
						.if ![esi].RASELCHANGE.nWordGroup
							.if !da.inprogress
;								invoke ApiListBox,esi
							.endif
							mov		[ebx].TABMEM.fupdate,TRUE
						.endif
					.endif
					mov		eax,[esi].RASELCHANGE.line
					mov		da.nLastLine,eax
					.if eax!=da.nLastPropLine
						mov		da.nLastPropLine,eax
						invoke ShowWindow,ha.hCC,SW_HIDE
						invoke ShowWindow,ha.hTT,SW_HIDE
						mov		da.cctype,CCTYPE_NONE
						.if ![esi].RASELCHANGE.nWordGroup
							.if [ebx].TABMEM.fupdate
								mov		[ebx].TABMEM.fupdate,FALSE
								invoke ParseEdit,[ebx].TABMEM.hedt,[ebx].TABMEM.pid
							.endif
						.endif
					.elseif da.cctype==CCTYPE_ALL
						.if !da.inprogress
;							invoke ApiListBox,esi
						.endif
					.endif
				.endif
				mov		da.fTimer,1
			.endif
		.elseif eax==ID_EDITTEXT
			.if [esi].NMHDR.code==EN_SELCHANGE
				mov		eax,[esi].RASELCHANGE.chrg.cpMin
				sub		eax,[esi].RASELCHANGE.cpLine
				invoke ShowPos,[esi].RASELCHANGE.line,eax
				.if[esi].RASELCHANGE.seltyp==SEL_TEXT
					.if [esi].RASELCHANGE.fchanged && ![ebx].TABMEM.fchanged
						invoke TabToolSetChanged,[ebx].TABMEM.hwnd,TRUE
					.endif
				.endif
				mov		da.fTimer,1
			.endif
		.elseif eax==ID_EDITHEX
			.if [esi].NMHDR.code==EN_SELCHANGE
				invoke SendMessage,[ebx].TABMEM.hedt,EM_LINEINDEX,[esi].HESELCHANGE.line,0
				mov		edx,[esi].HESELCHANGE.chrg.cpMin
				sub		edx,eax
				invoke ShowPos,[esi].HESELCHANGE.line,edx
				.if[esi].HESELCHANGE.seltyp==SEL_TEXT
					.if [esi].HESELCHANGE.fchanged && ![ebx].TABMEM.fchanged
						invoke TabToolSetChanged,[ebx].TABMEM.hwnd,TRUE
					.endif
				.endif
				mov		da.fTimer,1
			.endif
		.elseif eax==ID_EDITRES
			.if !da.inprogress
				mov		da.inprogress,TRUE
				invoke SendMessage,[esi].NMHDR.hwndFrom,PRO_GETMODIFY,0,0
				.if eax && ![ebx].TABMEM.fchanged
					invoke TabToolSetChanged,[ebx].TABMEM.hwnd,TRUE
				.endif
				mov		da.fTimer,1
				mov		da.inprogress,FALSE
			.endif
		.elseif eax==ID_EDITUSER
		.endif
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		movsx	eax,ax
		.if eax==-3
			;Expand All
			invoke SendMessage,ha.hEdt,REM_EXPANDALL,0,0
			invoke SendMessage,ha.hEdt,EM_SCROLLCARET,0,0
			invoke SendMessage,ha.hEdt,REM_REPAINT,0,0
		.elseif eax==-4
			;Collapse All
			invoke SendMessage,ha.hEdt,REM_COLLAPSEALL,0,0
			invoke SendMessage,ha.hEdt,EM_SCROLLCARET,0,0
			invoke SendMessage,ha.hEdt,REM_REPAINT,0,0
		.endif
	.elseif eax==WM_CONTEXTMENU
		mov		eax,lParam
		.if eax!=-1
			movsx	eax,ax
			mov		pt.x,eax
			mov		eax,lParam
			shr		eax,16
			movsx	eax,ax
			mov		pt.y,eax
		.else
			invoke GetWindowRect,ha.hClient,addr rect
			mov		eax,rect.left
			add		eax,10
			mov		pt.x,eax
			mov		eax,rect.top
			add		eax,10
			mov		pt.y,eax
		.endif
		mov		eax,wParam
		.if eax!=ha.hEdt
			invoke GetParent,eax
		.endif
		.if eax==ha.hEdt
			invoke GetWindowLong,ha.hEdt,GWL_ID
			.if eax==ID_EDITCODE || eax==ID_EDITTEXT || eax==ID_EDITHEX
				;Edit menu
				mov		ebx,1
				invoke EnableMenu,ha.hMenu,ebx
				add		ebx,da.win.fcldmax
				invoke GetSubMenu,ha.hMenu,ebx
				invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,ha.hWnd,0
			.elseif eax==ID_EDITRES
				;Resource contextmenu
				invoke EnableContextMenu,ha.hContextMenu,0
				invoke GetSubMenu,ha.hContextMenu,0
				invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,ha.hWnd,0
			.endif
		.endif
		xor		eax,eax
		jmp		Ex
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
	invoke GetModuleFileName,ha.hInstance,addr da.szAppPath,sizeof da.szAppPath
	invoke strlen,addr da.szAppPath
	.while da.szAppPath[eax]!='\'
		dec		eax
	.endw
	mov		da.szAppPath[eax],0
	invoke strcpy,addr da.szRadASMIni,addr da.szAppPath
	invoke strcat,addr da.szRadASMIni,addr szBS
	invoke strcat,addr da.szRadASMIni,addr szInifile
	invoke GetPrivateProfileString,addr szIniWin,addr szIniAppPath,NULL,addr tmpbuff,sizeof tmpbuff,addr da.szRadASMIni
	.if eax
		xor		eax,eax
		.if tmpbuff=='\'
			mov		eax,2
		.endif
		invoke strcpy,addr da.szAppPath[eax],addr tmpbuff
		invoke strcpy,addr da.szRadASMIni,addr da.szAppPath
		invoke strcat,addr da.szRadASMIni,addr szBS
		invoke strcat,addr da.szRadASMIni,addr szInifile
	.endif
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
	invoke GetSessionFiles
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
					invoke TranslateAccelerator,ha.hWnd,ha.hAccel,addr msg
					.if !eax
						invoke TranslateMessage,addr msg
						invoke DispatchMessage,addr msg
					.endif
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
	invoke InitCommonControls
	;prepare common control structure
	mov		icex.dwSize,sizeof INITCOMMONCONTROLSEX
	mov		icex.dwICC,ICC_DATE_CLASSES or ICC_USEREX_CLASSES or ICC_INTERNET_CLASSES or ICC_ANIMATE_CLASS or ICC_HOTKEY_CLASS or ICC_PAGESCROLLER_CLASS or ICC_COOL_CLASSES
	invoke InitCommonControlsEx,addr icex
	invoke OleInitialize,NULL
	invoke LoadLibrary,offset szRichEdit
	mov		hRichEd,eax
	;Install custom controls
	invoke InstallRACodeComplete,ha.hInstance,FALSE
	invoke InstallFileBrowser,ha.hInstance,FALSE
	invoke InstallProjectBrowser,ha.hInstance,FALSE
	invoke InstallRAProperty,ha.hInstance,FALSE
	invoke InstallRATools,ha.hInstance,FALSE
	invoke InstallRAEdit,ha.hInstance,FALSE
	invoke RAHexEdInstall,ha.hInstance,FALSE
	invoke ResEdInstall,ha.hInstance,FALSE
	invoke GridInstall,ha.hInstance,FALSE
	invoke GetCharTabPtr
	mov		da.lpCharTab,eax
	invoke WinMain,ha.hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	;Uninstall custom controls
	invoke GridUnInstall
	invoke ResEdUninstall
	invoke RAHexEdUnInstall
	invoke UnInstallRAEdit
	invoke UnInstallRATools
	invoke UnInstallRAProperty
	invoke UnInstallProjectBrowser
	invoke UnInstallFileBrowser
	invoke UnInstallRACodeComplete
	.if hRichEd
		invoke FreeLibrary,hRichEd
	.endif
	invoke OleUninitialize
	invoke ExitProcess,0

end start
