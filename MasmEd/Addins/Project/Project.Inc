
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
szProjectsPath		db '\Projects',0
szTemplatesPath		db '\Templates',0
szBakPath			db 'Bak',0
szResPath			db 'Res',0
szModPath			db 'Mod',0
szIncPath			db 'Inc',0
szNone				db '(None)',0
szTpl				db '\*.tpl',0
szBS				db '\',0
szDot				db '.',0
szAsmFile			db 'asm',0
szIncFile			db 'inc',0
szRcFile			db 'rc',0
szTxtFile			db 'txt',0

;Errors
szErrDir			db 'Could not create directory!',0Dh,0
szErrOpenDir		db 'Could not open directory!',0Dh,0
szErrOverwrite		db 'Overwrite existing file?',0Dh,0
szErrCreate			db 'Could not create the file!',0Dh,0

.data?

hInstance			dd ?		;Dll's module handle
lpHandles			dd ?		;Pointer to handles struct
lpProc				dd ?		;Pointer to proc struct
lpData				dd ?		;Pointer to data struct
MenuIDAddin			dd 4 dup(?)	;4 MenuID's allocated for this addin
hSubMenu			dd ?		;The addins Project sub menu
hook				HOOK <>
ProjectPath			db MAX_PATH dup(?)
TemplatePath		db MAX_PATH dup(?)
tempbuff			db 1024 dup(?)
hDlg1				HWND ?
hDlg2				HWND ?
