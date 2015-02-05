
include	windows.inc
include	kernel32.inc
include	user32.inc
include	comctl32.inc
include gdi32.inc
include wsock32.inc
include ws2_32.inc

includelib kernel32.lib
includelib user32.lib
includelib comctl32.lib
includelib gdi32.lib
includelib wsock32.lib
includelib ws2_32.lib

;#########################################################################
;VKim's Debug

include masm32.inc
include \RadASM30\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM30\masm\lib\debug.lib

;#########################################################################

IDD_MAIN						equ 101
IDC_TABFUNCTION					equ 102
IDC_IMGCONNECTED				equ 103

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
IDC_STCSAMPLESIZE				equ 1228

IDD_DLGDDS						equ 1300
IDC_BTNDDSFRQUP					equ 1304
IDC_BTNDDSFRQDN					equ 1302
IDC_EDTDDSFRQ					equ 1303
IDC_UDCDDSFRQ					equ 1301
IDC_BTNDDSWAVEUP        		equ 1307
IDC_BTNDDSWAVEDN        		equ 1305
IDC_STCDDSWAVE          		equ 1306
IDC_BTNDDSAMPUP         		equ 1308
IDC_BTNDDSAMPDN         		equ 1309
IDC_TRBDDSAMP           		equ 1310
IDC_BTNDDSOFSUP         		equ 1311
IDC_TRBDDSOFS           		equ 1312
IDC_BTNDDSOFSDN         		equ 1313
IDC_RBNSWEEPOFF					equ 1315
IDC_RBNSWEEPUP					equ 1316
IDC_RBNSWEEPDOWN				equ 1317
IDC_RBNSWEEPUPDOWN				equ 1318
IDC_BTNDDSSWEEPUP				equ 1319
IDC_EDTDDSSWEEP					equ 1320
IDC_BTNDDSSWEEPDN				equ 1321
IDC_BTNSWEEPRNGUP				equ 1322
IDC_EDTSWEEPRANGE				equ 1323
IDC_BTNSWEEPRNGDN				equ 1324
IDC_BTNSWEEPTIMEDN				equ 1326
IDC_EDTSWEEPSTEPTIME			equ 1327
IDC_BTNSWEEPTIMEUP				equ 1325

IDD_DLGLGA						equ 1400
IDC_BTNSRUP						equ 1401
IDC_TRBSR						equ 1402
IDC_BTNSRDN						equ 1403
IDC_BTNBSUP						equ 1404
IDC_STCSR						equ 1410
IDC_TRBBS						equ 1405
IDC_BTNBSDN						equ 1406
IDC_STCBS						equ 1415
IDC_CHKLGATRIGALL				equ 1429
IDC_CHKLGATRIGD0				equ 1420
IDC_CHKLGATRIGD1				equ 1421
IDC_CHKLGATRIGD2				equ 1422
IDC_CHKLGATRIGD3				equ 1423
IDC_CHKLGATRIGD4				equ 1424
IDC_CHKLGATRIGD5				equ 1425
IDC_CHKLGATRIGD6				equ 1426
IDC_CHKLGATRIGD7				equ 1427
IDC_CHKLGAMASKALL				equ 1439
IDC_CHKLGAMASKD0				equ 1430
IDC_CHKLGAMASKD1				equ 1431
IDC_CHKLGAMASKD2				equ 1432
IDC_CHKLGAMASKD3				equ 1433
IDC_CHKLGAMASKD4				equ 1434
IDC_CHKLGAMASKD5				equ 1435
IDC_CHKLGAMASKD6				equ 1436
IDC_CHKLGAMASKD7				equ 1437
IDC_BTNLGASAMPLE				equ 1407
IDC_BTNTRGPREVIOUS				equ 1409
IDC_BTNTRGNEXT					equ 1408

IDD_DLGMAKEWAVE         		equ 1500
IDC_RBNMAIN             		equ 1501
IDC_RBNHARMONIC         		equ 1502
IDC_RBNNOISE            		equ 1503
IDC_RBNRESULT           		equ 1504

IDC_BTNMADN             		equ 1506
IDC_TRBMA               		equ 1507
IDC_BTNMAUP             		equ 1508

IDC_BTN2HADN            		equ 1509
IDC_TRB2HA              		equ 1510
IDC_BTN2HAUP            		equ 1511

IDC_BTN3HADN            		equ 1513
IDC_TRB3HA              		equ 1514
IDC_BTN3HAUP            		equ 1515

IDC_BTN4HADN            		equ 1517
IDC_TRB4HA              		equ 1518
IDC_BTN4HAUP            		equ 1519

IDC_BTNNADN             		equ 1521
IDC_TRBNA               		equ 1522
IDC_BTNNAUP             		equ 1523

IDC_BTNNFDN             		equ 1512
IDC_TRBNF               		equ 1516
IDC_BTNNFUP             		equ 1520

IDC_RBNMAINSINE         		equ 1524
IDC_RBNMAINTRIANGLE     		equ 1525
IDC_RBNMAINSQUARE       		equ 1526
IDC_RBNHARMONICSINE     		equ 1527
IDC_RBNHARMONICTRIANGLE 		equ 1528
IDC_RBNHARMONICSQUARE   		equ 1529

IDD_DLGSCPSCRNCLD				equ 2000
IDC_UDCSCPSCRN					equ 2001

IDD_DLGDDSCLD					equ 3000
IDC_UDCDDSSCRN					equ 3001

IDD_DLGLGACLD					equ 4000
IDC_UDCLGASCRN					equ 4001

IDD_DLGMAKEWAVECLD				equ 5000
IDC_UDCMAKEWAVE					equ 5001

CMD_DONE						equ 0
CMD_LCMCAL						equ 1
CMD_LCMCAP						equ 2
CMD_LCMIND						equ 3
CMD_FRQCH1						equ 4
CMD_FRQCH2						equ 5
CMD_FRQCH3						equ 6
CMD_SCPSET                      equ 7
CMD_HSCSET						equ 8
CMD_DDSSET						equ 9
CMD_LGASET						equ 10
CMD_WAVEUPLOAD					equ 11
CMD_STARTUP						equ 99

STM32_CLOCK						equ 200000000
ADCSAMPLESIZE					equ 10000h
ADCSAMPLESTART					equ 64
ADCMAX							equ 4096
ADCMAXMV						equ 2990
ADCDIVMV						equ 500
TEXTHIGHT						equ 64
GRIDSIZE						equ 64
GRIDX							equ 10
GRIDY							equ 8
SCOPEWT							equ GRIDSIZE*GRIDX
SCOPEHT							equ GRIDSIZE*GRIDY

MAXSCPTIMEDIV					equ 21
MAXSCPVOLTDIV					equ 8

LGASAMPLESIZE					equ 32768
MAXLGASAMPLE					equ 15
MAXLGABUFFER					equ 32

DACMAX							equ 4095

;DDS Waveforms
DDS_ModeSinWave					equ 0
DDS_ModeTriWave					equ 1
DDS_ModeSqrWave					equ 2
DDS_ModeSawWave					equ 3
DDS_ModeRevSawWave				equ 4
DDS_ModeMakeWave				equ 5

;DDS SWEEP Modes
SWEEP_ModeOff					equ 0
SWEEP_ModeUp					equ 1
SWEEP_ModeDown					equ 2
SWEEP_ModeUpDown				equ 3

DDS_PHASESET					equ 1
DDS_WAVESET						equ 2
DDS_SWEEPSET					equ 3

BTH_ADDR						equ QWORD ?

SOCKADDR_BTH struct
	addressFamily				WORD ?
	btAddr						BTH_ADDR
	serviceClassId				GUID <>
	port						DWORD ?
SOCKADDR_BTH ends

SCOPERANGE struct
	ydiv						DWORD ?
	ymag						DWORD ?
	range						BYTE 32 dup(?)	
SCOPERANGE ends

SCOPETIME struct
	time						DWORD ?
	range						BYTE 32 dup(?)	
SCOPETIME ends

LGASAMPLE struct
	clockdiv					DWORD ?
	rate						BYTE 32 dup(?)
LGASAMPLE ends

STM32_HSC struct
	HSCSet						DWORD ?
	HSCDiv						DWORD ?
STM32_HSC ends

STM32_FRQ struct
	Frequency					DWORD ?
	FrequencySCP				DWORD ?
STM32_FRQ ends

STM32_LCM struct
	FrequencyCal0				DWORD ?
	FrequencyCal1				DWORD ?
STM32_LCM ends

STM32_SCP struct
	ADC_Prescaler				DWORD ?
	ADC_TwoSamplingDelay		DWORD ?
	ScopeTrigger				DWORD ?
	ScopeTriggerLevel			DWORD ?
	ScopeTimeDiv				DWORD ?
	ScopeVoltDiv				WORD ?
	ScopeMag					WORD ?
	ScopeVPos					DWORD ?
	ADC_TripleMode              DWORD ?
	ADC_SampleTime              DWORD ?
	ADC_SampleSize				DWORD ?
	fSubSampling				DWORD ?
STM32_SCP ends

STM32_DDS struct
	DDS_Cmd						WORD ?
	DDS_Wave					WORD ?
	DDS__PhaseAdd				DWORD ?
	DDS_Amplitude				DWORD ?
	DDS_DCOffset				DWORD ?
	SWEEP_Mode					WORD ?
	SWEEP_Time					WORD ?
	SWEEP_Step					DWORD ?
	SWEEP_Min					DWORD ?
	SWEEP_Max					DWORD ?
STM32_DDS ends

STM32_LGA struct
	DataBlocks					BYTE ?
	TriggerValue				BYTE ?
	TriggerMask					BYTE ?
	TriggerWait					BYTE ?
	LGASampleRateDiv			WORD ?
	LGASampleRate				WORD ?
STM32_LGA ends

STM32_CMD struct
	Cmd							DWORD ?
	STM32_Hsc					STM32_HSC <>
	STM32_Frq 					STM32_FRQ <>
	STM32_Lcm					STM32_LCM <>
	STM32_Scp					STM32_SCP <>
	STM32_Dds					STM32_DDS <>
	STM32_Lga					STM32_LGA <>
	TickCount					DWORD ?
	PreviousCountTIM2			DWORD ?
	ThisCountTIM2				DWORD ?
	PreviousCountTIM5			DWORD ?
	ThisCountTIM5				DWORD ?
STM32_CMD ends

DDSWAVEDATA struct
	DDS_WaveForm				DWORD ?
	DDS_Frequency				DWORD ?
	DDS_Amplitude				DWORD ?
	DDS_DCOffset				DWORD ?
	DDS_VMin					DWORD ?
	DDS_VMax					DWORD ?
	SWEEP_Mode					DWORD ?
	SWEEP_StepSize				DWORD ?
	SWEEP_Range					DWORD ?
	SWEEP_StepTime				DWORD ?
	SWEEP_FrqMin				DWORD ?
	SWEEP_FrqMax				DWORD ?
	DDS_WaveData				WORD 4098 dup(?)
	DDS_SweepMinWaveData		WORD 4098 dup(?)
	DDS_SweepMaxWaveData		WORD 4098 dup(?)
DDSWAVEDATA ends

MAKEWAVEDATA struct
	ShowWave					DWORD ?
	MainType					DWORD ?
	MainAmp						DWORD ?
	HarmonicType				DWORD ?
	SecondHarmonicAmp			DWORD ?
	ThirdHarmonicAmp			DWORD ?
	FourthHarmonicAmp			DWORD ?
	NoiseAmp					DWORD ?
	NoiseFrequency				DWORD ?
	MW_MainData					WORD 2048 dup(?)
	MW_SecondHarmonicData		WORD 2048 dup(?)
	MW_ThirdHarmonicData		WORD 2048 dup(?)
	MW_FourthHarmonicData		WORD 2048 dup(?)
	MW_SumHarmonicData			WORD 2048 dup(?)
	MW_RndNoiseData				WORD 2048 dup(?)
	MW_NoiseData				WORD 2048+256 dup(?)
	MW_ResultData				WORD 2048 dup(?)
MAKEWAVEDATA ends

FP_EQUALTO						equ	40h

.const

szFREQUENCYCLASS				BYTE 'FREQUENCYCLASS',0
szSCOPECLASS					BYTE 'SCOPECLASS',0
szDDSCLASS						BYTE 'DDSCLASS',0
szLGACLASS						BYTE 'LGACLASS',0
szMWCLASS						BYTE 'MWCLASS',0

Tahoma_36						LOGFONT <-36,0,0,0,400,0,0,0,0,3,2,1,34,"Tahoma">

szLCMeter						BYTE 'LC Meter - ',0
szLCM							BYTE 'LC Meter',0
szCalibrate						BYTE 'Calibrate',0
szCapacitance					BYTE 'Capacitance',0
szInductance					BYTE 'Inductance',0
szFerquencyCH1					BYTE 'HS Clock',0
szFerquencyCH2					BYTE 'Ferquency CH2',0
szFerquencyCH3					BYTE 'Ferquency CH3',0
szScope							BYTE 'Scope',0
szDDS							BYTE 'DDS Wave',0
szLGA							BYTE 'Logic Analyser',0
szMakeWave						BYTE 'Make Wave',0

szSampleRate					BYTE 'Sample Rate ',0
szBufferSize					BYTE 'Buffer Size %dKb',0

szFmtHz							BYTE '%dHz',0
szFmtKHz						BYTE '%dKHz',0
szFmtMHz						BYTE '%dMHz',0
szHz							BYTE 'Hz',0
szKHz							BYTE 'KHz',0
szMHz							BYTE 'MHz',0

szFmtLGA						BYTE ' Hex: %02X  Bin: %s  Bytenbr: %u Transitions: %u Time: %s',0
szFmtLGATimens					BYTE '%02uns',0
szFmtLGATimeus					BYTE '%uus',0
szFmtLGATimems					BYTE '%ums',0
szFmtLGATimeDiv					BYTE '%s / Div',0

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
float2							REAL8 2.0
float4							REAL8 4.0
float6							REAL8 6.0
float8							REAL8 8.0

ten_e3							REAL8 1.0e3
ten_e6							REAL8 1.0e6

ScopeTime						SCOPETIME <10,'10nS / Div'>,<20,'20nS / Div'>,<50,'50nS / Div'>,<100,'100nS / Div'>,<200,'200nS / Div'>,<500,'500nS / Div'>,<1000,'1uS / Div'>,<2000,'2uS / Div'>,<5000,'5uS / Div'>,<10000,'10uS / Div'>,<20000,'20uS / Div'>,<50000,'50uS / Div'>
								SCOPETIME <100000,'100uS / Div'>,<200000,'200uS / Div'>,<500000,'500uS / Div'>,<1000000,'1mS / Div'>,<2000000,'2mS / Div'>,<5000000,'5mS / Div'>,<10000000,'10mS / Div'>,<20000000,'20mS / Div'>,<50000000,'50mS / Div'>,<100000000,'100mS / Div'>
;ScopeRange						SCOPERANGE <15,0,'1mV/Div'>,<30,0,'2mV/Div'>,<76,0,'5mV/Div'>,<152,0,'10mV/Div'>,<305,0,'20mV/Div'>,<762,0,'50mV / Div'>,<1525,0,'100mV / Div'>,<3050,0,'200mV / Div'>,<7625,0,'500mV / Div'>
ScopeRange						SCOPERANGE <160,1,'1mV/Div'>,<320,1,'2mV/Div'>,<800,1,'5mV/Div'>,<1600,1,'10mV/Div'>,<3200,1,'20mV/Div'>,<8000,1,'50mV / Div'>,<1525,0,'100mV / Div'>,<3050,0,'200mV / Div'>,<7625,0,'500mV / Div'>

LgaSample						LGASAMPLE <199999,'1KHz'>,<99999,'2KHz'>,<39999,'5KHz'>,<19999,'10KHz'>,<9999,'20KHz'>,<3999,'50KHz'>,<1999,'100KHz'>,<999,'200KHz'>,<399,'500KHz'>,<199,'1MHz'>,<99,'2MHz'>,<39,'5MHz'>,<19,'10MHz'>,<9,'20MHz'>,<4,'40MHz'>

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

hLcmCld							HWND ?
hLcm							HWND ?

hHscCld							HWND ?
hHsc							HWND ?

hScpScrnCld						HWND ?
hScpScrn						HWND ?
hScpCld							HWND ?
hScp							HWND ?

hDDSScrnCld						HWND ?
hDDSScrn						HWND ?
hDDSCld							HWND ?
hDDS							HWND ?

hLGACld							HWND ?
hLGAScrnCld						HWND ?
hLGAScrn						HWND ?
hMakeWaveScrnCld				HWND ?
hMakeWaveScrn					HWND ?
hMakeWaveCld					HWND ?

hFont							HFONT ?
hIml							HIMAGELIST ?
hGrayIcon						HICON ?
hGreenIcon						HICON ?
hRedIcon						HICON ?

fHoldSampling					DWORD ?
fNoFrequency					DWORD ?
fExitThread						DWORD ?
fThreadDone						DWORD ?

mode							DWORD ?
lcmmode							DWORD ?
LCx								REAL10 ?
lpOldButtonProc					DWORD ?
nBtnCount						DWORD ?

STM32_Cmd						STM32_CMD <>

SampleRate						REAL10 ?
SampleTime						REAL10 ?
SignalPeriod					DWORD ?
SamplesPrPeriod					DWORD ?
STM32_Scp						STM32_SCP <>
scopexofs						DWORD ?
scopeyofs						DWORD ?
ADC_Data						WORD ADCSAMPLESIZE dup(?)
ADC_Tmp							WORD ADCSAMPLESIZE dup(?)
SubSample						DWORD 2048 dup(?)
SubSampleCount					WORD 2048 dup(?)

ddswavedata						DDSWAVEDATA <>
makewavedata					MAKEWAVEDATA <>

LGA_Data						BYTE LGASAMPLESIZE dup(?)
lgaxofs							DWORD ?
transcurpos						DWORD ?
transstart						DWORD ?
transend						DWORD ?
LGA_Text						BYTE 128 dup(?)
transbit						DWORD ?
transrisingedge					DWORD ?
transcount						DWORD ?

wsdata							WSADATA <>
serveraddress					SOCKADDR_BTH <>
client_socket					SOCKET ?
fBluetooth						DWORD ?
tc								DWORD ?
tcadd							DWORD ?
tccount							DWORD ?

;#########################################################################
