include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include gdi32.inc
include comctl32.inc
include comdlg32.inc

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib gdi32.lib
includelib comctl32.lib
includelib comdlg32.lib

;#########################################################################
;VKim's Debug

include masm32.inc
include \RadASM30\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM30\masm\lib\debug.lib

;#########################################################################

includelib STLinkLib.lib

STLinkConnect		PROTO hWin:HWND
STLinkDisconnect	PROTO hWin:HWND
STLinkRead 			PROTO hWin:HWND,rdadr:DWORD,wradr:DWORD,nBytes:DWORD
STLinkWrite			PROTO hWin:HWND,wradr:DWORD,rdadr:DWORD,nBytes:DWORD

IDD_DIALOG			equ 1000

IDM_MENU			equ 10000
IDM_FILE_EXIT		equ 10001
IDM_HELP_ABOUT		equ 10101

LENR struct
	SecCount		DWORD ?
	Pwm				DWORD ?
	Volt			WORD ?
	Amp				WORD ?
	Temp1			WORD ?
	Temp2			WORD ?
LENR ends

.const

szMainClass			BYTE 'MAINCLASS',0
szGraphClass		BYTE 'GRAPHCLASS',0

AppName				BYTE 'Dialog as main',0
AboutMsg			BYTE 'MASM32 RadASM Dialog as main',13,10,'Copyright © MASM32 2001',0

.data?

hInstance			HINSTANCE ?
CommandLine			DWORD ?
hWnd				HWND ?
connected			DWORD ?
lenr				LENR <>
