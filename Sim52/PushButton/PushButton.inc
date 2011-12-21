

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

IDD_DLGPB               equ 1000
IDC_STCPB0              equ 1010
IDC_BTNPB0              equ 1000
IDC_STCPB1              equ 1011
IDC_BTNPB1              equ 1001
IDC_STCPB2              equ 1012
IDC_BTNPB2              equ 1002
IDC_STCPB3              equ 1013
IDC_BTNPB3              equ 1003
IDC_STCPB4              equ 1014
IDC_BTNPB4              equ 1004
IDC_STCPB5              equ 1015
IDC_BTNPB5              equ 1005
IDC_STCPB6              equ 1016
IDC_BTNPB6              equ 1006
IDC_STCPB7              equ 1017
IDC_BTNPB7              equ 1007
IDC_BTNCONFIG           equ 1008
IDC_UDNBUTTONS			equ 1009
IDC_CHKPB0              equ 1020
IDC_CHKPB1              equ 1021
IDC_CHKPB2              equ 1022
IDC_CHKPB3              equ 1023
IDC_CHKPB4              equ 1024
IDC_CHKPB5              equ 1025
IDC_CHKPB6              equ 1026
IDC_CHKPB7              equ 1027
IDC_EDTPB0              equ 1030
IDC_EDTPB1              equ 1031
IDC_EDTPB2              equ 1032
IDC_EDTPB3              equ 1033
IDC_EDTPB4              equ 1034
IDC_EDTPB5              equ 1035
IDC_EDTPB6              equ 1036
IDC_EDTPB7              equ 1037
IDC_CBOTPB0             equ 1050
IDC_CBOBPB0             equ 1060
IDC_CBOTPB1             equ 1051
IDC_CBOBPB1             equ 1061
IDC_CBOTPB2             equ 1052
IDC_CBOBPB2             equ 1062
IDC_CBOTPB3             equ 1053
IDC_CBOBPB3             equ 1063
IDC_CBOTPB4             equ 1054
IDC_CBOBPB4             equ 1064
IDC_CBOTPB5             equ 1055
IDC_CBOBPB5             equ 1065
IDC_CBOTPB6             equ 1056
IDC_CBOBPB6             equ 1066
IDC_CBOTPB7             equ 1057
IDC_CBOBPB7             equ 1067
IDC_IMGPB0              equ 1070
IDC_IMGPB1              equ 1071
IDC_IMGPB2              equ 1072
IDC_IMGPB3              equ 1073
IDC_IMGPB4              equ 1074
IDC_IMGPB5              equ 1075
IDC_IMGPB6              equ 1076
IDC_IMGPB7              equ 1077
IDC_GRPPB				equ 1100
IDB_SWITCHOPEN          equ 100
IDB_PUSHBUTTON          equ 102
IDB_SWITCHCLOSED        equ 101

WM_PBDOWN				equ WM_USER+1
WM_PBUP					equ WM_USER+2

NC						equ 0
GND						equ 1
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

szPBLow					db 'NC',0,'GND',0,0
szPBHigh				db 'NC',0
						db 'P0.0',0,'P0.1',0,'P0.2',0,'P0.3',0,'P0.4',0,'P0.5',0,'P0.6',0,'P0.7',0
						db 'P1.0',0,'P1.1',0,'P1.2',0,'P1.3',0,'P1.4',0,'P1.5',0,'P1.6',0,'P1.7',0
						db 'P2.0',0,'P2.1',0,'P2.2',0,'P2.3',0,'P2.4',0,'P2.5',0,'P2.6',0,'P2.7',0
						db 'P3.0',0,'P3.1',0,'P3.2',0,'P3.3',0,'P3.4',0,'P3.5',0,'P3.6',0,'P3.7',0
						db 'MMI0.0',0,'MMI0.1',0,'MMI0.2',0,'MMI0.3',0,'MMI0.4',0,'MMI0.5',0,'MMI0.6',0,'MMI0.7',0
						db 'MMI1.0',0,'MMI1.1',0,'MMI1.2',0,'MMI1.3',0,'MMI1.4',0,'MMI1.5',0,'MMI1.6',0,'MMI1.7',0
						db 'MMI2.0',0,'MMI2.1',0,'MMI2.2',0,'MMI2.3',0,'MMI2.4',0,'MMI2.5',0,'MMI2.6',0,'MMI2.7',0
						db 'MMI3.0',0,'MMI3.1',0,'MMI3.2',0,'MMI3.3',0,'MMI3.4',0,'MMI3.5',0,'MMI3.6',0,'MMI3.7',0,0

szMenuPB				db 'Push Buttons',0
szExpand				db '>',0
szShrink				db '<',0
szNULL					db 0
szProPB					db 'PB',0
szDefLabel				db 'PB0',0,'PB1',0,'PB2',0,'PB3',0,'PB4',0,'PB5',0,'PB6',0,'PB7',0

.data?

hInstance				HINSTANCE ?
hDlg					HWND ?
IDAddin					DWORD ?
lpAddin					DWORD ?
hBmpPushButton			HBITMAP ?
hBmpSwitchOpen			HBITMAP ?
hBmpSwitchClosed		HBITMAP ?
lpOldBtnProc			DWORD ?
nButtons				DWORD ?
