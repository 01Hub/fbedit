
include windows.inc
include kernel32.inc
include user32.inc
include Comctl32.inc
include shell32.inc

includelib kernel32.lib
includelib user32.lib
includelib Comctl32.lib
includelib shell32.lib

include ..\RATools.inc

;VKim Debug
include masm32.inc
include \RadASM\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM\masm\lib\debug.lib

DlgProc			PROTO	:HWND,:UINT,:WPARAM,:LPARAM

IDD_DIALOG1						equ 101
IDC_TOOL						equ 1001

.const

szRATools			db 'RATools.dll',0

;#########################################################################

.data?

hInstance			HINSTANCE ?
hLib				HMODULE ?
hTool				HWND ?
hTL1				HWND ?

;#########################################################################
