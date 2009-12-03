
include windows.inc
include kernel32.inc
include user32.inc
include Comctl32.inc
include Comdlg32.inc
include gdi32.inc
include shell32.inc
include gdiplus.inc
include gdiplus_structs.inc

includelib kernel32.lib
includelib user32.lib
includelib Comctl32.lib
includelib Comdlg32.lib
includelib gdi32.lib
includelib shell32.lib
includelib gdiplus.lib

include masm32.inc
include Debug.Inc
includelib masm32.lib
includelib Debug.lib

DlgProc				PROTO	:HWND,:UINT,:WPARAM,:LPARAM

IDD_DIALOG1			equ 101

.const

JPGFilterString		db 'Picture (*.jpg)',0,'*.jpg',0,0
DefJpgExt			db 'jpg',0

;#########################################################################

;Res\SizePictureRes.rc
IDB_BLACK						equ 100

;SizePicture.dlg
IDD_DIALOG1						equ 101
IDC_IMG1						equ 1001
IDC_EDTSOURCE					equ 1002
IDC_BTNSOURCE					equ 1003
IDC_BTNDEST						equ 1004
IDC_EDTDEST						equ 1005
IDC_EDTINDEX					equ 1006
IDC_BTNCONVERT					equ 1007

;SizePicture.mnu
IDR_MENU						equ 10000
IDM_FILE_OPEN					equ 10001
IDM_FILE_SAVE					equ 10002
IDM_FILE_EXIT					equ 10003

szBrowse			db 'Browse For Folder',0
szBackSlash			db '\',0
szJPG				db '*.jpg',0
szFmt				db '\%d.jpg',0

.data?

hInstance			dd ?
OpenFileName		db MAX_PATH dup(?)
DestPath			db MAX_PATH dup(?)
SaveFileName		db MAX_PATH dup(?)
Temp				db MAX_PATH dup(?)
Inx					dd ?
pidl				dd ?
bri					BROWSEINFO <?>
wfd					WIN32_FIND_DATA <?>


;#########################################################################
