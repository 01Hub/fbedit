
IDD_PATHOPTION		equ 3500
IDC_EDTBIN			equ 1001
IDC_EDTINC			equ 1002
IDC_EDTLIB			equ 1003
IDC_BTNPATHRESTORE	equ 1004

IDD_BUILDOPTION		equ 3400
IDC_EDTRES			equ 1001
IDC_EDTASM			equ 1002
IDC_EDTLNK			equ 1003
IDC_BTNRESTORE		equ 1004

.const

szPath				db 'path',0
szInclude			db 'include',0
szIncludelib		db 'lib',0

.data?

hEnv				dd ?
hEnvMem				dd ?
pNextVal			dd ?

.code

ResetEnvironment proc uses esi edi

	mov		edi,hEnv
	.if	edi
		.while byte	ptr	[edi]
			mov		esi,edi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
			invoke SetEnvironmentVariable,edi,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
			mov		edi,esi
		.endw
		invoke GlobalFree,hEnv
		xor		eax,eax
		mov		hEnv,eax
	.endif
	ret

ResetEnvironment endp

SetVar proc uses edi,lpSave:DWORD,lpName:DWORD,lpValue:DWORD

	mov		edi,lpSave
	mov		byte ptr tmpbuff[4096],0
	invoke GetEnvironmentVariable,lpName,addr tmpbuff[4096],1024
	invoke lstrcpy,edi,lpName
	invoke lstrlen,edi
	lea		edi,[edi+eax+1]
	invoke lstrcpy,edi,addr tmpbuff[4096]
	invoke lstrlen,edi
	lea		edi,[edi+eax+1]
	invoke lstrcpy,addr tmpbuff,lpValue
	.if byte ptr tmpbuff[4096]
		invoke lstrcat,addr tmpbuff,addr szSemi
		invoke lstrcat,addr tmpbuff,addr tmpbuff[4096]
	.endif
	invoke SetEnvironmentVariable,lpName,addr tmpbuff
	ret

SetVar endp

SetEnvironment proc uses edi
	LOCAL	lpEnv:DWORD

	;Environment
	invoke ResetEnvironment
	invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16384
	mov		hEnv,eax
	mov		edi,eax
	invoke GetEnvironmentStrings
	mov		lpEnv,eax
	invoke SetVar,edi,addr szPath,addr PathBin
	mov		edi,eax
	invoke SetVar,edi,addr szInclude,addr PathInc
	mov		edi,eax
	invoke SetVar,edi,addr szIncludelib,addr PathLib
	mov		edi,eax
	ret

SetEnvironment endp

PathOptionDialogProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_EDTBIN,EM_LIMITTEXT,240,0
		invoke SendDlgItemMessage,hWin,IDC_EDTINC,EM_LIMITTEXT,240,0
		invoke SendDlgItemMessage,hWin,IDC_EDTLIB,EM_LIMITTEXT,240,0
		invoke SetDlgItemText,hWin,IDC_EDTBIN,addr PathBin
		invoke SetDlgItemText,hWin,IDC_EDTINC,addr PathInc
		invoke SetDlgItemText,hWin,IDC_EDTLIB,addr PathLib
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke GetDlgItemText,hWin,IDC_EDTBIN,addr PathBin,240
				invoke lstrlen,addr PathBin
				inc		eax
				invoke RegSetValueEx,hReg,addr szPathBin,0,REG_SZ,addr PathBin,eax
				invoke GetDlgItemText,hWin,IDC_EDTINC,addr PathInc,240
				invoke lstrlen,addr PathInc
				inc		eax
				invoke RegSetValueEx,hReg,addr szPathInc,0,REG_SZ,addr PathInc,eax
				invoke GetDlgItemText,hWin,IDC_EDTLIB,addr PathLib,240
				invoke lstrlen,addr PathLib
				inc		eax
				invoke RegSetValueEx,hReg,addr szPathLib,0,REG_SZ,addr PathLib,eax
				invoke SetEnvironment
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNRESTORE
				invoke SetDlgItemText,hWin,IDC_EDTBIN,addr defPathBin
				invoke SetDlgItemText,hWin,IDC_EDTINC,addr defPathInc
				invoke SetDlgItemText,hWin,IDC_EDTLIB,addr defPathLib
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

PathOptionDialogProc endp

BuildOptionDialogProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_EDTRES,EM_LIMITTEXT,240,0
		invoke SendDlgItemMessage,hWin,IDC_EDTASM,EM_LIMITTEXT,240,0
		invoke SendDlgItemMessage,hWin,IDC_EDTLNK,EM_LIMITTEXT,240,0
		invoke SetDlgItemText,hWin,IDC_EDTRES,addr CompileRC
		invoke SetDlgItemText,hWin,IDC_EDTASM,addr Assemble
		invoke SetDlgItemText,hWin,IDC_EDTLNK,addr Link
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke GetDlgItemText,hWin,IDC_EDTRES,addr CompileRC,240
				invoke lstrlen,addr CompileRC
				inc		eax
				invoke RegSetValueEx,hReg,addr szCompileRC,0,REG_SZ,addr CompileRC,eax
				invoke GetDlgItemText,hWin,IDC_EDTASM,addr Assemble,240
				invoke lstrlen,addr Assemble
				inc		eax
				invoke RegSetValueEx,hReg,addr szAssemble,0,REG_SZ,addr Assemble,eax
				invoke GetDlgItemText,hWin,IDC_EDTLNK,addr Link,240
				invoke lstrlen,addr Link
				inc		eax
				invoke RegSetValueEx,hReg,addr szLink,0,REG_SZ,addr Link,eax
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNRESTORE
				invoke SetDlgItemText,hWin,IDC_EDTRES,addr defCompileRC
				invoke SetDlgItemText,hWin,IDC_EDTASM,addr defAssemble
				invoke SetDlgItemText,hWin,IDC_EDTLNK,addr defLink
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

BuildOptionDialogProc endp
