ID_EDIT							equ	65501
ID_DIALOG						equ	65502
ID_EDITTXT						equ	65503
ID_EDITHEX						equ	65504
ID_FIRSTCHILD					equ 65001
ID_LASTCHILD					equ 65499

IDI_MDIICO						equ 100
IDC_SPLICURV					equ 150
IDC_SPLICURH					equ 151

;RadASM.mnu
IDR_MENU						equ 10000
IDM_FILE						equ 10001
IDM_FILE_NEW					equ 10002
IDM_FILE_EXIT					equ 10004

IDM_WINDOW						equ 10005

ADDINHANDLES struct
	hWnd			HWND ?
	hClient			HWND ?
	hInstance		HINSTANCE ?
	hMenu			HMENU ?
	hIcon			HICON ?
	hCursor			HCURSOR ?
	hSplitCurV		HCURSOR ?
	hSplitCurH		HCURSOR ?
	hTool			HWND ?
ADDINHANDLES ends

WIN struct
	x			DWORD ?
	y			DWORD ?
	wt			DWORD ?
	ht			DWORD ?
	fmax		DWORD ?
	ftopmost	DWORD ?
	fcldmax		DWORD ?
WIN ends

ADDINDATA struct
	win				WIN <?>
	szAppPath		BYTE MAX_PATH dup(?)
	szRadASMIni		BYTE MAX_PATH dup(?)
ADDINDATA ends

