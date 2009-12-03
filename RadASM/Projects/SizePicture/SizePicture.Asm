; Size of frame 150x83 mm, 640*354px
.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include SizePicture.inc
include GdiPluss.asm

.code

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax

    invoke InitCommonControls
	invoke GdipInit
	invoke DialogBoxParam,hInstance,IDD_DIALOG1,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

;########################################################################

BrowseFolder proc hWin:HWND,nID:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		bri.pidlRoot,0
	mov		bri.pszDisplayName,0
;	mov		eax,offset szBrowse
	xor		eax,eax
	mov		bri.lpszTitle,eax
	mov		bri.ulFlags,BIF_RETURNONLYFSDIRS or BIF_STATUSTEXT 
	mov		bri.lpfn,BrowseCallbackProc
	; get path   
	invoke SendDlgItemMessage,hWin,nID,WM_GETTEXT,sizeof buffer,addr buffer
	lea		eax,buffer
	mov		bri.lParam,eax 
	mov		bri.iImage,0
	invoke SHBrowseForFolder,offset bri
	.if !eax
		jmp		GetOut
	.endif      
	mov		pidl,eax
	invoke SHGetPathFromIDList,pidl,addr buffer
	; set new path back to edit
	invoke SendDlgItemMessage,hWin,nID,WM_SETTEXT,0,addr buffer
  GetOut:
	ret

BrowseFolder endp

;--------------------------------------------------------------------------------
; set initial folder in browser
BrowseCallbackProc proc hwnd:DWORD,uMsg:UINT,lParam:LPARAM,lpData:DWORD

	mov eax,uMsg
	.if eax==BFFM_INITIALIZED
		invoke PostMessage,hwnd,BFFM_SETSELECTION,TRUE,lpData
		invoke PostMessage,hwnd,BFFM_SETSTATUSTEXT,0,addr szBrowse
	.endif
	xor eax, eax
	ret

BrowseCallbackProc endp

ScanDir proc lpPth:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	hwfd:DWORD

	;Make the path local
	invoke lstrcpy,addr buffer,lpPth
	;Check if path ends with '\'. If not add.
	invoke lstrlen,addr buffer
	dec		eax
	mov		al,buffer[eax]
	.if al!='\'
		invoke lstrcat,addr buffer,addr szBackSlash
	.endif
	;Add '*.jpg'
	invoke lstrcat,addr buffer,addr szJPG
	;Find first match, if any
	invoke FindFirstFile,addr buffer,addr wfd
	.if eax!=INVALID_HANDLE_VALUE
		;Save returned handle
		mov		hwfd,eax
	  Next:
		;Check if found is a dir
		mov		eax,wfd.dwFileAttributes
		and		eax,FILE_ATTRIBUTE_DIRECTORY
		.if eax
			;Do not include '.' and '..'
			mov		al,wfd.cFileName
			.if al!='.'
				invoke lstrlen,addr buffer
				mov		edx,eax
				push	edx
				sub		edx,3
				;Do not remove the '\'
				mov		al,buffer[edx]
				.if al=='\'
					inc		edx
				.endif
				;Add new dir to path
				invoke lstrcpy,addr buffer[edx],addr wfd.cFileName
				;Call myself again, thats recursive!
				invoke ScanDir,addr buffer
				pop		edx
				;Remove what was added
				mov		buffer[edx],0
			.endif
		.else
			invoke lstrlen,addr wfd.cFileName
			.if eax>4
				invoke lstrcmpi,addr wfd.cFileName[eax-3],offset DefJpgExt
				.if !eax
					;Add file
					invoke lstrcpy,offset OpenFileName,addr buffer
					invoke lstrlen,offset OpenFileName
					.while eax && OpenFileName[eax-1]!='\'
						dec		eax
					.endw
					mov		OpenFileName[eax],0
					invoke lstrcat,offset OpenFileName,addr wfd.cFileName
					.if DestPath
						invoke lstrcpy,offset SaveFileName,offset DestPath
						invoke wsprintf,offset Temp,offset szFmt,Inx
						invoke lstrcat,offset SaveFileName,offset Temp
						inc		Inx
						invoke GetImage,offset OpenFileName,640,426,offset SaveFileName
						invoke SendDlgItemMessage,hDlg,1001,STM_SETIMAGE,IMAGE_BITMAP,eax
						invoke DeleteObject,eax
					.else
						invoke GetImage,offset OpenFileName,640,426,0
						invoke SendDlgItemMessage,hDlg,1001,STM_SETIMAGE,IMAGE_BITMAP,eax
						invoke DeleteObject,eax
					.endif
				.endif
			.endif
		.endif
		;Any more matches?
		invoke FindNextFile,hwfd,addr wfd
		or		eax,eax
		jne		Next
		;No more matches, close find
		invoke FindClose,hwfd
	.endif
	ret

ScanDir endp

DlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,hWin
		mov		hDlg,eax
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDM_FILE_OPEN
				invoke RtlZeroMemory,addr ofn,sizeof ofn
				mov		ofn.lStructSize,sizeof ofn
				mov		eax,hWin
				mov		ofn.hwndOwner,eax
				mov		eax,hInstance
				mov		ofn.hInstance,eax
				mov		ofn.lpstrFilter,offset JPGFilterString
				mov		ofn.lpstrFile,offset OpenFileName
				;mov		byte ptr [OpenFileName],0
				mov		ofn.nMaxFile,sizeof OpenFileName
				mov		ofn.lpstrDefExt,0;offset DefJpgExt
				mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
				invoke GetOpenFileName,addr ofn
				.if eax
					;invoke GetImage,offset OpenFileName,640,480,0
					invoke GetImage,offset OpenFileName,640,426,0
					invoke SendDlgItemMessage,hWin,1001,STM_SETIMAGE,IMAGE_BITMAP,eax
					invoke DeleteObject,eax
				.endif
			.elseif eax==IDM_FILE_SAVE
				invoke RtlZeroMemory,addr ofn,sizeof ofn
				mov		ofn.lStructSize,sizeof ofn
				push	hWin
				pop		ofn.hwndOwner
				push	hInstance
				pop		ofn.hInstance
				mov		ofn.lpstrFilter,offset JPGFilterString
				mov		ofn.lpstrFile,offset SaveFileName
				;mov		byte ptr [SaveFileName],0
				mov		ofn.nMaxFile,sizeof SaveFileName
				mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT
				mov		ofn.lpstrDefExt,offset DefJpgExt
				invoke GetSaveFileName,addr ofn
				.if eax
					;invoke GetImage,offset OpenFileName,640,480,offset SaveFileName
					invoke GetImage,offset OpenFileName,640,426,offset SaveFileName
					invoke SendDlgItemMessage,hWin,1001,STM_SETIMAGE,IMAGE_BITMAP,eax
					invoke DeleteObject,eax
				.endif
			.elseif eax==IDM_FILE_EXIT
				invoke SendDlgItemMessage,hWin,1001,STM_SETIMAGE,IMAGE_BITMAP,0
				invoke DeleteObject,eax
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNCONVERT
				invoke GetDlgItemText,hWin,IDC_EDTDEST,addr DestPath,sizeof DestPath
				invoke GetDlgItemText,hWin,IDC_EDTSOURCE,addr buffer,sizeof buffer
				invoke GetDlgItemInt,hWin,IDC_EDTINDEX,NULL,FALSE
				mov		Inx,eax
				invoke ScanDir,addr buffer
			.elseif eax==IDC_BTNSOURCE
				invoke BrowseFolder,hWin,IDC_EDTSOURCE
			.elseif eax==IDC_BTNDEST
				invoke BrowseFolder,hWin,IDC_EDTDEST
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

DlgProc endp

end start
