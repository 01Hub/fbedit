
include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc
include comctl32.inc
include comdlg32.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib Comctl32.lib
includelib comdlg32.lib

includelib STLinkLib.lib

include DDSWave.inc

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

STLinkConnect				PROTO hWin:HWND
STLinkDisconnect			PROTO hWin:HWND
STLinkReset					PROTO hWin:HWND
STLinkRead 					PROTO hWin:HWND,rdadr:DWORD,wradr:DWORD,nBytes:DWORD
STLinkWrite					PROTO hWin:HWND,wradr:DWORD,rdadr:DWORD,nBytes:DWORD

;MMenu ID's
IDR_MENU1					equ 10000
IDM_FILE					equ 10001
IDM_FILE_OPEN				equ 10002
IDM_FILE_OPEN_SCOPECHA		equ 10022
IDM_FILE_OPEN_SCOPECHB		equ 10023

IDM_FILE_SAVE				equ 10004
IDM_FILE_SAVE_SCOPECHA		equ 10024
IDM_FILE_SAVE_SCOPECHB		equ 10025
IDM_FILE_EXIT				equ 10006
IDM_VIEW					equ 10007
IDM_VIEW_SCOPECHA			equ 10008
IDM_VIEW_SCOPECHB			equ 10009
IDM_VIEW_SCOPECHACHB		equ 10010
IDM_VIEW_LOGICANALYSER		equ 10011
IDM_VIEW_HSCLOCKCHA			equ 10005
IDM_VIEW_HSCLOCKCHB			equ 10026
IDM_VIEW_HSCLOCKCHACHB		equ 10027
IDM_SETUP					equ 10017
IDM_SETUP_SCOPE				equ 10018
IDM_SETUP_LOGICANALYSER		equ 10020
IDM_SETUP_HIGHSPEEDCLOCK	equ 10021
IDM_HELP					equ 10015
IDM_HELP_ABOUT				equ 10016
IDM_VIEW_DDSWAVEGEN			equ 10003
IDM_SETUP_DDSWAVEGEN		equ 10012

;Main dialog ID's
IDD_MAIN					equ 101
IDC_BTNSAMPLE				equ 102
IDC_CHKAUTO					equ 103

;Scope screen
IDD_DLGSCOPE				equ 2000
IDC_UDCSCOPE				equ 2001
;Scope tool
IDD_DLGSCOPETOOL			equ 1500
IDC_TRBXMAG					equ 1503
IDC_TRBYMAG					equ 1501
IDC_CHKSUBSAMPLE			equ 1506
IDC_CHKPERIODS				equ 1505
;Scope setup
IDD_DLGSCOPESETUP			equ 1200
IDC_RBNTRIGMANUAL			equ 1201
IDC_RBNRISINGCHA			equ 1202
IDC_RBNFALLINGCHA			equ 1203
IDC_RBNRISINGCHB			equ 1204
IDC_RBNFALLINGCHB			equ 1205
IDC_RBNTRIGLGA				equ 1206
IDC_RBNTRIGLGAEDGE			equ 1207
IDC_TRBTRIGLEVEL			equ 1212
IDC_TRBDCNULLOUTCHA			equ 1208
IDC_TRBAMPLIFYCHA			equ 1213
IDC_TRBDCNULLOUTCHB			equ 1211
IDC_TRBAMPLIFYCHB			equ 1215
IDC_TRBBUFFERSIZE			equ 1210
IDC_CBODATABITS				equ 1214
IDC_CBOSAMPLECLOCKS			equ 1216
IDC_CBOCLOCKDIVISOR			equ 1209
IDC_STCSAMPLERATE			equ 1217

;Frequency / DVM dialog
IDD_DLGFREQUENCY			equ 1100
IDC_UDCFREQUENCYCHA			equ 1101
IDC_UDCFREQUENCYCHB			equ 1102
IDC_UDCVOLTSDVMA			equ 1103
IDC_UDCVOLTSDVMB			equ 1104

;Logic analyser screen
IDD_DLGLOGICANALYSER		equ 1400
IDC_UDCLOGICANALYSER		equ 1401
;Logic analyser tool
IDD_DLGLGATOOL				equ 1600
IDC_TRBLGAXMAG				equ 1601
;Logic analyser setup
IDD_DLGLGASETUP				equ 1700
IDC_RBNLGAMANUAL			equ 1704
IDC_RBNLGARISINGCHA			equ 1705
IDC_RBNTRGFALLINGCHA		equ 1706
IDC_RBNLGARISINGCHB			equ 1707
IDC_RBNLGAFALLINGCHB		equ 1708
IDC_RBNLGALGA				equ 1709
IDC_RBNLGALGAEDGE			equ 1710
IDC_CHKLGATRIGALL			equ 1729
IDC_CHKLGATRIGD0			equ 1720
IDC_CHKLGATRIGD1			equ 1721
IDC_CHKLGATRIGD2			equ 1722
IDC_CHKLGATRIGD3			equ 1723
IDC_CHKLGATRIGD4			equ 1724
IDC_CHKLGATRIGD5			equ 1725
IDC_CHKLGATRIGD6			equ 1726
IDC_CHKLGATRIGD7			equ 1727
IDC_CHKLGAMASKALL			equ 1739
IDC_CHKLGAMASKD0			equ 1730
IDC_CHKLGAMASKD1			equ 1731
IDC_CHKLGAMASKD2			equ 1732
IDC_CHKLGAMASKD3			equ 1733
IDC_CHKLGAMASKD4			equ 1734
IDC_CHKLGAMASKD5			equ 1735
IDC_CHKLGAMASKD6			equ 1736
IDC_CHKLGAMASKD7			equ 1737
IDC_TRBSAMPLERATE			equ 1701
IDC_STCLGASAMPLERATE		equ 1703
IDC_TRBLGABUFFERSIZE		equ 1702

;High speed clock screen
IDD_DLGHSCLOCK				equ 2300
IDC_UDCHSCLOCK				equ 2301
;High speed clock tool
IDD_DLGHSCLOCKTOOL			equ 2200
IDC_TRBHSCLOCKXMAG			equ 2201
;;High speed clock setup
IDD_DLGHSCLOCKSETUP			equ 2100
IDC_CHKHSCLOCKAENABLE		equ 2104
IDC_BTNFRQCHADN				equ 2101
IDC_EDTFRQCHA				equ 2105
IDC_BTNFRQCHAUP				equ 2102
IDC_TRBHSCLOCKADUTY			equ 2103
IDC_CHKHSCLOCKBENABLE		equ 2113
IDC_BTNFRQCHBDN				equ 2109
IDC_EDTFRQCHB				equ 2108
IDC_BTNFRQCHBUP				equ 2107
IDC_TRBHSCLOCKBDUTY			equ 2106

;DDS Wave screen
IDD_DDSWAVE					equ 1000
IDC_UDCDDSWAVE				equ 1001

;DDS Wave setup
IDD_DDSWAVESETUP			equ 1300
IDC_TRBDDSAMP				equ 1304
IDC_TRBDDSDCOFS				equ 1305
IDC_TRBDDSFRQH				equ 1306
IDC_TRBDDSFRQL				equ 1307
IDC_EDTDDSFREQUENCY			equ 1308
IDC_BTNDDSSET				equ 1309
IDC_RBNSWEEPOFF				equ 1310
IDC_RBNSWEEPUP				equ 1311
IDC_RBNSWEEPDOWN			equ 1312
IDC_RBNSWEEPUPDOWN			equ 1313
IDC_RBNSWEEPPEAK			equ 1314
IDC_EDTSWEEPSIZE			equ 1315
IDC_EDTSWEEPTIME			equ 1316
IDC_EDTSWEEPCOUNT			equ 1317
IDC_BTNSWEEPSET				equ 1318
IDC_CBODDSWAVE				equ 1303

;#########################################################################

STM32_DataSize				equ 1024*63
STM32_BlockSize				equ 64
STM32_MAXBLOCK				equ 255;STM32_DataSize/STM32_BlockSize/4

;Command
STM32_CommandWait			equ 0
STM32_CommandInit			equ 1
STM32_CommandDone			equ 99

;Mode
STM32_ModeNone				equ 0
STM32_ModeScopeCHA			equ 1
STM32_ModeScopeCHB			equ 2
STM32_ModeScopeCHACHB		equ 3
STM32_ModeHSClockCHA		equ 4
STM32_ModeHSClockCHB		equ 5
STM32_ModeHSClockCHACHB		equ 6
STM32_ModeLGA				equ 7
STM32_ModeDDSWave			equ 8

;Trigger
STM32_TriggerManual			equ 0
STM32_TriggerRisingCHA		equ 1
STM32_TriggerFallingCHA		equ 2
STM32_TriggerRisingCHB		equ 3
STM32_TriggerFallingCHB		equ 4
STM32_TriggerLGA			equ 5
STM32_TriggerLGAEdge		equ 6

;DDS Waveforms
DDS_ModeSinWave				equ 0
DDS_ModeTriWave				equ 1
DDS_ModeSqrWave				equ 2
DDS_ModeSawWave				equ 3
DDS_ModeRevSawWave			equ 4

;DDS SWEEP Modes
SWEEP_ModeOff				equ 0
SWEEP_ModeUp				equ 1
SWEEP_ModeDown				equ 2
SWEEP_ModeUpDown			equ 3

;STM32 ram addresses
STM32FrequencyCHA			equ 20000014h
STM32FrequencyCHB			equ 20000024h
STM32CommandStart			equ 20000034h
STM32DataStart				equ 20000064h

;#########################################################################

ADCMAX						equ 0FFh
DACMAX						equ 0FFFh
DDSMAX						equ 07FFFh
XMAGMAX						equ 512
YMAGMAX						equ 128
HSCMAX						equ 202

DVMMAX						equ 0FFFh
DVMAMUL						equ 3000
DVMBMUL						equ 3000
LGAXSTART					equ 23
TEXTHIGHT					equ 30

;#########################################################################

STM32_CommandStructDef struct
	Command					BYTE ?
	Mode					BYTE ?
	DataBlocks				BYTE ?
	TriggerMode				BYTE ?
	TriggerValue			BYTE ?
	TriggerMask				BYTE ?
	TriggerWait				BYTE ?
	ScopeDataBits			BYTE ?
	ScopeSampleClocks		BYTE ?
	ScopeClockDiv			BYTE ?
	ScopeAmplifyCHA			BYTE ?
	ScopeAmplifyCHB			BYTE ?
	ScopeDCNullOutCHA		BYTE ?
	ScopeDCNullOutCHB		BYTE ?
	LGASampleRate			WORD ?
	DDS_WaveType			BYTE ?
	DDS_SweepMode			BYTE ?
	DDS_PhaseAdd			DWORD ?
	DDS_Amplitude			WORD ?
	DDS_DCOffset			WORD ?
	SWEEP_Add				DWORD ?
	SWEEP_StepTime			WORD ?
	SWEEP_StepCount			WORD ?
	SWEEP_Min				DWORD ?
	SWEEP_Max				DWORD ?
	Reserved				WORD ?
STM32_CommandStructDef ends

STM32_FRQDataStructDef struct
	Frequency				DWORD ?
	PreviousCount			DWORD ?
	HSCEnable				WORD ?
	HSCClockDiv				WORD ?
	HSCCount				WORD ?
	HSCDuty					WORD ?
STM32_FRQDataStructDef ends

;#########################################################################

SCOPECHDATA struct
	hWndDialog				HWND ?
	hWndScope				HWND ?
	hWndScopeTool			HWND ?
	xmag					DWORD ?
	ymag					DWORD ?
	fYMagnify				DWORD ?
	fSubsampling			DWORD ?
	fTwoPeriods				DWORD ?
	frq_data				STM32_FRQDataStructDef <>
	nstart					DWORD ?
	nend					DWORD ?
	nperiods				DWORD ?
	nsamples				DWORD ?
	nusstart				DWORD ?
	frequency				QWORD ?
	period					QWORD ?
	convperiod				QWORD ?
	ADC_TriggerEdge			BYTE ?
	ADC_TriggerValue		BYTE ?
	ADC_DCNullOut			BYTE ?
	vmin					DWORD ?
	vmax					DWORD ?
	vpp						DWORD ?
	ADC_Data				BYTE STM32_DataSize*2 dup(?)
	ADC_USData				BYTE STM32_DataSize*2 dup(?)
SCOPECHDATA ends

SCOPEDATA struct
	ADC_CommandStruct		STM32_CommandStructDef <>
	ADC_CommandStructDone	STM32_CommandStructDef <>
	scopeCHAdata			SCOPECHDATA <>
	scopeCHBdata			SCOPECHDATA <>
SCOPEDATA ends

;#########################################################################

LGADATA struct
	hWndDialog				HWND ?
	hWndLGA					HWND ?
	hWndLGATool				HWND ?
	xmag					DWORD ?
	LGA_CommandStruct		STM32_CommandStructDef <>
	LGA_CommandStructDone	STM32_CommandStructDef <>
	LGA_Data				BYTE STM32_DataSize dup(?)
	LGA_Text				BYTE 128 dup(?)
LGADATA ends

;#########################################################################

HSCLOCKCHDATA struct
	hWndDialog				HWND ?
	hWndHSClock				HWND ?
	hWndHSClockTool			HWND ?
	xmag					DWORD ?
	hsclockenable			DWORD ?
	hsclockfrequency		WORD ?
	hsclockdivisor			WORD ?
	hsclockccr				WORD ?
	hsclockdutycycle		WORD ?
	HSC_Data				BYTE HSCMAX dup(?)
HSCLOCKCHDATA ends

HSCLOCKDATA struct
	HSC_CommandStruct		STM32_CommandStructDef <>
	HSC_CommandStructDone	STM32_CommandStructDef <>
	hscCHAData				HSCLOCKCHDATA <>
	hscCHBData				HSCLOCKCHDATA <>
	hscFRQ					STM32_FRQDataStructDef <>
HSCLOCKDATA ends

;#########################################################################

DDSDATA struct
	hWndDialog				HWND ?
	hWndDDS					HWND ?
	hWndDDSTool				HWND ?
	xmag					DWORD ?
	DDS_VMin				DWORD ?
	DDS_VMax				DWORD ?
	DDS_CommandStruct		STM32_CommandStructDef <>
	DDS_CommandStructDone	STM32_CommandStructDef <>
	DDS_WaveData			WORD 4098 dup(?)
DDSDATA ends

;#########################################################################

CHILDDIALOGS struct
	hWndScopeCHA			HWND ?
	hWndScopeCHB			HWND ?
	hWndHSClockCHA			HWND ?
	hWndHSClockCHB			HWND ?
	hWndLogicAnalyser		HWND ?
	hWndDDSWave				HWND ?
	hWndFrequency			HWND ?
	hWndScopeSetup			HWND ?
	hWndLGASetup			HWND ?
	hWndHSClockSetup		HWND ?
	hWndDDSWaveSetup		HWND ?
CHILDDIALOGS ends

;#########################################################################

.const

szMAINCLASS					BYTE 'MAINCLASS',0
szSCOPECLASS				BYTE 'SCOPECLASS',0
szTEXTCLASS					BYTE 'TEXTCLASS',0
szLOGICANALYSERCLASS		BYTE 'LOGICANALYSERCLASS',0
szHSCLOCKCLASS				BYTE 'HSCLOCKCLASS',0
szDDSWAVECLASS				BYTE 'DDSWAVECLASS',0

Tahoma						LOGFONT <-20,0,0,0,400,0,0,0,0,3,2,1,34,"Tahoma">

szNULL						BYTE 0
szFrequencyCHA				BYTE 'Frequency CHA',0
szFrequencyCHB				BYTE 'Frequency CHB',0
szVoltsDVMA					BYTE 'Volts DVMA',0
szVoltsDVMB					BYTE 'Volts DVMB',0
szLGADataBits				BYTE 'D0',0,'D1',0,'D2',0,'D3',0,'D4',0,'D5',0,'D6',0,'D7',0,0

szDDS_Waves					BYTE 'Sine Wave',0
							BYTE 'Triangle Wave',0
							BYTE 'Square Wave',0
							BYTE 'Sawtooth Wave',0
							BYTE 'Reverse Sawtooth Wave',0,0

szFmtVolts					BYTE '%04uV',0
szFmtFrq					BYTE ' Frequency: ',0
szFmtFrqHz					BYTE '%s%uHz',0
szFmtFrqHzX1000				BYTE '%s%04uHz',0
szFmtFrqKHz					BYTE '%s%uKHz',0
szFmtFrqMHz					BYTE '%s%uMHz',0
szFmtFrqMin					BYTE ' Fmin: ',0
szFmtFrqMax					BYTE '  Fmax: ',0
szFmtVmin					BYTE '  Vmin: %04uV',0
szFmtVmax					BYTE '  Vmax: %04uV',0
szFmtVpp					BYTE '  Vpp: %04uV',0
szFmtWaveDCOffset			BYTE '  DC Offset: %04uV',0
szFmtDuty					BYTE '  Pulse Width: %u%%',0
szFmtLGA					BYTE ' Hex: %02X  Bin: %s  Bytenbr: %u',0
szFmtDec					BYTE '%u',0
szCOMMA						BYTE ',',0
szCRLF						BYTE 0Dh,0Ah,0

szADCDataBits				BYTE '12',0,'10',0,'8',0,'6',0,0
szADCSampleClocks			BYTE '3',0,'15',0,'28',0,'56',0,'84',0,'112',0,'144',0,'480',0,0
szADCClockDiv				BYTE '2',0,'4',0,'6',0,'8',0,0

nsinasec					QWORD 1000000000.0
float2						QWORD 2.0
float100					QWORD 100.0

dds64						QWORD 100000000h
ddscycles					DWORD 8

STM32Clock					DWORD 168000000
STM32ClockDiv2				DWORD 84000000

;#########################################################################

.data?

hInstance					HINSTANCE ?
wc							WNDCLASSEX <>
hWnd						HWND ?
hDlg						HWND ?
fConnected					DWORD ?
fNoSTLink					DWORD ?
fFRQDVM						DWORD ?
fHSCCHA						DWORD ?
fHSCCHB						DWORD ?
fSCOPE						DWORD ?
fLGA						DWORD ?
fDDS						DWORD ?

scopedata					SCOPEDATA <>
lgadata						LGADATA <>
hsclockdata					HSCLOCKDATA <>
ddsdata						DDSDATA <>
childdialogs				CHILDDIALOGS <>

hFont						HFONT ?
hThread						HANDLE ?
fThreadExit					DWORD ?

lpSTM32_Command				DWORD ?
lpSTM32_CommandDone			DWORD ?
lpOldButtonProc				DWORD ?
msg							MSG <>

;#########################################################################
