
;#########################################################################
; Include files

include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc
include comctl32.inc
;include comdlg32.inc
include dbghelp.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib comctl32.lib
;includelib comdlg32.lib
includelib dbghelp.lib

;#########################################################################
; Libraries

includelib kernel32.lib
includelib user32.lib
;includelib Comctl32.lib
;includelib shell32.lib
;includelib ComDlg32.lib
;includelib Gdi32.lib

;#########################################################################
; RadASM Add In Include

include ..\RadAsm.inc

;#########################################################################
; VKim's Debug

include \RadASM\masm\inc\debug.inc
includelib \RadASM\masm\lib\debug.lib

DBGWIN_DEBUG_ON = 1		; include debug info into the program
DBGWIN_EXT_INFO = 0		; include extra debug info into the program

;#########################################################################
;		Prototypes

DLLProc							PROTO :DWORD, :DWORD, :DWORD, :DWORD
InstallDLL						PROTO :DWORD, :DWORD

IDM_WINDOW_TILEHOR				equ 47005
IDM_WINDOW_TILEVER				equ 47006
IDM_WINDOW_CASCADE				equ 47007
IDM_WINDOW_ARRANGEICONS			equ 47008

.const

DbgHelpDLL						db 'DbgHelp.dll',0

szEXCEPTION_DEBUG_EVENT			db 'EXCEPTION_DEBUG_EVENT',0
szEXCEPTION_BREAKPOINT			db 'EXCEPTION_BREAKPOINT',0
szEXCEPTION_ACCESS_VIOLATION	db 'EXCEPTION_ACCESS_VIOLATION',0
szCREATE_PROCESS_DEBUG_EVENT	db 'CREATE_PROCESS_DEBUG_EVENT',0
szCREATE_THREAD_DEBUG_EVENT		db 'CREATE_THREAD_DEBUG_EVENT',0
szEXIT_THREAD_DEBUG_EVENT		db 'EXIT_THREAD_DEBUG_EVENT',0
szEXIT_PROCESS_DEBUG_EVENT		db 'EXIT_PROCESS_DEBUG_EVENT',0
szLOAD_DLL_DEBUG_EVENT			db 'LOAD_DLL_DEBUG_EVENT',0
szUNLOAD_DLL_DEBUG_EVENT		db 'UNLOAD_DLL_DEBUG_EVENT',0
szOUTPUT_DEBUG_STRING_EVENT		db 'OUTPUT_DEBUG_STRING_EVENT',0
szRIP_EVENT						db 'RIP_EVENT',0
szCRLF							db 0Dh,0Ah,0
szNULL							db 0
szSourceByte					db 'Adress: %X Byte: %X',0
szDebug							db 'Debug',0

szFileName						db 'D:\FbEdit\Projects\Applications\FbEdit\RadASM\Projects\Debug\TestDebug.exe',0

.data

.data?

hInstance						HINSTANCE ?		; Dll's module handle
hDbgHelpDLL						HMODULE ?		; Handle of DbgHelp.dll
lpHandles						dd ?			; Pointer to handles struct
lpProc							dd ?			; Pointer to proc struct
lpData							dd ?			; Pointer to data struct
hOut							HWND ?			; Handle of output window
IDAddIn							dd ?			; Unique ID for this AddIn
