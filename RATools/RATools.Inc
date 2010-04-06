InstallRATools			PROTO :DWORD,:DWORD
UnInstallRATools		PROTO


;Tool messages
TLM_INIT		equ	WM_USER+1
TLM_CREATE		equ	WM_USER+2

TLM_DOCKING		equ	WM_USER+4
TLM_HIDE		equ	WM_USER+5
TLM_MOUSEMOVE	equ	WM_USER+6
TLM_LBUTTONDOWN	equ	WM_USER+7
TLM_LBUTTONUP	equ	WM_USER+8
TLM_PAINT		equ	WM_USER+9
TLM_SIZE		equ	WM_USER+10
TLM_REDRAW		equ	WM_USER+11
TLM_CAPTION		equ	WM_USER+12
TLM_ADJUSTRECT	equ	WM_USER+13
TLM_GET_VISIBLE	equ	WM_USER+14
TLM_GET_STRUCT	equ	WM_USER+15

TLM_SETTBR		equ	WM_USER+17
TLM_GET_DOCKED	equ	WM_USER+18
TLM_MOVETEST	equ	WM_USER+19

;Docking positions
TL_LEFT			equ	1
TL_TOP			equ	2
TL_RIGHT		equ	3
TL_BOTTOM		equ	4

DOCKING struct
	ID				dd ?
	Caption			dd ?
	Visible			dd ?
	Docked			dd ?
	Position		dd ?
	IsChild			dd ?
	DockWidth		dd ?
	DockHeight		dd ?
	FloatRect		RECT <>
DOCKING ends

.const

szToolClassName			db 'RATools',0

