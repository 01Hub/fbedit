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

include RAGrid.inc
includelib RAGrid.lib

include Addin.inc

;#########################################################################
; VKim's Debug

include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

;#########################################################################

IDR_ACCEL1				equ 1

IDD_SIM52               equ 1000
IDC_GRPPORTS            equ 1060
IDC_TBRSIM52            equ 1003
IDC_GRDCODE				equ 1005
IDC_SBRSIM52            equ 1002
IDC_IMGSTATUS			equ 1011
IDC_TABSTATUS            equ 1004

IDD_DLGTABSTATUS		equ 1600
IDC_GRPSTATUS           equ 1005
IDC_EDTPC               equ 1006
IDC_EDTDPTR             equ 1007
IDC_EDTDPTR1			equ 1601
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
IDC_IMGBIT00            equ 1000
IDC_IMGBIT01            equ 1001
IDC_IMGBIT02            equ 1002
IDC_IMGBIT03            equ 1003
IDC_IMGBIT04            equ 1004
IDC_IMGBIT05            equ 1005
IDC_IMGBIT06            equ 1006
IDC_IMGBIT07            equ 1007
IDC_IMGBIT08            equ 1008
IDC_IMGBIT09            equ 1009
IDC_IMGBIT0A            equ 1010
IDC_IMGBIT0B            equ 1011
IDC_IMGBIT0C            equ 1012
IDC_IMGBIT0D            equ 1013
IDC_IMGBIT0E            equ 1014
IDC_IMGBIT0F            equ 1015
IDC_IMGBIT10            equ 1016
IDC_IMGBIT11            equ 1017
IDC_IMGBIT12            equ 1018
IDC_IMGBIT13            equ 1019
IDC_IMGBIT14            equ 1020
IDC_IMGBIT15            equ 1021
IDC_IMGBIT16            equ 1022
IDC_IMGBIT17            equ 1023
IDC_IMGBIT18            equ 1024
IDC_IMGBIT19            equ 1025
IDC_IMGBIT1A            equ 1026
IDC_IMGBIT1B            equ 1027
IDC_IMGBIT1C            equ 1028
IDC_IMGBIT1D            equ 1029
IDC_IMGBIT1E            equ 1030
IDC_IMGBIT1F            equ 1031
IDC_IMGBIT20            equ 1032
IDC_IMGBIT21            equ 1033
IDC_IMGBIT22            equ 1034
IDC_IMGBIT23            equ 1035
IDC_IMGBIT24            equ 1036
IDC_IMGBIT25            equ 1037
IDC_IMGBIT26            equ 1038
IDC_IMGBIT27            equ 1039
IDC_IMGBIT28            equ 1040
IDC_IMGBIT29            equ 1041
IDC_IMGBIT2A            equ 1042
IDC_IMGBIT2B            equ 1043
IDC_IMGBIT2C            equ 1044
IDC_IMGBIT2D            equ 1045
IDC_IMGBIT2E            equ 1046
IDC_IMGBIT2F            equ 1047
IDC_IMGBIT30            equ 1048
IDC_IMGBIT31            equ 1049
IDC_IMGBIT32            equ 1050
IDC_IMGBIT33            equ 1051
IDC_IMGBIT34            equ 1052
IDC_IMGBIT35            equ 1053
IDC_IMGBIT36            equ 1054
IDC_IMGBIT37            equ 1055
IDC_IMGBIT38            equ 1056
IDC_IMGBIT39            equ 1057
IDC_IMGBIT3A            equ 1058
IDC_IMGBIT3B            equ 1059
IDC_IMGBIT3C            equ 1060
IDC_IMGBIT3D            equ 1061
IDC_IMGBIT3E            equ 1062
IDC_IMGBIT3F            equ 1063
IDC_IMGBIT40            equ 1064
IDC_IMGBIT41            equ 1065
IDC_IMGBIT42            equ 1066
IDC_IMGBIT43            equ 1067
IDC_IMGBIT44            equ 1068
IDC_IMGBIT45            equ 1069
IDC_IMGBIT46            equ 1070
IDC_IMGBIT47            equ 1071
IDC_IMGBIT48            equ 1072
IDC_IMGBIT49            equ 1073
IDC_IMGBIT4A            equ 1074
IDC_IMGBIT4B            equ 1075
IDC_IMGBIT4C            equ 1076
IDC_IMGBIT4D            equ 1077
IDC_IMGBIT4E            equ 1078
IDC_IMGBIT4F            equ 1079
IDC_IMGBIT50            equ 1080
IDC_IMGBIT51            equ 1081
IDC_IMGBIT52            equ 1082
IDC_IMGBIT53            equ 1083
IDC_IMGBIT54            equ 1084
IDC_IMGBIT55            equ 1085
IDC_IMGBIT56            equ 1086
IDC_IMGBIT57            equ 1087
IDC_IMGBIT58            equ 1088
IDC_IMGBIT59            equ 1089
IDC_IMGBIT5A            equ 1090
IDC_IMGBIT5B            equ 1091
IDC_IMGBIT5C            equ 1092
IDC_IMGBIT5D            equ 1093
IDC_IMGBIT5E            equ 1094
IDC_IMGBIT5F            equ 1095
IDC_IMGBIT60            equ 1096
IDC_IMGBIT61            equ 1097
IDC_IMGBIT62            equ 1098
IDC_IMGBIT63            equ 1099
IDC_IMGBIT64            equ 1100
IDC_IMGBIT65            equ 1101
IDC_IMGBIT66            equ 1102
IDC_IMGBIT67            equ 1103
IDC_IMGBIT68            equ 1104
IDC_IMGBIT69            equ 1105
IDC_IMGBIT6A            equ 1106
IDC_IMGBIT6B            equ 1107
IDC_IMGBIT6C            equ 1108
IDC_IMGBIT6D            equ 1109
IDC_IMGBIT6E            equ 1110
IDC_IMGBIT6F            equ 1111
IDC_IMGBIT70            equ 1112
IDC_IMGBIT71            equ 1113
IDC_IMGBIT72            equ 1114
IDC_IMGBIT73            equ 1115
IDC_IMGBIT74            equ 1116
IDC_IMGBIT75            equ 1117
IDC_IMGBIT76            equ 1118
IDC_IMGBIT77            equ 1119
IDC_IMGBIT78            equ 1120
IDC_IMGBIT79            equ 1121
IDC_IMGBIT7A            equ 1122
IDC_IMGBIT7B            equ 1123
IDC_IMGBIT7C            equ 1124
IDC_IMGBIT7D            equ 1125
IDC_IMGBIT7E            equ 1126
IDC_IMGBIT7F            equ 1127

IDD_DLGTABSFR           equ 1300
IDC_GRP3                equ 1301
IDC_UDCHEXSFR           equ 1302
IDC_CBOSFR              equ 1303
IDC_STCSFRADDR          equ 1304
IDC_IMGSFRBIT0          equ 1100
IDC_IMGSFRBIT1          equ 1101
IDC_IMGSFRBIT2          equ 1102
IDC_IMGSFRBIT3          equ 1103
IDC_IMGSFRBI4           equ 1104
IDC_IMGSFRBIT5          equ 1105
IDC_IMGSFRBIT6          equ 1106
IDC_IMGSFRBIT7          equ 1107
IDC_STCSFRBIT0          equ 1000
IDC_STCSFRBIT1          equ 1001
IDC_STCSFRBIT2          equ 1002
IDC_STCSFRBIT3          equ 1003
IDC_STCSFRBIT4          equ 1004
IDC_STCSFRBIT5          equ 1005
IDC_STCSFRBIT6          equ 1006
IDC_STCSFRBIT7          equ 1007

IDD_DLGTABXRAM          equ 1400
IDC_GRP4                equ 1401
IDC_UDCHEXXRAM          equ 1402

IDD_DLGTABCODE          equ 1500
IDC_GRP5                equ 1501
IDC_UDCHEXCODE          equ 1502

IDD_DLGTERMINAL			equ 1700
IDC_SCREEN				equ 1701

IDD_DLGFIND             equ 1800
IDC_EDTFIND             equ 1801
IDC_BTNFIND             equ 1802
IDC_RBNBREAKPOINT       equ 1803
IDC_RBNLABEL            equ 1804
IDC_RBNCODE             equ 1805
IDC_CHKMATCH            equ 1806
IDC_CHKWORD             equ 1807
IDC_RBNUP               equ 1808
IDC_RBNDOWN             equ 1809

IDD_DLGCLOCK			equ 1900
IDC_EDTCOMPUTER			equ 1901
IDC_EDTMCU				equ 1902
IDC_EDTREFRESH			equ 1903
IDC_UDNREFRESH			equ 1904

IDD_DLGTABMMIO			equ 2000

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
IDM_OPTION_CLOCK		equ 10013
IDM_HELP_ABOUT          equ 10101

IDB_TBRBMP              equ 100
IDB_LEDGRAY             equ 101
IDB_LEDGREEN            equ 102
IDB_LEDRED              equ 103

FIND_UP					equ 1
FIND_DOWN				equ 2
FIND_LABEL				equ 4
FIND_CODE				equ 8
FIND_BREAKPOINT			equ 16
FIND_MATCH				equ 32
FIND_WORD				equ 64

MCUADDR struct
	mcuaddr				WORD ?
	lbinx				WORD ?
	fbp					WORD ?
	bytes				BYTE ?
	cycles				BYTE ?
MCUADDR ends

ADDINS struct
	hDll				HINSTANCE ?
	lpAddinProc			DWORD ?
ADDINS ends

.const

tbrbtns					TBBUTTON <0,IDM_FILE_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <1,IDM_SEARCH_FIND,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
						TBBUTTON <2,IDM_DEBUG_RUN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <3,IDM_DEBUG_PAUSE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <4,IDM_DEBUG_STOP,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <5,IDM_DEBUG_STEP_INTO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <6,IDM_DEBUG_STEP_OVER,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
						TBBUTTON <7,IDM_DEBUG_TOGGLE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <8,IDM_VIEW_TERMINAL,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
ntbrbtns				equ 11

szClassName				BYTE 'DLGCLASS',0
szAppName				BYTE '8052 Simulator',0
szSlash					BYTE ' - ',0
szAboutMsg				BYTE 'MASM32 RadASM 8052 Simulator',13,10,'Copyright © MASM32 2001',0

szLSTFilterString		BYTE 'LST Files (*.lst)',0,'*.lst',0,0
Courier_New_9 			LOGFONT <-12,0,0,0,400,0,0,0,0,3,2,1,49,"Courier New">
szTabStatus				BYTE 'Status',0

szTabRam				BYTE 'Ram',0
szTabBit				BYTE 'Bit',0
szTabSfr				BYTE 'Sfr',0
szTabXRam				BYTE 'XRam',0
szTabCode				BYTE 'Code',0
szTabMMIO				BYTE 'Memory Mapped I/O',0

szFmtHexByte			BYTE '%02X',0
szFmtHexByteh			BYTE '%02Xh',0
szFmtHexWord			BYTE '%04X',0
szFmtBank				BYTE 'Bank %u',0
szFmtDec				BYTE '%u',0

szLabel					BYTE 'Label',0
szCode					BYTE 'Code',0
szBytes					BYTE 'B',0
szCycles				BYTE 'C',0

szNULL					BYTE 0
szIniFileName			BYTE 'Sim52.ini',0
szSfrFileExt			BYTE '.sfr',0
szIniConfig				BYTE 'Config',0
szIniPos				BYTE 'Pos',0
szIniClock				BYTE 'Clock',0
szIniAddin				BYTE 'Addin',0
szIniMCU				BYTE 'MCU',0
szIniSFRMAP				BYTE 'SFRMAP',0

.data?

addin					ADDIN <>
hFind					HWND ?
CommandLine				DWORD ?
hBmpGrayLed				HBITMAP ?
hBmpGreenLed			HBITMAP ?
hBmpRedLed				HBITMAP ?
SelTab					DWORD ?
hGrd					HWND ?
hIml					HIMAGELIST ?
hTabDlgStatus			HWND ?
hTabDlg					HWND 6 dup(?)
lpOldEditProc			DWORD ?
addins					ADDINS 16 dup(<>)
nFindRow				DWORD ?
nFindPos				DWORD ?
CharTab					BYTE 256 dup(?)
CaseTab					BYTE 256 dup(?)
WinRect					RECT <>
szPath					BYTE MAX_PATH dup(?)
szIniFile				BYTE MAX_PATH dup(?)
szSfrFile				BYTE MAX_PATH dup(?)
szMCUTypes				BYTE 32*16 dup(?)

hMemFile				HGLOBAL ?
hMemAddr				HGLOBAL ?
StatusLed				DWORD ?
ViewBank				DWORD ?
Refresh					DWORD ?
State					DWORD ?
CursorAddr				DWORD ?
TotalCycles				DWORD ?
SBUFWR					DWORD ?
ComputerClock			DWORD ?
MCUClock				DWORD ?
CpuCycles				DWORD ?
PerformanceCount		QWORD ?
RefreshRate				DWORD ?
PCDONE					DWORD ?

