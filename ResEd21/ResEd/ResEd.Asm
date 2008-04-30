.486
.model flat,stdcall
option casemap:none

include ResEd.inc
include Misc.asm
include About.asm
include Opt\MenuOption.asm
include Opt\TabOptions.asm

.code

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke LoadLibrary,offset szRichEdit
	mov		hRichEd,eax
	invoke GridInstall,hInstance,FALSE
	invoke InstallRAEdit,hInstance,FALSE
	invoke ResEdInstall,hInstance,FALSE
	invoke GetCommandLine
	mov		CommandLine,eax
	;Get command line filename
	invoke PathGetArgs,CommandLine
	mov		CommandLine,eax
  @@:
	mov		dl,[eax]
	.if dl==VK_SPACE
		inc		eax
		jmp		@b
	.elseif dl=='"'
		invoke PathUnquoteSpaces,eax
	.endif
	mov		CommandLine,eax
	invoke InitCommonControls
	;prepare common control structure
	mov		icex.dwSize,sizeof INITCOMMONCONTROLSEX
	mov		icex.dwICC,ICC_DATE_CLASSES or ICC_USEREX_CLASSES or ICC_INTERNET_CLASSES or ICC_ANIMATE_CLASS or ICC_HOTKEY_CLASS or ICC_PAGESCROLLER_CLASS or ICC_COOL_CLASSES
	invoke InitCommonControlsEx,addr icex
	invoke RegCreateKeyEx,HKEY_CURRENT_USER,addr szResEd,0,addr szREG_SZ,0,KEY_WRITE or KEY_READ,0,addr hReg,addr lpdwDisp
	.if lpdwDisp==REG_OPENED_EXISTING_KEY
		mov		lpcbData,sizeof wpos
		invoke RegQueryValueEx,hReg,addr szWinPos,0,addr lpType,addr wpos,addr lpcbData
		mov		lpcbData,sizeof nmeexp
		invoke RegQueryValueEx,hReg,addr szNmeExp,0,addr lpType,addr nmeexp,addr lpcbData
		mov		lpcbData,sizeof grdsize
		invoke RegQueryValueEx,hReg,addr szGrid,0,addr lpType,addr grdsize,addr lpcbData
		mov		lpcbData,sizeof col
		invoke RegQueryValueEx,hReg,addr szColor,0,addr lpType,addr col,addr lpcbData
		mov		lpcbData,sizeof initid
		invoke RegQueryValueEx,hReg,addr szInitID,0,addr lpType,addr initid,addr lpcbData
		mov		lpcbData,sizeof textfont
		invoke RegQueryValueEx,hReg,addr szTextFont,0,addr lpType,addr textfont,addr lpcbData
		mov		lpcbData,sizeof ProjectPath
		invoke RegQueryValueEx,hReg,addr szProPath,0,addr lpType,addr ProjectPath,addr lpcbData
		mov		lpcbData,sizeof SystemPath
		invoke RegQueryValueEx,hReg,addr szSysPath,0,addr lpType,addr SystemPath,addr lpcbData
	.endif
	.if wpos.wtpro<5
		mov		wpos.wtpro,150
	.endif
	.if wpos.htpro<5
		mov		wpos.htpro,200
	.endif
	mov		eax,wpos.htout
	mov		winsize.htout,eax
	mov		eax,wpos.wtpro
	mov		winsize.wtpro,eax
	mov		eax,wpos.htpro
	mov		winsize.htpro,eax
	mov		eax,wpos.wttbx
	.if !eax
		mov		eax,52
	.endif
	mov		winsize.wttbx,eax
	mov		eax,wpos.left
	mov		winsize.ptstyle.x,eax
	mov		eax,wpos.top
	mov		winsize.ptstyle.y,eax
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke RegSetValueEx,hReg,addr szWinPos,0,REG_BINARY,addr wpos,sizeof wpos
	xor		ecx,ecx
	mov		edx,offset mruproject
	.while ecx<10
		push	ecx
		push	edx
		push	edx
		invoke MakeKey,addr szMruProject,ecx,addr tmpbuff
		pop		edx
		.if byte ptr [edx]
			invoke RegSetValueEx,hReg,addr tmpbuff,0,REG_SZ,edx,MAX_PATH*2
		.else
			invoke RegDeleteValue,hReg,addr tmpbuff
		.endif
		pop		edx
		pop		ecx
		add		edx,MAX_PATH*2
		inc		ecx
	.endw
	invoke RegCloseKey,hReg
	invoke ResEdUninstall
	invoke UnInstallRAEdit
	.if hRichEd
		invoke FreeLibrary,hRichEd
	.endif
	invoke ExitProcess,0

SetWinCaption proc lpFileName:DWORD
	LOCAL	buffer[sizeof szAppName+3+MAX_PATH]:BYTE
	LOCAL	buffer1[4]:BYTE

	;Add filename to windows caption
	invoke lstrcpy,addr buffer,offset szAppName
	.if lpFileName
		mov		eax,' - '
		mov		dword ptr buffer1,eax
		invoke lstrcat,addr buffer,addr buffer1
		invoke lstrcat,addr buffer,lpFileName
	.endif
	invoke SetWindowText,hWnd,addr buffer
	ret

SetWinCaption endp

LoadProjectFile proc lpFileName:DWORD
    LOCAL   hFile:DWORD
	LOCAL	hMem:DWORD
	LOCAL	hMemRes:DWORD
	LOCAL	dwRead:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	;Open the file
	invoke CreateFile,lpFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*1024
		mov     hMem,eax
		invoke GlobalLock,hMem
		invoke GetFileSize,hFile,NULL
		push	eax
		inc		eax
		invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,eax
		mov     hMemRes,eax
		pop		edx
		invoke ReadFile,hFile,hMemRes,edx,addr dwRead,NULL
		invoke CloseHandle,hFile
		;Copy buffer to ProjectFileName
		invoke lstrcpy,offset ProjectFileName,lpFileName
		.if grdsize.defines
			invoke CreateFile,addr IncludeFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
			.if eax!=INVALID_HANDLE_VALUE
				mov		hFile,eax
				invoke GetFileSize,hFile,NULL
				mov		edx,eax
				invoke ReadFile,hFile,hMem,edx,addr dwRead,NULL
				invoke CloseHandle,hFile
			.endif
		.endif
		invoke lstrcat,hMem,hMemRes
		invoke GlobalFree,hMemRes
		invoke SendMessage,hResEd,PRO_OPEN,offset ProjectFileName,hMem
		invoke SetWinCaption,offset ProjectFileName
		invoke lstrcpy,addr buffer,offset ProjectFileName
		invoke lstrlen,addr buffer
		.while byte ptr buffer[eax]!='\' && eax
			dec		eax
		.endw
		mov		byte ptr buffer[eax],0
		lea		edx,buffer[eax+1]
		;invoke SendMessage,hResEd,PRO_SETNAME,edx,addr buffer
		invoke RemovePath,addr IncludeFileName,addr buffer
		invoke SendMessage,hResEd,PRO_SETDEFINE,0,eax
		invoke AddMruProject
	.else
		invoke MessageBox,hWnd,offset szOpenFileFail,offset szAppName,MB_OK or MB_ICONERROR
		mov		eax,FALSE
	.endif
	ret

LoadProjectFile endp

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	mov		wc.cbSize,SIZEOF WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,OFFSET WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,10000
	mov		wc.lpszClassName,OFFSET szDlgClass
	invoke LoadIcon,hInst,IDI_ICON
	mov		hIcon,eax
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,IDD_DIALOG,NULL,addr WndProc,NULL
	.if wpos.fMax
		mov		eax,SW_MAXIMIZE
	.else
		mov		eax,SW_SHOWNORMAL
	.endif
	invoke ShowWindow,hWnd,eax
	invoke UpdateWindow,hWnd
	;Get command line filename
	mov		eax,CommandLine
	.if byte ptr [eax]
		invoke LoadProjectFile,eax
	.endif
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke IsDialogMessage,hPreview,addr msg
		.if !eax
			invoke IsDialogMessage,hDialog,addr msg
			.if !eax
				invoke TranslateAccelerator,hWnd,hAccel,addr msg
				.if !eax
					invoke TranslateMessage,addr msg
					invoke DispatchMessage,addr msg
				.endif
			.endif
		.endif
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

DoToolBar proc hToolBar:HWND

	;Set toolbar struct size
	invoke SendMessage,hToolBar,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0
	invoke SendMessage,hToolBar,TB_ADDBUTTONS,ntbrbtns,addr tbrbtns
	invoke ImageList_LoadImage,hInstance,IDB_TOOLBAR,16,29,0FF00FFh,IMAGE_BITMAP,LR_CREATEDIBSECTION
	mov		hImlTbr,eax
	invoke SendMessage,hToolBar,TB_SETIMAGELIST,0,hImlTbr
	invoke GrayedImageList,hToolBar
	ret

DoToolBar endp

OpenInclude proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE

	;Zero out the ofn struct
	invoke RtlZeroMemory,addr ofn,sizeof ofn
	;Setup the ofn struct
	mov		ofn.lStructSize,sizeof ofn
	push	hWnd
	pop		ofn.hwndOwner
	push	hInstance
	pop		ofn.hInstance
	mov		ofn.lpstrFilter,offset szHFilterString
	mov		buffer[0],0
	.if ProjectPath
		mov		ofn.lpstrInitialDir,offset ProjectPath
	.endif
	lea		eax,buffer
	mov		ofn.lpstrFile,eax
	mov		ofn.nMaxFile,sizeof buffer
	mov		ofn.lpstrDefExt,NULL
	mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
	mov		ofn.lpstrTitle,offset szIncludeTitle
	.if ProjectFileName
		invoke GetCurrentDirectory,sizeof buffer1,addr buffer1
		lea		eax,buffer1
		mov		ofn.lpstrInitialDir,eax
	.endif
	;Show the Open dialog
	invoke GetOpenFileName,addr ofn
	.if eax
		invoke lstrcpy,addr IncludeFileName,addr buffer
		mov		eax,TRUE
	.endif
	ret

OpenInclude endp

OpenProject proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE

	;Zero out the ofn struct
	invoke RtlZeroMemory,addr ofn,sizeof ofn
	;Setup the ofn struct
	mov		ofn.lStructSize,sizeof ofn
	push	hWnd
	pop		ofn.hwndOwner
	push	hInstance
	pop		ofn.hInstance
	mov		ofn.lpstrFilter,offset szRCFilterString
	mov		buffer[0],0
	.if ProjectPath
		mov		ofn.lpstrInitialDir,offset ProjectPath
	.endif
	lea		eax,buffer
	mov		ofn.lpstrFile,eax
	mov		ofn.nMaxFile,sizeof buffer
	mov		ofn.lpstrDefExt,NULL
	mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
	mov		ofn.lpstrTitle,offset szProjectTitle
	.if ProjectFileName
		invoke GetCurrentDirectory,sizeof buffer1,addr buffer1
		lea		eax,buffer1
		mov		ofn.lpstrInitialDir,eax
	.endif
	;Show the Open dialog
	invoke GetOpenFileName,addr ofn
	.if eax
		.if grdsize.defines==2
			invoke OpenInclude
			.if eax
				invoke LoadProjectFile,addr buffer
			.endif
		.else
			invoke lstrcpy,addr IncludeFileName,addr buffer
			invoke lstrlen,addr IncludeFileName
			.while byte ptr IncludeFileName[eax-1]!='.' && eax
				dec		eax
			.endw
			mov		word ptr IncludeFileName[eax],'h'
			invoke LoadProjectFile,addr buffer
		.endif
	.endif
	ret

OpenProject endp

SaveProject proc lpFileName:DWORD
	LOCAL	hMem:DWORD
	LOCAL	hMemDef:DWORD
	LOCAL	hFile:DWORD
	LOCAL	nSize:DWORD
	LOCAL	buff[MAX_PATH]:BYTE

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*1024
	mov		hMem,eax
	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
	mov		hMemDef,eax
	invoke SendMessage,hResEd,PRO_EXPORT,hMemDef,hMem
	invoke SendMessage,hResEd,MEM_GETERR,0,0
	.if !eax
		invoke CreateFile,lpFileName,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
		.if eax!=INVALID_HANDLE_VALUE
			mov		hFile,eax
			invoke lstrlen,hMem
			mov		nSize,eax
			invoke WriteFile,hFile,hMem,nSize,addr nSize,NULL
			invoke CloseHandle,hFile
			invoke SendMessage,hResEd,PRO_SETMODIFY,FALSE,0
			.if grdsize.defines
;				.if !IncludeFileName
;					invoke lstrcpy,addr IncludeFileName,lpFileName
;					invoke lstrlen,addr IncludeFileName
;					.while byte ptr IncludeFileName[eax-1]!='.' && eax
;						dec		eax
;					.endw
;					mov		word ptr IncludeFileName[eax],'h'
;				.endif
				invoke CreateFile,addr IncludeFileName,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
				.if eax!=INVALID_HANDLE_VALUE
					mov		hFile,eax
					invoke lstrlen,hMemDef
					mov		nSize,eax
					invoke WriteFile,hFile,hMemDef,nSize,addr nSize,NULL
					invoke CloseHandle,hFile
				.endif
			.endif
			.if nmeexp.fAuto
				invoke SendMessage,hResEd,PRO_EXPORTNAMES,1,0
			.endif
			xor		eax,eax
		.endif
	.endif
	push	eax
	invoke GlobalFree,hMem
	invoke GlobalFree,hMemDef
	pop		eax
	ret

SaveProject endp

SaveIncludeFileAs proc lpFileName:DWORD
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke SendMessage,hResEd,PRO_GETMEM,0,0
	.if eax
		;Zero out the ofn struct
		invoke RtlZeroMemory,addr ofn,sizeof ofn
		;Setup the ofn struct
		mov		ofn.lStructSize,sizeof ofn
		push	hWnd
		pop		ofn.hwndOwner
		push	hInstance
		pop		ofn.hInstance
		mov		ofn.lpstrFilter,offset szHFilterString
		.if ProjectPath
			mov		ofn.lpstrInitialDir,offset ProjectPath
		.endif
		invoke lstrcpy,addr buffer,lpFileName
		invoke lstrlen,addr buffer
		.while buffer[eax-1]!='.' && eax
			dec		eax
		.endw
		mov		word ptr buffer[eax],'h'
		lea		eax,buffer
		mov		ofn.lpstrFile,eax
		mov		ofn.nMaxFile,sizeof buffer
		mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT
		mov		ofn.lpstrDefExt,offset szDefHExt
		;Show save as dialog
		invoke GetSaveFileName,addr ofn
		.if eax
			invoke lstrcpy,offset IncludeFileName,addr buffer
			mov		eax,TRUE
		.endif
	.endif
	ret

SaveIncludeFileAs endp

SaveProjectFileAs proc lpFileName:DWORD
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke SendMessage,hResEd,PRO_GETMEM,0,0
	.if eax
		;Zero out the ofn struct
		invoke RtlZeroMemory,addr ofn,sizeof ofn
		;Setup the ofn struct
		mov		ofn.lStructSize,sizeof ofn
		push	hWnd
		pop		ofn.hwndOwner
		push	hInstance
		pop		ofn.hInstance
		mov		ofn.lpstrFilter,offset szRCFilterString
		.if ProjectPath
			mov		ofn.lpstrInitialDir,offset ProjectPath
		.endif
		invoke lstrcpy,addr buffer,lpFileName
		lea		eax,buffer
		mov		ofn.lpstrFile,eax
		mov		ofn.nMaxFile,sizeof buffer
		mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT
		mov		ofn.lpstrDefExt,offset szDefRCExt
		;Show save as dialog
		invoke GetSaveFileName,addr ofn
		.if eax
			.if grdsize.defines==2
				invoke SaveIncludeFileAs,addr buffer
				.if eax
					invoke lstrcpy,offset ProjectFileName,addr buffer
					invoke SetWinCaption,offset ProjectFileName
					invoke lstrlen,addr buffer
					.while byte ptr buffer[eax]!='\' && eax
						dec		eax
					.endw
					mov		byte ptr buffer[eax],0
					lea		edx,buffer[eax+1]
					invoke SendMessage,hResEd,PRO_SETNAME,edx,addr buffer
					invoke RemovePath,addr IncludeFileName,addr buffer
					invoke SendMessage,hResEd,PRO_SETDEFINE,0,eax
					invoke SaveProject,offset ProjectFileName
					.if !eax
						xor		eax,eax
						inc		eax
					.else
						xor		eax,eax
					.endif
				.endif
			.else
				invoke lstrcpy,offset ProjectFileName,addr buffer
				invoke SetWinCaption,offset ProjectFileName
				invoke lstrlen,addr buffer
				.while byte ptr buffer[eax]!='\' && eax
					dec		eax
				.endw
				mov		byte ptr buffer[eax],0
				lea		edx,buffer[eax+1]
				invoke SendMessage,hResEd,PRO_SETNAME,edx,addr buffer
				invoke lstrcpy,addr IncludeFileName,addr ProjectFileName
				invoke lstrlen,addr IncludeFileName
				.while IncludeFileName[eax-1]!='.' && eax
					dec		eax
				.endw
				mov		word ptr IncludeFileName[eax],'h'
				invoke RemovePath,addr IncludeFileName,addr buffer
				invoke SendMessage,hResEd,PRO_SETDEFINE,0,eax
				invoke SaveProject,offset ProjectFileName
				.if !eax
					xor		eax,eax
					inc		eax
				.else
					xor		eax,eax
				.endif
			.endif
		.endif
	.endif
	ret

SaveProjectFileAs endp

ExportDialog proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke SendMessage,hResEd,PRO_GETMEM,0,0
	.if eax
		;Zero out the ofn struct
		invoke RtlZeroMemory,addr ofn,sizeof ofn
		;Setup the ofn struct
		mov		ofn.lStructSize,sizeof ofn
		push	hWnd
		pop		ofn.hwndOwner
		push	hInstance
		pop		ofn.hInstance
		mov		ofn.lpstrFilter,offset szDLGFilterString
		mov		buffer,0
		lea		eax,buffer
		mov		ofn.lpstrFile,eax
		mov		ofn.nMaxFile,sizeof buffer
		mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT
		mov		ofn.lpstrDefExt,offset szDefDLGExt
		;Show save as dialog
		invoke GetSaveFileName,addr ofn
		.if eax
			invoke SendMessage,hResEd,DEM_EXPORTDLG,0,addr buffer
		.endif
	.endif
	ret

ExportDialog endp

SaveProjectFile proc lpFileName:DWORD

	invoke SendMessage,hResEd,PRO_GETMEM,0,0
	.if eax
		invoke lstrcmp,lpFileName,offset szNewFile
		.if !eax
			invoke SaveProjectFileAs,lpFileName
		.else
			invoke SaveProject,lpFileName
			.if !eax
				xor		eax,eax
				inc		eax
			.else
				xor		eax,eax
			.endif
		.endif
	.endif
	ret

SaveProjectFile endp

WantToSaveProject proc lpFileName:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	buffer1[2]:BYTE

	invoke SetFocus,hWnd
	invoke SendMessage,hResEd,PRO_GETMODIFY,0,0
	.if eax
		invoke lstrcpy,addr buffer,offset szWannaSave
		invoke lstrcat,addr buffer,lpFileName
		mov		ax,'?'
		mov		word ptr buffer1,ax
		invoke lstrcat,addr buffer,addr buffer1
		invoke MessageBox,hWnd,addr buffer,offset szAppName,MB_YESNOCANCEL or MB_ICONQUESTION
		.if eax==IDYES
			invoke SaveProjectFile,lpFileName
			dec		eax
			push	eax
			invoke SendMessage,hResEd,PRO_GETMODIFY,0,0
			.if eax
				pop		eax
				push	1
			.endif
			pop		eax
		.elseif eax==IDNO
		    mov		eax,FALSE
		.else
		    mov		eax,TRUE
		.endif
	.endif
	ret

WantToSaveProject endp

ToolBarEnable proc uses ebx

	mov		ebx,hTbr
	invoke SendMessage,hResEd,DEM_CANUNDO,0,0
	invoke SendMessage,ebx,TB_ENABLEBUTTON,IDM_EDIT_UNDO,eax
	invoke SendMessage,hResEd,DEM_CANREDO,0,0
	invoke SendMessage,ebx,TB_ENABLEBUTTON,IDM_EDIT_REDO,eax
	invoke SendMessage,hResEd,DEM_ISSELECTION,0,0
	push	eax
	push	eax
	invoke SendMessage,ebx,TB_ENABLEBUTTON,IDM_EDIT_DELETE,eax
	pop		eax
	invoke SendMessage,ebx,TB_ENABLEBUTTON,IDM_EDIT_CUT,eax
	pop		eax
	invoke SendMessage,ebx,TB_ENABLEBUTTON,IDM_EDIT_COPY,eax
	invoke SendMessage,hResEd,DEM_CANPASTE,0,0
	invoke SendMessage,ebx,TB_ENABLEBUTTON,IDM_EDIT_PASTE,eax
	mov		eax,wpos.fView
	and		eax,1
	invoke SendMessage,ebx,TB_CHECKBUTTON,IDM_VIEW_OUTPUT,eax
	invoke SendMessage,hResEd,DEM_GETMEM,DEWM_DIALOG,0
	invoke SendMessage,ebx,TB_ENABLEBUTTON,IDM_VIEW_PREVIEW,eax
	xor		eax,eax
	.if hPreview
		inc		eax
	.endif
	invoke SendMessage,ebx,TB_CHECKBUTTON,IDM_VIEW_PREVIEW,eax
	ret

ToolBarEnable endp

WndProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hFont:DWORD
	LOCAL	pt:POINT
	LOCAL	rect:RECT
	LOCAL	hMem:DWORD
	LOCAL	nInx:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE
	LOCAL	mnu:MENU
	LOCAL	mii:MENUITEMINFO
	LOCAL	hBr:DWORD
	LOCAL	hPen:DWORD
	LOCAL	mDC:HDC
	LOCAL	lf:LOGFONT
	LOCAL	cust:CUSTSTYLE
	LOCAL	rarstype:RARSTYPE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
		invoke GetModuleFileName,0,addr AppPath,sizeof AppPath
		invoke lstrlen,addr AppPath
		.while byte ptr AppPath[eax]!='\' && eax
			dec		eax
		.endw
		mov		AppPath[eax],0
		invoke SetCurrentDirectory,addr AppPath
		invoke GetDlgItem,hWin,IDC_SBR1
		invoke SendMessage,eax,WM_GETFONT,0,0
		mov		hFont,eax
		invoke MoveWindow,hWin,wpos.x,wpos.y,wpos.wt,wpos.ht,TRUE
		invoke LoadAccelerators,hInstance,IDR_ACCEL
		mov		hAccel,eax
		invoke GetMenu,hWin
		mov		hMnu,eax
		invoke WriteDefHelp
		invoke SetToolMenu
		invoke SetHelpMenu
		invoke LoadMenu,hInstance,IDR_CONTEXT
		mov		hContextMenu,eax
		invoke GetSubMenu,eax,0
		mov		hContextMenuPopup,eax
		invoke GetDlgItem,hWin,IDC_TBR1
		mov		hTbr,eax
		invoke DoToolBar,eax
		mov		edx,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS
		.if grdsize.show
			or		edx,DES_GRID
		.endif
		.if grdsize.snap
			or		edx,DES_SNAPTOGRID
		.endif
		.if grdsize.tips
			or		edx,DES_TOOLTIP
		.endif
		.if grdsize.stylehex
			or		edx,DES_STYLEHEX
		.endif
		.if grdsize.sizetofont
			or		edx,DES_SIZETOFONT
		.endif
		.if grdsize.defines
			or		edx,DES_NODEFINES
		.endif
		.if grdsize.simple
			or		edx,DES_SIMPLEPROPERTY
		.endif
		.if grdsize.defstatic
			or		edx,DES_DEFIDC_STATIC
		.endif
		.if grdsize.borlandcomp
			or		edx,DES_BORLAND
		.endif
		invoke CreateWindowEx,0,addr szResEdClass,0,edx,0,0,0,0,hWin,IDC_RESED,hInstance,0
		mov		hResEd,eax
		invoke SendMessage,eax,WM_SETFONT,hFont,0
		mov		edx,nmeexp.nOutput
		shl		edx,16
		add		edx,nmeexp.nType
		invoke SendMessage,hResEd,PRO_SETEXPORT,edx,addr nmeexp.szFileName
		invoke SendMessage,hResEd,PRO_SETINITID,0,addr initid
		invoke GetDlgItem,hWin,IDC_SBR1
		invoke SendMessage,hResEd,DEM_SETPOSSTATUS,eax,0
		mov		eax,grdsize.y
		shl		eax,16
		add		eax,grdsize.x
		mov		edx,grdsize.line
		shl		edx,24
		add		edx,grdsize.color
		invoke SendMessage,hResEd,DEM_SETGRIDSIZE,eax,edx
		invoke SendMessage,hResEd,DEM_SETCOLOR,0,addr col
		invoke ImageList_Create,16,16,ILC_COLOR8 or ILC_MASK,2,0
		mov		hIml,eax
		invoke LoadBitmap,hInstance,IDB_ARROW
		push	eax
		invoke ImageList_AddMasked,hIml,eax,0C0C0C0h
		pop		eax
		invoke DeleteObject,eax
		invoke ToolBarEnable
		invoke SendMessage,hResEd,DEM_SETSIZE,0,addr winsize
		mov		eax,wpos.fView
		and		eax,1
		invoke SendMessage,hResEd,DEM_SHOWOUTPUT,eax,0
		;Add custom controls
		mov		nInx,1
		mov		ebx,offset hCustDll
		.while nInx<=32
			invoke MakeKey,addr szCust,nInx,addr buffer1
			mov		lpcbData,MAX_PATH
			mov		buffer,0
			invoke RegQueryValueEx,hReg,addr buffer1,0,addr lpType,addr buffer,addr lpcbData
			.if buffer
				invoke SendMessage,hResEd,DEM_ADDCONTROL,0,addr buffer
				.if eax
					mov		[ebx],eax
					add		ebx,4
				.endif
			.endif
			inc		nInx
		.endw
		;Add custom styles
		mov		nInx,1
		.while nInx<=64
			invoke MakeKey,addr szCustStyle,nInx,addr buffer1
			mov		lpcbData,sizeof CUSTSTYLE
			mov		cust.szStyle,0
			invoke RegQueryValueEx,hReg,addr buffer1,0,addr lpType,addr cust,addr lpcbData
			.if cust.szStyle
				invoke SendMessage,hResEd,DEM_ADDCUSTSTYLE,0,addr cust
			.endif
			inc		nInx
		.endw
		;Set resource types
		mov		nInx,1
		mov		ebx,offset hCustDll
		.while nInx<=32
			invoke MakeKey,addr szCustType,nInx,addr buffer1
			mov		lpcbData,sizeof RARSTYPE
			invoke RtlZeroMemory,addr rarstype,sizeof RARSTYPE
			invoke RegQueryValueEx,hReg,addr buffer1,0,addr lpType,addr rarstype,addr lpcbData
			.if rarstype.sztype || rarstype.nid
				mov		edx,nInx
				dec		edx
				invoke SendMessage,hResEd,PRO_SETCUSTOMTYPE,edx,addr rarstype
			.endif
			inc		nInx
		.endw
		;Set mru projects
		mov		nInx,0
		mov		ebx,offset mruproject
		.while nInx<=9
			invoke MakeKey,addr szMruProject,nInx,addr buffer1
			mov		lpcbData,MAX_PATH*2
			invoke RegQueryValueEx,hReg,addr buffer1,0,addr lpType,ebx,addr lpcbData
			.if byte ptr [ebx]
				mov		eax,nInx
				shl		eax,8
				or		eax,' 0&'
				mov		dword ptr buffer,eax
				invoke lstrcpy,offset tmpbuff,ebx
				invoke GetStrItem,offset tmpbuff,addr buffer1
				invoke PathCompactPathEx,addr buffer[3],addr buffer1,30,0
				invoke GetSubMenu,hMnu,0
				mov		edx,eax
				mov		ecx,nInx
				add		ecx,21000
				invoke AppendMenu,edx,MF_STRING,ecx,addr buffer
				add		ebx,MAX_PATH*2
			.endif
			inc		nInx
		.endw
		.if !grdsize.standardmnu
			invoke CoolMenu
		.endif
		invoke RtlZeroMemory,addr lf,sizeof lf
		invoke lstrcpy,addr lf.lfFaceName,addr textfont.lfFaceName
		mov		eax,textfont.lfHeight
		mov		lf.lfHeight,eax
		mov		eax,textfont.lfWeight
		mov		lf.lfWeight,eax
		mov		eax,textfont.lfItalic
		mov		lf.lfItalic,al
		mov		eax,textfont.lfCharSet
		mov		lf.lfCharSet,al
		invoke CreateFontIndirect,addr lf
		invoke SendMessage,hResEd,PRO_SETTEXTFONT,eax,0
		invoke SendMessage,hResEd,PRO_SETSYSTEMPATH,0,addr SystemPath
	.elseif eax==WM_NCACTIVATE
		.if hResEd
			invoke SendMessage,hResEd,DEM_GETMEM,DEWM_DIALOG,0
			.if eax
				invoke SendMessage,eax,WM_NCACTIVATE,wParam,0
			.endif
		.endif
		jmp		ExDef
	.elseif eax==WM_NCMOUSEMOVE
		invoke GetDlgItem,hWin,IDC_SBR1
		invoke SendMessage,eax,SB_SETTEXT,0,offset szNULL
	.elseif eax==WM_MOUSEMOVE
		invoke GetDlgItem,hWin,IDC_SBR1
		invoke SendMessage,eax,SB_SETTEXT,0,offset szNULL
	.elseif eax==WM_CONTEXTMENU
		mov		eax,lParam
		.if eax!=-1
			and		eax,0FFFFh
			cwde
			mov		pt.x,eax
			mov		eax,lParam
			shr		eax,16
			cwde
			mov		pt.y,eax
		.else
			invoke GetWindowRect,hWin,addr rect
			.if hResEd
				invoke SendMessage,hResEd,DEM_GETMEM,DEWM_DIALOG,0
				.if eax
					mov		edx,eax
					invoke GetWindowRect,edx,addr rect
				.endif
			.endif
			mov		eax,rect.left
			add		eax,30
			mov		pt.x,eax
			mov		eax,rect.top
			add		eax,30
			mov		pt.y,eax
		.endif
		mov		eax,wParam
		.if eax==hResEd
			invoke GetSubMenu,hMnu,4
			push	eax
			invoke SendMessage,hWin,WM_INITMENUPOPUP,eax,4
			pop		eax
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWin,0
		.else
			invoke SendMessage,hWin,WM_INITMENUPOPUP,hContextMenuPopup,1
			invoke SendMessage,hWin,WM_INITMENUPOPUP,hContextMenuPopup,2
			invoke TrackPopupMenu,hContextMenuPopup,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWin,0
		.endif
	.elseif eax==WM_INITMENUPOPUP
		mov		eax,lParam
		.if eax==1
			;Edit
			invoke SendMessage,hResEd,DEM_CANUNDO,0,0
			xor		eax,1
			.if eax
				mov		eax,MF_GRAYED
			.endif
			invoke EnableMenuItem,wParam,IDM_EDIT_UNDO,eax
			invoke SendMessage,hResEd,DEM_CANREDO,0,0
			xor		eax,1
			.if eax
				mov		eax,MF_GRAYED
			.endif
			invoke EnableMenuItem,wParam,IDM_EDIT_REDO,eax
			invoke SendMessage,hResEd,DEM_ISSELECTION,0,0
			.if !eax
				mov		ebx,MF_GRAYED
			.else
				xor		ebx,ebx
			.endif
			invoke EnableMenuItem,wParam,IDM_EDIT_DELETE,ebx
			invoke EnableMenuItem,wParam,IDM_EDIT_CUT,ebx
			invoke EnableMenuItem,wParam,IDM_EDIT_COPY,ebx
			invoke SendMessage,hResEd,DEM_CANPASTE,0,0
			xor		eax,1
			.if eax
				mov		eax,MF_GRAYED
			.endif
			invoke EnableMenuItem,wParam,IDM_EDIT_PASTE,eax
		.elseif eax==2
			;Format
			invoke SendMessage,hResEd,DEM_GETTEXTMODE,0,0
			.if eax
				invoke EnableMenuItem,wParam,IDM_FORMAT_LOCK,MF_GRAYED
				invoke EnableMenuItem,wParam,IDM_FORMAT_BACK,MF_GRAYED
				invoke EnableMenuItem,wParam,IDM_FORMAT_FRONT,MF_GRAYED
				invoke EnableMenuItem,wParam,IDM_FORMAT_GRID,MF_GRAYED
				invoke EnableMenuItem,wParam,IDM_FORMAT_SNAP,MF_GRAYED
				invoke EnableMenuItem,wParam,6,MF_BYPOSITION or MF_GRAYED
				invoke EnableMenuItem,wParam,7,MF_BYPOSITION or MF_GRAYED
				invoke EnableMenuItem,wParam,8,MF_BYPOSITION or MF_GRAYED
				invoke EnableMenuItem,wParam,IDM_FORMAT_TABINDEX,MF_GRAYED
				invoke EnableMenuItem,wParam,IDM_FORMAT_AUTOID,MF_GRAYED
			.else
				invoke EnableMenuItem,wParam,IDM_FORMAT_LOCK,0
				invoke EnableMenuItem,wParam,IDM_FORMAT_GRID,0
				invoke EnableMenuItem,wParam,IDM_FORMAT_SNAP,0
				invoke SendMessage,hResEd,DEM_ISLOCKED,0,0
				.if eax
					mov		eax,MF_CHECKED
				.endif
				invoke CheckMenuItem,wParam,IDM_FORMAT_LOCK,eax
				invoke GetWindowLong,hResEd,GWL_STYLE
				and		eax,DES_GRID
				.if eax
					mov		eax,MF_CHECKED
				.endif
				invoke CheckMenuItem,wParam,IDM_FORMAT_GRID,eax
				invoke GetWindowLong,hResEd,GWL_STYLE
				and		eax,DES_SNAPTOGRID
				.if eax
					mov		eax,MF_CHECKED
				.endif
				invoke CheckMenuItem,wParam,IDM_FORMAT_SNAP,eax
				invoke SendMessage,hResEd,DEM_ISBACK,0,0
				.if eax
					mov		eax,MF_GRAYED
				.endif
				invoke EnableMenuItem,wParam,IDM_FORMAT_BACK,eax
				invoke SendMessage,hResEd,DEM_ISFRONT,0,0
				.if eax
					mov		eax,MF_GRAYED
				.endif
				invoke EnableMenuItem,wParam,IDM_FORMAT_FRONT,eax
				invoke SendMessage,hResEd,DEM_ISSELECTION,0,0
				push	eax
				.if eax==2
					mov		ebx,MF_BYPOSITION
				.else
					mov		ebx,MF_BYPOSITION or MF_GRAYED
				.endif
				mov		ecx,wParam
				.if ecx==hContextMenuPopup
					mov		edx,14
				.else
					mov		edx,6
				.endif
				push	edx
				; Align
				invoke EnableMenuItem,wParam,edx,ebx
				pop		edx
				inc		edx
				push	edx
				; Same Size
				invoke EnableMenuItem,wParam,edx,ebx
				pop		edx
				inc		edx
				pop		eax
				push	edx
				.if eax>=1
					; Center in Dialog
					invoke EnableMenuItem,wParam,edx,MF_BYPOSITION
				.else
					invoke EnableMenuItem,wParam,edx,MF_BYPOSITION or MF_GRAYED
				.endif
				invoke SendMessage,hResEd,DEM_GETMEM,DEWM_DIALOG,0
				.if eax
					mov		eax,MF_BYPOSITION
				.else
					mov		eax,MF_BYPOSITION or MF_GRAYED
				.endif
				pop		edx
				inc		edx
				push	edx
				; Set Tabindex
				invoke EnableMenuItem,wParam,edx,eax
				pop		edx
				inc		edx
				; Auto Renumber ID's
				invoke EnableMenuItem,wParam,edx,ebx
			.endif
		.elseif eax==3
			;View
			test	wpos.fView,1
			.if !ZERO?
				mov		eax,MF_BYCOMMAND or MF_CHECKED
			.else
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_VIEW_OUTPUT,eax
			.if hPreview
				mov		eax,MF_BYCOMMAND or MF_CHECKED
			.else
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_VIEW_PREVIEW,eax
			invoke SendMessage,hResEd,DEM_GETMEM,DEWM_DIALOG,0
			.if eax
				mov		eax,MF_BYCOMMAND
			.else
				mov		eax,MF_BYCOMMAND or MF_GRAYED
			.endif
			push	eax
			invoke EnableMenuItem,wParam,IDM_VIEW_PREVIEW,eax
			pop		eax
			invoke EnableMenuItem,wParam,IDM_VIEW_TEXTMODE,eax
			invoke SendMessage,hResEd,DEM_GETTEXTMODE,0,0
			.if eax
				mov		eax,MF_BYCOMMAND or MF_CHECKED
			.else
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_VIEW_TEXTMODE,eax
		.elseif eax==4
			;Project
			invoke SendMessage,hResEd,PRO_GETMEM,0,0
			.if eax
				xor		ebx,ebx
			.else
				mov		ebx,MF_GRAYED
			.endif
			invoke EnableMenuItem,wParam,IDM_PROJECT_ADD_DIALOG,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_ADD_MENU,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_ADD_ACCELERATOR,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_ADD_VERSIONINFO,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_ADD_STRINGTABLE,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_ADD_XPMANIFEST,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_ADD_RCDATA,ebx
			invoke EnableMenuItem,wParam,IDM_PROJRCT_ADD_TOOLBAR,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_LANGUAGE,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_INCLUDE,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_RESOURCE,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_NAMES,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_EXPORT,ebx
			invoke SendMessage,hResEd,PRO_GETSELECTED,0,0
			mov		ebx,MF_GRAYED
			.if eax>=2
				xor		ebx,ebx
			.endif
			invoke EnableMenuItem,wParam,IDM_PROJECT_REMOVE,ebx
			invoke SendMessage,hResEd,PRO_CANUNDO,0,0
			mov		ebx,MF_GRAYED
			.if eax
				xor		ebx,ebx
			.endif
			invoke EnableMenuItem,wParam,IDM_PROJECT_UNDO,ebx
			invoke SendMessage,hResEd,DEM_GETMEM,DEWM_DIALOG,0
			mov		ebx,MF_GRAYED
			.if eax
				xor		ebx,ebx
			.endif
			invoke EnableMenuItem,wParam,IDM_PROJECT_DLGSAVE,ebx
		.endif
	.elseif eax==WM_NOTIFY
		mov		edx,lParam
		mov		eax,[edx].NMHDR.hwndFrom
		.if eax==hResEd
			invoke SendMessage,hResEd,DEM_GETSHOWDIALOG,0,0
			mov		hPreview,eax
			invoke SendMessage,hResEd,PRO_GETDIALOG,0,0
			mov		hDialog,eax
			invoke ToolBarEnable
		.else
			mov		eax,[edx].NMHDR.code
			.if eax==TTN_NEEDTEXT
				;Toolbar tooltip
				mov		edx,(NMHDR ptr [edx]).idFrom
				invoke LoadString,hInstance,edx,addr buffer,sizeof buffer
				lea		eax,buffer
				mov		edx,lParam
				mov		(TOOLTIPTEXT ptr [edx]).lpszText,eax
			.endif
		.endif
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		movzx	eax,ax
		.if eax==IDM_FILE_NEW_PROJECT
			invoke WantToSaveProject,offset ProjectFileName
			.if !eax
				invoke lstrcpy,offset ProjectFileName,offset szNewFile
				mov		IncludeFileName,0
				invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4096
				mov		hMem,eax
				invoke GlobalLock,hMem
				invoke SendMessage,hResEd,PRO_OPEN,offset ProjectFileName,hMem
				invoke SetWinCaption,offset ProjectFileName
				invoke SaveProjectFile,offset ProjectFileName
				.if !eax
					invoke SendMessage,hResEd,PRO_CLOSE,0,0
					invoke SetWinCaption,NULL
				.else
					invoke SendMessage,hResEd,PRO_CLOSE,0,0
					invoke LoadProjectFile,offset ProjectFileName
				.endif
			.endif
		.elseif eax==IDM_FILE_OPEN_PROJECT
			invoke WantToSaveProject,offset ProjectFileName
			.if !eax
				invoke OpenProject
			.endif
		.elseif eax==IDM_FILE_CLOSE_PROJECT
			invoke WantToSaveProject,offset ProjectFileName
			.if !eax
				invoke SendMessage,hResEd,PRO_CLOSE,0,0
				invoke SetWinCaption,NULL
			.endif
		.elseif eax==IDM_FILE_SAVE_PROJECT
			invoke SaveProjectFile,offset ProjectFileName
		.elseif eax==IDM_FILE_SAVE_PROJECT_AS
			invoke SaveProjectFileAs,offset ProjectFileName
		.elseif eax==IDM_FILE_EXIT
			invoke SendMessage,hWin,WM_CLOSE,0,0
		.elseif eax==IDM_EDIT_UNDO
			invoke SendMessage,hResEd,DEM_UNDO,0,0
		.elseif eax==IDM_EDIT_REDO
			invoke SendMessage,hResEd,DEM_REDO,0,0
		.elseif eax==IDM_EDIT_DELETE
			invoke SendMessage,hResEd,DEM_DELETECONTROLS,0,0
		.elseif eax==IDM_EDIT_CUT
			invoke SendMessage,hResEd,DEM_CUT,0,0
		.elseif eax==IDM_EDIT_COPY
			invoke SendMessage,hResEd,DEM_COPY,0,0
		.elseif eax==IDM_EDIT_PASTE
			invoke SendMessage,hResEd,DEM_PASTE,0,0
		.elseif eax==IDM_VIEW_OUTPUT
			xor		wpos.fView,1
			mov		eax,wpos.fView
			and		eax,1
			invoke SendMessage,hResEd,DEM_SHOWOUTPUT,eax,0
			invoke ToolBarEnable
		.elseif eax==IDM_VIEW_PREVIEW
			invoke SendMessage,hResEd,DEM_SHOWDIALOG,0,0
		.elseif eax==IDM_VIEW_TEXTMODE
			invoke SendMessage,hResEd,DEM_GETTEXTMODE,0,0
			xor		eax,1
			invoke SendMessage,hResEd,DEM_SETTEXTMODE,eax,0
		.elseif eax==IDM_FORMAT_LOCK
			invoke SendMessage,hResEd,DEM_ISLOCKED,0,0
			xor		eax,TRUE
			invoke SendMessage,hResEd,DEM_LOCKCONTROLS,0,eax
		.elseif eax==IDM_FORMAT_BACK
			invoke SendMessage,hResEd,DEM_SENDTOBACK,0,0
		.elseif eax==IDM_FORMAT_FRONT
			invoke SendMessage,hResEd,DEM_BRINGTOFRONT,0,0
		.elseif eax==IDM_FORMAT_GRID
			invoke GetWindowLong,hResEd,GWL_STYLE
			xor		eax,DES_GRID
			invoke SetWindowLong,hResEd,GWL_STYLE,eax
		.elseif eax==IDM_FORMAT_SNAP
			invoke GetWindowLong,hResEd,GWL_STYLE
			xor		eax,DES_SNAPTOGRID
			invoke SetWindowLong,hResEd,GWL_STYLE,eax
		.elseif eax==IDM_FORMAT_ALIGN_LEFT
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,ALIGN_LEFT
		.elseif eax==IDM_FORMAT_ALIGN_CENTER
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,ALIGN_CENTER
		.elseif eax==IDM_FORMAT_ALIGN_RIGHT
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,ALIGN_RIGHT
		.elseif eax==IDM_FORMAT_ALIGN_TOP
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,ALIGN_TOP
		.elseif eax==IDM_FORMAT_ALIGN_MIDDLE
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,ALIGN_MIDDLE
		.elseif eax==IDM_FORMAT_ALIGN_BOTTOM
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,ALIGN_BOTTOM
		.elseif eax==IDM_FORMAT_SIZE_WIDTH
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,SIZE_WIDTH
		.elseif eax==IDM_FORMAT_SIZE_HEIGHT
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,SIZE_HEIGHT
		.elseif eax==IDM_FORMAT_SIZE_BOTH
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,SIZE_BOTH
		.elseif eax==IDM_FORMAT_ALIGN_DLGHCENTER
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,ALIGN_DLGHCENTER
		.elseif eax==IDM_FORMAT_ALIGN_DLGVCENTER
			invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,ALIGN_DLGVCENTER
		.elseif eax==IDM_FORMAT_TABINDEX
			invoke SendMessage,hResEd,DEM_SHOWTABINDEX,0,0
		.elseif eax==IDM_FORMAT_AUTOID
			invoke SendMessage,hResEd,DEM_AUTOID,0,0
		.elseif eax==IDM_PROJECT_ADD_DIALOG
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_DIALOG,TRUE
		.elseif eax==IDM_PROJECT_ADD_MENU
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_MENU,TRUE
		.elseif eax==IDM_PROJECT_ADD_ACCELERATOR
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_ACCEL,TRUE
		.elseif eax==IDM_PROJECT_ADD_VERSIONINFO
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_VERSION,TRUE
		.elseif eax==IDM_PROJECT_ADD_STRINGTABLE
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_STRING,TRUE
		.elseif eax==IDM_PROJECT_ADD_XPMANIFEST
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_XPMANIFEST,TRUE
		.elseif eax==IDM_PROJECT_ADD_RCDATA
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_RCDATA,TRUE
		.elseif eax==IDM_PROJRCT_ADD_TOOLBAR
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_TOOLBAR,TRUE
		.elseif eax==IDM_PROJECT_LANGUAGE
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_LANGUAGE,TRUE
		.elseif eax==IDM_PROJECT_INCLUDE
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_INCLUDE,TRUE
		.elseif eax==IDM_PROJECT_RESOURCE
			invoke SendMessage,hResEd,PRO_ADDITEM,TPE_RESOURCE,TRUE
		.elseif eax==IDM_PROJECT_NAMES
			invoke SendMessage,hResEd,PRO_SHOWNAMES,0,0
		.elseif eax==IDM_PROJECT_REMOVE
			invoke SendMessage,hResEd,PRO_DELITEM,0,0
		.elseif eax==IDM_PROJECT_UNDO
			invoke SendMessage,hResEd,PRO_UNDODELETED,0,0
		.elseif eax==IDM_PROJECT_EXPORT
			invoke SendMessage,hResEd,PRO_EXPORTNAMES,0,0
		.elseif eax==IDM_PROJECT_DLGSAVE
			invoke ExportDialog
		.elseif eax==IDM_OPTION_TOOLS
			invoke DialogBoxParam,hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,1
			invoke ResetMenu
		.elseif eax==IDM_OPTION_HELP
			invoke DialogBoxParam,hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,2
			invoke ResetMenu
		.elseif eax==IDM_OPTION_OPTIONS
			invoke DialogBoxParam,hInstance,IDD_TABOPTIONS,hWin,offset TabOptionsProc,0
		.elseif eax==IDM_TOOLS_CLEAR
			invoke MessageBox,hWin,addr szClearMRU,addr szAppName,MB_OKCANCEL or MB_ICONQUESTION
			.if eax==IDOK
				invoke ClearMruProject
			.endif
		.elseif eax==IDM_HELP_ABOUT
			invoke DialogBoxParam,hInstance,IDD_DLGABOUT,hWin,offset AboutProc,0
		.elseif eax>=20000 && eax<=20020
			;Tool
			mov		mnu.szcap,0
			mov		mnu.szcmnd,0
			mov		edx,eax
			sub		edx,19999
			invoke MakeKey,addr szMenuTool,edx,addr buffer
			mov		lpcbData,sizeof mnu
			invoke RegQueryValueEx,hReg,addr buffer,0,addr lpType,addr mnu,addr lpcbData
			movzx	eax,mnu.szcmnd
			.if eax
				invoke ParseCmnd,addr mnu.szcmnd,addr buffer,addr buffer1
				invoke ShellExecute,hWin,NULL,addr buffer,addr buffer1,NULL,SW_SHOWNORMAL
			.endif
		.elseif eax>=30000 && eax<=30020
			;Help
			mov		mnu.szcap,0
			mov		mnu.szcmnd,0
			mov		edx,eax
			sub		edx,29999
			invoke MakeKey,addr szMenuHelp,edx,addr buffer
			mov		lpcbData,sizeof mnu
			invoke RegQueryValueEx,hReg,addr buffer,0,addr lpType,addr mnu,addr lpcbData
			movzx	eax,mnu.szcmnd
			.if eax
				invoke ParseCmnd,addr mnu.szcmnd,addr buffer,addr buffer1
				invoke ShellExecute,hWin,NULL,addr buffer,addr buffer1,NULL,SW_SHOWNORMAL
			.endif
		.elseif eax>=21000 && eax<=21009
			;MRU
			sub		eax,21000
			mov		ecx,MAX_PATH*2
			mul		ecx
			mov		ebx,offset mruproject
			add		ebx,eax
			invoke WantToSaveProject,offset ProjectFileName
			.if !eax
				invoke lstrcpy,addr buffer,ebx
				invoke GetStrItem,addr buffer,offset ProjectFileName
				invoke lstrcpy,offset IncludeFileName,addr buffer
				invoke LoadProjectFile,addr ProjectFileName
			.endif
		.endif
	.elseif eax==WM_SIZE
		;Statusbar
		invoke GetDlgItem,hWin,IDC_SBR1
		push	eax
		invoke MoveWindow,eax,0,0,0,0,FALSE
		pop		edx
		invoke GetWindowRect,edx,addr rect
		mov		ebx,rect.bottom
		sub		ebx,rect.top
		mov		eax,lParam
		movzx	edx,ax
		shr		eax,16
		mov		pt.x,edx
		mov		pt.y,eax
		;ToolBar
		invoke GetDlgItem,hWin,IDC_TBR1
		invoke MoveWindow,eax,0,0,pt.x,25,TRUE
		mov		ecx,pt.x
		mov		edx,pt.y
		sub		edx,25
		sub		edx,ebx
		invoke MoveWindow,hResEd,0,25,ecx,edx,TRUE
	.elseif eax==WM_CLOSE
		invoke SetFocus,hResEd
		invoke WantToSaveProject,offset ProjectFileName
		.if !eax
			invoke SendMessage,hResEd,PRO_CLOSE,0,0
			invoke GetWindowLong,hWin,GWL_STYLE
			test	eax,WS_MAXIMIZE
			.if ZERO?
				test	eax,WS_MINIMIZE
				.if ZERO?
					mov		wpos.fMax,FALSE
					invoke GetWindowRect,hWin,addr rect
					mov		eax,rect.left
					mov		wpos.x,eax
					mov		eax,rect.top
					mov		wpos.y,eax
					mov		eax,rect.right
					sub		eax,rect.left
					mov		wpos.wt,eax
					mov		eax,rect.bottom
					sub		eax,rect.top
					mov		wpos.ht,eax
				.endif
			.else
				mov		wpos.fMax,TRUE
			.endif
			invoke DestroyWindow,hWin
		.endif
	.elseif eax==WM_DESTROY
		invoke SendMessage,hResEd,DEM_GETSIZE,0,addr winsize
		mov		eax,winsize.htpro
		mov		wpos.htpro,eax
		mov		eax,winsize.wtpro
		mov		wpos.wtpro,eax
		mov		eax,winsize.htout
		mov		wpos.htout,eax
		mov		eax,winsize.wttbx
		mov		wpos.wttbx,eax
		mov		eax,winsize.ptstyle.x
		mov		wpos.left,eax
		mov		eax,winsize.ptstyle.y
		mov		wpos.top,eax
		.if hMnuFont
			invoke DeleteObject,hMenuBrushA
			invoke DeleteObject,hMenuBrushB
			invoke DeleteObject,hMnuFont
		.endif
		invoke DestroyIcon,hIcon
		invoke ImageList_Destroy,hIml
		invoke ImageList_Destroy,hImlTbr
		invoke ImageList_Destroy,hImlTbrGray
		invoke DestroyAcceleratorTable,hAccel
		invoke DestroyMenu,hContextMenu
		invoke DestroyWindow,hResEd
		mov		nInx,1
		mov		ebx,offset hCustDll
		.while nInx<=32
			mov		eax,[ebx]
			.if eax
				invoke FreeLibrary,eax
			.endif
			add		ebx,4
			inc		nInx
		.endw
		invoke PostQuitMessage,NULL
	.elseif eax==WM_DROPFILES
		invoke DragQueryFile,wParam,0,addr buffer,sizeof buffer
		invoke WantToSaveProject,offset ProjectFileName
		.if !eax
			invoke LoadProjectFile,addr buffer
		.endif
	.elseif eax==WM_MEASUREITEM
		mov		ebx,lParam
		.if [ebx].MEASUREITEMSTRUCT.CtlType==ODT_MENU
			mov		edx,[ebx].MEASUREITEMSTRUCT.itemData
			.if edx
				push	esi
				mov		esi,edx
				.if ![esi].MENUDATA.tpe
					lea		esi,[esi+sizeof MENUDATA]
					invoke GetDC,NULL
					push	eax
					invoke CreateCompatibleDC,eax
					mov		mDC,eax
					pop		eax
					invoke ReleaseDC,NULL,eax
					invoke SelectObject,mDC,hMnuFont
					push	eax
					mov		rect.left,0
					mov		rect.top,0
					invoke DrawText,mDC,esi,-1,addr rect,DT_CALCRECT or DT_SINGLELINE
					mov		eax,rect.right
					mov		[ebx].MEASUREITEMSTRUCT.itemWidth,eax
					invoke lstrlen,esi
					lea		esi,[esi+eax+1]
					invoke DrawText,mDC,esi,-1,addr rect,DT_CALCRECT or DT_SINGLELINE
					pop		eax
					invoke SelectObject,mDC,eax
					invoke DeleteDC,mDC
					mov		eax,rect.right
					add		eax,25
					add		[ebx].MEASUREITEMSTRUCT.itemWidth,eax
					mov		eax,20
					mov		[ebx].MEASUREITEMSTRUCT.itemHeight,eax
				.else
					mov		eax,10
					mov		[ebx].MEASUREITEMSTRUCT.itemHeight,eax
				.endif
				pop		esi
			.endif
			mov		eax,TRUE
			jmp		ExRet
		.endif
	.elseif eax==WM_DRAWITEM
		mov		ebx,lParam
		.if [ebx].DRAWITEMSTRUCT.CtlType==ODT_MENU
			push	esi
			mov		esi,[ebx].DRAWITEMSTRUCT.itemData
			.if esi
				invoke CreateCompatibleDC,[ebx].DRAWITEMSTRUCT.hdc
				mov		mDC,eax
				mov		rect.left,0
				mov		rect.top,0
				mov		eax,[ebx].DRAWITEMSTRUCT.rcItem.right
				sub		eax,[ebx].DRAWITEMSTRUCT.rcItem.left
				mov		rect.right,eax
				mov		eax,[ebx].DRAWITEMSTRUCT.rcItem.bottom
				sub		eax,[ebx].DRAWITEMSTRUCT.rcItem.top
				mov		rect.bottom,eax
				invoke CreateCompatibleBitmap,[ebx].DRAWITEMSTRUCT.hdc,rect.right,rect.bottom
				invoke SelectObject,mDC,eax
				push	eax
				invoke SelectObject,mDC,hMnuFont
				push	eax
				invoke GetStockObject,WHITE_BRUSH
				invoke FillRect,mDC,addr rect,eax
				invoke FillRect,mDC,addr rect,hMenuBrushB
				.if ![esi].MENUDATA.tpe
					invoke SetBkMode,mDC,TRANSPARENT
					test	[ebx].DRAWITEMSTRUCT.itemState,ODS_SELECTED
					.if !ZERO?
						invoke CreateSolidBrush,0F5BE9Fh
						mov		hBr,eax
						invoke FillRect,mDC,addr rect,hBr
						invoke DeleteObject,hBr
						invoke CreateSolidBrush,800000h
						mov		hBr,eax
						invoke FrameRect,mDC,addr rect,hBr
						invoke DeleteObject,hBr
					.endif
					test	[ebx].DRAWITEMSTRUCT.itemState,ODS_CHECKED
					.if !ZERO?
						; Check mark
						mov		edx,rect.bottom
						sub		edx,16
						shr		edx,1
						invoke ImageList_Draw,hImlTbr,11,mDC,2,edx,ILD_TRANSPARENT
					.else
						; Image
						mov		eax,[esi].MENUDATA.img
						.if eax
							mov		edx,rect.bottom
							sub		edx,16
							shr		edx,1
							dec		eax
							test	[ebx].DRAWITEMSTRUCT.itemState,ODS_GRAYED
							.if ZERO?
								invoke ImageList_Draw,hImlTbr,eax,mDC,2,edx,ILD_TRANSPARENT
							.else
								invoke ImageList_Draw,hImlTbrGray,eax,mDC,2,edx,ILD_TRANSPARENT
							.endif
						.endif
					.endif
					; Text
					test	[ebx].DRAWITEMSTRUCT.itemState,ODS_GRAYED
					.if ZERO?
						invoke GetSysColor,COLOR_MENUTEXT
					.else
						invoke GetSysColor,COLOR_GRAYTEXT
					.endif
					invoke SetTextColor,mDC,eax
					lea		esi,[esi+sizeof MENUDATA]
					invoke lstrlen,esi
					push	eax
					add		rect.left,22
					add		rect.top,2
					sub		rect.right,2
					invoke DrawText,mDC,esi,-1,addr rect,DT_LEFT or DT_VCENTER
					pop		eax
					lea		esi,[esi+eax+1]
					; Accelerator
					invoke DrawText,mDC,esi,-1,addr rect,DT_RIGHT or DT_VCENTER
					sub		rect.left,22
					sub		rect.top,2
					add		rect.right,2
				.else
					invoke CreatePen,PS_SOLID,1,0F5BE9Fh
					invoke SelectObject,mDC,eax
					push	eax
					add		rect.left,21
					add		rect.top,5
					invoke MoveToEx,mDC,rect.left,rect.top,NULL
					invoke LineTo,mDC,rect.right,rect.top
					sub		rect.left,21
					sub		rect.top,5
					pop		eax
					invoke SelectObject,mDC,eax
					invoke DeleteObject,eax
				.endif
				mov		eax,[ebx].DRAWITEMSTRUCT.rcItem.right
				sub		eax,[ebx].DRAWITEMSTRUCT.rcItem.left
				mov		edx,[ebx].DRAWITEMSTRUCT.rcItem.bottom
				sub		edx,[ebx].DRAWITEMSTRUCT.rcItem.top
				invoke BitBlt,[ebx].DRAWITEMSTRUCT.hdc,[ebx].DRAWITEMSTRUCT.rcItem.left,[ebx].DRAWITEMSTRUCT.rcItem.top,eax,edx,mDC,0,0,SRCCOPY
				pop		eax
				invoke SelectObject,mDC,eax
				pop		eax
				invoke SelectObject,mDC,eax
				invoke DeleteObject,eax
				invoke DeleteDC,mDC
			.endif
			pop		esi
			mov		eax,TRUE
			jmp		ExRet
		.endif
	.else
  ExDef:
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		jmp		ExRet
	.endif
  Ex:
	xor    eax,eax
  ExRet:
	ret

WndProc endp

end start
