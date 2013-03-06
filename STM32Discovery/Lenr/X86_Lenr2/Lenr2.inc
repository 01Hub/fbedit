include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include gdi32.inc
include comctl32.inc
include comdlg32.inc

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib gdi32.lib
includelib comctl32.lib
includelib comdlg32.lib

;#########################################################################
;VKim's Debug

include masm32.inc
include \RadASM30\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM30\masm\lib\debug.lib

;#########################################################################

includelib STLinkLib.lib

STLinkConnect		PROTO hWin:HWND
STLinkDisconnect	PROTO hWin:HWND
STLinkRead 			PROTO hWin:HWND,rdadr:DWORD,wradr:DWORD,nBytes:DWORD
STLinkWrite			PROTO hWin:HWND,wradr:DWORD,rdadr:DWORD,nBytes:DWORD

GRPWDT				equ 864*4
GRPXST				equ 72*4
GRPXPS				equ 30
GRPHGT				equ 500
GRPYST				equ 50
GRPYPS				equ 30
AVGCOUNT			equ 50

IDD_DIALOG			equ 1000
IDC_GRAPH			equ 1001
IDC_RBNVOLTAGE      equ 1002
IDC_RBNCURRENT      equ 1003
IDC_RBNPOWER        equ 1004
IDC_RBNCELL         equ 1005
IDC_RBNAMB          equ 1006
IDC_DISPLAY			equ 1021
IDC_STCAMBTEMP      equ 1018
IDC_EDTAMBTEMP      equ 1019
IDC_UDNAMBTEMP      equ 1020
IDC_UDNOFS			equ 1022
IDC_STCCELLTEMP     equ 1023
IDC_EDTCELLTEMP     equ 1024
IDC_UDNCELLTEMP     equ 1025
IDC_UDNPWM3			equ 1026
IDC_UDNPWM4			equ 1027
IDC_UDNPWM1MAX      equ 1028
IDC_EDTPWM1MAX      equ 1029
IDC_STCPWM1MAX      equ 1030
IDC_UDNPWM2MAX      equ 1031
IDC_EDTPWM2MAX      equ 1032
IDC_STCPWM2MAX      equ 1033

IDM_MENU			equ 10000
IDM_FILE_OPEN       equ 10002
IDM_FILE_CLOSE      equ 10003
IDM_FILE_SAVE       equ 10004
IDM_FILE_EXIT		equ 10001
IDM_HELP_ABOUT		equ 10101

LOG struct
	Volt			WORD ?
	Amp				WORD ?
	Temp1			WORD ?
	Temp2			WORD ?
LOG ends

LENR struct
	SecCount		DWORD ?
	Pwm1			WORD ?
	Pwm2			WORD ?
	Pwm3			WORD ?
	Pwm4			WORD ?
	log				LOG AVGCOUNT dup(<>)
LENR ends

.const

szMainClass			BYTE 'MAINCLASS',0
szGraphClass		BYTE 'GRAPHCLASS',0
szDisplayClass		BYTE 'DISPLAYCLASS',0

AppName				BYTE 'Dialog as main',0
AboutMsg			BYTE 'MASM32 RadASM Dialog as main',13,10,'Copyright © MASM32 2001',0

szTime				BYTE '00:00',0,'01:00',0,'02:00',0,'03:00',0,'04:00',0,'05:00',0,'06:00',0,'07:00',0,'08:00',0,'09:00',0,'10:00',0,'11:00',0
					BYTE '12:00',0,'13:00',0,'14:00',0,'15:00',0,'16:00',0,'17:00',0,'18:00',0,'19:00',0,'20:00',0,'21:00',0,'22:00',0,'23:00',0,'24:00',0,0
szVolt				BYTE 'Voltage',0,' 20',0,' 18',0,' 16',0,' 14',0,' 12',0,' 10',0,'  8',0,'  6',0,'  4',0,'  2',0,'  0',0,0
szAmp				BYTE 'Current',0,'5.0',0,'4.5',0,'4.0',0,'3.5',0,'3.0',0,'2.5',0,'2.0',0,'1.5',0,'1.0',0,'0.5',0,'  0',0,0
szPower				BYTE 'Power',0,'100',0,' 90',0,' 80',0,' 70',0,' 60',0,' 50',0,' 40',0,' 30',0,' 20',0,' 10',0,'  0',0,0
szTempAmbient		BYTE 'Temprature',0,' 40',0,' 36',0,' 32',0,' 28',0,' 24',0,' 20',0,' 16',0,' 12',0,'  8',0,'  4',0,'  0',0,0
szTempCell			BYTE 'Temprature',0,'100',0,' 90',0,' 80',0,' 70',0,' 60',0,' 50',0,' 40',0,' 30',0,' 20',0,' 10',0,'  0',0,0
szTempHeater		BYTE 'Temprature',0,'400',0,'360',0,'320',0,'280',0,'240',0,'200',0,'160',0,'120',0,' 80',0,' 40',0,'  0',0,0

Tahoma_36			LOGFONT <-36,0,0,0,400,0,0,0,0,3,2,1,34,"Tahoma">

szFmtVolt			BYTE '%.3dV',0
szFmtAmp			BYTE '%.3dA',0
szFmtPower			BYTE '%.3dW',0
szFmtTemp			BYTE '%.3dC',0
szFmtPwm1			BYTE 'PWM1: %d',0
szFmtPwm2			BYTE 'PWM2: %d',0
szFmtPwm3			BYTE 'PWM3: %d',0
szFmtPwm4			BYTE 'PWM4: %d',0
szFmtFile			BYTE '%s\Log\Lenr%.4d%.2d%.2d.dat',0

szLOGFilterString	BYTE 'DATA Files (*.dat)',0,'*.dat',0,0

.data?

hInstance			HINSTANCE ?
CommandLine			DWORD ?
hWnd				HWND ?
hFont				HFONT ?
connected			DWORD ?
lastsec				DWORD ?
lasthour			DWORD ?
lenr				LENR <>
logpos				DWORD ?
log					LOG GRPWDT dup(<>)
fileshow			DWORD ?
filelog				LOG GRPWDT dup(<>)
graph				DWORD ?
display				BYTE 16 dup (?)
rampupdown			DWORD ?
apppath				BYTE MAX_PATH dup (?)
xofs				DWORD ?

;Pt1000: 1000 ohm at 0°C
;4,0 ohm/Kelvin with Pt 1000 sensor

;2746 at 0C
;3025 at 25C