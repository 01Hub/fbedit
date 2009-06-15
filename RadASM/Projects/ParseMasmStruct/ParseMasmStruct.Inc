
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

;#########################################################################
; VKim's Debug

include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

IDD_DIALOG1			equ 101
IDC_EDT1			equ 1001

IDD_DLGRESULT		equ 2000
IDC_EDTRESULT		equ 2001

PREDATATYPE struct
	lpName		DWORD ?
	lpConvert	DWORD ?
	nSize		DWORD ?
PREDATATYPE ends

STRUCTSIZE struct
	nSize		DWORD ?
	szName		BYTE ?
STRUCTSIZE ends

.const

Courier_New_9 LOGFONT <-12,0,0,0,400,0,0,0,0,3,2,1,49,"Courier New">

szColon				db ':',0
szComma				db ',',0
szDot				db '.',0

szCrLf				db 0Dh,0Ah,0
szFmtDec			db '%u',0

szStructSizeFileName	db 'StructSize.txt',0
szTypeSizeFileName		db 'TypeSize.txt',0
szConstSizeFileName		db 'ConstSize.txt',0

szStruct			db 'struct',0
szUnion				db 'union',0
szEnds				db 'ends',0

; Predefined datatypes
szBYTE				db 'BYTE',0
szSBYTE				db 'SBYTE',0
szDB				db 'DB',0
szWORD				db 'WORD',0
szSWORD				db 'SWORD',0
szDW				db 'DW',0
szDWORD				db 'DWORD',0
szSDWORD			db 'SDWORD',0
szDD				db 'DD',0
szQWORD				db 'QWORD',0
szDQ				db 'DQ',0
szTBYTE				db 'TBYTE',0
szDT				db 'DT',0
					db 0

predatatype			PREDATATYPE 14 dup(<szBYTE,szBYTE,1>,
									   <szSBYTE,szSBYTE,1>,
									   <szDB,szBYTE,1>,
									   <szWORD,szWORD,2>,
									   <szSWORD,szSWORD,2>,
									   <szDW,szWORD,2>,
									   <szDWORD,szDWORD,4>,
									   <szSDWORD,szSDWORD,4>,
									   <szDD,szDWORD,4>,
									   <szQWORD,szQWORD,8>,
									   <szDQ,szQWORD,8>,
									   <szTBYTE,szTBYTE,10>,
									   <szDT,szTBYTE,10>,
									   <0,0>)

szTestStruct1		db 'RECT struct',0Dh,0Ah
					db '	left		DWORD ?',0Dh,0Ah
					db '	top		DWORD ?',0Dh,0Ah
					db '	rignt		DWORD ?',0Dh,0Ah
					db '	bottom		DWORD ?',0Dh,0Ah
					db 'RECT ends',0Dh,0Ah,0

szTestStruct2		db 'TEST struct',0Dh,0Ah
					db '	rect		RECT <>',0Dh,0Ah
					db '	nmhdr		NMHDR <>',0Dh,0Ah
					db '	var1		DWORD ?',0Dh,0Ah
					db '	var2		DWORD ?',0Dh,0Ah
					db 'TEST ends',0Dh,0Ah,0

szTestStruct3		db 'TEST struct',0Dh,0Ah
					db '	rect		RECT <>',0Dh,0Ah
					db '	nmhdr		NMHDR <>',0Dh,0Ah
					db '	var1		DWORD ?',0Dh,0Ah
					db '	var2		DWORD ?',0Dh,0Ah
					db '	struct TST1',0Dh,0Ah
					db '		var1		DWORD ?',0Dh,0Ah
					db '		var2		DWORD ?',0Dh,0Ah
					db '	ends',0Dh,0Ah
					db '	struct TST2',0Dh,0Ah
					db '		var1		DWORD ?',0Dh,0Ah
					db '		var2		DWORD ?',0Dh,0Ah
					db '	ends',0Dh,0Ah
					db '	var3		DWORD ?',0Dh,0Ah
					db 'TEST ends',0Dh,0Ah,0

szTestStruct4		db 'TEST struct',0Dh,0Ah
					db '	var1		DWORD ?',0Dh,0Ah
					db '	var2		DWORD ?',0Dh,0Ah
					db '	union TST1',0Dh,0Ah
					db '		var1		DWORD ?',0Dh,0Ah
					db '		var2		WORD ?',0Dh,0Ah
					db '		var3		BYTE ?',0Dh,0Ah
					db '	ends',0Dh,0Ah
					db '	union TST2',0Dh,0Ah
					db '		var1		BYTE ?',0Dh,0Ah
					db '		var2		WORD ?',0Dh,0Ah
					db '		var3		DWORD ?',0Dh,0Ah
					db '	ends',0Dh,0Ah
					db '	var3		DWORD ?',0Dh,0Ah
					db 'TEST ends',0Dh,0Ah,0

;#########################################################################

.data?

hInstance			HINSTANCE ?
hMemStructSize		HGLOBAL ?
hMemTypeSize		HGLOBAL ?
hMemConstSize		HGLOBAL ?
hEditFont			HFONT ?
nSize				DWORD ?
szOutput			BYTE 16384 dub(?)

;#########################################################################
