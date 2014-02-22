
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
IDC_FREQUENCY					equ 102
IDC_LCMETER						equ 103

STM32_FRQ struct
	Frequency					DWORD ?			;0x20000018
	PreviousCount				DWORD ?			;0x2000001C
	ThisCount					DWORD ?			;0x20000020
	TickCount					DWORD ?			;0x20000024
STM32_FRQ ends

STM32_LCM struct
	FrequencyCal0				DWORD ?			;0x20000028
	FrequencyCal1				DWORD ?			;0x2000002C
STM32_LCM ends

STM32_CMD struct
	Cmd							DWORD ?			;0x20000014
	STM32_Frq 					STM32_FRQ <>	;0x20000018
	STM32_Lcm					STM32_LCM <>	;0x20000028
STM32_CMD ends

FP_EQUALTO						equ	40h

.const

szFREQUENCYCLASS				BYTE 'FREQUENCYCLASS',0
Tahoma_36						LOGFONT <-36,0,0,0,400,0,0,0,0,3,2,1,34,"Tahoma">
szFmtHz							BYTE '%dHz',0
szFmtKHz						BYTE '%dKHz',0
szFmtMHz						BYTE '%dMHz',0
szPF							BYTE 'pF',0
szNF							BYTE 'nF',0
szUF							BYTE 'uF',0

CCal							REAL8 1.0e-9

ten16							REAL8 1.0e16
ten								REAL8 10.0
ten_1							TBYTE 1.0e1
								TBYTE 1.0e2
								TBYTE 1.0e3
								TBYTE 1.0e4
								TBYTE 1.0e5
ten_6							TBYTE 1.0e6
								TBYTE 1.0e7
								TBYTE 1.0e8
ten_9							TBYTE 1.0e9
								TBYTE 1.0e10
								TBYTE 1.0e11
ten_12							TBYTE 1.0e12
								TBYTE 1.0e13
								TBYTE 1.0e14
								TBYTE 1.0e15
ten_16							TBYTE 1.0e16
								TBYTE 1.0e32
								TBYTE 1.0e48
								TBYTE 1.0e64
								TBYTE 1.0e80
								TBYTE 1.0e96
								TBYTE 1.0e112
								TBYTE 1.0e128
								TBYTE 1.0e144
								TBYTE 1.0e160
								TBYTE 1.0e176
								TBYTE 1.0e192
								TBYTE 1.0e208
								TBYTE 1.0e224
								TBYTE 1.0e240
ten_256							TBYTE 1.0e256
								TBYTE 1.0e512
								TBYTE 1.0e768
								TBYTE 1.0e1024
								TBYTE 1.0e1280
								TBYTE 1.0e1536
								TBYTE 1.0e1792
								TBYTE 1.0e2048
								TBYTE 1.0e2304
								TBYTE 1.0e2560
								TBYTE 1.0e2816
								TBYTE 1.0e3072
								TBYTE 1.0e3328
								TBYTE 1.0e3584
								TBYTE 1.0e4096
								TBYTE 1.0e4352
								TBYTE 1.0e4608
								TBYTE 1.0e4864

;#########################################################################

.data?

hInstance						HINSTANCE ?
wc								WNDCLASSEX <>
hWnd							HWND ?
hFont							HFONT ?
connected						DWORD ?
STM32_Cmd						STM32_CMD <>
LCx								REAL10 ?

;#########################################################################
