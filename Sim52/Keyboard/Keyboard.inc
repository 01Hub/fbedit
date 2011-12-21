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

IDD_DLGKEYBOARD         equ 1000
IDC_BTN7                equ 1001
IDC_BTN8                equ 1002
IDC_BTN9                equ 1003
IDC_BTNADD              equ 1004
IDC_BTN4                equ 1005
IDC_BTN5                equ 1006
IDC_BTN6                equ 1007
IDC_BTNSUB              equ 1008
IDC_BTN1                equ 1009
IDC_BTN2                equ 1010
IDC_BTN3                equ 1011
IDC_BTNMUL              equ 1012
IDC_BTNCE               equ 1013
IDC_BTN0                equ 1014
IDC_BTNDOT              equ 1015
IDC_BTNDIV              equ 1016
IDC_BTNCONFIG           equ 1017
IDC_CBO0                equ 1018
IDC_CBO1                equ 1019
IDC_CBO2                equ 1020
IDC_CBO3                equ 1021
IDC_CBO4                equ 1022
IDC_CBO5                equ 1023
IDC_CBO6                equ 1024
IDC_CBO7                equ 1025
IDC_STCERROR			equ 1027
IDC_CHKACTIVE			equ 1028
IDC_EDTBUTTON			equ 1026
IDC_BTNSET				equ 1029

IDB_KEYBOARD			equ 100

WM_KDOWN				equ WM_USER+1
WM_KUP					equ WM_USER+2

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

MMO0_0					equ 32
MMO0_1					equ 33
MMO0_2					equ 34
MMO0_3					equ 35
MMO0_4					equ 36
MMO0_5					equ 37
MMO0_6					equ 38
MMO0_7					equ 39
MMO1_0					equ 40
MMO1_1					equ 41
MMO1_2					equ 42
MMO1_3					equ 43
MMO1_4					equ 44
MMO1_5					equ 45
MMO1_6					equ 46
MMO1_7					equ 47
MMO2_0					equ 48
MMO2_1					equ 49
MMO2_2					equ 50
MMO2_3					equ 51
MMO2_4					equ 52
MMO2_5					equ 53
MMO2_6					equ 54
MMO2_7					equ 55
MMO3_0					equ 56
MMO3_1					equ 57
MMO3_2					equ 58
MMO3_3					equ 59
MMO3_4					equ 60
MMO3_5					equ 61
MMO3_6					equ 62
MMO3_7					equ 63

MMI0_0					equ 32
MMI0_1					equ 33
MMI0_2					equ 34
MMI0_3					equ 35
MMI0_4					equ 36
MMI0_5					equ 37
MMI0_6					equ 38
MMI0_7					equ 39
MMI1_0					equ 40
MMI1_1					equ 41
MMI1_2					equ 42
MMI1_3					equ 43
MMI1_4					equ 44
MMI1_5					equ 45
MMI1_6					equ 46
MMI1_7					equ 47
MMI2_0					equ 48
MMI2_1					equ 49
MMI2_2					equ 50
MMI2_3					equ 51
MMI2_4					equ 52
MMI2_5					equ 53
MMI2_6					equ 54
MMI2_7					equ 55
MMI3_0					equ 56
MMI3_1					equ 57
MMI3_2					equ 58
MMI3_3					equ 59
MMI3_4					equ 60
MMI3_5					equ 61
MMI3_6					equ 62
MMI3_7					equ 63

KEY struct
	colport				DWORD ?
	colbit				DWORD ?
	rowport				DWORD ?
	rowbit				DWORD ?
KEY ends

.const

szPorts					BYTE 'P0.0',0,'P0.1',0,'P0.2',0,'P0.3',0,'P0.4',0,'P0.5',0,'P0.6',0,'P0.7',0
						BYTE 'P1.0',0,'P1.1',0,'P1.2',0,'P1.3',0,'P1.4',0,'P1.5',0,'P1.6',0,'P1.7',0
						BYTE 'P2.0',0,'P2.1',0,'P2.2',0,'P2.3',0,'P2.4',0,'P2.5',0,'P2.6',0,'P2.7',0
						BYTE 'P3.0',0,'P3.1',0,'P3.2',0,'P3.3',0,'P3.4',0,'P3.5',0,'P3.6',0,'P3.7',0,0

szMMIPorts				BYTE 'MMI0.0',0,'MMI0.1',0,'MMI0.2',0,'MMI0.3',0,'MMI0.4',0,'MMI0.5',0,'MMI0.6',0,'MMI0.7',0
						BYTE 'MMI1.0',0,'MMI1.1',0,'MMI1.2',0,'MMI1.3',0,'MMI1.4',0,'MMI1.5',0,'MMI1.6',0,'MMI1.7',0
						BYTE 'MMI2.0',0,'MMI2.1',0,'MMI2.2',0,'MMI2.3',0,'MMI2.4',0,'MMI2.5',0,'MMI2.6',0,'MMI2.7',0
						BYTE 'MMI3.0',0,'MMI3.1',0,'MMI3.2',0,'MMI3.3',0,'MMI3.4',0,'MMI3.5',0,'MMI3.6',0,'MMI3.7',0,0

szMMOPorts				BYTE 'MMO0.0',0,'MMO0.1',0,'MMO0.2',0,'MMO0.3',0,'MMO0.4',0,'MMO0.5',0,'MMO0.6',0,'MMO0.7',0
						BYTE 'MMO1.0',0,'MMO1.1',0,'MMO1.2',0,'MMO1.3',0,'MMO1.4',0,'MMO1.5',0,'MMO1.6',0,'MMO1.7',0
						BYTE 'MMO2.0',0,'MMO2.1',0,'MMO2.2',0,'MMO2.3',0,'MMO2.4',0,'MMO2.5',0,'MMO2.6',0,'MMO2.7',0
						BYTE 'MMO3.0',0,'MMO3.1',0,'MMO3.2',0,'MMO3.3',0,'MMO3.4',0,'MMO3.5',0,'MMO3.6',0,'MMO3.7',0,0

szMenuKeyboard			BYTE 'Keyboard',0

szDefButtonText			BYTE '7,8,9,+,4,5,6,-,1,2,3,*,CE/C,0,.,/',0
szExpand				BYTE '>',0
szShrink				BYTE '<',0
szNULL					BYTE 0
szError					BYTE 'Port not active',0

szProKeyboard			BYTE 'Keyboard',0
szProKeyboardText		BYTE 'Text',0

.data?

hInstance				HINSTANCE ?
hDlg					HWND ?
IDAddin					DWORD ?
lpAddin					DWORD ?
lpOldBtnProc			DWORD ?
fActive					DWORD ?
key						KEY 16 dup(<>)
keystate				DWORD ?
curkey					KEY <>
szButtonText			BYTE 256 dup(?)
