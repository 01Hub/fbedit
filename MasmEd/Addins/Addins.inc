
;Messages to MasmEd's main window
AIM_GETHANDLES				equ WM_USER+50			;returns a poiner to a struct containing all useful handles:see structures below
AIM_GETPROCS				equ WM_USER+51			;returns a poiner to a struct containing some procs in RadASM:see structures below
AIM_GETDATA					equ WM_USER+52			;returns a poiner to a struct comtaining data pointers:see structures below
AIM_GETMENUID				equ WM_USER+53			;Returns a free menu id. If you need more than one wParam contains the number of id's.

;Messages sendt to addins
AIM_ADDINSLOADED			equ WM_USER+100			;This message is sendt to the addins after all addins are loaded. wParam=0, lParam=0
AIM_COMMAND					equ WM_USER+101			;This message is sendt to the addins when user makes a menu selection or clicks a toolbar button. wParam and lParam as for WM_COMMAND
AIM_CLOSE					equ WM_USER+102			;MasmEd requests closing. Return TRUE to prevent MasmEd from closing. wParam and lParam as for WM_CLOSE
AIM_DESTROY					equ WM_USER+103			;MasmEd is about to be destroyed. Now is the time to free memory and resources that your addin allocated. Always return FALSE. wParam and lParam as for WM_DESTROY
AIM_MENUUPDATE				equ WM_USER+104			;MasmEd has updated menues. Now is the time to add menu items. Always return FALSE. wParam=hMnu, lParam=hContextMnu. NOTE: This command can be sendt more than once. Do not allocate MenuID's here.

;HOOK flags returned in hook1 of HOOK structure
HOOK_ADDINSLOADED			equ 1
HOOK_COMMAND				equ 2
HOOK_CLOSE					equ 4
HOOK_DESTROY				equ 8
HOOK_MENUUPDATE				equ 16

HOOK struct
	hook1					DWORD ?					;Combinations of HOOK_ flags
	hook2					DWORD ?					;Not used must be zero
	hook3					DWORD ?					;Not used must be zero
	hook4					DWORD ?					;Not used must be zero
HOOK ends

ADDINHANDLES struct
	hWnd					HWND ?					;Handle of main window
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
	lpOutputSelect			DWORD ?
	lpOutputShow			DWORD ?
	lpOutputString			DWORD ?
	lpOutputClear			DWORD ?
ADDINPROCS ends

;Edit window ID
IDC_RAE						equ 1011
IDC_RES						equ 1012
IDC_HEX						equ 1013

;MasmEd.mnu
IDM_MENU					equ 10000
IDM_HELPF1					equ 500
IDM_FILE					equ 11000
IDM_FILE_NEW				equ 10001
IDM_FILE_NEW_RES			equ 10007
IDM_FILE_OPEN				equ 10002
IDM_FILE_OPEN_HEX			equ 10022
IDM_FILE_SAVE				equ 10003
IDM_FILE_SAVEAS				equ 10004
IDM_FILE_SAVEALL			equ 10011
IDM_FILE_CLOSE				equ 10010
IDM_FILE_CLOSE_ALL			equ 10058
IDM_FILE_OPENSESSION		equ 10076
IDM_FILE_SAVESESSION		equ 10077
IDM_FILE_CLOSESESSION		equ 10078
IDM_FILE_PAGESETUP			equ 10029
IDM_FILE_PRINT				equ 10005
IDM_FILE_EXIT				equ 10006

IDM_EDIT					equ 11001
IDM_EDIT_UNDO				equ 10101
IDM_EDIT_REDO				equ 10102
IDM_EDIT_DELETE				equ 10103
IDM_EDIT_CUT				equ 10104
IDM_EDIT_COPY				equ 10105
IDM_EDIT_PASTE				equ 10106
IDM_EDIT_SELECTALL			equ 10107
IDM_EDIT_FIND				equ 10108
IDM_EDIT_FINDNEXT			equ 10110
IDM_EDIT_FINDPREV			equ 10111
IDM_EDIT_REPLACE			equ 10109
IDM_EDIT_GOTO				equ 10091
IDM_EDIT_RETURN				equ 10092
IDM_EDIT_INDENT				equ 10037
IDM_EDIT_OUTDENT			equ 10038
IDM_EDIT_COMMENT			equ 10035
IDM_EDIT_UNCOMMENT			equ 10036
IDM_EDIT_BLOCKMODE			equ 10061
IDM_EDIT_BLOCKINSERT		equ 10062
IDM_EDIT_TOGGLEBM			equ 10018
IDM_EDIT_NEXTBM				equ 10019
IDM_EDIT_PREVBM				equ 10020
IDM_EDIT_CLEARBM			equ 10021
IDM_EDIT_CLEARERRORS		equ 10074
IDM_EDIT_NEXTERROR			equ 10075

IDM_FORMAT					equ 11002
IDM_FORMAT_LOCK				equ 10012
IDM_FORMAT_BACK				equ 10013
IDM_FORMAT_FRONT			equ 10014
IDM_FORMAT_GRID				equ 10015
IDM_FORMAT_SNAP				equ 10016
IDM_FORMAT_ALIGN			equ 10017
IDM_FORMAT_ALIGN_LEFT		equ 10034
IDM_FORMAT_ALIGN_CENTER		equ 10042
IDM_FORMAT_ALIGN_RIGHT		equ 10043
IDM_FORMAT_ALIGN_TOP		equ 10044
IDM_FORMAT_ALIGN_MIDDLE		equ 10045
IDM_FORMAT_ALIGN_BOTTOM		equ 10046
IDM_FORMAT_SIZE				equ 10033
IDM_FORMAT_SIZE_WIDTH		equ 10039
IDM_FORMAT_SIZE_HEIGHT		equ 10040
IDM_FORMAT_SIZE_BOTH		equ 10041
IDM_FORMAT_CENTER			equ 10066
IDM_FORMAT_CENTER_HOR		equ 10067
IDM_FORMAT_CENTER_VERT		equ 10068
IDM_FORMAT_TABINDEX			equ 10069

IDM_VIEW					equ 11003
IDM_VIEW_TOOLBAR			equ 10008
IDM_VIEW_STATUSBAR			equ 10009
IDM_VIEW_OUTPUT				equ 10023
IDM_VIEW_DIALOG				equ 10065
IDM_VIEW_FILEBROWSER		equ 10059

IDM_RESOURCE				equ 11004
IDM_RESOURCE_DIALOG			equ 10048
IDM_RESOURCE_MENU			equ 10049
IDM_RESOURCE_ACCEL			equ 10050
IDM_RESOURCE_VERINF			equ 10051
IDM_RESOURCE_MANIFEST		equ 10071
IDM_RESOURCE_RCDATA			equ 10072
IDM_RESOURCE_TOOLBAR		equ 10073
IDM_RESOURCE_LANGUAGE		equ 10064
IDM_RESOURCE_INCLUDE		equ 10052
IDM_RESOURCE_RESOURCE		equ 10053
IDM_RESOURCE_STRING			equ 10054
IDM_RESOURCE_NAME			equ 10055
IDM_RESOURCE_EXPORT			equ 10063
IDM_RESOURCE_REMOVE			equ 10056
IDM_RESOURCE_UNDO			equ 10057

IDM_MAKE					equ 11005
IDM_MAKE_COMPILE			equ 10024
IDM_MAKE_ASSEMBLE			equ 10025
IDM_MAKE_LINK				equ 10026
IDM_MAKE_BUILD				equ 10090
IDM_MAKE_RUN				equ 10027
IDM_MAKE_GO					equ 10028
IDM_DEBUG_TOGGLE			equ 10082
IDM_DEBUG_CLEAR				equ 10083
IDM_DEBUG_RUN				equ 10081
IDM_DEBUG_BREAK				equ 10089
IDM_DEBUG_STOP				equ 10084
IDM_DEBUG_INTO				equ 10085
IDM_DEBUG_OVER				equ 10086
IDM_DEBUG_CARET				equ 10087
IDM_DEBUG_NODEBUG			equ 10088
IDM_MAKE_MAINFILE			equ 10079

IDM_TOOLS					equ 11005

IDM_OPTION					equ 11006
IDM_OPTION_CODE				equ 10030
IDM_OPTION_DIALOG			equ 10047
IDM_OPTION_PATH				equ 10080
IDM_OPTION_BUILD			equ 10070
IDM_OPTION_TOOLS			equ 10031
IDM_OPTION_HELP				equ 10032

IDM_HELP					equ 11007
IDM_HELP_ABOUT				equ 10201

IDR_MENUCONTEXT				equ 21000
IDM_TABTOOL					equ 21001
IDM_FILE_CLOSE_ALL_BUT		equ 21002
IDM_OUTPUT_CLEAR			equ 21004
IDM_IMMEDIATE_CLEAR			equ 21013
IDM_BROWSER_OPEN			equ 21006
IDM_BROWSER_COPY			equ 21007
IDM_PROPERTY_GOTODECLARE	equ 21010
IDM_PROPERTY_COPYTOCODE		equ 21011

