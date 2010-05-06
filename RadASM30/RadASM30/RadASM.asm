.486
.model flat, stdcall  ; 32 bit memory model
option casemap :none  ; case sensitive

include RadASM.inc
include Misc.asm
include IniFile.asm
include Tools.asm
include TabTool.asm
include Assembler.asm
include Project.asm
include FileIO.asm
include CodeComplete.asm
include KeyWords.asm
include TabOptions.asm
include Make.asm
include Option.asm
include Environment.asm
include About.asm
include ProjectOption.asm
include Find.asm
include Block.asm

.code

TimerProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	.if da.fTimer
		dec		da.fTimer
		.if ZERO?
			invoke EnableToolBar
			invoke ShowProc,da.nLastLine
		.endif
	.endif
	ret

TimerProc endp

MakeMdiCldWin proc ID:DWORD,pid:DWORD
	LOCAL	fi:FILEINFO
	LOCAL	rect:RECT

	.if pid
		.if da.fProject
			invoke GetFileInfo,pid,addr szIniProject,addr da.szProjectFile,addr fi
		.else
			invoke GetFileInfo,pid,addr szIniSession,addr da.szRadASMIni,addr fi
		.endif
		.if eax
			mov		eax,fi.rect.left
			mov		rect.left,eax
			mov		eax,fi.rect.top
			mov		rect.top,eax
			mov		eax,fi.rect.right
			mov		rect.right,eax
			mov		eax,fi.rect.bottom
			mov		rect.bottom,eax
		.else
			mov		eax,CW_USEDEFAULT
			mov		rect.left,eax
			mov		rect.top,eax
			mov		rect.right,eax
			mov		rect.bottom,eax
		.endif
	.else
		mov		eax,CW_USEDEFAULT
		mov		rect.left,eax
		mov		rect.top,eax
		mov		rect.right,eax
		mov		rect.bottom,eax
	.endif
	mov		eax,ID
	mov		mdiID,eax
	mov		edx,WS_EX_MDICHILD
	.if eax!=ID_EDITRES
		mov		edx,WS_EX_CLIENTEDGE or WS_EX_MDICHILD
	.endif
	mov		eax,MDIS_ALLCHILDSTYLES or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
	.if da.win.fcldmax
		or		eax,WS_MAXIMIZE
	.endif
	invoke CreateWindowEx,edx,addr szEditCldClassName,NULL,eax,rect.left,rect.top,rect.right,rect.bottom,ha.hClient,NULL,ha.hInstance,NULL
	ret

MakeMdiCldWin endp

ClientProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_MDIMAXIMIZE
	.elseif eax==WM_MDIRESTORE
	.endif
	invoke CallWindowProc,lpOldClientProc,hWin,uMsg,wParam,lParam
	ret

ClientProc endp

WndProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL   cc:CLIENTCREATESTRUCT
	LOCAL	rect:RECT
	LOCAL	pt:POINT
	LOCAL	ps:PAINTSTRUCT
	LOCAL	chrg:CHARRANGE
	LOCAL	trng:TEXTRANGE
	LOCAL	hebmk:HEBMK
	LOCAL	mii:MENUITEMINFO
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov da.inprogress,TRUE
		mov		eax,hWin
		mov		ha.hWnd,eax
		;Mdi Client
		mov		cc.hWindowMenu,0
		mov		cc.idFirstChild,ID_FIRSTCHILD
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,addr szMdiClientClassName,NULL,WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_HSCROLL or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,hWin,NULL,ha.hInstance,addr cc
		mov     ha.hClient,eax
		invoke SetWindowLong,ha.hClient,GWL_WNDPROC,offset ClientProc
		mov		lpOldClientProc,eax
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
		;Menu
		invoke LoadMenu,ha.hInstance,IDR_MENU
		mov		ha.hMenu,eax
		invoke LoadMenu,ha.hInstance,IDR_CONTEXTMENU
		mov		ha.hContextMenu,eax
		invoke GetSubMenu,ha.hMenu,9
		invoke SendMessage,ha.hClient,WM_MDISETMENU,ha.hMenu,eax
		invoke SendMessage,ha.hClient,WM_MDIREFRESHMENU,0,0
		invoke DrawMenuBar,hWin
		;Create tool windows
		invoke CreateTools
		invoke SendMessage,ha.hFileBrowser,FBM_GETIMAGELIST,0,0
		invoke SendMessage,ha.hTab,TCM_SETIMAGELIST,0,eax
		;Create code complete
		invoke CreateCodeComplete
		;Get assemblers
		invoke GetPrivateProfileString,addr szIniAssembler,addr szIniAssembler,addr szMasm,addr da.szAssemblers,sizeof da.szAssemblers,addr da.szRadASMIni
		;Get default assembler
		invoke strcpy,addr tmpbuff,addr da.szAssemblers
		invoke GetItemStr,addr tmpbuff,addr szMasm,addr da.szAssembler,sizeof da.szAssembler
		invoke OpenAssembler
		invoke strcpy,addr da.szFBPath,addr da.szAppPath
		invoke SendMessage,ha.hFileBrowser,FBM_SETPATH,TRUE,addr da.szFBPath
		invoke ImageList_Create,16,16,ILC_COLOR4 or ILC_MASK,4,0
		mov     ha.hMnuIml,eax
		invoke LoadBitmap,ha.hInstance,IDB_MNUARROW
		push	eax
		invoke ImageList_AddMasked,ha.hMnuIml,eax,0C0C0C0h
		pop		eax
		invoke DeleteObject,eax
		invoke SetTimer,hWin,200,200,addr TimerProc
		mov da.inprogress,FALSE
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movsx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED || edx==1
			.if eax==IDM_FILE_NEW
				invoke strcpy,addr da.szFileName,addr szNewFile
				invoke MakeMdiCldWin,ID_EDITCODE,0
			.elseif eax==IDM_FILE_OPEN
				invoke OpenEditFile,0
			.elseif eax==IDM_FILE_OPENHEX
				invoke OpenEditFile,ID_EDITHEX
			.elseif eax==IDM_FILE_REOPEN
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_USERDATA
					mov		ebx,eax
					.if [ebx].TABMEM.fchanged
						invoke strcpy,addr tmpbuff,addr szFileChanged
						invoke strcat,addr tmpbuff,addr [ebx].TABMEM.filename
						invoke MessageBox,hWin,addr tmpbuff,addr DisplayName,MB_YESNO or MB_ICONQUESTION
						.if eax==IDNO
							jmp		Ex
						.endif
					.endif
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
			.elseif (eax>=IDM_FILE_RECENTFILESSTART && eax<IDM_FILE_RECENTFILESSTART+10) || (eax>=IDM_FILE_RECENTPROJECTSSTART && eax<IDM_FILE_RECENTPROJECTSSTART+10)
				invoke OpenMRU,eax
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
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						.if ha.hFind
							invoke SetFocus,ha.hFind
						.else
							invoke CreateDialogParam,ha.hInstance,IDD_DLGFIND,hWin,offset FindDialogProc,FALSE
						.endif
					.endif
				.endif
			.elseif eax==IDM_EDIT_FINDNEXT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						.if !szfind
							.if ha.hFind
								invoke SetFocus,ha.hFind
							.else
								invoke CreateDialogParam,ha.hInstance,IDD_DLGFIND,hWin,offset FindDialogProc,FALSE
							.endif
						.else
							invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr da.find.ft.chrg
							mov		eax,da.find.ft.chrg.cpMax
							mov		da.find.ft.chrg.cpMin,eax
							mov		da.find.ft.chrg.cpMax,-1
							mov		eax,da.find.fr
							or		eax,FR_DOWN
							invoke SendMessage,ha.hEdt,EM_FINDTEXTEX,eax,offset da.find.ft
							.if eax!=-1
								invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,offset da.find.ft.chrgText
								invoke SendMessage,ha.hEdt,REM_VCENTER,0,0
								invoke SendMessage,ha.hEdt,EM_SCROLLCARET,0,0
								invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr da.find.ft.chrgText
							.endif
						.endif
					.endif
				.endif
			.elseif eax==IDM_EDIT_FINDPREV
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						.if !szfind
							.if ha.hFind
								invoke SetFocus,ha.hFind
							.else
								invoke CreateDialogParam,ha.hInstance,IDD_DLGFIND,hWin,offset FindDialogProc,FALSE
							.endif
						.else
							invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr da.find.ft.chrg
							mov		eax,da.find.ft.chrg.cpMin
							.if eax
								dec		eax
							.endif
							mov		da.find.ft.chrg.cpMin,eax
							mov		da.find.ft.chrg.cpMax,0
							mov		eax,da.find.fr
							and		eax,-1 xor FR_DOWN
							invoke SendMessage,ha.hEdt,EM_FINDTEXTEX,eax,offset da.find.ft
							.if eax!=-1
								invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,offset da.find.ft.chrgText
								invoke SendMessage,ha.hEdt,REM_VCENTER,0,0
								invoke SendMessage,ha.hEdt,EM_SCROLLCARET,0,0
								invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr da.find.ft.chrgText
							.endif
						.endif
					.endif
				.endif
			.elseif eax==IDM_EDIT_REPLACE
				.if ha.hFind
					invoke SetFocus,ha.hFind
				.else
					invoke CreateDialogParam,ha.hInstance,IDD_DLGFIND,hWin,offset FindDialogProc,TRUE
				.endif
			.elseif eax==IDM_EDIT_GOTODECLARE
				invoke GotoDeclare
			.elseif eax==IDM_EDIT_RETURN
				invoke ReturnDeclare
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
			.elseif eax==IDM_EDIT_BLOCKMODE
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke SendMessage,ha.hEdt,REM_GETMODE,0,0
						xor		eax,MODE_BLOCK
						invoke SendMessage,ha.hEdt,REM_SETMODE,eax,0
						mov		da.fTimer,1
					.endif
				.endif
			.elseif eax==IDM_EDIT_BLOCKINSERT
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke SendMessage,ha.hEdt,REM_GETMODE,0,0
						test	eax,MODE_BLOCK
						.if !ZERO?
							invoke DialogBoxParam,ha.hInstance,IDD_BLOCKDLG,hWin,offset BlockInsertProc,0
							mov		da.fTimer,1
						.endif
					.endif
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
				invoke SendMessage,ha.hTool,TLM_GETVISIBLE,0,ha.hToolProject
				invoke SendMessage,ha.hTbrView,TB_CHECKBUTTON,IDM_VIEW_PROJECT,eax
			.elseif eax==IDM_VIEW_OUTPUT
				invoke SendMessage,ha.hTool,TLM_HIDE,0,ha.hToolOutput
				invoke SendMessage,ha.hTool,TLM_GETVISIBLE,0,ha.hToolOutput
				invoke SendMessage,ha.hTbrView,TB_CHECKBUTTON,IDM_VIEW_OUTPUT,eax
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
				invoke DialogBoxParam,ha.hInstance,IDD_DLGNEWPROJECT,hWin,offset NewProjectProc,0
			.elseif eax==IDM_PROJECT_OPEN
				invoke OpenEditFile,ID_PROJECT
			.elseif eax==IDM_PROJECT_CLOSE
				.if da.fProject
					invoke CloseProject
				.endif
			.elseif eax==IDM_PROJECT_ADDNEWFILE
				.if da.fProject
					invoke AddNewProjectFile
				.endif
			.elseif eax==IDM_PROJET_ADDEXISTING
				.if da.fProject
					invoke AddExistingProjectFiles
				.endif
			.elseif eax==IDM_PROJECT_ADDOPEN
				.if da.fProject && ha.hMdi
					invoke AddOpenProjectFile
				.endif
			.elseif eax==IDM_PROJECT_ADDALLOPEN
				.if da.fProject && ha.hMdi
					invoke AddAllOpenProjectFiles
				.endif
			.elseif eax==IDM_PROJECT_ADDGROUP
				.if da.fProject
					invoke SendMessage,ha.hProjectBrowser,RPBM_ADDNEWGROUP,0,0
				.endif
			.elseif eax==IDM_PROJECT_REMOVEFILE
				.if da.fProject
					invoke RemoveProjectFile
				.endif
			.elseif eax==IDM_PROJECT_REMOVEGROUP
				.if da.fProject
					invoke SendMessage,ha.hProjectBrowser,RPBM_DELETEITEM,0,0
				.endif
			.elseif eax==IDM_PROJECT_EDITFILE
				.if da.fProject
					invoke SendMessage,ha.hProjectBrowser,RPBM_EDITITEM,0,0
				.endif
			.elseif eax==IDM_PROJECT_EDITGROUP
				.if da.fProject
					invoke SendMessage,ha.hProjectBrowser,RPBM_EDITITEM,0,0
				.endif
			.elseif eax==IDM_PROJECT_OPENITEMFILE
				.if da.fProject
					invoke OpenProjectItemFile
				.endif
			.elseif eax==IDM_PROJECT_OPENITEMGROUP
				.if da.fProject
					invoke OpenProjectItemGroup
				.endif
			.elseif eax==IDM_PROJECT_OPTION
				.if da.fProject
					invoke DialogBoxParam,ha.hInstance,IDD_DLGPO,hWin,offset ProjectOptionProc,0
				.endif
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
				invoke UpdateAll,UAM_CLEARERRORS,0
				invoke UpdateAll,UAM_SAVEALL,FALSE
				invoke OutputMake,IDM_MAKE_COMPILE,1
			.elseif eax==IDM_MAKE_ASSEMBLE
				invoke UpdateAll,UAM_CLEARERRORS,0
				invoke UpdateAll,UAM_SAVEALL,FALSE
				invoke OutputMake,IDM_MAKE_ASSEMBLE,1
			.elseif eax==IDM_MAKE_MODULES
				.if da.fProject
					invoke UpdateAll,UAM_CLEARERRORS,0
					invoke UpdateAll,UAM_SAVEALL,FALSE
					invoke OutputMake,IDM_MAKE_MODULES,1
				.endif
			.elseif eax==IDM_MAKE_LINK
				invoke UpdateAll,UAM_CLEARERRORS,0
				invoke UpdateAll,UAM_SAVEALL,FALSE
				invoke OutputMake,IDM_MAKE_LINK,1
			.elseif eax==IDM_MAKE_BUILD
				invoke UpdateAll,UAM_CLEARERRORS,0
				invoke UpdateAll,UAM_SAVEALL,FALSE
				;Get relative pointer to selected build command
				invoke SendMessage,ha.hCboBuild,CB_GETCURSEL,0,0
				mov		edx,sizeof MAKE
				mul		edx
				mov		edi,eax
				.if da.szMainRC && da.make.szCompileRC[edi]
					invoke OutputMake,IDM_MAKE_COMPILE,2
					.if !eax
						invoke OutputMake,IDM_MAKE_ASSEMBLE,0
						.if !eax
							invoke OutputMake,IDM_MAKE_LINK,3
						.endif
					.endif
				.else
					invoke OutputMake,IDM_MAKE_ASSEMBLE,2
					.if !eax
						invoke OutputMake,IDM_MAKE_LINK,3
					.endif
				.endif
			.elseif eax==IDM_MAKE_GO
				invoke UpdateAll,UAM_CLEARERRORS,0
				invoke UpdateAll,UAM_SAVEALL,FALSE
				.if da.szMainRC
					invoke OutputMake,IDM_MAKE_COMPILE,2
					.if !eax
						invoke OutputMake,IDM_MAKE_ASSEMBLE,0
						.if !eax
							invoke OutputMake,IDM_MAKE_LINK,3
							.if !eax
								invoke OutputMake,IDM_MAKE_RUN,0
							.endif
						.endif
					.endif
				.else
					invoke OutputMake,IDM_MAKE_ASSEMBLE,2
					.if !eax
						invoke OutputMake,IDM_MAKE_LINK,3
						.if !eax
							invoke OutputMake,IDM_MAKE_RUN,0
						.endif
					.endif
				.endif
			.elseif eax==IDM_MAKE_RUN
				invoke UpdateAll,UAM_SAVEALL,FALSE
				invoke OutputMake,IDM_MAKE_RUN,1
			.elseif eax==IDM_MAKE_DEBUG
				invoke UpdateAll,UAM_SAVEALL,FALSE
			.elseif eax==IDM_MAKE_SETMAIN
				.if ha.hMdi
					invoke strcpy,addr buffer,addr da.szFileName
					.if da.fProject
						invoke RemovePath,addr buffer,addr da.szProjectPath,addr buffer
					.else
						invoke strcpy,addr buffer,addr da.szFileName
					.endif
					invoke GetTheFileType,addr da.szFileName
					.if eax==ID_EDITCODE
						.if da.fProject
							invoke GetWindowLong,ha.hEdt,GWL_USERDATA
							.if [eax].TABMEM.pid
								invoke SetMain,[eax].TABMEM.pid,ID_EDITCODE
								.if eax
									invoke strcpy,addr da.szMainAsm,addr buffer
								.endif
							.endif
						.else
							invoke strcpy,addr da.szMainAsm,addr buffer
						.endif
					.elseif eax==ID_EDITRES
						.if da.fProject
							invoke GetWindowLong,ha.hEdt,GWL_USERDATA
							.if [eax].TABMEM.pid
								invoke SetMain,[eax].TABMEM.pid,ID_EDITRES
								.if eax
									invoke strcpy,addr da.szMainRC,addr buffer
								.endif
							.endif
						.else
							invoke strcpy,addr da.szMainRC,addr buffer
						.endif
					.endif
					mov		da.fTimer,1
				.endif
			.elseif eax==IDM_MAKE_TOGGLEMODULE
				.if da.fProject
					invoke GetTheFileType,addr da.szFileName
					.if eax==ID_EDITCODE
						invoke GetWindowLong,ha.hEdt,GWL_USERDATA
						.if [eax].TABMEM.pid
							invoke ToggleModule,[eax].TABMEM.pid
						.endif
					.endif
				.endif
			.elseif eax==IDM_DEBUG_TOGGLE
;####
			.elseif eax==IDM_DEBUG_CLEAR
			.elseif eax==IDM_DEBUG_RUN
			.elseif eax==IDM_DEBUG_BREAK
			.elseif eax==IDM_DEBUG_STOP
			.elseif eax==IDM_DEBUG_INTO
			.elseif eax==IDM_DEBUG_OVER
			.elseif eax==IDM_DEBUG_CARET
			.elseif eax==IDM_DEBUG_NODEBUG
;####
			.elseif eax>=IDM_TOOLS_START && eax<IDM_TOOLS_START+20
				;Help
				mov		edx,eax
				sub		edx,IDM_TOOLS_START
				invoke BinToDec,edx,addr buffer
				invoke GetPrivateProfileString,addr szIniTool,addr buffer,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
				.if eax
					invoke GetItemStr,addr tmpbuff,addr szNULL,addr buffer,sizeof buffer
					invoke FixPath,addr tmpbuff,addr da.szAppPath,addr szDollarA
					invoke ParseCmnd,addr tmpbuff,addr buffer,addr buffer1
					invoke ShellExecute,hWin,NULL,addr buffer,addr buffer1,NULL,SW_SHOWNORMAL;SW_SHOWDEFAULT
				.endif
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
			.elseif eax==IDM_OPTION_CODE
				invoke DialogBoxParam,ha.hInstance,IDD_DLGKEYWORDS,hWin,offset KeyWordsProc,0
			.elseif eax==IDM_OPTION_RESOURCE
				invoke DialogBoxParam,ha.hInstance,IDD_TABOPTIONS,hWin,offset TabOptionsProc,0
			.elseif eax==IDM_OPTION_ENVIRONMENT
				invoke DialogBoxParam,ha.hInstance,IDD_ENVIRONMENTOPTION,hWin,offset EnvironmentOptionsProc,0
			.elseif eax==IDM_OPTION_EXTERNAL
				invoke DialogBoxParam,ha.hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,eax
				.if eax
					invoke GetExternalFiles
				.endif
			.elseif eax==IDM_OPTION_ADDIN
;####
			.elseif eax==IDM_OPTION_TOOLS
				invoke DialogBoxParam,ha.hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,eax
				.if eax
					invoke SetToolMenu
				.endif
			.elseif eax==IDM_OPTION_HELP
				invoke DialogBoxParam,ha.hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,eax
				.if eax
					invoke SetHelpMenu
				.endif
			.elseif eax==IDM_OPTION_F1
				invoke DialogBoxParam,ha.hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,eax
				.if eax
					invoke SetF1Help
				.endif
			.elseif eax==IDM_HELP_ABOUT
				invoke DialogBoxParam,ha.hInstance,IDD_DLGABOUT,hWin,offset AboutProc,0
			.elseif eax>=IDM_HELP_START && eax<IDM_HELP_START+20
				;Help
				mov		edx,eax
				sub		edx,IDM_HELP_START
				invoke BinToDec,edx,addr buffer
				invoke GetPrivateProfileString,addr szIniHelp,addr buffer,addr szNULL,addr tmpbuff,sizeof tmpbuff,addr da.szAssemblerIni
				.if eax
					invoke GetItemStr,addr tmpbuff,addr szNULL,addr buffer,sizeof buffer
					mov		eax,dword ptr tmpbuff
					and		eax,5F5F5F5Fh
					.if eax=='PTTH'
						;Show internet browser
						invoke ShellExecute,hWin,addr szIniOpen,addr tmpbuff,NULL,NULL,SW_SHOWNORMAL;SW_SHOWDEFAULT
					.else
						;Show help file
						invoke FixPath,addr tmpbuff,addr da.szAppPath,addr szDollarA
						invoke ParseCmnd,addr tmpbuff,addr buffer,addr buffer1
						invoke ShellExecute,hWin,addr szIniOpen,addr buffer,addr buffer1,NULL,SW_SHOWNORMAL;SW_SHOWDEFAULT
					.endif
				.endif
			.elseif eax==IDM_HELPF1
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						xor		ebx,ebx
						invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
						invoke SendMessage,ha.hEdt,EM_FINDWORDBREAK,WB_MOVEWORDLEFT,chrg.cpMin
						.if eax
							mov		trng.chrg.cpMax,eax
							dec		eax
							mov		trng.chrg.cpMin,eax
							lea		eax,buffer1
							mov		trng.lpstrText,eax
							invoke SendMessage,ha.hEdt,EM_GETTEXTRANGE,0,addr trng
							.if buffer1=='.'
								mov		ebx,TRUE
							.endif
						.endif
						invoke SendMessage,ha.hEdt,REM_GETWORD,sizeof buffer1-1,addr buffer1
						invoke IsWordKeyWord,addr buffer1,ebx
						.if eax==1
							;Programming language help
							invoke DoHelp,addr da.szHelpF1[MAX_PATH*0],addr buffer1
						.elseif eax==2
							;RC help
							invoke DoHelp,addr da.szHelpF1[MAX_PATH*1],addr buffer1
						.elseif !eax
							;Win32 api help
							invoke DoHelp,addr da.szHelpF1[MAX_PATH*2],addr buffer1
						.endif
					.endif
				.endif
			.elseif eax==IDCM_FILE_OPEN
				invoke SendMessage,ha.hFileBrowser,FBM_GETSELECTED,0,addr buffer
				invoke GetFileAttributes,addr buffer
				.if eax!=INVALID_HANDLE_VALUE
					test	eax,FILE_ATTRIBUTE_DIRECTORY
					.if !ZERO?
						invoke SendMessage,ha.hFileBrowser,FBM_SETPATH,TRUE,addr buffer
					.else
						invoke UpdateAll,UAM_ISOPENACTIVATE,addr buffer
						.if eax==-1
							invoke OpenTheFile,addr buffer,0
						.endif
					.endif
				.endif
			.elseif eax==IDCM_FILE_EXPLORE
				invoke SendMessage,ha.hFileBrowser,FBM_GETSELECTED,0,addr buffer
				invoke GetFileAttributes,addr buffer
				.if eax!=INVALID_HANDLE_VALUE
					test	eax,FILE_ATTRIBUTE_DIRECTORY
					.if ZERO?
						invoke strlen,addr buffer
						.while buffer[eax]!='\' && eax
							dec		eax
						.endw
						mov		buffer[eax],0
					.endif
					invoke ShellExecute,hWin,addr szIniOpen,addr buffer,0,0,SW_SHOWDEFAULT
				.endif
			.elseif eax==IDCM_FILE_TOCODE
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke SendMessage,ha.hFileBrowser,FBM_GETSELECTED,0,addr buffer
						invoke SetFocus,ha.hEdt
						invoke SendMessage,ha.hEdt,EM_REPLACESEL,TRUE,addr buffer
					.endif
				.endif
			.elseif eax==IDM_PROPERTY_GOTO
				invoke SendMessage,ha.hProperty,WM_COMMAND,(LBN_DBLCLK shl 16) or 1003,0
			.elseif eax==IDM_PROPERTY_COPY
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke SendMessage,ha.hProperty,PRM_GETSELTEXT,0,addr buffer
						invoke SetFocus,ha.hEdt
						invoke SendMessage,ha.hEdt,EM_REPLACESEL,TRUE,addr buffer
					.endif
				.endif
			.elseif eax==IDM_PROPERTY_PROTO
				.if ha.hMdi
					invoke GetWindowLong,ha.hEdt,GWL_ID
					.if eax==ID_EDITCODE || eax==ID_EDITTEXT
						invoke SendMessage,ha.hProperty,PRM_GETSELTYP,0,0
						.if eax=='p'
							invoke SendMessage,ha.hProperty,PRM_GETSELTEXT,0,offset tmpbuff
							.if eax
								invoke SendMessage,ha.hProperty,PRM_FINDFIRST,offset szCCp,offset tmpbuff
								.while eax
									mov		ebx,eax
									invoke strcmp,offset tmpbuff,ebx
									.if !eax
										invoke strcat,offset tmpbuff,offset szPROTO
										invoke strlen,ebx
										lea		ebx,[ebx+eax+1]
										.if byte ptr [ebx]
											invoke strcat,offset tmpbuff,offset szSpc
											invoke strcat,offset tmpbuff,ebx
										.endif
										invoke strcat,offset tmpbuff,offset szCr
										invoke SendMessage,ha.hEdt,EM_REPLACESEL,TRUE,offset tmpbuff
										invoke SetFocus,ha.hEdt
										.break
									.endif
									invoke SendMessage,ha.hProperty,PRM_FINDNEXT,0,0
								.endw
							.endif
						.endif
					.endif
				.endif
			.elseif eax==IDM_OUTPUT_HIDE
				invoke SendMessage,ha.hTool,TLM_HIDE,0,ha.hToolOutput
				invoke SendMessage,ha.hTool,TLM_GETVISIBLE,0,ha.hToolOutput
				invoke SendMessage,ha.hTbrView,TB_CHECKBUTTON,IDM_VIEW_OUTPUT,eax
			.elseif eax==IDM_OUTPUT_CLEAR
				invoke SendMessage,ha.hTabOutput,TCM_GETCURSEL,0,0
				mov		ebx,ha.hOutput
				.if eax
					mov		ebx,ha.hImmediate
				.endif
				invoke SendMessage,ebx,WM_SETTEXT,0,0
			.elseif eax==IDM_OUTPUT_CUT
				invoke SendMessage,ha.hTabOutput,TCM_GETCURSEL,0,0
				mov		ebx,ha.hOutput
				.if eax
					mov		ebx,ha.hImmediate
				.endif
				mov		chrg.cpMin,0
				mov		chrg.cpMax,-1
				invoke SendMessage,ebx,EM_EXSETSEL,0,addr chrg
				invoke SendMessage,ebx,WM_CUT,0,0
			.elseif eax==IDM_OUTPUT_COPY
				invoke SendMessage,ha.hTabOutput,TCM_GETCURSEL,0,0
				mov		ebx,ha.hOutput
				.if eax
					mov		ebx,ha.hImmediate
				.endif
				mov		chrg.cpMin,0
				mov		chrg.cpMax,-1
				invoke SendMessage,ebx,EM_EXSETSEL,0,addr chrg
				invoke SendMessage,ebx,WM_COPY,0,0
			.elseif eax==19999
				mov		da.fTimer,1
			.else
				jmp		ExDef
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke UpdateAll,UAM_SAVEALL,TRUE
		.if eax
			invoke SaveTools
			invoke SaveReBar
			.if da.fProject
				invoke PutProject
			.else
				invoke PutSession
			.endif
			invoke UpdateAll,UAM_CLOSEALL,0
			invoke PutWinPos
			invoke PutFindHistory
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
		.if da.inprogress
			jmp		Ex
		.endif
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
			;Rebar
			invoke SendMessage,hWin,WM_SIZE,0,0
		.elseif [esi].NMHDR.code==TCN_SELCHANGE
			;Tab control
			.if eax==ha.hTabProject
				;Project tab
				invoke SendMessage,ha.hTabProject,TCM_GETCURSEL,0,0
				invoke SetProjectTab,eax
			.elseif eax==ha.hTabOutput
				;Output tab
				invoke SendMessage,ha.hTabOutput,TCM_GETCURSEL,0,0
				invoke SetOutputTab,eax
			.endif
		.elseif [esi].NMHDR.code==FBN_DBLCLICK && eax==ha.hFileBrowser
			;File browser file
			invoke UpdateAll,UAM_ISOPENACTIVATE,[esi].FBNOTIFY.lpfile
			.if eax==-1
				invoke OpenTheFile,[esi].FBNOTIFY.lpfile,0
			.endif
		.elseif [esi].NMHDR.code==FBN_PATHCHANGE && eax==ha.hFileBrowser
			;File browser path
			invoke strcpy,addr da.szFBPath,[esi].FBNOTIFY.lpfile
		.elseif [esi].NMHDR.code==RPBN_DBLCLICK && eax==ha.hProjectBrowser
			;Project browser dblclick
			mov		ebx,[esi].NMPBITEMDBLCLICK.lpPBITEM
			invoke UpdateAll,UAM_ISOPENACTIVATE,addr [ebx].PBITEM.szitem
			.if eax==-1
				invoke OpenTheFile,addr [ebx].PBITEM.szitem,0
			.endif
		.elseif [esi].NMHDR.code==RPBN_ITEMCHANGE && eax==ha.hProjectBrowser
			;Project browser item change
			invoke GetFileAttributes,[esi].NMPBITEMCHANGE.lpsznew
			.if eax!=INVALID_HANDLE_VALUE
				;File exists
				mov		[esi].NMPBITEMCHANGE.cancel,TRUE
				invoke strcpy,offset tmpbuff,offset szErrFileExists
				invoke strcat,offset tmpbuff,[esi].NMPBITEMCHANGE.lpsznew
				invoke MessageBox,ha.hWnd,offset tmpbuff,offset DisplayName,MB_OK or MB_ICONERROR
			.else
				mov		edi,[esi].NMPBITEMCHANGE.lpPBITEM
				invoke strcpy,addr buffer,addr [edi].PBITEM.szitem
				invoke UpdateAll,UAM_ISOPEN,addr [edi].PBITEM.szitem
				.if eax
					mov		ebx,eax
					;File is open
					invoke MoveFile,addr [edi].PBITEM.szitem,[esi].NMPBITEMCHANGE.lpsznew
					.if eax
						invoke TabToolGetInx,ebx
						invoke TabToolSetText,eax,[esi].NMPBITEMCHANGE.lpsznew
						invoke SetWindowText,ebx,[esi].NMPBITEMCHANGE.lpsznew
						.if ebx==ha.hMdi
							;and is the current window
							invoke strcpy,offset da.szFileName,[esi].NMPBITEMCHANGE.lpsznew
						.endif
					.else
						;Probably not a valid filename
						mov		[esi].NMPBITEMCHANGE.cancel,TRUE
						invoke strcpy,offset tmpbuff,offset szErrCreate
						invoke strcat,offset tmpbuff,[esi].NMPBITEMCHANGE.lpsznew
						invoke MessageBox,ha.hWnd,offset tmpbuff,offset DisplayName,MB_OK or MB_ICONERROR
					.endif
				.else
					;File is not open, move it
					invoke MoveFile,addr [edi].PBITEM.szitem,[esi].NMPBITEMCHANGE.lpsznew
					.if !eax
						;Probably not a valid filename
						mov		[esi].NMPBITEMCHANGE.cancel,TRUE
						invoke strcpy,offset tmpbuff,offset szErrCreate
						invoke strcat,offset tmpbuff,[esi].NMPBITEMCHANGE.lpsznew
						invoke MessageBox,ha.hWnd,offset tmpbuff,offset DisplayName,MB_OK or MB_ICONERROR
					.endif
				.endif
			.endif
		.elseif [esi].NMHDR.code==LBN_DBLCLK && eax==ha.hProperty
			;Property list
			.if ha.hMdi
				invoke GetWindowLong,ha.hEdt,GWL_ID
				.if eax==ID_EDITCODE
					invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
					invoke PushGoto,ha.hEdt,chrg.cpMin
				.endif
			.endif
			.if da.fProject
				invoke TabToolGetInxFromPid,[esi].RAPNOTIFY.nid
			.else
				invoke TabToolGetInx,[esi].RAPNOTIFY.nid
			.endif
			.if eax==-1
				invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEM,[esi].RAPNOTIFY.nid,0
				.if eax
					invoke OpenTheFile,addr [eax].PBITEM.szitem,0
				.else
					jmp		Ex
				.endif
			.else
				invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
				invoke TabToolActivate
			.endif
			invoke SendMessage,ha.hEdt,EM_LINEINDEX,[esi].RAPNOTIFY.nline,0
			mov		chrg.cpMin,eax
			mov		chrg.cpMax,eax
			invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
			invoke SendMessage,ha.hEdt,REM_VCENTER,0,0
			invoke SetFocus,ha.hEdt
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
			invoke SendMessage,ha.hTabProject,TCM_GETCURSEL,0,0
			.if !eax
				;File contextmenu
				invoke EnableContextMenu,ha.hContextMenu,1
				invoke GetSubMenu,ha.hContextMenu,1
				invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,ha.hWnd,0
			.else
				;Project menu
				mov		ebx,4
				invoke EnableMenu,ha.hMenu,ebx
				.if ha.hMdi
					add		ebx,da.win.fcldmax
				.endif
				invoke GetSubMenu,ha.hMenu,ebx
				invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,ha.hWnd,0
			.endif
		.elseif eax==ha.hToolProperties
			;Property contextmenu
			invoke EnableContextMenu,ha.hContextMenu,3
			invoke GetSubMenu,ha.hContextMenu,3
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,ha.hWnd,0
		.elseif eax==ha.hToolOutput
			;Output contextmenu
			invoke EnableContextMenu,ha.hContextMenu,4
			invoke GetSubMenu,ha.hContextMenu,4
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,ha.hWnd,0
		.elseif eax==ha.hToolTab || eax==ha.hWnd || eax==ha.hClient
			;Window menu
			mov		ebx,9
			invoke EnableMenu,ha.hMenu,ebx
			.if ha.hMdi
				add		ebx,da.win.fcldmax
			.endif
			invoke GetSubMenu,ha.hMenu,ebx
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,ha.hWnd,0
		.elseif eax==ha.hReBar
			;View / Toolbar menu
			invoke EnableMenu,ha.hMenu,2
			mov		mii.cbSize,sizeof MENUITEMINFO
			mov		mii.fMask,MIIM_SUBMENU
			invoke GetMenuItemInfo,ha.hMenu,IDM_VIEW_TOOLBAR,FALSE,addr mii
			invoke TrackPopupMenu,mii.hSubMenu,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,ha.hWnd,0
		.elseif eax==ha.hStatus
			PrintText "Sta"
		.else
			PrintText "???"
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
			invoke MoveWindow,ha.hProperty,0,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
		.elseif eax==ha.hToolOutput
			invoke MoveWindow,ha.hTabOutput,0,0,20,[esi].RECT.bottom,TRUE
			sub		[esi].RECT.right,20
			invoke MoveWindow,ha.hOutput,20,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
			invoke MoveWindow,ha.hImmediate,20,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
		.elseif eax==ha.hToolTab
			invoke MoveWindow,ha.hTab,0,0,[esi].RECT.right,[esi].RECT.bottom,TRUE
		.endif
	.elseif eax==WM_ACTIVATE
		.if ha.hMdi
			invoke SetFocus,ha.hEdt
		.endif
	.elseif eax==WM_DROPFILES
		xor		ebx,ebx
	  @@:
		invoke DragQueryFile,wParam,ebx,addr buffer,sizeof buffer
		.if eax
			invoke UpdateAll,UAM_ISOPENACTIVATE,addr buffer
			.if eax==-1
				invoke OpenTheFile,addr buffer,0
			.endif
			inc		ebx
			jmp		@b
		.endif
	.elseif eax==WM_MEASUREITEM
		mov		ebx,lParam
		.if [ebx].MEASUREITEMSTRUCT.CtlType==ODT_MENU
;			mov		edx,[ebx].MEASUREITEMSTRUCT.itemData
;			.if edx
;				push	esi
;				mov		esi,edx
;				.if ![esi].MENUDATA.tpe
;					lea		esi,[esi+sizeof MENUDATA]
;					invoke GetDC,NULL
;					push	eax
;					invoke CreateCompatibleDC,eax
;					mov		mDC,eax
;					pop		eax
;					invoke ReleaseDC,NULL,eax
;					invoke SelectObject,mDC,ha.hMnuFont
;					push	eax
;					mov		rect.left,0
;					mov		rect.top,0
;					invoke DrawText,mDC,esi,-1,addr rect,DT_CALCRECT or DT_SINGLELINE
;					mov		eax,rect.right
;					mov		[ebx].MEASUREITEMSTRUCT.itemWidth,eax
;					invoke strlen,esi
;					lea		esi,[esi+eax+1]
;					invoke DrawText,mDC,esi,-1,addr rect,DT_CALCRECT or DT_SINGLELINE
;					pop		eax
;					invoke SelectObject,mDC,eax
;					invoke DeleteDC,mDC
;					mov		eax,rect.right
;					add		eax,25
;					add		[ebx].MEASUREITEMSTRUCT.itemWidth,eax
;					mov		eax,20
;					mov		[ebx].MEASUREITEMSTRUCT.itemHeight,eax
;				.else
;					mov		eax,10
;					mov		[ebx].MEASUREITEMSTRUCT.itemHeight,eax
;				.endif
;				pop		esi
;			.endif
			mov		eax,TRUE
			jmp		ExRet
		.endif
	.elseif eax==WM_DRAWITEM
		mov		ebx,lParam
		.if [ebx].DRAWITEMSTRUCT.CtlType==ODT_MENU
;			push	esi
;			mov		esi,[ebx].DRAWITEMSTRUCT.itemData
;			.if esi
;				invoke CreateCompatibleDC,[ebx].DRAWITEMSTRUCT.hdc
;				mov		mDC,eax
;				mov		rect.left,0
;				mov		rect.top,0
;				mov		eax,[ebx].DRAWITEMSTRUCT.rcItem.right
;				sub		eax,[ebx].DRAWITEMSTRUCT.rcItem.left
;				mov		rect.right,eax
;				mov		eax,[ebx].DRAWITEMSTRUCT.rcItem.bottom
;				sub		eax,[ebx].DRAWITEMSTRUCT.rcItem.top
;				mov		rect.bottom,eax
;				invoke CreateCompatibleBitmap,[ebx].DRAWITEMSTRUCT.hdc,rect.right,rect.bottom
;				invoke SelectObject,mDC,eax
;				push	eax
;				invoke SelectObject,mDC,ha.hMnuFont
;				push	eax
;				invoke GetStockObject,WHITE_BRUSH
;				invoke FillRect,mDC,addr rect,eax
;				invoke FillRect,mDC,addr rect,ha.hMenuBrushB
;				.if ![esi].MENUDATA.tpe
;					invoke SetBkMode,mDC,TRANSPARENT
;					test	[ebx].DRAWITEMSTRUCT.itemState,ODS_SELECTED
;					.if !ZERO?
;						invoke CreateSolidBrush,0F5BE9Fh
;						mov		hBr,eax
;						invoke FillRect,mDC,addr rect,hBr
;						invoke DeleteObject,hBr
;						invoke CreateSolidBrush,800000h
;						mov		hBr,eax
;						invoke FrameRect,mDC,addr rect,hBr
;						invoke DeleteObject,hBr
;					.endif
;					test	[ebx].DRAWITEMSTRUCT.itemState,ODS_CHECKED
;					.if !ZERO?
;						; Check mark
;						mov		edx,rect.bottom
;						sub		edx,16
;						shr		edx,1
;						invoke ImageList_Draw,ha.hImlTbr,27,mDC,2,edx,ILD_TRANSPARENT
;					.else
;						; Image
;						mov		eax,[esi].MENUDATA.img
;						.if eax
;							mov		edx,rect.bottom
;							sub		edx,16
;							shr		edx,1
;							dec		eax
;							test	[ebx].DRAWITEMSTRUCT.itemState,ODS_GRAYED
;							.if ZERO?
;								invoke ImageList_Draw,ha.hImlTbr,eax,mDC,2,edx,ILD_TRANSPARENT
;							.else
;								invoke ImageList_Draw,ha.hImlTbrGray,eax,mDC,2,edx,ILD_TRANSPARENT
;							.endif
;						.endif
;					.endif
;					; Text
;					test	[ebx].DRAWITEMSTRUCT.itemState,ODS_GRAYED
;					.if ZERO?
;						invoke GetSysColor,COLOR_MENUTEXT
;					.else
;						invoke GetSysColor,COLOR_GRAYTEXT
;					.endif
;					invoke SetTextColor,mDC,eax
;					lea		esi,[esi+sizeof MENUDATA]
;					invoke strlen,esi
;					push	eax
;					add		rect.left,22
;					add		rect.top,2
;					sub		rect.right,2
;					invoke DrawText,mDC,esi,-1,addr rect,DT_LEFT or DT_VCENTER
;					pop		eax
;					lea		esi,[esi+eax+1]
;					; Accelerator
;					invoke DrawText,mDC,esi,-1,addr rect,DT_RIGHT or DT_VCENTER
;					sub		rect.left,22
;					sub		rect.top,2
;					add		rect.right,2
;				.else
;					invoke CreatePen,PS_SOLID,1,0F5BE9Fh
;					invoke SelectObject,mDC,eax
;					push	eax
;					add		rect.left,21
;					add		rect.top,5
;					invoke MoveToEx,mDC,rect.left,rect.top,NULL
;					invoke LineTo,mDC,rect.right,rect.top
;					sub		rect.left,21
;					sub		rect.top,5
;					pop		eax
;					invoke SelectObject,mDC,eax
;					invoke DeleteObject,eax
;				.endif
;				mov		eax,[ebx].DRAWITEMSTRUCT.rcItem.right
;				sub		eax,[ebx].DRAWITEMSTRUCT.rcItem.left
;				mov		edx,[ebx].DRAWITEMSTRUCT.rcItem.bottom
;				sub		edx,[ebx].DRAWITEMSTRUCT.rcItem.top
;				invoke BitBlt,[ebx].DRAWITEMSTRUCT.hdc,[ebx].DRAWITEMSTRUCT.rcItem.left,[ebx].DRAWITEMSTRUCT.rcItem.top,eax,edx,mDC,0,0,SRCCOPY
;				pop		eax
;				invoke SelectObject,mDC,eax
;				pop		eax
;				invoke SelectObject,mDC,eax
;				invoke DeleteObject,eax
;				invoke DeleteDC,mDC
;			.endif
;			pop		esi
			mov		eax,TRUE
			jmp		ExRet
		.endif
	.else
  ExDef:
		invoke DefFrameProc,hWin,ha.hClient,uMsg,wParam,lParam
		ret
	.endif
  Ex:
	xor     eax,eax
  ExRet:
	ret

WndProc endp

RAEditCodeProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	chrg:CHARRANGE
;	LOCAL	ti:TOOLINFO
	LOCAL	buffer[256]:BYTE
;	LOCAL	pt:POINT
;	LOCAL	dbgtip:DEBUGTIP
;	LOCAL	isinproc:ISINPROC
	LOCAL	trng:TEXTRANGE

	mov		eax,uMsg
	.if eax==WM_CHAR
		mov		eax,wParam
		.if eax==VK_TAB || eax==VK_RETURN
			invoke IsWindowVisible,ha.hCC
			.if eax
				invoke SendMessage,ha.hCC,CCM_GETCURSEL,0,0
				.if eax!=LB_ERR
					mov		da.inprogress,TRUE
					invoke SendMessage,ha.hEdt,REM_LOCKUNDOID,TRUE,0
					invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr ccchrg
					mov		eax,ccchrg.cpMin
					inc		eax
					mov		trng.chrg.cpMin,eax
					add		eax,16
					mov		trng.chrg.cpMax,eax
					lea		eax,buffer
					mov		trng.lpstrText,eax
					invoke SendMessage,ha.hEdt,EM_GETTEXTRANGE,0,addr trng
					invoke SendMessage,ha.hCC,CCM_GETCURSEL,0,0
					invoke SendMessage,ha.hCC,CCM_GETITEM,eax,0
					push	eax
					invoke strcpy,offset tmpbuff,eax
					xor		eax,eax
					.while tmpbuff[eax]
						.if tmpbuff[eax]==':' || tmpbuff[eax]=='['
							mov		tmpbuff[eax],0
							.break
						.endif
						inc		eax
					.endw
					invoke SendMessage,ha.hEdt,EM_REPLACESEL,TRUE,offset tmpbuff
					pop		eax
					.if da.cctype==CCTYPE_PROC
						lea		edx,buffer
						.while byte ptr [edx] && byte ptr [edx]!=VK_RETURN
							.if byte ptr [edx]==','
								xor		edx,edx
								.break
							.endif
							inc		edx
						.endw
						.if edx
							push	eax
							invoke strlen,eax
							pop		edx
							.if byte ptr [edx+eax+1]
								mov		da.inprogress,0
								mov		eax,','
								invoke SendMessage,ha.hEdt,WM_CHAR,eax,0
							.endif
						.endif
					.endif
					invoke SendMessage,ha.hEdt,REM_LOCKUNDOID,FALSE,0
					invoke ShowWindow,ha.hCC,SW_HIDE
					mov		da.cctype,CCTYPE_NONE
					xor		eax,eax
					mov		da.inprogress,eax
					jmp		Ex
				.else
					invoke ShowWindow,ha.hCC,SW_HIDE
					xor		eax,eax
					jmp		Ex
				.endif
			.elseif wParam==VK_TAB
				invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
				mov		eax,chrg.cpMin
				.if eax!=chrg.cpMax
					invoke GetKeyState,VK_SHIFT
					and		eax,80h
					xor		eax,80h
					invoke IndentComment,ha.hEdt,VK_TAB,eax
					xor		eax,eax
					jmp		Ex
				.endif
			.elseif wParam==VK_RETURN
				invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
				invoke CaseConvertWord,wParam,chrg.cpMin
				;Block complete
				invoke CallWindowProc,lpOldRAEditCodeProc,hWin,uMsg,wParam,lParam
				push	eax
				invoke BlockComplete,hWin
				pop		eax
				jmp		Ex
			.endif
		.elseif eax==VK_ESCAPE
			invoke ShowWindow,ha.hCC,SW_HIDE
			invoke ShowWindow,ha.hCC,SW_HIDE
			mov		da.cctype,CCTYPE_NONE
			xor		eax,eax
			jmp		Ex
		.elseif eax==VK_SPACE
			invoke GetKeyState,VK_CONTROL
			test		eax,80h
			.if !ZERO?
				mov		da.cctype,CCTYPE_ALL
				; Force a WM_NOTIFY
				invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
				invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
				xor		eax,eax
				jmp		Ex
			.endif
		.elseif eax=='.'
			mov		da.cctype,CCTYPE_STRUCT
			invoke CallWindowProc,lpOldRAEditCodeProc,hWin,uMsg,wParam,lParam
			jmp		Ex
		.elseif da.cctype==CCTYPE_ALL || da.cctype==CCTYPE_STRUCT
			push	eax
			invoke GetCharType,eax
			pop		edx
			.if eax==1 || edx==VK_BACK
				invoke CallWindowProc,lpOldRAEditCodeProc,hWin,uMsg,wParam,lParam
				push	eax
				; Force a WM_NOTIFY
				invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
				invoke SendMessage,ha.hEdt,EM_EXSETSEL,0,addr chrg
				pop		eax
				jmp		Ex
			.else
				mov		da.cctype,CCTYPE_NONE
				invoke ShowWindow,ha.hCC,SW_HIDE
			.endif
		.endif
		invoke GetCharType,wParam
		.if eax!=1
			invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
			mov		eax,chrg.cpMin
			.if eax==chrg.cpMax && wParam!=VK_BACK
				invoke CaseConvertWord,wParam,chrg.cpMin
			.endif
		.endif
	.elseif eax==WM_KEYDOWN
		mov		edx,wParam
		mov		eax,lParam
		shr		eax,16
		and		eax,3FFh
		.if (edx==28h && (eax==150h || eax==50h)) || (edx==26h && (eax==148h || eax==48h)) || (edx==21h && (eax==149h || eax==49h)) || (edx==22h && (eax==151h || eax==51h))
			;Down / Up /PgUp / PgDn
			invoke IsWindowVisible,ha.hCC
			.if eax
				invoke PostMessage,ha.hCC,uMsg,wParam,lParam
				xor		eax,eax
				jmp		Ex
			.endif
		.elseif (edx==25h && eax==14Bh) || (edx==27h && eax==14Dh)
			;Left / Right
			invoke IsWindowVisible,ha.hCC
			.if eax
				invoke ShowWindow,ha.hCC,SW_HIDE
			.endif
			invoke IsWindowVisible,ha.hCC
			.if eax
				invoke ShowWindow,ha.hCC,SW_HIDE
			.endif
			mov		da.cctype,CCTYPE_NONE
		.endif
	.elseif eax==WM_KILLFOCUS
		invoke ShowWindow,ha.hTT,SW_HIDE
	.elseif eax==WM_MOUSEMOVE
;		mov		ti.cbSize,SizeOf TOOLINFO
;		mov		ti.uFlags,TTF_IDISHWND
;		mov		eax,hWin
;		mov		ti.hWnd,eax
;		mov		ti.uId,eax
;		mov		ti.lpszText,0
;		invoke SendMessage,ha.hDbgTip,TTM_GETTOOLINFO,0,addr ti
;		.if fDebugging
;			.if !eax
;				;Add the tooltip
;				mov		ti.uFlags,TTF_IDISHWND Or TTF_SUBCLASS
;				mov		eax,hWin
;				mov		ti.hWnd,eax
;				mov		ti.uId,eax
;				mov		eax,ha.hInstance
;				mov		ti.hInst,eax
;				invoke SendMessage,ha.hDbgTip,TTM_ADDTOOL,0,addr ti
;			.endif
;			mov		eax,lParam
;			mov		edx,eax
;			shr		edx,16
;			movsx	edx,dx
;			movsx	eax,ax
;			mov		pt.x,eax
;			mov		pt.y,edx
;			sub		eax,dbgpt.x
;			.if CARRY?
;				neg		eax
;			.endif
;			sub		edx,dbgpt.y
;			.if CARRY?
;				neg		edx
;			.endif
;			.if eax>5 || edx>5
;				mov		eax,pt.x
;				mov		dbgpt.x,eax
;				mov		eax,pt.y
;				mov		dbgpt.y,eax
;				invoke SendMessage,ha.hREd,EM_CHARFROMPOS,0,addr pt
;				invoke SendMessage,ha.hREd,REM_ISCHARPOS,eax,0
;				.if !eax
;					invoke SendMessage,ha.hREd,REM_GETCURSORWORD,sizeof buffer,addr buffer
;					.if buffer
;						lea		eax,buffer
;						mov		dbgtip.lpWord,eax
;						invoke SendMessage,ha.hREd,EM_CHARFROMPOS,0,addr pt
;						invoke SendMessage,ha.hREd,EM_LINEFROMCHAR,eax,0
;						mov		isinproc.nLine,eax
;						inc		eax
;						mov		dbgtip.nLine,eax
;						mov		eax,ha.hREd
;						mov		isinproc.nOwner,eax
;						mov		isinproc.lpszType,offset szCCp
;						invoke SendMessage,ha.hProperty,PRM_ISINPROC,0,addr isinproc
;						mov		dbgtip.lpProc,eax
;						mov		dbgtip.lpFileName,offset da.FileName
;						invoke DebugCommand,FUNC_GETTOOLTIP,ha.hREd,addr dbgtip
;						.if eax
;							; Show tooltip
;							mov		ti.lpszText,eax
;							call	Activate
;						.else
;							; Hide tooltip
;							call	DeActivate
;						.endif
;					.else
;						; Hide tooltip
;						call	DeActivate
;					.endif
;				.else
;					; Hide tooltip
;					call	DeActivate
;				.endif
;			.endif
;		.elseif eax
;			; Delete the tool
;			invoke SendMessage,ha.hDbgTip,TTM_DELTOOL,0,addr ti
;		.endif
	.endif
	invoke CallWindowProc,lpOldRAEditCodeProc,hWin,uMsg,wParam,lParam
  Ex:
	ret

Activate:
;	invoke SendMessage,ha.hDbgTip,TTM_SETTOOLINFO,0,addr ti
;	invoke SendMessage,ha.hDbgTip,TTM_ACTIVATE ,FALSE,0
;	invoke SendMessage,ha.hDbgTip,TTM_ACTIVATE ,TRUE,0
	retn

DeActivate:
;	invoke SendMessage,ha.hDbgTip,TTM_ACTIVATE ,FALSE,0
	retn

RAEditCodeProc endp

MdiChildProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hEdt:HWND
	LOCAL	rect:RECT
	LOCAL	pt:POINT
	LOCAL	nBP:DWORD
	LOCAL	rescolor:RESCOLOR
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov		eax,mdiID
		.if eax==ID_EDITCODE
			mov		eax,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or STYLE_DRAGDROP or STYLE_SCROLLTIP or STYLE_AUTOSIZELINENUM
			.if da.edtopt.fopt & EDTOPT_CMNTHI
				or		eax,STYLE_HILITECOMMENT
			.endif
			invoke CreateWindowEx,0,addr szRAEditClass,NULL,eax,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,REM_SUBCLASS,0,offset RAEditCodeProc
			mov		lpOldRAEditCodeProc,eax
			invoke SendMessage,hEdt,REM_SETFONT,0,addr ha.racf
			invoke SendMessage,hEdt,REM_SETCOLOR,0,addr da.radcolor.racol
			invoke SendMessage,hEdt,REM_SETSTYLEEX,STYLEEX_BLOCKGUIDE or STILEEX_LINECHANGED,0
			;Set expand tabs and tabsize
			xor		eax,eax
			.if da.edtopt.fopt & EDTOPT_EXPTAB
				mov		eax,TRUE
			.endif
			invoke SendMessage,hEdt,REM_TABWIDTH,da.edtopt.tabsize,eax
			;Set autoindent
			.if !(da.edtopt.fopt & EDTOPT_INDENT)
				invoke SendMessage,hEdt,REM_AUTOINDENT,0,FALSE
			.endif
			;Set highlight active line
			.if da.edtopt.fopt & EDTOPT_LINEHI
				invoke SendMessage,hEdt,REM_HILITEACTIVELINE,0,2
			.endif
			;Line numbers
			.if da.edtopt.fopt & EDTOPT_LINENR
				invoke CheckDlgButton,hEdt,-2,TRUE
				invoke SendMessage,hEdt,WM_COMMAND,-2,0
			.endif
		.elseif eax==ID_EDITTEXT
			invoke CreateWindowEx,0,addr szRAEditClass,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or STYLE_DRAGDROP or STYLE_SCROLLTIP or STYLE_NOCOLLAPSE or STYLE_NOHILITE or STYLE_AUTOSIZELINENUM,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,REM_SETFONT,0,addr ha.ratf
			invoke SendMessage,hEdt,REM_SETCOLOR,0,addr da.radcolor.racol
			invoke SendMessage,hEdt,REM_SETSTYLEEX,STILEEX_LINECHANGED,0
			;Set expand tabs and tabsize
			xor		eax,eax
			.if da.edtopt.fopt & EDTOPT_EXPTAB
				mov		eax,TRUE
			.endif
			invoke SendMessage,hEdt,REM_TABWIDTH,da.edtopt.tabsize,eax
			;Set autoindent
			.if !(da.edtopt.fopt & EDTOPT_INDENT)
				invoke SendMessage,hEdt,REM_AUTOINDENT,0,FALSE
			.endif
			;Set highlight active line
			.if da.edtopt.fopt & EDTOPT_LINEHI
				invoke SendMessage,hEdt,REM_HILITEACTIVELINE,0,2
			.endif
		.elseif eax==ID_EDITHEX
			invoke CreateWindowEx,0,addr szRAHexEdClassName,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			invoke SendMessage,hEdt,HEM_SETFONT,0,addr ha.rahf
		.elseif eax==ID_EDITRES
			;Set style options
			mov		eax,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or DES_TOOLTIP
			test	da.resopt.fopt,RESOPT_GRID
			.if !ZERO?
				or		eax,DES_GRID
			.endif
			test	da.resopt.fopt,RESOPT_SNAP
			.if !ZERO?
				or		eax,DES_SNAPTOGRID
			.endif
			test	da.resopt.fopt,RESOPT_HEX
			.if !ZERO?
				or		eax,DES_STYLEHEX
			.endif
			invoke CreateWindowEx,0,addr szResEdClass,NULL,eax,0,0,0,0,hWin,mdiID,ha.hInstance,NULL
			mov		hEdt,eax
			;Set font
			invoke SendMessage,hEdt,WM_SETFONT,ha.hToolFont,FALSE
			;Set sizes
			invoke SendMessage,hEdt,DEM_SETSIZE,0,addr da.winres
			;Set colors
			mov		eax,da.radcolor.dialogback
			mov		rescolor.back,eax
			mov		eax,da.radcolor.dialogtext
			mov		rescolor.text,eax
			mov		eax,da.radcolor.styles
			mov		rescolor.styles,eax
			mov		eax,da.radcolor.words
			mov		rescolor.words,eax
			invoke SendMessage,hEdt,DEM_SETCOLOR,0,addr rescolor
			;Set status window
			invoke SendMessage,hEdt,DEM_SETPOSSTATUS,ha.hStatus,0
			;Set grid
			mov		eax,da.resopt.gridy
			shl		eax,16
			or		eax,da.resopt.gridy
			xor		edx,edx
			.if da.resopt.fopt & RESOPT_LINE
				mov		edx,1 shl 24
			.endif
			or		edx,da.resopt.color
			invoke SendMessage,hEdt,DEM_SETGRIDSIZE,eax,edx
			;Add custom controls
			xor		ebx,ebx
			mov		esi,offset da.resopt.custctrl
			.while ebx<32
				.if [esi].CUSTCTRL.szFileName
					invoke strcpy,addr buffer,addr [esi].CUSTCTRL.szFileName
					.if [esi].CUSTCTRL.szStyleMask
						invoke strcat,addr buffer,addr szComma
						invoke strcat,addr buffer,addr [esi].CUSTCTRL.szStyleMask
					.endif
					invoke SendMessage,hEdt,DEM_ADDCONTROL,0,addr buffer
					.if eax
						mov		[esi].CUSTCTRL.hDll,eax
					.endif
				.endif
				inc		ebx
				lea		esi,[esi+sizeof CUSTCTRL]
			.endw
			;Add custom styles
			xor		ebx,ebx
			mov		esi,offset da.resopt.custstyle
			.while ebx<64
				.if [esi].CUSTSTYLE.szStyle
					invoke SendMessage,hEdt,DEM_ADDCUSTSTYLE,0,esi
				.endif
				inc		ebx
				lea		esi,[esi+sizeof CUSTSTYLE]
			.endw
			;Add custom types
			xor		ebx,ebx
			mov		esi,offset da.resopt.custtype
			.while ebx<32
				.if [esi].RARSTYPE.sztype || [esi].RARSTYPE.nid
					invoke SendMessage,hEdt,PRO_SETCUSTOMTYPE,ebx,esi
					;Update menu
;					.if ![esi].RARSTYPE.szext && [esi].RARSTYPE.sztype && ebx>10
;						invoke lstrcpy,addr buffer,addr szAdd
;						invoke lstrcat,addr buffer,addr rarstype.sztype
;						mov		edx,nInx
;						lea		edx,[edx+22000-12]
;						invoke InsertMenu,ha.hMnu,IDM_RESOURCE_TOOLBAR,MF_BYCOMMAND,edx,addr buffer
;					.endif
				.endif
				inc		ebx
				lea		esi,[esi+sizeof RARSTYPE]
			.endw
		.elseif eax==ID_EDITUSER
			mov		hEdt,0
		.endif
		invoke SetWindowLong,hWin,GWL_USERDATA,hEdt
		invoke SetWinCaption,hWin,addr da.szFileName
		invoke TabToolAdd,hWin,addr da.szFileName
		xor		eax,eax
		jmp		Ex
	.elseif eax==WM_SIZE
		mov		eax,wParam
		.if eax==SIZE_MAXIMIZED
			mov		da.win.fcldmax,TRUE
		.elseif eax==SIZE_RESTORED || eax==SIZE_MINIMIZED
			mov		eax,hWin
			.if eax==ha.hMdi
				mov		da.win.fcldmax,FALSE
			.endif
		.endif
		invoke GetWindowLong,hWin,GWL_USERDATA
		mov		hEdt,eax
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,hEdt,0,0,rect.right,rect.bottom,TRUE
		invoke UpdateWindow,hEdt
	.elseif eax==WM_WINDOWPOSCHANGED
	.elseif eax==WM_MDIACTIVATE
		mov		eax,hWin
		.if eax==lParam
			;Activate
			invoke SendMessage,ha.hStatus,SB_SETTEXT,0,addr szNULL
			invoke TabToolGetInx,hWin
			invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
			invoke TabToolActivate
			invoke SetFocus,ha.hEdt
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
					invoke SendMessage,ha.hProperty,PRM_DELPROPERTY,hWin,0
					invoke SendMessage,ha.hProperty,PRM_REFRESHLIST,0,0
				.endif
			.elseif eax==ID_EDITTEXT
			.elseif eax==ID_EDITHEX
			.elseif eax==ID_EDITRES
				invoke SendMessage,hEdt,DEM_GETSIZE,0,addr da.winres
				invoke SendMessage,hEdt,PRO_CLOSE,0,0
				xor		ebx,ebx
				mov		esi,offset da.resopt.custctrl
				.while ebx<32
					.if [esi].CUSTCTRL.hDll
						invoke FreeLibrary,[esi].CUSTCTRL.hDll
						mov		[esi].CUSTCTRL.hDll,0
					.endif
					lea		esi,[esi+sizeof CUSTCTRL]
					inc		ebx
				.endw
			.endif
			.if da.fProject
				invoke GetWindowLong,hEdt,GWL_USERDATA
				mov		ebx,eax
				.if [ebx].TABMEM.pid
					invoke SendMessage,ha.hProjectBrowser,RPBM_FINDITEMINDEX,[ebx].TABMEM.pid,0
					.if eax!=-1
						invoke SaveProjectItem,eax,hWin
					.endif
				.endif
			.endif
			invoke DeleteGoto,hEdt
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
							invoke UpdateGoto,[ebx].TABMEM.hedt,[esi].RASELCHANGE.chrg.cpMin,eax
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
								invoke ApiListBox,esi
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
								invoke ParseEdit,[ebx].TABMEM.hwnd,[ebx].TABMEM.pid
							.endif
						.endif
					.elseif da.cctype==CCTYPE_ALL
						.if !da.inprogress
							invoke ApiListBox,esi
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
			invoke GetFocus
			mov		edi,eax
			invoke GetWindowRect,edi,addr rect
			invoke GetCaretPos,addr pt
			mov		eax,rect.left
			add		eax,10
			add		pt.x,eax
			mov		eax,rect.top
			add		eax,10
			add		pt.y,eax
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
	invoke GetPrivateProfileInt,addr szIniVersion,addr szIniVersion,0,addr da.szRadASMIni
	.if eax<3000
		invoke MessageBox,NULL,addr szRadASMVersion,addr DisplayName,MB_OK or MB_ICONERROR
		jmp		Ex
	.endif
	invoke GetResource
	invoke GetWinPos
	invoke GetFindHistory
	mov     eax,WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
	mov		edx,WS_EX_LEFT or WS_EX_ACCEPTFILES
	.if da.win.ftopmost
		or		edx,WS_EX_TOPMOST
	.endif
	invoke CreateWindowEx,edx,addr szMdiClassName,addr DisplayName,eax,da.win.x,da.win.y,da.win.wt,da.win.ht,NULL,NULL,hInst,NULL
	mov     eax,SW_SHOWNORMAL
	.if da.win.fmax
		mov     eax,SW_SHOWMAXIMIZED
	.endif
	invoke ShowWindow,ha.hWnd,eax
	invoke UpdateWindow,ha.hWnd
	invoke LoadMRU,addr szIniFile,addr da.szMruFiles
	invoke UpdateMRUMenu,addr da.szMruFiles
	invoke LoadMRU,addr szIniProject,addr da.szMruProjects
	invoke UpdateMRUMenu,addr da.szMruProjects
	invoke Init,CmdLine
	mov		da.fTimer,1
;	invoke ShowSplash
	.while TRUE
		invoke GetMessage,addr msg,0,0,0
	  .break .if !eax
		invoke IsDialogMessage,ha.hModeless,addr msg
		.if !eax
			invoke TranslateAccelerator,ha.hWnd,ha.hAccel,addr msg
			.if !eax
				invoke TranslateMessage,addr msg
				invoke DispatchMessage,addr msg
			.endif
		.endif
	.endw
	invoke SaveMRU,addr szIniFile,addr da.szMruFiles
	invoke SaveMRU,addr szIniProject,addr da.szMruProjects
	mov   eax,msg.wParam
  Ex:
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
;	invoke PathUnquoteSpaces,CommandLine
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
	invoke GridInstall,ha.hInstance,FALSE
	invoke ResEdInstall,ha.hInstance,FALSE
	invoke GetCharTabPtr
	mov		da.lpCharTab,eax
	invoke strcpy,addr da.szProjectFiles,addr szDotPrraDot
	mov		da.Version,RadASMVersion
	invoke WinMain,ha.hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	;Uninstall custom controls
	invoke ResEdUninstall
	invoke GridUnInstall
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
