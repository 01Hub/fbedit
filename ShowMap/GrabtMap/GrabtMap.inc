include windows.inc
include user32.inc
include kernel32.inc
include comctl32.inc
include gdi32.inc

includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib
includelib gdi32.lib

include FBEWeb.inc

;#########################################################################
;VKim's Debug

;include masm32.inc
;include Debug.Inc
;includelib masm32.lib
;includelib Debug.lib

IDD_DIALOG				equ 1000
IDC_MAP					equ 1001

IDM_MENU            	equ 10000
IDM_FILE_LAND       	equ 10003
IDM_FILE_SEA        	equ 10004
IDM_FILE_RIGHT      	equ 10006
IDM_FILE_DOWN       	equ 10005
IDM_FILE_LEFTTOP        equ 10009
IDM_FILE_RIGHTBOTTOM    equ 10010
IDM_FILE_START      	equ 10002
IDM_FILE_EXIT       	equ 10001

MAXX					equ 80			;Number of map tiles in X direction
MAXY					equ 64			;Number of map tiles in Y direction

PICX					equ 512			;Left rect position
PICY					equ 160			;Top rect posuition
PICWT					equ 512			;Tile width
PICHT					equ 512			;Tile height

INPUT struct
	ntype				DWORD ?
	dwdx				DWORD ?
	dwdy				DWORD ?
	mouseData			DWORD ?
	dwFlags				DWORD ?
	time				DWORD ?
	dwExtraInfo			DWORD ?
INPUT ends

.const

ClassName				db 'DLGCLASS',0
szDisplayDC				db  "DISPLAY",0
szwb					db 'FBEWeb.dll',0

szUrlLand				db 'http://kart.gulesider.no/query?profile=no&mop=yp&what=map&advert_code=Z000KKXO',0
;szUrlLand				db 'http://maps.google.no/',0
szFileNameLand			db 'Land\Land%02X%02X.bmp',0
szUrlSea				db 'http://kart.gulesider.no/m/p4VdK',0
szFileNameSea			db 'Sea\Sea%02X%02X.bmp',0

.data

mapright				INPUT <INPUT_MOUSE,-2048,-2048,0,MOUSEEVENTF_MOVE,0,0>
maprightmov				INPUT <INPUT_MOUSE,PICX+512,PICY,0,MOUSEEVENTF_MOVE,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_LEFTDOWN,0,0>
						INPUT <INPUT_MOUSE,-512,0,0,MOUSEEVENTF_MOVE,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_LEFTUP,0,0>

mapleft					INPUT <INPUT_MOUSE,-2048,-2048,0,MOUSEEVENTF_MOVE,0,0>
mapleftmov				INPUT <INPUT_MOUSE,PICX,PICY,0,MOUSEEVENTF_MOVE,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_LEFTDOWN,0,0>
						INPUT <INPUT_MOUSE,512,0,0,MOUSEEVENTF_MOVE,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_LEFTUP,0,0>

mapdown					INPUT <INPUT_MOUSE,-2048,-2048,0,MOUSEEVENTF_MOVE,0,0>
mapdownmov				INPUT <INPUT_MOUSE,PICX,PICY+512,0,MOUSEEVENTF_MOVE,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_LEFTDOWN,0,0>
						INPUT <INPUT_MOUSE,0,-512,0,MOUSEEVENTF_MOVE,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_LEFTUP,0,0>

maplefttop				INPUT <INPUT_MOUSE,-2048,-2048,0,MOUSEEVENTF_MOVE,0,0>
maplefttopmov			INPUT <INPUT_MOUSE,PICX,PICY,0,MOUSEEVENTF_MOVE,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_RIGHTDOWN,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_MOVE,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_RIGHTUP,0,0>

maprightbottom			INPUT <INPUT_MOUSE,-2048,-2048,0,MOUSEEVENTF_MOVE,0,0>
maprightbottommov		INPUT <INPUT_MOUSE,PICX+512,PICY+512,0,MOUSEEVENTF_MOVE,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_RIGHTDOWN,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_MOVE,0,0>
						INPUT <INPUT_MOUSE,0,0,0,MOUSEEVENTF_RIGHTUP,0,0>

.data?

hInstance				dd ?
CommandLine				dd ?
hWnd					dd ?
hWeb					dd ?
hLib					dd ?
szurl					db MAX_PATH dup(?)
szfilename				db MAX_PATH dup(?)
