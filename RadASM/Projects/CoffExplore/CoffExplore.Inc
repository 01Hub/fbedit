
include windows.inc
include kernel32.inc
include user32.inc
include Comctl32.inc
include shell32.inc
include gdi32.inc

includelib kernel32.lib
includelib user32.lib
includelib Comctl32.lib
includelib shell32.lib
includelib gdi32.lib

DlgProc			PROTO	:HWND,:UINT,:WPARAM,:LPARAM

IDD_DIALOG1			equ 101
IDC_EDT1			equ 1001
IDC_BTNDUMP			equ 1002
IDC_BTNCOFFHEADER	equ 1003

COFFHEADER struct
	Machine					WORD ?			; 0
	NumberOfSections		WORD ?			; 2
	TimeDateStamp			DWORD ?			; 4
	PointerToSymbolTable	DWORD ?			; 8
	NumberOfSymbols			DWORD ?			; 12
	SizeOfOptionalHeader	WORD ?			; 16
	Characteristics			WORD ?			; 18
COFFHEADER ends

SECTIONHEADER struct
	sName					BYTE 8 dup(?)
	VirtualSize				DWORD ?
	VirtualAddress			DWORD ?
	SizeOfRawData			DWORD ?
	PointerToRawData		DWORD ?
	PointerToRelocations	DWORD ?
	PointerToLinenumbers	DWORD ?
	NumberOfRelocations		WORD ?
	NumberOfLinenumbers		WORD ?
	Characteristics			DWORD ?
SECTIONHEADER ends

.const

; Font
Courier_New_9 			LOGFONT <-12,0,0,0,400,0,0,0,0,3,2,1,49,"Courier New">

szCoffHeader			db 'Machine              %04Xh',0Dh,0Ah
						db 'NumberOfSections     %04Xh',0Dh,0Ah
						db 'TimeDateStamp        %08Xh',0Dh,0Ah
						db 'PointerToSymbolTable %08Xh',0Dh,0Ah
						db 'NumberOfSymbols      %08Xh',0Dh,0Ah
						db 'SizeOfOptionalHeader %04Xh',0Dh,0Ah
						db 'Characteristics      %04Xh',0Dh,0Ah,0

szFileName				db 'CoffExplore.obj',0

;#########################################################################

.data?

hInstance			DWORD ?
hEdt				HWND ?
hEditFont			HFONT ?
szOutput			BYTE 2048 dup(?)
hMemFile			HGLOBAL ?
nCoffHeader			DWORD ?

;#########################################################################
