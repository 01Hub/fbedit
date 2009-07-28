.486
.model flat,stdcall
option casemap:none

include MasmEd.inc
include Tool\TabTool.asm
include Tool\PropertyTool.asm
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
	.if byte ptr [eax]
		push	ebx
		mov		ebx,eax
		.while byte ptr [ebx]==VK_SPACE
			inc		ebx
		.endw
		invoke lstrcmpi,ebx,addr szRemoveMasmEd
		.if !eax
			invoke MessageBox,0,addr szAskRemove,addr szAppName,MB_YESNO or MB_ICONQUESTION
			.if eax==IDYES
				invoke RemoveFromRegistry
				invoke ExitProcess,0
			.endif
		.endif
		pop		ebx
	.endif
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
	invoke lstrcat,offset szMasmEd,edx
	invoke SetCurrentDirectory,offset FileName
	invoke lstrcpy,addr AppPath,addr FileName
	invoke RegCreateKeyEx,HKEY_CURRENT_USER,addr szMasmEd,0,addr szREG_SZ,0,KEY_WRITE or KEY_READ,0,addr hReg,addr lpdwDisp
	.if lpdwDisp==REG_OPENED_EXISTING_KEY
		mov		lpcbData,sizeof ver
		invoke RegQueryValueEx,hReg,addr szVer,0,addr lpType,addr ver,addr lpcbData
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
			mov		col.styles,STYLESCOL
		.endif
		.if col.words==-1
			mov		col.words,WORDSCOL
		.endif
		.if ver<1053
			push	esi
			push	edi
			mov		esi,offset col.tttext
			mov		edi,offset col.ttsel
			mov		ecx,12
			.while ecx
				mov		eax,[esi]
				mov		[edi],eax
				sub		esi,4
				sub		edi,4
				dec		ecx
			.endw
			mov		col.racol.changed,CHCOL
			mov		col.racol.changesaved,CHSAVEDCOL
			pop		esi
			pop		edi
			invoke RegSetValueEx,hReg,addr szColor,0,REG_BINARY,addr col,sizeof col
			invoke UpdateTheme1053
			mov		ver,1053
		.endif
		.if ver<1054
			mov		ver,1054
		.endif
		.if ver<1055
			mov		ver,1055
		.endif
		.if ver<1056
			mov		ver,1056
		.endif
		.if ver<1057
			mov		ver,1057
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
	.else
		mov		ver,1057
	.endif
	invoke RegSetValueEx,hReg,addr szVer,0,REG_BINARY,addr ver,sizeof ver
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
	mov		eax,wpos.wttoolbox
	mov		winsize.wttbx,eax
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
	invoke InstallRAProperty,hInstance,FALSE
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	push	eax
	invoke UnInstallRAEdit
	invoke RAHexEdUnInstall
	invoke GridUnInstall
	invoke ResEdUninstall
	invoke UnInstallFileBrowser
	invoke UnInstallRACodeComplete
	invoke UnInstallRAProperty
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
		mov		tmpbuff,0
		mov		lpcbData,sizeof tmpbuff
		invoke RegQueryValueEx,hReg,addr szSession,0,addr lpType,addr tmpbuff,addr lpcbData
		.if byte ptr tmpbuff && edopt.session
			mov		MainFile,0
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
	invoke SendMessage,hWin,REM_BRACKETMATCH,0,offset szBracketMatch
	ret

SetBlockDefs endp

RAEditProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	chrg:CHARRANGE
	LOCAL	ti:TOOLINFO
	LOCAL	buffer[256]:BYTE
	LOCAL	pt:POINT

	mov		eax,uMsg
	.if eax==WM_CHAR
		mov		eax,wParam
		.if eax==VK_TAB || eax==VK_RETURN
			invoke IsWindowVisible,hCCLB
			.if eax
				mov		ccinprogress,eax
				invoke SendMessage,hREd,REM_LOCKUNDOID,TRUE,0
				invoke SendMessage,hREd,EM_EXSETSEL,0,addr ccchrg
				invoke SendMessage,hCCLB,CCM_GETCURSEL,0,0
				invoke SendMessage,hCCLB,CCM_GETITEM,eax,0
				push	eax
				invoke lstrcpy,offset tmpbuff,eax
				xor		eax,eax
				.while tmpbuff[eax]
					.if tmpbuff[eax]==':' || tmpbuff[eax]=='['
						mov		tmpbuff[eax],0
					.endif
					inc		eax
				.endw
				invoke SendMessage,hREd,EM_REPLACESEL,TRUE,offset tmpbuff
				pop		eax
				.if cctype==CCTYPE_PROC
					push	eax
					invoke lstrlen,eax
					pop		edx
					.if byte ptr [edx+eax+1]
						mov		ccinprogress,0
						mov		eax,','
						invoke SendMessage,hREd,WM_CHAR,eax,0
					.endif
				.endif
				invoke SendMessage,hREd,REM_LOCKUNDOID,FALSE,0
				invoke ShowWindow,hCCLB,SW_HIDE
				mov		cctype,CCTYPE_NONE
				xor		eax,eax
				mov		ccinprogress,eax
				jmp		Ex
			.endif
		.elseif eax==VK_ESCAPE
			invoke ShowWindow,hCCLB,SW_HIDE
			mov		cctype,CCTYPE_NONE
			xor		eax,eax
			jmp		Ex
		.elseif eax==VK_SPACE
			invoke GetKeyState,VK_CONTROL
			test		eax,80h
			.if !ZERO?
				mov		cctype,CCTYPE_ALL
				; Force a WM_NOTIFY
				invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
				invoke SendMessage,hREd,EM_EXSETSEL,0,addr chrg
				xor		eax,eax
				jmp		Ex
			.endif
		.elseif eax=='.'
			mov		cctype,CCTYPE_STRUCT
		.elseif cctype==CCTYPE_ALL || cctype==CCTYPE_STRUCT
			push	eax
			invoke IsCharAlphaNumeric,eax
			pop		edx
			.if eax || edx=='_' || edx==VK_BACK
				invoke CallWindowProc,lpOldRAEditProc,hWin,uMsg,wParam,lParam
				; Force a WM_NOTIFY
				invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
				invoke SendMessage,hREd,EM_EXSETSEL,0,addr chrg
				xor		eax,eax
				jmp		Ex
			.else
				mov		cctype,CCTYPE_NONE
				invoke ShowWindow,hCCLB,SW_HIDE
			.endif
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
		.elseif (edx==25h && eax==14Bh) || (edx==27h && eax==14Dh)
			;Left / Right
			invoke IsWindowVisible,hCCLB
			.if eax
				invoke ShowWindow,hCCLB,SW_HIDE
			.endif
			invoke IsWindowVisible,hCCTT
			.if eax
				invoke ShowWindow,hCCTT,SW_HIDE
			.endif
			mov		cctype,CCTYPE_NONE
		.endif
	.elseif eax==WM_KILLFOCUS
		invoke ShowWindow,hCCTT,SW_HIDE
	.elseif eax==WM_MOUSEMOVE
		mov		ti.cbSize,SizeOf TOOLINFO
		mov		ti.uFlags,TTF_IDISHWND
		mov		eax,hWin
		mov		ti.hWnd,eax
		mov		ti.uId,eax
		mov		ti.lpszText,0
		invoke SendMessage,hDbgTip,TTM_GETTOOLINFO,0,addr ti
		.if fDebugging
			.if !eax
				;Add the tooltip
				mov		ti.uFlags,TTF_IDISHWND Or TTF_SUBCLASS
				mov		eax,hWin
				mov		ti.hWnd,eax
				mov		ti.uId,eax
				mov		eax,hInstance
				mov		ti.hInst,eax
				invoke SendMessage,hDbgTip,TTM_ADDTOOL,0,addr ti
			.endif
			mov		eax,lParam
			mov		edx,eax
			shr		edx,16
			movsx	edx,dx
			movsx	eax,ax
			mov		pt.x,eax
			mov		pt.y,edx
			sub		eax,dbgpt.x
			.if CARRY?
				neg		eax
			.endif
			sub		edx,dbgpt.y
			.if CARRY?
				neg		edx
			.endif
			.if eax>5 || edx>5
				mov		eax,pt.x
				mov		dbgpt.x,eax
				mov		eax,pt.y
				mov		dbgpt.y,eax
				invoke SendMessage,hREd,EM_CHARFROMPOS,0,addr pt
				invoke SendMessage,hREd,REM_ISCHARPOS,eax,0
				.if !eax
					invoke SendMessage,hREd,REM_GETCURSORWORD,sizeof buffer,addr buffer
					.if buffer
						invoke DebugCommand,FUNC_GETTOOLTIP,0,0

						lea		eax,buffer
						mov		ti.lpszText,eax
						call	Activate

;						mov		var.IsSZ,0
;						invoke GetVarVal,addr buffer,eax,TRUE
;						.if eax
;							mov		edx,var.ProjectFileID
;							.if edx
;								invoke GetParent,hPar
;								invoke GetWindowLong,eax,16
;								mov		edx,var.ProjectFileID
;								sub		edx,eax
;							.endif
;							.if !edx
;								; Show tooltip
;								mov		ti.lpszText,offset outbuffer
;								call	Activate
;							.else
;								; Hide tooltip
;								call	DeActivate
;							.endif
;						.else
;							; Hide tooltip
;							call	DeActivate
;						.endif
					.else
						; Hide tooltip
						call	DeActivate
					.endif
				.else
					; Hide tooltip
					call	DeActivate
				.endif
			.endif
		.elseif eax
			; Delete the tool
			invoke SendMessage,hDbgTip,TTM_DELTOOL,0,addr ti
		.endif
	.endif
	invoke CallWindowProc,lpOldRAEditProc,hWin,uMsg,wParam,lParam
  Ex:
	ret

Activate:
	invoke SendMessage,hDbgTip,TTM_SETTOOLINFO,0,addr ti
	invoke SendMessage,hDbgTip,TTM_ACTIVATE ,FALSE,0
	invoke SendMessage,hDbgTip,TTM_ACTIVATE ,TRUE,0
	retn

DeActivate:
	invoke SendMessage,hDbgTip,TTM_ACTIVATE ,FALSE,0
	retn

RAEditProc endp

CreateRAEdit proc

	push	hREd
	.if edopt.hilitecmnt
		mov		eax,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or STYLE_DRAGDROP or STYLE_SCROLLTIP or STYLE_HILITECOMMENT or STYLE_AUTOSIZELINENUM
	.else
		mov		eax,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or STYLE_DRAGDROP or STYLE_SCROLLTIP or STYLE_AUTOSIZELINENUM
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
	invoke SendMessage,hREd,REM_SETSTYLEEX,STYLEEX_BLOCKGUIDE or STILEEX_LINECHANGED,0
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
	invoke SendMessage,hWnd,WM_SIZE,0,0
	ret

CreateRAHexEd endp

CreateNew proc

	invoke lstrcpy,offset FileName,offset szNewFile
	invoke CreateRAEdit
	invoke TabToolAdd,hREd,offset FileName
	invoke SetWinCaption,offset FileName
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
			.if hREd
				invoke GetWindowLong,hREd,GWL_ID
			.else
				mov		eax,-1
			.endif
			.if eax==-1
				call	DisableRes
				call	DisableEdit
				invoke SendMessage,hSbr,SB_SETTEXT,0,addr szNULL
			.elseif eax==IDC_RES
				call	DisableEdit
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
				invoke SendMessage,hSbr,SB_SETTEXT,0,addr szNULL
			.elseif eax==IDC_RAE
				call	DisableRes
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

				mov		eax,TRUE
				mov		edx,IDM_DEBUG_TOGGLE
				call	EnableDisable
				mov		edx,IDM_DEBUG_CLEAR
				call	EnableDisable
				mov		edx,IDM_DEBUG_RUN
				call	EnableDisable
				mov		eax,fDebugging
				mov		edx,IDM_DEBUG_STOP
				call	EnableDisable
				mov		edx,IDM_DEBUG_INTO
				call	EnableDisable
				mov		edx,IDM_DEBUG_OVER
				call	EnableDisable
				mov		edx,IDM_DEBUG_CARET
				call	EnableDisable

			.elseif eax==IDC_HEX
				xor		eax,eax
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

				mov		eax,FALSE
				mov		edx,IDM_DEBUG_TOGGLE
				call	EnableDisable
				mov		edx,IDM_DEBUG_CLEAR
				call	EnableDisable
				mov		edx,IDM_DEBUG_CARET
				call	EnableDisable

				mov		eax,fDebugging
				mov		edx,IDM_DEBUG_RUN
				call	EnableDisable
				mov		edx,IDM_DEBUG_STOP
				call	EnableDisable
				mov		edx,IDM_DEBUG_INTO
				call	EnableDisable
				mov		edx,IDM_DEBUG_OVER
				call	EnableDisable
				mov		eax,chrg.cpMin
				mov		edx,eax
				shr		edx,5
				and		eax,31
				invoke ShowPos,edx,eax
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
		invoke ShowProc,nLastLine
	.endif
	ret

DisableEdit:
	xor		eax,eax
	mov		edx,IDM_EDIT_CUT
	call	EnableDisable
	mov		edx,IDM_EDIT_COPY
	call	EnableDisable
	mov		edx,IDM_EDIT_PASTE
	call	EnableDisable
	mov		edx,IDM_EDIT_DELETE
	call	EnableDisable
	mov		edx,IDM_EDIT_UNDO
	call	EnableDisable
	mov		edx,IDM_EDIT_REDO
	call	EnableDisable
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

	mov		edx,IDM_DEBUG_TOGGLE
	call	EnableDisable
	mov		edx,IDM_DEBUG_CLEAR
	call	EnableDisable
	mov		edx,IDM_DEBUG_CARET
	call	EnableDisable

	mov		eax,fDebugging
	mov		edx,IDM_DEBUG_RUN
	call	EnableDisable
	mov		edx,IDM_DEBUG_STOP
	call	EnableDisable
	mov		edx,IDM_DEBUG_INTO
	call	EnableDisable
	mov		edx,IDM_DEBUG_OVER
	call	EnableDisable
	retn

DisableRes:
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
	retn

EnableDisable:
	push	eax
	push	edx
	.if eax
		mov		eax,MF_BYCOMMAND or MF_ENABLED
	.else
		mov		eax,MF_BYCOMMAND or MF_GRAYED
	.endif
	push	eax
	push	edx
	invoke EnableMenuItem,hMnu,edx,eax
	pop		edx
	pop		eax
	invoke EnableMenuItem,hContextMnu,edx,eax
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
	LOCAL	rescol:RESCOLOR
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
		mov		wpos.htprop,eax
		mov		eax,winsize.wtpro
		mov		wpos.wtprop,eax
		mov		eax,winsize.ptstyle.x
		mov		wpos.left,eax
		mov		eax,winsize.ptstyle.y
		mov		wpos.top,eax
		mov		eax,winsize.wttbx
		mov		wpos.wttoolbox,eax
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

DebugCallback proc nFunc:DWORD,wParam:DWORD,lParam:DWORD
	LOCAL	chrg:CHARRANGE

	mov		eax,nFunc
	.if eax==CB_SELECTLINE
		invoke OpenEditFile,lParam,0
		mov		eax,wParam
		dec		eax
		invoke SendMessage,hREd,REM_SETHILITELINE,eax,2
		mov		eax,wParam
		dec		eax
		invoke SendMessage,hREd,EM_LINEINDEX,eax,0
		mov		chrg.cpMin,eax
		mov		chrg.cpMax,eax
		invoke SendMessage,hREd,EM_EXSETSEL,0,addr chrg
		invoke SendMessage,hREd,EM_SCROLLCARET,0,0
		invoke SetFocus,hREd
	.elseif eax==CB_DESELECTLINE
		mov		eax,wParam
		dec		eax
		invoke SendMessage,lParam,REM_SETHILITELINE,eax,0
	.elseif eax==CB_DEBUG
		mov		eax,wParam
		mov		fDebugging,eax
		mov		fTimer,1
		.if eax
			invoke UpdateAll,LOCK_SOURCE_FILES
			invoke ShowWindow,hDbg,SW_SHOWNA
		.else
			invoke UpdateAll,UNLOCK_SOURCE_FILES
			invoke ShowWindow,hDbg,SW_HIDE
		.endif
		invoke SendMessage,hWnd,WM_SIZE,0,0
	.endif
	mov		eax,hREd
	ret

DebugCallback endp

WndProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	pt:POINT
	LOCAL	rect:RECT
	LOCAL	rect1:RECT
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
	LOCAL	mDC:HDC
	LOCAL	cust:CUSTSTYLE
	LOCAL	rarstype:RARSTYPE
	LOCAL	hFile:HANDLE

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
			mov		ecx,rect.right
			add		ecx,4
			.if eax<rect.right && edx>rect.bottom
				invoke SetCursor,hHSplitCur
				mov		fVSplit,1
			.elseif eax>=rect.right && eax<=ecx && edx>rect.top
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
				.if hREd
					invoke UpdateWindow,hREd
				.endif
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
				.if hREd
					invoke UpdateWindow,hREd
				.endif
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
				mov		eax,lParam
				movzx	eax,ax
				mov		rect.right,eax
				invoke MoveWindow,hTbr,2,2,695,23,TRUE
				invoke MoveWindow,hCbo,2,1,150,150,TRUE
				mov		eax,rect.right
				sub		eax,695+4
				invoke MoveWindow,hStc,2+695,2,eax,23,TRUE
				invoke MoveWindow,hShp,0,0,rect.right,27,TRUE
				invoke ShowWindow,hShp,SW_SHOW
				invoke ShowWindow,hTbr,SW_SHOW
				invoke ShowWindow,hStc,SW_SHOW
			.endif
			mov		eax,27
		.else
			invoke ShowWindow,hShp,SW_HIDE
			invoke ShowWindow,hTbr,SW_HIDE
			invoke ShowWindow,hStc,SW_HIDE
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
		;Resize tab window
		mov		edx,rect.right
		test	wpos.fView,8
		.if !ZERO?
			sub		edx,wpos.wtfile
		.endif
		push	edx
		sub		edx,17
		push	edx
		mov		eax,rect.top
		add		eax,5
		invoke MoveWindow,hBtn,edx,eax,15,15,TRUE
		invoke GetClientRect,hTab,addr rect1
		invoke SendMessage,hTab,TCM_GETROWCOUNT,0,0
		.if !eax
			inc		eax
		.endif
		mov		edx,24
		mul		edx
		mov		rect1.bottom,eax
		pop		edx
		invoke MoveWindow,hTab,-1,rect.top,edx,rect1.bottom,TRUE
		invoke UpdateWindow,hTab
		pop		edx
		test	wpos.fView,8
		.if !ZERO?
			;Resize file browser
			mov		eax,wpos.wtfile
			sub		rect.right,eax
			mov		edx,rect.bottom
			sub		edx,rect.top
			.if fDebugging
				sub		edx,HT_DEBUG
				.if CARRY?
					xor		edx,edx
				.endif
			.endif
			mov		ecx,rect.right
			add		ecx,RESIZEHT
			sub		eax,RESIZEHT
			shr		edx,1
			push	edx
			invoke MoveWindow,hBrowse,ecx,rect.top,eax,edx,TRUE
			pop		edx
			;Resize project browser
			push	rect.top
			add		edx,RESIZEHT
			add		rect.top,edx
			mov		edx,rect.bottom
			sub		edx,rect.top
			.if fDebugging
				sub		edx,HT_DEBUG
				.if CARRY?
					xor		edx,edx
				.endif
			.endif
			mov		ecx,rect.right
			add		ecx,RESIZEHT
			mov		eax,wpos.wtfile
			sub		eax,RESIZEHT
			push	edx
			invoke MoveWindow,hProperty,ecx,rect.top,eax,edx,TRUE
			pop		edx
			add		edx,RESIZEHT
			add		rect.top,edx

			mov		edx,rect.bottom
			sub		edx,rect.top
			mov		ecx,rect.right
			add		ecx,RESIZEHT
			mov		eax,wpos.wtfile
			sub		eax,RESIZEHT
			invoke MoveWindow,hDbg,ecx,rect.top,eax,edx,TRUE

			pop		rect.top
		.endif
		;Add height of tab window to top
		mov		eax,rect1.bottom
		add		rect.top,eax
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
		mov		eax,hREd
		.if !hREd
			invoke ShowWindow,hClient,SW_SHOWNA
			invoke MoveWindow,hClient,0,rect.top,rect.right,ht,TRUE
		.else
			invoke ShowWindow,hClient,SW_HIDE
			invoke MoveWindow,hREd,0,rect.top,rect.right,ht,TRUE
		.endif
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
		;Shape
		invoke GetDlgItem,hWin,IDC_SHP
		mov		hShp,eax
		;Static
		invoke GetDlgItem,hWin,IDC_STC
		mov		hStc,eax
		;Combo
		invoke GetDlgItem,hWin,IDC_CBO
		mov		hCbo,eax
		invoke SetParent,hCbo,hStc
		invoke SendMessage,hCbo,CB_ADDSTRING,0,addr szRelease
		invoke SendMessage,hCbo,CB_ADDSTRING,0,addr szDebug
		;Close button
		invoke GetDlgItem,hWin,IDC_BTNTABCLOSE
		mov		hBtn,eax
		invoke LoadBitmap,hInstance,111
		invoke SendMessage,hBtn,BM_SETIMAGE,IMAGE_BITMAP,eax
		;Client
		invoke GetDlgItem,hWin,IDC_CLIENT
		mov		hClient,eax
		;Window caption
		invoke SetWinCaption,0
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
		;Create debug window
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,offset szRAEditClass,NULL,WS_CHILD or STYLE_NOSPLITT or STYLE_NOLINENUMBER or STYLE_NOCOLLAPSE or STYLE_NOHILITE or STYLE_NOBACKBUFFER or STYLE_NOSTATE or STYLE_NOHSCROLL or STYLE_NOVSCROLL or STYLE_READONLY,0,0,0,0,hWnd,IDC_DBG,hInstance,0
		mov		hDbg,eax
		; Create debug tooltip
		invoke CreateWindowEx,0,addr sztooltips_class32,NULL,TTS_NOPREFIX,0,0,0,0,NULL,0,hInstance,0
		mov		hDbgTip,eax
		invoke SendMessage,hDbg,WM_SETFONT,hFont,FALSE
		;Create file browser
		invoke CreateWindowEx,0,addr szFBClassName,0,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or FBSTYLE_FLATTOOLBAR,0,0,0,0,hWin,IDC_FILE,hInstance,0
		mov		hBrowse,eax
		;Create property
		invoke CreateWindowEx,0,addr szPropertyClassName,0,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or PRSTYLE_FLATTOOLBAR,0,0,0,0,hWin,IDC_PROPERTY,hInstance,0
		mov		hProperty,eax
		invoke SendMessage,hSbr,WM_GETFONT,0,0
		push	eax
		push	eax
		invoke SendMessage,hBrowse,WM_SETFONT,eax,FALSE
		pop		eax
		invoke SendMessage,hProperty,WM_SETFONT,eax,FALSE
		;Create ResEd
		pop		eax
		invoke CreateWindowEx,0,addr szResClassName,0,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or WS_CLIPCHILDREN,0,0,0,0,hWin,IDC_RES,hInstance,eax
		mov		hRes,eax
		;Get handle of tab window
		invoke GetDlgItem,hWin,IDC_TAB
		mov		hTab,eax
		invoke SetWindowLong,hTab,GWL_WNDPROC,offset TabProc
		mov		lpOldTabProc,eax
		invoke SendMessage,hBrowse,FBM_GETIMAGELIST,0,0
		invoke SendMessage,hTab,TCM_SETIMAGELIST,0,eax
		invoke GetMenu,hWin
		mov		hMnu,eax
		invoke ImageList_Create,16,16,ILC_COLOR4 or ILC_MASK,4,0
		mov     hMnuIml,eax
		invoke LoadBitmap,hInstance,IDB_MNUARROW
		push	eax
		invoke ImageList_AddMasked,hMnuIml,eax,0C0C0C0h
		pop		eax
		invoke DeleteObject,eax
		invoke LoadMenu,hInstance,IDR_MENUCONTEXT
		mov		hContextMnu,eax
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
		;Add resource types
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

		invoke lstrcpy,addr PathBin,addr defPathBin
		mov		lpcbData,sizeof PathBin
		invoke RegQueryValueEx,hReg,addr szPathBin,0,addr lpType,addr PathBin,addr lpcbData
		invoke lstrcpy,addr PathInc,addr defPathInc
		mov		lpcbData,sizeof PathInc
		invoke RegQueryValueEx,hReg,addr szPathInc,0,addr lpType,addr PathInc,addr lpcbData
		invoke lstrcpy,addr PathLib,addr defPathLib
		mov		lpcbData,sizeof PathLib
		invoke RegQueryValueEx,hReg,addr szPathLib,0,addr lpType,addr PathLib,addr lpcbData
		invoke SetEnvironment
		invoke lstrcpy,addr CompileRC,addr defCompileRC
		mov		lpcbData,sizeof CompileRC
		invoke RegQueryValueEx,hReg,addr szCompileRC,0,addr lpType,addr CompileRC,addr lpcbData
		invoke lstrcpy,addr Assemble,addr defAssemble
		mov		lpcbData,sizeof Assemble
		invoke RegQueryValueEx,hReg,addr szAssemble,0,addr lpType,addr Assemble,addr lpcbData
		invoke lstrcpy,addr Link,addr defLink
		mov		lpcbData,sizeof Link
		invoke RegQueryValueEx,hReg,addr szLink,0,addr lpType,addr Link,addr lpcbData
		invoke lstrcpy,addr DbgLink,addr defDbgLink
		mov		lpcbData,sizeof DbgLink
		invoke RegQueryValueEx,hReg,addr szDbgLink,0,addr lpType,addr DbgLink,addr lpcbData
		mov		lpcbData,sizeof nCboBuild
		invoke RegQueryValueEx,hReg,addr szBuild,0,addr lpType,addr nCboBuild,addr lpcbData
		invoke SendMessage,hCbo,CB_SETCURSEL,nCboBuild,0

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
		invoke SetBlockDefs,hOut
		invoke SetPropertyDefs
		;Set hilite words
		invoke SetKeyWords
		invoke ResetMenu
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
				.if hREd
					invoke SaveEdit,hREd,offset FileName
					invoke SetFocus,hREd
				.endif
			.elseif eax==IDM_FILE_SAVEALL
				invoke UpdateAll,SAVE_ALL
			.elseif eax==IDM_FILE_SAVEAS
				.if hREd
					invoke SaveEditAs,hREd,offset FileName
				.endif
			.elseif eax==IDM_FILE_CLOSE || eax==IDC_BTNTABCLOSE
				invoke WantToSave,hREd,offset FileName
				.if !eax
					mov		eax,hREd
					.if eax!=hRes
						invoke DestroyWindow,hREd
						invoke SendMessage,hProperty,PRM_DELPROPERTY,hREd,0
						invoke SendMessage,hProperty,PRM_REFRESHLIST,0,0
					.endif
					invoke TabToolDel,hREd
				.endif
				mov		fTimer,1
			.elseif eax==IDM_FILE_CLOSE_ALL
				mov		nTabInx,-1
				invoke UpdateAll,WM_CLOSE
				.if !eax
					invoke UpdateAll,CLOSE_ALL
					mov		szSessionFile,0
					invoke CloseNotify
				.endif
				mov		fTimer,1
			.elseif eax==IDM_FILE_CLOSE_ALL_BUT
				invoke SendMessage,hTab,TCM_GETCURSEL,0,0
				mov		nTabInx,eax
				invoke UpdateAll,WM_CLOSE
				.if !eax
					invoke UpdateAll,CLOSE_ALL
				.endif
				mov		fTimer,1
			.elseif eax==IDM_FILE_OPENSESSION
				invoke OpenSessionFile
				mov		fTimer,1
			.elseif eax==IDM_FILE_SAVESESSION
				invoke SaveSessionFile
				mov		fTimer,1
			.elseif eax==IDM_FILE_CLOSESESSION
				mov		nTabInx,-1
				invoke UpdateAll,WM_CLOSE
				.if !eax
					invoke AskSaveSessionFile
					.if !eax
						mov		szSessionFile,0
						mov		MainFile,0
						invoke CloseNotify
						invoke UpdateAll,CLOSE_ALL
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
					mov		eax,PD_RETURNDC or PD_NOSELECTION
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
						push	ndir
						push	fallfiles
						mov		ndir,1
						mov		fallfiles,0
						invoke FindInit,hREd
						invoke SendMessage,hREd,EM_EXGETSEL,0,addr ft.chrgText
						mov		fres,0
						invoke Find,hREd,FR_DOWN
						pop		fallfiles
						pop		ndir
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
						push	ndir
						push	fallfiles
						mov		ndir,2
						mov		fallfiles,0
						invoke FindInit,hREd
						invoke SendMessage,hREd,EM_EXGETSEL,0,addr ft.chrgText
						mov		fres,0
						invoke Find,hREd,0
						pop		fallfiles
						pop		ndir
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
						invoke SetFocus,hREd
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
						invoke SetFocus,hREd
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
					invoke ShowWindow,hProperty,SW_SHOWNA
				.else
					invoke ShowWindow,hBrowse,SW_HIDE
					invoke ShowWindow,hProperty,SW_HIDE
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
			.elseif eax==IDM_DEBUG_TOGGLE
				invoke GetWindowLong,hREd,GWL_ID
				.if eax==IDC_RAE
					invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
					invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,chrg.cpMin
					mov		ebx,eax
					invoke SendMessage,hREd,REM_GETLINESTATE,ebx,0
					and		eax,STATE_BREAKPOINT
					xor		eax,STATE_BREAKPOINT
					invoke SendMessage,hREd,REM_SETBREAKPOINT,ebx,eax
					invoke DebugCommand,FUNC_BPCLEARALL,0,0
					invoke UpdateAll,SET_BREAKPOINTS
					invoke DebugCommand,FUNC_BPUPDATE,0,0
				.endif
			.elseif eax==IDM_DEBUG_CLEAR
				invoke UpdateAll,CLEAR_BREAKPOINTS
				invoke DebugCommand,FUNC_BPCLEARALL,0,0
				invoke DebugCommand,FUNC_BPUPDATE,0,0
			.elseif eax==IDM_DEBUG_RUN
				.if !fDebugging
					mov		nUnsaved,0
					invoke UpdateAll,UNSAVED_SOURCE_FILES
					.if nUnsaved
						invoke wsprintf,addr buffer,addr szUnsaved,nUnsaved
						invoke MessageBox,hWin,addr buffer,addr szAppName,MB_OK or MB_ICONERROR
						jmp		Ex
					.endif
					invoke lstrcpy,addr dbginf.FileName,offset MainFile
					invoke RemoveFileExt,addr dbginf.FileName
					invoke lstrcat,addr dbginf.FileName,offset ExtExe
					invoke CreateFile,addr dbginf.FileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
					.if eax!=INVALID_HANDLE_VALUE
						mov		hFile,eax
						invoke GetFileTime,hFile,NULL,NULL,addr ftexe
						invoke CloseHandle,hFile
						mov		nNewer,0
						invoke UpdateAll,NEWER_SOURCE_FILES
						.if nNewer
							invoke wsprintf,addr buffer,addr szNewer,nNewer
							invoke MessageBox,hWin,addr buffer,addr szAppName,MB_OK or MB_ICONERROR
							jmp		Ex
						.endif
					.else
						invoke strcpy,addr buffer,addr szOpenFileFail
						invoke strcat,addr buffer,addr dbginf.FileName
						invoke MessageBox,hWin,addr buffer,addr szAppName,MB_OK or MB_ICONERROR
						jmp		Ex
					.endif

					mov		eax,hWnd
					mov		dbginf.hWnd,eax
					mov		eax,hOut
					mov		dbginf.hOut,eax
					mov		eax,hDbg
					mov		dbginf.hDbg,eax
					mov		eax,hProperty
					mov		dbginf.hPrp,eax
					mov		eax,offset DebugCallback
					mov		dbginf.lpCallBack,eax
					invoke SetDebugInfo,addr dbginf
					invoke DebugCommand,FUNC_BPCLEARALL,0,0
					invoke UpdateAll,SET_BREAKPOINTS
				.endif
				invoke DebugCommand,FUNC_RUN,0,0
			.elseif eax==IDM_DEBUG_STOP
				invoke DebugCommand,FUNC_STOP,0,0
			.elseif eax==IDM_DEBUG_INTO
				invoke DebugCommand,FUNC_STEPINTO,0,0
			.elseif eax==IDM_DEBUG_OVER
				invoke DebugCommand,FUNC_STEPOVER,0,0
			.elseif eax==IDM_DEBUG_CARET
				invoke SendMessage,hREd,EM_EXGETSEL,0,addr chrg
				invoke SendMessage,hREd,EM_EXLINEFROMCHAR,0,chrg.cpMin
				inc		eax
				invoke DebugCommand,FUNC_RUNTOCARET,eax,offset FileName
			.elseif eax==IDM_MAKE_MAINFILE
				invoke lstrcpy,addr MainFile,addr FileName
				mov		fTimer,1
			.elseif eax==IDM_OPTION_CODE
				invoke DialogBoxParam,hInstance,IDD_DLGKEYWORDS,hWin,offset KeyWordsProc,0
			.elseif eax==IDM_OPTION_DIALOG
				invoke DialogBoxParam,hInstance,IDD_TABOPTIONS,hWin,offset TabOptionsProc,0
			.elseif eax==IDM_OPTION_PATH
				invoke DialogBoxParam,hInstance,IDD_PATHOPTION,hWin,offset PathOptionDialogProc,0
			.elseif eax==IDM_OPTION_BUILD
				invoke DialogBoxParam,hInstance,IDD_BUILDOPTION,hWin,offset BuildOptionDialogProc,0
			.elseif eax==IDM_OPTION_TOOLS
				invoke DialogBoxParam,hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,1
				invoke SetToolMenu
				invoke ResetMenu
			.elseif eax==IDM_OPTION_HELP
				invoke DialogBoxParam,hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,2
				invoke SetHelpMenu
				invoke ResetMenu
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
			.elseif eax==IDM_OUTPUT_CLEAR
				invoke SendMessage,hOut,WM_SETTEXT,0,addr szNULL
			.elseif eax==IDM_BROWSER_OPEN
				invoke SendMessage,hBrowse,FBM_GETSELECTED,0,addr buffer
				invoke GetFileAttributes,addr buffer
				test	eax,FILE_ATTRIBUTE_DIRECTORY
				.if ZERO?
					invoke OpenEditFile,addr buffer,0
				.else
					invoke SendMessage,hBrowse,FBM_SETPATH,TRUE,addr buffer
				.endif
			.elseif eax==IDM_BROWSER_COPY
				invoke SendMessage,hBrowse,FBM_GETSELECTED,0,addr buffer
				invoke SendMessage,hREd,EM_REPLACESEL,TRUE,addr buffer
				invoke SetFocus,hREd
			.elseif eax==IDM_PROPERTY_GOTODECLARE
				invoke SendMessage,hProperty,WM_COMMAND,(LBN_DBLCLK shl 16) or 1003,0
			.elseif eax==IDM_PROPERTY_COPYTOCODE
				invoke SendMessage,hProperty,PRM_GETSELTEXT,0,offset tmpbuff
				.if eax
					invoke SendMessage,hREd,EM_REPLACESEL,TRUE,offset tmpbuff
					invoke SetFocus,hREd
				.endif
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
				invoke SendMessage,hREd,REM_BRACKETMATCH,0,0
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
					invoke GetWindowLong,hREd,GWL_USERDATA
					mov		esi,eax
					.if ![esi].TABMEM.fchanged
						invoke TabToolSetChanged,hREd,TRUE
					.endif
					.if ![edi].RASELCHANGE.nWordGroup
						.if !ccinprogress
							invoke ApiListBox,edi
						.endif
						mov		[esi].TABMEM.fupdate,TRUE
					.endif
				.endif
				mov		eax,[edi].RASELCHANGE.line
				.if eax!=nLastLine
					mov		nLastLine,eax
					invoke ShowWindow,hCCLB,SW_HIDE
					invoke ShowWindow,hCCTT,SW_HIDE
					mov		cctype,CCTYPE_NONE
					.if ![edi].RASELCHANGE.nWordGroup
						invoke GetWindowLong,hREd,GWL_USERDATA
						.if [eax].TABMEM.fupdate
							mov		[eax].TABMEM.fupdate,FALSE
							invoke ParseEdit,hREd
						.endif
					.endif
				.elseif cctype==CCTYPE_ALL
					.if !ccinprogress
						invoke ApiListBox,edi
					.endif
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
		.elseif eax==BN_CLICKED && ecx==IDC_PROPERTY
			mov		eax,[edx].RAPNOTIFY.nid
			.if eax==1
				invoke SendMessage,hProperty,PRM_SELOWNER,hREd,0
			.elseif eax==2
				invoke SendMessage,hProperty,PRM_SELOWNER,0,0
			.elseif eax==5
				invoke SendMessage,hProperty,PRM_GETSELBUTTON,0,0
				.if eax==1
					invoke SendMessage,hProperty,PRM_SELOWNER,hREd,0
				.endif
				invoke SendMessage,hProperty,PRM_REFRESHLIST,0,0
			.endif
		.elseif eax==LBN_DBLCLK && ecx==IDC_PROPERTY
			push	[edx].RAPNOTIFY.nline
			invoke TabToolGetInx,[edx].RAPNOTIFY.nid
			invoke SendMessage,hTab,TCM_SETCURSEL,eax,0
			invoke TabToolActivate
			pop		eax
			invoke SendMessage,hREd,EM_LINEINDEX,eax,0
			mov		chrg.cpMin,eax
			mov		chrg.cpMax,eax
			invoke SendMessage,hREd,EM_EXSETSEL,0,addr chrg
			invoke SendMessage,hREd,REM_VCENTER,0,0
			invoke SetFocus,hREd
		.elseif eax==TTN_NEEDTEXT
			;Toolbar tooltip
			invoke LoadString,hInstance,ecx,addr buffer,sizeof buffer
			lea		eax,buffer
			mov		edx,lParam
			mov		(TOOLTIPTEXT ptr [edx]).lpszText,eax
		.elseif eax==TCN_SELCHANGE
			invoke TabToolActivate
			invoke SetFocus,hREd
		.endif
	.elseif eax==WM_SETFOCUS
		.if hREd
			invoke SetFocus,hREd
		.endif
	.elseif eax==WM_CLOSE
		mov		nTabInx,-1
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
				invoke SendMessage,hCbo,CB_GETCURSEL,0,0
				mov		dword ptr tmpbuff,eax
				invoke RegSetValueEx,hReg,addr szBuild,0,REG_DWORD,addr tmpbuff,4
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
				invoke DestroyWindow,hRes
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
		invoke ImageList_Destroy,hImlTbr
		invoke ImageList_Destroy,hImlTbrGray
		invoke DeleteObject,hBrBack
		.if hMnuFont
			invoke DeleteObject,hMenuBrushA
			invoke DeleteObject,hMenuBrushB
			invoke DeleteObject,hMnuFont
		.endif
		invoke ResetEnvironment
		invoke PostQuitMessage,NULL
	.elseif eax==WM_CONTEXTMENU
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
		mov		eax,wParam
		.if eax==hREd
			.if eax==hRes
				invoke GetSubMenu,hContextMnu,3
				invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWin,0
			.else
				invoke GetSubMenu,hMnu,1
				invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWin,0
			.endif
		.elseif eax==hTab
			invoke GetSubMenu,hContextMnu,0
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWin,0
		.elseif eax==hOut
			invoke GetSubMenu,hContextMnu,1
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWin,0
		.elseif eax==hBrowse
			invoke GetSubMenu,hContextMnu,2
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWin,0
		.elseif eax==hProperty
			invoke GetSubMenu,hContextMnu,4
			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWin,0
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
						invoke ImageList_Draw,hImlTbr,27,mDC,2,edx,ILD_TRANSPARENT
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
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		jmp		ExRet
	.endif
  Ex:
	xor    eax,eax
  ExRet:
	ret

WndProc endp

end start

