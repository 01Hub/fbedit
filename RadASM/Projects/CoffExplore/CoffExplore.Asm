.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include CoffExplore.inc
include Misc.asm

.code

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

;########################################################################

DlgProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_EDT1
		mov		hEdt,eax
		; Create font and set it to edit box
		invoke CreateFontIndirect,addr Courier_New_9
		mov		hEditFont,eax
		invoke SendMessage,hEdt,WM_SETFONT,hEditFont,FALSE
		; Allocate memory for files
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,256*1024
		mov		hMemFile,eax
		; Size of structures
		invoke ReadTheFile,addr szFileName,hMemFile
		mov		nCoffHeader,-1
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNDUMPHEADER
				inc		nCoffHeader
				mov		ebx,hMemFile
				movzx	eax,[ebx].COFFHEADER.NumberOfSections
				.if eax==nCoffHeader
					mov		nCoffHeader,0
				.endif
				movzx	eax,[ebx].COFFHEADER.SizeOfOptionalHeader
				lea		ebx,[ebx+eax+sizeof COFFHEADER]
				mov		eax,nCoffHeader
				mov		edx,sizeof SECTIONHEADER
				mul		edx
				lea		ebx,[ebx+eax]
				invoke DumpSection,ebx,sizeof SECTIONHEADER
			.elseif eax==IDC_BTNDUMPSECTION
				mov		ebx,hMemFile
				movzx	eax,[ebx].COFFHEADER.SizeOfOptionalHeader
				lea		ebx,[ebx+eax+sizeof COFFHEADER]
				mov		eax,nCoffHeader
				mov		edx,sizeof SECTIONHEADER
				mul		edx
				lea		ebx,[ebx+eax]
				mov		eax,[ebx].SECTIONHEADER.SizeOfRawData
				mov		edx,[ebx].SECTIONHEADER.PointerToRawData
				lea		ebx,[ebx+edx]
				invoke DumpSection,ebx,eax
			.elseif eax==IDC_BTNCOFFHEADER
				invoke ShowCoffHeader,hMemFile
			.elseif eax==IDCANCEL
				; Exit
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.endif
		.endif
	.elseif eax==WM_CLOSE
		; Free the font
		invoke DeleteObject,hEditFont
		; Free the file memory
		invoke GlobalFree,hMemFile
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

end start
