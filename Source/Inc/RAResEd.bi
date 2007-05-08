
';Dialog memory size
'MaxMem				equ 128*1024*3
'MaxCap				equ 256
'MaxName				equ 64
'
';Dialog structures
'DLGHEAD struct
'	changed			dd ?				;Set to FALSE
'	class			db 32 dup(?)		;Set to Null string
'	menuid			db MaxName dup(?)	;Set to Null string
'	font			db 32 dup(?)		;Set to "MS Sans Serif"
'	fontsize		dd ?				;Set to 8
'	fontht			dd ?				;Set to -10
'	lang			dd ?				;Set to NULL
'	sublang			dd ?				;Set to NULL
'	undo			dd ?				;Set to NULL
'	ctlid			dd ?				;Set to 1001
'	hmnu			dd ?				;Set to NULL
'	lpmnu			dd ?				;Set to NULL
'	htlb			dd ?				;Set to NULL
'	hstb			dd ?				;Set to NULL
'	locked			dd ?				;Set to TRUE or FALSE
'	hfont			dd ?				;Set to NULL
'	charset			db ?				;Set to NULL
'	italic			db ?				;Set to NULL
'	weight			dw ?				;Set to NULL
'DLGHEAD ends
'
'DIALOG struct
'	hwnd			dd ?				;Set to TRUE
'	hdmy			dd ?				;Handle of transparent window
'	oldproc			dd ?				;Set to NULL
'	hpar			dd ?				;Set to NULL
'	hcld			dd ?				;Set to NULL
'	style			dd ?				;Set to desired style
'	exstyle			dd ?				;Set to desired ex style
'	dux				dd ?				;X position in dialog units
'	duy				dd ?				;Y position in dialog units
'	duccx			dd ?				;Width in dialog units
'	duccy			dd ?				;Height in dialog units
'	x				dd ?				;X position in pixels
'	y				dd ?				;Y position in pixels
'	ccx				dd ?				;Width in pixels
'	ccy				dd ?				;Height in pixels
'	caption			db MaxCap dup(?)	;Caption max 255+1 char
'	ntype			dd ?				;Follows ToolBox buttons Dialog=0, Edit=1, Static=2, GroupBox=3
'	ntypeid			dd ?				;Set to NULL
'	tab				dd ?				;Tab index, Dialog=0, First index=0
'	id				dd ?				;Dialog / Controls ID
'	idname			db MaxName dup(?)	;ID Name, max 63+1 chars
'	helpid			dd ?				;Help ID
'	undo			dd ?				;Set to NULL
'	himg			dd ?				;Set to NULL
'DIALOG ends
'
';Control types
'TYPES struct
'	ID				dd ?
'	lpclass			dd ?
'	partype			dd ?
'	style			dd ?
'	typemask		dd ?
'	exstyle			dd ?
'	lpidname		dd ?
'	lpcaption		dd ?
'	lprc			dd ?
'	xsize			dd ?
'	ysize			dd ?
'	nmethod			dd ?
'	methods			dd ?
'	flist			dd 4 dup(?)
'TYPES ends
'
';Menu structures
'MNUHEAD struct
'	changed			dd ?
'	menuname		db MaxName dup(?)
'	menuid			dd ?
'	startid			dd ?
'	menuex			dd ?
'	lang			dd ?
'	sublang			dd ?
'MNUHEAD ends
'
'MNUITEM struct
'	itemflag		dd ?
'	itemname		db MaxName dup(?)
'	itemid			dd ?
'	itemcaption		db 64 dup(?)
'	level			dd ?
'	ntype			dd ?
'	nstate			dd ?
'	shortcut		dd ?
'	helpid			dd ?
'MNUITEM ends
'
Type RARESEDCOLOR
	back As Integer
	text As Integer
End Type

' Dialog editor messages
#Define DEM_BASE					WM_USER+2000
#Define DEM_OPEN					DEM_BASE+1		' wParam=0, lParam=Handle of memory or NULL
#Define DEM_DELETECONTROLS		DEM_BASE+2		' wParam=0, lParam=0
#Define DEM_CANUNDO				DEM_BASE+3		' wParam=0, lParam=0, Returns TRUE or FALSE
#Define DEM_UNDO					DEM_BASE+4		' wParam=0, lParam=0
#Define DEM_CUT					DEM_BASE+5		' wParam=0, lParam=0
#Define DEM_COPY					DEM_BASE+6		' wParam=0, lParam=0
#Define DEM_CANPASTE				DEM_BASE+7		' wParam=0, lParam=0, Returns TRUE or FALSE
#Define DEM_PASTE					DEM_BASE+8		' wParam=0, lParam=0
#Define DEM_ISLOCKED				DEM_BASE+9		' wParam=0, lParam=0, Returns TRUE or FALSE
#Define DEM_LOCKCONTROLS		DEM_BASE+10		' wParam=0, lParam=TRUE or FALSE
#Define DEM_ISBACK				DEM_BASE+11		' wParam=0, lParam=0, Returns TRUE or FALSE
#Define DEM_SENDTOBACK			DEM_BASE+12		' wParam=0, lParam=0
#Define DEM_ISFRONT				DEM_BASE+13		' wParam=0, lParam=0, Returns TRUE or FALSE
#Define DEM_BRINGTOFRONT		DEM_BASE+14		' wParam=0, lParam=0
#Define DEM_ISSELECTION			DEM_BASE+15		' wParam=0, lParam=0, Returns 0=Non selected, 1=Singleselect, 2=Multiselect
#Define DEM_ALIGNSIZE			DEM_BASE+16		' wParam=0, lParam=ALIGN_XX or SIZE_XX
#Define DEM_GETMODIFY			DEM_BASE+17		' wParam=0, lParam=0, Returns TRUE or FALSE
#Define DEM_SETMODIFY			DEM_BASE+18		' wParam=TRUE or FALSE, lParam=0
#Define DEM_COMPACT				DEM_BASE+19		' wParam=0, lParam=0, Returns memory size of compacted
#Define DEM_EXPORTTORC			DEM_BASE+20		' wParam=0, lParam=0, Returns memory handle
#Define DEM_SETPOSSTATUS		DEM_BASE+21		' wParam=Handle of status window, lParam=Pane
#Define DEM_SETGRIDSIZE			DEM_BASE+22		' wParam=y-size,x-size, lParam=color
#Define DEM_ADDCONTROL			DEM_BASE+23		' wParam=handle of toolbox, lParam=lpCCDEF
#Define DEM_GETCOLOR				DEM_BASE+24		' wParam=0, lParam=lpCOLOR
#Define DEM_SETCOLOR				DEM_BASE+25		' wParam=0, lParam=lpCOLOR
#Define DEM_SHOWDIALOG			DEM_BASE+26		' wParam=0, lParam=0
#Define DEM_SHOWTABINDEX		DEM_BASE+27		' wParam=0, lParam=0
#Define DEM_EXPORTDLG			DEM_BASE+28		' wParam=0, lParam=lpszFileName
#Define DEM_AUTOID				DEM_BASE+29		' wParam=0, lParam=0
#Define DEM_GETBUTTONCOUNT		DEM_BASE+30		' wParam=0, lParam=0

' DEM_ALIGNSIZE lParam
#Define ALIGN_LEFT				1
#Define ALIGN_CENTER				2
#Define ALIGN_RIGHT				3
#Define ALIGN_TOP					4
#Define ALIGN_MIDDLE				5
#Define ALIGN_BOTTOM				6
#Define SIZE_WIDTH				7
#Define SIZE_HEIGHT				8
#Define SIZE_BOTH					9
#Define ALIGN_DLGVCENTER		10
#Define ALIGN_DLGHCENTER		11

' Menu editor messages
#Define MEM_BASE					DEM_BASE+1000
#Define MEM_OPEN					MEM_BASE+1		' wParam=0, lParam=Handle of memory or NULL

' Project messages
#Define PRO_BASE					DEM_BASE+2000
#Define PRO_OPEN					PRO_BASE+1		' wParam=Pointer to project name, lParam=Handle of memory or NULL
#Define PRO_CLOSE					PRO_BASE+2		' wParam=0, lParam=0
#Define PRO_EXPORT				PRO_BASE+3		' wParam=0, lParam=Handle of memory
#Define PRO_GETMODIFY			PRO_BASE+4		' wParam=0, lParam=0
#Define PRO_SETMODIFY			PRO_BASE+5		' wParam=TRUE or FALSE, lParam=0
#Define PRO_GETSELECTED			PRO_BASE+6		' wParam=0, lParam=0
#Define PRO_ADDITEM				PRO_BASE+7		' wParam=nType, lParam=fOpen
#Define PRO_DELITEM				PRO_BASE+8		' wParam=0, lParam=0
#Define PRO_CANUNDO				PRO_BASE+9		' wParam=0, lParam=0
#Define PRO_UNDODELETED			PRO_BASE+10		' wParam=0, lParam=0
#Define PRO_SETNAME				PRO_BASE+11		' wParam=lpszName, lParam=lpszPath
#Define PRO_SHOWNAMES			PRO_BASE+12		' wParam=0, lParam=Handle output window
#Define PRO_SETEXPORT			PRO_BASE+13		' wParam=nType, lParam=lpszDefaultFileName
#Define PRO_EXPORTNAMES			PRO_BASE+14		' wParam=0, lParam=Handle output window
#Define PRO_GETSTYLEPOS			PRO_BASE+15		' wParam=0, lParam=lpPOINT
#Define PRO_SETSTYLEPOS			PRO_BASE+16		' wParam=0, lParam=lpPOINT

' Project item types
#Define TPE_NAME					1
#Define TPE_INCLUDE				2
#Define TPE_RESOURCE				3
#Define TPE_DIALOG				4
#Define TPE_MENU					5
#Define TPE_ACCEL					6
#Define TPE_VERSION				7
#Define TPE_STRING				8
#Define TPE_LANGUAGE				9
#Define TPE_LANGUAGE				9
#Define TPE_XPMANIFEST			10
#Define TPE_RCDATA				11

'type PROJECT
'	hmem			dd ?
'	ntype			dd ?
'	delete			dd ?
'	changed			dd ?
'	lnstart			dd ?
'	lnend			dd ?
'end type
'
'type NAMEMEM
'	szname			db MaxName dup(?)
'	value			dd ?
'	delete			dd ?
'end type
'
'type INCLUDEMEM
'	szfile			db MAX_PATH dup(?)
'end type
'
'type RESOURCEMEM
'	ntype			dd ?
'	szname			db MaxName dup(?)
'	value			dd ?
'	szfile			db MAX_PATH dup(?)
'end type
'
'type STRINGMEM
'	szname			db MaxName dup(?)
'	value			dd ?
'	szstring		db 512 dup(?)
'	lang			dd ?
'	sublang			dd ?
'end type
'
'type ACCELMEM
'	szname			db MaxName dup(?)
'	value			dd ?
'	nkey			dd ?
'	nascii			dd ?
'	flag			dd ?
'	lang			dd ?
'	sublang			dd ?
'end type
'
'type VERSIONMEM
'	szname			db MaxName dup(?)
'	value			dd ?
'	fv				dd ?
'	fv1				dd ?
'	fv2				dd ?
'	fv3				dd ?
'	pv				dd ?
'	pv1				dd ?
'	pv2				dd ?
'	pv3				dd ?
'	os				dd ?
'	ft				dd ?
'	ff				dd ?
'	fts				dd ?
'	lng				dd ?
'	chs				dd ?
'end type
'
'type VERSIONITEM
'	szname			db MaxName dup(?)
'	szvalue			db 256 dup(?)
'end type
'
'type LANGUAGEMEM
'	lang			dd ?
'	sublang			dd ?
'end type
'
' Dialog Edit Window Styles
#Define DES_GRID				1
#Define DES_SNAPTOGRID		2
#Define DES_TOOLTIP			4
#Define DES_STYLEHEX			8

' Dialog edit window memory
#Define DEWM_DIALOG			0
#Define DEWM_MEMORY			4
#Define DEWM_READONLY		8
#Define DEWM_SCROLLX			12
#Define DEWM_SCROLLY			16
#Define DEWM_PROJECT			20

' Window classes global
Const szDlgEditClass="DLGEDITCLASS"
Const szToolBoxClass="TOOLBOXCLASS"
Const szPropertyClass="PROPERTYCLASS"
Const szProjectClass="PROJECTCLASS"
Const szDlgEditDummyClass="DlgEditDummy"
