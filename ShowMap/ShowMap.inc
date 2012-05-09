include windows.inc
include user32.inc
include kernel32.inc
include comdlg32.inc
include comctl32.inc
include gdi32.inc
include gdiplus.inc
include gdiplus_structs.inc
include ole32.inc
include oleaut32.inc
include winmm.inc

includelib user32.lib
includelib kernel32.lib
includelib comdlg32.lib
includelib comctl32.lib
includelib gdi32.lib
includelib gdiplus.lib
includelib ole32.lib 
includelib oleaut32.lib 
includelib winmm.lib
includelib STLinkLib.lib 

;#########################################################################
;VKim's Debug

include masm32.inc
include \RadASM30\masm\inc\debug.inc
includelib masm32.lib
includelib \RadASM30\masm\lib\debug.lib

;#########################################################################

STLinkConnect			PROTO hWin:HWND
STLinkDisconnect		PROTO hWin:HWND
STLinkReset				PROTO hWin:HWND
STLinkRead 				PROTO hWin:HWND,rdadr:DWORD,wradr:DWORD,nBytes:DWORD
STLinkWrite				PROTO hWin:HWND,wradr:DWORD,rdadr:DWORD,nBytes:DWORD
FpToAscii				PROTO :DWORD,:DWORD,:DWORD
InitScroll				PROTO

;#########################################################################

IDD_DIALOG              equ 1000
IDC_MAP                 equ 1001
IDC_BTNZOOMIN           equ 1002
IDC_BTNZOOMOUT          equ 1003
IDC_BTNMAP				equ 1019
IDC_CHKPAUSEGPS			equ 1013
IDC_CHKLOCK				equ 1007
IDC_CHKTRAIL			equ 1008
IDC_CHKGRID				equ 1014
IDC_CHKSHOWSAT			equ 1024
IDC_CHKSHOWNMEA			equ 1027
IDC_CBOGOTOPLACE        equ 1004
IDC_EDTNORTH            equ 1005
IDC_EDTEAST             equ 1006
IDC_EDTDIST				equ 1009
IDC_STCLAT              equ 1010
IDC_STCLON              equ 1011
IDC_STCDIST             equ 1012
IDC_STCBEAR				equ 1016
IDC_EDTBEAR				equ 1015

IDD_DLGADDPLACE         equ 1100
IDC_EDTNAME             equ 1101
IDC_EDTLONGITUDE        equ 1102
IDC_EDTLATTITUDE        equ 1103
IDC_CBOFONT             equ 1104
IDC_CBOICON             equ 1105
IDC_BTNGPS              equ 1106
IDC_TRBZOOM             equ 1107
IDC_SHP3				equ 1018
IDC_CHKCHART			equ 1033
IDC_BTNRANGEDN			equ 1021
IDC_BTNRANGEUP			equ 1020
IDC_CHKAUTORANGE		equ 1022
IDC_LSTNMEA				equ 1025
IDC_CHKZOOM				equ 1026
IDC_CHKCURSOR			equ 1028

IDM_MENU                equ 10000
IDM_FILE_OPENTRIP       equ 10010
IDM_FILE_SAVETRIP       equ 10011
IDM_FILE_OPENDIST       equ 10014
IDM_FILE_SAVEDIST       equ 10015
IDM_FILE_OPENTRAIL      equ 10012
IDM_FILE_SAVETRAIL      equ 10013
IDM_FILE_EXIT           equ 10001
IDM_OPTION_SPEED        equ 10002
IDM_OPTION_BATTERY      equ 10003
IDM_OPTION_AIRTEMP      equ 10004
IDM_OPTION_SCALE		equ 10009
IDM_OPTION_TIME			equ 10016
IDM_OPTION_RANGE		equ 10020
IDM_OPTIO_DEPTH			equ 10019
IDM_OPTION_WATERTEMP	equ 10021
IDM_OPTION_SONAR		equ 10025
IDM_OPTION_GAIN			equ 10018
IDM_OPTION_SONARCOLOR	equ 10026
IDM_OPTION_GPS			equ 10008
IDM_LOG_START           equ 10005
IDM_LOG_END             equ 10006
IDM_LOG_REPLAY          equ 10007
IDM_LOG_CLEARTRAIL		equ 10017
IDM_LOG_STARTSONAR		equ 10022
IDM_LOG_ENDSONAR		equ 10023
IDM_LOG_REPLAYSONAR		equ 10024

IDM_CONTEXT             equ 11000
IDM_EDITPLACE           equ 11001
IDM_ADDPLACE            equ 11002
IDM_TRIPPLANNING        equ 11003
IDM_DISTANCE            equ 11004
IDM_FULLSCREEN			equ 11017
IDM_TRIP_DONE           equ 11005
IDM_TRIP_SAVE           equ 11006
IDM_TRIP_EDIT           equ 11011
IDM_TRIP_CLEAR          equ 11007
IDM_TRIP_INSERT         equ 11013
IDM_TRIP_DELETE         equ 11014
IDM_DIST_DONE           equ 11008
IDM_DIST_SAVE           equ 11009
IDM_DIST_EDIT           equ 11012
IDM_DIST_CLEAR          equ 11010
IDM_DIST_INSERT         equ 11015
IDM_DIST_DELETE         equ 11016
IDM_SONARCLEAR			equ 11018
IDM_SONARPAUSE			equ 11019
IDM_GPS_HIDE			equ 11022
IDM_GPS_PAUSE			equ 11020
IDM_GPS_SAVE			equ 11021
IDM_GPS_CLEAR			equ 11023

IDR_ACCEL				equ 1

;Map constants
MAXBMP					equ 512*2							;Max number of bitmaps to cache
MAXPLACES				equ 256								;Max number of places
MAXZOOM					equ 32								;Max number of zoom definitions
MAXFONT					equ 16								;Max number of font definitions
MAXTRIP					equ 1024							;Max number of trip positions
MAXTRAIL				equ 2048							;Max number of trail positions
MAXDIST					equ 256								;Max number of distance calculation poins
MAXMAPOPTION			equ 5								;Max number of overlays on map scteen
MAXSONAROPTION			equ 3								;Max number of overlays on sonar scteen

LONPOINT struct
	iLon			DWORD ?									;Longitude
	ixpos			DWORD ?									;Map x position
LONPOINT ends

LATPOINT struct
	iLat			DWORD ?									;Lattitude
	iypos			DWORD ?									;Map y position
LATPOINT ends

BMP struct
	inuse			DWORD ?									;The tile is still needed
	mapinx			DWORD ?									;Used in folder name to jpegs
	nx				DWORD ?									;Number x, used in filename
	ny				DWORD ?									;Number y, used in filename
	hBmp			HBITMAP ?								;Bitmap handle
BMP ends

PLACE struct
	font			DWORD ?									;Index of font, 0 (no font) or 1 to 6
	icon			DWORD ?									;Index of icon, 0 (no icon) or 1 to 16
	zoom			DWORD ?									;Minimum zoom level to plot text
	iLon			DWORD ?									;Longitude
	iLat			DWORD ?									;Lattitude
	ptmap			POINT <>								;Map coordinate
	text			BYTE 32 dup(?)							;Name of place
PLACE ends

ZOOM struct
	zoomval			DWORD ?									;Current zoom value
	mapinx			DWORD ?									;Used in folder name to jpegs
	scalem			DWORD ?									;Scale in meters
	text			BYTE 16 dup(?)							;Scale bar text
	nx				DWORD ?									;Number of x-jpegs in current zoom
	ny				DWORD ?									;Number of y-jpegs in current zoom
	xPixels			DWORD ?									;Width of map in pixels
	yPixels			DWORD ?									;Height of map in pixels
	xMeters			DWORD ?									;Width of map in meters
	yMeters			DWORD ?									;Height of map in meters
ZOOM ends

OPTIONS struct
	show			DWORD ?									;Show on map screen
	position		DWORD ?									;Position on map screen
	pt				POINT <>								;Offset from left/right and top/bottom
	font			DWORD ?									;Index of font (1 to 6)
	text			BYTE 16 dup(?)							;Text to plot on map screen
OPTIONS ends

LOG struct
	iLon			DWORD ?									;Longitude
	iLat			DWORD ?									;Lattitude
	iBear			DWORD ?									;Bearing
	iTime			DWORD ?									;Dos time
LOG ends

MAP struct
	zoomval			DWORD ?									;Current zoom value
	mapinx			DWORD ?									;Used in folder name to map jpegs
	topx			DWORD ?									;Upper left, unzoomed
	topy			DWORD ?									;Upper top, unzoomed
	mapwt			DWORD ?									;Current width of map screen
	mapht			DWORD ?									;Current height of map screen
	ncursor			DWORD ?									;The index of the bearing cursor (0 to 7)
	fcursor			DWORD ?									;If TRUE cursor is visible (used to make the cursor blink)
	cursorx			DWORD ?									;Cursor x position
	cursory			DWORD ?									;Cursor y position
	paintnow		DWORD ?									;Force a repaint counter

	zoominx			DWORD ?									;Current index of the ZOOM array
	zoommax			DWORD ?									;Index to first free ZOOM
	hDC				HDC ?									;Map window DC
	mDC				HDC ?									;Memory DC
	mDC2			HDC ?									;Memory DC
	tDC				HDC ?									;Used to draw a single tile onto mDC
	hmBmpOld		HBITMAP ?								;Original  bitmap in mDC
	hmBmpOld2		HBITMAP ?								;Original  bitmap in mDC2
	cxs				DWORD ?									;Screen x-size
	cys				DWORD ?									;Screen y-size
	nx				DWORD ?									;Number of x-jpegs in current zoom
	ny				DWORD ?									;Number of y-jpegs in current zoom
	xPixels			DWORD ?									;Width of map in pixels
	yPixels			DWORD ?									;Height of map in pixels
	xMeters			DWORD ?									;Width of map in meters
	yMeters			DWORD ?									;Height of map in meters
	iLon			DWORD ?									;Longitude
	iLat			DWORD ?									;Lattitude
	gpslogpause		DWORD ?									;TRUE if 'Pause Log' is checked
	gpslock			DWORD ?									;TRUE if 'Lock to GPS' is checked
	gpstrail		DWORD ?									;TRUE if 'Show Trail' is checked
	mapgrid			DWORD ?									;TRUE if 'Show Grid' is checked
	place			PLACE MAXPLACES dup(<>)					;Places definitions
	freeplace		DWORD ?									;Index to first emty place
	zoom			ZOOM MAXZOOM dup(<>)					;Zoom definitions
	font			HFONT MAXFONT dup(?)					;Font handles
	options			OPTIONS MAXMAPOPTION dup(<>)			;Options for overlays on map screen
	btrip			DWORD ?									;Trip planning flag, 0 not active, 1 active, 2 done, 3 edit
	triphead		DWORD ?									;Head index in trip array
	trip			LOG MAXTRIP dup(<>)						;Trip array
	ntrail			DWORD ?									;Number of trail points
	trailhead		DWORD ?									;Head index in trail array
	trailtail		DWORD ?									;Tail index in trail array
	trail			LOG MAXTRAIL dup(<>)					;Trail array
	bdist			DWORD ?									;Distance measure flag, 0 not active, 1 active, 2 done, 3 edit
	disthead		DWORD ?									;Head index in distance array
	dist			LOG MAXDIST dup(<>)						;Distance array
	iBear			DWORD ?									;Bearing
	iSpeed			DWORD ?									;Speed in kts
	iTime			DWORD ?									;Dos time
	onpoint			DWORD ?									;Point index, -1 if not on point
	fSumDist		REAL10 ?								;The sum of a distance calculation
	nLonPoint		DWORD ?									;Number of longitude entries in array
	hMemLon			HGLOBAL ?								;Longitude array
	nLatPoint		DWORD ?									;Number of lattitude entries in array
	hMemLat			HGLOBAL ?								;Lattitude array
	TrackSmooth		DWORD ?									;Minimum speed to add a trail point
	TrailRate		DWORD ?									;Number of seconds between trail points
	TrailCount		DWORD ?									;TrailRate down counter
	fShowNMEA		DWORD ?									;If TRUE NMEA log window is shown
	fSTLink			DWORD ?									;If TRUE internal GPS module is present
	GPSInit			DWORD ?									;If TRUE GPS initialization is performed
	GPSReset		DWORD ?									;If TRUE GPS initialization icludes factory reset command
MAP ends

SATELITE struct
	SatelliteID		BYTE ?									;Satelite ID
	Elevation		BYTE ?									;Elevation in degrees (0-90)
	Azimuth			WORD ?									;Azimuth in degrees (0-359)
	SNR				BYTE ?									;Signal strenght	(0-50, 0 not tracked) 
	Fixed			BYTE ?									;TRUE if used in fix
SATELITE ends

ALTITUDE struct
	fixquality		BYTE ?									;Fix quality
	nsat			BYTE ?									;Number of satelites tracked
	hdop			WORD ?									;Horizontal dilution of position * 10
	vdop			WORD ?									;Vertical dilution of position * 10
	pdop			WORD ?									;Position dilution of position * 10
	alt				WORD ?									;Altitude in meters
ALTITUDE ends

;STM32 constants
STM32_Sonar				equ 20000000h						;STM32 ram address
STM32_Clock				equ 40000000						;STM32 clock frequency
STM32_PingTimer			equ (STM32_Clock/200000/2)-1		;Default ping timer

;Sonar constants
MAXXECHO				equ 512								;Max number of sonar X-echos
MAXYECHO				equ 512								;Max number of sonar Y-echos
RANGESCALE				equ 5								;Width of range scale
SCROLLWT				equ 18								;Width / height of scrollbar
MAXRANGE				equ 32								;Max number of depth ranges that can be read from ini
REPLAYSPEED				equ 5								;At replay, the ping interval is divided by REPLAYSPEED
MAXFISH					equ 64								;Prevents showing repeated fish symbols and repeated fish alarms
MAXSONARBMP				equ 64								;Max number of bitmap tiles, for each range change a tile is created
SOUNDSPEEDMIN			equ 1400							;Minimum speed of sound in water
SOUNDSPEEDMAX			equ 1550							;Maximum speed of sound in water
SMALLFISHECHO			equ 96								;Minimum echo to detect small fish
LARGEFISHECHO			equ SMALLFISHECHO+64				;Minimum echo to detect large fish
MAXDEPTHJUMP			equ 10								;Max number of pixels to jump on depth detection
MAXPING					equ 128								;Max number of ping pulses

SONARBMP struct
	hBmp			HBITMAP ?								;Bitmap handle
	RangeInx		DWORD ?									;Range index
	xpos			DWORD ?									;X-Position
	wt				DWORD ?									;Width
SONARBMP ends

FISH struct
	fishtype		DWORD ?									;17=small fish, 18=large fish
	xpos			DWORD ?									;X position
	depth			DWORD ?									;Depth in meters*10
FISH ends

RANGE struct
	range			DWORD ?									;Range in meters
	interval		DWORD ?									;Update rate
	pixeltimer		DWORD ?									;Pixel timer value
	pingadd			DWORD ?									;Number of pulses to add to the initial ping (0 to 128). Used when autoping is on
	nticks			DWORD ?									;Number of ticks on the range scale
	scale			BYTE 64 dup(?)							;Zero terminated strings of depths on range scale
	gain			DWORD 17 dup(?)							;Gain increment levels read from ini file
RANGE ends

SONAR struct
	fSTLink			DWORD ?									;If TRUE STLink connected
	mDC				HDC ?									;The memory DC holds the echo bitmap, 512*512 pixels,
	hBmp			HBITMAP ?								;Handle of the bitmap used in mDC to draw echo
	hBmpOld			HBITMAP ?								;Handle of the original bitmap in mDC
	mDCS			HDC ?									;The memory DC holds the echo strenght bitmap, 32*512 pixels,
	hBmpS			HBITMAP ?								;Handle of the bitmap used in mDCS to draw echo strenght
	hBmpOldS		HBITMAP ?								;Handle of the original bitmap in mDCS
	hBrBack			HBRUSH ?								;Handle of bacckground brush
	hPen			HPEN ?									;Handle of signalbar pen
	hPenOld			HPEN ?									;Handle of the original pen in mDCS
	hReplay			HANDLE ?								;Handle of replay file
	hLog			HANDLE ?								;Handle of log file
	wt				DWORD ?									;Width of sonar screen
	options			OPTIONS MAXSONAROPTION dup(<>)			;Options for overlays on sonar screen
	AutoRange		DWORD ?									;If TRUE autorange is on
	AutoGain		DWORD ?									;If TRUE gain is set according to range
	AutoPing		DWORD ?									;If TRUE number of pingpulses is set according to range
	NoiseReject		DWORD ?									;If TRUE 2 adjacent pixels needed to show echo
	FishDetect		DWORD ?									;If TRUE fish detect is on
	FishAlarm		DWORD ?									;If TRUE fish alarm is on
	FishDepth		DWORD ?									;If TRUE fish depth is shown
	ChartSpeed		DWORD ?									;Sonar chart scroll speed.
	SoundSpeed		DWORD ?									;Speed of sound in water
	MaxRange		DWORD ?									;Number of range definitions read from ini
	RangeVal		DWORD ?									;Range in meters
	ShowDepth		DWORD ?									;Bit 0 depth on/off, Bit 1 blink depth if echo is lost
	Battery			DWORD ?									;Current battery
	WTemp			DWORD ?									;Current water surface temprature
	ATemp			DWORD ?									;Current air temprature
	PingInit		DWORD ?									;Ping initial value (0 to 128)
	GainSet			DWORD ?									;Gain set level (0 to 4095)
	NoiseLevel		DWORD ?									;Noise level (0 to 255)
	minyecho		DWORD ?									;Ping and surface clutter skipped
	nodptinx		DWORD ?									;Depth not found
	dptinx			DWORD ?									;Index in echo array
	fishinx			DWORD ?									;Current index in fishdata array
	fishdata		FISH MAXFISH dup(<>)					;Array of fish detected
	fFishSound		DWORD ?									;Countdown to avoid repeated fish sounds
	szFishSound		BYTE MAX_PATH dup(?)					;Path & filename of fish.wav file
	fGainUpload		DWORD ?									;If TRUE gain levels must be uploaded
	sonarbmp		SONARBMP MAXSONARBMP dup(<>)			;Array of bitmap tiles
	gainofs			DWORD ?									;Initial gain for gain calculations
	gainmax			DWORD ?									;Max gain for gain calculations
	gaindepth		DWORD ?									;Dept at max gain
	sonarrange		RANGE MAXRANGE dup(<?>)					;Sonar range definitions (max 32)
	struct
		Start			BYTE ?								;Set to 1 to init a new ping and echo reading
		PingPulses		BYTE ?								;Number of pulses in a ping (0 to 128)
		PingTimer		BYTE ?								;Timer value to generate 200 KHz ping
		RangeInx		BYTE ?								;Range index (0 to 31)
		PixelTimer		WORD ?								;Pixel timer value
		PingWait		WORD ?								;Ping wait loop
		ADCBattery		WORD ?								;Battery level
		ADCWaterTemp	WORD ?								;Water temprature
		ADCAirTemp		WORD ?								;Air temprature
		GPSHead			WORD ?								;Incremented when GPS array valid
		EchoArray		BYTE MAXYECHO dup(?)				;Echo array, processed using STM32Echo
		GainArray		WORD MAXYECHO dup(?)				;Gain array. Not downloaded or uploaded it is calculated by STM32 using GainInit
		GainInit		WORD 18 dup(?)						;First word is initial gain, next words is gain increment
		GPSArray		BYTE 512 dup(?)						;GPS array, read from STM32 if GPSHead <> GPSTail
	ends
	SignalBarWt		DWORD ?									;Width of signal bar
	fShowSat		DWORD ?									;If TRUE satelites window is shown
	zoom			DWORD ?									;If TRUE sonar zoom is on
	zoomofs			DWORD ?									;zoom offset from top
	cursor			DWORD ?									;If TRUE depth cursor is shown
	cursorpos		DWORD ?									;Position of depth cursor
	sonarcolor		DWORD 18 dup(?)							;Color definitions
	PaintNow		DWORD ?									;If TRUE sonar screen is updated
SONAR ends

SONARREPLAY struct
	Version			BYTE ?									;201
	PingPulses		BYTE ?									;Number of pulses in a ping (0 to 128)
	GainSet			WORD ?									;Gain set level (0 to 4095)
	SoundSpeed		WORD ?									;Speed of sound in water
	ADCBattery		WORD ?									;Battery level
	ADCWaterTemp	WORD ?									;Water temprature
	ADCAirTemp		WORD ?									;Air temprature
	iTime			DWORD ?									;UTC Dos file time. 2 seconds resolution
	iLon			DWORD ?									;Longitude, integer
	iLat			DWORD ?									;Lattitude, integer
	iSpeed			WORD ?									;Speed in kts
	iBear			WORD ?									;Degrees
SONARREPLAY ends

.const

dd256				DWORD 256
dd512				DWORD 512
dd72				DWORD 72

szMainClassName		BYTE 'DLGCLASS',0						;Window class for main window
szMapClassName		BYTE 'MAPCLASS',0						;Window class for map window
szSonarClassName	BYTE 'SONARCLASS',0						;Window class for sonar window
szGPSClassName		BYTE 'GPSCLASS',0						;Window class for GPS window
szAppName			BYTE 'Navigation',0						;Application name

szAskSaveTrail		BYTE 'Save current trail?',0			;Messagebox string
szAskOverwrite		BYTE 'Overwrite existing file?',0Dh,0Ah,0
szAskDelete			BYTE 'Delete file?',0Dh,0Ah,0

szLandFileName		BYTE '%s\Map\LandX%d\Land%02X%02X.jpg',0;Format string to get map tile path & filename
szSeaFileName		BYTE '%s\Map\SeaX%d\Sea%02X%02X.jpg',0	;Format string to get map tile path & filename

szNULL				BYTE 0
szBS				BYTE '\',0
szCRLF				BYTE 0Dh,0Ah,0

szIniFile			BYTE 'ShowMap.ini',0					;File name of ini file
szFishWav			BYTE '\Wav\fish.wav',0					;File name of fish alarm

szIniWin			BYTE 'Win',0							;Ini file app / key
szIniMap			BYTE 'Map',0
szIniMapRect		BYTE 'MapRect',0
szIniLatArray		BYTE 'LatArray',0
szIniPlace			BYTE 'Place',0
szIniPos			BYTE 'Pos',0
szIniZoom			BYTE 'Zoom',0
szIniFont			BYTE 'Font',0
szIniOption			BYTE 'Option',0
szIniSonar			BYTE 'Sonar',0
szIniSonarRange		BYTE 'SonarRange',0
szIniSonarColor		BYTE 'SonarColor',0
szIniGainDef		BYTE 'GainDef',0
szIniGPS			BYTE 'GPS',0

szFonts				BYTE 'None',0							;Font selection descriptions
					BYTE 'Small',0
					BYTE 'Small, Bold',0
					BYTE 'Medium',0
					BYTE 'Medium, Bold',0
					BYTE 'Large',0
					BYTE 'Large, Bold',0,0

szIcons				BYTE 'None',0							;Icon selection descriptions
					BYTE 'Waypoint, start',0
					BYTE 'Waypoint, middle',0
					BYTE 'Waypoint, end',0
					BYTE 'Cross',0
					BYTE 'City',0
					BYTE 'Building, small',0
					BYTE 'Building, large',0
					BYTE 'Light house',0
					BYTE 'Shallow',0
					BYTE 'Fish, small',0
					BYTE 'Fish, large',0
					BYTE 'Filled square',0
					BYTE 'Yellow dot',0
					BYTE 'Green dot',0
					BYTE 'Red dot',0
					BYTE 'Blue dot',0,0

szFmtDec			BYTE '%d',0
szFmtDec2			BYTE '%02d',0
szFmtDec3			BYTE '%03d',0
szFmtDec10			BYTE '%010d',0
szFmtVolts			BYTE '%02u',0
szVolts				BYTE 'V',0

szCelcius			BYTE 'C',0
watertempoffset		DWORD 1750
watertempconv		REAL8 5.25
airtempoffset		DWORD 2485
airtempconv			REAL8 5.60

szGPSDemoData		BYTE '$GPRMC,193409,A,6619.0367,N,01411.8237,E,0.0,356.4,230710,2.0,E',0Dh,0Ah
					BYTE '$GPGGA,193409,6619.0367,N,01411.8237,E,1,5,1.10,57,M,,,,',0Dh,0Ah
					BYTE '$GPGSV,3,1,12,21,64,118,40,6,53,259,,16,52,213,,3,38,272,',0Dh,0Ah
					BYTE '$GPGSV,3,2,12,18,29,140,36,24,27,216,40,7,24,329,38,26,13,59,38',0Dh,0Ah
					BYTE '$GPGSV,3,3,12,5,13,27,,29,12,108,,19,10,275,,15,9,76,',0Dh,0Ah
					BYTE '$GPGSA,A,3,21,,,,18,24,7,26,,,,,2.5,1.1,2.2',0Dh,0Ah,0

szGPSInitData		BYTE '$PSRF103,00,00,05,00*XX',0Dh,0Ah	;Enable GGA message, rate 5 seconds
					BYTE '$PSRF103,02,00,05,00*X',0Dh,0Ah	;Enable GSA message, rate 5 seconds
					BYTE '$PSRF103,03,00,05,00*X',0Dh,0Ah	;Enable GSV message, rate 5 seconds
					BYTE '$PSRF103,04,00,01,00*XX',0Dh,0Ah	;Enable RMC message, rate 1 second
					BYTE '$PSRF103,01,00,00,00*XX',0Dh,0Ah	;Disable GLL message
					BYTE '$PSRF103,05,00,00,00*XX',0Dh,0Ah	;Disable VTG message
					BYTE 0
szGPSReset			BYTE '$PSRF104,66.307350,14.135830,0,96000,237759,922,12,4*XX',0Dh,0Ah
					BYTE 0

szDefSonarColors	BYTE '16777215,12632256,10658466,8421504,65535,61680,54741,52942,45824,42496,40704,38400,255,242,223,215,8388608,16039276',0

.data?

hInstance			HINSTANCE ?								;Instance handle
CommandLine			DWORD ?									;Pointer to command line
gdiplSTI			GdiplusStartupInput <>					;Gdi+ structure
token				DWORD ?									;Gdi+ token
hWnd				HWND ?									;Handle of main window
hMap				HWND ?									;Handle of map screen
hSonar				HWND ?									;Handle of sonar screen
hGPS				HWND ?									;Handle of GPS screen
hMenu				HMENU ?									;Hamdle of menu
hContext			HMENU ?									;Hamdle of context menu
hAccel				HACCEL ?								;Handle of accelerator table
hIml				HIMAGELIST ?							;Imagelist handle
szAppPath			BYTE MAX_PATH dup(?)					;Application path
mapdata				MAP <>									;Map data
mousept				POINT <>								;Point where lbutton clicked
mousemappt			POINT <>
bmpcache			BMP MAXBMP dup(<>)						;Cached bitmaps
hMAPThread			HANDLE ?								;Map drawing thread
fExitMAPThread		DWORD ?									;Flag to exit the map drawing thread
hGPSThread			HANDLE ?								;Thread to comunicate with GPS
fExitGPSThread		DWORD ?									;Flag to exit the GPSThread
hSTMThread			HANDLE ?								;Thread to comunicate with STM32
fExitSTMThread		DWORD ?									;Flag to exit the STMThread
szIniFileName		BYTE MAX_PATH dup(?)					;Path and filename of ini file
szbuff				BYTE 512 dup(?)							;Temporary buffer
tid					DWORD ?									;Thread ID
sonardata			SONAR <>								;Sonar data
altitude			ALTITUDE <>								;GGA message info
satelites			SATELITE 12 dup(<>)						;Data for 12 satelites
hSplittV			HCURSOR ?								;Horizontal splitt cursor
rseed				DWORD ?									;Random seed
STM32Echo			BYTE MAXYECHO*4 dup(?)					;Echo work area
sonarreplay			SONARREPLAY <>							;Sonar replay record version 201
lpOldButtonProc		DWORD ?									;Button subclass
fSeaMap				DWORD ?									;If TRUE sea map is shown
szFileName			BYTE MAX_PATH dup(?)					;Format string to get map tile path & filename
winrect				RECT <>									;Main window rectangle
fMaximize			DWORD ?									;Main window maximized
CustColors			DWORD 16 dup(?)							;Custom colors
