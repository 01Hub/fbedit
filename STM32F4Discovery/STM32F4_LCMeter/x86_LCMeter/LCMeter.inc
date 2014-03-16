
include	windows.inc
include	kernel32.inc
include	user32.inc
include	comctl32.inc
include gdi32.inc

includelib kernel32.lib
includelib user32.lib
includelib comctl32.lib
includelib gdi32.lib

includelib STLinkLib.lib

STLinkConnect					PROTO hWin:HWND
STLinkDisconnect				PROTO hWin:HWND
STLinkRead 						PROTO hWin:HWND,rdadr:DWORD,wradr:DWORD,nBytes:DWORD
STLinkWrite						PROTO hWin:HWND,wradr:DWORD,rdadr:DWORD,nBytes:DWORD

;#########################################################################
;VKim's Debug

;include masm32.inc
;include Debug.Inc
;includelib masm32.lib
;includelib Debug.lib

include masm32.inc
include \RadASM30\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM30\masm\lib\debug.lib

;#########################################################################

IDD_MAIN						equ 101
IDC_BTNMODE						equ 105

IDD_DLGLCMETER					equ 1000
IDC_UDCLCM						equ 1001
IDC_BTNLCMCAL					equ 1002
IDC_BTNLCMMODE					equ 1003

IDD_DLGHSC						equ 1100
IDC_UDCHSC						equ 1101
IDC_BTNHSCDN					equ 1102
IDC_BTNHSCUP					equ 1103
IDC_EDTHSCFRQ					equ 1104

IDD_DLGSCP						equ 1200
IDC_UDCSCP						equ 1201
IDC_TRBADCCLOCK					equ 1202
IDC_TRBADCDELAY					equ 1203
IDC_STCADCSAMPLERATE			equ 1204
IDC_TRBTIMEDIV					equ 1205
IDC_TRBVOLTDIV					equ 1206
IDC_RBNTRIGGERNONE				equ 1207
IDC_RBNTRIGGERRISING			equ 1208
IDC_RBNTRIGGERFALLING			equ 1209
IDC_TRBTRIGGERLEVEL				equ 1210
IDC_CHKSUBSAMPLING				equ 1211
IDC_CHKHOLDSAMPLING				equ 1212
IDC_TRBVPOS						equ 1213
IDC_BTNSRD						equ 1214
IDC_BTNSRU						equ 1215
IDC_BTNADU						equ 1216
IDC_BTNADD						equ 1217
IDC_BTNTDU						equ 1218
IDC_BTNTDD						equ 1219
IDC_BTNVDU						equ 1220
IDC_BTNVDD						equ 1221
IDC_BTNVPU						equ 1222
IDC_BTNVPD						equ 1223
IDC_BTNTLU						equ 1224
IDC_BTNTLD						equ 1225
IDC_CHKTRIPLE					equ 1226
IDC_BTNAUTO						equ 1227

IDD_DLGSCPSCRNCLD				equ 2000
IDC_UDCSCPSCRN					equ 2001

CMD_DONE						equ 0
CMD_LCMCAL						equ 1
CMD_LCMCAP						equ 2
CMD_LCMIND						equ 3
CMD_FRQCH1						equ 4
CMD_FRQCH2						equ 5
CMD_FRQCH3						equ 6
CMD_SCPSET                      equ 7
CMD_HSCSET						equ 8

STM32_CLOCK						equ 200000000
ADCSAMPLESIZE					equ 10000h
ADCSAMPLESTART					equ 64
ADCMAX							equ 4096
ADCMAXMV						equ 3000
ADCDIVMV						equ 500
TEXTHIGHT						equ 64
GRIDSIZE						equ 64
GRIDX							equ 10
GRIDY							equ 8
SCOPEWT							equ GRIDSIZE*GRIDX
SCOPEHT							equ GRIDSIZE*GRIDY

MAXTIMEDIV						equ 21
MAXVOLTDIV						equ 8

SCOPERANGE struct
	ydiv						DWORD ?
	ymag						DWORD ?
	range						BYTE 32 dup(?)	
SCOPERANGE ends

SCOPETIME struct
	time						DWORD ?
	range						BYTE 32 dup(?)	
SCOPETIME ends

STM32_HSC struct
	HSCSet						DWORD ?			;0x20000018
STM32_HSC ends

STM32_FRQ struct
	Frequency					DWORD ?			;0x2000001C
	FrequencySCP				DWORD ?			;0x20000020
STM32_FRQ ends

STM32_LCM struct
	FrequencyCal0				DWORD ?			;0x20000024
	FrequencyCal1				DWORD ?			;0x20000028
STM32_LCM ends

STM32_SCP struct
	ADC_Prescaler				DWORD ?         ;0x2000002C
	ADC_TwoSamplingDelay		DWORD ?         ;0x20000030
	ScopeTrigger				DWORD ?			;0x20000034
	ScopeTriggerLevel			DWORD ?			;0x20000038
	ScopeTimeDiv				DWORD ?			;0x2000003C
	ScopeVoltDiv				DWORD ?			;0x20000040
	ScopeVPos					DWORD ?			;0x20000044
	ADC_TripleMode              DWORD ?         ;0x20000048
	ADC_SampleTime              DWORD ?         ;0x2000004C
STM32_SCP ends

STM32_CMD struct
	Cmd							DWORD ?			;0x20000014
	STM32_Hsc					STM32_HSC <>	;0x20000018
	STM32_Frq 					STM32_FRQ <>	;0x2000001C
	STM32_Lcm					STM32_LCM <>	;0x2000002C
	STM32_Scp					STM32_SCP <>	;0x20000034
	TickCount					DWORD ?
	PreviousCountTIM2			DWORD ?
	ThisCountTIM2				DWORD ?
	PreviousCountTIM5			DWORD ?
	ThisCountTIM5				DWORD ?
STM32_CMD ends

FP_EQUALTO						equ	40h

.const

szFREQUENCYCLASS				BYTE 'FREQUENCYCLASS',0
szSCOPECLASS					BYTE 'SCOPECLASS',0
Tahoma_36						LOGFONT <-36,0,0,0,400,0,0,0,0,3,2,1,34,"Tahoma">

szLCMeter						BYTE 'LC Meter - ',0
szCapacitance					BYTE 'Capacitance',0
szInductance					BYTE 'Inductance',0
szFerquencyCH1					BYTE 'Ferquency CH1',0
szFerquencyCH2					BYTE 'Ferquency CH2',0
szFerquencyCH3					BYTE 'Ferquency CH3',0
szScope							BYTE 'Scope',0

szFmtHz							BYTE '%dHz',0
szFmtKHz						BYTE '%dKHz',0
szFmtMHz						BYTE '%dMHz',0
szHz							BYTE 'Hz',0

szPF							BYTE 'pF',0
szNF							BYTE 'nF',0
szUF							BYTE 'uF',0

szNH							BYTE 'nH',0
szUH							BYTE 'uH',0
szMH							BYTE 'mH',0
szH								BYTE 'H',0

sznS							BYTE 'ns',0
szuS							BYTE 'us',0
szmS							BYTE 'ms',0

CCal							REAL10 1.015e-9
two								REAL10 2.0

ten16							REAL8 1.0e16
ten								REAL8 10.0
ten_1							REAL10 1.0e1
								REAL10 1.0e2
ten_3							REAL10 1.0e3
								REAL10 1.0e4
								REAL10 1.0e5
ten_6							REAL10 1.0e6
								REAL10 1.0e7
								REAL10 1.0e8
ten_9							REAL10 1.0e9
								REAL10 1.0e10
								REAL10 1.0e11
ten_12							REAL10 1.0e12
								REAL10 1.0e13
								REAL10 1.0e14
								REAL10 1.0e15
ten_16							REAL10 1.0e16
								REAL10 1.0e32
								REAL10 1.0e48
								REAL10 1.0e64
								REAL10 1.0e80
								REAL10 1.0e96
								REAL10 1.0e112
								REAL10 1.0e128
								REAL10 1.0e144
								REAL10 1.0e160
								REAL10 1.0e176
								REAL10 1.0e192
								REAL10 1.0e208
								REAL10 1.0e224
								REAL10 1.0e240
ten_256							REAL10 1.0e256
								REAL10 1.0e512
								REAL10 1.0e768
								REAL10 1.0e1024
								REAL10 1.0e1280
								REAL10 1.0e1536
								REAL10 1.0e1792
								REAL10 1.0e2048
								REAL10 1.0e2304
								REAL10 1.0e2560
								REAL10 1.0e2816
								REAL10 1.0e3072
								REAL10 1.0e3328
								REAL10 1.0e3584
								REAL10 1.0e4096
								REAL10 1.0e4352
								REAL10 1.0e4608
								REAL10 1.0e4864

ScopeTime						SCOPETIME <10,'10nS / Div'>,<20,'20nS / Div'>,<50,'50nS / Div'>,<100,'100nS / Div'>,<200,'200nS / Div'>,<500,'500nS / Div'>,<1000,'1uS / Div'>,<2000,'2uS / Div'>,<5000,'5uS / Div'>,<10000,'10uS / Div'>,<20000,'20uS / Div'>,<50000,'50uS / Div'>
								SCOPETIME <100000,'100uS / Div'>,<200000,'200uS / Div'>,<500000,'500uS / Div'>,<1000000,'1mS / Div'>,<2000000,'2mS / Div'>,<5000000,'5mS / Div'>,<10000000,'10mS / Div'>,<20000000,'20mS / Div'>,<50000000,'50mS / Div'>,<100000000,'100mS / Div'>
ScopeRange						SCOPERANGE <15,0,'1mV/Div'>,<30,0,'2mV/Div'>,<76,0,'5mV/Div'>,<152,0,'10mV/Div'>,<305,0,'20mV/Div'>,<762,0,'50mV / Div'>,<1525,0,'100mV / Div'>,<3050,0,'200mV / Div'>,<7625,0,'500mV / Div'>
szFmtVPP						BYTE 'Vpp: ',0
szFmtPPV						BYTE '%.04uV',0
szFmtPER						BYTE 'Per: ',0
ADCSingle_SampleClocks			DWORD 3,15,28,56,84,112,144,480

;#########################################################################

.data?

hInstance						HINSTANCE ?
wc								WNDCLASSEX <>
hWnd							HWND ?
msg								MSG <>
hScpScrnCld						HWND ?
hScpScrn						HWND ?
hHscCld							HWND ?
hHsc							HWND ?
hLcmCld							HWND ?
hLcm							HWND ?
hScpCld							HWND ?
hScp							HWND ?
hFont							HFONT ?
hIml							HIMAGELIST ?
connected						DWORD ?

mode							DWORD ?
LCx								REAL10 ?
lpOldButtonProc					DWORD ?
nBtnCount						DWORD ?
fSampleDone						DWORD ?
fHoldSampling					DWORD ?
fNoFrequency					DWORD ?
fSubSampling					DWORD ?
fExitThread						DWORD ?
fThreadDone						DWORD ?
SampleRate						REAL10 ?
SampleTime						REAL10 ?
SignalPeriod					DWORD ?
STM32_Cmd						STM32_CMD <>
STM32_Scp						STM32_SCP <>
ADC_Data						WORD ADCSAMPLESIZE dup(?)
SubSample						DWORD 2048 dup(?)
SubSampleCount					WORD 2048 dup(?)

;#########################################################################
