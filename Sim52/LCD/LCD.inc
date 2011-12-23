
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

IDD_DLGLCD              equ 1000
IDC_LCD                 equ 1001
IDC_BTNEXPAND			equ 1013
IDC_STCERROR			equ 1014
IDC_CHKACTIVE			equ 1015
IDC_CHKBACKLIGHT        equ 1023
IDC_CBOD0               equ 1002
IDC_CBOD1               equ 1003
IDC_CBOD2               equ 1004
IDC_CBOD3               equ 1005
IDC_CBOD4               equ 1006
IDC_CBOD5               equ 1007
IDC_CBOD6               equ 1008
IDC_CBOD7               equ 1009
IDC_CBORS               equ 1010
IDC_CBORW               equ 1011
IDC_CBOE                equ 1012

GND						equ 0
VCC						equ 1
NC						equ 2

P0_0					equ 3
P0_1					equ 4
P0_2					equ 5
P0_3					equ 6
P0_4					equ 7
P0_5					equ 8
P0_6					equ 9
P0_7					equ 10

P1_0					equ 11
P1_1					equ 12
P1_2					equ 13
P1_3					equ 14
P1_4					equ 15
P1_5					equ 16
P1_6					equ 17
P1_7					equ 18

P2_0					equ 19
P2_1					equ 20
P2_2					equ 21
P2_3					equ 22
P2_4					equ 23
P2_5					equ 24
P2_6					equ 25
P2_7					equ 26

P3_0					equ 27
P3_1					equ 28
P3_2					equ 29
P3_3					equ 30
P3_4					equ 31
P3_5					equ 32
P3_6					equ 33
P3_7					equ 34

MMO0_0					equ 35
MMO0_1					equ 36
MMO0_2					equ 37
MMO0_3					equ 38
MMO0_4					equ 39
MMO0_5					equ 40
MMO0_6					equ 41
MMO0_7					equ 42

MMO1_0					equ 43
MMO1_1					equ 44
MMO1_2					equ 45
MMO1_3					equ 46
MMO1_4					equ 47
MMO1_5					equ 48
MMO1_6					equ 49
MMO1_7					equ 50

MMO2_0					equ 51
MMO2_1					equ 52
MMO2_2					equ 53
MMO2_3					equ 54
MMO2_4					equ 55
MMO2_5					equ 56
MMO2_6					equ 57
MMO2_7					equ 58

MMO3_0					equ 59
MMO3_1					equ 60
MMO3_2					equ 61
MMO3_3					equ 62
MMO3_4					equ 63
MMO3_5					equ 64
MMO3_6					equ 65
MMO3_7					equ 66

BITRS					equ 00100000000b
BITRW					equ 01000000000b
BITE					equ 10000000000b

LCDBIT struct
	port				DWORD ?
	portbit				DWORD ?
	lcdbit				DWORD ?
LCDBIT ends

.const

LCDClass				BYTE 'LCDCLASS',0

szPortBits				BYTE 'GND',0,'VCC',0,'NC',0
						BYTE 'P0.0',0,'P0.1',0,'P0.2',0,'P0.3',0,'P0.4',0,'P0.5',0,'P0.6',0,'P0.7',0
						BYTE 'P1.0',0,'P1.1',0,'P1.2',0,'P1.3',0,'P1.4',0,'P1.5',0,'P1.6',0,'P1.7',0
						BYTE 'P2.0',0,'P2.1',0,'P2.2',0,'P2.3',0,'P2.4',0,'P2.5',0,'P2.6',0,'P2.7',0
						BYTE 'P3.0',0,'P3.1',0,'P3.2',0,'P3.3',0,'P3.4',0,'P3.5',0,'P3.6',0,'P3.7',0
						BYTE 'MMO0.0',0,'MMO0.1',0,'MMO0.2',0,'MMO0.3',0,'MMO0.4',0,'MMO0.5',0,'MMO0.6',0,'MMO0.7',0
						BYTE 'MMO1.0',0,'MMO1.1',0,'MMO1.2',0,'MMO1.3',0,'MMO1.4',0,'MMO1.5',0,'MMO1.6',0,'MMO1.7',0
						BYTE 'MMO2.0',0,'MMO2.1',0,'MMO2.2',0,'MMO2.3',0,'MMO2.4',0,'MMO2.5',0,'MMO2.6',0,'MMO2.7',0
						BYTE 'MMO3.0',0,'MMO3.1',0,'MMO3.2',0,'MMO3.3',0,'MMO3.4',0,'MMO3.5',0,'MMO3.6',0,'MMO3.7',0,0

szMenuLCD				BYTE 'LCD Display',0
szExpand				BYTE '>',0
szShrink				BYTE '<',0
szError					BYTE 'Port not activated',0

szNULL					BYTE 0
szProLCD				BYTE 'LCD',0

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
