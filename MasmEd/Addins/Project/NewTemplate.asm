

;NewTemplate.dlg
IDD_DLGNEWTEMPLATE				equ 2000
IDC_EDTDESCRIPTION				equ 1001
IDC_LSTFILES					equ 1002
IDC_BTNADD						equ 1003
IDC_BTNDEL						equ 1004
IDC_EDTFILENAME					equ 1005
IDC_BTNFILENAME					equ 1006

.const

TPLFilterString					db 'Template (*.tpl)',0,'*.tpl',0,0
szTplFile						db 'tpl',0
ALLFilterString					db 'All files (*.*)',0,'*.*',0,0

.code

NewTemplateDialogProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG

	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK

			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNFILENAME
				invoke RtlZeroMemory,addr ofn,SizeOf OPENFILENAME
				mov		ofn.lStructSize,SizeOf OPENFILENAME
				mov		eax,hWin
				mov		ofn.hwndOwner,eax
				mov		eax,hInstance
				mov		ofn.hInstance,eax
				mov		eax,lpData
				invoke lstrcpy,offset tempbuff,addr [eax].ADDINDATA.AppPath
				invoke lstrcat,offset tempbuff,offset szTemplatesPath
				mov		ofn.lpstrInitialDir,offset tempbuff
				mov		ofn.lpstrFilter,offset TPLFilterString
				mov		ofn.lpstrDefExt,offset szTplFile
				mov		buffer,0
				lea		eax,buffer
				mov		ofn.lpstrFile,eax
				mov		ofn.nMaxFile,sizeof buffer
				mov		ofn.Flags,OFN_EXPLORER or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_OVERWRITEPROMPT
				invoke GetSaveFileName,addr ofn
				.if eax
					invoke SetDlgItemText,hWin,IDC_EDTFILENAME,addr buffer
				.endif
			.elseif eax==IDC_BTNADD
				invoke RtlZeroMemory,addr ofn,SizeOf OPENFILENAME
				mov		ofn.lStructSize,SizeOf OPENFILENAME
				mov		eax,hWin
				mov		ofn.hwndOwner,eax
				mov		eax,hInstance
				mov		ofn.hInstance,eax
				mov		eax,lpData
				invoke lstrcpy,offset tempbuff,addr [eax].ADDINDATA.szInitFolder
				mov		ofn.lpstrInitialDir,offset tempbuff
				mov		ofn.lpstrFilter,offset ALLFilterString
				;mov		ofn.lpstrDefExt,offset szTplFile
				mov		buffer,0
				lea		eax,buffer
				mov		ofn.lpstrFile,eax
				mov		ofn.nMaxFile,sizeof buffer
				mov		ofn.Flags,OFN_EXPLORER or OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_ALLOWMULTISELECT or OFN_EXPLORER
				invoke GetOpenFileName,addr ofn
				.if eax
					
				.endif
			.elseif eax==IDC_BTNDEL
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

NewTemplateDialogProc endp
