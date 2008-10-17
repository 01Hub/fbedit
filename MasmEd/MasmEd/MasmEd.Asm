.386
.model flat,stdcall
option casemap:none

include MasmEd.inc
include Tool\CboTool.asm
include Tool\TabTool.asm
include Misc\Misc.asm
include Misc\FileIO.asm
include Misc\Find.asm
include Misc\Make.asm
include Opt\KeyWords.asm
include Opt\MenuOption.asm
include Opt\TabOptions.Asm
include Opt\BuildOption.Asm
include Misc\Print.asm
include Misc\CodeComplete.asm
include About\About.asm
include Block\Block.asm

.code

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax
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
	invoke LoadLibrary,offset szRichEdit
	mov		hRichEd,eax
	invoke GetModuleFileName,0,offset FileName,sizeof FileName
	invoke lstrlen,offset FileName
	mov		edx,offset FileName
	add		edx,eax
  @@:
	dec		edx
	mov		al,[edx]
	.if al=='.' || al=='\'
		mov		byte ptr [edx],0
	.endif
	.if al!='\'
		jmp		@b
	.endif
	inc		edx
	invoke lstrcat,offset szSimEd,edx
	invoke SetCurrentDirectory,offset FileName
	invoke RegCreateKeyEx,HKEY_CURRENT_USER,addr szSimEd,0,addr szREG_SZ,0,KEY_WRITE or KEY_READ,0,addr hReg,addr lpdwDisp
	.if lpdwDisp==REG_OPENED_EXISTING_KEY
		mov		lpcbData,sizeof wpos
		invoke RegQueryValueEx,hReg,addr szWinPos,0,addr lpType,addr wpos,addr lpcbData
		mov		lpcbData,sizeof edopt
		invoke RegQueryValueEx,hReg,addr szEditOpt,0,addr lpType,addr edopt,addr lpcbData
		mov		lpcbData,sizeof lfnt
		invoke RegQueryValueEx,hReg,addr szCodeFont,0,addr lpType,addr lfnt,addr lpcbData
		mov		lpcbData,sizeof lfntlnr
		invoke RegQueryValueEx,hReg,addr szLnrFont,0,addr lpType,addr lfntlnr,addr lpcbData
		mov		lpcbData,sizeof col
		invoke RegQueryValueEx,hReg,addr szColor,0,addr lpType,addr col,addr lpcbData
		.if col.styles==-1
			mov		col.styles,DEFSTYLESCOLOR
		.endif
		.if col.words==-1
			mov		col.words,DEFWORDSCOLOR
		.endif
		mov		lpcbData,sizeof CustColors
		invoke RegQueryValueEx,hReg,addr szCustColors,0,addr lpType,addr CustColors,addr lpcbData

		mov		lpcbData,sizeof nmeexp
		invoke RegQueryValueEx,hReg,addr szNmeExp,0,addr lpType,addr nmeexp,addr lpcbData
		mov		lpcbData,sizeof grdsize
		invoke RegQueryValueEx,hReg,addr szGrid,0,addr lpType,addr grdsize,addr lpcbData

		mov		lpcbData,16*4
		invoke RegQueryValueEx,hReg,addr szKeyWordColor,0,addr lpType,addr kwcol,addr lpcbData
		mov		lpcbData,sizeof ppos
		invoke RegQueryValueEx,hReg,addr szPrnPos,0,addr lpType,addr ppos,addr lpcbData
		mov		eax,ppos.margins.left
		mov		psd.rtMargin.left,eax
		mov		eax,ppos.margins.top
		mov		psd.rtMargin.top,eax
		mov		eax,ppos.margins.right
		mov		psd.rtMargin.right,eax
		mov		eax,ppos.margins.bottom
		mov		psd.rtMargin.bottom,eax
		mov		eax,ppos.pagesize.x
		mov		psd.ptPaperSize.x,eax
		mov		eax,ppos.pagesize.y
		mov		psd.ptPaperSize.y,eax
		mov		lpcbData,sizeof nmeexp
	.endif
	.if wpos.wtfile<50
		mov		wpos.wtfile,175
	.endif
	.if wpos.wtprop<5
		mov		wpos.wtprop,150
	.endif
	.if wpos.htprop<5
		mov		wpos.htprop,200
	.endif
	mov		winsize.htout,0
	mov		eax,wpos.wtprop
	mov		winsize.wtpro,eax
	mov		eax,wpos.htprop
	mov		winsize.htpro,eax
	mov		winsize.wttbx,52
	mov		eax,wpos.left
	mov		winsize.ptstyle.x,eax
	mov		eax,wpos.top
	mov		winsize.ptstyle.y,eax
	invoke OleInitialize,NULL
	invoke InstallRAEdit,hInstance,FALSE
	invoke RAHexEdInstall,hInstance,FALSE
	invoke GridInstall,hInstance,FALSE
	invoke ResEdInstall,hInstance,FALSE
	invoke InstallFileBrowser,hInstance,FALSE
	invoke InstallRACodeComplete,hInstance,FALSE
	invoke ParseApiFile,addr szApiCallFile
	mov		hApiCallMem,eax
	invoke ParseApiFile,addr szApiConstFile
	mov		hApiConstMem,eax
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	push	eax
	invoke UnInstallRAEdit
	invoke RAHexEdUnInstall
	invoke GridUnInstall
	invoke ResEdUninstall
	invoke UnInstallFileBrowser
	invoke UnInstallRACodeComplete
	.if hApiCallMem
		invoke GlobalFree,hApiCallMem
	.endif
	.if hApiConstMem
		invoke GlobalFree,hApiConstMem
	.endif
	.if hRichEd
		invoke FreeLibrary,hRichEd
	.endif
	invoke RegCloseKey,hReg
	invoke OleUninitialize
	pop		eax
	invoke ExitProcess,eax

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
	mov		wc.hbrBackground,COLOR_BTNFACE+1;NULL
	mov		wc.lpszMenuName,IDM_MENU
	mov		wc.lpszClassName,offset ClassName
	invoke LoadIcon,hInst,32106
	mov		hIcon,eax
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc

	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,offset ResProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,NULL
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1;NULL
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szResClassName
	xor		eax,eax
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc

	invoke CreateDialogParam,hInstance,IDD_DLG,NULL,offset WndProc,NULL
	mov		hWnd,eax
	.if wpos.fMax
		mov		eax,SW_MAXIMIZE
	.else
		mov		eax,SW_SHOWNORMAL
	.endif
	invoke ShowWindow,hWnd,eax
	test	wpos.fView,4
	.if !ZERO?
		invoke ShowWindow,hOut,SW_SHOWNA
	.endif
	invoke UpdateWindow,hWnd
	invoke LoadAccelerators,hInstance,IDR_ACCEL
	mov		hAccel,eax
	;Get command line filename
	mov		edx,CmdLine
	.if byte ptr [edx]
		invoke OpenCommandLine,CommandLine
	.else
		mov		lpcbData,sizeof tmpbuff
		invoke RegQueryValueEx,hReg,addr szSession,0,addr lpType,addr tmpbuff,addr lpcbData
		.if byte ptr tmpbuff && edopt.session
			mov		lpcbData,sizeof MainFile
			invoke RegQueryValueEx,hReg,addr szMainFile,0,addr lpType,addr MainFile,addr lpcbData
			invoke RestoreSession,TRUE
		.endif
	.endif
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .break .if !eax
		invoke IsDialogMessage,hFind,addr msg
		.if !eax
			invoke TranslateAccelerator,hWnd,hAccel,addr msg
			.if !eax
				invoke TranslateMessage,addr msg
				invoke DispatchMessage,addr msg
			.endif
		.endif
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

SetBlockDefs proc uses esi,hWin:HWND

	;Reset block defs
	invoke SendMessage,hWin,REM_ADDBLOCKDEF,0,0
	mov		esi,offset blocks
	.while dword ptr [esi]
		invoke SendMessage,hWin,REM_ADDBLOCKDEF,0,[esi]
		add		esi,4
	.endw
	ret

SetBlockDefs endp

RAEditProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_CHAR
		mov		eax,wParam
		.if eax==VK_TAB || eax==VK_RETURN
			invoke IsWindowVisible,hCCLB
			.if eax
				invoke SendMessage,hREd,REM_LOCKUNDOID,TRUE,0
				invoke SendMessage,hREd,EM_EXSETSEL,0,addr ccchrg
				invoke SendMessage,hCCLB,CCM_GETCURSEL,0,0
				invoke SendMessage,hCCLB,CCM_GETITEM,eax,0
				push	eax
				invoke SendMessage,hREd,EM_REPLACESEL,TRUE,eax
				pop		eax
				.if !fLBConst
					push	eax
					invoke lstrlen,eax
					pop		edx
					.if byte ptr [edx+eax+1]
						mov		word ptr LineTxt,','
						invoke SendMessage,hREd,EM_REPLACESEL,TRUE,offset LineTxt
					.endif
				.endif
				invoke SendMessage,hREd,REM_LOCKUNDOID,FALSE,0
				invoke ShowWindow,hCCLB,SW_HIDE
				xor		eax,eax
				mov		fLBConst,eax
				jmp		Ex
			.endif
		.elseif eax==VK_ESCAPE
			invoke ShowWindow,hCCLB,SW_HIDE
			xor		eax,eax
			jmp		Ex
		.endif
	.elseif eax==WM_KEYDOWN
		mov		edx,wParam
		mov		eax,lParam
		shr		eax,16
		and		eax,3FFh
		.if (edx==28h && (eax==150h || eax==50h)) || (edx==26h && (eax==148h || eax==48h)) || (edx==21h && (eax==149h || eax==49h)) || (edx==22h && (eax==151h || eax==51h))
			;Down / Up /PgUp / PgDn
			invoke IsWindowVisible,hCCLB
			.if eax
				invoke PostMessage,hCCLB,uMsg,wParam,lParam
				xor		eax,eax
				jmp		Ex
			.endif
		.endif
	.elseif eax==WM_KILLFOCUS
		invoke ShowWindow,hCCTT,SW_HIDE
	.endif
	invoke CallWindowProc,lpOldRAEditProc,hWin,uMsg,wParam,lParam
  Ex:
	ret

RAEditProc endp

CreateRAEdit proc

	push	hREd
	.if edopt.hilitecmnt
		mov		eax,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or STYLE_NOBACKBUFFER or STYLE_DRAGDROP or STYLE_SCROLLTIP or STYLE_HILITECOMMENT or STYLE_AUTOSIZELINENUM
	.else
		mov		eax,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or STYLE_NOBACKBUFFER or STYLE_DRAGDROP or STYLE_SCROLLTIP or STYLE_AUTOSIZELINENUM
	.endif
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,offset szRAEditClass,NULL,eax,0,0,0,0,hWnd,IDC_RAE,hInstance,0
	mov		hREd,eax
	invoke SendMessage,hREd,REM_SUBCLASS,0,addr RAEditProc
	mov		lpOldRAEditProc,eax
	invoke SetFormat,hREd
	;Set colors
	invoke SendMessage,hREd,REM_SETCOLOR,0,addr col
	.if edopt.linenumber
		invoke CheckDlgButton,hREd,-2,TRUE
		invoke SendMessage,hREd,WM_COMMAND,-2,0
	.endif
	invoke SendMessage,hREd,REM_SETSTYLEEX,STYLEEX_BLOCKGUIDE,0
	invoke SendMessage,hWnd,WM_SIZE,0,0
	pop		eax
	invoke ShowWindow,eax,SW_HIDE
	ret

CreateRAEdit endp

CreateRAHexEd proc
	LOCAL	hefnt:HEFONT

	invoke ShowWindow,hREd,SW_HIDE
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,offset szRAHexEdClassName,NULL,WS_CHILD or WS_VISIBLE,0,0,0,0,hWnd,IDC_HEX,hInstance,0
	mov		hREd,eax
	mov		eax,hFont
	mov		hefnt.hFont,eax
	mov		eax,hLnrFont
	mov		hefnt.hLnrFont,eax
	;Set fonts
	invoke SendMessage,hREd,HEM_SETFONT,0,addr hefnt
	;Set colors
;	invoke SendMessage,hREd,REM_SETCOLOR,0,addr col
	invoke SendMessage,hWnd,WM_SIZE,0,0
	ret

CreateRAHexEd endp

CreateNew proc

	invoke lstrcpy,offset FileName,offset szNewFile
	invoke CreateRAEdit
	invoke TabToolAdd,hREd,offset FileName
	invoke SetWinCaption,offset FileName
	invoke RefreshCombo,hREd
	invoke SetFocus,hREd
	ret

CreateNew endp

CreateNewRes proc
	LOCAL	hMem:DWORD

	invoke lstrcpy,offset FileName,offset szNewFile
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4096
	mov		hMem,eax
	invoke GlobalLock,hMem
	invoke SendMessage,hResEd,PRO_OPEN,offset FileName,hMem
	invoke ShowWindow,hREd,SW_HIDE
	mov		eax,hRes
	mov		hREd,eax
	invoke TabToolAdd,hREd,offset FileName
	invoke SetWinCaption,offset FileName
	invoke ShowWindow,hREd,SW_SHOW
	invoke SendMessage,hWnd,WM_SIZE,0,0
	invoke RefreshCombo,hREd
	invoke SetFocus,hREd
	ret

CreateNewRes endp

MyTimerProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	chrg:CHARRANGE

	.if fTimer
		dec		fTimer
		.if ZERO?
			invoke UpdateAll,IS_RESOURCE_OPEN
			xor		eax,1
			mov		edx,IDM_FILE_NEW_RES
			call	EnableDisable
			mov		eax,ErrID
			mov		edx,IDM_EDIT_CLEARERRORS
			call	EnableDisable
			mov		edx,IDM_EDIT_NEXTERROR
			call	EnableDisable
			xor		eax,eax
			.if szSessionFile
				mov		eax,TRUE
			.endif
			mov		edx,IDM_FILE_CLOSESESSION
			call	EnableDisable
			invoke GetWindowLong,hREd,GWL_ID
			.if eax==IDC_RES
				invoke SendMessage,hResEd,DEM_GETMEM,DEWM_DIALOG,0
				mov		edx,IDM_VIEW_DIALOG
				call	EnableDisable
				mov		edx,IDM_FORMAT_TABINDEX
				call	EnableDisable
				invoke SendMessage,hResEd,DEM_CANUNDO,0,0
				mov		edx,IDM_EDIT_UNDO
				call	EnableDisable
				invoke SendMessage,hResEd,DEM_CANREDO,0,0
				mov		edx,IDM_EDIT_REDO
				call	EnableDisable
				invoke SendMessage,hResEd,DEM_ISSELECTION,0,0
				mov		edx,IDM_EDIT_CUT
				call	EnableDisable
				mov		edx,IDM_EDIT_COPY
				call	EnableDisable
				mov		edx,IDM_EDIT_DELETE
				call	EnableDisable
				mov		edx,IDM_FORMAT_CENTER
				call	EnableDisable
				.if eax!=2
					xor		eax,eax
				.endif
				mov		edx,IDM_FORMAT_ALIGN
				call	EnableDisable
				mov		edx,IDM_FORMAT_SIZE
				call	EnableDisable
				invoke SendMessage,hResEd,DEM_CANPASTE,0,0
				mov		edx,IDM_EDIT_PASTE
				call	EnableDisable
				xor		eax,eax
				mov		edx,IDM_FILE_PRINT
				call	EnableDisable
				mov		edx,IDM_EDIT_SELECTALL
				call	EnableDisable
				mov		edx,IDM_EDIT_FIND
				call	EnableDisable
				mov		edx,IDM_EDIT_FINDNEXT
				call	EnableDisable
				mov		edx,IDM_EDIT_FINDPREV
				call	EnableDisable
				mov		edx,IDM_EDIT_REPLACE
				call	EnableDisable
				xor		eax,eax
				mov		edx,IDM_EDIT_BLOCKMODE
				call	EnableDisable
				mov		edx,IDM_EDIT_BLOCKINSERT
				call	EnableDisable
				mov		edx,IDM_EDIT_TOGGLEBM
				call	EnableDisable
				mov		edx,IDM_EDIT_NEXTBM
				call	EnableDisable
				mov		edx,IDM_EDIT_PREVBM
				call	EnableDisable
				mov		edx,IDM_EDIT_CLEARBM
				call	EnableDisable
				mov		edx,IDM_EDIT_INDENT
				call	EnableDisable
				mov		edx,IDM_EDIT_OUTDENT
				call	EnableDisable
				mov		edx,IDM_EDIT_COMMENT
				call	EnableDisable
				mov		edx,IDM_EDIT_UNCOMMENT
				call	EnableDisable
				mov		eax,TRUE
				mov		edx,IDM_FORMAT_LOCK
				call	EnableDisable
				mov		edx,IDM_FORMAT_GRID
				call	EnableDisable
				mov		edx,IDM_FORMAT_SNAP
				call	EnableDisable
				mov		edx,IDM_RESOURCE_DIALOG
				call	EnableDisable
				mov		edx,IDM_RESOURCE_MENU
				call	EnableDisable
				mov		edx,IDM_RESOURCE_ACCEL
				call	EnableDisable
				mov		edx,IDM_RESOURCE_VERINF
				call	EnableDisable
				mov		edx,IDM_RESOURCE_MANIFEST
				call	EnableDisable
				mov		edx,IDM_RESOURCE_RCDATA
				call	EnableDisable
				mov		edx,IDM_RESOURCE_TOOLBAR
				call	EnableDisable
				mov		edx,IDM_RESOURCE_LANGUAGE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_INCLUDE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_RESOURCE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_STRING
				call	EnableDisable
				mov		edx,IDM_RESOURCE_NAME
				call	EnableDisable
				mov		edx,IDM_RESOURCE_EXPORT
				call	EnableDisable
				mov		edx,IDM_RESOURCE_REMOVE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_UNDO
				call	EnableDisable
				invoke SendMessage,hResEd,DEM_ISBACK,0,0
				xor		eax,TRUE
				mov		edx,IDM_FORMAT_BACK
				call	EnableDisable
				invoke SendMessage,hResEd,DEM_ISFRONT,0,0
				xor		eax,TRUE
				mov		edx,IDM_FORMAT_FRONT
				call	EnableDisable
			.elseif eax==IDC_RAE
				xor		eax,eax
				mov		edx,IDM_FORMAT_LOCK
				call	EnableDisable
				mov		edx,IDM_FORMAT_BACK
				call	EnableDisable
				mov		edx,IDM_FORMAT_FRONT
				call	EnableDisable
				mov		edx,IDM_FORMAT_GRID
				call	EnableDisable
				mov		edx,IDM_FORMAT_SNAP
				call	EnableDisable
				mov		edx,IDM_FORMAT_ALIGN
				call	EnableDisable
				mov		edx,IDM_FORMAT_SIZE
				call	EnableDisable
				mov		edx,IDM_FORMAT_CENTER
				call	EnableDisable
				mov		edx,IDM_FORMAT_TABINDEX
				call	EnableDisable
				mov		edx,IDM_VIEW_DIALOG
				call	EnableDisable
				mov		edx,IDM_RESOURCE_DIALOG
				call	EnableDisable
				mov		edx,IDM_RESOURCE_MENU
				call	EnableDisable
				mov		edx,IDM_RESOURCE_ACCEL
				call	EnableDisable
				mov		edx,IDM_RESOURCE_VERINF
				call	EnableDisable
				mov		edx,IDM_RESOURCE_MANIFEST
				call	EnableDisable
				mov		edx,IDM_RESOURCE_RCDATA
				call	EnableDisable
				mov		edx,IDM_RESOURCE_TOOLBAR
				call	EnableDisable
				mov		edx,IDM_RESOURCE_LANGUAGE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_INCLUDE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_RESOURCE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_STRING
				call	EnableDisable
				mov		edx,IDM_RESOURCE_NAME
				call	EnableDisable
				mov		edx,IDM_RESOURCE_EXPORT
				call	EnableDisable
				mov		edx,IDM_RESOURCE_REMOVE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_UNDO
				call	EnableDisable
				mov		eax,TRUE
				mov		edx,IDM_FILE_PRINT
				call	EnableDisable
				mov		edx,IDM_EDIT_SELECTALL
				call	EnableDisable
				mov		edx,IDM_EDIT_TOGGLEBM
				call	EnableDisable
				mov		edx,IDM_EDIT_FIND
				call	EnableDisable
				mov		edx,IDM_EDIT_REPLACE
				call	EnableDisable
				mov		edx,IDM_EDIT_FINDNEXT
				call	EnableDisable
				mov		edx,IDM_EDIT_FINDPREV
				call	EnableDisable
				invoke SendMessage,hREd,EM_CANUNDO,0,0
				mov		edx,IDM_EDIT_UNDO
				call	EnableDisable
				invoke SendMessage,hREd,EM_CANREDO,0,0
				mov		edx,IDM_EDIT_REDO
				call	EnableDisable
				invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
				mov		eax,chrg.cpMax
				sub		eax,chrg.cpMin
				mov		edx,IDM_EDIT_CUT
				call	EnableDisable
				mov		edx,IDM_EDIT_COPY
				call	EnableDisable
				mov		edx,IDM_EDIT_DELETE
				call	EnableDisable
				mov		edx,IDM_EDIT_INDENT
				call	EnableDisable
				mov		edx,IDM_EDIT_OUTDENT
				call	EnableDisable
				mov		edx,IDM_EDIT_COMMENT
				call	EnableDisable
				mov		edx,IDM_EDIT_UNCOMMENT
				call	EnableDisable
				invoke SendMessage,hREd,EM_CANPASTE,CF_TEXT,0
				mov		edx,IDM_EDIT_PASTE
				call	EnableDisable
				invoke SendMessage,hREd,REM_GETMODE,0,0
				and		eax,MODE_BLOCK
				mov		edx,IDM_EDIT_BLOCKINSERT
				call	EnableDisable
				.if !eax
					mov		eax,MF_BYCOMMAND or MF_UNCHECKED
				.else
					mov		eax,MF_BYCOMMAND or MF_CHECKED
				.endif
				invoke CheckMenuItem,hMnu,IDM_EDIT_BLOCKMODE,eax
				mov		eax,TRUE
				mov		edx,IDM_EDIT_BLOCKMODE
				call	EnableDisable
				invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,chrg.cpMin
				mov		ebx,eax
				invoke SendMessage,hREd,REM_NXTBOOKMARK,ebx,3
				inc		eax
				mov		edx,IDM_EDIT_NEXTBM
				call	EnableDisable
				invoke SendMessage,hREd,REM_PRVBOOKMARK,ebx,3
				inc		eax
				mov		edx,IDM_EDIT_PREVBM
				call	EnableDisable
				invoke SendMessage,hREd,REM_NXTBOOKMARK,-1,3
				inc		eax
				mov		edx,IDM_EDIT_CLEARBM
				call	EnableDisable
			.elseif eax==IDC_HEX
				xor		eax,eax
				mov		edx,IDM_FORMAT_LOCK
				call	EnableDisable
				mov		edx,IDM_FORMAT_BACK
				call	EnableDisable
				mov		edx,IDM_FORMAT_FRONT
				call	EnableDisable
				mov		edx,IDM_FORMAT_GRID
				call	EnableDisable
				mov		edx,IDM_FORMAT_SNAP
				call	EnableDisable
				mov		edx,IDM_FORMAT_ALIGN
				call	EnableDisable
				mov		edx,IDM_FORMAT_SIZE
				call	EnableDisable
				mov		edx,IDM_FORMAT_CENTER
				call	EnableDisable
				mov		edx,IDM_VIEW_DIALOG
				call	EnableDisable
				mov		edx,IDM_RESOURCE_DIALOG
				call	EnableDisable
				mov		edx,IDM_RESOURCE_MENU
				call	EnableDisable
				mov		edx,IDM_RESOURCE_ACCEL
				call	EnableDisable
				mov		edx,IDM_RESOURCE_VERINF
				call	EnableDisable
				mov		edx,IDM_RESOURCE_MANIFEST
				call	EnableDisable
				mov		edx,IDM_RESOURCE_RCDATA
				call	EnableDisable
				mov		edx,IDM_RESOURCE_TOOLBAR
				call	EnableDisable
				mov		edx,IDM_RESOURCE_LANGUAGE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_INCLUDE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_RESOURCE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_STRING
				call	EnableDisable
				mov		edx,IDM_RESOURCE_NAME
				call	EnableDisable
				mov		edx,IDM_RESOURCE_EXPORT
				call	EnableDisable
				mov		edx,IDM_RESOURCE_REMOVE
				call	EnableDisable
				mov		edx,IDM_RESOURCE_UNDO
				call	EnableDisable
				mov		edx,IDM_FILE_PRINT
				call	EnableDisable
				mov		edx,IDM_EDIT_INDENT
				call	EnableDisable
				mov		edx,IDM_EDIT_OUTDENT
				call	EnableDisable
				mov		edx,IDM_EDIT_COMMENT
				call	EnableDisable
				mov		edx,IDM_EDIT_UNCOMMENT
				call	EnableDisable

				mov		eax,TRUE
				mov		edx,IDM_EDIT_SELECTALL
				call	EnableDisable
				mov		edx,IDM_EDIT_TOGGLEBM
				call	EnableDisable
				mov		edx,IDM_EDIT_FIND
				call	EnableDisable
				mov		edx,IDM_EDIT_REPLACE
				call	EnableDisable
				mov		edx,IDM_EDIT_FINDNEXT
				call	EnableDisable
				mov		edx,IDM_EDIT_FINDPREV
				call	EnableDisable

				invoke SendMessage,hREd,EM_CANUNDO,0,0
				mov		edx,IDM_EDIT_UNDO
				call	EnableDisable
				invoke SendMessage,hREd,EM_CANREDO,0,0
				mov		edx,IDM_EDIT_REDO
				call	EnableDisable
				invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
				mov		eax,chrg.cpMax
				sub		eax,chrg.cpMin
				mov		edx,IDM_EDIT_CUT
				call	EnableDisable
				mov		edx,IDM_EDIT_COPY
				call	EnableDisable
				mov		edx,IDM_EDIT_DELETE
				call	EnableDisable

				invoke SendMessage,hREd,EM_CANPASTE,CF_TEXT,0
				mov		edx,IDM_EDIT_PASTE
				call	EnableDisable

				xor		eax,eax
				mov		edx,IDM_EDIT_BLOCKMODE
				call	EnableDisable
				mov		edx,IDM_EDIT_BLOCKINSERT
				call	EnableDisable

				invoke SendMessage,hREd,HEM_ANYBOOKMARKS,0,0
				mov		edx,IDM_EDIT_NEXTBM
				call	EnableDisable
				mov		edx,IDM_EDIT_PREVBM
				call	EnableDisable
				mov		edx,IDM_EDIT_CLEARBM
				call	EnableDisable
			.endif
			xor		eax,eax
			test	wpos.fView,4
			.if !ZERO?
				inc		eax
			.endif
			invoke SendMessage,hTbr,TB_CHECKBUTTON,IDM_VIEW_OUTPUT,eax
			INVOKE ShowSession
			invoke GetCapture
			.if !eax
				invoke UpdateAll,IS_CHANGED
			.else
				mov		fTimer,2
			.endif
		.endif
	.endif
	ret

EnableDisable:
	push	eax
	push	edx
	.if eax
		mov		eax,MF_BYCOMMAND or MF_ENABLED
	.else
		mov		eax,MF_BYCOMMAND or MF_GRAYED
	.endif
	invoke EnableMenuItem,hMnu,edx,eax
	pop		edx
	pop		eax
	push	eax
	push	edx
	.if eax
		mov		eax,TRUE
	.endif
	invoke SendMessage,hTbr,TB_ENABLEBUTTON,edx,eax
	pop		edx
	pop		eax
	retn

MyTimerProc endp

ResProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	pt:POINT
	LOCAL	rect:RECT
	LOCAL	rescol:COLOR
	LOCAL	min:DWORD
	LOCAL	max:DWORD

	mov		eax,uMsg
	.if eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,hResEd,0,0,rect.right,rect.bottom,TRUE
	.elseif eax==WM_CREATE
		mov		ebx,lParam
		mov		ebx,[ebx].CREATESTRUCT.lpCreateParams
		mov		edx,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or WS_CLIPCHILDREN; or WS_VSCROLL or WS_HSCROLL
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
		invoke CreateWindowEx,0,addr szResEdClass,0,edx,0,0,0,0,hWin,IDC_DLGEDIT,hInstance,0
		mov		hResEd,eax
		invoke SendMessage,eax,WM_SETFONT,ebx,0
		mov		edx,nmeexp.nOutput
		shl		edx,16
		add		edx,nmeexp.nType
		invoke SendMessage,hResEd,PRO_SETEXPORT,edx,addr nmeexp.szFileName
		invoke SendMessage,hResEd,DEM_SETSIZE,0,addr winsize
		mov		eax,grdsize.y
		shl		eax,16
		add		eax,grdsize.x
		mov		edx,grdsize.line
		shl		edx,24
		add		edx,grdsize.color
		invoke SendMessage,hResEd,DEM_SETGRIDSIZE,eax,edx
	.elseif eax==WM_DESTROY
		invoke SendMessage,hResEd,DEM_GETSIZE,0,addr winsize
		mov		eax,winsize.htpro
		mov		eax,wpos.htprop
		mov		eax,winsize.wtpro
		mov		wpos.wtprop,eax
		mov		eax,winsize.ptstyle.x
		mov		wpos.left,eax
		mov		eax,winsize.ptstyle.y
		mov		wpos.top,eax
		invoke DestroyWindow,hResEd
	.elseif eax==EM_GETMODIFY
		invoke SendMessage,hResEd,PRO_GETMODIFY,0,0
		jmp		Ex
	.elseif eax==EM_SETMODIFY
		invoke SendMessage,hResEd,PRO_SETMODIFY,wParam,0
		jmp		Ex
	.elseif eax==EM_UNDO
		invoke SendMessage,hResEd,DEM_UNDO,0,0
		jmp		Ex
	.elseif eax==EM_REDO
		invoke SendMessage,hResEd,DEM_REDO,0,0
		jmp		Ex
	.elseif eax==WM_CUT
		invoke SendMessage,hResEd,DEM_CUT,0,0
		jmp		Ex
	.elseif eax==WM_COPY
		invoke SendMessage,hResEd,DEM_COPY,0,0
		jmp		Ex
	.elseif eax==WM_PASTE
		invoke SendMessage,hResEd,DEM_PASTE,0,0
		jmp		Ex
	.elseif eax==WM_CLEAR
		invoke SendMessage,hResEd,DEM_DELETECONTROLS,0,0
		jmp		Ex
	.elseif eax==WM_NOTIFY
		.if !fResNotify
			inc		fResNotify
			invoke SendMessage,hResEd,PRO_GETMODIFY,0,0
			.if eax
				invoke GetWindowLong,hWin,GWL_USERDATA
				.if ![eax].TABMEM.fchanged
					invoke TabToolSetChanged,hWin,TRUE
				.endif
			.endif
			mov		fTimer,1
			dec		fResNotify
		.endif
		xor		eax,eax
		jmp		Ex
	.endif
	invoke DefWindowProc,hWin,uMsg,wParam,lParam
  Ex:
	ret

ResProc endp

WndProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	pt:POINT
	LOCAL	rect:RECT
	LOCAL	tmprect:RECT
	LOCAL	ht:DWORD
	LOCAL	chrg:CHARRANGE
	LOCAL	cf:CHOOSEFONT
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[MAX_PATH]:BYTE
	LOCAL	mnu:MENU
	LOCAL	nInx:DWORD
	LOCAL	hebmk:HEBMK
	LOCAL	min:DWORD
	LOCAL	max:DWORD

	mov		eax,uMsg
	.if eax==WM_LBUTTONDOWN
		.if fVSplit==1
			invoke SetCapture,hWin
			invoke SetCursor,hHSplitCur
			mov		fVSplit,2
		.elseif fVSplit==3
			invoke SetCapture,hWin
			invoke SetCursor,hVSplitCur
			mov		fVSplit,4
		.endif
	.elseif eax==WM_LBUTTONUP
		.if fVSplit
			invoke ReleaseCapture
			mov		fVSplit,0
		.endif
	.elseif eax==WM_MOUSEMOVE
		invoke GetWindowRect,hSbr,addr rect
		mov		eax,rect.bottom
		sub		eax,rect.top
		push	eax
		invoke GetClientRect,hWin,addr rect
		pop		eax
		test	wpos.fView,2
		.if !ZERO?
			sub		rect.bottom,eax
		.endif
		test	wpos.fView,4
		.if !ZERO?
			mov		eax,wpos.htout
			add		eax,4
			sub		rect.bottom,eax
		.endif
		test	wpos.fView,8
		.if !ZERO?
			mov		eax,wpos.wtfile
			sub		rect.right,eax
		.endif
		test	wpos.fView,1
		.if !ZERO?
			add		rect.top,27
		.endif
		add		rect.top,TABHT
		invoke GetCursorPos,addr pt
		invoke ScreenToClient,hWin,addr pt
		.if fVSplit==0 || fVSplit==1 || fVSplit==3
			mov		fVSplit,0
			mov		eax,pt.x
			mov		edx,pt.y
			.if eax<rect.right && edx>rect.bottom
				invoke SetCursor,hHSplitCur
				mov		fVSplit,1
			.elseif eax>=rect.right && edx>rect.top
				invoke SetCursor,hVSplitCur
				mov		fVSplit,3
			.endif
		.elseif fVSplit==2
			xor		eax,eax
			test	wpos.fView,2
			.if !ZERO?
				;Get height of statusbar
				invoke GetWindowRect,hSbr,addr rect
				mov		eax,rect.bottom
				sub		eax,rect.top
			.endif
			mov		max,eax
			xor		eax,eax
			test	wpos.fView,1
			.if !ZERO?
				;Get height of toolbar
				invoke GetWindowRect,hTbr,addr rect
				mov		eax,rect.bottom
				sub		eax,rect.top
			.endif
			add		eax,TABHT
			add		eax,32
			mov		min,eax
			invoke GetClientRect,hWin,addr rect
			mov		eax,rect.bottom
			sub		eax,max
			push	eax
			sub		eax,30
			mov		max,eax
			pop		eax
			mov		edx,pt.y
			.if sdword ptr edx>max
				mov		edx,max
			.elseif sdword ptr edx<min
				mov		edx,min
			.endif
			sub		eax,edx
			sub		eax,RESIZEHT
			.if eax!=wpos.htout
				mov		wpos.htout,eax
				invoke SendMessage,hWin,WM_SIZE,0,0
				invoke UpdateWindow,hREd
				invoke UpdateWindow,hOut
			.endif
		.elseif fVSplit==4
			invoke GetClientRect,hWin,addr rect
			mov		eax,rect.right
			sub		eax,50
			mov		max,eax
			mov		min,50
			mov		eax,pt.x
			sub		eax,rect.right
			neg		eax
			.if sdword ptr eax>max
				mov		eax,max
			.endif
			.if sdword ptr eax<min
				mov		eax,min
			.endif
			.if eax!=wpos.wtfile
				mov		wpos.wtfile,eax
				invoke SendMessage,hWin,WM_SIZE,0,0
				invoke UpdateWindow,hREd
				invoke UpdateWindow,hOut
			.endif
		.endif
	.elseif eax==WM_SIZE
		;Get size of windows client area
		invoke GetClientRect,hWin,addr rect
		test	wpos.fView,1
		.if !ZERO?
			;Resize toolbar
			.if lParam
				invoke MoveWindow,hShp,0,0,rect.right,27,TRUE
				invoke ShowWindow,hShp,SW_SHOW
				mov		eax,rect.right
				sub		eax,4
				invoke MoveWindow,hTbr,2,2,eax,23,TRUE
				invoke ShowWindow,hTbr,SW_SHOW
			.endif
			mov		eax,27
		.else
			invoke ShowWindow,hShp,SW_HIDE
			invoke ShowWindow,hTbr,SW_HIDE
			xor		eax,eax
		.endif
		push	eax
		test	wpos.fView,2
		.if !ZERO?
			;Resize statusbar
			.if lParam
				mov		eax,rect.bottom
				sub		eax,21
				invoke MoveWindow,hSbr,0,eax,rect.right,21,TRUE
				invoke ShowWindow,hSbr,SW_SHOW
			.endif
			;Get height of statusbar
			invoke GetWindowRect,hSbr,addr tmprect
			mov		eax,tmprect.bottom
			sub		eax,tmprect.top
		.else
			invoke ShowWindow,hSbr,SW_HIDE
			xor		eax,eax
		.endif
		push	eax
		;Get size of windows client area
		invoke GetClientRect,hWin,addr rect
		;Subtract height of statusbar from bottom
		pop		eax
		sub		rect.bottom,eax
		;Add height of toolbar to top
		pop		eax
		add		rect.top,eax
		.if lParam
			;Resize tab window
			mov		edx,rect.right
			sub		edx,CBOWT
			push	edx
			sub		edx,17
			push	edx
			mov		eax,rect.top
			add		eax,5
			invoke MoveWindow,hBtn,edx,eax,16,16,TRUE
			pop		edx
			;dec		edx
			invoke MoveWindow,hTab,-1,rect.top,edx,TABHT,TRUE
			invoke UpdateWindow,hTab
			pop		edx
			;Resize combobox
			mov		eax,rect.right
			sub		eax,edx
			invoke MoveWindow,hCbo,edx,rect.top,eax,CBOWT,TRUE
			invoke UpdateWindow,hCbo
		.endif
		;Add height of tab window to top
		add		rect.top,TABHT
		test	wpos.fView,8
		.if !ZERO?
			;Resize file browser
			mov		eax,wpos.wtfile
			sub		rect.right,eax
			mov		edx,rect.bottom
			sub		edx,rect.top
			mov		ecx,rect.right
			add		ecx,RESIZEHT
			sub		eax,RESIZEHT
			invoke MoveWindow,hBrowse,ecx,rect.top,eax,edx,TRUE
		.endif
		test	wpos.fView,4
		.if !ZERO?
			;Subtract height of resize from bottom
			sub		rect.bottom,RESIZEHT
			;Subtract height of output from bottom
			mov		eax,wpos.htout
			sub		rect.bottom,eax
		.endif
		;Get new height of RAEdit window
		mov		eax,rect.bottom
		sub		eax,rect.top
		mov		ht,eax
		;Resize RAEdit window
		invoke MoveWindow,hREd,0,rect.top,rect.right,ht,TRUE
		test	wpos.fView,4
		.if !ZERO?
			mov		eax,ht
			add		eax,RESIZEHT
			add		rect.top,eax
			;Resize Output window
			invoke MoveWindow,hOut,0,rect.top,rect.right,wpos.htout,TRUE
			invoke UpdateWindow,hOut
			invoke ShowWindow,hOut,SW_SHOW
		.else
			invoke ShowWindow,hOut,SW_HIDE
		.endif
	.elseif eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
		invoke MoveWindow,hWin,wpos.x,wpos.y,wpos.wt,wpos.ht,TRUE
		mov		fr,FR_DOWN
		mov		eax,wpos.x
		add		eax,30
		mov		findpt.x,eax
		mov		eax,wpos.y
		add		eax,30
		mov		findpt.y,eax
		invoke LoadCursor,hInstance,IDC_HSPLIT
		mov		hHSplitCur,eax
		invoke LoadCursor,hInstance,IDC_VSPLIT
		mov		hVSplitCur,eax
		;Set the toolbar buttons
		invoke GetDlgItem,hWin,IDC_TBR
		mov		hTbr,eax
		invoke DoToolBar,hInstance,eax
		;Statusbar
		invoke GetDlgItem,hWin,IDC_SBR
		mov		hSbr,eax
		invoke DoStatusBar,eax
		;ComboBox
		invoke GetDlgItem,hWin,IDC_CBO
		mov		hCbo,eax
		;Shape
		invoke GetDlgItem,hWin,IDC_SHP
		mov		hShp,eax
		;Close button
		invoke GetDlgItem,hWin,IDC_BTNTABCLOSE
		mov		hBtn,eax
		invoke LoadBitmap,hInstance,111
		invoke SendMessage,hBtn,BM_SETIMAGE,IMAGE_BITMAP,eax
		;Set FileName to NewFile
		invoke lstrcpy,offset FileName,offset szNewFile
		invoke SetWinCaption,offset FileName
		;Create line number font
		invoke CreateFontIndirect,offset lfntlnr
		mov     hLnrFont,eax
		;Create normal font
		invoke CreateFontIndirect,offset lfnt
		mov     hFont,eax
		mov		al,lfnt.lfItalic
		push	eax
		;Create italics font
		mov		lfnt.lfItalic,TRUE
		invoke CreateFontIndirect,offset lfnt
		mov     hIFont,eax
		pop		eax
		mov		lfnt.lfItalic,al
		;Create output window
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,offset szRAEditClass,NULL,WS_CHILD or WS_VISIBLE or STYLE_NOSPLITT or STYLE_NOLINENUMBER or STYLE_NOCOLLAPSE or STYLE_NOHILITE or STYLE_NOBACKBUFFER or STYLE_DRAGDROP or STYLE_SCROLLTIP or STYLE_NOSTATE,0,0,0,0,hWnd,IDC_OUT,hInstance,0
		mov		hOut,eax
		invoke SendMessage,hOut,WM_SETFONT,hFont,FALSE
		invoke CreateRAEdit
		;Create file browser
		invoke CreateWindowEx,0,addr szFBClassName,0,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or FBSTYLE_FLATTOOLBAR,0,0,0,0,hWin,IDC_FILE,hInstance,0
		mov		hBrowse,eax
		invoke SendMessage,hSbr,WM_GETFONT,0,0
		push	eax
		invoke SendMessage,hBrowse,WM_SETFONT,eax,FALSE
		pop		eax
		;Create ResEd
		invoke CreateWindowEx,0,addr szResClassName,0,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or WS_CLIPCHILDREN,0,0,0,0,hWin,IDC_RES,hInstance,eax
		mov		hRes,eax
		;Set hilite words
		invoke SetKeyWords
		;Set colors
		invoke SendMessage,hREd,REM_SETCOLOR,0,addr col
		;and give it focus
		invoke SetFocus,hREd
		;Get handle of tab window
		invoke GetDlgItem,hWin,IDC_TAB
		mov		hTab,eax
		invoke SendMessage,hBrowse,FBM_GETIMAGELIST,0,0
		invoke SendMessage,hTab,TCM_SETIMAGELIST,0,eax
		invoke TabToolAdd,hREd,offset FileName
		invoke GetMenu,hWin
		mov		hMnu,eax
		invoke ImageList_Create,16,16,ILC_COLOR4 or ILC_MASK,4,0
		mov     hMnuIml,eax
		invoke LoadBitmap,hInstance,IDB_MNUARROW
		push	eax
		invoke ImageList_AddMasked,hMnuIml,eax,0C0C0C0h
		pop		eax
		invoke DeleteObject,eax

		invoke SetToolMenu
		invoke SetHelpMenu
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
		invoke lstrcpy,addr CompileRC,addr defCompileRC
		mov		lpcbData,sizeof CompileRC
		invoke RegQueryValueEx,hReg,addr szCompileRC,0,addr lpType,addr CompileRC,addr lpcbData
		invoke lstrcpy,addr Assemble,addr defAssemble
		mov		lpcbData,sizeof Assemble
		invoke RegQueryValueEx,hReg,addr szAssemble,0,addr lpType,addr Assemble,addr lpcbData
		invoke lstrcpy,addr Link,addr defLink
		mov		lpcbData,sizeof Link
		invoke RegQueryValueEx,hReg,addr szLink,0,addr lpType,addr Link,addr lpcbData
		invoke CreateCodeComplete
		invoke UpdateToolColors
		invoke SendMessage,hBrowse,FBM_SETFILTERSTRING,FALSE,addr szFilter
		invoke SendMessage,hBrowse,FBM_SETFILTER,FALSE,TRUE
		mov		lpcbData,sizeof szInitFolder
		invoke RegQueryValueEx,hReg,addr szFolder,0,addr lpType,addr szInitFolder,addr lpcbData
		.if byte ptr szInitFolder
			invoke lstrcpy,addr buffer,addr szInitFolder
		.else
			invoke GetModuleFileName,0,addr buffer,sizeof buffer
		.endif
		invoke SetCurDir,addr buffer,TRUE
		invoke SetTimer,hWin,200,200,addr MyTimerProc
		INVOKE SetBlockDefs,hREd
		mov		fTimer,1
	.elseif eax==WM_COMMAND
		;Menu and toolbar has the same ID's
		mov		eax,wParam
		mov		edx,eax
		movzx	eax,ax
		shr		edx,16
		.if edx==BN_CLICKED || edx==CBN_SELCHANGE
			.if eax==IDM_FILE_NEW
				invoke CreateNew
				mov		fTimer,1
			.elseif eax==IDM_FILE_NEW_RES
				invoke CreateNewRes
				mov		fTimer,1
			.elseif eax==IDM_FILE_OPEN
				invoke OpenEdit
				mov		fTimer,1
			.elseif eax==IDM_FILE_OPEN_HEX
				invoke OpenHex
				mov		fTimer,1
			.elseif eax==IDM_FILE_SAVE
				invoke SaveEdit,hREd,offset FileName
				invoke SetFocus,hREd
			.elseif eax==IDM_FILE_SAVEALL
				invoke UpdateAll,SAVE_ALL
			.elseif eax==IDM_FILE_SAVEAS
				invoke SaveEditAs,hREd,offset FileName
			.elseif eax==IDM_FILE_CLOSE || eax==IDC_BTNTABCLOSE
				invoke WantToSave,hREd,offset FileName
				.if !eax
					mov		eax,hREd
					.if eax!=hRes
						invoke DestroyWindow,eax
					.endif
					invoke TabToolDel,hREd
				.endif
				mov		fTimer,1
			.elseif eax==IDM_FILE_CLOSE_ALL
				invoke UpdateAll,WM_CLOSE
				.if !eax
					mov		szSessionFile,0
					invoke CloseNotify
					invoke UpdateAll,CLOSE_ALL
					invoke CreateNew
				.endif
				mov		fTimer,1
			.elseif eax==IDM_FILE_OPENSESSION
				invoke OpenSessionFile
				mov		fTimer,1
			.elseif eax==IDM_FILE_SAVESESSION
				invoke SaveSessionFile
				mov		fTimer,1
			.elseif eax==IDM_FILE_CLOSESESSION
				invoke UpdateAll,WM_CLOSE
				.if !eax
					invoke AskSaveSessionFile
					.if !eax
						mov		szSessionFile,0
						mov		MainFile,0
						invoke CloseNotify
						invoke UpdateAll,CLOSE_ALL
						invoke CreateNew
					.endif
				.endif
				mov		fTimer,1
			.elseif eax==IDM_FILE_PAGESETUP
				invoke GetPrnCaps
				mov		psd.lStructSize,sizeof psd
				mov		eax,hWin
				mov		psd.hwndOwner,eax
				mov		eax,hInstance
				mov		psd.hInstance,eax
				.if prnInches
					mov		eax,PSD_MARGINS or PSD_INTHOUSANDTHSOFINCHES
				.else
					mov		eax,PSD_MARGINS or PSD_INHUNDREDTHSOFMILLIMETERS
				.endif
				mov		psd.Flags,eax
				invoke PageSetupDlg,addr psd
				.if eax
					mov		eax,psd.rtMargin.left
					mov		ppos.margins.left,eax
					mov		eax,psd.rtMargin.top
					mov		ppos.margins.top,eax
					mov		eax,psd.rtMargin.right
					mov		ppos.margins.right,eax
					mov		eax,psd.rtMargin.bottom
					mov		ppos.margins.bottom,eax
					mov		eax,psd.ptPaperSize.x
					mov		ppos.pagesize.x,eax
					mov		eax,psd.ptPaperSize.y
					mov		ppos.pagesize.y,eax
					invoke RegSetValueEx,hReg,addr szPrnPos,0,REG_BINARY,addr ppos,sizeof ppos
				.endif
			.elseif eax==IDM_FILE_PRINT
				mov		pd.lStructSize,sizeof pd
				mov		eax,hWin
				mov		pd.hwndOwner,eax
				mov		eax,hInstance
				mov		pd.hInstance,eax
				invoke SendMessage,hREd,EM_GETLINECOUNT,0,0
				inc		eax
				mov		ecx,ppos.nlinespage
				.if !ecx
					mov		ecx,66
				.endif
				xor		edx,edx
				div		ecx
				.if edx
					inc		eax
				.endif
				mov		pd.nMinPage,1
				mov		pd.nMaxPage,ax
				mov		pd.nFromPage,1
				mov		pd.nToPage,ax
				invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
				mov		eax,chrg.cpMin
				.if eax!=chrg.cpMax
					mov		eax,PD_RETURNDC or PD_SELECTION
				.else
					mov		eax,PD_RETURNDC or PD_NOSELECTION; or PD_PAGENUMS
				.endif
				mov		pd.Flags,eax
				invoke PrintDlg,addr pd
				.if eax
					invoke Print
				.endif
			.elseif eax==IDM_FILE_EXIT
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax==IDM_EDIT_UNDO
				invoke SendMessage,hREd,EM_UNDO,0,0
			.elseif eax==IDM_EDIT_REDO
				invoke SendMessage,hREd,EM_REDO,0,0
			.elseif eax==IDM_EDIT_DELETE
				invoke SendMessage,hREd,WM_CLEAR,0,0
			.elseif eax==IDM_EDIT_CUT
				invoke SendMessage,hREd,WM_CUT,0,0
			.elseif eax==IDM_EDIT_COPY
				invoke SendMessage,hREd,WM_COPY,0,0
			.elseif eax==IDM_EDIT_PASTE
				invoke SendMessage,hREd,WM_PASTE,0,0
			.elseif eax==IDM_EDIT_SELECTALL
				mov		chrg.cpMin,0
				mov		chrg.cpMax,-1
				invoke SendMessage,hREd,EM_EXSETSEL,0,addr chrg
			.elseif eax==IDM_EDIT_FIND
				.if !hFind
					invoke GetWindowLong,hREd,GWL_ID
					.if eax==IDC_RAE
						invoke GetSelText,offset findbuff
						invoke CreateDialogParam,hInstance,IDD_FINDDLG,hWin,offset FindDlgProc,FALSE
					.elseif eax==IDC_HEX
						invoke CreateDialogParam,hInstance,IDD_HEXFINDDLG,hWin,offset HexFindDlgProc,FALSE
					.endif
				.else
					invoke SetFocus,hFind
				.endif
			.elseif eax==IDM_EDIT_REPLACE
				.if !hFind
					invoke GetWindowLong,hREd,GWL_ID
					.if eax==IDC_RAE
						invoke GetSelText,offset findbuff
						invoke CreateDialogParam,hInstance,IDD_FINDDLG,hWin,addr FindDlgProc,TRUE
					.elseif eax==IDC_HEX
						invoke CreateDialogParam,hInstance,IDD_HEXFINDDLG,hWin,offset HexFindDlgProc,TRUE
					.endif
				.else
					invoke SetFocus,hFind
				.endif
			.elseif eax==IDM_EDIT_FINDNEXT
				.if !hFind
					invoke GetSelText,offset findbuff
				.endif
				invoke GetWindowLong,hREd,GWL_ID
				.if eax==IDC_RAE
					mov		al,findbuff
					.if al
						invoke Find,FR_DOWN
					.endif
				.elseif eax==IDC_HEX
					mov		al,findbuff
					.if al
						invoke HexFind,FR_DOWN or FR_HEX
					.endif
				.endif
			.elseif eax==IDM_EDIT_FINDPREV
				.if !hFind
					invoke GetSelText,offset findbuff
				.endif
				invoke GetWindowLong,hREd,GWL_ID
				.if eax==IDC_RAE
					mov		al,findbuff
					.if al
						invoke Find,0
					.endif
				.elseif eax==IDC_HEX
					mov		al,findbuff
					.if al
						invoke HexFind,FR_HEX
					.endif
				.endif
			.elseif eax==IDM_EDIT_INDENT
				invoke IndentComment,VK_TAB,TRUE
			.elseif eax==IDM_EDIT_OUTDENT
				invoke IndentComment,VK_TAB,FALSE
			.elseif eax==IDM_EDIT_COMMENT
				invoke IndentComment,';',TRUE
			.elseif eax==IDM_EDIT_UNCOMMENT
				invoke IndentComment,';',FALSE
			.elseif eax==IDM_EDIT_BLOCKMODE
				invoke SendMessage,hREd,REM_GETMODE,0,0
				xor		eax,MODE_BLOCK
				invoke SendMessage,hREd,REM_SETMODE,eax,0
				mov		fTimer,1
			.elseif eax==IDM_EDIT_BLOCKINSERT
				invoke CreateDialogParam,hInstance,IDD_BLOCKDLG,hWin,addr BlockDlgProc,0
			.elseif eax==IDM_EDIT_TOGGLEBM
				invoke GetWindowLong,hREd,GWL_ID
				.if eax==IDC_RAE
					invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
					invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,chrg.cpMin
					mov		ebx,eax
					invoke SendMessage,hREd,REM_GETBOOKMARK,ebx,0
					.if !eax
						invoke SendMessage,hREd,REM_SETBOOKMARK,ebx,3
					.elseif eax==3
						invoke SendMessage,hREd,REM_SETBOOKMARK,ebx,0
					.endif
				.elseif eax==IDC_HEX
					invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
					mov		eax,chrg.cpMin
					shr		eax,5
					invoke SendMessage,hREd,HEM_TOGGLEBOOKMARK,eax,0
				.endif
				mov		fTimer,1
			.elseif eax==IDM_EDIT_NEXTBM
				invoke GetWindowLong,hREd,GWL_ID
				.if eax==IDC_RAE
					invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
					invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,chrg.cpMin
					invoke SendMessage,hREd,REM_NXTBOOKMARK,eax,3
					.if eax!=-1
						invoke SendMessage,hREd,EM_LINEINDEX,eax,0
						mov		chrg.cpMin,eax
						mov		chrg.cpMax,eax
						invoke SendMessage,hREd,EM_EXSETSEL,0,addr chrg
						invoke SendMessage,hREd,EM_SCROLLCARET,0,0
					.endif
				.elseif eax==IDC_HEX
					invoke SendMessage,hREd,HEM_NEXTBOOKMARK,0,addr hebmk
					.if eax
						invoke TabToolGetInx,hebmk.hWin
						invoke SendMessage,hTab,TCM_SETCURSEL,eax,0
						invoke TabToolActivate
						mov		eax,hebmk.nLine
						shl		eax,5
						mov		chrg.cpMin,eax
						mov		chrg.cpMax,eax
						invoke SendMessage,hREd,EM_EXSETSEL,0,addr chrg
						invoke SendMessage,hREd,HEM_VCENTER,0,0
					.endif
				.endif
			.elseif eax==IDM_EDIT_PREVBM
				invoke GetWindowLong,hREd,GWL_ID
				.if eax==IDC_RAE
					invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
					invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,chrg.cpMin
					invoke SendMessage,hREd,REM_PRVBOOKMARK,eax,3
					.if eax!=-1
						invoke SendMessage,hREd,EM_LINEINDEX,eax,0
						mov		chrg.cpMin,eax
						mov		chrg.cpMax,eax
						invoke SendMessage,hREd,EM_EXSETSEL,0,addr chrg
						invoke SendMessage,hREd,EM_SCROLLCARET,0,0
					.endif
				.elseif eax==IDC_HEX
					invoke SendMessage,hREd,HEM_PREVIOUSBOOKMARK,0,addr hebmk
					.if eax
						invoke TabToolGetInx,hebmk.hWin
						invoke SendMessage,hTab,TCM_SETCURSEL,eax,0
						invoke TabToolActivate
						mov		eax,hebmk.nLine
						shl		eax,5
						mov		chrg.cpMin,eax
						mov		chrg.cpMax,eax
						invoke SendMessage,hREd,EM_EXSETSEL,0,addr chrg
						invoke SendMessage,hREd,HEM_VCENTER,0,0
					.endif
				.endif
			.elseif eax==IDM_EDIT_CLEARBM
				invoke GetWindowLong,hREd,GWL_ID
				.if eax==IDC_RAE
					invoke SendMessage,hREd,REM_CLRBOOKMARKS,0,3
				.elseif eax==IDC_HEX
					invoke SendMessage,hREd,HEM_CLEARBOOKMARKS,0,0
				.endif
				mov		fTimer,1
			.elseif eax==IDM_EDIT_CLEARERRORS
				invoke UpdateAll,CLEAR_ERRORS
			.elseif eax==IDM_EDIT_NEXTERROR
				mov		eax,nErrID
				mov		eax,ErrID[eax*4]
				.if !eax
					mov		nErrID,0
					mov		eax,ErrID
				.endif
				.if eax
					invoke UpdateAll,FIND_ERROR
					inc		nErrID
				.endif
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
			.elseif eax==IDM_FORMAT_CENTER_HOR
				invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,ALIGN_DLGHCENTER
			.elseif eax==IDM_FORMAT_CENTER_VERT
				invoke SendMessage,hResEd,DEM_ALIGNSIZE,0,ALIGN_DLGVCENTER
			.elseif eax==IDM_FORMAT_TABINDEX
				invoke SendMessage,hResEd,DEM_SHOWTABINDEX,0,0
			.elseif eax==IDM_VIEW_TOOLBAR
				xor		wpos.fView,1
				test	wpos.fView,1
				.if !ZERO?
					invoke ShowWindow,hTbr,SW_SHOWNA
				.else
					invoke ShowWindow,hTbr,SW_HIDE
				.endif
				invoke SendMessage,hWin,WM_SIZE,0,1
			.elseif eax==IDM_VIEW_STATUSBAR
				xor		wpos.fView,2
				test	wpos.fView,2
				.if !ZERO?
					invoke ShowWindow,hSbr,SW_SHOWNA
				.else
					invoke ShowWindow,hSbr,SW_HIDE
				.endif
				invoke SendMessage,hWin,WM_SIZE,0,1
				invoke SendMessage,hOut,WM_SIZE,0,0
				invoke SendMessage,hOut,REM_REPAINT,0,0
			.elseif eax==IDM_VIEW_OUTPUT
				xor		wpos.fView,4
				invoke SendMessage,hWin,WM_SIZE,0,1
				test	wpos.fView,4
				.if !ZERO?
					invoke ShowWindow,hOut,SW_SHOWNA
				.else
					invoke ShowWindow,hOut,SW_HIDE
				.endif
				mov		fTimer,1
			.elseif eax==IDM_VIEW_FILEBROWSER
				xor		wpos.fView,8
				invoke SendMessage,hWin,WM_SIZE,0,1
				test	wpos.fView,8
				.if !ZERO?
					invoke ShowWindow,hBrowse,SW_SHOWNA
				.else
					invoke ShowWindow,hBrowse,SW_HIDE
				.endif
			.elseif eax==IDM_VIEW_DIALOG
				invoke SendMessage,hResEd,DEM_SHOWDIALOG,0,0
			.elseif eax==IDM_RESOURCE_DIALOG
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_DIALOG,TRUE
			.elseif eax==IDM_RESOURCE_MENU
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_MENU,TRUE
			.elseif eax==IDM_RESOURCE_ACCEL
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_ACCEL,TRUE
			.elseif eax==IDM_RESOURCE_VERINF
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_VERSION,TRUE
			.elseif eax==IDM_RESOURCE_MANIFEST
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_XPMANIFEST,TRUE
			.elseif eax==IDM_RESOURCE_RCDATA
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_RCDATA,TRUE
			.elseif eax==IDM_RESOURCE_TOOLBAR
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_TOOLBAR,TRUE
			.elseif eax==IDM_RESOURCE_LANGUAGE
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_LANGUAGE,TRUE
			.elseif eax==IDM_RESOURCE_INCLUDE
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_INCLUDE,TRUE
			.elseif eax==IDM_RESOURCE_RESOURCE
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_RESOURCE,TRUE
			.elseif eax==IDM_RESOURCE_STRING
				invoke SendMessage,hResEd,PRO_ADDITEM,TPE_STRING,TRUE
			.elseif eax==IDM_RESOURCE_NAME
				invoke SendMessage,hResEd,PRO_SHOWNAMES,0,hOut
			.elseif eax==IDM_RESOURCE_EXPORT
				invoke SendMessage,hResEd,PRO_EXPORTNAMES,0,hOut
			.elseif eax==IDM_RESOURCE_REMOVE
				invoke SendMessage,hResEd,PRO_DELITEM,0,0
			.elseif eax==IDM_RESOURCE_UNDO
				invoke SendMessage,hResEd,PRO_UNDODELETED,0,0
			.elseif eax==IDM_MAKE_COMPILE
				invoke UpdateAll,CLEAR_ERRORS
				invoke UpdateAll,SAVE_ALL
				invoke OutputMake,IDM_MAKE_COMPILE,offset MainFile,TRUE
			.elseif eax==IDM_MAKE_ASSEMBLE
				invoke UpdateAll,CLEAR_ERRORS
				invoke UpdateAll,SAVE_ALL
				invoke OutputMake,IDM_MAKE_ASSEMBLE,offset MainFile,TRUE
			.elseif eax==IDM_MAKE_LINK
				invoke UpdateAll,CLEAR_ERRORS
				invoke UpdateAll,SAVE_ALL
				invoke OutputMake,IDM_MAKE_LINK,offset MainFile,TRUE
			.elseif eax==IDM_MAKE_RUN
				invoke UpdateAll,SAVE_ALL
				invoke OutputMake,IDM_MAKE_RUN,offset MainFile,2
			.elseif eax==IDM_MAKE_GO
				invoke UpdateAll,CLEAR_ERRORS
				invoke UpdateAll,SAVE_ALL
				invoke OutputMake,IDM_MAKE_COMPILE,offset MainFile,2
				or		eax,eax
				jne		Ex
				invoke OutputMake,IDM_MAKE_ASSEMBLE,offset MainFile,0
				or		eax,eax
				jne		Ex
				invoke OutputMake,IDM_MAKE_LINK,offset MainFile,3
				or		eax,eax
				jne		Ex
				invoke OutputMake,IDM_MAKE_RUN,offset MainFile,4
			.elseif eax==IDM_MAKE_MAINFILE
				invoke lstrcpy,addr MainFile,addr FileName
				mov		fTimer,1
			.elseif eax==IDM_OPTION_CODE
				invoke DialogBoxParam,hInstance,IDD_DLGKEYWORDS,hWin,offset KeyWordsProc,0
			.elseif eax==IDM_OPTION_DIALOG
				invoke DialogBoxParam,hInstance,IDD_TABOPTIONS,hWin,offset TabOptionsProc,0
			.elseif eax==IDM_OPTION_BUILD
				invoke DialogBoxParam,hInstance,IDD_BUILDOPTION,hWin,offset BuildOptionDialogProc,0
			.elseif eax==IDM_OPTION_TOOLS
				invoke DialogBoxParam,hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,1
				invoke SetToolMenu
			.elseif eax==IDM_OPTION_HELP
				invoke DialogBoxParam,hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,2
				invoke SetHelpMenu
			.elseif eax==IDM_HELP_ABOUT
				invoke DialogBoxParam,hInstance,IDD_DLGABOUT,hWin,offset AboutProc,0
			.elseif ax==-3
				;Expand button clicked
				invoke SendMessage,hREd,REM_EXPANDALL,0,0
				invoke SendMessage,hREd,EM_SCROLLCARET,0,0
				invoke SendMessage,hREd,REM_REPAINT,0,0
			.elseif ax==-4
				;Collapse button clicked
				invoke SendMessage,hREd,REM_COLLAPSEALL,0,0
				invoke SendMessage,hREd,EM_SCROLLCARET,0,0
				invoke SendMessage,hREd,REM_REPAINT,0,0
			.elseif eax==IDM_HELPF1
				;F1-Help key pressed
				mov		mnu.szcap,0
				mov		mnu.szcmnd,0
				invoke lstrcpy,addr buffer,addr szMenuHelp
				invoke lstrlen,addr buffer
				mov		word ptr buffer[eax],'1'
				mov		lpcbData,sizeof mnu
				invoke RegQueryValueEx,hReg,addr buffer,0,addr lpType,addr mnu,addr lpcbData
				movzx	eax,mnu.szcmnd
				.if eax
					invoke SendMessage,hREd,REM_GETWORD,sizeof buffer,addr buffer
					invoke WinHelp,hWin,addr mnu.szcmnd,HELP_KEY,addr buffer
				.endif
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
					invoke ShellExecute,hWin,NULL,addr buffer,addr buffer1,NULL,SW_SHOWNORMAL;SW_SHOWDEFAULT
				.endif
			.elseif eax>=30000 && eax<=30020
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
					invoke ShellExecute,hWin,NULL,addr buffer,addr buffer1,NULL,SW_SHOWNORMAL;SW_SHOWDEFAULT
				.endif
			.elseif eax==IDC_CBO
				invoke SelectCombo
			.endif
		.endif
	.elseif eax==WM_NOTIFY
		mov		edx,lParam
		mov		eax,[edx].NMHDR.code
		mov		ecx,[edx].NMHDR.idFrom
		.if eax==EN_SELCHANGE && ecx==IDC_RAE
			mov		edi,edx
			mov		eax,[edi].RASELCHANGE.chrg.cpMin
			sub		eax,[edi].RASELCHANGE.cpLine
			invoke ShowPos,[edi].RASELCHANGE.line,eax
			.if [edi].RASELCHANGE.seltyp==SEL_OBJECT
				invoke SendMessage,hREd,REM_GETBOOKMARK,[edi].RASELCHANGE.line,0
				.if eax==1
					;Collapse
					invoke SendMessage,hREd,REM_COLLAPSE,[edi].RASELCHANGE.line,0
				.elseif eax==2
					;Expand
					invoke SendMessage,hREd,REM_EXPAND,[edi].RASELCHANGE.line,0
				.elseif eax==8
					;Expand hidden lines
					invoke SendMessage,hREd,REM_EXPAND,[edi].RASELCHANGE.line,0
				.else
					;Clear bookmark
					invoke SendMessage,hREd,REM_SETBOOKMARK,[edi].RASELCHANGE.line,0
				.endif
			.else
				invoke SendMessage,hREd,REM_SETHILITELINE,prvline,0
				mov		eax,[edi].RASELCHANGE.line
				mov		prvline,eax
				.if edopt.hiliteline
					invoke SendMessage,hREd,REM_SETHILITELINE,prvline,2
				.endif
				.if [edi].RASELCHANGE.fchanged
					.if ![edi].RASELCHANGE.nWordGroup
						invoke SendMessage,hREd,REM_SETCOMMENTBLOCKS,addr szCmntStart,addr szCmntEnd
					.endif
				  OnceMore:
					invoke SendMessage,hREd,REM_GETBOOKMARK,nLastLine,0
					mov		ebx,eax
					mov		esi,offset blocks
					mov		ecx,[esi]
					xor		eax,eax
					dec		eax
					.while ecx
						mov		edx,[ecx].RABLOCKDEF.flag
						shr		edx,16
						.if edx==[edi].RASELCHANGE.nWordGroup
							invoke SendMessage,hREd,REM_ISLINE,nLastLine,[ecx].RABLOCKDEF.lpszStart
						.endif
						.break .if eax!=-1
						add		esi,4
						mov		ecx,[esi]
					.endw
					.if eax==-1
						.if ebx==1 || ebx==2
							.if ebx==2
								invoke SendMessage,hREd,REM_EXPAND,nLastLine,0
							.endif
							invoke SendMessage,hREd,REM_SETBOOKMARK,nLastLine,0
							invoke SendMessage,hREd,REM_SETDIVIDERLINE,nLastLine,FALSE
							invoke SendMessage,hREd,REM_SETSEGMENTBLOCK,nLastLine,FALSE
						.endif
					.else
						xor		eax,eax
						mov		ecx,[esi]
						test	[ecx].RABLOCKDEF.flag,BD_NONESTING
						.if !ZERO?
							invoke SendMessage,hREd,REM_ISINBLOCK,nLastLine,ecx
						.endif
						.if !eax
							mov		edx,nLastLine
							inc		edx
							invoke SendMessage,hREd,REM_ISLINEHIDDEN,edx,0
							.if eax
								invoke SendMessage,hREd,REM_SETBOOKMARK,nLastLine,2
							.else
								invoke SendMessage,hREd,REM_SETBOOKMARK,nLastLine,1
							.endif
							mov		edx,[esi]
							mov		edx,[edx].RABLOCKDEF.flag
							and		edx,BD_DIVIDERLINE
							invoke SendMessage,hREd,REM_SETDIVIDERLINE,nLastLine,edx
							mov		edx,[esi]
							mov		edx,[edx].RABLOCKDEF.flag
							and		edx,BD_SEGMENTBLOCK
							invoke SendMessage,hREd,REM_SETSEGMENTBLOCK,nLastLine,edx
						.endif
					.endif
					mov		eax,[edi].RASELCHANGE.line
					.if eax>nLastLine
						inc		nLastLine
						jmp		OnceMore
					.elseif eax<nLastLine
						dec		nLastLine
						jmp		OnceMore
					.endif
				.endif
				.if [edi].RASELCHANGE.fchanged
					invoke ApiListBox,edi
				.endif
				mov		eax,[edi].RASELCHANGE.line
				.if eax!=nLastLine
					mov		nLastLine,eax
					invoke ShowWindow,hCCLB,SW_HIDE
					invoke ShowWindow,hCCTT,SW_HIDE
				.endif
			.endif
			.if [edi].RASELCHANGE.fchanged
				invoke GetWindowLong,hREd,GWL_USERDATA
				.if ![eax].TABMEM.fchanged
					invoke TabToolSetChanged,hREd,TRUE
				.endif
			.endif
			mov		fTimer,2
		.elseif eax==EN_SELCHANGE && ecx==IDC_HEX
			mov		edi,edx
			.if [edi].HESELCHANGE.fchanged
				invoke GetWindowLong,hREd,GWL_USERDATA
				.if ![eax].TABMEM.fchanged
					invoke TabToolSetChanged,hREd,TRUE
				.endif
			.endif
			mov		fTimer,2
		.elseif eax==FBN_DBLCLICK && ecx==IDC_FILE
			invoke OpenEditFile,[edx].FBNOTIFY.lpfile,0
		.elseif eax==TTN_NEEDTEXT
			;Toolbar tooltip
			mov		edx,(NMHDR ptr [edx]).idFrom
			invoke LoadString,hInstance,edx,addr buffer,sizeof buffer
			lea		eax,buffer
			mov		edx,lParam
			mov		(TOOLTIPTEXT ptr [edx]).lpszText,eax
		.elseif eax==TCN_SELCHANGE
			invoke TabToolActivate
		.endif
	.elseif eax==WM_SETFOCUS
		invoke SetFocus,hREd
	.elseif eax==WM_CLOSE
		invoke UpdateAll,WM_CLOSE
		.if !eax
			invoke AskSaveSessionFile
			.if !eax
				invoke MakeSession
				invoke lstrcpy,addr LineTxt,addr tmpbuff
				invoke lstrcpy,addr tmpbuff,addr szSessionFile
				invoke lstrcat,addr tmpbuff,addr szComma
				invoke lstrcat,addr tmpbuff,addr LineTxt
				invoke lstrlen,addr tmpbuff
				inc		eax
				invoke RegSetValueEx,hReg,addr szSession,0,REG_SZ,addr tmpbuff,eax
				invoke SendMessage,hBrowse,FBM_GETPATH,0,addr szInitFolder
				invoke lstrcat,addr szInitFolder,addr szBackSlash
				invoke RegSetValueEx,hReg,addr szFolder,0,REG_SZ,addr szInitFolder,sizeof szInitFolder
				invoke RegSetValueEx,hReg,addr szMainFile,0,REG_SZ,addr MainFile,sizeof MainFile
				invoke CloseNotify
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
				invoke RegSetValueEx,hReg,addr szWinPos,0,REG_BINARY,addr wpos,sizeof wpos
				invoke DestroyWindow,hCCLB
				invoke DestroyWindow,hCCTT
				invoke DestroyWindow,hWin
			.endif
		.endif
	.elseif eax==WM_DESTROY
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
		invoke KillTimer,hWin,200
		invoke UpdateAll,WM_DESTROY
		invoke DeleteObject,hFont
		invoke DeleteObject,hIFont
		invoke DeleteObject,hLnrFont
		invoke DestroyCursor,hVSplitCur
		invoke DestroyCursor,hHSplitCur
		invoke DestroyIcon,hIcon
		invoke ImageList_Destroy,hMnuIml
		invoke DeleteObject,hBrBack
		invoke PostQuitMessage,NULL
	.elseif eax==WM_CONTEXTMENU
		mov		eax,wParam
		.if eax==hREd
			mov		eax,lParam
			.if eax==-1
				invoke GetCaretPos,addr pt
				invoke GetFocus
				mov		edx,eax
				invoke ClientToScreen,edx,addr pt
			.else
				and		eax,0FFFFh
				mov		pt.x,eax
				mov		eax,lParam
				shr		eax,16
				mov		pt.y,eax
			.endif
			invoke GetMenu,hWin
			invoke GetSubMenu,eax,1
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWin,0
			jmp		Ex
		.endif
	.elseif eax==WM_INITMENUPOPUP
		movzx	eax,word ptr lParam
		.if eax==2
			;Format
			invoke SendMessage,hResEd,DEM_ISLOCKED,0,0
			mov		edx,MF_BYCOMMAND
			.if eax
				mov		edx,MF_BYCOMMAND or MF_CHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_FORMAT_LOCK,edx
			invoke GetWindowLong,hResEd,GWL_STYLE
			push	eax
			test	eax,DES_GRID
			mov		edx,MF_BYCOMMAND
			.if !ZERO?
				mov		edx,MF_BYCOMMAND or MF_CHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_FORMAT_GRID,edx
			pop		eax
			test	eax,DES_SNAPTOGRID
			mov		edx,MF_BYCOMMAND
			.if !ZERO?
				mov		edx,MF_BYCOMMAND or MF_CHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_FORMAT_SNAP,edx
		.elseif eax==3
			;View
			mov		edx,MF_BYCOMMAND
			test	wpos.fView,1
			.if !ZERO?
				mov		edx,MF_BYCOMMAND or MF_CHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_VIEW_TOOLBAR,edx
			mov		edx,MF_BYCOMMAND
			test	wpos.fView,2
			.if !ZERO?
				mov		edx,MF_BYCOMMAND or MF_CHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_VIEW_STATUSBAR,edx
			mov		edx,MF_BYCOMMAND
			test	wpos.fView,4
			.if !ZERO?
				mov		edx,MF_BYCOMMAND or MF_CHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_VIEW_OUTPUT,edx
			mov		edx,MF_BYCOMMAND
			test	wpos.fView,8
			.if !ZERO?
				mov		edx,MF_BYCOMMAND or MF_CHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_VIEW_FILEBROWSER,edx
		.endif
	.elseif eax==WM_DROPFILES
		xor		ebx,ebx
	  @@:
		invoke DragQueryFile,wParam,ebx,addr buffer,sizeof buffer
		.if eax
			invoke OpenEditFile,addr buffer,0
			inc		ebx
			jmp		@b
		.endif
	.elseif eax==WM_ACTIVATE
		mov		fTimer,2
	.elseif eax==WM_CTLCOLORLISTBOX || eax==WM_CTLCOLOREDIT
		invoke SetBkColor,wParam,col.toolback
		invoke SetTextColor,wParam,col.tooltext
		mov		eax,hBrBack
		jmp		ExRet
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		jmp		ExRet
	.endif
  Ex:
	xor    eax,eax
  ExRet:
	ret

WndProc endp

end start

