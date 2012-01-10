
include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib

;Debug
include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

include ..\Addin.inc
include CharTab.inc

IDD_DLGGLCD             equ 1000
IDC_UDCGLCD             equ 1009
IDC_BTNEXPAND			equ 1010
IDC_CBODATA				equ 1001
IDC_CBOCS               equ 1002
IDC_CBOCD               equ 1003
IDC_CBOR                equ 1004
IDC_CBOW                equ 1005
IDC_CBORST              equ 1006
IDC_CBOMD               equ 1007
IDC_CBOFS               equ 1008

IDC_CHKACTIVE			equ 1013
IDC_CHKBACKLIGHT        equ 1014

GND						equ 0
VCC						equ 1
P0_0					equ 2
P0_1					equ 3
P0_2					equ 4
P0_3					equ 5
P0_4					equ 6
P0_5					equ 7
P0_6					equ 8
P0_7					equ 9

P1_0					equ 10
P1_1					equ 11
P1_2					equ 12
P1_3					equ 13
P1_4					equ 14
P1_5					equ 15
P1_6					equ 16
P1_7					equ 17

P2_0					equ 18
P2_1					equ 19
P2_2					equ 20
P2_3					equ 21
P2_4					equ 22
P2_5					equ 23
P2_6					equ 24
P2_7					equ 25

P3_0					equ 26
P3_1					equ 27
P3_2					equ 28
P3_3					equ 29
P3_4					equ 30
P3_5					equ 31
P3_6					equ 32
P3_7					equ 33

GLCDBIT struct
	port				DWORD ?
	portbit				DWORD ?
	bitval				DWORD ?
	oldbitval			DWORD ?
GLCDBIT ends

.const

GLCDClass				BYTE 'GLCDCLASS',0

szPorts					BYTE 'P0',0,'P1',0,'P2',0,'P3',0,0

szPortBits				BYTE 'GND',0,'VCC',0
						BYTE 'P0.0',0,'P0.1',0,'P0.2',0,'P0.3',0,'P0.4',0,'P0.5',0,'P0.6',0,'P0.7',0
						BYTE 'P1.0',0,'P1.1',0,'P1.2',0,'P1.3',0,'P1.4',0,'P1.5',0,'P1.6',0,'P1.7',0
						BYTE 'P2.0',0,'P2.1',0,'P2.2',0,'P2.3',0,'P2.4',0,'P2.5',0,'P2.6',0,'P2.7',0
						BYTE 'P3.0',0,'P3.1',0,'P3.2',0,'P3.3',0,'P3.4',0,'P3.5',0,'P3.6',0,'P3.7',0,0

GLCDBIT_CS				equ sizeof GLCDBIT*0
GLCDBIT_CD				equ sizeof GLCDBIT*1
GLCDBIT_R				equ sizeof GLCDBIT*2
GLCDBIT_W				equ sizeof GLCDBIT*3
GLCDBIT_RST				equ sizeof GLCDBIT*4
GLCDBIT_MD				equ sizeof GLCDBIT*5
GLCDBIT_FS				equ sizeof GLCDBIT*6

szMenuGLCD				BYTE 'Grapic LCD Display',0
szExpand				BYTE '>',0
szShrink				BYTE '<',0

szNULL					BYTE 0
szProGLCD				BYTE 'GLCD',0

.data?

hInstance				HINSTANCE ?
hDlg					HWND ?
hLcd					HWND ?
hDotBrush				HBRUSH ?
hBackBrush				HBRUSH ?
mDC						HDC ?
hBmp					HBITMAP ?
lpAddin					DWORD ?
IDAddin					DWORD ?
BackLight				DWORD ?
fActive					DWORD ?

P0Bits					DWORD ?				;Each bit used by LCD is 1
P1Bits					DWORD ?				;Each bit used by LCD is 1
P2Bits					DWORD ?				;Each bit used by LCD is 1
P3Bits					DWORD ?				;Each bit used by LCD is 1
dataport				DWORD ?
lcddata1				DWORD ?
lcddata2				DWORD ?
lcdcmnd					DWORD ?

lcdbit					GLCDBIT 7 dup(<>)	;What port bit the GLCD bit is connected to

LCDDDRAMADDR			DWORD ?
LCDCGRAMADDR			DWORD ?
