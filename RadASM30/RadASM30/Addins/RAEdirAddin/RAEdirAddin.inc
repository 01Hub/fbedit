

RA						equ 1

;#########################################################################
;Include files

include windows.inc
include kernel32.inc
include user32.inc
include Gdi32.inc

;#########################################################################
;Libraries

includelib kernel32.lib
includelib user32.lib
includelib Gdi32.lib

;#########################################################################
;VKim's Debug

include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

;#########################################################################
;RadASM AddIn Include

include RAEdit.inc
include RAResEd.inc
include RACodeComplete.inc
include RAHexEd.inc
include Addins.inc

IDD_DLGRAEDIT		equ 1000
IDC_RAEDIT			equ 1001

.const

szMenuName			db "RAEdir addin demo",0

.data?

hInstance			dd ?					;Dll's module handle
lpHandles			dd ?					;Pointer to handles struct
lpProc				dd ?					;Pointer to proc struct
lpData				dd ?					;Pointer to data struct

hook				HOOK <>
IDAddIn				dd ?
hWnd				dd ?

