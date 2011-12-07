
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
IDC_CHKBACKLIGHT        equ 1023
IDC_BTNEXPAND			equ 1013

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

.const

LCDClass				db 'LCDCLASS',0

szPortBits				db 'GND',0,'VCC',0,'NC',0
						db 'P0.0',0,'P0.1',0,'P0.2',0,'P0.3',0,'P0.4',0,'P0.5',0,'P0.6',0,'P0.7',0
						db 'P1.0',0,'P1.1',0,'P1.2',0,'P1.3',0,'P1.4',0,'P1.5',0,'P1.6',0,'P1.7',0
						db 'P2.0',0,'P2.1',0,'P2.2',0,'P2.3',0,'P2.4',0,'P2.5',0,'P2.6',0,'P2.7',0
						db 'P3.0',0,'P3.1',0,'P3.2',0,'P3.3',0,'P3.4',0,'P3.5',0,'P3.6',0,'P3.7',0,0

szMenuLCD				db 'LCD Display',0
szExpand				db '>',0
szShrink				db '<',0

.data?

hDlg					HWND ?
hInstance				HINSTANCE ?
databits				DWORD ?
lpAddin					DWORD ?
P0Bits					DWORD ?
P1Bits					DWORD ?
P2Bits					DWORD ?
P3Bits					DWORD ?
DB0						DWORD ?
DB1						DWORD ?
DB2						DWORD ?
DB3						DWORD ?
DB4						DWORD ?
DB5						DWORD ?
DB6						DWORD ?
DB7						DWORD ?
RS						DWORD ?
RW						DWORD ?
E						DWORD ?
IDAddin					DWORD ?
BackLight				DWORD ?
LCDLine1				BYTE 40 dup(?)
LCDLine2				BYTE 40 dup(?)
