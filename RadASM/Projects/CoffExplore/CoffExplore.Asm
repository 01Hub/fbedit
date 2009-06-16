.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include CoffExplore.inc
include Misc.asm

.code

;########################################################################

CldDlgProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hCldDlg,eax
		invoke GetDlgItem,hWin,IDC_STCSECTION
		mov		hStc,eax
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				invoke SendMessage,hWnd,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNBROWSE
				;Zero out the ofn struct
				invoke RtlZeroMemory,addr ofn,sizeof ofn
				;Setup the ofn struct
				mov		ofn.lStructSize,sizeof ofn
				push	hWin
				pop		ofn.hwndOwner
				push	hInstance
				pop		ofn.hInstance
				mov		ofn.lpstrFilter,offset szOBJFilterString
				mov		buffer[0],0
				lea		eax,buffer
				mov		ofn.lpstrFile,eax
				mov		ofn.nMaxFile,sizeof buffer
				mov		ofn.lpstrDefExt,NULL
				mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
				;Show the Open dialog
				invoke GetOpenFileName,addr ofn
				.if eax
					invoke SetDlgItemText,hWin,IDC_EDTFILE,addr buffer
					invoke CloseOBJ
					; Allocate memory for file
					invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
					mov		hMemFile,eax
					invoke ReadTheFile,addr buffer,hMemFile
					.if !eax
						invoke ShowCoffHeader,hMemFile
						mov		ebx,hMemFile
						movzx	eax,[ebx].COFFHEADER.NumberOfSections
						mov		nCoffHeaders,eax
						movzx	eax,[ebx].COFFHEADER.SizeOfOptionalHeader
						lea		ebx,[ebx+eax+sizeof COFFHEADER]
						invoke SendMessage,hStc,WM_SETTEXT,0,addr [ebx].COFFSECTIONHEADER.sName
						invoke ReadSectionHeaders
					.endif
				.endif
			.elseif eax==IDC_BTNPREVIOUS
				.if nCoffHeader
					dec		nCoffHeader
					mov		ebx,hMemFile
					movzx	eax,[ebx].COFFHEADER.SizeOfOptionalHeader
					lea		ebx,[ebx+eax+sizeof COFFHEADER]
					mov		eax,nCoffHeader
					mov		edx,sizeof COFFSECTIONHEADER
					mul		edx
					lea		ebx,[ebx+eax]
					invoke lstrcpyn,addr szSection,addr [ebx].COFFSECTIONHEADER.sName,9
					invoke SendMessage,hStc,WM_SETTEXT,0,addr szSection
				.endif
			.elseif eax==IDC_BTNNEXT
				mov		eax,nCoffHeader
				inc		eax
				.if eax<nCoffHeaders
					inc		nCoffHeader
					mov		ebx,hMemFile
					movzx	eax,[ebx].COFFHEADER.SizeOfOptionalHeader
					lea		ebx,[ebx+eax+sizeof COFFHEADER]
					mov		eax,nCoffHeader
					mov		edx,sizeof COFFSECTIONHEADER
					mul		edx
					lea		ebx,[ebx+eax]
					invoke lstrcpyn,addr szSection,addr [ebx].COFFSECTIONHEADER.sName,9
					invoke SendMessage,hStc,WM_SETTEXT,0,addr szSection
				.endif
			.elseif eax==IDC_BTNDUMP
				.if nCoffHeaders
					mov		ebx,hMemFile
					movzx	eax,[ebx].COFFHEADER.SizeOfOptionalHeader
					lea		ebx,[ebx+eax+sizeof COFFHEADER]
					mov		eax,nCoffHeader
					mov		edx,sizeof COFFSECTIONHEADER
					mul		edx
					lea		ebx,[ebx+eax]
					invoke SendMessage,hEdt,WM_SETTEXT,0,addr szNULL
					invoke DumpSection,ebx,sizeof COFFSECTIONHEADER
					mov		eax,[ebx].COFFSECTIONHEADER.SizeOfRawData
					mov		ebx,[ebx].COFFSECTIONHEADER.PointerToRawData
					add		ebx,hMemFile
					invoke DumpSection,ebx,eax
				.endif
			.elseif eax==IDC_BTNDUMPSYMBOLS
				.if nCoffHeaders
					invoke SendMessage,hEdt,WM_SETTEXT,0,addr szNULL
					mov		ebx,hMemFile
					mov		eax,[ebx].COFFHEADER.NumberOfSymbols
					mov		ebx,[ebx].COFFHEADER.PointerToSymbolTable
					add		ebx,hMemFile
					invoke DumpSymbols,ebx,eax
				.endif
			.elseif eax==IDC_BTNDUMPPROCS
				.if nCoffHeaders
					invoke SendMessage,hEdt,WM_SETTEXT,0,addr szNULL
					mov		ebx,hMemFile
					mov		eax,[ebx].COFFHEADER.NumberOfSymbols
					mov		ebx,[ebx].COFFHEADER.PointerToSymbolTable
					add		ebx,hMemFile
					invoke DumpProcs,ebx,eax
				.endif
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

CldDlgProc endp

DlgProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	cldrect:RECT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hWnd,eax
		invoke GetDlgItem,hWin,IDC_EDT1
		mov		hEdt,eax
		; Create font and set it to edit box
		invoke CreateFontIndirect,addr Courier_New_9
		mov		hEditFont,eax
		invoke SendMessage,hEdt,WM_SETFONT,hEditFont,FALSE
		invoke CreateDialogParam,hInstance,IDD_DLGCHILD,hWin,addr CldDlgProc,0
	.elseif eax==WM_SIZE
		; Move and size the rich edit control
		invoke GetClientRect,hWin,addr rect
		mov		eax,rect.bottom
		sub		eax,70
		invoke MoveWindow,hEdt,0,0,rect.right,eax,TRUE
		; Move the cild dialog
		invoke GetClientRect,hCldDlg,addr cldrect
		mov		eax,rect.bottom
		sub		eax,65
		mov		edx,rect.right
		sub		edx,cldrect.right
		invoke MoveWindow,hCldDlg,edx,eax,cldrect.right,cldrect.bottom,TRUE
	.elseif eax==WM_CLOSE
		; Free the font
		invoke DeleteObject,hEditFont
		; Free the file memory
		.if hMemFile
			invoke GlobalFree,hMemFile
		.endif
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

start:

	invoke LoadLibrary,addr szRichEditDLL
	.if eax
		mov		hRichEdDLL,eax
		invoke GetModuleHandle,NULL
		mov		hInstance,eax
	    invoke InitCommonControls
		invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	.else
		invoke MessageBox,0,addr szRichEditDLL,addr szRichEditDLL,MB_OK
	.endif
	invoke ExitProcess,0

end start
