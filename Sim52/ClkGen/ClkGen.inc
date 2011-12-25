
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

IDD_DLGCLKGEN           equ 1000
IDC_EDTFREQUENCY        equ 1001
IDC_CHKACTIVE           equ 1002
IDC_BTNEXPAND           equ 1004
IDC_STCDIVISOR          equ 1005
IDC_CBOOUT              equ 1006

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
MMI0_0					equ 33
MMI0_1					equ 34
MMI0_2					equ 35
MMI0_3					equ 36
MMI0_4					equ 37
MMI0_5					equ 38
MMI0_6					equ 39
MMI0_7					equ 40
MMI1_0					equ 41
MMI1_1					equ 42
MMI1_2					equ 43
MMI1_3					equ 44
MMI1_4					equ 45
MMI1_5					equ 46
MMI1_6					equ 47
MMI1_7					equ 48
MMI2_0					equ 49
MMI2_1					equ 50
MMI2_2					equ 51
MMI2_3					equ 52
MMI2_4					equ 53
MMI2_5					equ 54
MMI2_6					equ 55
MMI2_7					equ 56
MMI3_0					equ 57
MMI3_1					equ 58
MMI3_2					equ 59
MMI3_3					equ 60
MMI3_4					equ 61
MMI3_5					equ 62
MMI3_6					equ 63
MMI3_7					equ 64

.const

szPortBits				BYTE 'NC',0
						BYTE 'P0.0',0,'P0.1',0,'P0.2',0,'P0.3',0,'P0.4',0,'P0.5',0,'P0.6',0,'P0.7',0
						BYTE 'P1.0',0,'P1.1',0,'P1.2',0,'P1.3',0,'P1.4',0,'P1.5',0,'P1.6',0,'P1.7',0
						BYTE 'P2.0',0,'P2.1',0,'P2.2',0,'P2.3',0,'P2.4',0,'P2.5',0,'P2.6',0,'P2.7',0
						BYTE 'P3.0',0,'P3.1',0,'P3.2',0,'P3.3',0,'P3.4',0,'P3.5',0,'P3.6',0,'P3.7',0
						BYTE 'MMI0.0',0,'MMI0.1',0,'MMI0.2',0,'MMI0.3',0,'MMI0.4',0,'MMI0.5',0,'MMI0.6',0,'MMI0.7',0
						BYTE 'MMI1.0',0,'MMI1.1',0,'MMI1.2',0,'MMI1.3',0,'MMI1.4',0,'MMI1.5',0,'MMI1.6',0,'MMI1.7',0
						BYTE 'MMI2.0',0,'MMI2.1',0,'MMI2.2',0,'MMI2.3',0,'MMI2.4',0,'MMI2.5',0,'MMI2.6',0,'MMI2.7',0
						BYTE 'MMI3.0',0,'MMI3.1',0,'MMI3.2',0,'MMI3.3',0,'MMI3.4',0,'MMI3.5',0,'MMI3.6',0,'MMI3.7',0,0

szMenuClkGen			BYTE 'Clock Generator',0
szExpand				BYTE '>',0
szShrink				BYTE '<',0

szNULL					BYTE 0
szProClkGen				BYTE 'ClkGen',0
szFmtDiv				BYTE '/%u',0

.data?

hInstance				HINSTANCE ?
hDlg					HWND ?
fActive					DWORD ?
lpAddin					DWORD ?
IDAddin					DWORD ?
Frequency				DWORD ?
Divisor					DWORD ?
portbit					DWORD ?
portaddr				DWORD ?
hThread					HANDLE ?
fExitThread				DWORD ?
