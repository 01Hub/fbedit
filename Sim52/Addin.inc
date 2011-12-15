
												;Always return FALSE
AM_INIT					equ 0001h				;hWin=Handle to main window, wParam=0, lParam=pointer to ADDIN struct
AM_PORTWRITE			equ 0002h				;hWin=Handle to main window, wParam=Port (0-3), lParam=Port value
AM_ALECHANGED			equ 0003h
AM_MMOWRITE				equ 0004h				;hWin=Handle to main window, wParam=XRam address, lParam=XRam value
AM_XRAMREAD				equ 0005h				;hWin=Handle to main window, wParam=XRam address, lParam=XRam value
AM_MMIBITCHANGED		equ 0006h				;hWin=Handle to main window, wParam=MMIPort bit (0 to 31), lParam=TRUE or FALSE
AM_COMMAND				equ 0007h				;hWin=Handle to main window, wParam=0, lParam=MenuID
AM_RESET				equ 0008h				;hWin=Handle to main window, wParam=0, lParam=0
AM_REFRESH				equ 0009h				;hWin=Handle to main window, wParam=0, lParam=0

SFRMAP struct
	ad					DWORD ?					;SFR Adress
	rst					DWORD ?					;SFR Reset Value
	nme					BYTE 8 dup(?)			;SFR Name
	d7					BYTE 8 dup(?)			;SFR Bit 7 Name
	d6					BYTE 8 dup(?)			;SFR Bit 6 Name
	d5					BYTE 8 dup(?)			;SFR Bit 5 Name
	d4					BYTE 8 dup(?)			;SFR Bit 4 Name
	d3					BYTE 8 dup(?)			;SFR Bit 3 Name
	d2					BYTE 8 dup(?)			;SFR Bit 2 Name
	d1					BYTE 8 dup(?)			;SFR Bit 1 Name
	d0					BYTE 8 dup(?)			;SFR Bit 0 Name
SFRMAP ends

ADDIN struct
	hInstance			HINSTANCE ?
	hWnd				HWND ?
	hGrd				HWND ?
	hActive				HWND ?
	hTabDlgStatus		HWND ?
	hTabDlg				HWND 16 dup(?)
	hIml				HIMAGELIST ?
	hMenu				HMENU ?
	hAccel				HACCEL ?
	hLstFont			HFONT ?
	hBmpGrayLed			HBITMAP ?
	hBmpGreenLed		HBITMAP ?
	hBmpRedLed			HBITMAP ?
	MenuID				DWORD ?
	Ram					BYTE 256 dup(?)
	SfrData				SFRMAP 128 dup(<>)
	Sfr					BYTE 256 dup(?)
	XRam				BYTE 65536 dup(?)
	Code				BYTE 65536 dup(?)
	Bank				DWORD ?
	PC					DWORD ?
	nAddr				DWORD ?
	Refresh				DWORD ?
	lpSendAddinMessage	DWORD ?
	mmoutport			DWORD 4 dup(?)
	mmoutportdata		DWORD 4 dup(?)
	mminport			DWORD 4 dup(?)
	mminportdata		DWORD 4 dup(?)
ADDIN ends

SFR_P0      			equ 080h
SFR_SP      			equ 081h
SFR_DPL     			equ 082h
SFR_DPH     			equ 083h
SFR_DP1L     			equ 084h
SFR_DP1H     			equ 085h
SFR_PCON    			equ 087h
SFR_TCON    			equ 088h
SFR_TMOD    			equ 089h
SFR_TL0     			equ 08Ah
SFR_TL1     			equ 08Bh
SFR_TH0     			equ 08Ch
SFR_TH1     			equ 08Dh
SFR_AUXR    			equ 08Eh
SFR_P1      			equ 090h
SFR_SCON    			equ 098h
SFR_SBUF    			equ 099h
SFR_P2      			equ 0A0h
SFR_AUXR1   			equ 0A2h
SFR_WDTRST  			equ 0A6h
SFR_IE      			equ 0A8h
SFR_P3      			equ 0B0h
SFR_IP      			equ 0B8h
SFR_T2CON   			equ 0C8h
SFR_T2MOD   			equ 0C9h
SFR_RCAP2L  			equ 0CAh
SFR_RCAP2H  			equ 0CBh
SFR_TL2     			equ 0CCh
SFR_TH2     			equ 0CDh
SFR_PSW     			equ 0D0h
SFR_ACC     			equ 0E0h
SFR_B       			equ 0F0h

IDM_FILE            	equ 10200
IDM_SEARCH          	equ 10201
IDM_VIEW            	equ 10202
IDM_DEBUG           	equ 10203
IDM_OPTIONS         	equ 10204
IDM_HELP            	equ 10205
