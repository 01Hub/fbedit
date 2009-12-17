
;#########################################################################
;		Include files

include windows.inc
include kernel32.inc
include user32.inc
;include Comctl32.inc
;include shell32.inc
;include ComDlg32.inc
;include Gdi32.inc

;#########################################################################
;		Libraries

includelib kernel32.lib
includelib user32.lib
;includelib Comctl32.lib
;includelib shell32.lib
;includelib ComDlg32.lib
;includelib Gdi32.lib

;#########################################################################
;		RadASM Add In Include

include ..\radasm.inc

;#########################################################################
;		VKim's Debug

include debug.inc
include masm32.inc
includelib debug.lib

REM_BASE				equ WM_USER+1000
REM_GETUNDO				equ REM_BASE+89		;wParam=nSize, lParam=lpMem
REM_SETUNDO				equ REM_BASE+90		;wParam=nSize, lParam=lpMem

.const

szUndo				db 'Undo',0
szFmtd				db '%d',0
szNULL				db 0
szComma				db ',',0

.data?

hInstance			dd ?	;Dll's module handle
lpHandles			dd ?	;Pointer to handles struct
lpProc				dd ?	;Pointer to proc struct
lpData				dd ?	;Pointer to data struct

