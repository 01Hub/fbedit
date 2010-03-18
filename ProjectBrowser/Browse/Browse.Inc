
include windows.inc
include kernel32.inc
include user32.inc
include Comctl32.inc
include shell32.inc

includelib kernel32.lib
includelib user32.lib
includelib Comctl32.lib
includelib shell32.lib

include ..\RAProject.inc

DlgProc			PROTO	:HWND,:UINT,:WPARAM,:LPARAM

.const

IDD_DIALOG1			equ 101
IDC_RAP				equ 1001

szRAProject			db 'RAProject.dll',0

;#########################################################################
pbfileext			PBFILEEXT 3 dup(<1,'.asm.'>,<2,'.inc.'>,<0>)
pbitems				PBITEM 7 dup(<-1,0,'MyProject'>,<-2,-1,'Assembly'>,<-3,-2,'Asm'>,<-4,-2,'Inc'>,<1,-3,'MyAsm1.asm'>,<2,-3,'MyAsm2.asm'>,<3,-4,'MyInc.inc'>,<0,0>)

.data?

hInstance			HINSTANCE ?
hLib				HMODULE ?
hPbr				HWND ?

;#########################################################################
