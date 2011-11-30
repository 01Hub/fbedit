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

IDD_SIM52			equ 1000
IDC_LSTCODE			equ 1001

IDM_MENU			equ 10000
IDM_FILE_OPEN		equ 10001
IDM_FILE_EXIT		equ 10002
IDM_HELP_ABOUT		equ 10101

.const

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
