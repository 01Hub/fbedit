.386
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
	invoke GridInstall,hInstance
	invoke ResEdInstall,hInstance
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
		.if wpos.wtpro<5
			mov		wpos.wtpro,150
		.endif
		.if wpos.htpro<5
			mov		wpos.htpro,200
		.endif
		mov		lpcbData,sizeof nmeexp
		invoke RegQueryValueEx,hReg,addr szNmeExp,0,addr lpType,addr nmeexp,addr lpcbData
		mov		lpcbData,sizeof grdsize
		invoke RegQueryValueEx,hReg,addr szGrid,0,addr lpType,addr grdsize,addr lpcbData
		mov		lpcbData,sizeof col
		invoke RegQueryValueEx,hReg,addr szColor,0,addr lpType,addr col,addr lpcbData
		mov		lpcbData,sizeof initid
		invoke RegQueryValueEx,hReg,addr szInitID,0,addr lpType,addr initid,addr lpcbData
	.endif
	invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke RegSetValueEx,hReg,addr szWinPos,0,REG_BINARY,addr wpos,sizeof wpos
	invoke RegCloseKey,hReg
	invoke ResEdUninstall
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
	LOCAL	buff[MAX_PATH]:BYTE

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
		.if grdsize.nodefines
			invoke lstrcpy,addr buff,lpFileName
			invoke lstrlen,addr buff
			.while byte ptr buff[eax-1]!='.' && eax
				dec		eax
			.endw
			mov		word ptr buff[eax],'h'
			;invoke lstrcat,addr buff,offset szDefines
			invoke CreateFile,addr buff,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
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
		invoke SendMessage,hProject,PRO_OPEN,offset ProjectFileName,hMem
		invoke SetWinCaption,offset ProjectFileName
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

DoToolBar proc hToolBar:HWND
	LOCAL	tbab:TBADDBITMAP

	;Set toolbar struct size
	invoke SendMessage,hToolBar,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0
	;Set toolbar bitmap
	push	hInstance
	pop		tbab.hInst
	mov		tbab.nID,IDB_TOOLBAR
	invoke SendMessage,hToolBar,TB_ADDBITMAP,9,addr tbab
	;Set toolbar buttons
	invoke SendMessage,hToolBar,TB_ADDBUTTONS,ntbrbtns,addr tbrbtns
	ret

DoToolBar endp

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
	lea		eax,buffer
	mov		ofn.lpstrFile,eax
	mov		ofn.nMaxFile,sizeof buffer
	mov		ofn.lpstrDefExt,NULL
	mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
	.if ProjectFileName
		invoke GetCurrentDirectory,sizeof buffer1,addr buffer1
		lea		eax,buffer1
		mov		ofn.lpstrInitialDir,eax
	.endif
	;Show the Open dialog
	invoke GetOpenFileName,addr ofn
	.if eax
		invoke LoadProjectFile,addr buffer
	.endif
	ret

OpenProject endp

SaveProject proc lpFileName:DWORD
	LOCAL	hMem:DWORD
	LOCAL	hMemDef:DWORD
	LOCAL	hFile:DWORD
	LOCAL	nSize:DWORD
	LOCAL	buff[MAX_PATH]:BYTE

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
	mov		hMem,eax
	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
	mov		hMemDef,eax
	invoke SendMessage,hProject,PRO_EXPORT,hMemDef,hMem
	invoke CreateFile,lpFileName,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke lstrlen,hMem
		mov		nSize,eax
		invoke WriteFile,hFile,hMem,nSize,addr nSize,NULL
		invoke CloseHandle,hFile
		invoke SendMessage,hProject,PRO_SETMODIFY,FALSE,0
		.if grdsize.nodefines
			invoke lstrcpy,addr buff,lpFileName
			invoke lstrlen,addr buff
			.while byte ptr buff[eax-1]!='.' && eax
				dec		eax
			.endw
			mov		word ptr buff[eax],'h'
			invoke CreateFile,addr buff,GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
			.if eax!=INVALID_HANDLE_VALUE
				mov		hFile,eax
				invoke lstrlen,hMemDef
				mov		nSize,eax
				invoke WriteFile,hFile,hMemDef,nSize,addr nSize,NULL
				invoke CloseHandle,hFile
			.endif
		.endif
		.if nmeexp.fAuto
			invoke SendMessage,hProject,PRO_EXPORTNAMES,1,hOut
		.endif
		xor		eax,eax
	.endif
	push	eax
	invoke GlobalFree,hMem
	invoke GlobalFree,hMemDef
	pop		eax
	ret

SaveProject endp

SaveProjectFileAs proc lpFileName:DWORD
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke GetWindowLong,hProject,0
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
		invoke lstrcpy,addr buffer,lpFileName
		lea		eax,buffer
		mov		ofn.lpstrFile,eax
		mov		ofn.nMaxFile,sizeof buffer
		mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT
		mov		ofn.lpstrDefExt,offset szDefRCExt
		;Show save as dialog
		invoke GetSaveFileName,addr ofn
		.if eax
			invoke lstrcpy,offset ProjectFileName,addr buffer
			invoke SetWinCaption,offset ProjectFileName
			invoke lstrlen,offset ProjectFileName
			lea		edx,buffer
			.while byte ptr [edx+eax]!='\' && eax
				dec		eax
			.endw
			mov		byte ptr [edx+eax],0
			lea		edx,[edx+eax+1]
			invoke SendMessage,hProject,PRO_SETNAME,edx,addr buffer
			invoke SaveProject,offset ProjectFileName
			.if !eax
				xor		eax,eax
				inc		eax
			.else
				xor		eax,eax
			.endif
		.endif
	.endif
	ret

SaveProjectFileAs endp

ExportDialog proc
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke GetWindowLong,hProject,0
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
			invoke GetDlgItem,hWnd,IDC_DLGEDIT
			mov		edx,eax
			invoke SendMessage,edx,DEM_EXPORTDLG,0,addr buffer
		.endif
	.endif
	ret

ExportDialog endp

SaveProjectFile proc lpFileName:DWORD

	invoke GetWindowLong,hProject,0
	.if eax
		invoke lstrcmp,offset ProjectFileName,offset szNewFile
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
	invoke SendMessage,hProject,PRO_GETMODIFY,0,0
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
		.elseif eax==IDNO
		    mov		eax,FALSE
		.else
		    mov		eax,TRUE
		.endif
	.endif
	ret

WantToSaveProject endp

ToolBarEnable proc uses ebx,hTbr:HWND

	mov		ebx,hTbr
	invoke SendMessage,hResEd,DEM_CANUNDO,0,0
	invoke SendMessage,ebx,TB_ENABLEBUTTON,IDM_EDIT_UNDO,eax
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

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		push	hWin
		pop		hWnd
		invoke GetModuleFileName,0,addr buffer,sizeof buffer
		invoke lstrlen,addr buffer
		.while byte ptr buffer[eax]!='\' && eax
			dec		eax
		.endw
		mov		buffer[eax],0
		invoke SetCurrentDirectory,addr buffer
		invoke GetDlgItem,hWin,IDC_SBR1
		invoke SendMessage,eax,WM_GETFONT,0,0
		mov		hFont,eax
		invoke MoveWindow,hWin,wpos.x,wpos.y,wpos.wt,wpos.ht,TRUE
		invoke LoadAccelerators,hInstance,IDR_ACCEL
		mov		hAccel,eax
		invoke GetMenu,hWin
		mov		hMnu,eax
		invoke SetToolMenu
		invoke SetHelpMenu
		invoke LoadMenu,hInstance,IDR_CONTEXT
		mov		hContextMenu,eax
		invoke GetSubMenu,eax,0
		mov		hContextMenuPopup,eax
		invoke GetDlgItem,hWin,IDC_TBR1
		invoke DoToolBar,eax
		invoke GetDlgItem,hWin,IDC_EDT1
		mov		hOut,eax
		mov		edx,52300000h
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
		.if grdsize.nodefines
			or		edx,DES_NODEFINES
		.endif
		.if grdsize.simple
			or		edx,DES_SIMPLEPROPERTY
		.endif
		invoke CreateWindowEx,200h,addr szDlgEditClass,0,edx,0,0,0,0,hWin,IDC_DLGEDIT,hInstance,0
		mov		hResEd,eax
		invoke SendMessage,eax,WM_SETFONT,hFont,0
		invoke CreateWindowEx,200h,addr szProjectClass,0,56000000h,0,0,0,0,hWin,IDC_PROJECT,hInstance,0
		mov		hProject,eax
		invoke SendMessage,eax,WM_SETFONT,hFont,0
		mov		edx,nmeexp.nOutput
		shl		edx,16
		add		edx,nmeexp.nType
		invoke SendMessage,hProject,PRO_SETEXPORT,edx,addr nmeexp.szFileName
		invoke SendMessage,hProject,PRO_SETSTYLEPOS,0,addr wpos.left
		invoke SendMessage,hProject,PRO_SETINITID,0,addr initid
		invoke CreateWindowEx,0h,addr szPropertyClass,0,56000000h,0,0,0,0,hWin,IDC_PROPERTY,hInstance,0
		invoke SendMessage,eax,WM_SETFONT,hFont,0
		invoke CreateWindowEx,0h,addr szToolBoxClass,0,56000000h,0,0,0,0,hWin,IDC_TOOLBOX,hInstance,0
		invoke SendMessage,eax,WM_SETFONT,hFont,0
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
		invoke LoadCursor,hInstance,IDC_HSPLIT
		mov		hHSplit,eax
		invoke LoadCursor,hInstance,IDC_VSPLIT
		mov		hVSplit,eax
		invoke GetDlgItem,hWin,IDC_TBR1
		invoke ToolBarEnable,eax
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
	.elseif eax==WM_NCACTIVATE
		.if hResEd
			invoke GetWindowLong,hResEd,DEWM_DIALOG
			.if eax
				invoke SendMessage,eax,WM_NCACTIVATE,wParam,0
			.endif
		.endif
		jmp		ExDef
	.elseif eax==WM_NCMOUSEMOVE
		invoke GetDlgItem,hWin,IDC_SBR1
		invoke SendMessage,eax,SB_SETTEXT,0,offset szNULL
	.elseif eax==WM_MOUSEMOVE
		invoke GetClientRect,hWin,addr rect
		invoke GetDlgItem,hWin,IDC_SBR1
		invoke SendMessage,eax,SB_SETTEXT,0,offset szNULL
		mov		eax,lParam
		movzx	eax,ax
		cwde
		mov		pt.x,eax
		mov		eax,lParam
		shr		eax,16
		cwde
		mov		pt.y,eax
		invoke GetCapture
		.if eax==hWin
			.if fSize==1
				mov		eax,rect.right
				mov		edx,eax
				sub		edx,80+53
				sub		eax,pt.x
				.if sdword ptr eax<80
					mov		eax,80
				.elseif sdword ptr eax>edx
					mov		eax,edx
				.endif
				.if eax!=wpos.wtpro
					mov		wpos.wtpro,eax
					mov		eax,rect.bottom
					shl		eax,16
					add		eax,rect.right
					invoke SendMessage,hWin,WM_SIZE,0,eax
				.endif
			.elseif fSize==2
				mov		eax,rect.bottom
				mov		edx,eax
				sub		edx,80+25
				mov		eax,pt.y
				sub		eax,25
				.if sdword ptr eax<80-25
					mov		eax,80-25
				.elseif sdword ptr eax>edx
					mov		eax,edx
				.endif
				.if eax!=wpos.htpro
					mov		wpos.htpro,eax
					mov		eax,rect.bottom
					shl		eax,16
					add		eax,rect.right
					invoke SendMessage,hWin,WM_SIZE,0,eax
				.endif
			.elseif fSize==3
				mov		edx,rect.bottom
				sub		edx,80
				mov		eax,pt.y
				.if sdword ptr eax<80
					mov		eax,80
				.elseif sdword ptr eax>edx
					mov		eax,edx
				.endif
				mov		edx,rect.bottom
				sub		edx,eax
				sub		edx,21+3
				.if edx!=wpos.htout
					mov		wpos.htout,edx
					mov		eax,rect.bottom
					shl		eax,16
					add		eax,rect.right
					invoke SendMessage,hWin,WM_SIZE,0,eax
				.endif
			.endif
		.else
			mov		edx,rect.right
			sub		edx,wpos.wtpro
			mov		ecx,edx
			sub		edx,3
			mov		eax,pt.x
			.if sdword ptr eax>=edx && sdword ptr eax<=ecx
				invoke SetCursor,hVSplit
				mov		fSize,1
				jmp		Ex
			.elseif sdword ptr eax>edx
				invoke SetCursor,hHSplit
				mov		fSize,2
				jmp		Ex
			.else
				mov		edx,rect.bottom
				sub		edx,wpos.htout
				sub		edx,21
				mov		ecx,edx
				sub		edx,3
				mov		eax,pt.y
				.if sdword ptr eax>=edx && sdword ptr eax<=ecx
					invoke SetCursor,hHSplit
					mov		fSize,3
					jmp		Ex
				.endif
			.endif
			invoke LoadCursor,0,IDC_ARROW
			invoke SetCursor,eax
			mov		fSize,0
		.endif
	.elseif eax==WM_LBUTTONDOWN
		.if fSize==1
			invoke SetCapture,hWin
			invoke SetCursor,hVSplit
		.elseif fSize==2
			invoke SetCapture,hWin
			invoke SetCursor,hHSplit
		.elseif fSize==3
			invoke SetCapture,hWin
			invoke SetCursor,hHSplit
		.endif
	.elseif eax==WM_LBUTTONUP
		.if fSize
			invoke ReleaseCapture
			mov		fSize,0
		.endif
	.elseif eax==WM_CONTEXTMENU
		mov		eax,lParam
		.if eax!=-1
			and		eax,0FFFFh
			mov		pt.x,eax
			mov		eax,lParam
			shr		eax,16
			mov		pt.y,eax
		.else
			invoke GetWindowRect,hWin,addr rect
			.if hResEd
				invoke GetWindowLong,hResEd,DEWM_DIALOG
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
		.if eax==hProject
			invoke SendMessage,hWin,WM_INITMENUPOPUP,hMnu,4
			invoke GetSubMenu,hMnu,4
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
				mov		edx,13
			.else
				mov		edx,6
			.endif
			push	edx
			invoke EnableMenuItem,wParam,edx,ebx
			pop		edx
			inc		edx
			push	edx
			invoke EnableMenuItem,wParam,edx,ebx
			pop		edx
			inc		edx
			push	edx
			invoke EnableMenuItem,wParam,edx,ebx
			pop		edx
			pop		eax
			push	edx
			.if eax==1
				invoke EnableMenuItem,wParam,edx,MF_BYPOSITION
			.endif
			pop		edx
			inc		edx
			inc		edx
			invoke EnableMenuItem,wParam,edx,ebx
		.elseif eax==3
			;View
			test	wpos.fView,1
			.if !ZERO?
				mov		eax,MF_BYCOMMAND or MF_CHECKED
			.else
				mov		eax,MF_BYCOMMAND or MF_UNCHECKED
			.endif
			invoke CheckMenuItem,wParam,IDM_VIEW_OUTPUT,eax
		.elseif eax==4
			;Project
			invoke GetWindowLong,hProject,0
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
			invoke EnableMenuItem,wParam,IDM_PROJECT_LANGUAGE,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_INCLUDE,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_RESOURCE,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_NAMES,ebx
			invoke EnableMenuItem,wParam,IDM_PROJECT_EXPORT,ebx
			invoke SendMessage,hProject,PRO_GETSELECTED,0,0
			mov		ebx,MF_GRAYED
			.if eax>=2
				xor		ebx,ebx
			.endif
			invoke EnableMenuItem,wParam,IDM_PROJECT_REMOVE,ebx
			invoke SendMessage,hProject,PRO_CANUNDO,0,0
			mov		ebx,MF_GRAYED
			.if eax
				xor		ebx,ebx
			.endif
			invoke EnableMenuItem,wParam,IDM_PROJECT_UNDO,ebx
			invoke GetDlgItem,hWin,IDC_DLGEDIT
			invoke GetWindowLong,eax,DEWM_DIALOG
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
			invoke GetDlgItem,hWin,IDC_TBR1
			invoke ToolBarEnable,eax
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
				invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4096
				mov		hMem,eax
				invoke GlobalLock,hMem
				invoke GetDlgItem,hWin,IDC_PROJECT
				invoke SendMessage,eax,PRO_OPEN,offset ProjectFileName,hMem
				invoke SetWinCaption,offset ProjectFileName
				invoke SaveProjectFile,offset ProjectFileName
				.if !eax
					invoke GetDlgItem,hWin,IDC_PROJECT
					invoke SendMessage,eax,PRO_CLOSE,0,0
					invoke SetWinCaption,NULL
				.else
					invoke GetDlgItem,hWin,IDC_PROJECT
					invoke SendMessage,eax,PRO_CLOSE,0,0
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
				invoke GetDlgItem,hWin,IDC_PROJECT
				invoke SendMessage,eax,PRO_CLOSE,0,0
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
			invoke GetClientRect,hWin,addr rect
			mov		eax,rect.bottom
			shl		eax,16
			add		eax,rect.right
			invoke SendMessage,hWin,WM_SIZE,0,eax
			invoke GetDlgItem,hWin,IDC_TBR1
			invoke ToolBarEnable,eax
		.elseif eax==IDM_VIEW_PREVIEW
			invoke SendMessage,hResEd,DEM_SHOWDIALOG,0,0
			mov		hPreview,eax
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
			invoke SendMessage,hProject,PRO_ADDITEM,TPE_DIALOG,TRUE
		.elseif eax==IDM_PROJECT_ADD_MENU
			invoke SendMessage,hProject,PRO_ADDITEM,TPE_MENU,TRUE
		.elseif eax==IDM_PROJECT_ADD_ACCELERATOR
			invoke SendMessage,hProject,PRO_ADDITEM,TPE_ACCEL,TRUE
		.elseif eax==IDM_PROJECT_ADD_VERSIONINFO
			invoke SendMessage,hProject,PRO_ADDITEM,TPE_VERSION,TRUE
		.elseif eax==IDM_PROJECT_ADD_STRINGTABLE
			invoke SendMessage,hProject,PRO_ADDITEM,TPE_STRING,TRUE
		.elseif eax==IDM_PROJECT_ADD_XPMANIFEST
			invoke SendMessage,hProject,PRO_ADDITEM,TPE_XPMANIFEST,TRUE
		.elseif eax==IDM_PROJECT_ADD_RCDATA
			invoke SendMessage,hProject,PRO_ADDITEM,TPE_RCDATA,TRUE
		.elseif eax==IDM_PROJECT_LANGUAGE
			invoke SendMessage,hProject,PRO_ADDITEM,TPE_LANGUAGE,TRUE
		.elseif eax==IDM_PROJECT_INCLUDE
			invoke SendMessage,hProject,PRO_ADDITEM,TPE_INCLUDE,TRUE
		.elseif eax==IDM_PROJECT_RESOURCE
			invoke SendMessage,hProject,PRO_ADDITEM,TPE_RESOURCE,TRUE
		.elseif eax==IDM_PROJECT_NAMES
			invoke SendMessage,hProject,PRO_SHOWNAMES,0,hOut
		.elseif eax==IDM_PROJECT_REMOVE
			invoke SendMessage,hProject,PRO_DELITEM,0,0
		.elseif eax==IDM_PROJECT_UNDO
			invoke SendMessage,hProject,PRO_UNDODELETED,0,0
		.elseif eax==IDM_PROJECT_EXPORT
			invoke SendMessage,hProject,PRO_EXPORTNAMES,0,hOut
		.elseif eax==IDM_PROJECT_DLGSAVE
			invoke ExportDialog
		.elseif eax==IDM_OPTION_TOOLS
			invoke DialogBoxParam,hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,1
			invoke SetToolMenu
		.elseif eax==IDM_OPTION_HELP
			invoke DialogBoxParam,hInstance,IDD_DLGOPTMNU,hWin,offset MenuOptionProc,2
			invoke SetHelpMenu
		.elseif eax==IDM_OPTION_OPTIONS
			invoke DialogBoxParam,hInstance,IDD_TABOPTIONS,hWin,offset TabOptionsProc,0
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
				invoke ShellExecute,hWin,NULL,addr buffer,addr buffer1,NULL,SW_SHOWNORMAL;SW_SHOWDEFAULT
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
				invoke ShellExecute,hWin,NULL,addr buffer,addr buffer1,NULL,SW_SHOWNORMAL;SW_SHOWDEFAULT
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
		;ToolBox
		invoke GetDlgItem,hWin,IDC_TOOLBOX
		mov		edx,pt.y
		sub		edx,25
		sub		edx,ebx
		invoke MoveWindow,eax,0,25,53,edx,TRUE
		;Dialog edit
		invoke GetDlgItem,hWin,IDC_DLGEDIT
		mov		ecx,pt.x
		sub		ecx,wpos.wtpro
		sub		ecx,3+53
		mov		edx,pt.y
		sub		edx,25
		sub		edx,ebx
		test	wpos.fView,1
		.if !ZERO?
			sub		edx,wpos.htout
			sub		edx,3
		.endif
		invoke MoveWindow,eax,53,25,ecx,edx,TRUE
		;Output
		invoke GetDlgItem,hWin,IDC_EDT1
		mov		edx,pt.y
		sub		edx,ebx
		sub		edx,wpos.htout
		mov		ecx,pt.x
		sub		ecx,3+53
		sub		ecx,wpos.wtpro
		test	wpos.fView,1
		.if ZERO?
			xor		eax,eax
		.else
			mov		eax,wpos.htout
		.endif
		invoke MoveWindow,hOut,53,edx,ecx,eax,TRUE
		;Project
		invoke GetDlgItem,hWin,IDC_PROJECT
		mov		ecx,pt.x
		sub		ecx,wpos.wtpro
		mov		pt.x,ecx
		invoke MoveWindow,eax,ecx,25,wpos.wtpro,wpos.htpro,TRUE
		;Property
		invoke GetDlgItem,hWin,IDC_PROPERTY
		mov		ecx,pt.x
		sub		ecx,wpos.wtpro
		mov		ecx,wpos.htpro
		mov		edx,pt.y
		sub		edx,ecx
		sub		edx,25+1
		sub		edx,ebx
		add		ecx,2+25
		invoke MoveWindow,eax,pt.x,ecx,wpos.wtpro,edx,TRUE
	.elseif eax==WM_CLOSE
		invoke WantToSaveProject,offset ProjectFileName
		.if !eax
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
		invoke SendMessage,hProject,PRO_GETSTYLEPOS,0,addr wpos.left
		invoke DestroyCursor,hHSplit
		invoke DestroyCursor,hVSplit
		invoke DestroyIcon,hIcon
		invoke ImageList_Destroy,hIml
		invoke DestroyAcceleratorTable,hAccel
		invoke DestroyMenu,hContextMenu
		invoke DestroyWindow,hResEd
		invoke DestroyWindow,hProject
		invoke GetDlgItem,hWin,IDC_TOOLBOX
		invoke DestroyWindow,eax
		invoke GetDlgItem,hWin,IDC_PROPERTY
		invoke DestroyWindow,eax
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
		mov		eax,hBrBackColor
		.if eax
			invoke DeleteObject,eax
		.endif
		invoke PostQuitMessage,NULL
	.elseif eax==WM_CTLCOLOREDIT
		xor		eax,eax
		mov		edx,lParam
		.if edx==hOut
			invoke SetBkColor,wParam,col.back
			invoke SetTextColor,wParam,col.text
			mov		eax,hBrBackColor
			.if !eax
				invoke CreateSolidBrush,col.back
				mov		hBrBackColor,eax
			.endif
		.endif
		jmp		ExRet
	.elseif eax==WM_DROPFILES
		invoke DragQueryFile,wParam,0,addr buffer,sizeof buffer
		invoke WantToSaveProject,offset ProjectFileName
		.if !eax
			invoke LoadProjectFile,addr buffer
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
