ID_EDITCODE						equ	1
ID_EDITTEXT						equ	2
ID_EDITHEX						equ	3
ID_EDITRES						equ 4
ID_EDITUSER						equ 5
ID_PROJECT						equ 6
ID_EXTERNAL						equ 7

ID_FIRSTCHILD					equ 65001
ID_LASTCHILD					equ 65499

;Res\RadASMAcl.rc
IDA_ACCEL						equ 100
IDB_MNUARROW					equ 32101

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
IDM_FILE_RECENTFILES			equ 10179
IDM_FILE_RECENTPROJECTS			equ 10180
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
IDM_EDIT_FINDNEXT				equ 10169
IDM_EDIT_FINDPREV				equ 10170
IDM_EDIT_REPLACE				equ 10018
IDM_EDIT_GOTODECLARE			equ 10172
IDM_EDIT_RETURN					equ 10173
IDM_EDIT_BLOCK					equ 10022
IDM_EDIT_INDENT					equ 10028
IDM_EDIT_OUTDENT				equ 10029
IDM_EDIT_COMMENT				equ 10030
IDM_EDIT_UNCOMMENT				equ 10031
IDM_EDIT_BLOCKMODE				equ 10185
IDM_EDIT_BLOCKINSERT			equ 10186
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
IDM_PROJECT_ADDNEWFILE			equ 10094
IDM_PROJET_ADDEXISTING			equ 10095
IDM_PROJECT_ADDOPEN				equ 10096
IDM_PROJECT_ADDALLOPEN			equ 10097
IDM_PROJECT_ADDGROUP			equ 10098
IDM_PROJECT_REMOVE				equ 10093
IDM_PROJECT_REMOVEFILE			equ 10101
IDM_PROJECT_REMOVEGROUP			equ 10102
IDM_PROJECT_EDIT				equ 10150
IDM_PROJECT_EDITFILE			equ 10165
IDM_PROJECT_EDITGROUP			equ 10164
IDM_PROJECT_OPENITEM			equ 10166
IDM_PROJECT_OPENITEMFILE		equ 10167
IDM_PROJECT_OPENITEMGROUP		equ 10168
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
IDM_MAKE_SETMAIN				equ 10177
IDM_MAKE_TOGGLEMODULE			equ 10178
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
IDM_TOOLS_SNIPLETS				equ 10174
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
IDM_OPTION_ENVIRONMENT			equ 10156
IDM_OPTION_MAKE					equ 10182
IDM_OPTION_EXTERNAL				equ 10158
IDM_OPTION_ADDIN				equ 10157
IDM_OPTION_TOOLS				equ 10160
IDM_OPTION_HELP					equ 10161
IDM_OPTION_F1					equ 10183
IDM_HELP						equ 10045
IDM_HELP_ABOUT					equ 10162

IDM_FILE_RECENTFILESSTART		equ 12000
IDM_FILE_RECENTPROJECTSSTART	equ 12100
IDM_TOOLS_START					equ 12200
IDM_HELP_START					equ 12300
IDM_HELPF1						equ 12400

;Context.mnu
IDR_CONTEXTMENU					equ 11000
IDCM_RESOURCE					equ 11001
IDCM_FILE						equ 11005
IDCM_FILE_OPEN					equ 11014
IDCM_FILE_EXPLORE				equ 11019
IDCM_FILE_TOCODE				equ 11018
IDCM_PROJECT					equ 11006
IDCM_PROPERTY					equ 11008
IDM_PROPERTY_GOTO				equ 11025
IDM_PROPERTY_COPY				equ 11026
IDM_PROPERTY_PROTO				equ 11027
IDCM_OUTPUT						equ 11009
IDM_OUTPUT_HIDE					equ 11020
IDM_OUTPUT_CLEAR				equ 11024
IDM_OUTPUT_CUT					equ 11023
IDM_OUTPUT_COPY					equ 11022

ADDINHANDLES struct
	hInstance			HINSTANCE ?
	hWnd				HWND ?
	hClient				HWND ?
	hMdi				HWND ?
	hEdt				HWND ?
	hMenu				HMENU ?
	hContextMenu		HMENU ?
	hAccel				HACCEL ?
	hIcon				HICON ?
	hCursor				HCURSOR ?
	hSplitCurV			HCURSOR ?
	hSplitCurH			HCURSOR ?
	hTool				HWND ?
	hToolProject		HWND ?
	hTabProject			HWND ?
	hFileBrowser		HWND ?
	hProjectBrowser		HWND ?
	hToolProperties		HWND ?
	hProperty			HWND ?
	hToolOutput			HWND ?
	hTabOutput			HWND ?
	hOutput				HWND ?
	hImmediate			HWND ?
	hToolTab			HWND ?
	hTab				HWND ?
	hStatus				HWND ?
	hReBar				HWND ?
	hStcBuild			HWND ?
	hCboBuild			HWND ?
	hToolFont			HFONT ?
	racf				RAFONT <>
	ratf				RAFONT <>
	rahf				HEFONT <>
	hImlTbr				HIMAGELIST ?
	hImlTbrGray			HIMAGELIST ?
	hMnuIml				HIMAGELIST ?
	hTbrFile			HWND ?
	hTbrEdit1			HWND ?
	hTbrEdit2			HWND ?
	hTbrView			HWND ?
	hTbrMake			HWND ?
	hDiv1				HWND ?
	hDiv2				HWND ?
	hCC					HWND ?
	hTT					HWND ?
	hModeless			HWND ?
	hHtmlOcx			HANDLE ?
	hFind				HWND ?
ADDINHANDLES ends

VIEW_STATUSBAR					equ 1

WIN struct
	x					DWORD ?
	y					DWORD ?
	wt					DWORD ?
	ht					DWORD ?
	fmax				DWORD ?
	ftopmost			DWORD ?
	fcldmax				DWORD ?
	fView				DWORD ?
	ccwt				DWORD ?
	ccht				DWORD ?
	ptfind				POINT <>
WIN ends

;16+20+12=48
RADCOLOR struct
	kwcol				DWORD 16 dup(?)		;Keywords
	racol				RACOLOR <?>			;RAEdit
	toolback			DWORD ?
	tooltext			DWORD ?
	dialogback			DWORD ?
	dialogtext			DWORD ?
	styles				DWORD ?
	words				DWORD ?
	ccback				DWORD ?
	cctext				DWORD ?
	ttback				DWORD ?
	tttext				DWORD ?
	ttapi				DWORD ?
	ttsel				DWORD ?
RADCOLOR ends

THEME struct
	szname				BYTE 32 dup(?)
	radcol				RADCOLOR <>
THEME ends

EDTOPT_EXPTAB					equ 1
EDTOPT_INDENT					equ 2
EDTOPT_LINEHI					equ 4
EDTOPT_CMNTHI					equ 8
EDTOPT_LINENR					equ 16
EDTOPT_SESSION					equ 32
EDTOPT_BRACE					equ 64

EDTOPT struct
	tabsize				DWORD ?
	fopt				DWORD ?
EDTOPT ends

RESOPT_LOCK						equ 1
RESOPT_GRID						equ 2
RESOPT_SNAP						equ 4
RESOPT_LINE						equ 8
RESOPT_HEX						equ 16
RESOPT_AUTO						equ 32
RESOPT_TIP						equ 64

CUSTCTRL struct
	hDll				HMODULE ?
	szFileName			BYTE 128 dup(?)
	szStyleMask			BYTE 16 dup(?)
CUSTCTRL ends

RESOPT struct
	gridx				DWORD ?						;Assembler.ini
	gridy				DWORD ?						;Assembler.ini
	color				DWORD ?						;Assembler.ini
	fopt				DWORD ?						;Assembler.ini
	nExport				DWORD ?						;Assembler.ini
	szExport			BYTE 64 dup(?)				;Assembler.ini
	nOutput				DWORD ?						;Assembler.ini
	custctrl			CUSTCTRL 32 dup(<>)
	custstyle			CUSTSTYLE 64 dup(<>)
	custtype			RARSTYPE 32 dup(<>)
RESOPT ends

EXTERNAL struct
	szprog				BYTE MAX_PATH dup(?)
	szfiles				BYTE 64 dup(?)
EXTERNAL ends

MAKE struct
	szType				BYTE 128 dup(?)
	szCompileRC			BYTE 128 dup(?)
	szOutCompileRC		BYTE 32 dup(?)
	szAssemble			BYTE 128 dup(?)
	szOutAssemble		BYTE 32 dup(?)
	szLink				BYTE 128 dup(?)
	szOutLink			BYTE 32 dup(?)
	szLib				BYTE 128 dup(?)
	szOutLib			BYTE 32 dup(?)
MAKE ends

FIND struct
	fr					DWORD ?
	fdir				DWORD ?
	fscope				DWORD ?
	fres				DWORD ?
	fproc				DWORD ?
	nfound				DWORD ?
	nreplace			DWORD ?
	initchrg			CHARRANGE <>
	scopechrg			CHARRANGE <>
	ft					FINDTEXTEX <>
	szfindbuff			BYTE MAX_PATH dup(?)
	szreplacebuff		BYTE MAX_PATH dup(?)
	repdiff				DWORD ?
	szfindhistory		BYTE 10*256 dup(?)
FIND ends

ADDINDATA struct
	Version				DWORD ?
	win					WIN <>
	winres				WINSIZE <>
	radcolor			RADCOLOR <>
	szAppPath			BYTE MAX_PATH dup(?)
	szRadASMIni			BYTE MAX_PATH dup(?)
	szAssemblerIni		BYTE MAX_PATH dup(?)
	szAssemblerPath		BYTE MAX_PATH dup(?)
	szProjectFile		BYTE MAX_PATH dup(?)
	szProjectPath		BYTE MAX_PATH dup(?)
	szDefProjectPath	BYTE MAX_PATH dup(?)
	szAssemblers		BYTE 256 dup(?)
	szAssembler			BYTE 32 dup(?)
	nAsm				DWORD ?
	szFileName			BYTE MAX_PATH dup(?)
	szFBPath			BYTE MAX_PATH dup(?)
	fProject			DWORD ?
	tabinx				DWORD ?
	fTimer				DWORD ?
	nLastLine			DWORD ?
	nLastPropLine		DWORD ?
	nLastSize			DWORD ?
	fChanged			DWORD ?
	rabdstr				BYTE 2048 dup(?)
	rabd				RABLOCKDEF 32 dup(<>)
	szCmntStart			BYTE 64 dup(?)
	szCmntEnd			BYTE 64 dup(?)
	szBraceMatch		BYTE 64 dup(?)
	cctype				DWORD ?
	inprogress			DWORD ?
	lpCharTab			DWORD ?
	edtopt				EDTOPT <>
	resopt				RESOPT <>
	fLockToolbar		DWORD ?
	szFilter			BYTE 64 dup(?)
	szCodeFiles			BYTE 32 dup(?)
	szTextFiles			BYTE 32 dup(?)
	szHexFiles			BYTE 32 dup(?)
	szResourceFiles		BYTE 32 dup(?)
	szProjectFiles		BYTE 32 dup(?)
	szCCTrig			BYTE 128 dup(?)
	szCCInc				BYTE 32 dup(?)
	szCCLib				BYTE 32 dup(?)
	external			EXTERNAL 20 dup(<>)
	szCODEString		BYTE 64 dup(?)
	szRESString			BYTE 64 dup(?)
	szTXTString			BYTE 64 dup(?)
	szANYString			BYTE 64 dup(?)
	szPROString			BYTE 64 dup(?)
	szALLString			BYTE 64*4 dup(?)
	szTypes				BYTE 256 dup(?)
	szCompileRC			BYTE 128 dup(?)
	szCompileRCHelp		BYTE 128 dup(?)
	szAssemble			BYTE 128 dup(?)
	szAssembleHelp		BYTE 128 dup(?)
	szLink				BYTE 128 dup(?)
	szLinkHelp			BYTE 128 dup(?)
	szLib				BYTE 128 dup(?)
	szLibHelp			BYTE 128 dup(?)
	make				MAKE 32 dup(<>)
	szMainRC			BYTE 128 dup(?)
	szMainAsm			BYTE 128 dup(?)
	szDebug				BYTE 128 dup(?)
	szMruFiles			BYTE 10*MAX_PATH dup(?)
	szMruProjects		BYTE 10*MAX_PATH dup(?)
	pHtmlHelpProc		DWORD ?
	szHelpF1			BYTE 3*MAX_PATH dup(?)
	szCommandLine		BYTE 128 dup(?)
	fDelMinor			DWORD ?
	fCmdExe				DWORD ?
	szCmdExe			BYTE 64 dup(?)
	find				FIND <>
ADDINDATA ends

FILEINFO struct
	pid					DWORD ?
	idparent			DWORD ?
	flag				DWORD ?
	ID					DWORD ?
	rect				RECT <>
	nline				DWORD ?
	filename			BYTE MAX_PATH dup(?)
FILEINFO ends

TABMEM struct
	hwnd				HWND ?					;Handle of the mdi child window.
	hedt				HWND ?					;Handle of the edit window
	pid					DWORD ?					;Project id
	filename			BYTE MAX_PATH dup (?)	;Filename including full path.
	ft					FILETIME <?>			;Filetime for last write.
	nchange				DWORD ?
	fchanged			DWORD ?
	fupdate				DWORD ?
	fnonotify			DWORD ?
TABMEM ends

UAM_ISOPEN						equ 1
UAM_ISOPENACTIVATE				equ 2
UAM_ISRESOPEN					equ 3
UAM_SAVEALL						equ 4
UAM_CLOSEALL					equ 5
UAM_SETCOLORS					equ 6
UAM_SETFONTS					equ 7
UAM_CLEARERRORS					equ 8
UAM_PARSE						equ 9
UAM_ANYBOOKMARKS				equ 10
UAM_CLEARBOOKMARKS				equ 11
UAM_ANYBREAKPOINTS				equ 12
UAM_CLEARBREAKPOINTS			equ 13
