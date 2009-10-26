
;#########################################################################
;Include files

include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc
include comctl32.inc
include comdlg32.inc

;#########################################################################
;Libraries

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib comctl32.lib
includelib comdlg32.lib

;#########################################################################
;MasmEd Addin Include

include ..\Addins.inc

;#########################################################################
;VKim's Debug

include masm32.inc
include debug.inc
includelib debug.lib

IDD_TBRCREATE		equ 1015
IDC_HMEM			equ 9999

IDC_EDTTBRNAME      equ 1001
IDC_EDTTBRID        equ 1002
IDC_EDTBTNNAME      equ 1005
IDC_EDTBTNID        equ 1003
IDC_LSTBTN          equ 1004
IDC_BTNUP           equ 1006
IDC_BTNADDBTN       equ 1008
IDC_BTNINSBTN       equ 1009
IDC_BTNADDSEP       equ 1011
IDC_BTNINSSEP       equ 1010
IDC_BTNDEL          equ 1012
IDC_BTNDN           equ 1007
IDC_EDTBMPFILE      equ 1013
IDC_BTNBMP          equ 1017
IDC_EDTBMPNAME      equ 1015
IDC_EDTBMPNBR       equ 1014
IDC_STCBTN          equ 1016
IDC_BTNEXPORT       equ 1019
IDC_CHKTBRFLAT      equ 1018
IDC_CHKTBRWRAP      equ 1020
IDC_CHKTBRDIVIDER   equ 1021
IDC_CHKTBRTIP       equ 1023
IDC_CHKTBRLIST      equ 1022
IDC_CHKBTNCHECK     equ 1025
IDC_CHKBTNGROUP     equ 1024
IDC_EDTSIZE         equ 1026
IDC_UDNSIZE         equ 1027
IDC_TBR1            equ 1028
IDC_TBR2            equ 1029

TBRBTN struct
	szBtnName		db 32 dup(?)
	nBtnID			dd ?
	nBmp			dd ?
	nStyle			dd ?
TBRBTN ends

TBR struct
	szTbrName		db 32 dup(?)
	nTbrID			dd ?
	szBmpFile		db MAX_PATH dup(?)
	szBmpName		db 32 dup(?)
	nBmp			dd ?
	nStyle			dd ?
	nBtnSize		dd ?
	nBtn			dd ?
TBR ends

TBRDEF struct
	FileName		db MAX_PATH dup(?)
	hIml			HIMAGELIST ?
	fChanged		dd ?
TBRDEF ends

TBRMEM struct
	tbrdef			TBRDEF <>
	tbr				TBR <>
	tbrbtn			TBRBTN 256 dup(<>)
TBRMEM ends

.const

szMenuItem			db 'Add new Toolbar',0
szNewFile			db '(Untitled)',0
szTbr				db '.tbr',0
szSTD				db 'IDB_STD_SMALL_COLOR',0
szToolbarWindow32	db 'ToolbarWindow32',0
szNULL				db 0
szIDC_TBB			db 'IDC_TBB',0
szSEP				db '-',0
szBMPFilterString	db 'Bitmap (*.bmp)',0,'*.bmp',0,0

.data?

hInstance			dd ?	;Dll's module handle
lpHandles			dd ?	;Pointer to handles struct
lpProc				dd ?	;Pointer to proc struct
lpData				dd ?	;Pointer to data struct
MenuIDAddin			dd ?	;A MenuID allocated for this addin
