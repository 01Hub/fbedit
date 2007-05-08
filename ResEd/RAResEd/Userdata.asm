IDD_USERDATA					equ 2500
IDC_EDTUSERDATA					equ 1003
IDC_EDTUDID						equ 1002
IDC_EDTUDNAME					equ 1001
IDC_CBOUDTYPE					equ 1004

.data

defuserdata			USERDATAMEM<"IDR_USERDATA",1,0>
					db 0

.code

ExportUserdataNames proc uses esi edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,1024*16
	mov     edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	;#define
    .if [esi].USERDATAMEM.szname && [esi].USERDATAMEM.value
		invoke SaveStr,edi,addr szDEFINE
		add		edi,eax
		mov		al,' '
		stosb
		invoke SaveStr,edi,addr [esi].USERDATAMEM.szname
		add		edi,eax
		mov		al,' '
		stosb
		invoke ResEdBinToDec,[esi].USERDATAMEM.value,edi
		invoke lstrlen,edi
		lea		edi,[edi+eax]
		mov		al,0Dh
		stosb
		mov		al,0Ah
		stosb
	.endif
	mov		al,0
	stosb
	pop		eax
	ret

ExportUserdataNames endp

ExportUserdata proc uses esi edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,16*1024
	mov		edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	;Name or ID
    .if [esi].USERDATAMEM.szname
    	invoke lstrcpy,edi,addr [esi].USERDATAMEM.szname
	.else
		invoke ResEdBinToDec,[esi].USERDATAMEM.value,edi
	.endif
	invoke lstrlen,edi
	add		edi,eax
	mov		al,' '
	stosb
	mov		eax,[esi].USERDATAMEM.ntype
	.if eax==0
		;Bitmap
		mov		eax,offset szBITMAP
	.elseif eax==1
		;Cursor
		mov		eax,offset szCURSOR
	.elseif eax==2
		;Icon
		mov		eax,offset szICON
	.elseif eax==3
		;Avi
		mov		eax,offset szAVI
	.elseif eax==4
		;RCDATA
		mov		eax,offset szRCDATA
	.elseif eax==5
		;Wave
		mov		eax,offset szWAVE
	.elseif eax==6
		;Image
		mov		eax,offset szIMAGE
	.elseif eax==7
		;Manifest
		mov		eax,offset szMANIFEST
	.elseif eax==8
		mov		eax,offset szANICURSOR
		;Ani cursor
	.elseif eax==9
		;Font
		mov		eax,offset szFONT
	.elseif eax==10
		;Messagetable
		mov		eax,offset szMESSAGETABLE
	.endif
   	invoke lstrcpy,edi,eax
	invoke lstrlen,edi
	add		edi,eax
	mov		al,0Dh
	stosb
	mov		al,0Ah
	stosb
	invoke SaveStr,edi,addr szBEGIN
	add		edi,eax
	mov		al,0Dh
	stosb
	mov		al,0Ah
	stosb
	lea		edx,[esi+sizeof USERDATAMEM]
	.while byte ptr [edx]
		mov		al,[edx]
		mov		[edi],al
		inc		edi
		inc		edx
	.endw
	.if byte ptr [edi-1]!=0Ah
		mov		al,0Dh
		stosb
		mov		al,0Ah
		stosb
	.endif
	invoke SaveStr,edi,addr szEND
	add		edi,eax
	mov		al,0Dh
	stosb
	mov		al,0Ah
	stosb
	mov		byte ptr [edi],0
	pop		eax
	ret

ExportUserdata endp

UserdataEditProc proc uses esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[256]:BYTE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		esi,lParam
		.if [esi].PROJECT.hmem
			mov		edi,[esi].PROJECT.hmem
		.else
			mov		edi,offset defuserdata
		.endif
		invoke SetWindowLong,hWin,GWL_USERDATA,esi
		invoke SendDlgItemMessage,hWin,IDC_EDTUDNAME,EM_LIMITTEXT,MaxName-1,0
		invoke SetDlgItemText,hWin,IDC_EDTUDNAME,addr [edi].USERDATAMEM.szname
		invoke SendDlgItemMessage,hWin,IDC_EDTUDID,EM_LIMITTEXT,5,0
		invoke SetDlgItemInt,hWin,IDC_EDTUDID,[edi].USERDATAMEM.value,TRUE
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szBITMAP
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szCURSOR
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szICON
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szAVI
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szRCDATA
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szWAVE
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szIMAGE
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szMANIFEST
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szANICURSOR
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szFONT
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_ADDSTRING,0,offset szMESSAGETABLE
		invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_SETCURSEL,0,0
		invoke SetDlgItemText,hWin,IDC_EDTUSERDATA,addr [edi+sizeof USERDATAMEM]
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				xor		esi,esi
				invoke GetWindowLong,hWin,GWL_USERDATA
				.if eax
					mov		esi,[eax].PROJECT.hmem
				.endif
				.if !esi
					invoke SendMessage,hPrj,PRO_ADDITEM,TPE_USERDATA,FALSE
				.endif
				mov		[eax].PROJECT.changed,TRUE
				mov		esi,[eax].PROJECT.hmem
				invoke GetDlgItemText,hWin,IDC_EDTUDNAME,addr [esi].USERDATAMEM.szname,MaxName
				invoke GetDlgItemInt,hWin,IDC_EDTUDID,NULL,FALSE
				mov		[esi].USERDATAMEM.value,eax
				invoke SendDlgItemMessage,hWin,IDC_CBOUDTYPE,CB_GETCURSEL,0,0
				mov		[esi].USERDATAMEM.ntype,eax
				invoke GetDlgItemText,hWin,IDC_EDTUSERDATA,addr [esi+sizeof USERDATAMEM],64*1024
				invoke GetWindowLong,hWin,GWL_USERDATA
				mov		esi,eax
				invoke GetProjectItemName,esi,addr buffer
				invoke SetProjectItemName,esi,addr buffer
				invoke SendMessage,hWin,WM_CLOSE,NULL,TRUE
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
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

UserdataEditProc endp
