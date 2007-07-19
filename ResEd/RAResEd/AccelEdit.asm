
;AccelEdit.dlg
IDD_DLGACCEL		equ 1300
IDC_GRDACL			equ 1001
IDC_BTNACLADD		equ 1002
IDC_BTNACLDEL		equ 1003
IDC_EDTACLNAME		equ 1004
IDC_EDTACLID		equ 1005
IDC_BTNACLLANG		equ 1006

.data

szAccelName			db 'IDR_ACCEL',0
defacl				ACCELMEM <,1,0,0,0,0,0>
					ACCELMEM <>
.data?

fNoUpdate			dd ?
acllng				LANGUAGEMEM <>

.code

ExportAccelNames proc uses esi edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,64*1024
	mov		edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	.while byte ptr [esi].ACCELMEM.szname || [esi].ACCELMEM.value
		.if byte ptr [esi].ACCELMEM.szname && [esi].ACCELMEM.value
			invoke SaveStr,edi,offset szDEFINE
			add		edi,eax
			mov		al,' '
			stosb
			invoke SaveStr,edi,addr [esi].ACCELMEM.szname
			add		edi,eax
			mov		al,' '
			stosb
			invoke SaveVal,[esi].ACCELMEM.value,FALSE
			mov		al,0Dh
			stosb
			mov		al,0Ah
			stosb
		.endif
		add		esi,sizeof ACCELMEM
	.endw
	mov		byte ptr [edi],0
	pop		eax
	ret

ExportAccelNames endp

ExportAccel proc uses esi edi,hMem:DWORD
	LOCAL	fAscii:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,64*1024
	mov		edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	.if byte ptr [esi].ACCELMEM.szname
		invoke SaveStr,edi,addr [esi].ACCELMEM.szname
		add		edi,eax
	.else
		invoke SaveVal,[esi].ACCELMEM.value,FALSE
	.endif
	mov		al,' '
	stosb
	invoke SaveStr,edi,offset szACCELERATORS
	add		edi,eax
	mov		al,0Dh
	stosb
	mov		al,0Ah
	stosb
	.if [esi].ACCELMEM.lang || [esi].ACCELMEM.sublang
		invoke SaveLanguage,addr [esi].ACCELMEM.lang,edi
		add		edi,eax
	.endif
	add		esi,sizeof ACCELMEM
	invoke SaveStr,edi,offset szBEGIN
	add		edi,eax
	mov		al,0Dh
	stosb
	mov		al,0Ah
	stosb
	.while byte ptr [esi].ACCELMEM.szname || byte ptr [esi].ACCELMEM.value
		mov		al,' '
		stosb
		stosb
		mov		ecx,[esi].ACCELMEM.nkey
		.if ecx
			push	esi
			mov		esi,offset szAclKeys
			.while ecx
				push	ecx
				invoke lstrlen,esi
				lea		esi,[esi+eax+1]
				pop		ecx
				dec		ecx
			.endw
			movzx	eax,byte ptr [esi]
			pop		esi
			mov		fAscii,FALSE
		.else
			mov		eax,[esi].ACCELMEM.nascii
			mov		fAscii,TRUE
		.endif
		invoke SaveVal,eax,FALSE
		mov		al,','
		stosb
		.if byte ptr [esi].ACCELMEM.szname
			invoke SaveStr,edi,addr [esi].ACCELMEM.szname
			add		edi,eax
		.else
			invoke SaveVal,[esi].ACCELMEM.value,FALSE
		.endif
		mov		al,','
		stosb
		.if fAscii
			mov		eax,offset szASCII
		.else
			mov		eax,offset szVIRTKEY
		.endif
		invoke SaveStr,edi,eax
		add		edi,eax
		test	[esi].ACCELMEM.flag,1
		.if !ZERO?
			mov		al,','
			stosb
			invoke SaveStr,edi,offset szCONTROL
			add		edi,eax
		.endif
		test	[esi].ACCELMEM.flag,2
		.if !ZERO?
			mov		al,','
			stosb
			invoke SaveStr,edi,offset szSHIFT
			add		edi,eax
		.endif
		test	[esi].ACCELMEM.flag,4
		.if !ZERO?
			mov		al,','
			stosb
			invoke SaveStr,edi,offset szALT
			add		edi,eax
		.endif
		mov		al,','
		stosb
		invoke SaveStr,edi,offset szNOINVERT
		add		edi,eax
		mov		al,0Dh
		stosb
		mov		al,0Ah
		stosb
		add		esi,sizeof ACCELMEM
	.endw
	invoke SaveStr,edi,offset szEND
	add		edi,eax
	mov		al,0Dh
	stosb
	mov		al,0Ah
	stosb
	mov		byte ptr [edi],0
	pop		eax
	ret

ExportAccel endp

SaveAccelEdit proc uses ebx esi edi,hWin:HWND
	LOCAL	hGrd:HWND
	LOCAL	nRows:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke GetDlgItem,hWin,IDC_GRDACL
	mov		hGrd,eax
	invoke SendMessage,hGrd,GM_GETROWCOUNT,0,0
	mov		nRows,eax
	invoke GetWindowLong,hWin,GWL_USERDATA
	.if !eax
		invoke SendMessage,hPrj,PRO_ADDITEM,TPE_ACCEL,FALSE
	.endif
	mov		ebx,eax
	mov		edi,[eax].PROJECT.hmem
	invoke GetDlgItemText,hWin,IDC_EDTACLNAME,addr [edi].ACCELMEM.szname,MaxName
	invoke GetDlgItemInt,hWin,IDC_EDTACLID,NULL,FALSE
	mov		[edi].ACCELMEM.value,eax
	.if [edi].ACCELMEM.szname
		lea		eax,[edi].ACCELMEM.szname
	.else
		invoke ResEdBinToDec,[edi].ACCELMEM.value,addr buffer
		lea		eax,buffer
	.endif
	invoke GetProjectItemName,ebx,addr buffer
	invoke SetProjectItemName,ebx,addr buffer
	mov		eax,acllng.lang
	mov		[edi].ACCELMEM.lang,eax
	mov		eax,acllng.sublang
	mov		[edi].ACCELMEM.sublang,eax
	add		edi,sizeof ACCELMEM
	xor		esi,esi
	.while esi<nRows
		;Name
		mov		ecx,esi
		shl		ecx,16
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		invoke lstrcpy,addr [edi].ACCELMEM.szname,addr buffer
		;ID
		mov		ecx,esi
		shl		ecx,16
		add		ecx,1
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		mov		eax,dword ptr buffer
		mov		[edi].ACCELMEM.value,eax
		;Key
		mov		ecx,esi
		shl		ecx,16
		add		ecx,2
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		mov		eax,dword ptr buffer
		mov		[edi].ACCELMEM.nkey,eax
		;Ascii
		mov		ecx,esi
		shl		ecx,16
		add		ecx,3
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		movzx	eax,byte ptr buffer
		mov		[edi].ACCELMEM.nascii,eax
		xor		ebx,ebx
		;Ctrl
		mov		ecx,esi
		shl		ecx,16
		add		ecx,4
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		.if dword ptr buffer
			or		ebx,1
		.endif
		;Shift
		mov		ecx,esi
		shl		ecx,16
		add		ecx,5
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		.if dword ptr buffer
			or		ebx,2
		.endif
		;Alt
		mov		ecx,esi
		shl		ecx,16
		add		ecx,6
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		.if dword ptr buffer
			or		ebx,4
		.endif
		mov		[edi].ACCELMEM.flag,ebx
		add		edi,sizeof ACCELMEM
		inc		esi
	.endw
	xor		eax,eax
	mov		[edi].ACCELMEM.szname,al
	mov		[edi].ACCELMEM.value,eax
	mov		[edi].ACCELMEM.nkey,eax
	mov		[edi].ACCELMEM.flag,eax
	ret

SaveAccelEdit endp

AccelEditProc proc uses esi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hGrd:HWND
	LOCAL	col:COLUMN
	LOCAL	row[7]:DWORD
	LOCAL	val:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_GRDACL
		mov		hGrd,eax
		invoke SendMessage,hWin,WM_GETFONT,0,0
		invoke SendMessage,hGrd,WM_SETFONT,eax,FALSE
		invoke SendMessage,hGrd,GM_SETBACKCOLOR,color.back,0
		invoke SendMessage,hGrd,GM_SETTEXTCOLOR,color.text,0
		invoke ConvertDpiSize,18
		push	eax
		invoke SendMessage,hGrd,GM_SETHDRHEIGHT,0,eax
		pop		eax
		invoke SendMessage,hGrd,GM_SETROWHEIGHT,0,eax
		;Name
		invoke ConvertDpiSize,110
		mov		col.colwt,eax
		mov		col.lpszhdrtext,offset szHdrName
		mov		col.halign,GA_ALIGN_LEFT
		mov		col.calign,GA_ALIGN_LEFT
		mov		col.ctype,TYPE_EDITTEXT
		mov		col.ctextmax,MaxName-1
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col
		;ID
		invoke ConvertDpiSize,40
		mov		col.colwt,eax
		mov		col.lpszhdrtext,offset szHdrID
		mov		col.halign,GA_ALIGN_RIGHT
		mov		col.calign,GA_ALIGN_RIGHT
		mov		col.ctype,TYPE_EDITLONG
		mov		col.ctextmax,5
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col
		;Keys
		invoke ConvertDpiSize,76
		mov		col.colwt,eax
		mov		col.lpszhdrtext,offset szHdrKey
		mov		col.halign,GA_ALIGN_LEFT
		mov		col.calign,GA_ALIGN_LEFT
		mov		col.ctype,TYPE_COMBOBOX
		mov		col.ctextmax,0
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col
		;Fill Keys in the combo
		mov		esi,offset szAclKeys
		.while byte ptr [esi]
			inc		esi
			invoke SendMessage,hGrd,GM_COMBOADDSTRING,2,esi
			invoke lstrlen,esi
			lea		esi,[esi+eax+1]
		.endw
		;Ascii
		invoke ConvertDpiSize,36
		mov		col.colwt,eax
		mov		col.lpszhdrtext,offset szHdrAscii
		mov		col.halign,GA_ALIGN_CENTER
		mov		col.calign,GA_ALIGN_CENTER
		mov		col.ctype,TYPE_EDITTEXT
		mov		col.ctextmax,1
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col
		;Ctrl
		invoke ConvertDpiSize,36
		mov		col.colwt,eax
		mov		col.lpszhdrtext,offset szHdrCtrl
		mov		col.halign,GA_ALIGN_CENTER
		mov		col.calign,GA_ALIGN_CENTER
		mov		col.ctype,TYPE_CHECKBOX
		mov		col.ctextmax,0
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col
		;Shift
		invoke ConvertDpiSize,36
		mov		col.colwt,eax
		mov		col.lpszhdrtext,offset szHdrShift
		mov		col.halign,GA_ALIGN_CENTER
		mov		col.calign,GA_ALIGN_CENTER
		mov		col.ctype,TYPE_CHECKBOX
		mov		col.ctextmax,0
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col
		;Alt
		invoke ConvertDpiSize,36
		mov		col.colwt,eax
		mov		col.lpszhdrtext,offset szHdrAlt
		mov		col.halign,GA_ALIGN_CENTER
		mov		col.calign,GA_ALIGN_CENTER
		mov		col.ctype,TYPE_CHECKBOX
		mov		col.ctextmax,0
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col
		mov		esi,lParam
		invoke SetWindowLong,hWin,GWL_USERDATA,esi
		.if esi
			mov		esi,[esi].PROJECT.hmem
		.else
			invoke GetFreeProjectitemID,TPE_ACCEL
			mov		esi,offset defacl
			mov		[esi].ACCELMEM.value,eax
			invoke lstrcpy,addr [esi].ACCELMEM.szname,addr szAccelName
			invoke GetUnikeName,addr [esi].ACCELMEM.szname
		.endif
		invoke SetDlgItemText,hWin,IDC_EDTACLNAME,addr [esi].ACCELMEM.szname
		invoke SetDlgItemInt,hWin,IDC_EDTACLID,[esi].ACCELMEM.value,FALSE
		mov		eax,[esi].ACCELMEM.lang
		mov		acllng.lang,eax
		mov		eax,[esi].ACCELMEM.sublang
		mov		acllng.sublang,eax
		add		esi,sizeof ACCELMEM
		.while [esi].ACCELMEM.szname || [esi].ACCELMEM.value
			lea		eax,[esi].ACCELMEM.szname
			mov		row,eax
			mov		eax,[esi].ACCELMEM.value
			mov		row[4],eax
			mov		eax,[esi].ACCELMEM.nkey
			mov		row[8],eax
			mov		eax,[esi].ACCELMEM.nascii
			mov		val,eax
			.if eax
				lea		eax,val
			.endif
			mov		row[12],eax
			xor		eax,eax
			mov		row[16],eax
			mov		row[20],eax
			mov		row[24],eax
			mov		eax,[esi].ACCELMEM.flag
			shr		eax,1
			rcl		row[16],1
			shr		eax,1
			rcl		row[20],1
			shr		eax,1
			rcl		row[24],1
			invoke SendMessage,hGrd,GM_ADDROW,0,addr row
			add		esi,sizeof ACCELMEM
		.endw
		invoke SendMessage,hGrd,GM_SETCURSEL,0,0
		invoke SendDlgItemMessage,hWin,IDC_EDTACLNAME,EM_LIMITTEXT,MaxName-1,0
		invoke SendDlgItemMessage,hWin,IDC_EDTACLID,EM_LIMITTEXT,5,0
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			push	eax
			invoke GetDlgItem,hWin,IDC_GRDACL
			mov		hGrd,eax
			invoke SetFocus,hGrd
			pop		eax
			.if eax==IDOK
				invoke SaveAccelEdit,hWin
				invoke SendMessage,hPrj,PRO_SETMODIFY,TRUE,0
				invoke SendMessage,hWin,WM_CLOSE,TRUE,NULL
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,FALSE,NULL
			.elseif eax==IDC_BTNACLLANG
				invoke DialogBoxParam,hInstance,IDD_LANGUAGE,hWin,offset LanguageEditProc2,offset acllng
			.elseif eax==IDC_BTNACLADD
				invoke SendMessage,hGrd,GM_ADDROW,0,NULL
				invoke SendMessage,hGrd,GM_SETCURSEL,0,eax
				invoke SetFocus,hGrd
				xor		eax,eax
				jmp		Ex
			.elseif eax==IDC_BTNACLDEL
				invoke SendMessage,hGrd,GM_GETCURROW,0,0
				push	eax
				invoke SendMessage,hGrd,GM_DELROW,eax,0
				pop		eax
				invoke SendMessage,hGrd,GM_SETCURSEL,0,eax
				invoke SetFocus,hGrd
				xor		eax,eax
				jmp		Ex
			.endif
		.endif
	.elseif eax==WM_NOTIFY
		invoke GetDlgItem,hWin,IDC_GRDACL
		mov		hGrd,eax
		mov		esi,lParam
		mov		eax,[esi].NMHDR.hwndFrom
		.if eax==hGrd
			mov		eax,[esi].NMHDR.code
			.if eax==GN_HEADERCLICK
				;Sort the grid by column, invert sorting order
				invoke SendMessage,hGrd,GM_COLUMNSORT,[esi].GRIDNOTIFY.col,SORT_INVERT
			.elseif eax==GN_BEFOREEDIT
				.if [esi].GRIDNOTIFY.col==3
					mov		ecx,[esi].GRIDNOTIFY.row
					shl		ecx,16
					add		ecx,2
					invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr val
					.if dword ptr val
						mov		[esi].GRIDNOTIFY.fcancel,TRUE
					.endif
				.endif
			.elseif eax==GN_AFTERUPDATE
				.if [esi].GRIDNOTIFY.col==2 && !fNoUpdate
					mov		ecx,[esi].GRIDNOTIFY.row
					shl		ecx,16
					add		ecx,2
					push	ecx
					invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr val
					pop		ecx
					.if dword ptr val
						inc		ecx
						mov		fNoUpdate,TRUE
						invoke SendMessage,hGrd,GM_SETCELLDATA,ecx,NULL
						mov		fNoUpdate,FALSE
					.endif
				.endif
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,wParam
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
  Ex:
	ret

AccelEditProc endp
