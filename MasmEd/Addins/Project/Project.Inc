
;#########################################################################
;Include files

include windows.inc
include kernel32.inc
include user32.inc

;#########################################################################
;Libraries

includelib kernel32.lib
includelib user32.lib

;#########################################################################
;	MasmEd Addin Include

include ..\Addins.inc

;#########################################################################
;		VKim's Debug

include masm32.inc
include debug.inc
includelib debug.lib

.const

szMenuItem			db 'Project',0
szNewProject		db 'Create New Project',0
szCreateTemplate	db 'Create Project Template',0
szOptions			db 'Options',0
szFiles				db 'Files',0
szTemplate			db 'Template',0

.data?

hInstance			dd ?		;Dll's module handle
lpHandles			dd ?		;Pointer to handles struct
lpProc				dd ?		;Pointer to proc struct
lpData				dd ?		;Pointer to data struct
MenuIDAddin			dd 4 dup(?)	;4 MenuID's allocated for this addin
hSubMenu			dd ?		;The addins Project sub menu
hook				HOOK <>
