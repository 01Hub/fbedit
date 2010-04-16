ID_EDITCODE						equ	65501
ID_EDITTEXT						equ	65502
ID_EDITHEX						equ	65503
ID_EDITRES						equ 65004
ID_EDITUSER						equ 65005

ID_FIRSTCHILD					equ 65001
ID_LASTCHILD					equ 65499

;Res\RadASMAcl.rc
IDA_ACCEL						equ 100

;RadASM.mnu
IDR_MENU						equ 10000
IDM_FILE						equ 10001
IDM_FILE_NEW					equ 10002
IDM_FILE_OPEN					equ 10006
IDM_FILE_OPENHEX				equ 10060
IDM_FILE_REOPEN					equ 10062
IDM_FILE_CLOSE					equ 10055
IDM_FILE_SAVE					equ 10007
IDM_FILE_SAVEAS					equ 10061
IDM_FILE_SAVEALL				equ 10008
IDM_FILE_PAGESETUP				equ 10056
IDM_FILE_PRINT					equ 10010
IDM_FILE_EXIT					equ 10004
IDM_EDIT						equ 10011
IDM_EDIT_UNDO					equ 10019
IDM_EDIT_REDO					equ 10020
IDM_EDIT_CUT					equ 10012
IDM_EDIT_COPY					equ 10013
IDM_EDIT_PASTE					equ 10014
IDM_EDIT_DELETE					equ 10015
IDM_EDIT_SELECTALL				equ 10059
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
IDM_VIEW_LOCK					equ 10063
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
IDM_FORMAT_LOCK					equ 10070
IDM_FORMAT_FRONT				equ 10071
IDM_FORMAT_BACK					equ 10072
IDM_FORMAT_SHOW					equ 10073
IDM_FORMAT_SNAP					equ 10074
IDM_FORMAT_ALIGN				equ 10076
IDM_FORMAT_ALIGNLEFT			equ 10080
IDM_FORMAT_ALIGNCENTER			equ 10081
IDM_FORMAT_ALIGNRIGHT			equ 10082
IDM_FORMAT_ALIGNTOP				equ 10084
IDM_FORMAT_ALIGNMIDDLE			equ 10085
IDM_FORMAT_ALIGNBOTTOM			equ 10086
IDM_FORMAT_SIZE					equ 10077
IDM_FORMAT_SIZEWIDTH			equ 10087
IDM_FORMAT_SIZEHEIGHT			equ 10088
IDM_FORMAT_SIZEBOTH				equ 10089
IDM_FORMAT_CENTER				equ 10078
IDM_FORMAT_CENTERHORIZONTAL		equ 10090
IDM_FORMAT_CENTERVERTICAL		equ 10091
IDM_FORMAT_INDEX				equ 10079
IDM_PROJECT						equ 10042
IDM_PROJECT_NEW					equ 10066
IDM_PROJECT_OPEN				equ 10067
IDM_PROJECT_CLOSE				equ 10068
IDM_PROJECT_ADD					equ 10092
IDM_PROJECT_ADDFILE				equ 10094
IDM_PROJET_ADDEXISTING			equ 10095
IDM_PROJECT_ADDOPEN				equ 10096
IDM_PROJECT_ADDALLOPEN			equ 10097
IDM_PROJECT_ADDGROUP			equ 10098
IDM_PROJECT_REMOVE				equ 10093
IDM_PROJECT_REMOVEFILE			equ 10101
IDM_PROJECT_REMOVEGROUP			equ 10102
IDM_PROJECT_OPTION				equ 10103
IDM_RESOURCE					equ 10065
IDM_RESOURCE_ADD				equ 10108
IDM_RESOURCE_ADDDIALOG			equ 10109
IDM_RESOURCE_ADDMENU			equ 10110
IDM_RESOURCE_ADDACCELERATOR		equ 10111
IDM_RESOURCE_ADDVERSION			equ 10112
IDM_RESOURCE_ADDSTRING			equ 10113
IDM_RESOURCE_ADDMANIFEST		equ 10114
IDM_RESOURCE_ADDRCDATA			equ 10115
IDM_RESOURCE_ADDTOLBAR			equ 10116
IDM_RESOURCE_LANGUAGE			equ 10117
IDM_RESOURCE_INCLUDE			equ 10118
IDM_RESOURCE_RESOURCE			equ 10119
IDM_RESOURCE_NAMES				equ 10120
IDM_RESOURCE_EXPORT				equ 10121
IDM_RESOURCE_REMOVE				equ 10123
IDM_RESOURCE_UNDO				equ 10124
IDM_MAKE						equ 10036
IDM_MAKE_COMPILE				equ 10104
IDM_MAKE_ASSEMBLE				equ 10037
IDM_MAKE_MODULES				equ 10141
IDM_MAKE_LINK					equ 10107
IDM_MAKE_BUILD					equ 10038
IDM_MAKE_GO						equ 10040
IDM_MAKE_RUN					equ 10039
IDM_MAKE_DEBUG					equ 10140
IDM_DEBUG						equ 10125
IDM_DEBUG_TOGGLE				equ 10128
IDM_DEBUG_CLEAR					equ 10129
IDM_DEBUG_RUN					equ 10131
IDM_DEBUG_BREAK					equ 10132
IDM_DEBUG_STOP					equ 10133
IDM_DEBUG_INTO					equ 10135
IDM_DEBUG_OVER					equ 10136
IDM_DEBUG_CARET					equ 10137
IDM_DEBUG_NODEBUG				equ 10139
IDM_TOOLS						equ 10043
IDM_WINDOW						equ 10005
IDM_WINDOW_CLOSE				equ 10055
IDM_WINDOW_CLOSEALL				equ 10151
IDM_WINDOW_CLOSEALLBUT			equ 10152
IDM_WINDOW_HORIZONTAL			equ 10142
IDM_WINDOW_VERTICAL				equ 10143
IDM_WIDDOW_CASCADE				equ 10144
IDM_WINDOW_ICONS				equ 10145
IDM_WINDOW_MAXIMIZE				equ 10147
IDM_WINDOW_RESTORE				equ 10148
IDM_WINDOW_MINIMIZE				equ 10149
IDM_OPTION						equ 10044
IDM_OPTION_CODE					equ 10154
IDM_OPTION_RESOURCE				equ 10155
IDM_OPTION_PATH					equ 10156
IDM_OPTION_EXTERNAL				equ 10158
IDM_OPTION_ADDIN				equ 10157
IDM_OPTION_TOOLS				equ 10160
IDM_OPTION_HELP					equ 10161
IDM_HELP						equ 10045
IDM_HELP_ABOUT					equ 10162

;Context.mnu
IDR_CONTEXTMENU					equ 11000
IDCM_RESOURCE					equ 11001

ADDINHANDLES struct
	hWnd			HWND ?
	hClient			HWND ?
	hMdi			HWND ?
	hEdt			HWND ?
	hInstance		HINSTANCE ?
	hMenu			HMENU ?
	hContextMenu	HMENU ?
	hAccel			HACCEL ?
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
	hProperty		HWND ?
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
	hCC				HWND ?
	hTT				HWND ?
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
	ccwt			DWORD ?
	ccht			DWORD ?
WIN ends

;16+20+12=48
RADCOLOR struct
	kwcol			DWORD 16 dup(?)		;Keywords
	racol			RACOLOR <?>			;RAEdit
	toolback		DWORD ?
	tooltext		DWORD ?
	dialogback		DWORD ?
	dialogtext		DWORD ?
	styles			DWORD ?
	words			DWORD ?
	ccback			DWORD ?
	cctext			DWORD ?
	ttback			DWORD ?
	tttext			DWORD ?
	ttapi			DWORD ?
	ttsel			DWORD ?
RADCOLOR ends

EDTOPT struct
	tabsize			DWORD ?
	exptabs			DWORD ?
	indent			DWORD ?
	hiliteline		DWORD ?
	hilitecmnt		DWORD ?
	session			DWORD ?
	linenumber		DWORD ?
EDTOPT ends

ADDINDATA struct
	win				WIN <>
	winres			WINSIZE <>
	radcolor		RADCOLOR <>
	szAppPath		BYTE MAX_PATH dup(?)
	szRadASMIni		BYTE MAX_PATH dup(?)
	szAssemblerIni	BYTE MAX_PATH dup(?)
	szProject		BYTE MAX_PATH dup(?)
	szProjectPath	BYTE MAX_PATH dup(?)
	szAssembler		BYTE 32 dup(?)
	nAsm			DWORD ?
	szFileName		BYTE MAX_PATH dup(?)
	szFBPath		BYTE MAX_PATH dup(?)
	fProject		DWORD ?
	tabinx			DWORD ?
	fTimer			DWORD ?
	nLastLine		DWORD ?
	nLastPropLine	DWORD ?
	nLastSize		DWORD ?
	rabdstr			BYTE 2048 dup(?)
	rabd			RABLOCKDEF 32 dup(<>)
	szCmntStart		BYTE 64 dup(?)
	szCmntEnd		BYTE 64 dup(?)
	szBraceMatch	BYTE 64 dup(?)
	cctype			DWORD ?
	inprogress		DWORD ?
	lpCharTab		DWORD ?
	edtopt			EDTOPT <>
	fLockToolbar	DWORD ?
	szCodeFiles		BYTE 32 dup(?)
	szTextFiles		BYTE 32 dup(?)
	szHexFiles		BYTE 32 dup(?)
	szResourceFiles	BYTE 32 dup(?)
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
UAM_SAVEALL						equ 4
UAM_CLOSEALL					equ 5
