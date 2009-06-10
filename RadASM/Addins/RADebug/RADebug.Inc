
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
;includelib dbghelp.lib
includelib version.lib

;#########################################################################
; RadASM Add In Include

include ..\RadAsm.inc

;#########################################################################
; VKim's Debug

include masm32.inc
includelib masm32.lib
include \RadASM\masm\inc\debug.inc
includelib \RadASM\masm\lib\debug.lib

DBGWIN_DEBUG_ON = 1		; include debug info into the program
DBGWIN_EXT_INFO = 0		; include extra debug info into the program

;#########################################################################
;		Prototypes

DLLProc							PROTO :DWORD, :DWORD, :DWORD, :DWORD
InstallDLL						PROTO :DWORD, :DWORD

;DoNotDebug.dlg
IDD_DLGDONOTDEBUG				equ 1000
IDC_LSTDONOTDEBUG				equ 1001
IDC_LSTDEBUG					equ 1002
IDC_BTNDONOTDEBUG				equ 1003
IDC_BTNDEBUG					equ 1004
IDC_BTNDONOTDEBUGALL			equ 1005
IDC_BTNDEBUGALL					equ 1006

IDM_EDIT_TOGGLEBP				equ 41013
IDM_EDIT_CLEARBP				equ 41014

FUNC_RUN						equ 1
FUNC_STEPINTO					equ 2
FUNC_STEPOVER					equ 3
FUNC_RUNTOCARET					equ 4
FUNC_STOP						equ 5

tagACCEL struct
	fVirt					db ?
	dummy					db ?
	key						dw ?
	cmd						dw ?
tagACCEL ends

BREAKPOINT struct
	ProjectFileID			DWORD ?					; Project file id
	LineNumber				DWORD ?					; Line number, zero based
BREAKPOINT ends

PROPERTIES struct
	nSize			dd ?
	Owner			dd ?
	nType			db ?
PROPERTIES ends

DEBUGSOURCE struct
	FileID					WORD ?
	FileName				BYTE MAX_PATH dup(?)
DEBUGSOURCE ends

DEBUGLINE struct
	LineNumber              DWORD ?
	Address                 DWORD ?
	FileID					WORD ?
	NoDebug					BYTE ?
	BreakPoint				BYTE ?
DEBUGLINE ends

DEBUGSYMBOL struct
	Address                 DWORD ?
	nSize					DWORD ?
	szName					db 64 dup(?)
	lpType					DWORD ?
	nType					WORD ?
	NoDebug					WORD ?
DEBUGSYMBOL ends

DEBUGTHREAD struct
	htread					HANDLE ?				; Thread handle
	threadid				DWORD ?					; Thread ID
	lpline					DWORD ?					; Pointer to line
	address					DWORD ?					; Address
	suspended				DWORD ?					; TRUE if suspended
	isdebugged				DWORD ?
DEBUGTHREAD ends

DEBUG struct
	hDbgThread				HANDLE ?				; Thread that runs the debugger
	pinfo					PROCESS_INFORMATION <>	; Process information
	hdbghand				HANDLE ?				; Handle to read / write process memory
	hdbgfile				HANDLE ?				; File handle
	prevline				DWORD ?					; Previous hilited line
	prevhwnd				DWORD ?					; Previous hilited line window handle
	szprevline				db 256 dup(?)			; Line text
	lpthread				DWORD ?					; Pointer to current thread
	thread					DEBUGTHREAD 64 dup(<>)	; Threads
	context					CONTEXT <>				; Context
	prevcontext				CONTEXT <>				; Previous Context
	inxsource				DWORD ?					; Index to next free DEBUGSOURCE
	hMemSource				HGLOBAL ?				; Handle to memory containing DEBUGSOURCE structures
	inxsymbol				DWORD ?					; Index to next free DEBUGSYMBOL
	hMemSymbol				HGLOBAL ?				; Handle to memory containing DEBUGSYMBOL structures
	inxline					DWORD ?					; Index to next free DEBUGLINE
	hMemLine				HGLOBAL ?				; Handle to memory containing DEBUGLINE structures
	hMemNoBP				HGLOBAL ?
	hMemBP					HGLOBAL ?
	minadr					DWORD ?					; Lowest address
	maxadr					DWORD ?					; Highest address
	lpProc					DWORD ?					; Current proc
	func					DWORD ?					; Current debug function
	fHandled				DWORD ?
	pt						POINT <>
DEBUG ends

VAR struct
	szName					BYTE 256 dup(?)
	szType					BYTE 256 dup(?)
	nType					DWORD ?
	nArray					DWORD ?
	nSize					DWORD ?
	fPtr					DWORD ?
	Address					DWORD ?
VAR ends

REG struct
	szName					BYTE 16 dup(?)
	nSize					DWORD ?
	nOfs					DWORD ?
REG ends

.const

reg32							REG 10 dup(<'EAX',4,CONTEXT.regEax>,
										   <'EBX',4,CONTEXT.regEbx>,
										   <'ECX',4,CONTEXT.regEcx>,
										   <'EDX',4,CONTEXT.regEdx>,
										   <'ESI',4,CONTEXT.regEsi>,
										   <'EDI',4,CONTEXT.regEdi>,
										   <'EBP',4,CONTEXT.regEbp>,
										   <'ESP',4,CONTEXT.regEsp>,
										   <'EIP',4,CONTEXT.regEip>,
										   <'EFL',4,CONTEXT.regFlag>)
reg16							REG 4  dup(<'AX',2,CONTEXT.regEax>,
										   <'BX',2,CONTEXT.regEbx>,
										   <'CX',2,CONTEXT.regEcx>,
										   <'DX',2,CONTEXT.regEdx>)
reg8							REG 10 dup(<'AL',1,CONTEXT.regEax>,
										   <'AH',3,CONTEXT.regEax>,
										   <'BL',1,CONTEXT.regEbx>,
										   <'BH',3,CONTEXT.regEbx>,
										   <'CL',1,CONTEXT.regEcx>,
										   <'CH',3,CONTEXT.regEcx>,
										   <'DL',1,CONTEXT.regEdx>,
										   <'DH',3,CONTEXT.regEdx>,
										   <,0,0>)

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
szSpace							db ' ',0

szSourceByte					db 'Address: %X Byte: %X File: %u',0
szDebug							db 'Debug',0
szDebuggingStarted				db 'Debugging started',0
szUnhanfledBreakpoints			db 'There are %u unhandled breakpoint(s).',0
szUnsavedFiles					db 'There are %u unsaved file(s).',0
szNewerFiles					db '%u source files are newer than the exe.',0
szExeNotFound					db 'Could not open:',0Dh,0Ah,'%s',0
szNoDebugInfo					db 'No debug info found.',0Dh,0Ah,'Use the /Zd, /Zi and /DEBUG command line options.',0

szRADebugBP						db 'RADebugBP',0
szBPNULL						db 0,0
szCommaBP						db ',%u',0

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
szNoDebug						db 'NoDebug',0

szShowDbgHelp					db 'Show DbgHelp output',0
AddinOpt						ADDINOPT <offset szShowDbgHelp,1,1>
								ADDINOPT <0,0,0>
sztooltips_class32				db 'tooltips_class32',0

szReg							db '%s = %X',0
szProc							db '%s PROC Size %u',0
szData							db '%s:%s Address %X Size %u',0
szDataVal						db '%s:%s Address %X Size %u Hex %X Dec %d',0
szParam							db 'PARAM %s Offst %d Hex %X Dec %d',0
szLocal							db 'LOCAL %s Offset %d Hex %X Dec %d',0

szCall							db 'invoke',0
								db 'call',0
;								db 'Add other call types here',0
								db 0

szBYTE							db 'BYTE',0
								db 'DB',0
;								db 'Add other byte types here',0
								db 0

szWORD							db 'WORD',0
								db 'DW',0
;								db 'Add other word types here',0
								db 0

szDWORD							db 'DWORD',0
								db 'DD',0
								db 'HWND',0
								db 'HINSTANCE',0
								db 'HANDLE',0
								db 'HMODULE',0
								db 'HGLOBAL',0
								db 'HMENU',0
								db 'HBITMAP',0
								db 'HBRUSH',0
								db 'HDC',0
								db 'LPARAM',0
								db 'WPARAM',0
								db 'UMSG',0
								db 'PROC',0
								db 'UINT',0
								db 'HACCEL',0
;								db 'Add other dword types here',0
								db 0

.data?

hInstance						HINSTANCE ?						; Dll's module handle
hDbgHelpDLL						HMODULE ?						; Handle of DbgHelp.dll
hTip							HWND ?							; Tooltip
fOptions						dd ?							; Options for RADebug
lpHandles						dd ?							; Pointer to handles struct
lpProc							dd ?							; Pointer to proc struct
lpData							dd ?							; Pointer to data struct
hMnu							HMENU ?							; Debug popup
IDAddIn							dd 32 dup(?)					; Unique ID's for this AddIn
hOut1							HWND ?							; Handle of output window #1
hOut2							HWND ?							; Handle of output window #2
hOut3							HWND ?							; Handle of output window #3
szTempName						db MAX_PATH dup(?)
szExeName						db MAX_PATH dup(?)
szObjName						db MAX_PATH dup(?)
szSourceName					db MAX_PATH dup(?)
szFileName						db MAX_PATH dup(?)
breakpoint						BREAKPOINT 512 dup(<>)			; Breakpoints
lpOldEditProc					dd ?
dbg								DEBUG <>
var								VAR <>
fNoDebugInfo					dd ?
outbuffer						db 1024 dup(?)
typeupper						db 64 dup(?)
