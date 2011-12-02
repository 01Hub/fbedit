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

include RAHexEd.inc
includelib RAHexEd.lib

;#########################################################################
; VKim's Debug

include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

;#########################################################################

IDD_SIM52               equ 1000
IDC_GRPPORTS            equ 1060
IDC_TBRSIM52            equ 1003
IDC_LSTCODE             equ 1001
IDC_SBRSIM52            equ 1002
IDC_TABSIM52            equ 1004
IDC_GRPSTATUS           equ 1005
IDC_EDTPC               equ 1006
IDC_EDTDPTR             equ 1007
IDC_EDTACC              equ 1008
IDC_EDTB                equ 1010
IDC_EDTSP               equ 1012
IDC_IMGCY               equ 1207
IDC_IMGAC               equ 1206
IDC_IMGF0               equ 1205
IDC_IMGRS1              equ 1204
IDC_IMGRS0              equ 1203
IDC_IMGOV               equ 1202
IDC_IMGFL               equ 1201
IDC_IMGP                equ 1200
IDC_IMGP0_7             equ 1307
IDC_IMGP0_6             equ 1306
IDC_IMGP0_5             equ 1305
IDC_IMGP0_4             equ 1304
IDC_IMGP0_3             equ 1303
IDC_IMGP0_2             equ 1302
IDC_IMGP0_1             equ 1301
IDC_IMGP0_0             equ 1300
IDC_IMGP1_7             equ 1317
IDC_IMGP1_6             equ 1316
IDC_IMGP1_5             equ 1315
IDC_IMGP1_4             equ 1314
IDC_IMGP1_3             equ 1313
IDC_IMGP1_2             equ 1312
IDC_IMGP1_1             equ 1311
IDC_IMGP1_0             equ 1310
IDC_IMGP2_7             equ 1327
IDC_IMGP2_6             equ 1326
IDC_IMGP2_5             equ 1325
IDC_IMGP2_4             equ 1324
IDC_IMGP2_3             equ 1323
IDC_IMGP2_2             equ 1322
IDC_IMGP2_1             equ 1321
IDC_IMGP2_0             equ 1320
IDC_IMGP3_7             equ 1337
IDC_IMGP3_6             equ 1336
IDC_IMGP3_5             equ 1335
IDC_IMGP3_4             equ 1334
IDC_IMGP3_3             equ 1333
IDC_IMGP3_2             equ 1332
IDC_IMGP3_1             equ 1331
IDC_IMGP3_0             equ 1330
IDC_GRPREG              equ 1051
IDC_STCBANK             equ 1069
IDC_UDNBANK             equ 1068
IDC_EDTR0               equ 1052
IDC_EDTR1               equ 1053
IDC_EDTR2               equ 1054
IDC_EDTR3               equ 1055
IDC_EDTR4               equ 1056
IDC_EDTR5               equ 1057
IDC_EDTR6               equ 1058
IDC_EDTR7               equ 1059

IDC_STCCYCLES			equ 1014
IDC_BTNRESET			equ 1013

IDC_TABVIEW             equ 1009

IDD_DLGTABRAM           equ 1100
IDC_GRP1                equ 1101
IDC_UDCHEXRAM           equ 1102

IDD_DLGTABBIT           equ 1200
IDC_GRP2                equ 1201

IDD_DLGTABSFR           equ 1300
IDC_GRP3                equ 1301
IDC_UDCHEXSFR           equ 1302

IDD_DLGTABXRAM          equ 1400
IDC_GRP4                equ 1401
IDC_UDCHEXXRAM          equ 1402

IDD_DLGTABCODE          equ 1500
IDC_GRP5                equ 1501
IDC_UDCHEXCODE          equ 1502

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

MCUADDR struct
	mcuaddr		dw ?
	lbinx		dw ?
	fbp			dw ?
	bytes		db ?
	cycles		db ?
MCUADDR ends

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
szTabStatus			db 'Status',0

szTabRam			db 'Ram',0
szTabBit			db 'Bit',0
szTabSfr			db 'Sfr',0
szTabXRam			db 'XRam',0
szTabCode			db 'Code',0

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
SelTab				dd ?
hTabDlg				HWND 5 dup(?)
