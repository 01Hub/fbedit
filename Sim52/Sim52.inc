include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include comctl32.inc
include comdlg32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib gdi32.lib

;#########################################################################
; VKim's Debug

include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

;#########################################################################

IDB_TBRBMP			equ 100

IDD_SIM52			equ 1000
IDC_LSTCODE			equ 1001
IDC_TBRSIM52		equ 1003
IDC_SBRSIM52		equ 1002

IDM_MENU                equ 10000
IDM_FILE_OPEN           equ 10001
IDM_FILE_EXIT           equ 10002
IDM_SEARCH_FIND         equ 10003
IDM_VIEW_TERMINAL       equ 10004
IDM_DEBUG_RUN           equ 10005
IDM_DEBUG_PAUSE         equ 10006
IDM_DEBUG_STOP          equ 10007
IDM_DEBUG_STEP_INTO     equ 10009
IDM_DEBUG_STEP_OVER     equ 10008
IDM_DEBUG_RUN_TO_CURSOR equ 10010
IDM_DEBUG_TOGGLE        equ 10011
IDM_DEBUG_CLEAR         equ 10012
IDM_HELP_ABOUT          equ 10101

.const

tbrbtns				TBBUTTON <0,IDM_FILE_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <1,IDM_SEARCH_FIND,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <2,IDM_DEBUG_RUN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <3,IDM_DEBUG_PAUSE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <4,IDM_DEBUG_STOP,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <5,IDM_DEBUG_STEP_INTO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <6,IDM_DEBUG_STEP_OVER,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <7,IDM_DEBUG_TOGGLE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
					TBBUTTON <8,IDM_VIEW_TERMINAL,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
ntbrbtns			equ 9

ClassName			db 'DLGCLASS',0
AppName				db '8052 Simulator',0
AboutMsg			db 'MASM32 RadASM 8052 Simulator',13,10,'Copyright © MASM32 2001',0

szLSTFilterString	db 'LST Files (*.lst)',0,'*.lst',0,0
Courier_New_9 		LOGFONT <-12,0,0,0,400,0,0,0,0,3,2,1,49,"Courier New">

.data?

hInstance			dd ?
CommandLine			dd ?
hWnd				dd ?
hMemFile			HGLOBAL ?
hMemCode			HGLOBAL ?
hLstFont			HFONT ?
