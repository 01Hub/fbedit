
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

P0_0					equ 0
P0_1					equ 1
P0_2					equ 2
P0_3					equ 3
P0_4					equ 4
P0_5					equ 5
P0_6					equ 6
P0_7					equ 7

P1_0					equ 8
P1_1					equ 9
P1_2					equ 10
P1_3					equ 11
P1_4					equ 12
P1_5					equ 13
P1_6					equ 14
P1_7					equ 15

P2_0					equ 16
P2_1					equ 17
P2_2					equ 18
P2_3					equ 19
P2_4					equ 20
P2_5					equ 21
P2_6					equ 22
P2_7					equ 23

P3_0					equ 24
P3_1					equ 25
P3_2					equ 26
P3_3					equ 27
P3_4					equ 28
P3_5					equ 29
P3_6					equ 30
P3_7					equ 31

BITRS					equ 00100000000b
BITRW					equ 01000000000b
BITE					equ 10000000000b

LCDBIT struct
	port				DWORD ?
	portbit				DWORD ?
	lcdbit				DWORD ?
LCDBIT ends

.const

GLCDClass				BYTE 'GLCDCLASS',0

szPorts					BYTE 'P0',0,'P1',0,'P2',0,'P3',0,0

szPortBits				BYTE 'P0.0',0,'P0.1',0,'P0.2',0,'P0.3',0,'P0.4',0,'P0.5',0,'P0.6',0,'P0.7',0
						BYTE 'P1.0',0,'P1.1',0,'P1.2',0,'P1.3',0,'P1.4',0,'P1.5',0,'P1.6',0,'P1.7',0
						BYTE 'P2.0',0,'P2.1',0,'P2.2',0,'P2.3',0,'P2.4',0,'P2.5',0,'P2.6',0,'P2.7',0
						BYTE 'P3.0',0,'P3.1',0,'P3.2',0,'P3.3',0,'P3.4',0,'P3.5',0,'P3.6',0,'P3.7',0,0

szMenuGLCD				BYTE 'Grapic LCD Display',0
szExpand				BYTE '>',0
szShrink				BYTE '<',0
szError					BYTE 'Port not activated',0

szNULL					BYTE 0
szProGLCD				BYTE 'GLCD',0

.data?

hInstance				HINSTANCE ?
hDlg					HWND ?
hLcd					HWND ?
lpOldEditProc			DWORD ?
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
MMBits					DWORD 4 dup(?)		;Each bit used by LCD is 1
MMAddr					DWORD 4 dup(?)		;Memory mapped output port address

lcdbit					LCDBIT 8+3 dup(<>)	;What port or MM bit the LCD bit is connected to
LCDDB					DWORD ?				;H=8, L=4 databits
LCDDL					DWORD ?				;H=2, L=1 displaylines
LCDF					DWORD ?				;H=5x11, L=5x8 font
LCDCG					DWORD ?				;H=CGRAM. L=DDRAM
LCDCD					DWORD ?				;H=Inc, L=Dec cursor direction
LCDDSON					DWORD ?				;H=On, l=Off display shift
LCDDON					DWORD ?				;H=On, l=Off display on/off
LCDCON					DWORD ?				;H=On, l=Off cursor on/off
LCDCPON					DWORD ?				;H=On, l=Off cursor position on/off
LCDDSD					DWORD ?				;H=Right, L=Left display shift direction

LCDDDRAMADDR			DWORD ?
LCDCGRAMADDR			DWORD ?

LCDNIBBLE				DWORD ?
LCDData					DWORD ?
LCDNibbleData			DWORD ?
LCDCGRAM				BYTE 64 dup(?)
LCDDDRAM				BYTE 128 dup(?)
