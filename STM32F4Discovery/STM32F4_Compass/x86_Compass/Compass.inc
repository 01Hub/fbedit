
include	windows.inc
include	kernel32.inc
include	user32.inc
include	comctl32.inc
include gdi32.inc

includelib kernel32.lib
includelib user32.lib
includelib comctl32.lib
includelib gdi32.lib

includelib STLinkLib.lib

STLinkConnect					PROTO hWin:HWND
STLinkDisconnect				PROTO hWin:HWND
STLinkRead 						PROTO hWin:HWND,rdadr:DWORD,wradr:DWORD,nBytes:DWORD
STLinkWrite						PROTO hWin:HWND,wradr:DWORD,rdadr:DWORD,nBytes:DWORD

;#########################################################################
;VKim's Debug

include masm32.inc
include \RadASM30\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM30\masm\lib\debug.lib

;#########################################################################

IDD_MAIN						equ 101
IDC_STC1						equ 102
IDC_STC2						equ 103
IDC_STC3						equ 104
IDC_STC4						equ 106
IDC_UDCCOMPASS					equ 105
IDC_BTNCOMP						equ 107
IDC_BTNCALIBRATE				equ 108
IDC_EDTRESULT					equ 109
IDC_BTNSAVE						equ 110
IDC_EDTDEC						equ 111
IDC_STC5						equ 112
IDC_STC6						equ 113
IDC_STC7						equ 114
IDC_RBN1						equ 115
IDC_RBN2						equ 116
IDC_RBN3						equ 117
IDC_RBN4						equ 118
IDC_BTNMINMAXX					equ 119
IDC_BTNMINMAXY					equ 120
IDC_BTNMINMAXZ					equ 121
IDC_CHKTILT						equ 122
IDC_STCMAGMINMAX				equ 123
IDC_STCACLMINMAX				equ 124

MODE_NORMAL						equ 1	; Normal operation
MODE_COMPENSATE					equ 2	; Get compass temprature compensation
MODE_CALIBRATE					equ 3	; Get compass calibration
MODE_COMPENSATEOFF				equ 4	; End compass temprature compensation
MODE_MINMAXX					equ 9
MODE_MINMAXY					equ 17
MODE_MINMAXZ					equ 33

STM32_ADDRESS					equ 20000028h

COMPASS struct
	flag	WORD ?
	x		WORD ?
	y		WORD ?
	z		WORD ?
	buffer	BYTE 6 dup(?)
	delay	WORD ?
	ideg	DWORD ?

	tcxrt	DWORD ?
	tcyrt	DWORD ?
	tczrt	DWORD ?
	tcxct	DWORD ?
	tcyct	DWORD ?
	tczct	DWORD ?

	mminx	DWORD ?
	mmaxx	DWORD ?
	xscale	DWORD ?
	mminy	DWORD ?
	mmaxy	DWORD ?
	yscale	DWORD ?
	mminz	DWORD ?
	mmaxz	DWORD ?
	zscale	DWORD ?

	declin	DWORD ?
	ftilt	DWORD ?
	aminx	DWORD ?
	amaxx	DWORD ?
	aminy	DWORD ?
	amaxy	DWORD ?
	aminz	DWORD ?
	amaxz	DWORD ?
	pitch	REAL8 ?
	roll	REAL8 ?
	ipitch	DWORD ?
	iroll	DWORD ?
COMPASS ends

COMPENSATION struct
	x		DWORD ?
	y		DWORD ?
	z		DWORD ?
COMPENSATION ends

CALIBRATION struct
	x		WORD ?
	y		WORD ?
CALIBRATION ends

MAGREAD struct
	x		WORD ?
	y		WORD ?
	z		WORD ?
	dmy		WORD ?
MAGREAD ends

ACLREAD struct
	x		WORD ?
	y		WORD ?
	z		WORD ?
	dmy		WORD ?
ACLREAD ends

.const

Tahoma_72						LOGFONT <-30,0,0,0,400,0,0,0,0,3,2,1,34,"Tahoma">

szCOMPASSCLASS					BYTE 'UDCOMPASS',0

szNorth							BYTE 'N',0
szSouth							BYTE 'S',0
szEast							BYTE 'E',0
szWest							BYTE 'W',0
magxAxis						BYTE 'magX',0
magyAxis						BYTE 'magY',0
magzAxis						BYTE 'magZ',0

aclxAxis						BYTE 'aclX',0
aclyAxis						BYTE 'aclY',0
aclzAxis						BYTE 'aclZ',0

szFmtAxis						BYTE '%s = %d',0
szFmtCompensate					BYTE 'Temprature compensation:',0Dh,0Ah
								BYTE 'X = %d',0Dh,0Ah
								BYTE 'Y = %d',0Dh,0Ah
								BYTE 'Z = %d',0Dh,0Ah,0
szFmpCalibrate					BYTE 'Offset calibration',0Dh,0Ah
								BYTE 'mX-Min %d, mX-Max %d, mScale %d',0Dh,0Ah
								BYTE 'mY-Min %d, mY-Max %d, mScale %d',0Dh,0Ah,0

szFmtaXCalibrate				BYTE 'Accelerometer calibration',0Dh,0Ah
								BYTE 'aX-Min %d, aX-Max %d',0Dh,0Ah,0
szFmtaYCalibrate				BYTE 'Accelerometer calibration',0Dh,0Ah
								BYTE 'aY-Min %d, aY-Max %d',0Dh,0Ah,0
szFmtaZCalibrate				BYTE 'Accelerometer calibration',0Dh,0Ah
								BYTE 'aZ-Min %d, aZ-Max %d',0Dh,0Ah,0

szFmtMinMax						BYTE '%d / %d',0

rad2deg							REAL8 57.29577951308232088
deg2rad							REAL8 0.017453292519943334

szIniFile						BYTE '\Compass.ini',0
szIniCompass					BYTE 'Compass',0

;#########################################################################

.data?

hInstance						HINSTANCE ?
wc								WNDCLASSEX <>
hWnd							HWND ?
hCompass						HWND ?
hFont							HFONT ?
connected						DWORD ?
mode							DWORD ?
compass							COMPASS <>
calinx							DWORD ?
calibration						CALIBRATION 1024 dup(<>)
countdown						DWORD ?
IniFile							BYTE MAX_PATH dup(?)
ShowMode						DWORD ?
readinx							DWORD ?
magread							MAGREAD 8 dup(<>)
aclread							ACLREAD 8 dup(<>)

;#########################################################################
