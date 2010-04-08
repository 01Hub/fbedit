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

include Addins\Addins.inc
include Inc\RAEdit.inc
include Inc\RAHexEd.inc
include Inc\RAGrid.inc
include Inc\RACodeComplete.Inc
include Inc\RAFile.Inc
include Inc\RAProject.inc
include Inc\RAProperty.Inc
include Inc\RAResEd.Inc
include Inc\RATools.Inc

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
szNULL							db 0

;RadASM.ini
szIniFile						db 'RadASM.ini',0
szIniWin						db 'Win',0
szIniPos						db 'Pos',0


.data?

osvi							OSVERSIONINFO <?>
fNT								DWORD ?
CommandLine						DWORD ?
ha								ADDINHANDLES <>
da								ADDINDATA <>
