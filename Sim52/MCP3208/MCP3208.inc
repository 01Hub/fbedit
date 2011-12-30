
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

IDD_DLGMCP3208          equ 1000
IDC_TRBCH0              equ 1001
IDC_TRBCH1              equ 1002
IDC_TRBCH2              equ 1003
IDC_TRBCH3              equ 1004
IDC_TRBCH4              equ 1005
IDC_TRBCH5              equ 1006
IDC_TRBCH6              equ 1007
IDC_TRBCH7              equ 1008
IDC_BTNEXPAND           equ 1009
IDC_CHKACTIVE           equ 1010
IDC_CBOCS               equ 1011
IDC_CBOCLK              equ 1012
IDC_CBODIN              equ 1013
IDC_CBODOUT             equ 1014
IDC_TRBVREF				equ 1015

NC						equ 0
P0_0					equ 1
P0_1					equ 2
P0_2					equ 3
P0_3					equ 4
P0_4					equ 5
P0_5					equ 6
P0_6					equ 7
P0_7					equ 8
P1_0					equ 9
P1_1					equ 10
P1_2					equ 11
P1_3					equ 12
P1_4					equ 13
P1_5					equ 14
P1_6					equ 15
P1_7					equ 16
P2_0					equ 17
P2_1					equ 18
P2_2					equ 19
P2_3					equ 20
P2_4					equ 21
P2_5					equ 22
P2_6					equ 23
P2_7					equ 24
P3_0					equ 25
P3_1					equ 26
P3_2					equ 27
P3_3					equ 28
P3_4					equ 29
P3_5					equ 30
P3_6					equ 31
P3_7					equ 32

PORTBIT struct
	portadr				DWORD ?
	portbit				DWORD ?
	bitval				DWORD ?
PORTBIT ends

PORTBIT_CS				equ 0*sizeof PORTBIT
PORTBIT_CLK				equ 1*sizeof PORTBIT
PORTBIT_DIN				equ 2*sizeof PORTBIT
PORTBIT_DOUT			equ 3*sizeof PORTBIT

.const

szMenuMCP3208			BYTE 'MCP3208 ADC',0

szPortBits				BYTE 'NC',0
						BYTE 'P0.0',0,'P0.1',0,'P0.2',0,'P0.3',0,'P0.4',0,'P0.5',0,'P0.6',0,'P0.7',0
						BYTE 'P1.0',0,'P1.1',0,'P1.2',0,'P1.3',0,'P1.4',0,'P1.5',0,'P1.6',0,'P1.7',0
						BYTE 'P2.0',0,'P2.1',0,'P2.2',0,'P2.3',0,'P2.4',0,'P2.5',0,'P2.6',0,'P2.7',0
						BYTE 'P3.0',0,'P3.1',0,'P3.2',0,'P3.3',0,'P3.4',0,'P3.5',0,'P3.6',0,'P3.7',0,0

szExpand				BYTE '>',0
szShrink				BYTE '<',0

szNULL					BYTE 0
szProMCP3208			BYTE 'MCP3209',0

.data?

hInstance				HINSTANCE ?
hDlg					HWND ?
fActive					DWORD ?
lpAddin					DWORD ?
IDAddin					DWORD ?
portbit					PORTBIT 4 dup(<>)		;Port configurations
CHValue					DWORD 8 dup(?)			;CH0 to CH7 values
VREFValue				DWORD ?					;VREF value
fCLKTransition			DWORD ?					;TRUE if a high to low transition on CLK
nStarted				DWORD ?					;Progress counter
nChannel				DWORD ?					;Selected channel (0 to 7)
nMode					DWORD ?					;Mode FALSE=Differential, TRUE=Single ended input mode
ADCVal					DWORD ?					;Shift out register
