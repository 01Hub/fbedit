include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include comctl32.inc
include comdlg32.inc

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib STLinkLib.lib

;#########################################################################
;VKim's Debug

include masm32.inc
include \RadASM30\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM30\masm\lib\debug.lib

;#########################################################################

STLinkConnect		PROTO hWin:HWND
STLinkDisconnect	PROTO hWin:HWND
STLinkReset			PROTO hWin:HWND
STLinkRead 			PROTO hWin:HWND,rdadr:DWORD,wradr:DWORD,nBytes:DWORD
STLinkWrite			PROTO hWin:HWND,wradr:DWORD,rdadr:DWORD,nBytes:DWORD

IDD_DIALOG			equ 1000
IDC_EDTSEND			equ 1001
IDC_EDTRECEIVE		equ 1002
IDC_STCBYTESSENDT	equ 1003
IDC_STCBYTESREC		equ 1004
IDC_CHKHEX			equ 1005

IDM_MENU			equ 10000
IDM_FILE_EXIT		equ 10001
IDM_FILE_TEST		equ 10002
IDM_HELP_ABOUT		equ 10101

STM32_Data			equ 20000000h						;STM32 ram address

.const

ClassName			BYTE 'DLGCLASS',0
AppName				BYTE 'Dialog as main',0
AboutMsg			BYTE 'MASM32 RadASM Dialog as main',13,10,'Copyright © MASM32 2001',0
szFmtHex			BYTE '%02X ',0

.data?

hInstance			HINSTANCE ?
CommandLine			DWORD ?
hWnd				HWND ?
fSTLink				DWORD ?
lpOldEditProc		DWORD ?
tail				DWORD ?
hex					DWORD ?
