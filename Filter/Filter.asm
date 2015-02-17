
; STM32 value line Discovery Digital Oscilloscope demo project.
; -------------------------------------------------------------------------------
;
; IMPORTANT NOTICE!
; -----------------
; The use of the evaluation board is restricted:
; "This device is not, and may not be, offered for sale or lease, or sold or
; leased or otherwise distributed".
;
; For more info see this license agreement:
; http://www.st.com/internet/com/LEGAL_RESOURCES/LEGAL_AGREEMENT/
; LICENSE_AGREEMENT/EvaluationProductLicenseAgreement.pdf

.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include Filter.inc
include DDSWave.asm

.code

MainDlgProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	tid:DWORD
	LOCAL	tci:TC_ITEM

	mov		eax,uMsg
	.if	eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		invoke GetDlgItem,hWin,IDC_MAINTAB
		mov		childdialogs.hWndMainTab,eax
		mov		tci.imask,TCIF_TEXT
		mov		tci.lpReserved1,0
		mov		tci.lpReserved2,0
		mov		tci.iImage,-1
		mov		tci.lParam,0
		mov		tci.pszText,offset szTabTitleDDS
		invoke SendMessage,childdialogs.hWndMainTab,TCM_INSERTITEM,0,addr tci
		invoke CreateFontIndirect,addr Tahoma
		mov		hFont,eax
		;Create DDS Wave child dialog
		invoke CreateDialogParam,hInstance,IDD_DDSWAVE,childdialogs.hWndMainTab,addr DDSWaveChildProc,0
		mov		childdialogs.hWndDDSWaveDialog,eax
		
	.elseif	eax==WM_SIZE
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,childdialogs.hWndMainTab,0,0,rect.right,rect.bottom,TRUE
		add		rect.left,5
		sub		rect.right,10
		add		rect.top,25
		sub		rect.bottom,30
		invoke MoveWindow,childdialogs.hWndDDSWaveDialog,rect.left,rect.top,rect.right,rect.bottom,TRUE
	.elseif	eax==WM_CLOSE
		invoke DeleteObject,hFont
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

MainDlgProc endp

start:
	
	invoke	GetModuleHandle,NULL
	mov		hInstance,eax
	invoke	InitCommonControls
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.cbClsExtra,0
	mov		wc.cbWndExtra,0
	mov		eax,hInstance
	mov		wc.hInstance,eax
	mov		wc.hIcon,NULL
	mov		wc.hIconSm,NULL
	mov		wc.hbrBackground,NULL
	invoke LoadCursor,0,IDC_CROSS
	mov		wc.hCursor,eax
	mov		wc.lpfnWndProc,offset DDSWaveProc
	mov		wc.lpszClassName,offset szDDSWAVECLASS
	invoke RegisterClassEx,addr wc
	mov		wc.lpfnWndProc,offset DDSPeakProc
	mov		wc.lpszClassName,offset szDDSPEAKCLASS
	invoke RegisterClassEx,addr wc
	invoke	DialogBoxParam,hInstance,IDD_MAIN,NULL,addr MainDlgProc,NULL
	invoke	ExitProcess,0

end start
