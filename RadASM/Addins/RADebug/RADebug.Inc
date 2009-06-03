
;#########################################################################
; Include files

include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc
include comctl32.inc
include version.inc
include dbghelp.inc
include RAEdit.inc

;#########################################################################
; Libraries

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib comctl32.lib
includelib dbghelp.lib
includelib version.lib

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

IDM_EDIT_TOGGLEBP				equ 41013
IDM_EDIT_CLEARBP				equ 41014

tagACCEL struct
	fVirt					db ?
	dummy					db ?
	key						dw ?
	cmd						dw ?
tagACCEL ends

BREAKPOINT struct
	ProjectFileID			DWORD ?								; Project file id
	LineNumber				DWORD ?								; Line number, zero based
BREAKPOINT ends

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
szDebugStopped					db 'Debuging ended',0
szCRLF							db 0Dh,0Ah,0
szNULL							db 0
szSourceByte					db 'Address: %X Byte: %X File: %u',0
szDebug							db 'Debug',0
szDebuggingStarted				db 'Debugging started',0
szUnhanfledBreakpoints			db 'There are %u unhandled breakpoint(s).',0
szUnsavedFiles					db 'There are %u unsaved file(s).',0
szNewerFiles					db '%u source files are newer than the exe.',0
szExeNotFound					db 'Could not open:',0Dh,0Ah,'%s',0
szNoDebugInfo					db 'No debug info found.',0Dh,0Ah,'Use the /Zd and /DEBUG command line options.',0

DebugMenu						db 'Deb&ug',0
MenuItems						db 'Toggle &Breakpoint',VK_TAB,'Ctrl+T',0
								db '&Clear Breakpoints',VK_TAB,'Ctrl+Shift+T',0
								db '-',0
								db '&Run',VK_TAB,'Shift+F7',0
								db '&Stop',VK_TAB,'Alt+F7',0
								db '-',0
								db 'Step &Into',VK_TAB,'F7',0
								db 'Step &Over',VK_TAB,'Ctrl+F7',0
								db 'Run &To Caret',VK_TAB,'Ctrl+Shift+F7',0
								db 'Do not Debug',0
								db 0
szMakeFiles						db 'MakeFiles',0
szMakeFilesExeKey				db '5',0
szMakeFilesObjKey				db '3',0

szShowDbgHelp					db 'Show DbgHelp output',0
AddinOpt						ADDINOPT <offset szShowDbgHelp,1,1>
								ADDINOPT <0,0,0>

.data?

hInstance						HINSTANCE ?						; Dll's module handle
hDbgHelpDLL						HMODULE ?						; Handle of DbgHelp.dll
fOptions						dd ?							; Options for RADebug
lpHandles						dd ?							; Pointer to handles struct
lpProc							dd ?							; Pointer to proc struct
lpData							dd ?							; Pointer to data struct
hMnu							HMENU ?							; Debug popup
IDAddIn							dd 32 dup(?)					; Unique ID's for this AddIn
hOut							HWND ?							; Handle of output window
szTempName						db MAX_PATH dup(?)
szExeName						db MAX_PATH dup(?)
szObjName						db MAX_PATH dup(?)
szSourceName					db MAX_PATH dup(?)
szFileName						db MAX_PATH dup(?)
breakpoint						BREAKPOINT 512 dup(<>)			; Breakpoints
lpOldEditProc					dd ?
