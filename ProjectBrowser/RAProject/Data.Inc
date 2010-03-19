include windows.inc
include Comctl32.inc
include user32.inc
include kernel32.inc
include gdi32.inc

includelib comctl32.lib
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

;VKim Debug
include masm32.inc
include \RadASM\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM\masm\lib\debug.lib

IDB_TRV					equ 300
MAXITEMMEM				equ 128*1024
MAXFIEEXTMEM			equ 8*1024

PROJECTBROWSER struct
	hwnd			HWND ?
	htrv			HWND ?
	htbr			HWND ?
	himl			HIMAGELIST ?
	projectpath		db MAX_PATH dup(?)
	hmemfileext		HGLOBAL ?
	hmemitems		HGLOBAL ?
	ngrouping		dd ?
	expanded		dd 256 dup(?)
PROJECTBROWSER ends

SORT struct
	szname			db MAX_PATH dup(?)
	lpPBITEM		dd ?
SORT ends

.const

szTreeView				db 'SysTreeView32',0
szToolBar				db 'ToolbarWindow32',0

btns					TBBUTTON <8,1,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
						TBBUTTON <9,2,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>

CombSort_Const			REAL4 1.3

.data?

hInstance				dd ?
lpOldGroupTrvEditProc	dd ?
IsDragging				dd ?
TVDragItem				dd ?
hDragIml				HIMAGELIST ?
