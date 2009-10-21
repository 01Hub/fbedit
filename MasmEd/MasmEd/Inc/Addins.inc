
ADDINHANDLES struct
	hWnd					HWND ?				;Handle of main window
	hClient					HWND ?
	hREd					HWND ?
	hTab					HWND ?
	hBtn					HWND ?
	hFind					HWND ?
	hTbr					HWND ?
	hShp					HWND ?
	hStc					HWND ?
	hCbo					HWND ?
	hCCLB					HWND ?
	hCCTT					HWND ?
	hRes					HWND ?
	hResEd					HWND ?
	hOut					HWND ?
	hImmOut					HWND ?
	hTabOut					HWND ?
	hBrowse					HWND ?
	hProperty				HWND ?
	hSbr					HWND ?
	hDbgReg					HWND ?
	hDbgWatch				HWND ?
	hTabDbg					HWND ?
	hDbgTip					HWND ?
	hInstance				HINSTANCE ?
	hAccel					HACCEL ?
	hMnu					HMENU ?
	hContextMnu				HMENU ?
	hVSplitCur				HCURSOR ?
	hHSplitCur				HCURSOR ?
	hFont					HFONT ?
	hIFont					HFONT ?
	hLnrFont				HFONT ?
	hImlTbr					HIMAGELIST ?
	hImlTbrGray				HIMAGELIST ?
	hMnuIml					HIMAGELIST ?
	hBrBack					HBRUSH ?
	hMenuBrushA				HBRUSH ?
	hMenuBrushB				HBRUSH ?
	hMnuFont				HFONT ?
	hReg					HKEY ?
ADDINHANDLES ends

ADDINDATA struct
	AppPath					BYTE MAX_PATH dup(?)
	FileName				BYTE MAX_PATH dup(?)
	MainFile				BYTE MAX_PATH dup(?)
	DbgFileName				BYTE MAX_PATH dup(?)
	findbuff				BYTE 256 dup(?)
	replacebuff				BYTE 256 dup(?)
	szInitFolder			BYTE MAX_PATH dup(?)
	szSessionFile			BYTE MAX_PATH dup(?)
	PathBin					BYTE MAX_PATH dup(?)
	PathInc					BYTE MAX_PATH dup(?)
	PathLib					BYTE MAX_PATH dup(?)
	CompileRC				BYTE 256 dup(?)
	Assemble				BYTE 256 dup(?)
	Link					BYTE 256 dup(?)
	DbgAssemble				BYTE 256 dup(?)
	DbgLink					BYTE 256 dup(?)
ADDINDATA ends

ADDINPROCS struct
	lpOpenEditFile			DWORD ?
ADDINPROCS ends

IDC_RAE						equ 1011
IDC_RES						equ 1012
IDC_HEX						equ 1013
