include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include comctl32.inc
include comdlg32.inc
include gdi32.inc
include shlwapi.inc
include RAEdit.inc

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib gdi32.lib
includelib shlwapi.lib
includelib RAEdit.lib

;#########################################################################
;VKim's Debug

include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

WriteCom				PROTO	:DWORD

IDD_DIALOG              equ 1000
IDC_SCREEN              equ 1001
IDC_SBR1                equ 1002
IDC_TBR1                equ 1003
IDC_RAE1				equ 1004

IDD_DLGCOMPORT          equ 1400
IDC_CHKCOMACTIVE        equ 1401
IDC_EDTCOMPORT          equ 1402
IDC_CBOCOMBAUD          equ 1404
IDC_CBOCOMBITS          equ 1405
IDC_CBOCOMSTOP          equ 1407
IDC_CHKCOMPARITY        equ 1403

IDM_MENU                equ 10000
IDM_FILE_INITCOM        equ 10002
IDM_FILE_EXIT           equ 10001
IDM_FILE_OPEN           equ 10003
IDM_FILE_SAVE           equ 10004
IDM_FILE_PRINT          equ 10005
IDM_FILE_GO             equ 10006
IDM_FILE_DEBUG			equ 10010
IDM_OPTION_COMPORT      equ 10007
IDM_HELP_INSTRUCTIONSET equ 10008
IDM_HELP_HARDWARE		equ 10098

COM struct
	active		DWORD ?								;Communication with MCU is active if TRUE
	szcom		BYTE 16 dup(?)						;Com port (COM1, COM2 ...)
	nbaud		DWORD ?								;Baudrate (4800 to 38400)
	nbits		DWORD ?								;Data bits (7 or 8)
	nparity		DWORD ?								;Parity bit (False/True)
	nstop		DWORD ?								;Stop bits (0 or 1)
COM ends

.const

ClassName				db 'DLGCLASS',0
szCOM					db 'COM1',0
szComFailed				db 'Opening com port failed',0
szDefCmdData			db 'CMDDATA.CMD',0
szDefRomData			db 'ROMDATA.HEX',0
szNULL					db 0

tbrbtnsfile				TBBUTTON <14,IDM_FILE_PRINT,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
						TBBUTTON <7,IDM_FILE_OPEN,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <8,IDM_FILE_SAVE,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
						TBBUTTON <10,IDM_FILE_GO,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
						TBBUTTON <9,IDM_FILE_DEBUG,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>

ntbrbtns				equ 8

szANYString				db 'All Files (*.*)',0,'*.*',0,0
szIniFile				db '\Emu8051.ini',0

szIniCom				db 'Com',0

Courier_New_12 			LOGFONT <-16,0,0,0,400,0,0,0,0,3,2,1,49,"Courier New">

.data?

hInstance				HINSTANCE ?
CommandLine				DWORD ?
hWnd					HWND ?
hScrn					HWND ?
hREd					HWND ?
hFont					HFONT ?
dcb						DCB <>
hCom					HANDLE ?
to						COMMTIMEOUTS <>
lpOldScreenProc			DWORD ?
szapppath				BYTE MAX_PATH dup(?)
szinifile				BYTE MAX_PATH dup(?)
szcmdfilename			BYTE MAX_PATH dup(?)
szromfilename			BYTE MAX_PATH dup(?)
szlstfilename			BYTE MAX_PATH dup(?)
fExit					DWORD ?
fprogrom				DWORD ?
fblockmode				DWORD ?
hrdfile					HANDLE ?
hrdblock				HANDLE ?
hwrfile					HANDLE ?
comopt					COM <>
fDebug					DWORD ?
