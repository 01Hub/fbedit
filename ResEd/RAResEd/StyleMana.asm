
RSM_ADDITEM			equ WM_USER+0					;wParam=0, lParam=lpString, Returns nothing
RSM_DELITEM			equ WM_USER+1					;wParam=Index, lParam=0, Returns nothing
RSM_GETITEM			equ WM_USER+2					;wParam=Index, lParam=0, Returns pointer to string or NULL
RSM_GETCOUNT		equ WM_USER+3					;wParam=0, lParam=0, Returns count
RSM_CLEAR			equ WM_USER+4					;wParam=0, lParam=0, Returns nothing
RSM_SETCURSEL		equ WM_USER+5					;wParam=Index, lParam=0, Returns nothing
RSM_GETCURSEL		equ WM_USER+6					;wParam=0, lParam=0, Returns Index
RSM_GETTOPINDEX		equ WM_USER+7					;wParam=0, lParam=0, Returns TopIndex
RSM_SETTOPINDEX		equ WM_USER+8					;wParam=TopIndex, lParam=0, Returns nothing
RSM_GETITEMRECT		equ WM_USER+9					;wParam=Index, lParam=lpRECT, Returns nothing
RSM_SETVISIBLE		equ WM_USER+10					;wParam=0, lParam=0, Returns nothing
RSM_SETSTYLEVAL		equ WM_USER+11					;wParam=o, lParam=lpDIALOG, Returns nothing
RSM_GETSTYLEVAL		equ WM_USER+12					;wParam=0, lParam=0, Returns Style
RSM_GETCOLOR		equ WM_USER+13					;wParam=0, lParam=lpRS_COLOR, Returns nothing
RSM_SETCOLOR		equ WM_USER+14					;wParam=0, lParam=lpRS_COLOR, Returns nothing
RSM_UPDATESTYLEVAL	equ WM_USER+14					;wParam=0, lParam=lpDIALOG, Returns nothing

RASTYLE struct
	style		dd ?
	backcolor	dd ?
	textcolor	dd ?
	hfont		dd ?
	hboldfont	dd ?
	fredraw		dd ?
	itemheight	dd ?
	cursel		dd ?
	count		dd ?
	topindex	dd ?
	hmem		dd ?
	lpmem		dd ?
	cbsize		dd ?
	lpdialog	dd ?
	ntype		dd ?
	ntypeid		dd ?
	styleval	dd ?
	G1Visible	dd ?
	G2Visible	dd ?
RASTYLE ends

RS_COLOR struct
	back		dd ?
	text		dd ?
RS_COLOR ends

RSTYPES struct
	ctlid		dd ?
	style1		db 8 dup(?)
	style2		db 8 dup(?)
	style3		db 8 dup(?)
RSTYPES ends

DLGC_CODE			equ DLGC_WANTCHARS or DLGC_WANTARROWS
IDD_DLGSTYLEMANA	equ 1900
IDC_LSTSTYLEMANA	equ 1001
IDC_EDTDWORD		equ 1002
IDC_BTNUPDATE		equ 1003

.const

szClassName			db 'RAStyle',0
szWindowStyles		db 'Window styles',0
szExWindowStyles	db 'Extended Window styles',0
szControlStyles		db 'Control styles',0

types				RSTYPES <0,'WS_','DS_',>				;Dialog	
					RSTYPES <1,'WS_','ES_',>				;Edit
					RSTYPES <2,'WS_','SS_',>				;Static
					RSTYPES <3,'WS_','BS_',>				;GroupBox
					RSTYPES <4,'WS_','BS_',>				;Button
					RSTYPES <5,'WS_','BS_',>				;CheckBox
					RSTYPES <6,'WS_','BS_',>				;RadioButton
					RSTYPES <7,'WS_','CBS_',>				;ComboBox
					RSTYPES <8,'WS_','LBS_',>				;ListBox
					RSTYPES <9,'WS_','SBS_',>				;H-ScrollBar
					RSTYPES <10,'WS_','SBS_',>				;V-ScrollBar
					RSTYPES <11,'WS_','TCS_',>				;Tab control
					RSTYPES <12,'WS_','PBS_',>				;Progress bar
					RSTYPES <13,'WS_','TVS_',>				;Tree view
					RSTYPES <14,'WS_','LVS_',>				;List view
					RSTYPES <15,'WS_','TBS_',>				;Track bar
					RSTYPES <16,'WS_','UDS_',>				;UpDown
					RSTYPES <17,'WS_','SS_',>				;Image
					RSTYPES <18,'WS_','TBSTYLE','CCS_'>		;ToolBar
					RSTYPES <19,'WS_','SBARS_','CCS_'>		;Status bar
					RSTYPES <20,'WS_','DTS_',>				;DateTimp picker
					RSTYPES <21,'WS_','MCS_',>				;Month view
					RSTYPES <22,'WS_','ES_',>				;Rich edit
					RSTYPES <23,'WS_',,>					;User defined
					RSTYPES <24,'WS_',,>					;ComboBoxEx
					RSTYPES <25,'WS_','SS_',>				;Shape
					RSTYPES <26,'WS_',,>					;IPAddress
					RSTYPES <27,'WS_','ACS_',>				;Animate
					RSTYPES <28,'WS_',,>					;Hotkey
					RSTYPES <29,'WS_','PGS_',>				;H-Pager
					RSTYPES <30,'WS_','PGS_',>				;V-Pager
					RSTYPES <31,'WS_','RBS_',>				;ReBar
					RSTYPES <32,'WS_','HDS_',>				;Header
					RSTYPES <260,'WS_','RAES_',>			;RAEdit
					RSTYPES <280,'WS_','RAGS_',>			;RAGrid
					RSTYPES <256,'WS_','SPS_',>				;SpreadSheet
					RSTYPES <-1,'WS_',>

extypes				RSTYPES <'WS_',,>						;Dialog	
					RSTYPES <'WS_',,>						;Edit
					RSTYPES <'WS_',,>						;Static
					RSTYPES <'WS_',,>						;GroupBox
					RSTYPES <'WS_',,>						;Button
					RSTYPES <'WS_',,>						;CheckBox
					RSTYPES <'WS_',,>						;RadioButton
					RSTYPES <'WS_',,>						;ComboBox
					RSTYPES <'WS_',,>						;ListBox
					RSTYPES <'WS_',,>						;H-ScrollBar
					RSTYPES <'WS_',,>						;V-ScrollBar
					RSTYPES <'WS_',,>						;Tab control
					RSTYPES <'WS_',,>						;Progress bar
					RSTYPES <'WS_',,>						;Tree view
					RSTYPES <'WS_',,>						;List view
					RSTYPES <'WS_',,>						;Track bar
					RSTYPES <'WS_',,>						;UpDown
					RSTYPES <'WS_',,>						;Image
					RSTYPES <'WS_',,>						;ToolBar
					RSTYPES <'WS_',,>						;Status bar
					RSTYPES <'WS_',,>						;DateTimp picker
					RSTYPES <'WS_',,>						;Month view
					RSTYPES <'WS_',,>						;Rich edit
					RSTYPES <'WS_',,>						;User defined
					RSTYPES <'WS_',,>						;ComboBoxEx
					RSTYPES <'WS_',,>						;Shape
					RSTYPES <'WS_',,>						;IPAddress
					RSTYPES <'WS_',,>						;Animate
					RSTYPES <'WS_',,>						;Hotkey
					RSTYPES <'WS_',,>						;H-Pager
					RSTYPES <'WS_',,>						;V-Pager
					RSTYPES <'WS_',,>						;ReBar
					RSTYPES <'WS_',,>						;Header
					RSTYPES <'WS_',,>						;Custom controls
					RSTYPES <,,>

rsstyledefdlg	dd DS_3DLOOK
				dd DS_3DLOOK
				db 'DS_3DLOOK',0
				dd DS_ABSALIGN
				dd DS_ABSALIGN
				db 'DS_ABSALIGN',0
				dd DS_CENTER
				dd DS_CENTER
				db 'DS_CENTER',0
				dd DS_CENTERMOUSE
				dd DS_CENTERMOUSE
				db 'DS_CENTERMOUSE',0
				dd DS_CONTEXTHELP
				dd DS_CONTEXTHELP
				db 'DS_CONTEXTHELP',0
				dd DS_CONTROL
				dd DS_CONTROL
				db 'DS_CONTROL',0
				dd DS_FIXEDSYS
				dd DS_FIXEDSYS
				db 'DS_FIXEDSYS',0
				dd DS_LOCALEDIT
				dd DS_LOCALEDIT
				db 'DS_LOCALEDIT',0
				dd DS_MODALFRAME
				dd DS_MODALFRAME
				db 'DS_MODALFRAME',0
				dd DS_NOFAILCREATE
				dd DS_NOFAILCREATE
				db 'DS_NOFAILCREATE',0
				dd DS_NOIDLEMSG
				dd DS_NOIDLEMSG
				db 'DS_NOIDLEMSG',0
				dd DS_SETFONT
				dd DS_SETFONT
				db 'DS_SETFONT',0
				dd DS_SETFOREGROUND
				dd DS_SETFOREGROUND
				db 'DS_SETFOREGROUND',0
				dd DS_SYSMODAL
				dd DS_SYSMODAL
				db 'DS_SYSMODAL',0
				dd WS_BORDER
				dd WS_CAPTION
				db 'WS_BORDER',0
				dd WS_CAPTION
				dd WS_CAPTION
				db 'WS_CAPTION',0
				dd WS_CHILD
				dd WS_POPUP or WS_CHILD
				db 'WS_CHILD',0
;				dd WS_CHILDWINDOW
;				dd WS_POPUP or WS_CHILD
;				db 'WS_CHILDWINDOW',0
				dd WS_CLIPCHILDREN
				dd WS_CLIPCHILDREN
				db 'WS_CLIPCHILDREN',0
				dd WS_CLIPSIBLINGS
				dd WS_CLIPSIBLINGS
				db 'WS_CLIPSIBLINGS',0
				dd WS_DISABLED
				dd WS_DISABLED
				db 'WS_DISABLED',0
				dd WS_DLGFRAME
				dd WS_CAPTION
				db 'WS_DLGFRAME',0
				dd WS_HSCROLL
				dd WS_HSCROLL
				db 'WS_HSCROLL',0
				dd WS_ICONIC
				dd WS_ICONIC
				db 'WS_ICONIC',0
				dd WS_MAXIMIZE
				dd WS_MAXIMIZE
				db 'WS_MAXIMIZE',0
				dd WS_MAXIMIZEBOX
				dd WS_MAXIMIZEBOX
				db 'WS_MAXIMIZEBOX',0
				dd WS_MINIMIZE
				dd WS_MINIMIZE
				db 'WS_MINIMIZE',0
				dd WS_MINIMIZEBOX
				dd WS_MINIMIZEBOX
				db 'WS_MINIMIZEBOX',0
;				dd WS_OVERLAPPED
;				dd WS_OVERLAPPED
;				db 'WS_OVERLAPPED',0
				dd WS_OVERLAPPEDWINDOW
				dd WS_OVERLAPPEDWINDOW
				db 'WS_OVERLAPPEDWINDOW',0
				dd WS_POPUP
				dd WS_POPUP or WS_CHILD
				db 'WS_POPUP',0
;				dd WS_POPUPWINDOW
;				dd WS_POPUP or WS_CHILD
;				db 'WS_POPUPWINDOW',0
				dd WS_SIZEBOX
				dd WS_SIZEBOX
				db 'WS_SIZEBOX',0
				dd WS_SYSMENU
				dd WS_SYSMENU
				db 'WS_SYSMENU',0
				dd WS_THICKFRAME
				dd WS_THICKFRAME
				db 'WS_THICKFRAME',0
;				dd WS_TILED
;				dd WS_TILED
;				db 'WS_TILED',0
;				dd WS_TILEDWINDOW
;				dd WS_TILEDWINDOW
;				db 'WS_TILEDWINDOW',0
				dd WS_VISIBLE
				dd WS_VISIBLE
				db 'WS_VISIBLE',0
				dd WS_VSCROLL
				dd WS_VSCROLL
				db 'WS_VSCROLL',0
				dd 0,0
				db 0

rsstyledef		dd ACS_CENTER
				dd ACS_CENTER
				db 'ACS_CENTER',0
				dd ACS_TRANSPARENT
				dd ACS_TRANSPARENT
				db 'ACS_TRANSPARENT',0
				dd ACS_AUTOPLAY
				dd ACS_AUTOPLAY
				db 'ACS_AUTOPLAY',0
				dd ACS_TIMER
				dd ACS_TIMER
				db 'ACS_TIMER',0
				dd BS_3STATE
				dd 01Fh
				db 'BS_3STATE',0
				dd BS_AUTO3STATE
				dd 01Fh
				db 'BS_AUTO3STATE',0
				dd BS_AUTOCHECKBOX
				dd 01Fh
				db 'BS_AUTOCHECKBOX',0
				dd BS_AUTORADIOBUTTON
				dd 01Fh
				db 'BS_AUTORADIOBUTTON',0
				dd BS_BITMAP
				dd 01Fh
				db 'BS_BITMAP',0
				dd BS_BOTTOM
				dd 0C00h
				db 'BS_BOTTOM',0
				dd BS_CENTER
				dd 300h
				db 'BS_CENTER',0
				dd BS_CHECKBOX
				dd 01Fh
				db 'BS_CHECKBOX',0
				dd BS_DEFPUSHBUTTON
				dd 01Fh
				db 'BS_DEFPUSHBUTTON',0
				dd BS_FLAT
				dd BS_FLAT
				db 'BS_FLAT',0
				dd BS_GROUPBOX
				dd 01Fh
				db 'BS_GROUPBOX',0
				dd BS_ICON
				dd 01Fh
				db 'BS_ICON',0
				dd BS_LEFT
				dd 0300h
				db 'BS_LEFT',0
				dd BS_LEFTTEXT
				dd BS_LEFTTEXT
				db 'BS_LEFTTEXT',0
				dd BS_MULTILINE
				dd BS_MULTILINE
				db 'BS_MULTILINE',0
				dd BS_NOTIFY
				dd BS_NOTIFY
				db 'BS_NOTIFY',0
				dd BS_OWNERDRAW
				dd 01Fh
				db 'BS_OWNERDRAW',0
				dd BS_PUSHBUTTON
				dd 01Fh
				db 'BS_PUSHBUTTON',0
				dd BS_PUSHLIKE
				dd BS_PUSHLIKE
				db 'BS_PUSHLIKE',0
				dd BS_RADIOBUTTON
				dd 01Fh
				db 'BS_RADIOBUTTON',0
				dd BS_RIGHT
				dd 0300h
				db 'BS_RIGHT',0
				dd BS_RIGHTBUTTON
				dd BS_RIGHTBUTTON
				db 'BS_RIGHTBUTTON',0
				dd BS_TEXT
				dd BS_TEXT
				db 'BS_TEXT',0
				dd BS_TOP
				dd 0C00h
				db 'BS_TOP',0
				dd BS_USERBUTTON
				dd 01Fh
				db 'BS_USERBUTTON',0
				dd BS_VCENTER
				dd 0C00h
				db 'BS_VCENTER',0
				dd CBS_AUTOHSCROLL
				dd CBS_AUTOHSCROLL
				db 'CBS_AUTOHSCROLL',0
				dd CBS_DISABLENOSCROLL
				dd CBS_DISABLENOSCROLL
				db 'CBS_DISABLENOSCROLL',0
				dd CBS_DROPDOWN
				dd 3
				db 'CBS_DROPDOWN',0
				dd CBS_DROPDOWNLIST
				dd 3
				db 'CBS_DROPDOWNLIST',0
				dd CBS_HASSTRINGS
				dd CBS_HASSTRINGS
				db 'CBS_HASSTRINGS',0
				dd CBS_LOWERCASE
				dd CBS_LOWERCASE
				db 'CBS_LOWERCASE',0
				dd CBS_NOINTEGRALHEIGHT
				dd CBS_NOINTEGRALHEIGHT
				db 'CBS_NOINTEGRALHEIGHT',0
				dd CBS_OEMCONVERT
				dd CBS_OEMCONVERT
				db 'CBS_OEMCONVERT',0
				dd CBS_OWNERDRAWFIXED
				dd CBS_OWNERDRAWFIXED
				db 'CBS_OWNERDRAWFIXED',0
				dd CBS_OWNERDRAWVARIABLE
				dd CBS_OWNERDRAWVARIABLE
				db 'CBS_OWNERDRAWVARIABLE',0
				dd CBS_SIMPLE
				dd 3
				db 'CBS_SIMPLE',0
				dd CBS_SORT
				dd CBS_SORT
				db 'CBS_SORT',0
				dd CBS_UPPERCASE
				dd CBS_UPPERCASE
				db 'CBS_UPPERCASE',0
				dd CCS_TOP
				dd 83h
				db 'CCS_TOP',0
				dd CCS_NOMOVEY
				dd 83h
				db 'CCS_NOMOVEY',0
				dd CCS_BOTTOM
				dd 83h
				db 'CCS_BOTTOM',0
				dd CCS_NORESIZE
				dd CCS_NORESIZE
				db 'CCS_NORESIZE',0
				dd CCS_NOPARENTALIGN
				dd CCS_NOPARENTALIGN
				db 'CCS_NOPARENTALIGN',0
				dd CCS_ADJUSTABLE
				dd CCS_ADJUSTABLE
				db 'CCS_ADJUSTABLE',0
				dd CCS_NODIVIDER
				dd CCS_NODIVIDER
				db 'CCS_NODIVIDER',0
				dd CCS_VERT
				dd CCS_VERT
				db 'CCS_VERT',0
				dd CCS_LEFT
				dd 83h
				db 'CCS_LEFT',0
				dd CCS_RIGHT
				dd 83h
				db 'CCS_RIGHT',0
				dd CCS_NOMOVEX
				dd 83h
				db 'CCS_NOMOVEX',0
				dd DTS_UPDOWN
				dd DTS_UPDOWN
				db 'DTS_UPDOWN',0
				dd DTS_SHOWNONE
				dd DTS_SHOWNONE
				db 'DTS_SHOWNONE',0
				dd DTS_SHORTDATEFORMAT
				dd DTS_LONGDATEFORMAT
				db 'DTS_SHORTDATEFORMAT',0
				dd DTS_LONGDATEFORMAT
				dd DTS_LONGDATEFORMAT
				db 'DTS_LONGDATEFORMAT',0
				dd DTS_TIMEFORMAT
				dd DTS_TIMEFORMAT
				db 'DTS_TIMEFORMAT',0
				dd DTS_APPCANPARSE
				dd DTS_APPCANPARSE
				db 'DTS_APPCANPARSE',0
				dd DTS_RIGHTALIGN
				dd DTS_RIGHTALIGN
				db 'DTS_RIGHTALIGN',0
				dd ES_AUTOHSCROLL
				dd ES_AUTOHSCROLL
				db 'ES_AUTOHSCROLL',0
				dd ES_AUTOVSCROLL
				dd ES_AUTOVSCROLL
				db 'ES_AUTOVSCROLL',0
				dd ES_CENTER
				dd 03h
				db 'ES_CENTER',0
				dd ES_DISABLENOSCROLL
				dd ES_DISABLENOSCROLL
				db 'ES_DISABLENOSCROLL',0
				dd ES_LEFT
				dd 03h
				db 'ES_LEFT',0
				dd ES_LOWERCASE
				dd 018h
				db 'ES_LOWERCASE',0
				dd ES_MULTILINE
				dd ES_MULTILINE
				db 'ES_MULTILINE',0
				dd ES_NOHIDESEL
				dd ES_NOHIDESEL
				db 'ES_NOHIDESEL',0
				dd ES_NUMBER
				dd ES_NUMBER
				db 'ES_NUMBER',0
				dd ES_OEMCONVERT
				dd ES_OEMCONVERT
				db 'ES_OEMCONVERT',0
				dd ES_PASSWORD
				dd ES_PASSWORD
				db 'ES_PASSWORD',0
				dd ES_READONLY
				dd ES_READONLY
				db 'ES_READONLY',0
				dd ES_RIGHT
				dd 03h
				db 'ES_RIGHT',0
				dd ES_SAVESEL
				dd ES_SAVESEL
				db 'ES_SAVESEL',0
				dd ES_SELECTIONBAR
				dd ES_SELECTIONBAR
				db 'ES_SELECTIONBAR',0
				dd ES_SUNKEN
				dd ES_SUNKEN
				db 'ES_SUNKEN',0
				dd ES_UPPERCASE
				dd 018h
				db 'ES_UPPERCASE',0
				dd ES_VERTICAL
				dd ES_VERTICAL
				db 'ES_VERTICAL',0
				dd ES_WANTRETURN
				dd ES_WANTRETURN
				db 'ES_WANTRETURN',0
				dd HDS_BUTTONS
				dd HDS_BUTTONS
				db 'HDS_BUTTONS',0
				dd HDS_DRAGDROP
				dd HDS_DRAGDROP
				db 'HDS_DRAGDROP',0
				dd HDS_FILTERBAR
				dd HDS_FILTERBAR
				db 'HDS_FILTERBAR',0
				dd HDS_FULLDRAG
				dd HDS_FULLDRAG
				db 'HDS_FULLDRAG',0
				dd HDS_HIDDEN
				dd HDS_HIDDEN
				db 'HDS_HIDDEN',0
				dd HDS_HORZ
				dd HDS_HORZ
				db 'HDS_HORZ',0
				dd HDS_HOTTRACK
				dd HDS_HOTTRACK
				db 'HDS_HOTTRACK',0
				dd LBS_DISABLENOSCROLL
				dd LBS_DISABLENOSCROLL
				db 'LBS_DISABLENOSCROLL',0
				dd LBS_EXTENDEDSEL
				dd LBS_EXTENDEDSEL
				db 'LBS_EXTENDEDSEL',0
				dd LBS_HASSTRINGS
				dd LBS_HASSTRINGS
				db 'LBS_HASSTRINGS',0
				dd LBS_MULTICOLUMN
				dd LBS_MULTICOLUMN
				db 'LBS_MULTICOLUMN',0
				dd LBS_MULTIPLESEL
				dd LBS_MULTIPLESEL
				db 'LBS_MULTIPLESEL',0
				dd LBS_NODATA
				dd LBS_NODATA
				db 'LBS_NODATA',0
				dd LBS_NOINTEGRALHEIGHT
				dd LBS_NOINTEGRALHEIGHT
				db 'LBS_NOINTEGRALHEIGHT',0
				dd LBS_NOREDRAW
				dd LBS_NOREDRAW
				db 'LBS_NOREDRAW',0
				dd LBS_NOTIFY
				dd LBS_NOTIFY
				db 'LBS_NOTIFY',0
				dd LBS_OWNERDRAWFIXED
				dd LBS_OWNERDRAWFIXED
				db 'LBS_OWNERDRAWFIXED',0
				dd LBS_OWNERDRAWVARIABLE
				dd LBS_OWNERDRAWVARIABLE
				db 'LBS_OWNERDRAWVARIABLE',0
				dd LBS_SORT
				dd LBS_SORT
				db 'LBS_SORT',0
				dd LBS_STANDARD
				dd LBS_STANDARD
				db 'LBS_STANDARD',0
				dd LBS_USETABSTOPS
				dd LBS_USETABSTOPS
				db 'LBS_USETABSTOPS',0
				dd LBS_WANTKEYBOARDINPUT
				dd LBS_WANTKEYBOARDINPUT
				db 'LBS_WANTKEYBOARDINPUT',0
				dd LVS_ICON
				dd 0003h
				db 'LVS_ICON',0
				dd LVS_REPORT
				dd 0003h
				db 'LVS_REPORT',0
				dd LVS_SMALLICON
				dd 0003h
				db 'LVS_SMALLICON',0
				dd LVS_LIST
				dd 0003h
				db 'LVS_LIST',0
				dd LVS_SINGLESEL
				dd LVS_SINGLESEL
				db 'LVS_SINGLESEL',0
				dd LVS_SHOWSELALWAYS
				dd LVS_SHOWSELALWAYS
				db 'LVS_SHOWSELALWAYS',0
				dd LVS_SORTASCENDING
				dd LVS_SORTASCENDING
				db 'LVS_SORTASCENDING',0
				dd LVS_SORTDESCENDING
				dd LVS_SORTDESCENDING
				db 'LVS_SORTDESCENDING',0
				dd LVS_SHAREIMAGELISTS
				dd LVS_SHAREIMAGELISTS
				db 'LVS_SHAREIMAGELISTS',0
				dd LVS_NOLABELWRAP
				dd LVS_NOLABELWRAP
				db 'LVS_NOLABELWRAP',0
				dd LVS_AUTOARRANGE
				dd LVS_AUTOARRANGE
				db 'LVS_AUTOARRANGE',0
				dd LVS_EDITLABELS
				dd LVS_EDITLABELS
				db 'LVS_EDITLABELS',0
				dd LVS_NOSCROLL
				dd LVS_NOSCROLL
				db 'LVS_NOSCROLL',0
				dd LVS_ALIGNTOP
				dd LVS_ALIGNLEFT
				db 'LVS_ALIGNTOP',0
				dd LVS_ALIGNLEFT
				dd LVS_ALIGNLEFT
				db 'LVS_ALIGNLEFT',0
				dd LVS_OWNERDRAWFIXED
				dd LVS_OWNERDRAWFIXED
				db 'LVS_OWNERDRAWFIXED',0
				dd LVS_NOCOLUMNHEADER
				dd LVS_NOCOLUMNHEADER
				db 'LVS_NOCOLUMNHEADER',0
				dd LVS_NOSORTHEADER
				dd LVS_NOSORTHEADER
				db 'LVS_NOSORTHEADER',0
				dd LVS_OWNERDATA
				dd LVS_OWNERDATA
				db 'LVS_OWNERDATA',0
				dd MCS_DAYSTATE
				dd MCS_DAYSTATE
				db 'MCS_DAYSTATE',0
				dd MCS_MULTISELECT
				dd MCS_MULTISELECT
				db 'MCS_MULTISELECT',0
				dd MCS_NOTODAY
				dd MCS_NOTODAY
				db 'MCS_NOTODAY',0
				dd MCS_NOTODAYCIRCLE
				dd MCS_NOTODAYCIRCLE
				db 'MCS_NOTODAYCIRCLE',0
				dd MCS_WEEKNUMBERS
				dd MCS_WEEKNUMBERS
				db 'MCS_WEEKNUMBERS',0
				dd PBS_SMOOTH
				dd PBS_SMOOTH
				db 'PBS_SMOOTH',0
				dd PBS_VERTICAL
				dd PBS_VERTICAL
				db 'PBS_VERTICAL',0
				dd PGS_VERT
				dd PGS_VERT
				db 'PGS_VERT',0
				dd PGS_HORZ
				dd PGS_HORZ
				db 'PGS_HORZ',0
				dd PGS_AUTOSCROLL
				dd PGS_AUTOSCROLL
				db 'PGS_AUTOSCROLL',0
				dd PGS_DRAGNDROP
				dd PGS_DRAGNDROP
				db 'PGS_DRAGNDROP',0
				dd RBS_TOOLTIPS
				dd RBS_TOOLTIPS
				db 'RBS_TOOLTIPS',0
				dd RBS_VARHEIGHT
				dd RBS_VARHEIGHT
				db 'RBS_VARHEIGHT',0
				dd RBS_BANDBORDERS
				dd RBS_BANDBORDERS
				db 'RBS_BANDBORDERS',0
				dd RBS_FIXEDORDER
				dd RBS_FIXEDORDER
				db 'RBS_FIXEDORDER',0
				dd RBS_REGISTERDROP
				dd RBS_REGISTERDROP
				db 'RBS_REGISTERDROP',0
				dd RBS_AUTOSIZE
				dd RBS_AUTOSIZE
				db 'RBS_AUTOSIZE',0
				dd RBS_VERTICALGRIPPER
				dd RBS_VERTICALGRIPPER
				db 'RBS_VERTICALGRIPPER',0
				dd RBS_DBLCLKTOGGLE
				dd RBS_DBLCLKTOGGLE
				db 'RBS_DBLCLKTOGGLE',0
				dd SBARS_SIZEGRIP
				dd SBARS_SIZEGRIP
				db 'SBARS_SIZEGRIP',0
				dd SBARS_TOOLTIPS
				dd SBARS_TOOLTIPS
				db 'SBARS_TOOLTIPS',0
				dd SBS_BOTTOMALIGN
				dd SBS_BOTTOMALIGN
				db 'SBS_BOTTOMALIGN',0
				dd SBS_HORZ
				dd SBS_HORZ
				db 'SBS_HORZ',0
				dd SBS_LEFTALIGN
				dd SBS_LEFTALIGN
				db 'SBS_LEFTALIGN',0
				dd SBS_RIGHTALIGN
				dd SBS_RIGHTALIGN
				db 'SBS_RIGHTALIGN',0
				dd SBS_SIZEBOX
				dd SBS_SIZEBOX
				db 'SBS_SIZEBOX',0
				dd SBS_SIZEBOXBOTTOMRIGHTALIGN
				dd SBS_SIZEBOXBOTTOMRIGHTALIGN
				db 'SBS_SIZEBOXBOTTOMRIGHTALIGN',0
				dd SBS_SIZEBOXTOPLEFTALIGN
				dd SBS_SIZEBOXTOPLEFTALIGN
				db 'SBS_SIZEBOXTOPLEFTALIGN',0
				dd SBS_SIZEGRIP
				dd SBS_SIZEGRIP
				db 'SBS_SIZEGRIP',0
				dd SBS_TOPALIGN
				dd SBS_TOPALIGN
				db 'SBS_TOPALIGN',0
				dd SBS_VERT
				dd SBS_VERT
				db 'SBS_VERT',0
				dd SS_BITMAP
				dd 01Fh
				db 'SS_BITMAP',0
				dd SS_BLACKFRAME
				dd 01Fh
				db 'SS_BLACKFRAME',0
				dd SS_BLACKRECT
				dd 01Fh
				db 'SS_BLACKRECT',0
				dd SS_CENTER
				dd 01Fh
				db 'SS_CENTER',0
				dd SS_CENTERIMAGE
				dd SS_CENTERIMAGE
				db 'SS_CENTERIMAGE',0
				dd SS_ETCHEDHORZ
				dd 01Fh
				db 'SS_ETCHEDHORZ',0
				dd SS_ETCHEDFRAME
				dd 01Fh
				db 'SS_ETCHEDFRAME',0
				dd SS_ETCHEDVERT
				dd 01Fh
				db 'SS_ETCHEDVERT',0
				dd SS_GRAYFRAME
				dd 01Fh
				db 'SS_GRAYFRAME',0
				dd SS_GRAYRECT
				dd 01Fh
				db 'SS_GRAYRECT',0
				dd SS_ICON
				dd 01Fh
				db 'SS_ICON',0
				dd SS_LEFT
				dd 01Fh
				db 'SS_LEFT',0
				dd SS_LEFTNOWORDWRAP
				dd 01Fh
				db 'SS_LEFTNOWORDWRAP',0
				dd SS_NOPREFIX
				dd SS_NOPREFIX
				db 'SS_NOPREFIX',0
				dd SS_RIGHT
				dd 01Fh
				db 'SS_RIGHT',0
				dd SS_SIMPLE
				dd 01Fh
				db 'SS_SIMPLE',0
				dd SS_USERITEM
				dd 01Fh
				db 'SS_USERITEM',0
				dd SS_WHITEFRAME
				dd 01Fh
				db 'SS_WHITEFRAME',0
				dd SS_WHITERECT
				dd 01Fh
				db 'SS_WHITERECT',0
				dd TBSTYLE_TOOLTIPS
				dd TBSTYLE_TOOLTIPS
				db 'TBSTYLE_TOOLTIPS',0
				dd TBSTYLE_WRAPABLE
				dd TBSTYLE_WRAPABLE
				db 'TBSTYLE_WRAPABLE',0
				dd TBSTYLE_ALTDRAG
				dd TBSTYLE_ALTDRAG
				db 'TBSTYLE_ALTDRAG',0
				dd TBSTYLE_FLAT
				dd TBSTYLE_FLAT
				db 'TBSTYLE_FLAT',0
				dd TBSTYLE_LIST
				dd TBSTYLE_LIST
				db 'TBSTYLE_LIST',0
				dd TBSTYLE_CUSTOMERASE
				dd TBSTYLE_CUSTOMERASE
				db 'TBSTYLE_CUSTOMERASE',0
				dd TBSTYLE_REGISTERDROP
				dd TBSTYLE_REGISTERDROP
				db 'TBSTYLE_REGISTERDROP',0
				dd TBSTYLE_TRANSPARENT
				dd TBSTYLE_TRANSPARENT
				db 'TBSTYLE_TRANSPARENT',0
				dd TBSTYLE_AUTOSIZE
				dd TBSTYLE_AUTOSIZE
				db 'TBSTYLE_AUTOSIZE',0
				dd TBS_AUTOTICKS
				dd TBS_AUTOTICKS
				db 'TBS_AUTOTICKS',0
				dd TBS_VERT
				dd TBS_VERT
				db 'TBS_VERT',0
				dd TBS_HORZ
				dd TBS_HORZ
				db 'TBS_HORZ',0
				dd TBS_TOP
				dd TBS_TOP
				db 'TBS_TOP',0
				dd TBS_BOTTOM
				dd TBS_BOTTOM
				db 'TBS_BOTTOM',0
				dd TBS_LEFT
				dd TBS_LEFT
				db 'TBS_LEFT',0
				dd TBS_RIGHT
				dd TBS_RIGHT
				db 'TBS_RIGHT',0
				dd TBS_BOTH
				dd TBS_BOTH
				db 'TBS_BOTH',0
				dd TBS_NOTICKS
				dd TBS_NOTICKS
				db 'TBS_NOTICKS',0
				dd TBS_ENABLESELRANGE
				dd TBS_ENABLESELRANGE
				db 'TBS_ENABLESELRANGE',0
				dd TBS_FIXEDLENGTH
				dd TBS_FIXEDLENGTH
				db 'TBS_FIXEDLENGTH',0
				dd TBS_NOTHUMB
				dd TBS_NOTHUMB
				db 'TBS_NOTHUMB',0
				dd TBS_TOOLTIPS
				dd TBS_TOOLTIPS
				db 'TBS_TOOLTIPS',0
				dd TCS_SCROLLOPPOSITE
				dd TCS_SCROLLOPPOSITE
				db 'TCS_SCROLLOPPOSITE',0
				dd TCS_BOTTOM
				dd TCS_BOTTOM
				db 'TCS_BOTTOM',0
				dd TCS_BOTTOM
				dd TCS_BOTTOM
				db 'TCS_RIGHT',0
				dd TCS_MULTISELECT
				dd TCS_MULTISELECT
				db 'TCS_MULTISELECT',0
				dd TCS_FLATBUTTONS
				dd TCS_FLATBUTTONS
				db 'TCS_FLATBUTTONS',0
				dd TCS_FORCEICONLEFT
				dd TCS_FORCEICONLEFT
				db 'TCS_FORCEICONLEFT',0
				dd TCS_FORCELABELLEFT
				dd TCS_FORCELABELLEFT
				db 'TCS_FORCELABELLEFT',0
				dd TCS_HOTTRACK
				dd TCS_HOTTRACK
				db 'TCS_HOTTRACK',0
				dd TCS_VERTICAL
				dd TCS_VERTICAL
				db 'TCS_VERTICAL',0
				dd TCS_TABS
				dd TCS_TABS
				db 'TCS_TABS',0
				dd TCS_BUTTONS
				dd TCS_BUTTONS
				db 'TCS_BUTTONS',0
				dd TCS_SINGLELINE
				dd TCS_SINGLELINE
				db 'TCS_SINGLELINE',0
				dd TCS_MULTILINE
				dd TCS_MULTILINE
				db 'TCS_MULTILINE',0
				dd TCS_RIGHTJUSTIFY
				dd TCS_RIGHTJUSTIFY
				db 'TCS_RIGHTJUSTIFY',0
				dd TCS_FIXEDWIDTH
				dd TCS_FIXEDWIDTH
				db 'TCS_FIXEDWIDTH',0
				dd TCS_RAGGEDRIGHT
				dd TCS_RAGGEDRIGHT
				db 'TCS_RAGGEDRIGHT',0
				dd TCS_FOCUSONBUTTONDOWN
				dd TCS_FOCUSONBUTTONDOWN
				db 'TCS_FOCUSONBUTTONDOWN',0
				dd TCS_OWNERDRAWFIXED
				dd TCS_OWNERDRAWFIXED
				db 'TCS_OWNERDRAWFIXED',0
				dd TCS_TOOLTIPS
				dd TCS_TOOLTIPS
				db 'TCS_TOOLTIPS',0
				dd TCS_FOCUSNEVER
				dd TCS_FOCUSNEVER
				db 'TCS_FOCUSNEVER',0
				dd TVS_HASBUTTONS
				dd TVS_HASBUTTONS
				db 'TVS_HASBUTTONS',0
				dd TVS_HASLINES
				dd TVS_HASLINES
				db 'TVS_HASLINES',0
				dd TVS_LINESATROOT
				dd TVS_LINESATROOT
				db 'TVS_LINESATROOT',0
				dd TVS_EDITLABELS
				dd TVS_EDITLABELS
				db 'TVS_EDITLABELS',0
				dd TVS_DISABLEDRAGDROP
				dd TVS_DISABLEDRAGDROP
				db 'TVS_DISABLEDRAGDROP',0
				dd TVS_SHOWSELALWAYS
				dd TVS_SHOWSELALWAYS
				db 'TVS_SHOWSELALWAYS',0
				dd TVS_RTLREADING
				dd TVS_RTLREADING
				db 'TVS_RTLREADING',0
				dd TVS_NOTOOLTIPS
				dd TVS_NOTOOLTIPS
				db 'TVS_NOTOOLTIPS',0
				dd TVS_CHECKBOXES
				dd TVS_CHECKBOXES
				db 'TVS_CHECKBOXES',0
				dd TVS_TRACKSELECT
				dd TVS_TRACKSELECT
				db 'TVS_TRACKSELECT',0
				dd TVS_SINGLEEXPAND
				dd TVS_SINGLEEXPAND
				db 'TVS_SINGLEEXPAND',0
				dd TVS_INFOTIP
				dd TVS_INFOTIP
				db 'TVS_INFOTIP',0
				dd TVS_FULLROWSELECT
				dd TVS_FULLROWSELECT
				db 'TVS_FULLROWSELECT',0
				dd TVS_NOSCROLL
				dd TVS_NOSCROLL
				db 'TVS_NOSCROLL',0
				dd TVS_NONEVENHEIGHT
				dd TVS_NONEVENHEIGHT
				db 'TVS_NONEVENHEIGHT',0
				dd TVS_NOHSCROLL
				dd TVS_NOHSCROLL
				db 'TVS_NOHSCROLL',0
				dd UDS_WRAP
				dd UDS_WRAP
				db 'UDS_WRAP',0
				dd UDS_SETBUDDYINT
				dd UDS_SETBUDDYINT
				db 'UDS_SETBUDDYINT',0
				dd UDS_ALIGNRIGHT
				dd UDS_ALIGNRIGHT
				db 'UDS_ALIGNRIGHT',0
				dd UDS_ALIGNLEFT
				dd UDS_ALIGNLEFT
				db 'UDS_ALIGNLEFT',0
				dd UDS_AUTOBUDDY
				dd UDS_AUTOBUDDY
				db 'UDS_AUTOBUDDY',0
				dd UDS_ARROWKEYS
				dd UDS_ARROWKEYS
				db 'UDS_ARROWKEYS',0
				dd UDS_HORZ
				dd UDS_HORZ
				db 'UDS_HORZ',0
				dd UDS_NOTHOUSANDS
				dd UDS_NOTHOUSANDS
				db 'UDS_NOTHOUSANDS',0
				dd UDS_HOTTRACK
				dd UDS_HOTTRACK
				db 'UDS_HOTTRACK',0
				dd WS_BORDER
				dd WS_CAPTION
				db 'WS_BORDER',0
				dd WS_CAPTION
				dd WS_CAPTION
				db 'WS_CAPTION',0
				dd WS_CHILD
				dd WS_POPUP or WS_CHILD
				db 'WS_CHILD',0
;				dd WS_CHILDWINDOW
;				dd WS_POPUP or WS_CHILD
;				db 'WS_CHILDWINDOW',0
				dd WS_CLIPCHILDREN
				dd WS_CLIPCHILDREN
				db 'WS_CLIPCHILDREN',0
				dd WS_CLIPSIBLINGS
				dd WS_CLIPSIBLINGS
				db 'WS_CLIPSIBLINGS',0
				dd WS_DISABLED
				dd WS_DISABLED
				db 'WS_DISABLED',0
				dd WS_DLGFRAME
				dd WS_CAPTION
				db 'WS_DLGFRAME',0
				dd WS_GROUP
				dd WS_GROUP
				db 'WS_GROUP',0
				dd WS_HSCROLL
				dd WS_HSCROLL
				db 'WS_HSCROLL',0
				dd WS_ICONIC
				dd WS_ICONIC
				db 'WS_ICONIC',0
				dd WS_MAXIMIZE
				dd WS_MAXIMIZE
				db 'WS_MAXIMIZE',0
				dd WS_MINIMIZE
				dd WS_MINIMIZE
				db 'WS_MINIMIZE',0
;				dd WS_OVERLAPPED
;				dd WS_OVERLAPPED
;				db 'WS_OVERLAPPED',0
				dd WS_OVERLAPPEDWINDOW
				dd WS_OVERLAPPEDWINDOW
				db 'WS_OVERLAPPEDWINDOW',0
				dd WS_POPUP
				dd WS_POPUP or WS_CHILD
				db 'WS_POPUP',0
;				dd WS_POPUPWINDOW
;				dd WS_POPUP or WS_CHILD
;				db 'WS_POPUPWINDOW',0
				dd WS_SIZEBOX
				dd WS_SIZEBOX
				db 'WS_SIZEBOX',0
				dd WS_SYSMENU
				dd WS_SYSMENU
				db 'WS_SYSMENU',0
				dd WS_TABSTOP
				dd WS_TABSTOP
				db 'WS_TABSTOP',0
				dd WS_THICKFRAME
				dd WS_THICKFRAME
				db 'WS_THICKFRAME',0
;				dd WS_TILED
;				dd WS_TILED
;				db 'WS_TILED',0
;				dd WS_TILEDWINDOW
;				dd WS_TILEDWINDOW
;				db 'WS_TILEDWINDOW',0
				dd WS_VISIBLE
				dd WS_VISIBLE
				db 'WS_VISIBLE',0
				dd WS_VSCROLL
				dd WS_VSCROLL
				db 'WS_VSCROLL',0
;RAEdit
				dd 00001h			;No splitt button
				dd 00001h
				db 'RAES_NOSPLITT',0
				dd 00002h			;No linenumber button
				dd 00002h
				db 'RAES_NOLINENUMBER',0
				dd 00004h			;No expand/collapse buttons
				dd 00004h
				db 'RAES_NOCOLLAPSE',0
				dd 00008h			;No horizontal scrollbar
				dd 00008h
				db 'RAES_NOHSCROLL',0
				dd 00010h			;No vertical scrollbar
				dd 00010h
				db 'RAES_NOVSCROLL',0
				dd 00020h			;No color hiliting
				dd 00020h
				db 'RAES_NOHILITE',0
				dd 00040h			;No size grip
				dd 00040h
				db 'RAES_NOSIZEGRIP',0
				dd 00080h			;No action on double clicks
				dd 00080h
				db 'RAES_NODBLCLICK',0
				dd 00100h			;Text is locked
				dd 00100h
				db 'RAES_READONLY',0
				dd 00200h			;Blocks are not divided by line
				dd 00200h
				db 'RAES_NODIVIDERLINE',0
				dd 00400h			;Drawing directly to screen DC
				dd 00400h
				db 'RAES_NOBACKBUFFER',0
				dd 00800h			;No state indicator
				dd 00800h
				db 'RAES_NOSTATE',0
				dd 01000h			;Drag & Drop support, app must load ole
				dd 01000h
				db 'RAES_DRAGDROP',0
				dd 02000h			;Scrollbar tooltip
				dd 02000h
				db 'RAES_SCROLLTIP',0
				dd 04000h			;Comments are hilited
				dd 04000h
				db 'RAES_HILITECOMMENT',0
				dd 08000h			;Line number column autosizes
				dd 08000h
				db 'RAES_AUTOSIZELINENUM',0
				dd 10000h			;No lock button
				dd 10000h
				db 'RAES_NOLOCK',0
;RAGrid
				dd 01h
				dd 01h
				db 'RAGS_NOSEL',0
				dd 02h
				dd 02h
				db 'RAGS_NOFOCUS',0
				dd 04h
				dd 04h
				db 'RAGS_HGRIDLINES',0
				dd 08h
				dd 08h
				db 'RAGS_VGRIDLINES',0
				dd 10h
				dd 10h
				db 'RAGS_GRIDFRAME',0
				dd 20h
				dd 20h
				db 'RAGS_NOCOLSIZE',0
;SpreadSheet
				dd 0001h			;Vertical scrollbar
				dd 0001h
				db 'SPS_VSCROLL',0
				dd 0002h			;Horizontal scrollbar
				dd 0002h
				db 'SPS_HSCROLL',0
				dd 0004h			;Show status window
				dd 0004h
				db 'SPS_STATUS',0
				dd 0008h			;Show grid lines
				dd 0008h
				db 'SPS_GRIDLINES',0
				dd 0010h			;Selection by row
				dd 0010h
				db 'SPS_ROWSELECT',0
				dd 0020h			;Cell editing
				dd 0020h
				db 'SPS_CELLEDIT',0
				dd 0040h			;Inserting and deleting row/col adjusts max row/col
				dd 0040h
				db 'SPS_GRIDMODE',0
				dd 0080h			;Allow col widt sizeing by mouse
				dd 0080h
				db 'SPS_COLSIZE',0
				dd 0100h			;Allow row height sizeing by mouse
				dd 0100h
				db 'SPS_ROWSIZE',0
				dd 0200h			;Allow splitt window sizeing by mouse
				dd 0200h
				db 'SPS_WINSIZE',0
				dd 0400h			;Allow multiselect
				dd 0400h
				db 'SPS_MULTISELECT',0
				dd 0,0
				db 0

rsexstyledef	dd WS_EX_ACCEPTFILES
				dd WS_EX_ACCEPTFILES
				db 'WS_EX_ACCEPTFILES',0
				dd WS_EX_APPWINDOW
				dd WS_EX_APPWINDOW
				db 'WS_EX_APPWINDOW',0
				dd WS_EX_CLIENTEDGE
				dd WS_EX_CLIENTEDGE
				db 'WS_EX_CLIENTEDGE',0
				dd WS_EX_CONTEXTHELP
				dd WS_EX_CONTEXTHELP
				db 'WS_EX_CONTEXTHELP',0
				dd WS_EX_CONTROLPARENT
				dd WS_EX_CONTROLPARENT
				db 'WS_EX_CONTROLPARENT',0
				dd WS_EX_DLGMODALFRAME
				dd WS_EX_DLGMODALFRAME
				db 'WS_EX_DLGMODALFRAME',0
				dd WS_EX_LAYERED
				dd WS_EX_LAYERED
				db 'WS_EX_LAYERED',0
				dd WS_EX_LEFT
				dd WS_EX_RIGHT
				db 'WS_EX_LEFT',0
				dd WS_EX_LEFTSCROLLBAR
				dd WS_EX_LEFTSCROLLBAR
				db 'WS_EX_LEFTSCROLLBAR',0
				dd WS_EX_LTRREADING
				dd WS_EX_RTLREADING
				db 'WS_EX_LTRREADING',0
				dd WS_EX_MDICHILD
				dd WS_EX_MDICHILD
				db 'WS_EX_MDICHILD',0
				dd WS_EX_NOPARENTNOTIFY
				dd WS_EX_NOPARENTNOTIFY
				db 'WS_EX_NOPARENTNOTIFY',0
				dd WS_EX_OVERLAPPEDWINDOW
				dd WS_EX_OVERLAPPEDWINDOW
				db 'WS_EX_OVERLAPPEDWINDOW',0
				dd WS_EX_PALETTEWINDOW
				dd WS_EX_PALETTEWINDOW
				db 'WS_EX_PALETTEWINDOW',0
				dd WS_EX_RIGHT
				dd WS_EX_RIGHT
				db 'WS_EX_RIGHT',0
				dd WS_EX_RIGHTSCROLLBAR
				dd WS_EX_LEFTSCROLLBAR
				db 'WS_EX_RIGHTSCROLLBAR',0
				dd WS_EX_RTLREADING
				dd WS_EX_RTLREADING
				db 'WS_EX_RTLREADING',0
				dd WS_EX_STATICEDGE
				dd WS_EX_STATICEDGE
				db 'WS_EX_STATICEDGE',0
				dd WS_EX_TOOLWINDOW
				dd WS_EX_TOOLWINDOW
				db 'WS_EX_TOOLWINDOW',0
				dd WS_EX_TOPMOST
				dd WS_EX_TOPMOST
				db 'WS_EX_TOPMOST',0
				dd WS_EX_TRANSPARENT
				dd WS_EX_TRANSPARENT
				db 'WS_EX_TRANSPARENT',0
				dd WS_EX_WINDOWEDGE
				dd WS_EX_WINDOWEDGE
				db 'WS_EX_WINDOWEDGE',0
				dd 0,0
				db 0

.data?

hIml				dd ?
hBr					dd ?
lpOldHexEditProc	dd ?

.code

HexConv proc lpBuff:DWORD,nVal:DWORD
	
	mov		eax,nVal
	mov		edx,lpBuff
	xor		ecx,ecx
	.while ecx<8
		rol		eax,4
		push	eax
		and		eax,0Fh
		.if eax<=9
			add		eax,'0'
		.else
			add		eax,'A'-10
		.endif
		mov		[edx],ax
		inc		edx
		pop		eax
		inc		ecx
	.endw
	ret

HexConv endp

ShowStyles proc uses ebx esi edi,hWin:HWND
	LOCAL	nHeight:DWORD
	LOCAL	buffer[16]:BYTE

	invoke SendMessage,hWin,WM_SETREDRAW,FALSE,0
	invoke GetWindowLong,hWin,0
	mov		ebx,eax
	invoke SendMessage,hWin,RSM_GETTOPINDEX,0,0
	push	eax
	invoke SendMessage,hWin,RSM_CLEAR,0,0
	mov		eax,[ebx].RASTYLE.ntypeid
	mov		esi,offset types
	.while dword ptr [esi].RSTYPES.ctlid!=-1
		.break .if eax==[esi].RSTYPES.ctlid
		lea		esi,[esi+sizeof RSTYPES]
	.endw
	.if !StyleEx
		lea		eax,[esi].RSTYPES.style2
		.if byte ptr [eax]
			push	eax
			invoke SendMessage,hWin,RSM_ADDITEM,0,1
			pop		eax
			.if [ebx].RASTYLE.G1Visible
				call	AddStyles
			.endif
		.endif
		lea		eax,[esi].RSTYPES.style3
		.if byte ptr [eax]
			.if [ebx].RASTYLE.G1Visible
				call	AddStyles
			.endif
		.endif
	.endif
	lea		eax,[esi].RSTYPES.style1
	.if byte ptr [eax]
		push	eax
		invoke SendMessage,hWin,RSM_ADDITEM,0,2
		pop		eax
		.if [ebx].RASTYLE.G2Visible
			call	AddStyles
		.endif
	.endif
	pop		eax
	invoke SendMessage,hWin,RSM_SETTOPINDEX,eax,0
	invoke SendMessage,hWin,WM_SETREDRAW,TRUE,0
	invoke HexConv,addr buffer,[ebx].RASTYLE.styleval
	invoke GetParent,hWin
	mov		edx,eax
	invoke SetDlgItemText,edx,IDC_EDTDWORD,addr buffer
	ret

Compare:
	xor		eax,eax
	xor		ecx,ecx
	.while byte ptr [esi+ecx]
		mov		al,[esi+ecx]
		sub		al,[edi+ecx+8]
		.break .if eax
		inc		ecx
	.endw
	retn

AddStyles:
	push	esi
	mov		esi,eax
	.if StyleEx
		mov		edi,offset rsexstyledef
	.else
		.if [ebx].RASTYLE.ntype
			mov		edi,offset rsstyledef
		.else
			mov		edi,offset rsstyledefdlg
		.endif
	.endif
	.while byte ptr [edi+8]
		call	Compare
		.if !eax
			invoke SendMessage,hWin,RSM_ADDITEM,0,edi
		.endif
		invoke lstrlen,addr [edi+8]
		lea		edi,[edi+eax+8+1]
	.endw
	pop		esi
	retn

ShowStyles endp

HexEditProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_CHAR
		mov		eax,wParam
		.if (eax>='0' && eax<='9') || (eax>='A' && eax<='F') || (eax>='a' && eax<='f') || eax==8
			jmp		ExDef
		.elseif eax==03h || eax==16h || eax==18h || eax==1Ah
			;Ctrl+C, Ctrl+V, Ctrl+X and Ctrl+Z
			jmp		ExDef
		.else
			invoke MessageBeep,0FFFFFFFFh
			xor		eax,eax
			ret
		.endif
	.endif
  ExDef:
	invoke CallWindowProc,lpOldHexEditProc,hWin,uMsg,wParam,lParam
	ret

HexEditProc endp

StyleProc proc uses ebx esi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	mDC:HDC
	LOCAL	pt:POINT
	LOCAL	rect:RECT
	LOCAL	sinf:SCROLLINFO
	LOCAL	lf:LOGFONT
	LOCAL	buffer[64]:BYTE
	LOCAL	style:DWORD
	LOCAL	exstyle:DWORD
	LOCAL	hCtl:HWND
	LOCAL	hMem:DWORD

	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke BeginPaint,hWin,addr ps
		invoke GetClientRect,hWin,addr rect
		invoke CreateCompatibleDC,ps.hdc
		mov		mDC,eax
		invoke CreateCompatibleBitmap,ps.hdc,rect.right,rect.bottom
		invoke SelectObject,mDC,eax
		push	eax
		invoke SelectObject,mDC,[ebx].RASTYLE.hfont
		push	eax
		mov		eax,[ebx].RASTYLE.backcolor
		.if sdword ptr eax<0
			and		eax,7FFFFFFFh
			invoke GetSysColor,eax
		.endif
		invoke CreateSolidBrush,eax
		push	eax
		invoke FillRect,mDC,addr ps.rcPaint,eax
		pop		eax
		invoke DeleteObject,eax
		invoke SetBkMode,mDC,TRANSPARENT
		mov		ecx,[ebx].RASTYLE.topindex
		mov		pt.y,0
		mov		edx,[ebx].RASTYLE.lpmem
		.while ecx<[ebx].RASTYLE.count
			mov		eax,pt.y
			.break .if eax>ps.rcPaint.bottom
			add		eax,[ebx].RASTYLE.itemheight
			.if eax>ps.rcPaint.top
				push	ecx
				push	edx
				push	ecx
				mov		esi,[edx+ecx*4]
				invoke GetClientRect,hWin,addr rect
				mov		eax,pt.y
				mov		rect.top,eax
				add		eax,[ebx].RASTYLE.itemheight
				.if eax>ps.rcPaint.bottom
					mov		eax,ps.rcPaint.bottom
				.endif
				mov		rect.bottom,eax
				mov		eax,[ebx].RASTYLE.textcolor
				.if sdword ptr eax<0
					and		eax,7FFFFFFFh
					invoke GetSysColor,eax
				.endif
				invoke SetTextColor,mDC,eax
				.if esi>1000
					mov		ecx,[esi+4]
					mov		edx,[esi]
					mov		eax,[ebx].RASTYLE.styleval
					and		eax,ecx
					cmp		eax,edx
					.if ZERO?
						invoke GetSysColor,COLOR_HIGHLIGHTTEXT
						invoke SetTextColor,mDC,eax
						invoke GetSysColor,COLOR_HIGHLIGHT
						invoke CreateSolidBrush,eax
						push	eax
						invoke FillRect,mDC,addr rect,eax
						pop		eax
						invoke DeleteObject,eax
					.endif
					invoke lstrlen,addr [esi+8]
					invoke TextOut,mDC,20,pt.y,addr [esi+8],eax
					invoke HexConv,addr buffer,[esi]
					invoke TextOut,mDC,180,pt.y,addr buffer,8
					mov		rect.right,18
					invoke FillRect,mDC,addr rect,hBr
				.else
					invoke GetSysColor,COLOR_BTNFACE
					invoke SetBkColor,mDC,eax
					invoke SelectObject,mDC,[ebx].RASTYLE.hboldfont
					push	eax
					push	esi
					.if esi==1
						mov		esi,offset szControlStyles
					.elseif esi==2
						mov		esi,offset szWindowStyles
						.if StyleEx
							mov		esi,offset szExWindowStyles
						.endif
					.endif
					mov		eax,ps.rcPaint.left
					mov		rect.left,eax
					mov		eax,ps.rcPaint.right
					mov		rect.right,eax
					invoke lstrlen,esi
					invoke ExtTextOut,mDC,20,pt.y,ETO_OPAQUE,addr rect,esi,eax,NULL
					pop		esi
					pop		eax
					invoke SelectObject,mDC,eax
					xor		eax,eax
					.if esi==1
						.if ![ebx].RASTYLE.G1Visible
							inc		eax
						.endif
					.elseif esi==2
						.if ![ebx].RASTYLE.G2Visible
							inc		eax
						.endif
					.endif
					mov		edx,pt.y
					add		edx,4

					invoke ImageList_Draw,hIml,eax,mDC,4,edx,ILD_NORMAL
				.endif
				pop		ecx
				.if ecx==[ebx].RASTYLE.cursel
					invoke GetClientRect,hWin,addr rect
					mov		eax,pt.y
					mov		rect.top,eax
					add		eax,[ebx].RASTYLE.itemheight
					mov		rect.bottom,eax
					invoke SetTextColor,mDC,0
					mov		rect.left,20
					invoke DrawFocusRect,mDC,addr rect
					mov		rect.left,0
				.endif
				pop		edx
				pop		ecx
			.endif
			mov		eax,[ebx].RASTYLE.itemheight
			add		pt.y,eax
			inc		ecx
		.endw
		invoke BitBlt,ps.hdc,ps.rcPaint.left,ps.rcPaint.top,ps.rcPaint.right,ps.rcPaint.bottom,mDC,ps.rcPaint.left,ps.rcPaint.top,SRCCOPY
		pop		eax
		invoke SelectObject,mDC,eax
		pop		eax
		invoke SelectObject,mDC,eax
		invoke DeleteObject,eax
		invoke DeleteDC,mDC
		invoke EndPaint,hWin,addr ps
		xor		eax,eax
	.elseif eax==WM_CREATE
		invoke GetProcessHeap
		invoke HeapAlloc,eax,HEAP_ZERO_MEMORY,sizeof RASTYLE
		mov		ebx,eax
		invoke SetWindowLong,hWin,0,ebx
		mov		[ebx].RASTYLE.cbsize,1024*32
		invoke xGlobalAlloc,GMEM_MOVEABLE,[ebx].RASTYLE.cbsize
		mov		[ebx].RASTYLE.hmem,eax
		invoke GlobalLock,[ebx].RASTYLE.hmem
		mov		[ebx].RASTYLE.lpmem,eax
		mov		[ebx].RASTYLE.cursel,-1
		mov		[ebx].RASTYLE.backcolor,80000000h or COLOR_WINDOW
		mov		[ebx].RASTYLE.textcolor,80000000h or COLOR_WINDOWTEXT
		invoke GetWindowLong,hWin,GWL_STYLE
		mov		[ebx].RASTYLE.style,eax
		mov		[ebx].RASTYLE.fredraw,TRUE
		mov		[ebx].RASTYLE.itemheight,16
		mov		[ebx].RASTYLE.G1Visible,TRUE
		mov		[ebx].RASTYLE.G2Visible,TRUE
		xor		eax,eax
	.elseif eax==WM_DESTROY
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke DeleteObject,[ebx].RASTYLE.hboldfont
		invoke GlobalUnlock,[ebx].RASTYLE.hmem
		invoke GlobalFree,[ebx].RASTYLE.hmem
		invoke GetProcessHeap
		invoke HeapFree,eax,0,ebx
		xor		eax,eax
	.elseif eax==RSM_ADDITEM
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		ecx,[ebx].RASTYLE.count
		lea		eax,[ecx*4]
		.if eax>=[ebx].RASTYLE.cbsize
			invoke GlobalUnlock,[ebx].RASTYLE.hmem
			add		[ebx].RASTYLE.cbsize,1024*32
			invoke GlobalReAlloc,[ebx].RASTYLE.hmem,[ebx].RASTYLE.cbsize,GMEM_MOVEABLE
			mov		[ebx].RASTYLE.hmem,eax
			invoke GlobalLock,[ebx].RASTYLE.hmem
			mov		[ebx].RASTYLE.lpmem,eax
			mov		ecx,[ebx].RASTYLE.count
		.endif
		mov		edx,[ebx].RASTYLE.lpmem
		mov		eax,lParam
		mov		[edx+ecx*4],eax
		inc		ecx
		mov		[ebx].RASTYLE.count,ecx
		.if [ebx].RASTYLE.fredraw
			call	SetScroll
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==RSM_DELITEM
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		.if eax<[ebx].RASTYLE.count
			mov		edx,[ebx].RASTYLE.lpmem
			.while eax<[ebx].RASTYLE.count
				mov		ecx,[edx+eax*4+4]
				mov		[edx+eax*4],ecx
				inc		eax
			.endw
			dec		[ebx].RASTYLE.count
			.if [ebx].RASTYLE.fredraw
				call	SetScroll
				invoke InvalidateRect,hWin,NULL,TRUE
			.endif
		.endif
		xor		eax,eax
	.elseif eax==RSM_GETITEM
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		.if eax<[ebx].RASTYLE.count
			mov		edx,[ebx].RASTYLE.lpmem
			mov		eax,[edx+eax*4]
		.else
			xor		eax,eax
		.endif
	.elseif eax==RSM_GETCOUNT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RASTYLE.count
	.elseif eax==RSM_CLEAR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		mov		[ebx].RASTYLE.count,eax
		mov		[ebx].RASTYLE.topindex,eax
		dec		eax
		mov		[ebx].RASTYLE.cursel,eax
		.if [ebx].RASTYLE.fredraw
			call	SetScroll
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==RSM_SETCURSEL
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		.if [ebx].RASTYLE.fredraw
			invoke SendMessage,hWin,RSM_GETITEMRECT,[ebx].RASTYLE.cursel,addr ps.rcPaint
			call	SetScroll
			invoke InvalidateRect,hWin,addr ps.rcPaint,TRUE
		.endif
		mov		eax,wParam
		.if eax<[ebx].RASTYLE.count
			mov		[ebx].RASTYLE.cursel,eax
			.if [ebx].RASTYLE.fredraw
				invoke SendMessage,hWin,RSM_GETITEMRECT,[ebx].RASTYLE.cursel,addr ps.rcPaint
				call	SetScroll
				invoke InvalidateRect,hWin,addr ps.rcPaint,TRUE
			.endif
		.else
			mov		[ebx].RASTYLE.cursel,-1
		.endif
		xor		eax,eax
	.elseif eax==RSM_GETCURSEL
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RASTYLE.cursel
	.elseif eax==RSM_GETTOPINDEX
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RASTYLE.topindex
	.elseif eax==RSM_SETTOPINDEX
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		.if eax>=[ebx].RASTYLE.count
			mov		eax,[ebx].RASTYLE.count
			.if eax
				dec		eax
			.endif
		.endif
		mov		[ebx].RASTYLE.topindex,eax
		.if [ebx].RASTYLE.fredraw
			call	SetScroll
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==RSM_GETITEMRECT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke GetClientRect,hWin,addr rect
		mov		edx,lParam
		mov		[edx].RECT.left,0
		mov		eax,rect.right
		mov		[edx].RECT.right,eax
		mov		eax,wParam
		sub		eax,[ebx].RASTYLE.topindex
		mov		ecx,[ebx].RASTYLE.itemheight
		mul		ecx
		mov		edx,lParam
		mov		[edx].RECT.top,eax
		add		eax,ecx
		mov		[edx].RECT.bottom,eax
		xor		eax,eax
	.elseif eax==RSM_SETVISIBLE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SendMessage,hWin,RSM_GETITEMRECT,[ebx].RASTYLE.cursel,addr ps.rcPaint
		invoke GetClientRect,hWin,addr rect
		mov		eax,ps.rcPaint.top
		mov		edx,ps.rcPaint.bottom
		.if sdword ptr eax<0
			mov		eax,[ebx].RASTYLE.cursel
			.if eax<[ebx].RASTYLE.count
				mov		[ebx].RASTYLE.topindex,eax
			.endif
		.elseif edx>rect.bottom
			mov		eax,rect.bottom
			mov		ecx,[ebx].RASTYLE.itemheight
			xor		edx,edx
			div		ecx
			dec		eax
			mov		edx,[ebx].RASTYLE.cursel
			sub		edx,eax
			.if CARRY?
				xor		edx,edx
			.endif
			mov		[ebx].RASTYLE.topindex,edx
		.endif
		.if [ebx].RASTYLE.fredraw
			call	SetScroll
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==RSM_SETSTYLEVAL
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,lParam
		mov		[ebx].RASTYLE.lpdialog,edx
		mov		eax,[edx].DIALOG.ntype
		mov		[ebx].RASTYLE.ntype,eax
		mov		eax,[edx].DIALOG.ntypeid
		mov		[ebx].RASTYLE.ntypeid,eax
		.if StyleEx
			mov		eax,[edx].DIALOG.exstyle
		.else
			mov		eax,[edx].DIALOG.style
		.endif
		mov		[ebx].RASTYLE.styleval,eax
		invoke ShowStyles,hWin
		xor		eax,eax
	.elseif eax==RSM_GETSTYLEVAL
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RASTYLE.styleval
	.elseif eax==RSM_UPDATESTYLEVAL
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,[ebx].RASTYLE.lpdialog
		mov		eax,wParam
		.if StyleEx
			mov		exstyle,eax
		.else
			mov		style,eax
		.endif
		mov		[ebx].RASTYLE.styleval,eax
		push	[edx].DIALOG.hwnd
		invoke ShowStyles,hWin
		pop		eax
		mov		hCtl,eax
		call	UpdateStyle
	.elseif eax==RSM_GETCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,lParam
		mov		eax,[ebx].RASTYLE.backcolor
		mov		[edx].RS_COLOR.back,eax
		mov		eax,[ebx].RASTYLE.textcolor
		mov		[edx].RS_COLOR.text,eax
		xor		eax,eax
	.elseif eax==RSM_SETCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,lParam
		mov		eax,[edx].RS_COLOR.back
		mov		[ebx].RASTYLE.backcolor,eax
		mov		eax,[edx].RS_COLOR.text
		mov		[ebx].RASTYLE.textcolor,eax
		.if [ebx].RASTYLE.fredraw
			call	SetScroll
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_SETFONT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		.if [ebx].RASTYLE.hboldfont
			invoke DeleteObject,[ebx].RASTYLE.hboldfont
		.endif
		mov		eax,wParam
		mov		[ebx].RASTYLE.hfont,eax
		invoke GetDC,hWin
		mov		ps.hdc,eax
		invoke SelectObject,ps.hdc,[ebx].RASTYLE.hfont
		push	eax
		mov		pt.x,'a'
		invoke GetTextExtentPoint32,ps.hdc,addr pt,1,addr pt
		pop		eax
		invoke SelectObject,ps.hdc,eax
		invoke ReleaseDC,hWin,ps.hdc
		mov		eax,pt.y
		inc		eax
		mov		[ebx].RASTYLE.itemheight,eax
		invoke GetObject,[ebx].RASTYLE.hfont,sizeof LOGFONT,addr lf
		mov		lf.lfWeight,800
		invoke CreateFontIndirect,addr lf
		mov		[ebx].RASTYLE.hboldfont,eax
		.if lParam
			call	SetScroll
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_LBUTTONDBLCLK
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SendMessage,hWin,WM_LBUTTONDOWN,wParam,lParam
		invoke GetCapture
		.if eax==hWin
			invoke ReleaseCapture
		.endif
		mov		eax,[ebx].RASTYLE.cursel
		.if eax<[ebx].RASTYLE.count
			mov		edx,[ebx].RASTYLE.lpmem
			mov		esi,[edx+eax*4]
			.if esi==1 || esi==2
				call	FlipStyle
			.endif
		.endif
		xor		eax,eax
	.elseif eax==WM_LBUTTONDOWN
		invoke SetFocus,hWin
		invoke SetCapture,hWin
		invoke SendMessage,hWin,WM_MOUSEMOVE,wParam,lParam
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RASTYLE.cursel
		.if eax<[ebx].RASTYLE.count
			mov		edx,[ebx].RASTYLE.lpmem
			mov		esi,[edx+eax*4]
			.if esi==1 || esi==2
				invoke ReleaseCapture
				mov		eax,lParam
				movsx	eax,ax
				.if sdword ptr eax>=4 && sdword ptr eax<4+9
					invoke SendMessage,hWin,RSM_GETITEMRECT,[ebx].RASTYLE.cursel,addr rect
					mov		eax,lParam
					shr		eax,16
					cwde
					mov		ecx,rect.top
					add		ecx,4
					mov		edx,ecx
					add		edx,9
					.if sdword ptr eax>=ecx && sdword ptr eax<edx
						call	FlipStyle
					.endif
				.endif
			.else
				call	FlipStyle
			.endif
		.endif
		xor		eax,eax
	.elseif eax==WM_MOUSEMOVE
		invoke GetCapture
		.if eax==hWin
			invoke GetWindowLong,hWin,0
			mov		ebx,eax
			invoke GetClientRect,hWin,addr rect
			mov		eax,rect.bottom
			mov		ecx,[ebx].RASTYLE.itemheight
			xor		edx,edx
			div		ecx
			push	eax
			mul		ecx
			mov		rect.bottom,eax
			mov		eax,lParam
			shr		eax,16
			cwde
			pop		edx
			.if sdword ptr eax<0
				mov		eax,[ebx].RASTYLE.topindex
				.if eax
					dec		eax
					mov		[ebx].RASTYLE.topindex,eax
					mov		[ebx].RASTYLE.cursel,eax
					call	SetScroll
					invoke InvalidateRect,hWin,NULL,TRUE
				.endif
			.elseif eax>=rect.bottom
				mov		eax,[ebx].RASTYLE.topindex
				add		eax,edx
				.if eax<[ebx].RASTYLE.count
					inc		[ebx].RASTYLE.topindex
					mov		[ebx].RASTYLE.cursel,eax
					call	SetScroll
					invoke InvalidateRect,hWin,NULL,TRUE
				.endif
			.else
				mov		ecx,[ebx].RASTYLE.itemheight
				xor		edx,edx
				idiv	ecx
				add		eax,[ebx].RASTYLE.topindex
				.if eax<[ebx].RASTYLE.count && eax!=[ebx].RASTYLE.cursel
					push	eax
					invoke SendMessage,hWin,RSM_GETITEMRECT,[ebx].RASTYLE.cursel,addr rect
					pop		[ebx].RASTYLE.cursel
					call	SetScroll
					invoke InvalidateRect,hWin,addr rect,TRUE
					invoke SendMessage,hWin,RSM_GETITEMRECT,[ebx].RASTYLE.cursel,addr rect
					call	SetScroll
					invoke InvalidateRect,hWin,addr rect,TRUE
				.endif
			.endif
		.endif
		xor		eax,eax
	.elseif eax==WM_SETFOCUS
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,[ebx].RASTYLE.cursel
		.if sdword ptr edx>=0
			invoke SendMessage,hWin,RSM_GETITEMRECT,edx,addr rect
			call	SetScroll
			invoke InvalidateRect,hWin,addr rect,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_KILLFOCUS
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,[ebx].RASTYLE.cursel
		.if sdword ptr edx>=0
			invoke SendMessage,hWin,RSM_GETITEMRECT,edx,addr rect
			call	SetScroll
			invoke InvalidateRect,hWin,addr rect,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_LBUTTONUP
		invoke GetCapture
		.if eax==hWin
			invoke ReleaseCapture
		.endif
		xor		eax,eax
	.elseif eax==WM_KEYDOWN
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		.if [ebx].RASTYLE.count
			invoke GetClientRect,hWin,addr rect
			mov		edx,wParam
			mov		eax,lParam
			shr		eax,16
			and		eax,3FFh
			mov		ecx,[ebx].RASTYLE.cursel
			.if edx==28h && (eax==150h || eax==50h)
				;Down
				inc		ecx
				.if ecx<[ebx].RASTYLE.count
					mov		[ebx].RASTYLE.cursel,ecx
					invoke SendMessage,hWin,RSM_SETVISIBLE,0,0
				.endif
			.elseif edx==26h && (eax==148h || eax==48h)
				;Up
				.if ecx && ecx<[ebx].RASTYLE.count
					dec		ecx
					mov		[ebx].RASTYLE.cursel,ecx
					invoke SendMessage,hWin,RSM_SETVISIBLE,0,0
				.endif
			.elseif edx==21h && (eax==149h || eax==49h)
				;PgUp
				mov		eax,rect.bottom
				mov		ecx,[ebx].RASTYLE.itemheight
				xor		edx,edx
				div		ecx
				mov		ecx,eax
				mov		eax,[ebx].RASTYLE.cursel
				sub		eax,ecx
				.if CARRY?
					xor		eax,eax
				.endif
				mov		[ebx].RASTYLE.cursel,eax
				invoke SendMessage,hWin,RSM_SETVISIBLE,0,0
			.elseif edx==22h && (eax==151h || eax==51h)
				;PgDn
				mov		eax,rect.bottom
				mov		ecx,[ebx].RASTYLE.itemheight
				xor		edx,edx
				div		ecx
				add		eax,[ebx].RASTYLE.cursel
				.if eax>=[ebx].RASTYLE.count
					mov		eax,[ebx].RASTYLE.count
					dec		eax
				.endif
				mov		[ebx].RASTYLE.cursel,eax
				invoke SendMessage,hWin,RSM_SETVISIBLE,0,0
			.elseif edx==24h && (eax==147h || eax==47h)
				;Home
				mov		[ebx].RASTYLE.cursel,0
				invoke SendMessage,hWin,RSM_SETVISIBLE,0,0
			.elseif edx==23h && (eax==14Fh || eax==4Fh)
				;End
				mov		eax,[ebx].RASTYLE.count
				dec		eax
				mov		[ebx].RASTYLE.cursel,eax
				invoke SendMessage,hWin,RSM_SETVISIBLE,0,0
			.endif
		.endif
		xor		eax,eax
	.elseif eax==WM_CHAR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		.if wParam==VK_SPACE
			call	FlipStyle
		.endif
		xor		eax,eax
	.elseif eax==WM_MOUSEWHEEL
		mov		eax,wParam
		shr		eax,16
		cwde
		.if sdword ptr eax<0
			invoke PostMessage,hWin,WM_VSCROLL,SB_LINEDOWN,0
			invoke PostMessage,hWin,WM_VSCROLL,SB_LINEDOWN,0
			invoke PostMessage,hWin,WM_VSCROLL,SB_LINEDOWN,0
		.else
			invoke PostMessage,hWin,WM_VSCROLL,SB_LINEUP,0
			invoke PostMessage,hWin,WM_VSCROLL,SB_LINEUP,0
			invoke PostMessage,hWin,WM_VSCROLL,SB_LINEUP,0
		.endif
		xor		eax,eax
	.elseif eax==WM_VSCROLL
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		sinf.cbSize,sizeof sinf
		mov		sinf.fMask,SIF_ALL
		invoke GetScrollInfo,hWin,SB_VERT,addr sinf
		mov		eax,[ebx].RASTYLE.topindex
		mov		edx,wParam
		movzx	edx,dx
		.if edx==SB_THUMBTRACK || edx==SB_THUMBPOSITION
			mov		eax,sinf.nTrackPos
		.elseif edx==SB_LINEDOWN
			inc		eax
			mov		edx,sinf.nMax
			sub		edx,sinf.nPage
			inc		edx
			.if eax>edx
				mov		eax,edx
			.endif
		.elseif edx==SB_LINEUP
			.if eax
				dec		eax
			.endif
		.elseif edx==SB_PAGEDOWN
			add		eax,sinf.nPage
			mov		edx,sinf.nMax
			sub		edx,sinf.nPage
			inc		edx
			.if eax>edx
				mov		eax,edx
			.endif
		.elseif edx==SB_PAGEUP
			sub		eax,sinf.nPage
			jnb		@f
			xor		eax,eax
		  @@:
		.elseif edx==SB_BOTTOM
			mov		eax,sinf.nMax
		.elseif edx==SB_TOP
			xor		eax,eax
		.endif
		.if eax!=sinf.nPos
			mov		sinf.nPos,eax
			mov		[ebx].RASTYLE.topindex,eax
			call	SetScroll
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_GETDLGCODE
		mov		eax,DLGC_CODE
	.elseif eax==WM_SETREDRAW
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		mov		eax,wParam
		mov		[ebx].RASTYLE.fredraw,eax
		.if eax
			call	SetScroll
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret

SetScroll:
	invoke GetClientRect,hWin,addr rect
	.if rect.right && rect.bottom
		mov		sinf.cbSize,sizeof sinf
		mov		sinf.fMask,SIF_ALL
		mov		eax,rect.bottom
		cdq
		mov		ecx,[ebx].RASTYLE.itemheight
		div		ecx
		mov		sinf.nPage,eax
		mov		sinf.nMin,0
		mov		eax,[ebx].RASTYLE.count
		.if eax
			dec		eax
		.endif
		mov		sinf.nMax,eax
		mov		eax,[ebx].RASTYLE.topindex
		mov		sinf.nPos,eax
		invoke SetScrollInfo,hWin,SB_VERT,addr sinf,TRUE
	.endif
	retn

FlipStyle:
	mov		eax,[ebx].RASTYLE.cursel
	.if eax<[ebx].RASTYLE.count
		mov		edx,[ebx].RASTYLE.lpmem
		mov		esi,[edx+eax*4]
		.if esi<1000
			mov		eax,[ebx].RASTYLE.cursel
			mov		edx,[ebx].RASTYLE.lpmem
			mov		eax,[edx+eax*4]
			.if eax==1
				xor		[ebx].RASTYLE.G1Visible,TRUE
			.elseif eax==2
				xor		[ebx].RASTYLE.G2Visible,TRUE
			.endif
			push	[ebx].RASTYLE.cursel
			invoke ShowStyles,hWin
			pop		[ebx].RASTYLE.cursel
		.else
			mov		eax,[ebx].RASTYLE.styleval
			mov		ecx,[esi]
			mov		edx,[esi+4]
			and		eax,edx
			.if eax==ecx
				;Turn Off
				xor		edx,-1
				and		[ebx].RASTYLE.styleval,edx
			.else
				;Turn on
				xor		edx,-1
				and		[ebx].RASTYLE.styleval,edx
				or		[ebx].RASTYLE.styleval,ecx
			.endif
			push	[ebx].RASTYLE.cursel
			invoke ShowStyles,hWin
			pop		[ebx].RASTYLE.cursel
			mov		edx,[ebx].RASTYLE.lpdialog
			mov		eax,[ebx].RASTYLE.styleval
			.if StyleEx
				mov		exstyle,eax
			.else
				mov		style,eax
			.endif
			call	UpdateStyle
		.endif
	.endif
	retn

UpdateStyle:
	.if hMultiSel
		push	0
		mov		eax,hMultiSel
		.while eax
			push	eax
			invoke GetParent,eax
			mov		edx,eax
			pop		eax
			push	edx
			mov		ecx,8
			.while ecx
				push	ecx
				invoke GetWindowLong,eax,GWL_USERDATA
				pop		ecx
				dec		ecx
			.endw
		.endw
		.while hMultiSel
			invoke DestroyMultiSel,hMultiSel
			mov		hMultiSel,eax
		.endw
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4096
		mov		ebx,eax
		mov		hMem,eax
		pop		eax
		.while eax
			mov		hCtl,eax
			invoke GetWindowLong,hCtl,GWL_USERDATA
			mov		edx,eax
			.if StyleEx
				mov		eax,exstyle
				mov		[edx].DIALOG.exstyle,eax
			.else
				mov		eax,style
				mov		[edx].DIALOG.style,eax
			.endif
			invoke UpdateCtl,hCtl
			mov		[ebx],eax
			add		ebx,4
			pop		eax
		.endw
		mov		ebx,hMem
		.while dword ptr [ebx]
			mov		eax,[ebx]
			invoke CtlMultiSelect,eax,0
			add		ebx,4
		.endw
		invoke PropertyList,-1
	.else
		mov		eax,[ebx].RASTYLE.lpdialog
		mov		eax,[eax].DIALOG.hwnd
		mov		hCtl,eax
		invoke GetWindowLong,hCtl,GWL_USERDATA
		mov		edx,eax
		.if StyleEx
			mov		eax,exstyle
			mov		[edx].DIALOG.exstyle,eax
		.else
			mov		eax,style
			mov		[edx].DIALOG.style,eax
		.endif
		invoke UpdateCtl,hCtl
	.endif
	retn

StyleProc endp

StyleManaDialogProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	buffer[16]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SetWindowPos,hWin,0,winsize.ptstyle.x,winsize.ptstyle.y,0,0,SWP_NOREPOSITION or SWP_NOSIZE
		invoke SendDlgItemMessage,hWin,IDC_EDTDWORD,EM_LIMITTEXT,8,0
		invoke SendDlgItemMessage,hWin,IDC_LSTSTYLEMANA,RSM_SETSTYLEVAL,0,lParam
		invoke GetDlgItem,hWin,IDC_EDTDWORD
		invoke SetWindowLong,eax,GWL_WNDPROC,offset HexEditProc
		mov		lpOldHexEditProc,eax
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNUPDATE
				invoke GetDlgItemText,hWin,IDC_EDTDWORD,addr buffer,sizeof buffer
				invoke HexToBin,addr buffer
				push	eax
				invoke HexConv,addr buffer,eax
				invoke SetDlgItemText,hWin,IDC_EDTDWORD,addr buffer
				pop		eax
				invoke SendDlgItemMessage,hWin,IDC_LSTSTYLEMANA,RSM_UPDATESTYLEVAL,eax,0
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke GetWindowRect,hWin,addr rect
		mov		eax,rect.left
		mov		winsize.ptstyle.x,eax
		mov		eax,rect.top
		mov		winsize.ptstyle.y,eax
		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

StyleManaDialogProc endp


