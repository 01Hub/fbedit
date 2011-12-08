
AM_INIT				equ 0001h				;hWin=Handle to main window, wParam=0, lParam=pointer to ADDIN struct
AM_PORTCHANGED		equ 0002h				;hWin=Handle to main window, wParam=Port (0-3), lParam=Port value
AM_XRAMCHANGED		equ 0003h				;hWin=Handle to main window, wParam=XRam address, lParam=XRam value
AM_COMMAND			equ 0004h				;hWin=Handle to main window, wParam=0, lParam=MenuID
AM_RESET			equ 0005h				;hWin=Handle to main window, wParam=0, lParam=0

ADDIN struct
	hInstance		HINSTANCE ?
	hWnd			HWND ?
	hMenu			HMENU ?
	MenuID			DWORD ?
	hAccel			HACCEL ?
	hLstFont		HFONT ?
	Sfr				BYTE 256 dup(?)
	Ram				BYTE 256 dup(?)
	XRam			BYTE 65536 dup(?)
	Code			BYTE 65536 dup(?)
	Bank			DWORD ?
	PC				DWORD ?
	nAddr			DWORD ?
ADDIN ends

SFR_P0      		equ 080h
SFR_SP      		equ 081h
SFR_DPL     		equ 082h
SFR_DPH     		equ 083h
SFR_DP1L     		equ 084h
SFR_DP1H     		equ 085h
SFR_PCON    		equ 087h
SFR_TCON    		equ 088h
SFR_TMOD    		equ 089h
SFR_TL0     		equ 08Ah
SFR_TL1     		equ 08Bh
SFR_TH0     		equ 08Ch
SFR_TH1     		equ 08Dh
SFR_AUXR    		equ 08Eh
SFR_P1      		equ 090h
SFR_SCON    		equ 098h
SFR_SBUF    		equ 099h
SFR_P2      		equ 0A0h
SFR_AUXR1   		equ 0A2h
SFR_WDTRST  		equ 0A6h
SFR_IE      		equ 0A8h
SFR_P3      		equ 0B0h
SFR_IP      		equ 0B8h
SFR_T2CON   		equ 0C8h
SFR_T2MOD   		equ 0C9h
SFR_RCAP2L  		equ 0CAh
SFR_RCAP2H  		equ 0CBh
SFR_TL2     		equ 0CCh
SFR_TH2     		equ 0CDh
SFR_PSW     		equ 0D0h
SFR_ACC     		equ 0E0h
SFR_B       		equ 0F0h

IDM_FILE            equ 10200
IDM_SEARCH          equ 10201
IDM_VIEW            equ 10202
IDM_DEBUG           equ 10203
IDM_OPTIONS         equ 10204
IDM_HELP            equ 10205
