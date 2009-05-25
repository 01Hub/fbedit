
include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc
include comctl32.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib comctl32.lib

include masm32.inc
include \RadASM\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM\masm\lib\debug.lib

;Debug.dlg
IDD_DIALOG1						equ 101
IDC_EDT1						equ 1001

;#########################################################################

.const

RichEditDLL			db 'riched20.dll',0

szEXCEPTION_DEBUG_EVENT			db 'EXCEPTION_DEBUG_EVENT',0
szCREATE_PROCESS_DEBUG_EVENT	db 'CREATE_PROCESS_DEBUG_EVENT',0
szCREATE_THREAD_DEBUG_EVENT		db 'CREATE_THREAD_DEBUG_EVENT',0
szEXIT_THREAD_DEBUG_EVENT		db 'EXIT_THREAD_DEBUG_EVENT',0
szEXIT_PROCESS_DEBUG_EVENT		db 'EXIT_PROCESS_DEBUG_EVENT',0
szLOAD_DLL_DEBUG_EVENT			db 'LOAD_DLL_DEBUG_EVENT',0
szUNLOAD_DLL_DEBUG_EVENT		db 'UNLOAD_DLL_DEBUG_EVENT',0
szOUTPUT_DEBUG_STRING_EVENT		db 'OUTPUT_DEBUG_STRING_EVENT',0
szRIP_EVENT						db 'RIP_EVENT',0
szCRLF							db 0Dh,0Ah,0

.data

szFileName			db 'TestDebug.exe',0
Courier_New_10		LOGFONT <-13,0,0,0,400,0,0,0,0,3,2,1,49,"Courier New">

.data?

hInstance			HINSTANCE ?
hRichEdDLL			HMODULE ?
hEdt				HWND ?
hFont				HFONT ?
pinfo 				PROCESS_INFORMATION <?>
dbghand				HANDLE ?
dbgdump				dd ?

;#########################################################################
