
;NewProject.dlg
IDD_DLGNEWPROJECT				equ 1000
IDC_EDTNAME						equ 1001
IDC_CHKSUB						equ 1002
IDC_CHKBAK						equ 1003
IDC_CHKMOD						equ 1004
IDC_CHKINC						equ 1005
IDC_CHKRES						equ 1006
IDC_EDTPATH						equ 1007
IDC_BTNPATH						equ 1008
IDC_TAB1						equ 1009

;NewProject1.dlg
IDD_DLGTAB1						equ 1100
IDC_CBOBUILD					equ 1001
IDC_CHKASM						equ 1002
IDC_CHKRC						equ 1003
IDC_CHKTXT						equ 1004
IDC_CHKINC						equ 1005

;NewProject2.dlg
IDD_DLGTAB2						equ 1200
IDC_LSTTEMPLATE					equ 1001
IDC_STCTEMPLATE					equ 1002

.code

Tab1Proc proc uses ebx esi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		ebx,lpHandles
		mov		ebx,[ebx].ADDINHANDLES.hCbo
		xor		esi,esi
		.while TRUE
			invoke SendMessage,ebx,CB_GETLBTEXT,esi,addr buffer
			.break .if eax==LB_ERR
			invoke SendDlgItemMessage,hWin,IDC_CBOBUILD,CB_ADDSTRING,0,addr buffer
			inc		esi
		.endw
		invoke SendDlgItemMessage,hWin,IDC_CBOBUILD,CB_SETCURSEL,0,0
		invoke CheckDlgButton,hWin,IDC_CHKASM,BST_CHECKED
		invoke CheckDlgButton,hWin,IDC_CHKINC,BST_CHECKED
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

Tab1Proc endp

Tab2Proc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	wfd:WIN32_FIND_DATA
	LOCAL	hwfd:HANDLE
	LOCAL	nInx:DWORD
	LOCAL	hFile:HANDLE
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_LSTTEMPLATE,LB_ADDSTRING,0,offset szNone
		invoke lstrcpy,addr buffer,offset TemplatePath
		invoke lstrcat,addr buffer,offset szTpl
		invoke FindFirstFile,addr buffer,addr wfd
		mov		hwfd,eax
		.if eax!=INVALID_HANDLE_VALUE
			mov		hwfd,eax
			.while TRUE
				invoke SendDlgItemMessage,hWin,IDC_LSTTEMPLATE,LB_ADDSTRING,0,addr wfd.cFileName
				invoke FindNextFile,hwfd,addr wfd
				.break .if !eax
			.endw
			invoke FindClose,hwfd
		.endif
		invoke SendDlgItemMessage,hWin,IDC_LSTTEMPLATE,LB_SETCURSEL,0,0
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==LBN_SELCHANGE
			mov		buffer,0
			invoke SendDlgItemMessage,hWin,IDC_LSTTEMPLATE,LB_GETCURSEL,0,0
			.if sdword ptr eax>0
				push	eax
				invoke lstrcpy,addr buffer,offset TemplatePath
				invoke lstrcat,addr buffer,offset szBS
				invoke lstrlen,addr buffer
				pop		edx
				invoke SendDlgItemMessage,hWin,IDC_LSTTEMPLATE,LB_GETTEXT,edx,addr buffer[eax]
				invoke CreateFile,addr buffer,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
				.if eax!=INVALID_HANDLE_VALUE
					mov		hFile,eax
					invoke RtlZeroMemory,addr buffer,sizeof buffer
					invoke ReadFile,hFile,addr buffer,sizeof buffer-1,addr nInx,NULL
					xor		eax,eax
					.while eax<sizeof buffer
						.if buffer[eax]==0Dh
							mov		buffer[eax],0
							.break
						.endif
						inc		eax
					.endw
					invoke CloseHandle,hFile
				.endif
			.endif
			invoke SetDlgItemText,hWin,IDC_STCTEMPLATE,addr buffer
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

Tab2Proc endp

FolderCreate proc hWin:HWND,lpPath:DWORD,lpFolder:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke lstrcpy,addr buffer,lpPath
	invoke lstrcat,addr buffer,offset szBS
	invoke lstrcat,addr buffer,lpFolder
	invoke CreateDirectory,addr buffer,NULL
	.if !eax
		invoke lstrcpy,offset tempbuff,offset szErrDir
		invoke lstrcat,offset tempbuff,addr buffer
		invoke MessageBox,hWin,offset tempbuff,offset szMenuItem,MB_OK or MB_ICONERROR
		xor		eax,eax
	.else
		invoke lstrcpy,offset tempbuff,addr buffer
		mov		eax,offset tempbuff
	.endif
	ret

FolderCreate endp

FileCreate proc hWin:HWND,lpPath:DWORD,lpFile:DWORD,lpExt:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke lstrcpy,addr buffer,lpPath
	invoke lstrcat,addr buffer,offset szBS
	invoke lstrcat,addr buffer,lpFile
	invoke lstrcat,addr buffer,offset szDot
	invoke lstrcat,addr buffer,lpExt
	invoke GetFileAttributes,addr buffer
	.if eax!=-1
		invoke lstrcpy,offset tempbuff,offset szErrOverwrite
		invoke lstrcat,offset tempbuff,addr buffer
		invoke MessageBox,hWin,offset tempbuff,offset szMenuItem,MB_YESNO or MB_ICONERROR
		.if eax==IDNO
			xor		eax,eax
			ret
		.endif
	.endif
	invoke CreateFile,addr buffer,GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax==INVALID_HANDLE_VALUE
		invoke lstrcpy,offset tempbuff,offset szErrCreate
		invoke lstrcat,offset tempbuff,addr buffer
		invoke MessageBox,hWin,offset tempbuff,offset szMenuItem,MB_YESNO or MB_ICONERROR
		xor		eax,eax
		ret
	.endif
	invoke CloseHandle,eax
	mov		eax,TRUE
	ret

FileCreate endp

CreateProject proc uses ebx esi edi,hWin:HWND
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	propath[MAX_PATH]:BYTE

	; Create directories
	invoke GetDlgItemText,hWin,IDC_EDTPATH,addr propath,sizeof propath
	invoke IsDlgButtonChecked,hWin,IDC_CHKSUB
	.if eax
		invoke GetDlgItemText,hWin,IDC_EDTNAME,addr buffer,sizeof buffer
		invoke FolderCreate,hWin,addr propath,addr buffer
		or		eax,eax
		jz		Ex
		invoke lstrcpy,addr propath,eax
	.endif
	invoke SetCurrentDirectory,addr propath
	.if !eax
		invoke lstrcpy,offset tempbuff,offset szErrOpenDir
		invoke lstrcat,offset tempbuff,addr buffer
		invoke MessageBox,hWin,offset tempbuff,offset szMenuItem,MB_OK or MB_ICONERROR
		xor		eax,eax
		jmp		Ex
	.endif
	invoke IsDlgButtonChecked,hWin,IDC_CHKBAK
	.if eax
		invoke FolderCreate,hWin,addr propath,offset szBakPath
		or		eax,eax
		jz		Ex
	.endif
	invoke IsDlgButtonChecked,hWin,IDC_CHKMOD
	.if eax
		invoke FolderCreate,hWin,addr propath,offset szModPath
		or		eax,eax
		jz		Ex
	.endif
	invoke IsDlgButtonChecked,hWin,IDC_CHKINC
	.if eax
		invoke FolderCreate,hWin,addr propath,offset szIncPath
		or		eax,eax
		jz		Ex
	.endif
	invoke IsDlgButtonChecked,hWin,IDC_CHKRES
	.if eax
		invoke FolderCreate,hWin,addr propath,offset szResPath
		or		eax,eax
		jz		Ex
	.endif
	invoke SendDlgItemMessage,hDlg2,IDC_LSTTEMPLATE,LB_GETCURSEL,0,0
	.if sdword ptr eax>0
		; Template
	.else
		; No template
		invoke GetDlgItemText,hWin,IDC_EDTNAME,addr buffer,sizeof buffer
		invoke IsDlgButtonChecked,hDlg1,IDC_CHKASM
		.if eax
			invoke FileCreate,hWin,addr propath,addr buffer,offset szAsmFile
			or		eax,eax
			jz		Ex
		.endif
		invoke IsDlgButtonChecked,hDlg1,IDC_CHKINC
		.if eax
			invoke FileCreate,hWin,addr propath,addr buffer,offset szIncFile
			or		eax,eax
			jz		Ex
		.endif
		invoke IsDlgButtonChecked,hDlg1,IDC_CHKRC
		.if eax
			invoke FileCreate,hWin,addr propath,addr buffer,offset szRcFile
			or		eax,eax
			jz		Ex
		.endif
		invoke IsDlgButtonChecked,hDlg1,IDC_CHKTXT
		.if eax
			invoke FileCreate,hWin,addr propath,addr buffer,offset szTxtFile
			or		eax,eax
			jz		Ex
		.endif
	.endif
	mov		eax,TRUE
  Ex:
	ret

CreateProject endp

NewProjectDialogProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hTab:HWND
	LOCAL	tci:TCITEM
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SetDlgItemText,hWin,IDC_EDTPATH,offset ProjectPath
		invoke CheckDlgButton,hWin,IDC_CHKSUB,BST_CHECKED
		invoke CheckDlgButton,hWin,IDC_CHKBAK,BST_CHECKED
		; Get handle of tabstrip
		invoke GetDlgItem,hWin,IDC_TAB1
		mov		hTab,eax
		mov		tci.imask,TCIF_TEXT Or TCIF_PARAM
		mov		tci.pszText,offset szFiles
		; Create Tab1 child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGTAB1,hTab,addr Tab1Proc,0
		mov		tci.lParam,eax
		mov		hDlg1,eax
		invoke SendMessage,hTab,TCM_INSERTITEM,0,addr tci
		mov		tci.pszText,offset szTemplate
		; Create Tab2 child dialog
		invoke CreateDialogParam,hInstance,IDD_DLGTAB2,hTab,addr Tab2Proc,0
		mov		tci.lParam,eax
		mov		hDlg2,eax
		invoke SendMessage,hTab,TCM_INSERTITEM,1,addr tci
	.elseif eax==WM_NOTIFY
		mov		ebx,lParam
		.if [ebx].NMHDR.code==TCN_SELCHANGING
			; Hide the currently selected dialog
			mov		tci.imask,TCIF_PARAM
			invoke SendMessage,[ebx].NMHDR.hwndFrom,TCM_GETCURSEL,0,0
			mov		edx,eax
			invoke SendMessage,[ebx].NMHDR.hwndFrom,TCM_GETITEM,edx,addr tci
			invoke ShowWindow,tci.lParam,SW_HIDE
		.elseif [ebx].NMHDR.code==TCN_SELCHANGE
			; Show the currently selected dialog
			mov		tci.imask,TCIF_PARAM
			invoke SendMessage,[ebx].NMHDR.hwndFrom,TCM_GETCURSEL,0,0
			mov		edx,eax
			invoke SendMessage,[ebx].NMHDR.hwndFrom,TCM_GETITEM,edx,addr tci
			invoke ShowWindow,tci.lParam,SW_SHOW
		.endif
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				mov		ebx,lpData
				mov		eax,lpHandles
				.if [ebx].ADDINDATA.szSessionFile
					invoke SendMessage,[eax].ADDINHANDLES.hWnd,WM_COMMAND,IDM_FILE_CLOSESESSION or (BN_CLICKED SHL 16),NULL
				.else
					.if [eax].ADDINHANDLES.hREd
						invoke SendMessage,[eax].ADDINHANDLES.hWnd,WM_COMMAND,IDM_FILE_CLOSE_ALL or (BN_CLICKED SHL 16),NULL
					.endif
				.endif
				mov		eax,lpHandles
				.if ![ebx].ADDINDATA.szSessionFile && ![eax].ADDINHANDLES.hREd
					; Create the project
					invoke CreateProject,hWin
					.if eax
						invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
					.endif
				.endif
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNPATH
			.endif
		.elseif edx==EN_CHANGE
			invoke GetDlgItem,hWin,IDOK
			push	eax
			invoke GetDlgItemText,hWin,IDC_EDTNAME,addr buffer,sizeof buffer
			pop		edx
			invoke EnableWindow,edx,eax
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

NewProjectDialogProc endp
