
;Addin messages
AM_INIT					equ 0001h				;hWin=Handle to main window, wParam=0, lParam=pointer to ADDIN struct, Return or'ed hook flags
AM_PORTWRITE			equ 0002h				;hWin=Handle to main window, wParam=Port (0-3), lParam=Port value, No Return
AM_ALECHANGED			equ 0003h				;hWin=Handle to main window, wParam=0, lParam=0, No Return
AM_MMPORTWRITE			equ 0004h				;hWin=Handle to main window, wParam=Port address, lParam=Port value, No Return				
AM_COMMAND				equ 0005h				;hWin=Handle to main window, wParam=0, lParam=MenuID, No Return
AM_RESET				equ 0006h				;hWin=Handle to main window, wParam=0, lParam=0, No Return
AM_REFRESH				equ 0007h				;hWin=Handle to main window, wParam=0, lParam=0, No Return
AM_PROJECTOPEN			equ 0008h				;hWin=Handle to main window, wParam=0, lParam=lpProjectFile, No Return
AM_PROJECTCLOSE			equ 0009h				;hWin=Handle to main window, wParam=0, lParam=lpProjectFile, No Return
AM_CLOCKOUT				equ 000Ah				;hWin=Handle to main window, wParam=TRUE/FALSE, lParam=0, No Return

;Handling of AM_PORTWRITE, AM_ALECHANGED and AM_MMPORTWRITE must be optimized for speed.
;Do NOT call any windows api's when your addin processes these messages.
;IMPORTANT: You MUST preserve ebx, esi and edi.

;Hook flags, return or'ed flags in responce to AM_INIT
AH_PORTWRITE            equ 0001h
AH_ALECHANGED           equ 0002h
AH_MMPORTWRITE          equ 0004h
AH_COMMAND              equ 0008h
AH_RESET                equ 0010h
AH_REFRESH              equ 0020h
AH_PROJECTOPEN          equ 0040h
AH_PROJECTCLOSE         equ 0080h
AH_CLOCKOUT				equ 0100h

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

ADDINS struct
	szDll				BYTE 64 dup(?)
	hDll				HINSTANCE ?
	lpAddinProc			DWORD ?
	hook				DWORD ?
ADDINS ends

ADDIN struct
	hInstance			HINSTANCE ?				;Instace handle
	hWnd				HWND ?					;Main window handle
	hGrd				HWND ?					;Code grid handle
	hActive				HWND ?					;Handle of current active window
	hTabDlgStatus		HWND ?					;Handle of status dialog
	hTabDlg				HWND 16 dup(?)			;Handle of Ram, Bit, Sfr, XRam or Code
	hIml				HIMAGELIST ?			;Handle of image list
	hMenu				HMENU ?					;Handle of menu
	hAccel				HACCEL ?				;Handle of accelerators
	hGrdFont			HFONT ?					;Handle of code grid / hexedit font
	hBmpGrayLed			HBITMAP ?				;Handle of gray led bitmap
	hBmpGreenLed		HBITMAP ?				;Handle of green led bitmap
	hBmpRedLed			HBITMAP ?				;Handle of red led bitmap
	MenuID				DWORD ?					;Menu ID's for addins
	nRam				DWORD ?					;Size of Ram (128 or 256)
	Ram					BYTE 256 dup(?)			;Ram bytes
	SfrData				SFRMAP 128 dup(<>)		;Sfr definitions
	Sfr					BYTE 256 dup(?)			;Sfr bytes, only top 128 bytes used
	XRam				BYTE 65536 dup(?)		;XRam bytes
	Code				BYTE 65536 dup(?)		;Code bytes
	Bank				DWORD ?					;Current register bank
	PC					DWORD ?					;Program counter
	nAddr				DWORD ?					;Number of addresses
	Refresh				DWORD ?					;Set to TRUE to force a refresh
	lpSendAddinMessage	DWORD ?					;Pointer to SendAddinMessage api
	mmoutport			DWORD 4 dup(?)			;Memory mapped output port addresses
	mmoutportdata		DWORD 4 dup(?)			;Memory mapped output data
	mminport			DWORD 4 dup(?)			;Memory mapped input addresses
	mminportdata		DWORD 4 dup(?)			;Memory mapped input data
	szMCU				BYTE 16 dup(?)			;Current selected MCU
	addins				ADDINS 16 dup(<>)
	HalfCycles			DWORD ?
	TotalCycles			DWORD ?
	ComputerClock		DWORD ?
	MCUClock			DWORD ?
	RefreshRate			DWORD ?
	ThreadPriority		DWORD ?
ADDIN ends

;Addresses of all implemented sfr's
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

IDM_FILE            	equ 10200				;ID of file menu
IDM_SEARCH          	equ 10201				;ID of search menu
IDM_VIEW            	equ 10202				;ID of view menu
IDM_DEBUG           	equ 10203				;ID of debug menu
IDM_OPTIONS         	equ 10204				;ID of options menu
IDM_TOOLS				equ 10020				;ID of tools meny
IDM_HELP            	equ 10205				;ID of help menu
