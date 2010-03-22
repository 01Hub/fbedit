;Messages
RPBM_SETPATH			equ WM_USER+1	;wParam=0, lParam=Pointer to path string
RPBM_GETPATH			equ WM_USER+2	;wParam=0, lParam=0 Returns pointer to path string
RPBM_ADDFILEEXT			equ WM_USER+3	;wParam=Index, lParam=Pointer to a PBFILEEXT structure, if NULL array is cleared
RPBM_GETFILEEXT			equ WM_USER+4	;wParam=Index, lParam=0 Returns pointer to a PBFILEEXT structure
RPBM_ADDITEM			equ WM_USER+5	;wParam=Index, lParam=Pointer to a PBITEM structure, if NULL array is cleared
RPBM_GETITEM			equ WM_USER+6	;wParam=Index, lParam=0 Returns pointer to a PBITEM structure
RPBM_SETGROUPING		equ WM_USER+7	;wParam=FALSE/TRUE(Refresh), lParam=1,2 or 3
RPBM_GETGROUPING		equ WM_USER+8	;wParam=0, lParam=0 Returns grouping 1,2 or 3
RPBM_SETSELECTED		equ WM_USER+9	;wParam=0, lParam=lpszItem
RPBM_GETSELECTED		equ WM_USER+10	;wParam=0, lParam=0 Returns pointer to a PBITEM structure
RPBM_SETBACKCOLOR		equ WM_USER+11	;wParam=0, lParam=nColor
RPBM_GETBACKCOLOR		equ WM_USER+12	;wParam=0, lParam=0
RPBM_SETTEXTCOLOR		equ WM_USER+13	;wParam=0, lParam=nColor
RPBM_GETTEXTCOLOR		equ WM_USER+14	;wParam=0, lParam=0
RPBM_GETIMAGELIST		equ WM_USER+15	;wParam=0, lParam=0
RPBM_SETTOOLTIP			equ WM_USER+16	;wParam=n (1 or 2), lParam=lpszText

PBFILEEXT struct
	id			dd ?					;image index
	szfileext	db MAX_PATH dup(?)		;list of fileextensions
PBFILEEXT ends

PBITEM struct
	id			dd ?					;<0 for groups,>0 for files
	idparent	dd ?					;id of parent group
	szitem		db MAX_PATH dup(?)		;Group string for groups, path & filename for files
	expanded	dd ?					;TRUE if expanded
	hitem		dd ?					;Handle of treview item
	lParam		dd ?					;Application defined 32 bit value
PBITEM ends

;Notifications
RPBN_DBLCLICK			equ 1
RPBN_ITEMCHANGE			equ 2

NMPBITEMDBLCLICK struct
	nmhdr		NMHDR <?>
	lpPBITEM	dd ?
NMPBITEMDBLCLICK ends

NMPBITEMCHANGE struct
	nmhdr		NMHDR <?>
	lpPBITEM	dd ?
	lpsznew		dd ?
	cancel		dd ?
NMPBITEMCHANGE ends

;Grouping
RPBG_NONE				equ 1
RPBG_PATH				equ 2
RPBG_GROUPS				equ 3

;Styles
RPBS_FLATTOOLBAR		equ 1
RPBS_DIVIDERLINE		equ 2

.const

szPBClassName			db 'RAProject',0
