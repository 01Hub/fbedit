.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include ParseMasmStruct.inc
include Misc.asm

.code

;########################################################################

ResultProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_EDTRESULT,WM_SETFONT,hEditFont,FALSE
		invoke SetDlgItemText,hWin,IDC_EDTRESULT,addr szOutput
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				invoke EndDialog,hWin,0
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

ResultProc endp

ParseMasmStruct proc uses ebx esi edi,hWin:HWND
	LOCAL	szstruct[512]:BYTE

	invoke GetDlgItemText,hWin,IDC_EDT1,addr szstruct,sizeof szstruct
	.if eax
		mov		szOutput,0
		lea		esi,szstruct
		invoke ParseStruct,NULL,FALSE,addr nSize,addr szOutput
		invoke DialogBoxParam,hInstance,IDD_DLGRESULT,NULL,addr ResultProc,NULL
	.endif
	ret

ParseMasmStruct endp

DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hMemFile:HGLOBAL

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
		mov		hMemFile,eax
		; Size of structures
		invoke ReadTheFile,addr szStructSizeFileName,hMemFile
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
		mov		hMemStructSize,eax
		invoke ParseSizeFile,hMemFile,hMemStructSize
		; Size of types
		invoke ReadTheFile,addr szTypeSizeFileName,hMemFile
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
		mov		hMemTypeSize,eax
		invoke ParseSizeFile,hMemFile,hMemTypeSize
		; Size of constants
		invoke ReadTheFile,addr szConstSizeFileName,hMemFile
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
		mov		hMemConstSize,eax
		invoke ParseSizeFile,hMemFile,hMemConstSize
		invoke GlobalFree,hMemFile
		invoke CreateFontIndirect,addr Courier_New_9
		mov		hEditFont,eax
		invoke SendDlgItemMessage,hWin,IDC_EDT1,WM_SETFONT,hEditFont,FALSE
		invoke SetDlgItemText,hWin,IDC_EDT1,addr szTestStruct4
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke ParseMasmStruct,hWin
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke DeleteObject,hEditFont
		invoke GlobalFree,hMemStructSize
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

end start
