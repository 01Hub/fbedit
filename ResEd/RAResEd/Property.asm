
.const

PRP_NUM_ID			equ 1
PRP_NUM_POSL		equ 2
PRP_NUM_POST		equ 3
PRP_NUM_SIZEW		equ 4
PRP_NUM_SIZEH		equ 5
PRP_NUM_STARTID		equ 6
PRP_NUM_TAB			equ 7
PRP_NUM_HELPID		equ 8

PRP_STR_NAME		equ 100
PRP_STR_CAPTION		equ 101
PRP_STR_FONT		equ 1000
PRP_STR_CLASS		equ 1001
PRP_STR_MENU		equ 1002
PRP_STR_IMAGE		equ 1005
PRP_STR_AVI			equ 1006

PRP_FUN_STYLE		equ 1003
PRP_FUN_EXSTYLE		equ 1004
PRP_FUN_LANG		equ 1007

PRP_BOOL_SYSMENU	equ 200
PRP_BOOL_MAXBUTTON	equ 201
PRP_BOOL_MINBUTTON	equ 202
PRP_BOOL_ENABLED	equ 203
PRP_BOOL_VISIBLE	equ 204
PRP_BOOL_DEFAULT	equ 205
PRP_BOOL_AUTO		equ 206
PRP_BOOL_MNEMONIC	equ 207
PRP_BOOL_WORDWRAP	equ 208
PRP_BOOL_MULTI		equ 209
PRP_BOOL_LOCK		equ 210
PRP_BOOL_CHILD		equ 211
PRP_BOOL_SIZE		equ 212
PRP_BOOL_TABSTOP	equ 213
PRP_BOOL_NOTIFY		equ 214
PRP_BOOL_WANTCR		equ 215
PRP_BOOL_SORT		equ 216
PRP_BOOL_FLAT		equ 217
PRP_BOOL_GROUP		equ 218
PRP_BOOL_ICON		equ 219
PRP_BOOL_USETAB		equ 220
PRP_BOOL_SETBUDDY	equ 221
PRP_BOOL_HIDE		equ 222
PRP_BOOL_TOPMOST	equ 223
PRP_BOOL_INTEGRAL	equ 224
PRP_BOOL_BUTTON		equ 225
PRP_BOOL_POPUP		equ 226
PRP_BOOL_OWNERDRAW	equ 227
PRP_BOOL_TRANSP		equ 228
PRP_BOOL_TIME		equ 229
PRP_BOOL_WEEK		equ 230
PRP_BOOL_TOOLTIP	equ 231
PRP_BOOL_WRAP		equ 232
PRP_BOOL_DIVIDER	equ 233
PRP_BOOL_DRAGDROP	equ 234
PRP_BOOL_SMOOTH		equ 235
PRP_BOOL_AUTOSCROLL	equ 236
PRP_BOOL_AUTOPLAY	equ 237
PRP_BOOL_AUTOSIZE	equ 238
PRP_BOOL_HASSTRINGS	equ 239

PRP_MULTI_CLIP		equ 300
PRP_MULTI_SCROLL	equ 301
PRP_MULTI_ALIGN		equ 302
PRP_MULTI_AUTOSCROLL	equ 303
PRP_MULTI_FORMAT	equ 304
PRP_MULTI_STARTPOS	equ 305
PRP_MULTI_ORIENT	equ 306
PRP_MULTI_SORT		equ 307
PRP_MULTI_OWNERDRAW	equ 308
PRP_MULTI_ELLIPSIS	equ 309

PRP_MULTI_BORDER	equ 400
PRP_MULTI_TYPE		equ 401

IDD_PROPERTY		equ 1600
IDC_EDTSTYLE		equ 3301
IDC_BTNLEFT			equ 3302
IDC_BTNRIGHT		equ 3303
IDC_BTNSET			equ 3304
IDC_STCWARN			equ 3305
IDC_STCTXT			equ 3306

.data

szStyle				db 'Style',0
szExStyle			db 'ExStyle',0

szFalse				db 'False',0
szTrue				db 'True',0
;False/True Styles
SysMDlg				dd -1 xor WS_SYSMENU,0
					dd -1 xor WS_SYSMENU,WS_SYSMENU
MaxBDlg				dd -1 xor WS_MAXIMIZEBOX,0
					dd -1 xor WS_MAXIMIZEBOX,WS_MAXIMIZEBOX
MinBDlg				dd -1 xor WS_MINIMIZEBOX,0
					dd -1 xor WS_MINIMIZEBOX,WS_MINIMIZEBOX
EnabAll				dd -1 xor WS_DISABLED,WS_DISABLED
					dd -1 xor WS_DISABLED,0
VisiAll				dd -1 xor WS_VISIBLE,0
					dd -1 xor WS_VISIBLE,WS_VISIBLE
DefaBtn				dd -1 xor BS_DEFPUSHBUTTON,0
					dd -1 xor BS_DEFPUSHBUTTON,BS_DEFPUSHBUTTON
AutoChk				dd -1 xor (BS_AUTOCHECKBOX or BS_CHECKBOX),BS_CHECKBOX
					dd -1 xor (BS_AUTOCHECKBOX or BS_CHECKBOX),BS_AUTOCHECKBOX
AutoRbt				dd -1 xor (BS_AUTORADIOBUTTON or BS_RADIOBUTTON),BS_RADIOBUTTON
					dd -1 xor (BS_AUTORADIOBUTTON or BS_RADIOBUTTON),BS_AUTORADIOBUTTON
AutoCbo				dd -1 xor CBS_AUTOHSCROLL,0
					dd -1 xor CBS_AUTOHSCROLL,CBS_AUTOHSCROLL
AutoSpn				dd -1 xor UDS_AUTOBUDDY,0
					dd -1 xor UDS_AUTOBUDDY,UDS_AUTOBUDDY
AutoTbr				dd -1 xor CCS_NORESIZE,CCS_NORESIZE 
					dd -1 xor CCS_NORESIZE,0
AutoAni				dd -1 xor ACS_AUTOPLAY,0
					dd -1 xor ACS_AUTOPLAY,ACS_AUTOPLAY
MnemStc				dd -1 xor SS_NOPREFIX,SS_NOPREFIX
					dd -1 xor SS_NOPREFIX,0
WordStc				dd -1 xor (SS_LEFTNOWORDWRAP or SS_CENTER or SS_RIGHT),SS_LEFTNOWORDWRAP
					dd -1 xor (SS_LEFTNOWORDWRAP or SS_CENTER or SS_RIGHT),0
MultEdt				dd -1 xor ES_MULTILINE,0
					dd -1 xor ES_MULTILINE,ES_MULTILINE
MultBtn				dd -1 xor BS_MULTILINE,0
					dd -1 xor BS_MULTILINE,BS_MULTILINE
MultTab				dd -1 xor TCS_MULTILINE,0
					dd -1 xor TCS_MULTILINE,TCS_MULTILINE
MultLst				dd -1 xor (LBS_MULTIPLESEL or LBS_EXTENDEDSEL),0
					dd -1 xor (LBS_MULTIPLESEL or LBS_EXTENDEDSEL),LBS_MULTIPLESEL or LBS_EXTENDEDSEL
MultMvi				dd -1 xor MCS_MULTISELECT,0
					dd -1 xor MCS_MULTISELECT,MCS_MULTISELECT
LockEdt				dd -1 xor ES_READONLY,0
					dd -1 xor ES_READONLY,ES_READONLY
ChilAll				dd -1 xor WS_CHILD,0
					dd -1 xor WS_CHILD,WS_CHILD
SizeDlg				dd -1 xor WS_SIZEBOX,0
					dd -1 xor WS_SIZEBOX,WS_SIZEBOX
SizeSbr				dd -1 xor SBARS_SIZEGRIP,0
					dd -1 xor SBARS_SIZEGRIP,SBARS_SIZEGRIP
TabSAll				dd -1 xor WS_TABSTOP,0
					dd -1 xor WS_TABSTOP,WS_TABSTOP
NotiStc				dd -1 xor SS_NOTIFY,0
					dd -1 xor SS_NOTIFY,SS_NOTIFY
NotiBtn				dd -1 xor BS_NOTIFY,0
					dd -1 xor BS_NOTIFY,BS_NOTIFY
NotiLst				dd -1 xor LBS_NOTIFY,0
					dd -1 xor LBS_NOTIFY,LBS_NOTIFY
WantEdt				dd -1 xor ES_WANTRETURN,0
					dd -1 xor ES_WANTRETURN,ES_WANTRETURN
SortCbo				dd -1 xor CBS_SORT,0
					dd -1 xor CBS_SORT,CBS_SORT
SortLst				dd -1 xor LBS_SORT,0
					dd -1 xor LBS_SORT,LBS_SORT
FlatTbr				dd -1 xor TBSTYLE_FLAT,0
					dd -1 xor TBSTYLE_FLAT,TBSTYLE_FLAT
GrouAll				dd -1 xor WS_GROUP,0
					dd -1 xor WS_GROUP,WS_GROUP
UseTLst				dd -1 xor LBS_USETABSTOPS,0
					dd -1 xor LBS_USETABSTOPS,LBS_USETABSTOPS
SetBUdn				dd -1 xor UDS_SETBUDDYINT,0
					dd -1 xor UDS_SETBUDDYINT,UDS_SETBUDDYINT
HideEdt				dd -1 xor ES_NOHIDESEL,ES_NOHIDESEL
					dd -1 xor ES_NOHIDESEL,0
HideTrv				dd -1 xor TVS_SHOWSELALWAYS,TVS_SHOWSELALWAYS
					dd -1 xor TVS_SHOWSELALWAYS,0
HideLsv				dd -1 xor LVS_SHOWSELALWAYS,LVS_SHOWSELALWAYS
					dd -1 xor LVS_SHOWSELALWAYS,0
IntHtCbo			dd -1 xor CBS_NOINTEGRALHEIGHT,CBS_NOINTEGRALHEIGHT
					dd -1 xor CBS_NOINTEGRALHEIGHT,0
IntHtLst			dd -1 xor LBS_NOINTEGRALHEIGHT,LBS_NOINTEGRALHEIGHT
					dd -1 xor LBS_NOINTEGRALHEIGHT,0
ButtTab				dd -1 xor TCS_BUTTONS,0
					dd -1 xor TCS_BUTTONS,TCS_BUTTONS
ButtTrv				dd -1 xor TVS_HASBUTTONS,0
					dd -1 xor TVS_HASBUTTONS,TVS_HASBUTTONS
ButtHdr				dd -1 xor HDS_BUTTONS,0
					dd -1 xor HDS_BUTTONS,HDS_BUTTONS
PopUAll				dd -1 xor WS_POPUP,0
					dd -1 xor WS_POPUP,WS_POPUP
OwneLsv				dd -1 xor LVS_OWNERDRAWFIXED,0
					dd -1 xor LVS_OWNERDRAWFIXED,LVS_OWNERDRAWFIXED
TranAni				dd -1 xor ACS_TRANSPARENT,0
					dd -1 xor ACS_TRANSPARENT,ACS_TRANSPARENT
TimeAni				dd -1 xor ACS_TIMER,0
					dd -1 xor ACS_TIMER,ACS_TIMER
WeekMvi				dd -1 xor MCS_WEEKNUMBERS,0
					dd -1 xor MCS_WEEKNUMBERS,MCS_WEEKNUMBERS
ToolTbr				dd -1 xor TBSTYLE_TOOLTIPS,0
					dd -1 xor TBSTYLE_TOOLTIPS,TBSTYLE_TOOLTIPS
ToolTab				dd -1 xor TCS_TOOLTIPS,0
					dd -1 xor TCS_TOOLTIPS,TCS_TOOLTIPS
WrapTbr				dd -1 xor TBSTYLE_WRAPABLE,0
					dd -1 xor TBSTYLE_WRAPABLE,TBSTYLE_WRAPABLE
DiviTbr				dd -1 xor CCS_NODIVIDER,CCS_NODIVIDER
					dd -1 xor CCS_NODIVIDER,0
DragHdr				dd -1 xor HDS_DRAGDROP,0
					dd -1 xor HDS_DRAGDROP,HDS_DRAGDROP
SmooPgb				dd -1 xor PBS_SMOOTH,0
					dd -1 xor PBS_SMOOTH,PBS_SMOOTH
HasStcb				dd -1 xor CBS_HASSTRINGS,0
					dd -1 xor CBS_HASSTRINGS,CBS_HASSTRINGS
HasStlb				dd -1 xor LBS_HASSTRINGS,0
					dd -1 xor LBS_HASSTRINGS,LBS_HASSTRINGS


;False/True ExStyles
TopMost				dd -1 xor WS_EX_TOPMOST,0
					dd -1 xor WS_EX_TOPMOST,WS_EX_TOPMOST

;Multi styles
ClipAll				db 'None,Children,Siblings,Both',0
					dd -1 xor (WS_CLIPCHILDREN or WS_CLIPSIBLINGS),0
					dd -1,0
					dd -1 xor (WS_CLIPCHILDREN or WS_CLIPSIBLINGS),WS_CLIPCHILDREN
					dd -1,0
					dd -1 xor (WS_CLIPCHILDREN or WS_CLIPSIBLINGS),WS_CLIPSIBLINGS
					dd -1,0
					dd -1 xor (WS_CLIPCHILDREN or WS_CLIPSIBLINGS),WS_CLIPCHILDREN or WS_CLIPSIBLINGS
					dd -1,0
ScroAll				db 'None,Horizontal,Vertical,Both',0
					dd -1 xor (WS_HSCROLL or WS_VSCROLL),0
					dd -1,0
					dd -1 xor (WS_HSCROLL or WS_VSCROLL),WS_HSCROLL
					dd -1,0
					dd -1 xor (WS_HSCROLL or WS_VSCROLL),WS_VSCROLL
					dd -1,0
					dd -1 xor (WS_HSCROLL or WS_VSCROLL),WS_HSCROLL or WS_VSCROLL
					dd -1,0
AligStc				db 'TopLeft,TopCenter,TopRight,CenterLeft,CenterCenter,CenterRight',0
					dd -1 xor (SS_CENTER or SS_RIGHT or SS_CENTERIMAGE),0
					dd -1,0
					dd -1 xor (SS_LEFTNOWORDWRAP or SS_CENTER or SS_RIGHT or SS_CENTERIMAGE),SS_CENTER
					dd -1,0
					dd -1 xor (SS_LEFTNOWORDWRAP or SS_CENTER or SS_RIGHT or SS_CENTERIMAGE),SS_RIGHT
					dd -1,0
					dd -1 xor (SS_CENTER or SS_RIGHT or SS_CENTERIMAGE),SS_CENTERIMAGE
					dd -1,0
					dd -1 xor (SS_LEFTNOWORDWRAP or SS_CENTER or SS_RIGHT or SS_CENTERIMAGE),SS_CENTER or SS_CENTERIMAGE
					dd -1,0
					dd -1 xor (SS_LEFTNOWORDWRAP or SS_CENTER or SS_RIGHT or SS_CENTERIMAGE),SS_RIGHT or SS_CENTERIMAGE
					dd -1,0
AligEdt				db 'Left,Center,Right',0
					dd -1 xor (ES_CENTER or ES_RIGHT),0
					dd -1,0
					dd -1 xor (ES_CENTER or ES_RIGHT),ES_CENTER
					dd -1,0
					dd -1 xor (ES_CENTER or ES_RIGHT),ES_RIGHT
					dd -1,0
AligBtn				db 'Default,TopLeft,TopCenter,TopRight,CenterLeft,CenterCenter,CenterRight,BottomLeft,BottomCenter,BottomRight',0
					dd -1 xor (BS_CENTER or BS_VCENTER),0
					dd -1,0
					dd -1 xor (BS_CENTER or BS_VCENTER),BS_TOP or BS_LEFT
					dd -1,0
					dd -1 xor (BS_CENTER or BS_VCENTER),BS_CENTER or BS_TOP
					dd -1,0
					dd -1 xor (BS_CENTER or BS_VCENTER),BS_TOP or BS_RIGHT
					dd -1,0
					dd -1 xor (BS_CENTER or BS_VCENTER),BS_LEFT or BS_VCENTER
					dd -1,0
					dd -1 xor (BS_CENTER or BS_VCENTER),BS_CENTER or BS_VCENTER
					dd -1,0
					dd -1 xor (BS_CENTER or BS_VCENTER),BS_RIGHT or BS_VCENTER
					dd -1,0
					dd -1 xor (BS_CENTER or BS_VCENTER),BS_BOTTOM or BS_LEFT
					dd -1,0
					dd -1 xor (BS_CENTER or BS_VCENTER),BS_CENTER or BS_BOTTOM
					dd -1,0
					dd -1 xor (BS_CENTER or BS_VCENTER),BS_BOTTOM or BS_RIGHT
					dd -1,0
AligChk				db 'Left,Right',0
					dd -1 xor (BS_LEFTTEXT),0
					dd -1,0
					dd -1 xor (BS_LEFTTEXT),BS_LEFTTEXT
					dd -1,0
AligTab				db 'Left,Top,Right,Bottom',0
					dd -1 xor (TCS_BOTTOM or TCS_VERTICAL),TCS_VERTICAL
					dd -1,0
					dd -1 xor (TCS_BOTTOM or TCS_VERTICAL),0
					dd -1,0
					dd -1 xor (TCS_BOTTOM or TCS_VERTICAL),TCS_BOTTOM or TCS_VERTICAL
					dd -1,0
					dd -1 xor (TCS_BOTTOM or TCS_VERTICAL),TCS_BOTTOM
					dd -1,0
AligLsv				db 'Left,Top',0
					dd -1 xor LVS_ALIGNLEFT,LVS_ALIGNLEFT
					dd -1,0
					dd -1 xor LVS_ALIGNLEFT,0
					dd -1,0
AligSpn				db 'None,Left,Right',0
					dd -1 xor (UDS_ALIGNLEFT or UDS_ALIGNRIGHT),0
					dd -1,0
					dd -1 xor (UDS_ALIGNLEFT or UDS_ALIGNRIGHT),UDS_ALIGNLEFT
					dd -1,0
					dd -1 xor (UDS_ALIGNLEFT or UDS_ALIGNRIGHT),UDS_ALIGNRIGHT
					dd -1,0
AligIco				db 'AutoSize,Center',0
					dd -1 xor SS_CENTERIMAGE,0
					dd -1,0
					dd -1 xor SS_CENTERIMAGE,SS_CENTERIMAGE
					dd -1,0
AligTbr				db 'Left,Top,Right,Bottom',0
					dd -1 xor (CCS_VERT or CCS_BOTTOM or CCS_TOP),CCS_TOP or CCS_VERT
					dd -1,0
					dd -1 xor (CCS_VERT or CCS_BOTTOM or CCS_TOP),CCS_TOP
					dd -1,0
					dd -1 xor (CCS_VERT or CCS_BOTTOM or CCS_TOP),CCS_BOTTOM or CCS_VERT
					dd -1,0
					dd -1 xor (CCS_VERT or CCS_BOTTOM or CCS_TOP),CCS_BOTTOM
					dd -1,0
AligAni				db 'AutoSize,Center',0
					dd -1 xor ACS_CENTER,0
					dd -1,0
					dd -1 xor ACS_CENTER,ACS_CENTER
					dd -1,0
BordDlg				db 'Flat,Boarder,Dialog,Tool,ModalFrame',0
					dd -1 xor (WS_DLGFRAME or WS_BORDER or DS_MODALFRAME),0
					dd -1 xor (WS_EX_TOOLWINDOW or WS_EX_DLGMODALFRAME),0
					dd -1 xor (WS_DLGFRAME or WS_BORDER or DS_MODALFRAME),WS_BORDER
					dd -1 xor (WS_EX_TOOLWINDOW or WS_EX_DLGMODALFRAME),0
					dd -1 xor (WS_DLGFRAME or WS_BORDER or DS_MODALFRAME),WS_BORDER or WS_DLGFRAME
					dd -1 xor (WS_EX_TOOLWINDOW or WS_EX_DLGMODALFRAME),0
					dd -1 xor (WS_DLGFRAME or WS_BORDER or DS_MODALFRAME),WS_BORDER or WS_DLGFRAME
					dd -1 xor (WS_EX_TOOLWINDOW or WS_EX_DLGMODALFRAME),WS_EX_TOOLWINDOW
					dd -1 xor (WS_DLGFRAME or WS_BORDER or DS_MODALFRAME),WS_BORDER or WS_DLGFRAME or DS_MODALFRAME
					dd -1 xor (WS_EX_TOOLWINDOW or WS_EX_DLGMODALFRAME),WS_EX_DLGMODALFRAME
BordAll				db 'Flat,Boarder,Raised,Sunken,3D-Look,Edge',0
					dd -1 xor WS_BORDER,0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),0
					dd -1 xor WS_BORDER,WS_BORDER
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),0
					dd -1 xor WS_BORDER,0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),WS_EX_DLGMODALFRAME
					dd -1 xor WS_BORDER,0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),WS_EX_STATICEDGE
					dd -1 xor WS_BORDER,0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),WS_EX_CLIENTEDGE
					dd -1 xor WS_BORDER,0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),WS_EX_CLIENTEDGE or WS_EX_DLGMODALFRAME
BordStc				db 'Flat,Boarder,Raised,Sunken,3D-Look,Edge',0
					dd -1 xor (WS_BORDER or SS_SUNKEN),0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE),0
					dd -1 xor (WS_BORDER or SS_SUNKEN),WS_BORDER
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE),0
					dd -1 xor (WS_BORDER or SS_SUNKEN),0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE),WS_EX_DLGMODALFRAME
					dd -1 xor (WS_BORDER or SS_SUNKEN),SS_SUNKEN
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE),0
					dd -1 xor (WS_BORDER or SS_SUNKEN),0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE),WS_EX_CLIENTEDGE
					dd -1 xor WS_BORDER,0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE),WS_EX_CLIENTEDGE or WS_EX_DLGMODALFRAME
BordBtn				db 'Flat,Boarder,Raised,Sunken,3D-Look,Edge',0
					dd -1 xor (WS_BORDER or BS_FLAT),BS_FLAT
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),0
					dd -1 xor (WS_BORDER or BS_FLAT),WS_BORDER or BS_FLAT
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),0
					dd -1 xor (WS_BORDER or BS_FLAT),0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),WS_EX_DLGMODALFRAME
					dd -1 xor (WS_BORDER or BS_FLAT),0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),WS_EX_STATICEDGE
					dd -1 xor (WS_BORDER or BS_FLAT),0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),0
					dd -1 xor (WS_BORDER or BS_FLAT),0
					dd -1 xor (WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE or WS_EX_STATICEDGE),WS_EX_DLGMODALFRAME or WS_EX_CLIENTEDGE
TypeEdt				db 'Normal,Upper,Lower,Number,Password',0
					dd -1 xor (ES_UPPERCASE or ES_LOWERCASE or ES_PASSWORD or ES_NUMBER),0
					dd -1,0
					dd -1 xor (ES_UPPERCASE or ES_LOWERCASE or ES_PASSWORD or ES_NUMBER),ES_UPPERCASE
					dd -1,0
					dd -1 xor (ES_UPPERCASE or ES_LOWERCASE or ES_PASSWORD or ES_NUMBER),ES_LOWERCASE
					dd -1,0
					dd -1 xor (ES_UPPERCASE or ES_LOWERCASE or ES_PASSWORD or ES_NUMBER),ES_NUMBER
					dd -1,0
					dd -1 xor (ES_UPPERCASE or ES_LOWERCASE or ES_PASSWORD or ES_NUMBER),ES_PASSWORD
					dd -1,0
TypeCbo				db 'DropDownCombo,DropDownList,SimpleCombo',0
					dd -1 xor (CBS_DROPDOWN or CBS_DROPDOWNLIST or CBS_SIMPLE),CBS_DROPDOWN
					dd -1,0
					dd -1 xor (CBS_DROPDOWN or CBS_DROPDOWNLIST or CBS_SIMPLE),CBS_DROPDOWNLIST
					dd -1,0
					dd -1 xor (CBS_DROPDOWN or CBS_DROPDOWNLIST or CBS_SIMPLE),CBS_SIMPLE
					dd -1,0
TypeBtn				db 'Text,Bitmap,Icon',0
					dd -1 xor (BS_BITMAP or BS_ICON),0
					dd -1,0
					dd -1 xor (BS_BITMAP or BS_ICON),BS_BITMAP
					dd -1,0
					dd -1 xor (BS_BITMAP or BS_ICON),BS_ICON
					dd -1,0
TypeTrv				db 'NoLines,Lines,LinesAtRoot',0
					dd -1 xor (TVS_HASLINES or TVS_LINESATROOT),0
					dd -1,0
					dd -1 xor (TVS_HASLINES or TVS_LINESATROOT),TVS_HASLINES
					dd -1,0
					dd -1 xor (TVS_HASLINES or TVS_LINESATROOT),TVS_HASLINES or TVS_LINESATROOT
					dd -1,0
TypeLsv				db 'Icon,List,Report,SmallIcon',0
					dd -1 xor LVS_TYPEMASK,LVS_ICON
					dd -1,0
					dd -1 xor LVS_TYPEMASK,LVS_LIST
					dd -1,0
					dd -1 xor LVS_TYPEMASK,LVS_REPORT
					dd -1,0
					dd -1 xor LVS_TYPEMASK,LVS_SMALLICON
					dd -1,0
TypeImg				db 'Bitmap,Icon',0
					dd -1 xor (SS_BITMAP or SS_ICON),SS_BITMAP
					dd -1,0
					dd -1 xor (SS_BITMAP or SS_ICON),SS_ICON
					dd -1,0
TypeDtp				db 'Normal,UpDown,CheckBox,Both',0
					dd -1 xor 03h,00h
					dd -1,0
					dd -1 xor 03h,01h
					dd -1,0
					dd -1 xor 03h,02h
					dd -1,0
					dd -1 xor 03h,03h
					dd -1,0
TypeStc				db 'BlackRect,GrayRect,WhiteRect,HollowRect,BlackFrame,GrayFrame,WhiteFrame,EtchedFrame,H-Line,V-Line',0
					dd -1 xor 1Fh,SS_BLACKRECT
					dd -1,0
					dd -1 xor 1Fh,SS_GRAYRECT
					dd -1,0
					dd -1 xor 1Fh,SS_WHITERECT
					dd -1,0
					dd -1 xor 1Fh,SS_OWNERDRAW
					dd -1,0
					dd -1 xor 1Fh,SS_BLACKFRAME
					dd -1,0
					dd -1 xor 1Fh,SS_GRAYFRAME
					dd -1,0
					dd -1 xor 1Fh,SS_WHITEFRAME
					dd -1,0
					dd -1 xor 1Fh,SS_ETCHEDFRAME
					dd -1,0
					dd -1 xor 1Fh,SS_ETCHEDHORZ
					dd -1,0
					dd -1 xor 1Fh,SS_ETCHEDVERT
					dd -1,0
AutoEdt				db 'None,Horizontal,Vertical,Both',0
					dd -1 xor (ES_AUTOHSCROLL or ES_AUTOVSCROLL),0
					dd -1,0
					dd -1 xor (ES_AUTOHSCROLL or ES_AUTOVSCROLL),ES_AUTOHSCROLL
					dd -1,0
					dd -1 xor (ES_AUTOHSCROLL or ES_AUTOVSCROLL),ES_AUTOVSCROLL
					dd -1,0
					dd -1 xor (ES_AUTOHSCROLL or ES_AUTOVSCROLL),ES_AUTOHSCROLL or ES_AUTOVSCROLL
					dd -1,0
FormDtp				db 'Short,Medium,Long,Time',0
					dd -1 xor 0Ch,00h
					dd -1,0
					dd -1 xor 0Ch,0Ch
					dd -1,0
					dd -1 xor 0Ch,04h
					dd -1,0
					dd -1 xor 0Ch,08h
					dd -1,0
StarDlg				db 'Normal,CenterScreen,CenterMouse',0
					dd -1 xor (DS_CENTER or DS_CENTERMOUSE),0
					dd -1,0
					dd -1 xor (DS_CENTER or DS_CENTERMOUSE),DS_CENTER
					dd -1,0
					dd -1 xor (DS_CENTER or DS_CENTERMOUSE),DS_CENTERMOUSE
					dd -1,0
OriePgb				db 'Horizontal,Vertical',0
					dd -1 xor PBS_VERTICAL,0
					dd -1,0
					dd -1 xor PBS_VERTICAL,PBS_VERTICAL
					dd -1,0
OrieUdn				db 'Vertical,Horizontal',0
					dd -1 xor UDS_HORZ,0
					dd -1,0
					dd -1 xor UDS_HORZ,UDS_HORZ
					dd -1,0
SortLsv				db 'None,Ascending,Descending',0
					dd -1 xor (LVS_SORTASCENDING or LVS_SORTDESCENDING),0
					dd -1,0
					dd -1 xor (LVS_SORTASCENDING or LVS_SORTDESCENDING),LVS_SORTASCENDING
					dd -1,0
					dd -1 xor (LVS_SORTASCENDING or LVS_SORTDESCENDING),LVS_SORTDESCENDING
					dd -1,0
OwneCbo				db 'None,Fixed,Variable',0
					dd -1 xor (CBS_OWNERDRAWFIXED or CBS_OWNERDRAWVARIABLE),0
					dd -1,0
					dd -1 xor (CBS_OWNERDRAWFIXED or CBS_OWNERDRAWVARIABLE),CBS_OWNERDRAWFIXED
					dd -1,0
					dd -1 xor (CBS_OWNERDRAWFIXED or CBS_OWNERDRAWVARIABLE),CBS_OWNERDRAWVARIABLE
					dd -1,0
ElliStc				db 'None,EndEllipsis,PathEllipsis,WordEllipsis',0
					dd -1 xor SS_ELLIPSISMASK,0
					dd -1,0
					dd -1 xor SS_ELLIPSISMASK,SS_ENDELLIPSIS
					dd -1,0
					dd -1 xor SS_ELLIPSISMASK,SS_PATHELLIPSIS
					dd -1,0
					dd -1 xor SS_ELLIPSISMASK,SS_WORDELLIPSIS
					dd -1,0

szPropErr			db 'Invalid property value.',0
szStyleWarn			db 'WARNING!!',0Dh,'Some styles can make dialog editor unstable. Save before use.',0
StyleEx				dd 0
StyleOfs			dd 0
StyleTxt			dd 0
StylePos			dd 0
szStyleExTxt		db ',,,,'
					db ',,,,'
					db ',,,,'
					db 'WS_EX_LAYERED,WS_EX_APPWINDOW,WS_EX_STATICEDGE,WS_EX_CONTROLPARENT,'
					db ',WS_EX_LEFTSCROLLBAR,WS_EX_RTLREADING,WS_EX_RIGHT,'
					db ',WS_EX_CONTEXTHELP,WS_EX_CLIENTEDGE,WS_EX_WINDOWEDGE,'
					db 'WS_EX_TOOLWINDOW,WS_EX_MDICHILD,WS_EX_TRANSPARENT,WS_EX_ACCEPTFILES,'
					db 'WS_EX_TOPMOST,WS_EX_NOPARENTNOTIFY,,WS_EX_DLGMODALFRAME',0
szStyleTxt			db 'WS_POPUP,WS_CHILD,WS_MINIMIZE,WS_VISIBLE,'
					db 'WS_DISABLED,WS_CLIPSIBLINGS,WS_CLIPCHILDREN,WS_MAXIMIZE,'
					db 'WS_BORDER,WS_DLGFRAME,WS_VSCROLL,WS_HSCROLL,'
					db 'WS_SYSMENU,WS_THICKFRAME,WS_GROUP,WS_TABSTOP',0
szMaxWt				db 'QwnerDraw',0

.data?

lbtxtbuffer			db 4096 dup(?)
szLbString			db 64 dup(?)
hPrpCboDlg			dd ?
OldPrpCboDlgProc	dd ?
hPrpLstDlg			dd ?
OldPrpLstDlgProc	dd ?
hPrpEdtDlgCld		dd ?
OldPrpEdtDlgCldProc	dd ?
hPrpLstDlgCld		dd ?
OldPrpLstDlgCldProc	dd ?
hPrpBtnDlgCld		dd ?

tempbuff			db 256 dup(?)
fBtnClick			dd ?

.code

AddStyle proc uses esi,lpBuff:DWORD,nStyle:DWORD,lpStyle1:DWORD,lpStyle2:DWORD

	invoke lstrcat,lpBuff,addr szComma
	mov		esi,offset styledef
	.while byte ptr [esi+4]
		mov		eax,nStyle
		mov		edx,[esi]
		add		esi,4
		.if eax==edx
			mov		edx,lpStyle1
			call	TestStr
			.if !eax
				call	AddStr
				jmp		@f
			.else
				mov		edx,lpStyle2
				call	TestStr
				.if !eax
					call	AddStr
					jmp		@f
				.endif
			.endif
		.endif
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
	.endw
  @@:
	ret

AddStr:
	invoke lstrcat,lpBuff,esi
	retn

TestStr:
	xor		ecx,ecx
	xor		eax,eax
	inc		eax
	.while byte ptr [edx+ecx]
		mov		al,[edx+ecx]
		sub		al,[esi+ecx]
		jne		@f
		inc		ecx
	.endw
  @@:
	retn

AddStyle endp

PropertyStyleTxt proc uses ebx,hWin:HWND,lpBuff:DWORD
	LOCAL	buffer[1024]:BYTE
	LOCAL	buffer1[64]:BYTE

	mov		ebx,StyleOfs
	.if StyleEx
		invoke lstrcpy,addr buffer,addr szStyleExTxt
		mov		eax,(DIALOG ptr [ebx]).exstyle
	.else
		invoke lstrcpy,addr buffer,addr szStyleTxt
		xor		eax,eax
		mov		dword ptr buffer1,eax
		mov		dword ptr buffer1[4],eax
		mov		dword ptr buffer1[8],eax
		mov		dword ptr buffer1[12],eax
		mov		eax,(DIALOG ptr [ebx]).ntype
		.if !eax
			;Dialog
			mov		dword ptr buffer1,'_SD'
		.elseif eax==1
			;Edit
			mov		dword ptr buffer1,'_SE'
		.elseif eax==2
			;Static
			mov		dword ptr buffer1,'_SS'
		.elseif eax==3
			;Groupbox
			mov		dword ptr buffer1,'_SB'
		.elseif eax==4
			;Button
			mov		dword ptr buffer1,'_SB'
		.elseif eax==5
			;CheckBox
			mov		dword ptr buffer1,'_SB'
		.elseif eax==6
			;RadioButton
			mov		dword ptr buffer1,'_SB'
		.elseif eax==7
			;ComboBox
			mov		dword ptr buffer1,'_SBC'
		.elseif eax==8
			;ListBox
			mov		dword ptr buffer1,'_SBL'
		.elseif eax==9
			;H-ScrollBar
			mov		dword ptr buffer1,'_SBS'
		.elseif eax==10
			;V-ScrollBar
			mov		dword ptr buffer1,'_SBS'
		.elseif eax==11
			;TabControl
			mov		dword ptr buffer1,'_SCT'
		.elseif eax==12
			;ProgressBar
			mov		dword ptr buffer1,'_SBP'
		.elseif eax==13
			;TreeView
			mov		dword ptr buffer1,'_SVT'
		.elseif eax==14
			;ListView
			mov		dword ptr buffer1,'_SVL'
		.elseif eax==15
			;TrackBar
			mov		dword ptr buffer1,'_SBT'
		.elseif eax==16
			;UpDown
			mov		dword ptr buffer1,'_SDU'
		.elseif eax==17
			;Image
		.elseif eax==18
			;ToolBar
			mov		dword ptr buffer1,'TSBT'
			mov		dword ptr buffer1[8],'_SCC'
		.elseif eax==19
			;Statusbar
			mov		dword ptr buffer1,'RABS'
			mov		dword ptr buffer1[8],'_SCC'
		.elseif eax==20
			;DateTime
			mov		dword ptr buffer1,'_STD'
		.elseif eax==21
			;MonthView
			mov		dword ptr buffer1,'_SCM'
		.elseif eax==22
			;RichEdit
		.elseif eax==23
			;UserControl
		.elseif eax==24
			;ComboBoxEx
		.elseif eax==25
			;Shape
		.elseif eax==26
			;IPAddress
		.elseif eax==27
			;AnimateControl
			mov		dword ptr buffer1,'_SCA'
		.elseif eax==28
			;HotTrack
		.elseif eax==29
			;H-Pager
			mov		dword ptr buffer1,'_SGP'
		.elseif eax==30
			;V-Pager
			mov		dword ptr buffer1,'_SGP'
		.elseif eax==31
			;ReBar
			mov		dword ptr buffer1,'_SBR'
		.elseif eax==32
			;Header
			mov		dword ptr buffer1,'_SDH'
		.endif
		mov		edx,8000h
		.while edx
			push	edx
			invoke AddStyle,addr buffer,edx,addr buffer1,addr buffer1[8]
			pop		edx
			shr		edx,1
		.endw
		mov		eax,(DIALOG ptr [ebx]).style
	.endif
	mov		ecx,32
	mov		edx,lpBuff
	.while ecx
		mov		byte ptr [edx],'0'
		shl		eax,1
		jnc		@f
		mov		byte ptr [edx],'1'
	  @@:
		inc		edx
		dec		ecx
	.endw
	mov		byte ptr [edx],0
	invoke SetDlgItemText,hWin,IDC_EDTSTYLE,lpBuff
	mov		eax,StylePos
	inc		eax
	invoke SendDlgItemMessage,hWin,IDC_EDTSTYLE,EM_SETSEL,StylePos,eax
	mov		eax,StylePos
	inc		eax
	.while eax
		push	eax
		invoke GetStrItem,addr buffer,addr buffer1
		pop		eax
		dec		eax
	.endw
	invoke SetDlgItemText,hWin,IDC_STCTXT,addr buffer1
	ret

PropertyStyleTxt endp

PropertyDlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[33]:BYTE
	LOCAL	hCtl:HWND
	LOCAL	rect:RECT
	LOCAL	prect:RECT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		StylePos,0
		invoke GetWindowRect,hPrpLstDlg,addr prect
		invoke GetWindowRect,hWin,addr rect
		;width
		mov		eax,rect.left
		sub		rect.right,eax
		;height
		mov		eax,rect.top
		sub		rect.bottom,eax
		;left
		mov		eax,prect.right
		sub		eax,rect.right		;width
		jnc		@f
		xor		eax,eax
	  @@:
		mov		rect.left,eax
		;Top
		mov		eax,rect.top
		sub		eax,95
		jnc		@f
		xor		eax,eax
	  @@:
		mov		rect.top,eax
		invoke MoveWindow,hWin,rect.left,rect.top,rect.right,rect.bottom,TRUE
		invoke SendMessage,hWin,WM_SETTEXT,0,StyleTxt
		invoke SetDlgItemText,hWin,IDC_STCWARN,addr szStyleWarn
		invoke PropertyStyleTxt,hWin,addr buffer
		invoke GetDlgItem,hWin,IDC_BTNLEFT
		mov		hCtl,eax
		invoke ImageList_GetIcon,hMnuIml,0,ILD_NORMAL
		invoke SendMessage,hCtl,BM_SETIMAGE,IMAGE_ICON,eax
		invoke GetDlgItem,hWin,IDC_BTNRIGHT
		mov		hCtl,eax
		invoke ImageList_GetIcon,hMnuIml,1,ILD_NORMAL
		invoke SendMessage,hCtl,BM_SETIMAGE,IMAGE_ICON,eax
		invoke GetDlgItem,hWin,IDC_BTNSET
		mov		hCtl,eax
		invoke ImageList_GetIcon,hMnuIml,2,ILD_NORMAL
		invoke SendMessage,hCtl,BM_SETIMAGE,IMAGE_ICON,eax
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		mov		edx,eax
		shr		edx,16
		and		eax,0FFFFh
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNLEFT
				dec		StylePos
				and		StylePos,31
				mov		eax,StylePos
				inc		eax
				invoke SendDlgItemMessage,hWin,IDC_EDTSTYLE,EM_SETSEL,StylePos,eax
				invoke PropertyStyleTxt,hWin,addr buffer
			.elseif eax==IDC_BTNRIGHT
				inc		StylePos
				and		StylePos,31
				mov		eax,StylePos
				inc		eax
				invoke SendDlgItemMessage,hWin,IDC_EDTSTYLE,EM_SETSEL,StylePos,eax
				invoke PropertyStyleTxt,hWin,addr buffer
			.elseif eax==IDC_BTNSET
				mov		ecx,StylePos
				mov		eax,80000000h
				shr		eax,cl
				mov		ecx,StyleOfs
				.if StyleEx
;					and		eax,000777FDh
					and		eax,0FFFFFFFFh
					xor		(DIALOG ptr [ecx]).exstyle,eax
				.else
					and		eax,0FFFFFFFFh
					xor		(DIALOG ptr [ecx]).style,eax
				.endif
				.if eax
					invoke GetWindowLong,hPrpLstDlg,GWL_USERDATA
					mov		hCtl,eax
					invoke UpdateCtl,hCtl
					invoke PropertyStyleTxt,hWin,addr buffer
				.endif
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.else
		mov eax,FALSE
		ret
	.endif
	mov  eax,TRUE
	ret

PropertyDlgProc endp

UpdateCbo proc uses esi,lpData:DWORD
	LOCAL	nInx:DWORD
	LOCAL	buffer[128]:BYTE
	LOCAL	buffer1[1024]:BYTE
	LOCAL	buffer2[64]:BYTE

	invoke SendMessage,hPrpCboDlg,CB_RESETCONTENT,0,0
	mov		esi,lpData
	add		esi,sizeof DLGHEAD
	assume esi:ptr DIALOG
  @@:
	mov		eax,[esi].hwnd
	.if eax
		.if eax!=-1
			mov		al,[esi].idname
			.if al
				invoke lstrcpy,addr buffer,addr [esi].idname
			.else
				invoke ResEdBinToDec,[esi].id,addr buffer
			.endif
			invoke lstrcpy,addr buffer1,addr szCtlText
			mov		eax,[esi].ntype
			inc		eax
			.while eax
				push	eax
				invoke GetStrItem,addr buffer1,addr buffer2
				pop		eax
				dec		eax
			.endw
			push	esi
			invoke lstrlen,addr buffer
			lea		esi,buffer
			add		esi,eax
			mov		al,' '
			mov		[esi],al
			inc		esi
			invoke lstrcpy,esi,addr buffer2
			pop		esi
			invoke SendMessage,hPrpCboDlg,CB_ADDSTRING,0,addr buffer
			mov		nInx,eax
			invoke SendMessage,hPrpCboDlg,CB_SETITEMDATA,nInx,[esi].hwnd
		.endif
		add		esi,sizeof DIALOG
		jmp		@b
	.endif
	assume esi:nothing
	ret

UpdateCbo endp

SetCbo proc hCtl:DWORD
	LOCAL	nInx:DWORD

	invoke SendMessage,hPrpCboDlg,CB_GETCOUNT,0,0
	mov		nInx,eax
  @@:
	.if nInx
		dec		nInx
		invoke SendMessage,hPrpCboDlg,CB_GETITEMDATA,nInx,0
		.if eax==hCtl
			invoke SendMessage,hPrpCboDlg,CB_SETCURSEL,nInx,0
		.endif
		jmp		@b
	.endif
	ret

SetCbo endp

PropListSetTxt proc uses esi,hWin:HWND
	LOCAL	nInx:DWORD
	LOCAL	buffer[512]:BYTE

	invoke SendMessage,hWin,LB_GETCURSEL,0,0
	.if eax!=LB_ERR
		mov		nInx,eax
		invoke SendMessage,hWin,LB_GETTEXT,nInx,addr buffer
		lea		esi,buffer
	  @@:
		mov		al,[esi]
		inc		esi
		cmp		al,09h
		jne		@b
		invoke SendMessage,hWin,LB_GETITEMDATA,nInx,0
		.if eax==PRP_STR_CAPTION || eax==PRP_STR_IMAGE || eax==PRP_STR_AVI
			invoke SendMessage,hPrpEdtDlgCld,EM_LIMITTEXT,MaxCap-1,0
		.elseif eax==PRP_STR_NAME
			invoke SendMessage,hPrpEdtDlgCld,EM_LIMITTEXT,MaxName-1,0
		.else
			invoke SendMessage,hPrpEdtDlgCld,EM_LIMITTEXT,31,0
		.endif
		invoke SetWindowText,hPrpEdtDlgCld,esi
	.endif
	ret

PropListSetTxt endp

PropListSetPos proc
	LOCAL	rect:RECT
	LOCAL	nInx:DWORD
	LOCAL	lbid:DWORD

	invoke ShowWindow,hPrpEdtDlgCld,SW_HIDE
	invoke ShowWindow,hPrpBtnDlgCld,SW_HIDE
	invoke SendMessage,hPrpLstDlg,LB_GETCURSEL,0,0
	.if eax!=LB_ERR
		mov		nInx,eax
		invoke SendMessage,hPrpLstDlg,LB_GETTEXT,nInx,addr lbtxtbuffer
		mov		ecx,offset lbtxtbuffer
		mov		edx,offset szLbString
		.while byte ptr [ecx]!=VK_TAB
			mov		al,[ecx]
			mov		[edx],al
			inc		ecx
			inc		edx
		.endw
		mov		byte ptr [edx],0
		invoke SendMessage,hPrpLstDlg,LB_GETITEMRECT,nInx,addr rect
		invoke SendMessage,hPrpLstDlg,LB_GETITEMDATA,nInx,0
		mov		lbid,eax
		invoke SetWindowLong,hPrpBtnDlgCld,GWL_USERDATA,eax
		mov		eax,lbid
		.if (eax>=PRP_BOOL_SYSMENU && eax<=499) || eax==PRP_STR_FONT || eax==PRP_FUN_STYLE || eax==PRP_FUN_EXSTYLE || eax==PRP_FUN_LANG || eax>65535
			mov		ecx,nPropHt
			sub		rect.right,ecx
			mov		eax,rect.right
			sub		eax,rect.left
			mov		edx,nPropWt
			add		edx,32
			sub		edx,ecx
			.if eax<edx
				mov		rect.right,edx
			.endif
			invoke SetWindowPos,hPrpBtnDlgCld,HWND_TOP,rect.right,rect.top,nPropHt,nPropHt,0
			invoke ShowWindow,hPrpBtnDlgCld,SW_SHOWNOACTIVATE
		.else
			invoke PropListSetTxt,hPrpLstDlg
			.if lbid==PRP_STR_MENU || lbid==PRP_STR_IMAGE || lbid==PRP_STR_AVI
				mov		ecx,nPropHt
				dec		ecx
				sub		rect.right,ecx
				invoke SetWindowPos,hPrpBtnDlgCld,HWND_TOP,rect.right,rect.top,nPropHt,nPropHt,0
				invoke ShowWindow,hPrpBtnDlgCld,SW_SHOWNOACTIVATE
			.endif
			mov		edx,nPropWt
			add		edx,1
			mov		rect.left,edx
			sub		rect.right,edx
			invoke SetWindowPos,hPrpEdtDlgCld,HWND_TOP,rect.left,rect.top,rect.right,nPropHt,0
			invoke ShowWindow,hPrpEdtDlgCld,SW_SHOWNOACTIVATE
			mov		rect.left,1
			mov		rect.top,0
			mov		eax,nPropHt
			mov		rect.bottom,eax
			invoke SendMessage,hPrpEdtDlgCld,EM_SETRECT,0,addr rect
		.endif
		xor		eax,eax
	.endif
	ret

PropListSetPos endp

TxtLstFalseTrue proc uses esi,CtlVal:DWORD,lpVal:DWORD

	invoke SendMessage,hPrpLstDlgCld,LB_RESETCONTENT,0,0
	invoke SendMessage,hPrpLstDlgCld,LB_ADDSTRING,0,addr szFalse
	mov		eax,lpVal
	invoke SendMessage,hPrpLstDlgCld,LB_SETITEMDATA,0,eax
	invoke SendMessage,hPrpLstDlgCld,LB_ADDSTRING,0,addr szTrue
	mov		eax,lpVal
	add		eax,8
	invoke SendMessage,hPrpLstDlgCld,LB_SETITEMDATA,1,eax
	mov		esi,lpVal
	mov		eax,[esi]
	xor		eax,-1
	and		eax,CtlVal
	.if eax==[esi+4]
		invoke SendMessage,hPrpLstDlgCld,LB_SETCURSEL,0,0
	.else
		invoke SendMessage,hPrpLstDlgCld,LB_SETCURSEL,1,0
	.endif
	ret

TxtLstFalseTrue endp

TxtLstMulti proc uses esi,CtlValSt:DWORD,CtlValExSt:DWORD,lpVal:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	buffer1[64]:BYTE
	LOCAL	nInx:DWORD

	invoke SendMessage,hPrpLstDlgCld,LB_RESETCONTENT,0,0
	invoke lstrcpy,addr buffer,lpVal
	invoke lstrlen,lpVal
	add		lpVal,eax
	inc		lpVal
 @@:
	invoke GetStrItem,addr buffer,addr buffer1
	invoke SendMessage,hPrpLstDlgCld,LB_ADDSTRING,0,addr buffer1
	mov		nInx,eax
	invoke SendMessage,hPrpLstDlgCld,LB_SETITEMDATA,nInx,lpVal
	mov		esi,lpVal
	mov		eax,[esi]
	xor		eax,-1
	and		eax,CtlValSt
	.if eax==[esi+4]
		mov		eax,[esi+8]
		xor		eax,-1
		and		eax,CtlValExSt
		.if eax==[esi+12]
			invoke SendMessage,hPrpLstDlgCld,LB_SETCURSEL,nInx,0
		.endif
	.endif
	add		lpVal,16
	mov		al,buffer[0]
	or		al,al
	jne		@b
	ret

TxtLstMulti endp

PropTxtLst proc uses esi edi,hCtl:DWORD,lbid:DWORD
	LOCAL	nType:DWORD
	LOCAL	buffer[32]:BYTE

	invoke GetWindowLong,hCtl,GWL_USERDATA
	mov		esi,eax
	assume esi:ptr DIALOG
	push	[esi].ntype
	pop		nType
	invoke SetWindowLong,hPrpLstDlgCld,GWL_USERDATA,hCtl
	mov		eax,lbid
	.if eax==PRP_BOOL_SYSMENU
		invoke TxtLstFalseTrue,[esi].style,addr SysMDlg
	.elseif eax==PRP_BOOL_MAXBUTTON
		invoke TxtLstFalseTrue,[esi].style,addr MaxBDlg
	.elseif eax==PRP_BOOL_MINBUTTON
		invoke TxtLstFalseTrue,[esi].style,addr MinBDlg
	.elseif eax==PRP_BOOL_ENABLED
		invoke TxtLstFalseTrue,[esi].style,addr EnabAll
	.elseif eax==PRP_BOOL_VISIBLE
		invoke TxtLstFalseTrue,[esi].style,addr VisiAll
	.elseif eax==PRP_BOOL_DEFAULT
		invoke TxtLstFalseTrue,[esi].style,addr DefaBtn
	.elseif eax==PRP_BOOL_AUTO
		.if nType==5
			invoke TxtLstFalseTrue,[esi].style,addr AutoChk
		.elseif nType==6
			invoke TxtLstFalseTrue,[esi].style,addr AutoRbt
		.elseif nType==16
			invoke TxtLstFalseTrue,[esi].style,addr AutoSpn
		.endif
	.elseif eax==PRP_BOOL_AUTOSCROLL
		.if nType==7
			invoke TxtLstFalseTrue,[esi].style,addr AutoCbo
		.endif
	.elseif eax==PRP_BOOL_AUTOPLAY
		.if nType==27
			invoke TxtLstFalseTrue,[esi].style,addr AutoAni
		.endif
	.elseif eax==PRP_BOOL_AUTOSIZE
		.if nType==18 || nType==19
			invoke TxtLstFalseTrue,[esi].style,addr AutoTbr
		.endif
	.elseif eax==PRP_BOOL_MNEMONIC
		invoke TxtLstFalseTrue,[esi].style,addr MnemStc
	.elseif eax==PRP_BOOL_WORDWRAP
		invoke TxtLstFalseTrue,[esi].style,addr WordStc
	.elseif eax==PRP_BOOL_MULTI
		.if nType==1 || nType==22
			invoke TxtLstFalseTrue,[esi].style,addr MultEdt
		.elseif nType==4 || nType==5 || nType==6
			invoke TxtLstFalseTrue,[esi].style,addr MultBtn
		.elseif nType==8
			invoke TxtLstFalseTrue,[esi].style,addr MultLst
		.elseif nType==11
			invoke TxtLstFalseTrue,[esi].style,addr MultTab
		.elseif nType==21
			invoke TxtLstFalseTrue,[esi].style,addr MultMvi
		.endif
	.elseif eax==PRP_BOOL_LOCK
		invoke TxtLstFalseTrue,[esi].style,addr LockEdt
	.elseif eax==PRP_BOOL_CHILD
		invoke TxtLstFalseTrue,[esi].style,addr ChilAll
	.elseif eax==PRP_BOOL_SIZE
		.if nType==0
			invoke TxtLstFalseTrue,[esi].style,addr SizeDlg
		.elseif nType==19
			invoke TxtLstFalseTrue,[esi].style,addr SizeSbr
		.endif
	.elseif eax==PRP_BOOL_TABSTOP
		invoke TxtLstFalseTrue,[esi].style,addr TabSAll
	.elseif eax==PRP_BOOL_NOTIFY
		.if nType==2 || nType==17 || nType==25
			invoke TxtLstFalseTrue,[esi].style,addr NotiStc
		.elseif nType==4 || nType==5 || nType==6
			invoke TxtLstFalseTrue,[esi].style,addr NotiBtn
		.elseif nType==8
			invoke TxtLstFalseTrue,[esi].style,addr NotiLst
		.endif
	.elseif eax==PRP_BOOL_WANTCR
		invoke TxtLstFalseTrue,[esi].style,addr WantEdt
	.elseif eax==PRP_BOOL_SORT
		.if nType==7
			invoke TxtLstFalseTrue,[esi].style,addr SortCbo
		.elseif nType==8
			invoke TxtLstFalseTrue,[esi].style,addr SortLst
		.endif
	.elseif eax==PRP_BOOL_FLAT
		invoke TxtLstFalseTrue,[esi].style,addr FlatTbr
	.elseif eax==PRP_BOOL_GROUP
		invoke TxtLstFalseTrue,[esi].style,addr GrouAll
	.elseif eax==PRP_BOOL_ICON
;		invoke TxtLstFalseTrue,[esi].style,addr IconBtn
	.elseif eax==PRP_BOOL_USETAB
		invoke TxtLstFalseTrue,[esi].style,addr UseTLst
	.elseif eax==PRP_BOOL_SETBUDDY
		invoke TxtLstFalseTrue,[esi].style,addr SetBUdn
	.elseif eax==PRP_BOOL_HIDE
		.if nType==1 || nType==22
			invoke TxtLstFalseTrue,[esi].style,addr HideEdt
		.elseif nType==13
			invoke TxtLstFalseTrue,[esi].style,addr HideTrv
		.elseif nType==14
			invoke TxtLstFalseTrue,[esi].style,addr HideLsv
		.endif
	.elseif eax==PRP_BOOL_TOPMOST
		invoke TxtLstFalseTrue,[esi].exstyle,addr TopMost
	.elseif eax==PRP_BOOL_INTEGRAL
		.if nType==7
			invoke TxtLstFalseTrue,[esi].style,addr IntHtCbo
		.elseif nType==8
			invoke TxtLstFalseTrue,[esi].style,addr IntHtLst
		.endif
	.elseif eax==PRP_BOOL_BUTTON
		.if nType==11
			invoke TxtLstFalseTrue,[esi].style,addr ButtTab
		.elseif nType==13
			invoke TxtLstFalseTrue,[esi].style,addr ButtTrv
		.elseif nType==32
			invoke TxtLstFalseTrue,[esi].style,addr ButtHdr
		.endif
	.elseif eax==PRP_BOOL_POPUP
		invoke TxtLstFalseTrue,[esi].style,addr PopUAll
	.elseif eax==PRP_BOOL_OWNERDRAW
		invoke TxtLstFalseTrue,[esi].style,addr OwneLsv
	.elseif eax==PRP_BOOL_TRANSP
		invoke TxtLstFalseTrue,[esi].style,addr TranAni
	.elseif eax==PRP_BOOL_TIME
		invoke TxtLstFalseTrue,[esi].style,addr TimeAni
	.elseif eax==PRP_BOOL_WEEK
		invoke TxtLstFalseTrue,[esi].style,addr WeekMvi
	.elseif eax==PRP_BOOL_TOOLTIP
		.if nType==11
			invoke TxtLstFalseTrue,[esi].style,addr ToolTab
		.else
			invoke TxtLstFalseTrue,[esi].style,addr ToolTbr
		.endif
	.elseif eax==PRP_BOOL_WRAP
		invoke TxtLstFalseTrue,[esi].style,addr WrapTbr
	.elseif eax==PRP_BOOL_DIVIDER
		invoke TxtLstFalseTrue,[esi].style,addr DiviTbr
	.elseif eax==PRP_BOOL_DRAGDROP
		invoke TxtLstFalseTrue,[esi].style,addr DragHdr
	.elseif eax==PRP_BOOL_SMOOTH
		invoke TxtLstFalseTrue,[esi].style,addr SmooPgb
	.elseif eax==PRP_BOOL_HASSTRINGS
		.if nType==7
			invoke TxtLstFalseTrue,[esi].style,addr HasStcb
		.elseif nType==8
			invoke TxtLstFalseTrue,[esi].style,addr HasStlb
		.endif
	.elseif eax==PRP_MULTI_CLIP
		invoke TxtLstMulti,[esi].style,[esi].exstyle,addr ClipAll
	.elseif eax==PRP_MULTI_SCROLL
		invoke TxtLstMulti,[esi].style,[esi].exstyle,addr ScroAll
	.elseif eax==PRP_MULTI_ALIGN
		.if nType==1
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AligEdt
		.elseif nType==2
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AligStc
		.elseif nType==4
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AligBtn
		.elseif nType==5 || nType==6
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AligChk
		.elseif nType==11
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AligTab
		.elseif nType==14
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AligLsv
		.elseif nType==16
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AligSpn
		.elseif nType==17
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AligIco
		.elseif nType==18 || nType==19
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AligTbr
		.elseif nType==27
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AligAni
		.endif
	.elseif eax==PRP_MULTI_AUTOSCROLL
		invoke TxtLstMulti,[esi].style,[esi].exstyle,addr AutoEdt
	.elseif eax==PRP_MULTI_FORMAT
		invoke TxtLstMulti,[esi].style,[esi].exstyle,addr FormDtp
	.elseif eax==PRP_MULTI_STARTPOS
		invoke TxtLstMulti,[esi].style,[esi].exstyle,addr StarDlg
	.elseif eax==PRP_MULTI_ORIENT
		.if nType==12
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr OriePgb
		.elseif nType==16
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr OrieUdn
		.endif
	.elseif eax==PRP_MULTI_SORT
		invoke TxtLstMulti,[esi].style,[esi].exstyle,addr SortLsv
	.elseif eax==PRP_MULTI_OWNERDRAW
		invoke TxtLstMulti,[esi].style,[esi].exstyle,addr OwneCbo
	.elseif eax==PRP_MULTI_ELLIPSIS
		invoke TxtLstMulti,[esi].style,[esi].exstyle,addr ElliStc
	.elseif eax==PRP_MULTI_BORDER
		mov		eax,nType
		.if eax==0
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr BordDlg
		.elseif eax==2 || eax==17 || eax==25
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr BordStc
		.elseif eax==3 || eax==4
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr BordBtn
		.else
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr BordAll
		.endif
	.elseif eax==PRP_MULTI_TYPE
		mov		eax,nType
		.if eax==1
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr TypeEdt
		.elseif eax==4
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr TypeBtn
		.elseif eax==7 || eax==24
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr TypeCbo
		.elseif eax==13
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr TypeTrv
		.elseif eax==14
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr TypeLsv
		.elseif eax==17
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr TypeImg
		.elseif eax==20
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr TypeDtp
		.elseif eax==25
			invoke TxtLstMulti,[esi].style,[esi].exstyle,addr TypeStc
		.endif
	.elseif eax==PRP_STR_MENU
		;Dialog Menu
		invoke SendMessage,hPrpLstDlgCld,LB_RESETCONTENT,0,0
		invoke GetWindowLong,hPrj,0
		mov		edi,eax
		.while [edi].PROJECT.hmem
			.if [edi].PROJECT.ntype==TPE_MENU
				mov		edx,[edi].PROJECT.hmem
				.if [edx].MNUHEAD.menuname
					lea		edx,[edx].MNUHEAD.menuname
				.else
					invoke ResEdBinToDec,[edx].MNUHEAD.menuid,addr buffer
					lea		edx,buffer
				.endif
				invoke SendMessage,hPrpLstDlgCld,LB_ADDSTRING,0,edx
			.endif
			lea		edi,[edi+sizeof PROJECT]
		.endw
	.elseif eax==PRP_STR_IMAGE
		;Image
		invoke SendMessage,hPrpLstDlgCld,LB_RESETCONTENT,0,0
		invoke GetWindowLong,hPrj,0
		mov		edi,eax
		.while [edi].PROJECT.hmem
			.if [edi].PROJECT.ntype==TPE_RESOURCE
				mov		edx,[edi].PROJECT.hmem
				.while [edx].RESOURCEMEM.szname || [edx].RESOURCEMEM.value
					mov		eax,[esi].DIALOG.style
					and		eax,SS_TYPEMASK
					.if eax==SS_BITMAP
						mov		eax,0
					.elseif eax==SS_ICON
						mov		eax,2
					.endif
					.if eax==[edx].RESOURCEMEM.ntype
						push	edx
						.if [edx].RESOURCEMEM.szname
							lea		edx,[edx].RESOURCEMEM.szname
						.else
							mov		buffer,'#'
							invoke ResEdBinToDec,[edx].RESOURCEMEM.value,addr buffer[1]
							lea		edx,buffer
						.endif
						invoke SendMessage,hPrpLstDlgCld,LB_ADDSTRING,0,edx
						pop		edx
					.endif
					lea		edx,[edx+sizeof RESOURCEMEM]
				.endw
			.endif
			lea		edi,[edi+sizeof PROJECT]
		.endw
	.elseif eax==PRP_STR_AVI
		;Avi
		invoke SendMessage,hPrpLstDlgCld,LB_RESETCONTENT,0,0
		invoke GetWindowLong,hPrj,0
		mov		edi,eax
		.while [edi].PROJECT.hmem
			.if [edi].PROJECT.ntype==TPE_RESOURCE
				mov		edx,[edi].PROJECT.hmem
				.while [edx].RESOURCEMEM.szname || [edx].RESOURCEMEM.value
					.if [edx].RESOURCEMEM.ntype==3
						push	edx
						.if [edx].RESOURCEMEM.szname
							lea		edx,[edx].RESOURCEMEM.szname
						.else
							mov		buffer,'#'
							invoke ResEdBinToDec,[edx].RESOURCEMEM.value,addr buffer[1]
							lea		edx,buffer
						.endif
						invoke SendMessage,hPrpLstDlgCld,LB_ADDSTRING,0,edx
						pop		edx
					.endif
					lea		edx,[edx+sizeof RESOURCEMEM]
				.endw
			.endif
			lea		edi,[edi+sizeof PROJECT]
		.endw
	.elseif eax==PRP_FUN_LANG
		;Language
	.elseif eax>65535
		;Custom control
		mov		edx,[eax+4]
		.if dword ptr [eax]==1
			invoke TxtLstFalseTrue,[esi].style,edx
		.elseif dword ptr [eax]==2
			invoke TxtLstFalseTrue,[esi].exstyle,edx
		.elseif dword ptr [eax]==3
			invoke TxtLstMulti,[esi].style,[esi].exstyle,edx
		.endif
	.endif
	assume esi:nothing
	ret

PropTxtLst endp

SetTxtLstPos proc lpRect:DWORD
	LOCAL	rect:RECT
	LOCAL	lbht:DWORD
	LOCAL	ht:DWORD

	invoke GetClientRect,hPrpLstDlg,addr rect
	mov		eax,rect.bottom
	mov		ht,eax

	invoke CopyRect,addr rect,lpRect
	invoke SendMessage,hPrpLstDlgCld,LB_GETITEMHEIGHT,0,0
	push	eax
	invoke SendMessage,hPrpLstDlgCld,LB_GETCOUNT,0,0
	.if eax>8
		mov		eax,8
	.endif
	pop		edx
	mul		edx
	add		eax,2
	mov		lbht,eax
	add		eax,rect.top
	.if eax>ht
		mov		eax,lbht
		inc		eax
		add		eax,nPropHt
		sub		rect.top,eax
	.endif
	invoke SetWindowPos,hPrpLstDlgCld,HWND_TOP,rect.left,rect.top,rect.right,lbht,0
	invoke ShowWindow,hPrpLstDlgCld,SW_SHOWNOACTIVATE
	ret

SetTxtLstPos endp

PropEditChkVal proc uses esi,lpTxt:DWORD,nTpe:DWORD,lpfErr:DWORD
	LOCAL buffer[16]:BYTE
	LOCAL val:DWORD

	mov		eax,lpfErr
	mov		dword ptr [eax],FALSE
	invoke ResEdDecToBin,lpTxt
	mov		val,eax
	invoke ResEdBinToDec,val,addr buffer
	invoke lstrcmp,lpTxt,addr buffer
	.if eax
		mov		eax,lpfErr
		mov		dword ptr [eax],TRUE
		invoke MessageBox,hPrp,addr szPropErr,addr szAppName,MB_OK or MB_ICONERROR
	.endif
	mov		eax,val
	ret

PropEditChkVal endp

PropEditUpdList proc uses esi edi,lpPtr:DWORD
	LOCAL	nInx:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	buffer1[512]:BYTE
	LOCAL	hCtl:DWORD
	LOCAL	lpTxt:DWORD
	LOCAL	fErr:DWORD
	LOCAL	lbid:DWORD
	LOCAL	val:DWORD

	mov		fErr,FALSE
	invoke SendMessage,hPrpLstDlg,LB_GETCURSEL,0,0
	.if eax!=LB_ERR
		mov		nInx,eax
		invoke SendMessage,hPrpLstDlg,LB_SETCURSEL,-1,0
		invoke ShowWindow,hPrpEdtDlgCld,SW_HIDE
		invoke ShowWindow,hPrpBtnDlgCld,SW_HIDE
		invoke ShowWindow,hPrpLstDlgCld,SW_HIDE
		;Get text
		invoke SendMessage,hPrpLstDlg,LB_GETTEXT,nInx,addr buffer
		invoke GetWindowText,hPrpEdtDlgCld,addr buffer1,sizeof buffer1
		;Find TAB char
		lea		esi,buffer
	  @@:
		mov		al,[esi]
		inc		esi
		cmp		al,09h
		jne		@b
		mov		lpTxt,esi
		;Text changed ?
		invoke lstrcmp,lpTxt,addr buffer1
		.if eax
			;Get controls hwnd
			invoke GetWindowLong,hPrpLstDlg,GWL_USERDATA
			mov		hCtl,eax
			;and ptr data
			invoke GetWindowLong,hCtl,GWL_USERDATA
			mov		esi,eax
			assume esi:ptr DIALOG
			;Get type
			invoke SendMessage,hPrpLstDlg,LB_GETITEMDATA,nInx,0
			mov		lbid,eax
			;Pos, Size, ID or HelpID
			.if eax>=PRP_NUM_ID && eax<=PRP_NUM_HELPID
				;Test valid num
				invoke PropEditChkVal,addr buffer1,lbid,addr fErr
				mov		val,eax
			.endif
			.if !fErr
				;What is changed
				mov		eax,lbid
				.if eax==PRP_STR_NAME
					invoke lstrcpy,addr [esi].idname,addr buffer1
					.if ![esi].ntype
						invoke GetWindowLong,hDEd,DEWM_PROJECT
						mov		edx,eax
						push	edx
						invoke GetProjectItemName,edx,addr buffer1
						pop		edx
						invoke SetProjectItemName,edx,addr buffer1
					.endif
				.elseif eax==PRP_NUM_ID
					push	val
					pop		[esi].id
					.if ![esi].ntype
						invoke GetWindowLong,hDEd,DEWM_PROJECT
						mov		edx,eax
						push	edx
						invoke GetProjectItemName,edx,addr buffer1
						pop		edx
						invoke SetProjectItemName,edx,addr buffer1
					.endif
				.elseif eax==PRP_NUM_POSL
					mov		eax,val
					mov		[esi].x,eax
					xor		eax,eax
					mov		[esi].dux,eax
					mov		[esi].duy,eax
					mov		[esi].duccx,eax
					mov		[esi].duccy,eax
				.elseif eax==PRP_NUM_POST
					mov		eax,val
					mov		[esi].y,eax
					xor		eax,eax
					mov		[esi].dux,eax
					mov		[esi].duy,eax
					mov		[esi].duccx,eax
					mov		[esi].duccy,eax
				.elseif eax==PRP_NUM_SIZEW
					mov		eax,val
					mov		[esi].ccx,eax
					xor		eax,eax
					mov		[esi].dux,eax
					mov		[esi].duy,eax
					mov		[esi].duccx,eax
					mov		[esi].duccy,eax
				.elseif eax==PRP_NUM_SIZEH
					mov		eax,val
					mov		[esi].ccy,eax
					xor		eax,eax
					mov		[esi].dux,eax
					mov		[esi].duy,eax
					mov		[esi].duccx,eax
					mov		[esi].duccy,eax
				.elseif eax==PRP_NUM_STARTID
					sub		esi,sizeof DLGHEAD
					push	val
					pop		(DLGHEAD ptr [esi]).ctlid
					add		esi,sizeof DLGHEAD
				.elseif eax==PRP_NUM_TAB
					invoke SetNewTab,hCtl,val
				.elseif eax==PRP_NUM_HELPID
					mov		eax,val
					mov		[esi].helpid,eax
				.elseif eax==PRP_STR_CAPTION
					invoke lstrcpy,addr [esi].caption,addr buffer1
				.elseif eax==PRP_STR_IMAGE
					invoke lstrcpy,addr [esi].caption,addr buffer1
				.elseif eax==PRP_STR_AVI
					invoke lstrcpy,addr [esi].caption,addr buffer1
				.elseif eax==PRP_STR_FONT
					mov		edx,esi
					sub		edx,sizeof DLGHEAD
					invoke lstrcpy,addr (DLGHEAD ptr [edx]).font,addr buffer1
				.elseif eax==PRP_STR_CLASS
					mov		eax,[esi].ntype
					.if eax==0
						mov		edx,esi
						sub		edx,sizeof DLGHEAD
						invoke lstrcpy,addr (DLGHEAD ptr [edx]).class,addr buffer1
					.elseif eax==23
						invoke lstrcpy,addr [esi].class,addr buffer1
					.endif
				.elseif eax==PRP_STR_MENU
					mov		edx,esi
					sub		edx,sizeof DLGHEAD
					invoke lstrcpy,addr (DLGHEAD ptr [edx]).menuid,addr buffer1
				.endif
				mov		eax,lbid
				;Is True/False Style or Multi Style changed
				mov		edi,lpPtr
				.if eax>=PRP_BOOL_SYSMENU && eax<=499
					.if eax==223
						mov		eax,[esi].exstyle
						and		eax,[edi]
						or		eax,[edi+4]
						mov		[esi].exstyle,eax
					.else
						mov		eax,[esi].style
						and		eax,[edi]
						or		eax,[edi+4]
						mov		[esi].style,eax
					.endif
					;Is Multi Style changed
					mov		eax,lbid
					.if eax>=PRP_MULTI_CLIP
						mov		eax,[esi].exstyle
						and		eax,[edi+8]
						or		eax,[edi+12]
						mov		[esi].exstyle,eax
					.endif
				.elseif eax>65535
					.if dword ptr [eax]==1
						mov		eax,[esi].style
						and		eax,[edi]
						or		eax,[edi+4]
						mov		[esi].style,eax
					.elseif dword ptr [eax]==2
						mov		eax,[esi].exstyle
						and		eax,[edi]
						or		eax,[edi+4]
						mov		[esi].exstyle,eax
					.elseif dword ptr [eax]==3
						mov		eax,[esi].style
						and		eax,[edi]
						or		eax,[edi+4]
						mov		[esi].style,eax
						mov		eax,[esi].exstyle
						and		eax,[edi+8]
						or		eax,[edi+12]
						mov		[esi].exstyle,eax
					.endif
				.endif
				invoke UpdateCtl,hCtl
				assume esi:nothing
			.endif
		.endif
	.endif
	ret

PropEditUpdList endp

ListFalseTrue proc uses esi,CtlVal:DWORD,lpVal:DWORD,lpBuff:DWORD

	mov		esi,lpVal
	mov		eax,[esi]
	xor		eax,-1
	and		eax,CtlVal
	.if eax==[esi+4]
		invoke lstrcpy,lpBuff,addr szFalse
	.else
		invoke lstrcpy,lpBuff,addr szTrue
	.endif
	ret

ListFalseTrue endp

ListMultiStyle proc uses esi,CtlValSt:DWORD,CtlValExSt:DWORD,lpVal:DWORD,lpBuff:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	buffer1[64]:BYTE

	invoke lstrcpy,addr buffer,lpVal
	invoke lstrlen,lpVal
	add		lpVal,eax
	inc		lpVal
 @@:
	invoke GetStrItem,addr buffer,addr buffer1
	mov		esi,lpVal
	mov		eax,[esi]
	xor		eax,-1
	and		eax,CtlValSt
	.if eax==[esi+4]
		mov		eax,[esi+8]
		xor		eax,-1
		and		eax,CtlValExSt
		.if eax==[esi+12]
			invoke lstrcpy,lpBuff,addr buffer1
			ret
		.endif
	.endif
	add		lpVal,16
	mov		al,buffer[0]
	or		al,al
	jne		@b
	ret

ListMultiStyle endp

GetCustProp proc nType:DWORD,nProp:DWORD

	invoke GetTypePtr,nType
	mov		edx,nProp
	sub		edx,[eax].TYPES.nmethod
	mov		eax,[eax].TYPES.methods
	.if eax
		lea		eax,[eax+edx*8]
	.endif
	ret

GetCustProp endp

PropertyList proc uses esi edi,hCtl:DWORD
	LOCAL	buffer[1024]:BYTE
	LOCAL	buffer1[512]:BYTE
	LOCAL	nType:DWORD
	LOCAL	lbid:DWORD
	LOCAL	fList1:DWORD
	LOCAL	fList2:DWORD
	LOCAL	fList3:DWORD
	LOCAL	fList4:DWORD
	LOCAL	nInx:DWORD
	LOCAL	tInx:DWORD

	invoke ShowWindow,hPrpEdtDlgCld,SW_HIDE
	invoke ShowWindow,hPrpBtnDlgCld,SW_HIDE
	invoke ShowWindow,hPrpLstDlgCld,SW_HIDE
	invoke SendMessage,hPrpCboDlg,CB_RESETCONTENT,0,0
	invoke SendMessage,hPrpLstDlg,LB_GETTOPINDEX,0,0
	mov		tInx,eax
	invoke SendMessage,hPrpLstDlg,WM_SETREDRAW,FALSE,0
	invoke SendMessage,hPrpLstDlg,LB_RESETCONTENT,0,0
	invoke SetWindowLong,hPrpLstDlg,GWL_USERDATA,hCtl
	.if hCtl
		invoke GetWindowLong,hCtl,GWL_USERDATA
		mov		esi,eax
		assume esi:ptr DIALOG
		mov		eax,[esi].ntype
		mov		nType,eax
		invoke GetTypePtr,nType
		push	(TYPES ptr [eax]).flist
		pop		fList1
		push	(TYPES ptr [eax]).flist+4
		pop		fList2
		push	(TYPES ptr [eax]).flist+8
		pop		fList3
		push	(TYPES ptr [eax]).flist+12
		pop		fList4
		invoke lstrcpy,addr buffer,addr PrAll
		mov		nInx,0
	  @@:
		invoke GetStrItem,addr buffer,addr buffer1
		xor		eax,eax
		mov		al,buffer1[0]
		or		al,al
		je		@f
		shl		fList4,1
		rcl		fList3,1
		rcl		fList2,1
		rcl		fList1,1
		.if CARRY?
			invoke lstrlen,addr buffer1
			lea		edi,buffer1[eax]
			mov		ax,09h
			stosw
			dec		edi
			mov		eax,nType
			mov		edx,nInx
			mov		lbid,0
			.if edx==0
				;(Name)
				mov		lbid,PRP_STR_NAME
				invoke lstrcpy,edi,addr [esi].idname
			.elseif edx==1
				;(ID)
				mov		lbid,PRP_NUM_ID
				invoke ResEdBinToDec,[esi].id,edi
			.elseif edx==2
				;Left
				mov		lbid,PRP_NUM_POSL
				invoke ResEdBinToDec,[esi].x,edi
			.elseif edx==3
				;Top
				mov		lbid,PRP_NUM_POST
				invoke ResEdBinToDec,[esi].y,edi
			.elseif edx==4
				;Width
				mov		lbid,PRP_NUM_SIZEW
				invoke ResEdBinToDec,[esi].ccx,edi
			.elseif edx==5
				;Height
				mov		lbid,PRP_NUM_SIZEH
				invoke ResEdBinToDec,[esi].ccy,edi
			.elseif edx==6
				;Caption
				mov		lbid,PRP_STR_CAPTION
				invoke lstrcpy,edi,addr [esi].caption
			.elseif edx==7
				;Border
				mov		lbid,PRP_MULTI_BORDER
				.if eax==0
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr BordDlg,edi
				.elseif eax==2 || eax==17 || eax==25
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr BordStc,edi
				.elseif eax==3 || eax==4
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr BordBtn,edi
				.else
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr BordAll,edi
				.endif
			.elseif edx==8
				;SysMenu
				mov		lbid,PRP_BOOL_SYSMENU
				invoke ListFalseTrue,[esi].style,addr SysMDlg,edi
			.elseif edx==9
				;MaxButton
				mov		lbid,PRP_BOOL_MAXBUTTON
				invoke ListFalseTrue,[esi].style,addr MaxBDlg,edi
			.elseif edx==10
				;MinButton
				mov		lbid,PRP_BOOL_MINBUTTON
				invoke ListFalseTrue,[esi].style,addr MinBDlg,edi
			.elseif edx==11
				;Enabled
				mov		lbid,PRP_BOOL_ENABLED
				invoke ListFalseTrue,[esi].style,addr EnabAll,edi
			.elseif edx==12
				;Visible
				mov		lbid,PRP_BOOL_VISIBLE
				invoke ListFalseTrue,[esi].style,addr VisiAll,edi
			.elseif edx==13
				;Clipping
				mov		lbid,PRP_MULTI_CLIP
				invoke ListMultiStyle,[esi].style,[esi].exstyle,addr ClipAll,edi
			.elseif edx==14
				;ScrollBar
				mov		lbid,PRP_MULTI_SCROLL
				invoke ListMultiStyle,[esi].style,[esi].exstyle,addr ScroAll,edi
			.elseif edx==15
				;Default
				mov		lbid,PRP_BOOL_DEFAULT
				invoke ListFalseTrue,[esi].style,addr DefaBtn,edi
			.elseif edx==16
				;Auto
				mov		lbid,PRP_BOOL_AUTO
				.if eax==5
					invoke ListFalseTrue,[esi].style,addr AutoChk,edi
				.elseif eax==6
					invoke ListFalseTrue,[esi].style,addr AutoRbt,edi
				.elseif eax==16
					invoke ListFalseTrue,[esi].style,addr AutoSpn,edi
				.endif
			.elseif edx==17
				;Alignment
				mov		lbid,PRP_MULTI_ALIGN
				.if eax==1
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AligEdt,edi
				.elseif eax==2
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AligStc,edi
				.elseif eax==4
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AligBtn,edi
				.elseif eax==5 || eax==6
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AligChk,edi
				.elseif eax==11
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AligTab,edi
				.elseif eax==14
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AligLsv,edi
				.elseif eax==16
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AligSpn,edi
				.elseif eax==17
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AligIco,edi
				.elseif eax==18 || eax==19
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AligTbr,edi
				.elseif eax==27
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AligAni,edi
				.endif
			.elseif edx==18
				;Mnemonic
				mov		lbid,PRP_BOOL_MNEMONIC
				invoke ListFalseTrue,[esi].style,addr MnemStc,edi
			.elseif edx==19
				;WordWrap
				mov		lbid,PRP_BOOL_WORDWRAP
				invoke ListFalseTrue,[esi].style,addr WordStc,edi
			.elseif edx==20
				;MultiLine
				mov		lbid,PRP_BOOL_MULTI
				.if eax==1 || eax==22
					invoke ListFalseTrue,[esi].style,addr MultEdt,edi
				.elseif eax==4 || eax==5 || eax==6
					invoke ListFalseTrue,[esi].style,addr MultBtn,edi
				.elseif eax==11
					invoke ListFalseTrue,[esi].style,addr MultTab,edi
				.endif
			.elseif edx==21
				;Type
				mov		lbid,PRP_MULTI_TYPE
				.if eax==1
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr TypeEdt,edi
				.elseif eax==4
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr TypeBtn,edi
				.elseif eax==7 || eax==24
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr TypeCbo,edi
				.elseif eax==13
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr TypeTrv,edi
				.elseif eax==14
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr TypeLsv,edi
				.elseif eax==17
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr TypeImg,edi
				.elseif eax==20
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr TypeDtp,edi
				.elseif eax==25
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr TypeStc,edi
				.endif
			.elseif edx==22
				;Locked
				mov		lbid,PRP_BOOL_LOCK
				invoke ListFalseTrue,[esi].style,addr LockEdt,edi
			.elseif edx==23
				;Child
				mov		lbid,PRP_BOOL_CHILD
				invoke ListFalseTrue,[esi].style,addr ChilAll,edi
			.elseif edx==24
				;SizeBorder
				mov		lbid,PRP_BOOL_SIZE
				.if eax==0
					invoke ListFalseTrue,[esi].style,addr SizeDlg,edi
				.endif
			.elseif edx==25
				;TabStop
				mov		lbid,PRP_BOOL_TABSTOP
				invoke ListFalseTrue,[esi].style,addr TabSAll,edi
			.elseif edx==26
				;Font
				mov		lbid,PRP_STR_FONT
				sub		esi,sizeof DLGHEAD
				.if byte ptr (DLGHEAD ptr [esi]).font
					mov		eax,(DLGHEAD ptr [esi]).fontsize
					invoke ResEdBinToDec,eax,edi
					invoke lstrlen,edi
					lea		edi,[edi+eax]
					mov		al,','
					stosb
				.endif
				invoke lstrcpy,edi,addr (DLGHEAD ptr [esi]).font
				add		esi,sizeof DLGHEAD
			.elseif edx==27
				;Menu
				mov		lbid,PRP_STR_MENU
				sub		esi,sizeof DLGHEAD
				invoke lstrcpy,edi,addr (DLGHEAD ptr [esi]).menuid
				add		esi,sizeof DLGHEAD
			.elseif edx==28
				;Class
				mov		lbid,PRP_STR_CLASS
				.if eax==0
					sub		esi,sizeof DLGHEAD
					invoke lstrcpy,edi,addr (DLGHEAD ptr [esi]).class
					add		esi,sizeof DLGHEAD
				.elseif eax==23
					invoke lstrcpy,edi,addr (DIALOG ptr [esi]).class
				.endif
			.elseif edx==29
				;Notify
				mov		lbid,PRP_BOOL_NOTIFY
				.if eax==2 || eax==17 || eax==25
					invoke ListFalseTrue,[esi].style,addr NotiStc,edi
				.elseif eax==4 || eax==5 || eax==6
					invoke ListFalseTrue,[esi].style,addr NotiBtn,edi
				.elseif eax==8
					invoke ListFalseTrue,[esi].style,addr NotiLst,edi
				.endif
			.elseif edx==30
				;AutoScroll
				.if eax==1 || eax==22
					mov		lbid,PRP_MULTI_AUTOSCROLL
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr AutoEdt,edi
				.elseif eax==7
					mov		lbid,PRP_BOOL_AUTOSCROLL
					invoke ListFalseTrue,[esi].style,addr AutoCbo,edi
				.endif
			.elseif edx==31
				;WantCr
				mov		lbid,PRP_BOOL_WANTCR
				invoke ListFalseTrue,[esi].style,addr WantEdt,edi
;****
			.elseif edx==32
				;Sort
				mov		lbid,PRP_BOOL_SORT
				.if eax==7
					invoke ListFalseTrue,[esi].style,addr SortCbo,edi
				.elseif eax==8
					invoke ListFalseTrue,[esi].style,addr SortLst,edi
				.elseif eax==14
					mov		lbid,PRP_MULTI_SORT
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr SortLsv,edi
				.endif
			.elseif edx==33
				;Flat
				mov		lbid,PRP_BOOL_FLAT
				invoke ListFalseTrue,[esi].style,addr FlatTbr,edi
			.elseif edx==34
				;(StartID)
				mov		lbid,PRP_NUM_STARTID
				sub		esi,sizeof DLGHEAD
				invoke ResEdBinToDec,(DLGHEAD ptr [esi]).ctlid,edi
				add		esi,sizeof DLGHEAD
			.elseif edx==35
				;TabIndex
				mov		lbid,PRP_NUM_TAB
				invoke ResEdBinToDec,[esi].tab,edi
			.elseif edx==36
				;Format
				mov		lbid,PRP_MULTI_FORMAT
				invoke ListMultiStyle,[esi].style,[esi].exstyle,addr FormDtp,edi
			.elseif edx==37
				;SizeGrip
				mov		lbid,PRP_BOOL_SIZE
				.if eax==19
					invoke ListFalseTrue,[esi].style,addr SizeSbr,edi
				.endif
			.elseif edx==38
				;Group
				mov		lbid,PRP_BOOL_GROUP
				invoke ListFalseTrue,[esi].style,addr GrouAll,edi
			.elseif edx==39
				;Icon
				mov		lbid,PRP_BOOL_ICON
			.elseif edx==40
				;UseTabs
				mov		lbid,PRP_BOOL_USETAB
				invoke ListFalseTrue,[esi].style,addr UseTLst,edi
			.elseif edx==41
				;StartupPos
				mov		lbid,PRP_MULTI_STARTPOS
				invoke ListMultiStyle,[esi].style,[esi].exstyle,addr StarDlg,edi
			.elseif edx==42
				;Orientation
				mov		lbid,PRP_MULTI_ORIENT
				.if eax==12
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr OriePgb,edi
				.elseif eax==16
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr OrieUdn,edi
				.endif
			.elseif edx==43
				;SetBuddy
				mov		lbid,PRP_BOOL_SETBUDDY
				invoke ListFalseTrue,[esi].style,addr SetBUdn,edi
			.elseif edx==44
				;MultiSelect
				mov		lbid,PRP_BOOL_MULTI
				.if eax==8
					invoke ListFalseTrue,[esi].style,addr MultLst,edi
				.elseif eax==21
					invoke ListFalseTrue,[esi].style,addr MultMvi,edi
				.endif
			.elseif edx==45
				;HideSel
				mov		lbid,PRP_BOOL_HIDE
				.if eax==1 || eax==22
					invoke ListFalseTrue,[esi].style,addr HideEdt,edi
				.elseif eax==13
					invoke ListFalseTrue,[esi].style,addr HideTrv,edi
				.elseif eax==14
					invoke ListFalseTrue,[esi].style,addr HideLsv,edi
				.endif
			.elseif edx==46
				;TopMost
				mov		lbid,PRP_BOOL_TOPMOST
				invoke ListFalseTrue,[esi].exstyle,addr TopMost,edi
			.elseif edx==47
				;xExStyle
				mov		lbid,PRP_FUN_STYLE
				mov		eax,[esi].exstyle
				invoke hexEax
				invoke lstrcpy,edi,addr strHex
			.elseif edx==48
				;xStyle
				mov		lbid,PRP_FUN_EXSTYLE
				mov		eax,[esi].style
				invoke hexEax
				invoke lstrcpy,edi,addr strHex
			.elseif edx==49
				;IntegralHgt
				mov		lbid,PRP_BOOL_INTEGRAL
				.if eax==7
					invoke ListFalseTrue,[esi].style,addr IntHtCbo,edi
				.elseif eax==8
					invoke ListFalseTrue,[esi].style,addr IntHtLst,edi
				.endif
			.elseif edx==50
				;Image
				mov		lbid,PRP_STR_IMAGE
				invoke lstrcpy,edi,addr [esi].caption
			.elseif edx==51
				;Buttons
				mov		lbid,PRP_BOOL_BUTTON
				.if eax==11
					invoke ListFalseTrue,[esi].style,addr ButtTab,edi
				.elseif eax==13
					invoke ListFalseTrue,[esi].style,addr ButtTrv,edi
				.elseif eax==32
					invoke ListFalseTrue,[esi].style,addr ButtHdr,edi
				.endif
			.elseif edx==52
				;PopUp
				mov		lbid,PRP_BOOL_POPUP
				invoke ListFalseTrue,[esi].style,addr PopUAll,edi
			.elseif edx==53
				;OwnerDraw
				mov		lbid,PRP_BOOL_OWNERDRAW
				.if eax==14
					invoke ListFalseTrue,[esi].style,addr OwneLsv,edi
				.elseif eax==7 || eax==8
					mov		lbid,PRP_MULTI_OWNERDRAW
					invoke ListMultiStyle,[esi].style,[esi].exstyle,addr OwneCbo,edi
				.endif
			.elseif edx==54
				;Transp
				mov		lbid,PRP_BOOL_TRANSP
				invoke ListFalseTrue,[esi].style,addr TranAni,edi
			.elseif edx==55
				;Timer
				mov		lbid,PRP_BOOL_TIME
				invoke ListFalseTrue,[esi].style,addr TimeAni,edi
			.elseif edx==56
				;AutoPlay
				mov		lbid,PRP_BOOL_AUTOPLAY
				.if eax==27
					invoke ListFalseTrue,[esi].style,addr AutoAni,edi
				.endif
			.elseif edx==57
				;WeekNum
				mov		lbid,PRP_BOOL_WEEK
				invoke ListFalseTrue,[esi].style,addr WeekMvi,edi
			.elseif edx==58
				;AviClip
				mov		lbid,PRP_STR_AVI
				invoke lstrcpy,edi,addr [esi].caption
			.elseif edx==59
				;AutoSize
				mov		lbid,PRP_BOOL_AUTOSIZE
				.if eax==18 || eax==19
					invoke ListFalseTrue,[esi].style,addr AutoTbr,edi
				.endif
			.elseif edx==60
				;ToolTip
				mov		lbid,PRP_BOOL_TOOLTIP
				.if eax==11
					invoke ListFalseTrue,[esi].style,addr ToolTab,edi
				.else
					invoke ListFalseTrue,[esi].style,addr ToolTbr,edi
				.endif
			.elseif edx==61
				;Wrap
				mov		lbid,PRP_BOOL_WRAP
				invoke ListFalseTrue,[esi].style,addr WrapTbr,edi
			.elseif edx==62
				;Divider
				mov		lbid,PRP_BOOL_DIVIDER
				invoke ListFalseTrue,[esi].style,addr DiviTbr,edi
			.elseif edx==63
				;DragDrop
				mov		lbid,PRP_BOOL_DRAGDROP
				invoke ListFalseTrue,[esi].style,addr DragHdr,edi
			.elseif edx==64
				;Smooth
				mov		lbid,PRP_BOOL_SMOOTH
				invoke ListFalseTrue,[esi].style,addr SmooPgb,edi
			.elseif edx==65
				;Ellipsis
				mov		lbid,PRP_MULTI_ELLIPSIS
				invoke ListMultiStyle,[esi].style,[esi].exstyle,addr ElliStc,edi
			.elseif edx==66
				;Language
				mov		lbid,PRP_FUN_LANG
				sub		esi,sizeof DLGHEAD
				mov		eax,(DLGHEAD ptr [esi]).lang
				invoke ResEdBinToDec,eax,edi
				invoke lstrlen,edi
				lea		edi,[edi+eax]
				mov		byte ptr [edi],','
				inc		edi
				mov		eax,(DLGHEAD ptr [esi]).sublang
				invoke ResEdBinToDec,eax,edi
				add		esi,sizeof DLGHEAD
			.elseif edx==67
				;HasStrings
				mov		lbid,PRP_BOOL_HASSTRINGS
				.if eax==7
					invoke ListFalseTrue,[esi].style,addr HasStcb,edi
				.elseif eax==8
					invoke ListFalseTrue,[esi].style,addr HasStlb,edi
				.endif
			.elseif edx==68
				;HelpID
				mov		lbid,PRP_NUM_HELPID
				invoke ResEdBinToDec,[esi].helpid,edi
			.elseif eax>=NoOfButtons
				;Custom properties
				invoke GetCustProp,eax,edx
				mov		lbid,eax
				.if eax
					.if dword ptr [eax]==1
						invoke ListFalseTrue,[esi].style,[eax+4],edi
					.elseif dword ptr [eax]==2
						invoke ListFalseTrue,[esi].exstyle,[eax+4],edi
					.elseif dword ptr [eax]==3
						invoke ListMultiStyle,[esi].style,[esi].exstyle,[eax+4],edi
					.endif
				.endif
			.endif
			invoke SendMessage,hPrpLstDlg,LB_ADDSTRING,0,addr buffer1
			invoke SendMessage,hPrpLstDlg,LB_SETITEMDATA,eax,lbid
		.endif
		inc		nInx
		jmp		@b
	  @@:
		invoke SendMessage,hPrpLstDlg,LB_SETTOPINDEX,tInx,0
		invoke GetWindowLong,hDEd,DEWM_MEMORY
		.if eax
			invoke UpdateCbo,eax
			invoke SetCbo,hCtl
		.endif
		assume esi:nothing
	.endif
	invoke SetFocus,hDEd
	invoke SendMessage,hPrpLstDlg,LB_FINDSTRING,-1,addr szLbString
	.if eax==LB_ERR
		xor		eax,eax
	.endif
	invoke SendMessage,hPrpLstDlg,LB_SETCURSEL,eax,0
	invoke SendMessage,hPrpLstDlg,WM_SETREDRAW,TRUE,0
	ret

PropertyList endp

PrpCboDlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	nInx:DWORD

	mov		eax,uMsg
	.if eax==WM_COMMAND
		mov		eax,wParam
		shr		eax,16
		.if eax==CBN_SELCHANGE
			invoke SendMessage,hWin,CB_GETCURSEL,0,0
			mov		nInx,eax
			invoke SendMessage,hWin,CB_GETITEMDATA,nInx,0
			invoke SizeingRect,eax,FALSE
		.endif
	.endif
	invoke CallWindowProc,OldPrpCboDlgProc,hWin,uMsg,wParam,lParam
	ret

PrpCboDlgProc endp

PrpLstDlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	nInx:DWORD
	LOCAL	rect:RECT
	LOCAL	hCtl:DWORD
	LOCAL	lbid:DWORD
	LOCAL	lf:LOGFONT
	LOCAL	hFnt:DWORD
    LOCAL	hDC:DWORD
    LOCAL	cf:CHOOSEFONT


	mov		eax,uMsg
	.if eax==WM_LBUTTONDBLCLK
		invoke SendMessage,hWin,LB_GETCURSEL,0,0
		mov		nInx,eax
		invoke SendMessage,hWin,LB_GETITEMDATA,nInx,0
		mov		lbid,eax
		.if (eax>=PRP_BOOL_SYSMENU && eax<=499) || eax>65535
			invoke SendMessage,hWin,WM_SETREDRAW,FALSE,0
			invoke SendMessage,hWin,WM_COMMAND,1,0
			invoke ShowWindow,hPrpLstDlgCld,SW_HIDE
			invoke ShowWindow,hPrpEdtDlgCld,SW_HIDE
			invoke SendMessage,hPrpLstDlgCld,LB_GETCURSEL,0,0
			inc		eax
			mov		nInx,eax
			invoke SendMessage,hPrpLstDlgCld,LB_GETCOUNT,0,0
			.if eax==nInx
				mov		nInx,0
			.endif
			invoke SendMessage,hPrpLstDlgCld,LB_SETCURSEL,nInx,0
			invoke SendMessage,hPrpLstDlgCld,WM_LBUTTONUP,0,0
			invoke SendMessage,hWin,WM_SETREDRAW,TRUE,0
			invoke SetFocus,hWin
		.elseif eax==PRP_STR_FONT || eax==PRP_STR_MENU || eax==1003 || eax==1004 || eax==PRP_STR_IMAGE || eax==PRP_STR_AVI || eax==PRP_FUN_LANG
			invoke SendMessage,hWin,WM_COMMAND,1,0
		.else
			invoke PropListSetPos
			invoke ShowWindow,hPrpEdtDlgCld,SW_SHOW
			invoke SetFocus,hPrpEdtDlgCld
			invoke SendMessage,hPrpEdtDlgCld,EM_SETSEL,0,-1
		.endif
		xor		eax,eax
		ret
	.elseif eax==WM_LBUTTONDOWN
		invoke ShowWindow,hPrpLstDlgCld,SW_HIDE
	.elseif eax==WM_MOUSEMOVE
		.if hStatus
			invoke SendMessage,hStatus,SB_SETTEXT,nStatus,offset szNULL
		.endif
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED && eax==1
			invoke GetWindowLong,hPrpLstDlgCld,GWL_STYLE
			and		eax,WS_VISIBLE
			.if eax
				invoke ShowWindow,hPrpLstDlgCld,SW_HIDE
			.else
				invoke SendMessage,hWin,LB_GETCURSEL,0,0
				.if eax!=LB_ERR
					mov		nInx,eax
					invoke GetWindowLong,hWin,GWL_USERDATA
					mov		hCtl,eax
					invoke SendMessage,hWin,LB_GETITEMDATA,nInx,0
					mov		lbid,eax
					.if eax==PRP_STR_FONT
						;Font
						invoke RtlZeroMemory,addr lf,sizeof lf
						invoke GetWindowLong,hCtl,GWL_USERDATA
						mov		esi,eax
						sub		esi,sizeof DLGHEAD
						invoke lstrcpy,addr lf.lfFaceName,addr (DLGHEAD ptr [esi]).font
						push	(DLGHEAD ptr [esi]).fontht
						pop		lf.lfHeight
						mov		al,(DLGHEAD ptr [esi]).charset
						mov		lf.lfCharSet,al
						mov		al,(DLGHEAD ptr [esi]).italic
						mov		lf.lfItalic,al
						movzx	eax,word ptr (DLGHEAD ptr [esi]).weight
						mov		lf.lfWeight,eax
						mov		cf.lStructSize,sizeof CHOOSEFONT
						invoke GetDC,hWin
						mov		hDC, eax
						mov		cf.hDC,eax
						push	hWin
						pop		cf.hWndOwner
						lea		eax,lf
						mov		cf.lpLogFont,eax
						mov		cf.iPointSize,0
						mov		cf.Flags,CF_SCREENFONTS or CF_INITTOLOGFONTSTRUCT
						mov		cf.rgbColors,0
						mov		cf.lCustData,0
						mov		cf.lpfnHook,0
						mov		cf.lpTemplateName,0
						mov		cf.hInstance,0
						mov		cf.lpszStyle,0
						mov		cf.nFontType,0
						mov		cf.Alignment,0
						mov		cf.nSizeMin,0
						mov		cf.nSizeMax,0
						invoke ChooseFont,addr cf
						push	eax
						invoke ReleaseDC,hWin,hDC
						pop		eax
						.if eax
							invoke ResetSize,esi
							.if fSizeToFont
								mov		eax,cf.iPointSize
								mov		ecx,10
								xor		edx,edx
								div		ecx
								invoke DlgResize,esi,addr (DLGHEAD ptr [esi]).font,(DLGHEAD ptr [esi]).fontsize,addr lf.lfFaceName,eax
								invoke SizeingRect,hCtl,FALSE
							.endif
							mov		eax,lf.lfHeight
							mov		(DLGHEAD ptr [esi]).fontht,eax
							mov		al,lf.lfItalic
							mov		(DLGHEAD ptr [esi]).italic,al
							mov		al,lf.lfCharSet
							mov		(DLGHEAD ptr [esi]).charset,al
							mov		eax,lf.lfWeight
							mov		(DLGHEAD ptr [esi]).weight,ax
							mov		eax,cf.iPointSize
							mov		ecx,10
							xor		edx,edx
							div		ecx
							mov		(DLGHEAD ptr [esi]).fontsize,eax
							invoke lstrcpy,addr (DLGHEAD ptr [esi]).font,addr lf.lfFaceName
							call	UpdateFont
						.endif
					.elseif eax==PRP_STR_MENU
						;Dialog Memu
						invoke SendMessage,hWin,LB_GETITEMRECT,nInx,addr rect
						mov		ecx,nPropHt
						add		rect.top,ecx
						mov		edx,nPropWt
						add		edx,1
						add		rect.left,edx
						mov		eax,rect.left
						sub		rect.right,eax
						invoke PropTxtLst,hCtl,lbid
						invoke SetTxtLstPos,addr rect
					.elseif eax==1003
						;xExStyle
						invoke GetWindowLong,hCtl,GWL_USERDATA
						mov		StyleOfs,eax
						mov		StyleTxt,offset szExStyle
						mov		StyleEx,TRUE
;						invoke DialogBoxParam,hInstance,IDD_PROPERTY,hWin,addr PropertyDlgProc,0
						invoke GetWindowLong,hCtl,GWL_USERDATA
						invoke DialogBoxParam,hInstance,IDD_DLGSTYLEMANA,hWin,addr StyleManaDialogProc,eax
						invoke SendMessage,hWin,LB_SETCURSEL,nInx,0
					.elseif eax==1004
						;;xStyle
						invoke GetWindowLong,hCtl,GWL_USERDATA
						mov		StyleOfs,eax
						mov		StyleTxt,offset szStyle
						mov		StyleEx,FALSE
;						invoke DialogBoxParam,hInstance,IDD_PROPERTY,hWin,addr PropertyDlgProc,0
						invoke GetWindowLong,hCtl,GWL_USERDATA
						invoke DialogBoxParam,hInstance,IDD_DLGSTYLEMANA,hWin,addr StyleManaDialogProc,eax
						invoke SendMessage,hWin,LB_SETCURSEL,nInx,0
					.elseif eax==PRP_STR_IMAGE
						;Image
						invoke SendMessage,hWin,LB_GETITEMRECT,nInx,addr rect
						mov		ecx,nPropHt
						add		rect.top,ecx
						mov		edx,nPropWt
						add		edx,1
						add		rect.left,edx
						mov		eax,rect.left
						sub		rect.right,eax
						invoke PropTxtLst,hCtl,lbid
						invoke SetTxtLstPos,addr rect
					.elseif eax==PRP_STR_AVI
						;Avi
						invoke SendMessage,hWin,LB_GETITEMRECT,nInx,addr rect
						mov		ecx,nPropHt
						add		rect.top,ecx
						mov		edx,nPropWt
						add		edx,1
						add		rect.left,edx
						mov		eax,rect.left
						sub		rect.right,eax
						invoke PropTxtLst,hCtl,lbid
						invoke SetTxtLstPos,addr rect
					.elseif eax==PRP_FUN_LANG
						;Language
						invoke GetWindowLong,hCtl,GWL_USERDATA
						mov		esi,eax
						sub		esi,sizeof DLGHEAD
						invoke DialogBoxParam,hInstance,IDD_LANGUAGE,hPrj,offset LanguageEditProc2,addr [esi].DLGHEAD.lang
						.if eax
							invoke PropertyList,hCtl
							invoke SetChanged,TRUE,0
						.endif
					.else
						invoke SendMessage,hWin,LB_GETITEMRECT,nInx,addr rect
						mov		ecx,nPropHt
						add		rect.top,ecx
						mov		edx,nPropWt
						add		edx,1
						add		rect.left,edx
						mov		eax,rect.left
						sub		rect.right,eax
						invoke PropTxtLst,hCtl,lbid
						invoke SetTxtLstPos,addr rect
					.endif
				.endif
			.endif
		.endif
	.elseif eax==WM_CHAR
		.if wParam==VK_RETURN
			invoke SendMessage,hWin,WM_LBUTTONDBLCLK,0,0
		.elseif wParam==VK_TAB
			invoke SetFocus,hDEd
			invoke SendMessage,hDEd,WM_KEYDOWN,VK_TAB,0
		.endif
	.elseif eax==WM_DRAWITEM
		push	esi
		mov		esi,lParam
		invoke GetWindowLong,[esi].DRAWITEMSTRUCT.hwndItem,GWL_USERDATA
		.if eax<1000 || eax>65535 || eax==PRP_STR_MENU || eax==PRP_STR_IMAGE || eax==PRP_STR_AVI
			mov		edx,DFCS_SCROLLDOWN
			mov		eax,[esi].DRAWITEMSTRUCT.itemState
			and		eax,ODS_FOCUS or ODS_SELECTED
			.if eax==ODS_FOCUS or ODS_SELECTED
				mov		edx,DFCS_SCROLLDOWN or DFCS_PUSHED
			.endif
			invoke DrawFrameControl,[esi].DRAWITEMSTRUCT.hdc,addr [esi].DRAWITEMSTRUCT.rcItem,DFC_SCROLL,edx
		.else
			mov		edx,DFCS_BUTTONPUSH
			mov		eax,[esi].DRAWITEMSTRUCT.itemState
			and		eax,ODS_FOCUS or ODS_SELECTED
			.if eax==ODS_FOCUS or ODS_SELECTED
				mov		edx,DFCS_BUTTONPUSH or DFCS_PUSHED
			.endif
			invoke DrawFrameControl,[esi].DRAWITEMSTRUCT.hdc,addr [esi].DRAWITEMSTRUCT.rcItem,DFC_BUTTON,edx
			invoke SetBkMode,[esi].DRAWITEMSTRUCT.hdc,TRANSPARENT
			invoke DrawText,[esi].DRAWITEMSTRUCT.hdc,addr szDots,3,addr [esi].DRAWITEMSTRUCT.rcItem,DT_CENTER or DT_SINGLELINE
		.endif
		pop		esi
	.elseif eax==WM_KEYDOWN
		mov		edx,wParam
		mov		eax,lParam
		shr		eax,16
		and		eax,3FFh
		.if edx==2Eh && (eax==153h || eax==53h)
			invoke SendMessage,hWin,LB_GETCURSEL,0,0
			.if eax!=LB_ERR
				invoke SendMessage,hWin,LB_GETITEMDATA,eax,0
				.if eax==PRP_STR_FONT
					invoke GetWindowLong,hWin,GWL_USERDATA
					mov		hCtl,eax
					invoke GetWindowLong,eax,GWL_USERDATA
					sub		eax,sizeof DLGHEAD
					mov		esi,eax
					mov		[esi].DLGHEAD.font,0
					mov		[esi].DLGHEAD.fontsize,0
					mov		[esi].DLGHEAD.fontht,0
					call	UpdateFont
				.endif
			.endif
		.endif
	.elseif eax==WM_VSCROLL
		invoke ShowWindow,hPrpBtnDlgCld,SW_HIDE
		invoke ShowWindow,hPrpLstDlgCld,SW_HIDE
		invoke ShowWindow,hPrpEdtDlgCld,SW_HIDE
	.elseif eax==WM_CTLCOLORLISTBOX
		invoke SetBkColor,wParam,color.back
		invoke SetTextColor,wParam,color.text
		mov		eax,hBrBack
		jmp		Ex
	.elseif eax==WM_CTLCOLOREDIT
		invoke SetBkColor,wParam,color.back
		invoke SetTextColor,wParam,color.text
		mov		eax,hBrBack
		jmp		Ex
	.endif
	invoke CallWindowProc,OldPrpLstDlgProc,hWin,uMsg,wParam,lParam
  Ex:
	assume esi:nothing
	ret

UpdateFont:
	invoke MakeDlgFont,esi
	mov		hFnt,eax
	add		esi,sizeof DLGHEAD
	assume esi:ptr DIALOG
	.while TRUE
		mov		eax,[esi].hwnd
	  .break .if !eax
		.if eax!=-1
			mov		eax,[esi].hcld
			.if eax
				invoke SendMessage,eax,WM_SETFONT,hFnt,TRUE
			.endif
			mov		eax,[esi].hwnd
			invoke SendMessage,eax,WM_SETFONT,hFnt,TRUE
			mov		eax,[esi].hcld
			.if eax
				invoke InvalidateRect,eax,NULL,TRUE
				mov		eax,[esi].hwnd
				invoke InvalidateRect,eax,NULL,TRUE
			.endif
		.endif
		add		esi,sizeof DIALOG
	.endw
	invoke PropertyList,hCtl
	invoke SetChanged,TRUE,0
	assume esi:nothing
	retn

PrpLstDlgProc endp

PrpEdtDlgCldProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	nInx:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	hCtl:HWND

	mov		eax,uMsg
	.if eax==WM_KILLFOCUS
		invoke PropEditUpdList,0
	.elseif eax==WM_CHAR
		.if wParam==VK_RETURN || wParam==VK_TAB
			invoke SendMessage,hPrpLstDlg,LB_GETCURSEL,0,0
			mov		nInx,eax
			invoke SetFocus,hDEd
			invoke SendMessage,hPrpLstDlg,LB_SETCURSEL,nInx,0
			invoke PropListSetPos
			.if wParam==VK_RETURN
				invoke SetFocus,hPrpLstDlg
			.else
				invoke SendMessage,hDEd,WM_KEYDOWN,VK_TAB,0
			.endif
			xor		eax,eax
			ret
		.endif
	.elseif eax==WM_KEYUP
		invoke SendMessage,hPrpLstDlg,LB_GETCURSEL,0,0
		mov		edx,eax
		invoke SendMessage,hPrpLstDlg,LB_GETTEXT,edx,addr buffer
		.if dword ptr buffer=='tpaC'
			push	esi
			invoke GetWindowText,hWin,addr buffer,sizeof buffer
			invoke GetWindowLong,hPrpLstDlg,GWL_USERDATA
			mov		hCtl,eax
			invoke GetWindowLong,hCtl,GWL_USERDATA
			.if [eax].DIALOG.ntype==3
				mov		edx,[eax].DIALOG.hcld
				mov		hCtl,edx
			.endif
			invoke SetWindowText,hCtl,addr buffer
			pop		esi
		.endif
	.endif
	invoke CallWindowProc,OldPrpEdtDlgCldProc,hWin,uMsg,wParam,lParam
	ret

PrpEdtDlgCldProc endp

PrpLstDlgCldProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	nInx:DWORD
	LOCAL	lbid:DWORD
	LOCAL	buffer[512]:BYTE

	mov		eax,uMsg
	.if eax==WM_LBUTTONUP
		invoke SendMessage,hWin,LB_GETCURSEL,0,0
		.if eax!=LB_ERR
			mov		nInx,eax
			invoke SendMessage,hPrpLstDlg,LB_GETCURSEL,0,0
			push	eax
			invoke SendMessage,hWin,LB_GETTEXT,nInx,addr buffer
			invoke SetWindowText,hPrpEdtDlgCld,addr buffer
			invoke SendMessage,hWin,LB_GETITEMDATA,nInx,0
			mov		lbid,eax
			invoke PropEditUpdList,lbid
			pop		nInx
			invoke SendMessage,hPrpLstDlg,LB_SETCURSEL,nInx,0
			invoke PropListSetPos
			invoke SetFocus,hDEd
		.endif
		xor		eax,eax
		ret
	.elseif uMsg==WM_CHAR
		.if wParam==13
			invoke SendMessage,hWin,WM_LBUTTONUP,0,0
			xor		eax,eax
			ret
		.endif
	.endif
	invoke CallWindowProc,OldPrpLstDlgCldProc,hWin,uMsg,wParam,lParam
	ret

PrpLstDlgCldProc endp

Do_Property proc hWin:HWND

	invoke CreateWindowEx,0,addr szComboBoxClass,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or CBS_DROPDOWNLIST or WS_VSCROLL or CBS_SORT,0,0,0,0,hWin,0,hInstance,0
	mov		hPrpCboDlg,eax
	invoke SetWindowLong,hPrpCboDlg,GWL_WNDPROC,addr PrpCboDlgProc
	mov		OldPrpCboDlgProc,eax
	invoke CreateWindowEx,WS_EX_CLIENTEDGE,addr szListBoxClass,NULL,WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or LBS_HASSTRINGS or LBS_NOINTEGRALHEIGHT or LBS_USETABSTOPS or LBS_SORT or LBS_OWNERDRAWFIXED or LBS_NOTIFY,0,0,0,0,hWin,0,hInstance,0
	mov		hPrpLstDlg,eax
	invoke SetWindowLong,hWin,0,eax
	invoke SetWindowLong,hPrpLstDlg,GWL_WNDPROC,addr PrpLstDlgProc
	mov		OldPrpLstDlgProc,eax
	invoke CreateWindowEx,0,addr szEditClass,NULL,WS_CHILD or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or ES_AUTOHSCROLL or ES_MULTILINE,0,0,0,0,hPrpLstDlg,0,hInstance,0
	mov		hPrpEdtDlgCld,eax
	invoke SetWindowLong,hPrpEdtDlgCld,GWL_WNDPROC,addr PrpEdtDlgCldProc
	mov		OldPrpEdtDlgCldProc,eax
	invoke CreateWindowEx,0,addr szListBoxClass,NULL,WS_CHILD or WS_VSCROLL or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or WS_BORDER or LBS_HASSTRINGS,0,0,0,0,hPrpLstDlg,0,hInstance,0
	mov		hPrpLstDlgCld,eax
	invoke SetWindowLong,hPrpLstDlgCld,GWL_WNDPROC,addr PrpLstDlgCldProc
	mov		OldPrpLstDlgCldProc,eax
	invoke CreateWindowEx,0,addr szButtonClass,NULL,WS_CHILD or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or BS_OWNERDRAW,0,0,0,0,hPrpLstDlg,1,hInstance,0
	mov		hPrpBtnDlgCld,eax
	ret

Do_Property endp

