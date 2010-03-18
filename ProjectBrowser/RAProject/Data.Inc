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

PROJECTBROWSER struct
	htrv			HWND ?
	htbr			HWND ?
	himl			HIMAGELIST ?
	projectpath		db MAX_PATH dup(?)
	hmemfileext		HGLOBAL ?
	hmemitems		HGLOBAL ?
PROJECTBROWSER ends

.const

szTreeView				db 'SysTreeView32',0
szToolBar				db 'ToolbarWindow32',0

btns					TBBUTTON <8,1,TBSTATE_ENABLED,TBSTYLE_BUTTON,0,0>
						TBBUTTON <0,0,TBSTATE_ENABLED,TBSTYLE_SEP,0,0>
						TBBUTTON <9,2,TBSTATE_ENABLED,TBSTYLE_BUTTON or TBSTYLE_CHECK,0,0>

.data?

hInstance				dd ?
