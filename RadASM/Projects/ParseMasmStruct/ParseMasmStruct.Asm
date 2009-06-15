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
		; Set edit box font
		invoke SendDlgItemMessage,hWin,IDC_EDTRESULT,WM_SETFONT,hEditFont,FALSE
		; Set edit box text
		invoke SetDlgItemText,hWin,IDC_EDTRESULT,addr szOutput
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				; Exit
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.endif
		.endif
	.elseif eax==WM_CLOSE
		; End the dialog
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

ResultProc endp

ParseMasmStruct proc uses ebx esi edi,hWin:HWND
	LOCAL	szstruct[1024]:BYTE

	; Get the struct text
	invoke GetDlgItemText,hWin,IDC_EDT1,addr szstruct,sizeof szstruct
	.if eax
		mov		szOutput,0
		lea		esi,szstruct
		invoke PreParse,esi
		invoke ParseStruct,NULL,addr nSize,addr szOutput,0,1
		; Show result
		invoke DialogBoxParam,hInstance,IDD_DLGRESULT,NULL,addr ResultProc,NULL
	.endif
	ret

ParseMasmStruct endp

DlgProc proc uses esi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hMemFile:HGLOBAL

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		; Allocate memory for files
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
		; Free the file memory
		invoke GlobalFree,hMemFile
		; Create font and set it to edit box
		invoke CreateFontIndirect,addr Courier_New_9
		mov		hEditFont,eax
		invoke SendDlgItemMessage,hWin,IDC_EDT1,WM_SETFONT,hEditFont,FALSE
		; Add combobox items
		mov		esi,offset ComboItems
		.while byte ptr [esi].COMBOITEM.szName
			invoke SendDlgItemMessage,hWin,IDC_CBO1,CB_ADDSTRING,0,addr [esi].COMBOITEM.szName
			invoke SendDlgItemMessage,hWin,IDC_CBO1,CB_SETITEMDATA,eax,[esi].COMBOITEM.lpItem
			lea		esi,[esi+sizeof COMBOITEM]
		.endw
		invoke SendDlgItemMessage,hWin,IDC_CBO1,CB_SETCURSEL,0,0
		invoke SetDlgItemText,hWin,IDC_EDT1,addr szTestStruct1
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				; Do the parsing
				invoke ParseMasmStruct,hWin
			.elseif eax==IDCANCEL
				; Exit
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.endif
		.elseif edx==CBN_SELCHANGE
			; Get combobox itemdata and update edit box
			invoke SendDlgItemMessage,hWin,IDC_CBO1,CB_GETCURSEL,0,0
			invoke SendDlgItemMessage,hWin,IDC_CBO1,CB_GETITEMDATA,eax,0
			invoke SetDlgItemText,hWin,IDC_EDT1,eax
		.endif
	.elseif eax==WM_CLOSE
		; Free the font
		invoke DeleteObject,hEditFont
		; Free memory
		invoke GlobalFree,hMemStructSize
		invoke GlobalFree,hMemTypeSize
		invoke GlobalFree,hMemConstSize
		; End the dialog
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

start:

include Test.asm
PrintDec sizeof TST
PrintDec TST.a
PrintDec TST.b
PrintDec TST.tstsub
PrintDec TST.tstsub.a
PrintDec TST.tstsub.b

	invoke GetModuleHandle,NULL
	mov		hInstance,eax
    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

end start
