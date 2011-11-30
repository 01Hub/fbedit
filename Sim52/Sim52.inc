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

IDD_SIM52               equ 1000
IDC_TABSIM52            equ 1004
IDC_GRPPORTS            equ 1060
IDC_GRPREG              equ 1051
IDC_GRPSTATUS           equ 1005
IDC_LSTCODE             equ 1001
IDC_SBRSIM52            equ 1002
IDC_TBRSIM52            equ 1003
IDC_EDTPC               equ 1006
IDC_EDTDPTR             equ 1007
IDC_EDTACC              equ 1008
IDC_EDTB                equ 1010
IDC_EDTSP               equ 1012
IDC_IMGCY               equ 1023
IDC_IMGAC               equ 1024
IDC_IMGF0               equ 1025
IDC_IMGRS1              equ 1026
IDC_IMGRS0              equ 1027
IDC_IMGOV               equ 1028
IDC_IMGFL               equ 1029
IDC_IMGP                equ 1030
IDC_IMGP0_0             equ 1009
IDC_IMGP0_1             equ 1011
IDC_IMGP0_2             equ 1013
IDC_IMGP0_3             equ 1014
IDC_IMGP0_4             equ 1015
IDC_IMGP0_5             equ 1016
IDC_IMGP0_6             equ 1017
IDC_IMGP0_7             equ 1018
IDC_IMGP1_0             equ 1019
IDC_IMGP1_1             equ 1020
IDC_IMGP1_2             equ 1021
IDC_IMGP1_3             equ 1022
IDC_IMGP1_4             equ 1031
IDC_IMGP1_5             equ 1032
IDC_IMGP1_6             equ 1033
IDC_IMGP1_7             equ 1034
IDC_IMGP2_0             equ 1035
IDC_IMGP2_1             equ 1036
IDC_IMGP2_2             equ 1037
IDC_IMGP2_3             equ 1038
IDC_IMGP2_4             equ 1039
IDC_IMGP2_5             equ 1040
IDC_IMGP2_6             equ 1041
IDC_IMGP2_7             equ 1042
IDC_IMGP3_0             equ 1043
IDC_IMGP3_1             equ 1044
IDC_IMGP3_2             equ 1045
IDC_IMGP3_3             equ 1046
IDC_IMGP3_4             equ 1047
IDC_IMGP3_5             equ 1048
IDC_IMGP3_6             equ 1049
IDC_IMGP3_7             equ 1050
IDC_EDTR0               equ 1052
IDC_EDTR1               equ 1053
IDC_EDTR2               equ 1054
IDC_EDTR3               equ 1055
IDC_EDTR4               equ 1056
IDC_EDTR5               equ 1057
IDC_EDTR6               equ 1058
IDC_EDTR7               equ 1059
IDC_UDNBANK             equ 1068
IDC_STCBANK             equ 1069

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

IDB_TBRBMP              equ 100
IDB_LEDGRAY             equ 101
IDB_LEDGREEN            equ 102
IDB_LEDRED              equ 103

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
szTabTitle			db 'Status',0

szFmtHexByte		db '%02X',0
szFmtHexWord		db '%04X',0
szFmtBank			db 'Bank %u',0

.data?

hInstance			dd ?
CommandLine			dd ?
hWnd				dd ?
hMenu				HMENU ?
hLstFont			HFONT ?
hBmpGrayLed			HBITMAP ?
hBmpGreenLed		HBITMAP ?
hBmpRedLed			HBITMAP ?
