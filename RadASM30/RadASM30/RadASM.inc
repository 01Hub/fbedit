
;#########################################################################

;include files
include windows.inc
include gdi32.inc
include user32.inc
include kernel32.inc
include comctl32.inc
include comdlg32.inc
include shell32.inc
include shlwapi.inc
include ole32.inc
include advapi32.inc
include wininet.inc

;libraries
includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib shell32.lib
includelib shlwapi.lib
includelib ole32.lib
includelib advapi32.lib
includelib wininet.lib

include Inc\RAEdit.inc
include Inc\RAHexEd.inc
include Inc\RAGrid.inc
include Inc\RACodeComplete.Inc
include Inc\RAFile.Inc
include Inc\RAProject.inc
include Inc\RAProperty.Inc
include Inc\RAResEd.Inc
include Inc\RATools.Inc
include Addins\Addins.inc

include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

includelib ..\Lib\RACodeComplete.lib
includelib ..\Lib\RAFile.lib
includelib ..\Lib\RAHexEd.lib
includelib ..\Lib\RAProject.lib
includelib ..\Lib\RAProperty.lib
includelib ..\Lib\RAResEd.lib
includelib ..\Lib\RATools.lib

TabProc							PROTO	:HWND,:UINT,:WPARAM,:LPARAM
TabToolActivate					PROTO
MakeMdiCldWin					PROTO	:DWORD,:DWORD
SaveTheFile						PROTO	:HWND
WantToSave						PROTO	:HWND

IDI_MDIICO						equ 100
IDC_SPLICURV					equ 150
IDC_SPLICURH					equ 151
IDB_TBRBMP						equ 152

FILENOTIFYPATH struct
	nCount				DWORD ?
	path				BYTE MAX_PATH dup(?)
FILENOTIFYPATH ends

FILENOTIFY struct
	hThread				HANDLE ?
	lpPath				DWORD ?
	nCount				DWORD ?
	lpHandle			DWORD ?
	lpPtrPth			DWORD ?
FILENOTIFY ends

.const

szMdiClassName					db 'RadASMClass',0
szMdiClientClassName			db 'MDICLIENT',0
szEditCldClassName				db 'MdiEditChild',0
szReBarClassName				db 'ReBarWindow32',0
szComboBoxClassName				db 'ComboBox',0
szToolBarClassName				db 'ToolbarWindow32',0
szStaticClassName				db 'Static',0
szTabControlClassName			db 'SysTabControl32',0

DisplayName						db 'RadASM',0
szBS							db '\',0
szDot							db '.',0
szNULL							db 0

;RadASM.ini
szInifile						db 'RadASM.ini',0
szIniWin						db 'Win',0
szIniPos						db 'Pos',0
szIniPosRes						db 'PosRes',0
szIniFont						db 'Font',0
szIniTool						db 'Tool',0
szIniCode						db 'Code',0
szIniLine						db 'Line',0
szIniText						db 'Text',0
szIniHex						db 'Hex',0
szIniProject					db 'Project',0
szIniProperty					db 'Property',0
szIniOutput						db 'Output',0
szIniTab						db 'Tab',0
szIniReBar						db 'Rebar',0
szIniFile						db 'File',0
szIniPath						db 'Path',0

szDefReBar						db '1,132,123,2,132,199,3,132,193,4,132,47,5,132,101,6,132,1024',0
szNewFile						db '(Untitled)',0

szOpenFileFail					db 'Cannot open the file.',0Dh,0
szWannaSave           			db 'Want to save changes to',0Dh,0

.data

fn								FILENOTIFY <0,fnpath,0,fnhandle,fnptrpth>
ALLFilterString					db 'Assembly Files (*.asm, *.inc, *.rc)',0,'*.asm;*.inc;*.rc',0
								db 'Text Files (*.txt)',0,'*.txt',0
ANYFilterString					db 'All Files (*.*)',0,'*.*',0,0

szCodeFiles						db '.asm.inc.',0
szTextFiles						db '.txt.ini.',0
szHexFiles						db '.obj.res.bmp.ico.cur.',0
szResourceFiles					db '.rc.',0

.data?

osvi							OSVERSIONINFO <?>
fNT								DWORD ?
CommandLine						DWORD ?
ha								ADDINHANDLES <>
da								ADDINDATA <>
mdiID							DWORD ?
;File changed notifications
fnpath							FILENOTIFYPATH MAXIMUM_WAIT_OBJECTS dup(<?>)
fnhandle						DWORD MAXIMUM_WAIT_OBJECTS dup(?)
fnptrpth						DWORD MAXIMUM_WAIT_OBJECTS dup(?)
lpOldTabProc					DWORD ?
tmpbuff							BYTE 16384 dup(?)
