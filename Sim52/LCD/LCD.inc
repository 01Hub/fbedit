
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

.const

LCDClass				db 'LCDCLASS',0

szPortBits				db 'GND',0,'VCC',0,'NC',0
						db 'P0.0',0,'P0.1',0,'P0.2',0,'P0.3',0,'P0.4',0,'P0.5',0,'P0.6',0,'P0.7',0
						db 'P1.0',0,'P1.1',0,'P1.2',0,'P1.3',0,'P1.4',0,'P1.5',0,'P1.6',0,'P1.7',0
						db 'P2.0',0,'P2.1',0,'P2.2',0,'P2.3',0,'P2.4',0,'P2.5',0,'P2.6',0,'P2.7',0
						db 'P3.0',0,'P3.1',0,'P3.2',0,'P3.3',0,'P3.4',0,'P3.5',0,'P3.6',0,'P3.7',0,0

.data?

hDlg					HWND ?
hInstance				HINSTANCE ?
