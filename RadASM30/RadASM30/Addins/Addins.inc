ID_EDIT							equ	65501
ID_DIALOG						equ	65502
ID_EDITTXT						equ	65503
ID_EDITHEX						equ	65504
ID_FIRSTCHILD					equ 65001
ID_LASTCHILD					equ 65499

IDI_MDIICO						equ 100
IDC_SPLICURV					equ 150
IDC_SPLICURH					equ 151
IDB_TBRBMP						equ 152

;RadASM.mnu
IDR_MENU						equ 10000
IDM_FILE						equ 10001
IDM_FILE_NEW					equ 10002
IDM_FILE_OPEN					equ 10006
IDM_FILE_SAVE					equ 10007
IDM_FILE_SAVEALL				equ 10008
IDM_FILE_PRINT					equ 10010
IDM_FILE_EXIT					equ 10004
IDM_EDIT						equ 10011
IDM_EDIT_UNDO					equ 10019
IDM_EDIT_REDO					equ 10020
IDM_EDIT_CUT					equ 10012
IDM_EDIT_COPY					equ 10013
IDM_EDIT_PASTE					equ 10014
IDM_EDIT_DELETE					equ 10015
IDM_EDIT_FIND					equ 10017
IDM_EDIT_REPLACE				equ 10018
IDM_EDIT_BLOCK					equ 10022
IDM_EDIT_INDENT					equ 10028
IDM_EDIT_OUTDENT				equ 10029
IDM_EDIT_COMMENT				equ 10030
IDM_EDIT_UNCOMMENT				equ 10031
IDM_EDIT_BOKKMARK				equ 10023
IDM_EDIT_TOGGLEBM				equ 10024
IDM_EDIT_NEXTBM					equ 10025
IDM_EDIT_PREVBM					equ 10026
IDM_EDIT_CLEARBM				equ 10027
IDM_VIEW						equ 10032
IDM_VIEW_STATUSBAR				equ 10033
IDM_VIEW_OUTPUT					equ 10034
IDM_VIEW_DIALOG					equ 10035
IDM_MAKE						equ 10036
IDM_MAKE_ASSEMBLE				equ 10037
IDM_MAKE_BUILD					equ 10038
IDM_MAKE_RUN					equ 10039
IDM_MAKE_GO						equ 10040
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
	hToolProject	HWND ?
	hTabProject		HWND ?
	hFileBrowser	HWND ?
	hProjectBrowser	HWND ?
	hToolProperties	HWND ?
	hProperties		HWND ?
	hToolOutput		HWND ?
	hToolTab		HWND ?
	hStatus			HWND ?
	hReBar			HWND ?
	hCboBuild		HWND ?
	hToolFont		HFONT ?
	hImlTbr			HIMAGELIST ?
	hImlTbrGray		HIMAGELIST ?
	hTbrFile		HWND ?
	hTbrEdit1		HWND ?
	hTbrEdit2		HWND ?
	hTbrView		HWND ?
	hTbrMake		HWND ?
	hDiv1			HWND ?
	hDiv2			HWND ?
ADDINHANDLES ends

WIN struct
	x			DWORD ?
	y			DWORD ?
	wt			DWORD ?
	ht			DWORD ?
	fmax		DWORD ?
	ftopmost	DWORD ?
	fcldmax		DWORD ?
	fSbr		DWORD ?
WIN ends

ADDINDATA struct
	win				WIN <?>
	szAppPath		BYTE MAX_PATH dup(?)
	szRadASMIni		BYTE MAX_PATH dup(?)
ADDINDATA ends

