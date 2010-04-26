
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
MakeMdiCldWin					PROTO	:DWORD
SaveTheFile						PROTO	:HWND
WantToSave						PROTO	:HWND
SetHiliteWords					PROTO	:DWORD,:DWORD
OpenTheFile						PROTO	:DWORD,:DWORD
TabToolGetInx					PROTO	:DWORD
TabToolGetInxFromPid			PROTO	:DWORD
OpenProject						PROTO
CloseProject					PROTO
GetTheFileType					PROTO	:DWORD

RadASMVersion					equ 3000

CCTYPE_NONE						equ 0
CCTYPE_PROC						equ 1
CCTYPE_TOOLTIP					equ 2
CCTYPE_CONST					equ 3
CCTYPE_ALL						equ 4
CCTYPE_STRUCT					equ 5

IDI_MDIICO						equ 100
IDC_SPLICURV					equ 150
IDC_SPLICURH					equ 151
IDB_TBRBMP						equ 152

MAX_MISS						equ 10
START_FILES						equ 1
MAX_FILES						equ 1000

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

DECLARE struct
	hWin				HWND ?
	cp					DWORD ?
DECLARE ends

.const

szMdiClassName					db 'RadASMClass',0
szMdiClientClassName			db 'MDICLIENT',0
szEditCldClassName				db 'MdiEditChild',0
szReBarClassName				db 'ReBarWindow32',0
szComboBoxClassName				db 'ComboBox',0
szToolBarClassName				db 'ToolbarWindow32',0
szStaticClassName				db 'Static',0
szTabControlClassName			db 'SysTabControl32',0
szRichEdit						db 'riched20.dll',0

DisplayName						db 'RadASM',0
szBS							db '\',0
szPipe							db '|',0
szDot							db '.',0
szComma							db ',',0
szQuote							db '"',0
szSemi							db ';',0
szDotIni						db '.ini',0
szDotRapr						db '.rapr',0
szDotRaprDot					db '.rapr.',0
szBSApiBS						db '\Api\',0
szSpc							db ' ',0
szCr							db VK_RETURN,0
szNULL							db 0
szDefFilter						db '.asm.inc.rc.rapr.',0
szPROTO							db ' PROTO',0
szMasm							db 'masm',0
szError							db ': error ',0

;Code properties
szCCPp							db 'Pp',0
szCCp							db 'p',0
szCCC							db 'C',0
szCCAll							db 'WScdsm',0
szCCSs							db 'Ss',0
szCCd							db 'd',0
szCCAssume						db 'assume ',0
szCaseTypes						db 'WPMpcm',0
szGotoTypes						db 'pldcs',0
szMsg1							db 'SendMessage',0
szMsg2							db 'PostMessage',0
szMsg3							db 'SendDlgItemMessage',0

;RadASM.ini
szInifile						db 'RadASM.ini',0
szIniAppPath					db 'AppPath',0
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
szIniLock						db 'Lock',0
szIniSession					db 'Session',0
szIniPath						db 'Path',0
szIniAssembler					db 'Assembler',0
szIniKeywords					db 'Keywords',0
szIniColors						db 'Colors',0
szIniCodeBlock					db 'CodeBlock',0
szIniCmnt						db 'Cmnt',0
szIniEdit						db 'Edit',0
szIniBraceMatch					db 'BraceMatch',0
szIniOption						db 'Option',0
szIniParse						db 'Parse',0
szIniType						db 'Type',0
szIniIgnore						db 'Ignore',0
szIniDef						db 'Def',0
szIniFile						db 'File',0
szIniResource					db 'Resource',0
szIniCodeComplete				db 'CodeComplete',0
szIniTrig						db 'Trig',0
szIniInc						db 'Inc',0
szIniLib						db 'Lib',0
szIniApi						db 'Api',0
szIniFilter						db 'Filter',0
szIniGroup						db 'Group',0
szIniOpen						db 'Open',0
szIniVersion					db 'Version',0
szIniTheme						db 'Theme',0
szIniCustCtrl					db 'CustCtrl',0
szIniCustStyle					db 'CustStyle',0
szIniCustType					db 'CustType',0
szIniMake						db 'Make',0
szIniHelp						db 'Help',0
szIniEnvironment				db 'Environment',0
szIniHeader						db 'Header',0

szDefReBar						db '1,132,123,2,132,199,3,132,193,4,132,47,5,132,101,6,132,1024',0
szNewFile						db '(Untitled)',0

szOpenFileFail					db 'Cannot open the file.',0Dh,0
szWannaSave           			db 'Want to save changes to',0Dh,0
szFileChanged					db 'The file is changed. Continue?',0Dh,0
szRadASMVersion					db 'The RadASM.ini file is an older version or is missing.',0Dh,0
szProjectVersion				db 'The project file is an older version.',0
szAssemblerVersion				db 'The Assembler.ini file is an older version or is missing.',0Dh,0
szNoMain						db 'No main file selected.',0Dh,0
szErrDir						db 'Could not create directory!',0Dh,0
szErrOpenDir					db 'Could not open directory!',0Dh,0
szErrOverwrite					db 'Overwrite existing file?',0Dh,0
szErrCreate						db 'Could not create the file!',0Dh,0

szAddNewProjectFile				db 'Add New File To Project',0
szAddExistingProjectFiles		db 'Add Existing Files To Project',0

defcol							dd 00800040h,00800040h,00800040h,00800040h,00800040h,10800040h,00800040h,00800040h,01800040h,00800040h,00800040h,00800040h,00800040h,00800040h,00800040h,00800040h
								dd 00FFFFFFh,00000000h,00800000h,00FFFFFFh,02008000h,00A00000h,000000A0h,00F0C0C0h,00C0F0C0h,00C0C0F0h,00E0E0E0h,00808080h,00800000h,00808080h,00FFFFFFh,00FFFFFFh,00FFFFFFh,00FFFFFFh,0000F0F0h,0000F000h
								dd 00FFFFFFh,00000000h,00FFFFFFh,00000000h,00804000h,00C00000h,00FFFFFFh,00000000h,00C0F0F0h,00000000h,00404080h,00FF0000h

szDefCODEString					db 'Assembly Files (*.asm; *.inc)|*.asm;*.inc',0
szDefRESString					db 'Resource Files (*.rc)|*.rc',0
szDefTXTString					db 'Text Files (*.txt)|*.txt',0
szDefANYString					db 'All Files (*.*)|*.*',0
szDefPROString					db 'Project Files (*.rapr)|*.rapr',0

.data

fn								FILENOTIFY <0,fnpath,0,fnhandle,fnptrpth>

.data?

osvi							OSVERSIONINFO <>
fNT								DWORD ?
CommandLine						DWORD ?
icex							INITCOMMONCONTROLSEX <>
ha								ADDINHANDLES <>
da								ADDINDATA <>
mdiID							DWORD ?
;File changed notifications
fnpath							FILENOTIFYPATH MAXIMUM_WAIT_OBJECTS dup(<?>)
fnhandle						DWORD MAXIMUM_WAIT_OBJECTS dup(?)
fnptrpth						DWORD MAXIMUM_WAIT_OBJECTS dup(?)
lpOldTabProc					DWORD ?
tmpbuff							BYTE 24*1024 dup(?)
LineTxt							BYTE 24*1024 dup(?)
lpOldClientProc					DWORD ?
lpOldRAEditCodeProc				DWORD ?
hRichEd							DWORD ?
ttmsg							MESSAGE <>
tt								TOOLTIP <>
gotostack						DECLARE 32 dup(<?>)
hEnv							HGLOBAL ?
