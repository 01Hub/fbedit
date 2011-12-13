
include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

;Debug
include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

include ..\Addin.inc

IDD_DLGMMIO				equ 1000

.const

szMenuMMIO				BYTE 'Memory Mapped I/O',0

.data?

hInstance				HINSTANCE ?
hDlg					HWND ?
lpAddin					DWORD ?
IDAddin					DWORD ?
