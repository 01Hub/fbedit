;Messages
RPBM_SETPATH			equ WM_USER+1	;wParam=FALSE/TRUE(Refresh), lParam=Pointer to path string
RPBM_GETPATH			equ WM_USER+2	;wParam=cbSize, lParam=Pointer to path string
RPBM_SETFILEEXT			equ WM_USER+3	;wParam=FALSE/TRUE(Refresh), lParam=Pointer to array of PBFILEEXTs
RPBM_GETFILEEXT			equ WM_USER+4	;wParam=0, lParam=0 Returns pointer to array of PBFILEEXTs
RPBM_SETITEMS			equ WM_USER+5	;wParam=FALSE/TRUE(Refresh), lParam=Pointer to array of PBITEMs
RPBM_GETITEMS			equ WM_USER+6	;wParam=0, lParam=0 Returns pointer to array of PBITEMs
RPBM_SETGROUPING		equ WM_USER+7	;wParam=FALSE/TRUE(Refresh), lParam=1,2 or 3
RPBM_GETGROUPING		equ WM_USER+8	;wParam=0, lParam=0
RPBM_SETSELECTED		equ WM_USER+9	;wParam=0, lParam=lpFile
RPBM_GETSELECTED		equ WM_USER+10	;wParam=0, lParam=lpFile
RPBM_SETBACKCOLOR		equ WM_USER+11	;wParam=0, lParam=nColor
RPBM_GETBACKCOLOR		equ WM_USER+12	;wParam=0, lParam=0
RPBM_SETTEXTCOLOR		equ WM_USER+13	;wParam=0, lParam=nColor
RPBM_GETTEXTCOLOR		equ WM_USER+14	;wParam=0, lParam=0
RPBM_GETIMAGELIST		equ WM_USER+15	;wParam=0, lParam=0
RPBM_SETTOOLTIP			equ WM_USER+16	;wParam=n (1 or 2), lParam=lpszText

;Notifications
PBN_DBLCLICK		equ 1

PBFILEEXT struct
	id			dd ?				;image index
	szfileext	db MAX_PATH dup(?)	;list of fileextensions
PBFILEEXT ends

PBITEM struct
	id			dd ?				;<0 for groups,>0 for files
	idparent	dd ?				;ID of parent group
	szitem		db MAX_PATH dup(?)	;Group string for groups, relative filename for files
PBITEM ends

PBNOTIFY struct
	nmhdr		NMHDR <?>
	lpfile		dd ?
PBNOTIFY ends

;Styles
PBSTYLE_FLATTOOLBAR	equ 1
PBSTYLE_DIVIDERLINE	equ 2

.const

szPBClassName		db 'RAProject',0
