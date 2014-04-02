
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

;include masm32.inc
;include Debug.Inc
;includelib masm32.lib
;includelib Debug.lib

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

MODE_NORMAL						equ 1	; Normal operation
MODE_COMPENSATE					equ 2	; Get temprature compensation
MODE_CALIBRATE					equ 3	; Get calibration

COMPASS struct
	flag	WORD ?
	x		WORD ?
	y		WORD ?
	z		WORD ?
	count	DWORD ?
	ideg	DWORD ?
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

.const

Tahoma_72						LOGFONT <-30,0,0,0,400,0,0,0,0,3,2,1,34,"Tahoma">

szCOMPASSCLASS					BYTE 'UDCOMPASS',0

xAxis							BYTE 'X',0
yAxis							BYTE 'Y',0
zAxis							BYTE 'Z',0
szNULL							BYTE 0

szFmtAxis						BYTE '%s = %d',0
rad2deg							REAL8 57.29577951308232088
deg2rad							REAL8 0.017453292519943334

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

;#########################################################################
