ID_EDITCODE						equ	65501
ID_EDITTEXT						equ	65502
ID_EDITHEX						equ	65503
ID_EDITRES						equ 65004
ID_EDITUSER						equ 65005

ID_FIRSTCHILD					equ 65001
ID_LASTCHILD					equ 65499

;RadASM.mnu
IDR_MENU						equ 10000
IDM_FILE						equ 10001
IDM_FILE_NEW					equ 10002
IDM_FILE_CLOSE					equ 10055
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
IDM_VIEW_TOOLBAR				equ 10046
IDM_VIEW_TBFILE					equ 10049
IDM_VIEW_TBEDIT					equ 10050
IDM_VIEW_TBBOOKMARK				equ 10053
IDM_VIEW_TBVIEW					equ 10051
IDM_VIEW_TBMAKE					equ 10052
IDM_VIEW_TBBUILD				equ 10054
IDM_VIEW_STATUSBAR				equ 10033
IDM_VIEW_PROJECT				equ 10047
IDM_VIEW_PROPERTIES				equ 10048
IDM_VIEW_OUTPUT					equ 10034
IDM_VIEW_TAB					equ 10035
IDM_FORMAT						equ 10041
IDM_PROJECT						equ 10042
IDM_MAKE						equ 10036
IDM_MAKE_ASSEMBLE				equ 10037
IDM_MAKE_BUILD					equ 10038
IDM_MAKE_RUN					equ 10039
IDM_MAKE_GO						equ 10040
IDM_TOOLS						equ 10043
IDM_WINDOW						equ 10005
IDM_OPTION						equ 10044
IDM_HELP						equ 10045

ADDINHANDLES struct
	hWnd			HWND ?
	hClient			HWND ?
	hMdi			HWND ?
	hEdt			HWND ?
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
	hTabOutput		HWND ?
	hOutput			HWND ?
	hImmediate		HWND ?
	hToolTab		HWND ?
	hTab			HWND ?
	hStatus			HWND ?
	hReBar			HWND ?
	hStcBuild		HWND ?
	hCboBuild		HWND ?
	hToolFont		HFONT ?
	racf			RAFONT <>
	ratf			RAFONT <>
	rahf			HEFONT <>
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

VIEW_STATUSBAR					equ 1

WIN struct
	x				DWORD ?
	y				DWORD ?
	wt				DWORD ?
	ht				DWORD ?
	fmax			DWORD ?
	ftopmost		DWORD ?
	fcldmax			DWORD ?
	fView			DWORD ?
WIN ends

ADDINDATA struct
	win				WIN <?>
	winres			WINSIZE <?>
	szAppPath		BYTE MAX_PATH dup(?)
	szRadASMIni		BYTE MAX_PATH dup(?)
	FileName		BYTE MAX_PATH dup(?)
	fProject		DWORD ?
	tabinx			DWORD ?
	fTimer			DWORD ?
	nLastSize		DWORD ?
ADDINDATA ends

TABMEM struct
	hwnd			HWND ?					;Handle of the mdi child window.
	hedt			HWND ?					;Handle of the edit window
	pid				DWORD ?					;Project id
	filename		BYTE MAX_PATH dup (?)	;Filename including full path.
	ft				FILETIME <?>			;Filetime for last write.
	nchange			DWORD ?
	fchanged		DWORD ?
	fupdate			DWORD ?
	fnonotify		DWORD ?
TABMEM ends

UAM_ISOPEN						equ 1
UAM_ISOPENACTIVATE				equ 2
UAM_ISRESOPEN					equ 3
