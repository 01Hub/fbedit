
;ResourceEdit.dlg
IDD_DLGRESOURCE							equ 1100
IDC_GRDRES								equ 1001
IDC_BTNRESADD							equ 1002
IDC_BTNRESDEL							equ 1003

.const

szRESOURCE				db 'RESOURCE',0

.code

ExportResourceNames proc uses esi edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,64*1024
	mov		edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	.while byte ptr [esi].RESOURCEMEM.szfile
		.if byte ptr [esi].RESOURCEMEM.szname && [esi].RESOURCEMEM.value
			invoke SaveStr,edi,offset szDEFINE
			add		edi,eax
			mov		al,' '
			stosb
			invoke SaveStr,edi,addr [esi].RESOURCEMEM.szname
			add		edi,eax
			mov		al,' '
			stosb
			invoke SaveVal,[esi].RESOURCEMEM.value,FALSE
			mov		al,0Dh
			stosb
			mov		al,0Ah
			stosb
		.endif
		add		esi,sizeof RESOURCEMEM
	.endw
;	mov		ax,0A0Dh
;	stosw
	mov		byte ptr [edi],0
	pop		eax
	ret

ExportResourceNames endp

ExportResource proc uses esi edi,hMem:DWORD

	invoke xGlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,64*1024
	mov		edi,eax
	invoke GlobalLock,edi
	push	edi
	mov		esi,hMem
	.while byte ptr [esi].RESOURCEMEM.szfile
		.if byte ptr [esi].RESOURCEMEM.szname
			invoke SaveStr,edi,addr [esi].RESOURCEMEM.szname
			add		edi,eax
		.else
			invoke SaveVal,[esi].RESOURCEMEM.value,FALSE
		.endif
		mov		al,' '
		stosb
		mov		eax,[esi].RESOURCEMEM.ntype
		push	eax
		.if eax==0
			mov		eax,offset szBITMAP
		.elseif eax==1
			mov		eax,offset szCURSOR
		.elseif eax==2
			mov		eax,offset szICON
		.elseif eax==3
			mov		eax,offset szAVI
		.elseif eax==4
			mov		eax,offset szRCDATA
		.elseif eax==5
			mov		eax,offset szWAVE
		.elseif eax==6
			mov		eax,offset szIMAGE
		.elseif eax==7
			mov		eax,offset szMANIFEST
		.elseif eax==8
			mov		eax,offset szANICURSOR
		.elseif eax==9
			mov		eax,offset szFONT
		.elseif eax==10
			mov		eax,offset szMESSAGETABLE
		.endif
		invoke SaveStr,edi,eax
		add		edi,eax
		mov		al,' '
		stosb
		pop		eax
		.if eax!=10
			invoke SaveStr,edi,offset szDISCARDABLE
			add		edi,eax
			mov		al,' '
			stosb
		.endif
		mov		al,'"'
		stosb
		xor		ecx,ecx
		.while byte ptr [esi+ecx].RESOURCEMEM.szfile
			mov		al,[esi+ecx].RESOURCEMEM.szfile
			.if al=='\'
				mov		al,'/'
			.endif
			mov		[edi],al
			inc		ecx
			inc		edi
		.endw
		mov		al,'"'
		stosb
		mov		al,0Dh
		stosb
		mov		al,0Ah
		stosb
		add		esi,sizeof RESOURCEMEM
	.endw
	mov		al,0Dh
	stosb
	mov		al,0Ah
	stosb
	mov		byte ptr [edi],0
	pop		eax
	ret

ExportResource endp

SaveResourceEdit proc uses esi edi,hWin:HWND
	LOCAL	hGrd:HWND
	LOCAL	nRows:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	lpProMem:DWORD

	invoke GetWindowLong,hPrj,0
	mov		lpProMem,eax
	invoke GetDlgItem,hWin,IDC_GRDRES
	mov		hGrd,eax
	invoke SendMessage,hGrd,GM_GETROWCOUNT,0,0
	mov		nRows,eax
	invoke GetWindowLong,hWin,GWL_USERDATA
	.if !eax
		invoke SendMessage,hRes,PRO_ADDITEM,TPE_RESOURCE,FALSE
	.endif
	push	eax
	mov		edi,[eax].PROJECT.hmem
	xor		esi,esi
	.while esi<nRows
		;Type
		mov		ecx,esi
		shl		ecx,16
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		mov		eax,dword ptr buffer
		mov		[edi].RESOURCEMEM.ntype,eax
		;Name
		mov		ecx,esi
		shl		ecx,16
		add		ecx,1
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		invoke strcpy,addr [edi].RESOURCEMEM.szname,addr buffer
		;ID
		mov		ecx,esi
		shl		ecx,16
		add		ecx,2
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		mov		eax,dword ptr buffer
		mov		[edi].RESOURCEMEM.value,eax
		;File
		mov		ecx,esi
		shl		ecx,16
		add		ecx,3
		invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
		.if buffer
			invoke strcpy,addr [edi].RESOURCEMEM.szfile,addr buffer
			.if [edi].RESOURCEMEM.ntype==7
				invoke FindName,lpProMem,addr szMANIFEST
				.if !eax
					invoke AddName,lpProMem,addr szMANIFEST,addr szManifestValue
				.endif
			.endif
			add		edi,sizeof RESOURCEMEM
		.endif
		inc		esi
	.endw
	xor		eax,eax
	mov		[edi].RESOURCEMEM.ntype,eax
	mov		[edi].RESOURCEMEM.szname,al
	mov		[edi].RESOURCEMEM.value,eax
	mov		[edi].RESOURCEMEM.szfile,al
	pop		eax
	ret

SaveResourceEdit endp

ResourceEditProc proc uses esi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hGrd:HWND
	LOCAL	col:COLUMN
	LOCAL	row[4]:DWORD
	LOCAL	ofn:OPENFILENAME
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	rect:RECT
	LOCAL	fChanged:DWORD
	LOCAL	val:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		fChanged,FALSE
		invoke GetDlgItem,hWin,IDC_GRDRES
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
		;Type
		invoke ConvertDpiSize,90
		mov		col.colwt,eax
		mov		col.lpszhdrtext,offset szHdrType
		mov		col.halign,GA_ALIGN_LEFT
		mov		col.calign,GA_ALIGN_LEFT
		mov		col.ctype,TYPE_COMBOBOX
		mov		col.ctextmax,0
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col
		;Fill types in the combo
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szBITMAP
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szCURSOR
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szICON
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szAVI
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szRCDATA
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szWAVE
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szIMAGE
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szMANIFEST
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szANICURSOR
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szFONT
		invoke SendMessage,hGrd,GM_COMBOADDSTRING,0,offset szMESSAGETABLE
		;Name
		invoke ConvertDpiSize,100
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
		;Filename
		invoke ConvertDpiSize,140
		mov		col.colwt,eax
		mov		col.lpszhdrtext,offset szHdrFileName
		mov		col.halign,GA_ALIGN_LEFT
		mov		col.calign,GA_ALIGN_LEFT
		mov		col.ctype,TYPE_EDITBUTTON
		mov		col.ctextmax,MAX_PATH
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrd,GM_ADDCOL,0,addr col
		mov		esi,lParam
		invoke SetWindowLong,hWin,GWL_USERDATA,esi
		.if esi
			mov		esi,[esi].PROJECT.hmem
			.while [esi].RESOURCEMEM.szfile
				mov		eax,[esi].RESOURCEMEM.ntype
				mov		row,eax
				lea		eax,[esi].RESOURCEMEM.szname
				mov		row[4],eax
				mov		eax,[esi].RESOURCEMEM.value
				mov		row[8],eax
				lea		eax,[esi].RESOURCEMEM.szfile
				mov		row[12],eax
				invoke SendMessage,hGrd,GM_ADDROW,0,addr row
				add		esi,sizeof RESOURCEMEM 
			.endw
			invoke SendMessage,hGrd,GM_SETCURSEL,0,0
		.else
			invoke SaveResourceEdit,hWin
			invoke SetWindowLong,hWin,GWL_USERDATA,eax
			mov		fChanged,TRUE
		.endif
		invoke SendMessage,hPrpCboDlg,CB_RESETCONTENT,0,0
		invoke SendMessage,hPrpCboDlg,CB_ADDSTRING,0,offset szRESOURCE
		invoke SendMessage,hPrpCboDlg,CB_SETCURSEL,0,0
		invoke SendMessage,hWin,WM_SIZE,0,0
		mov		eax,fChanged
		mov		fDialogChanged,eax
	.elseif eax==WM_COMMAND
		invoke GetDlgItem,hWin,IDC_GRDRES
		mov		hGrd,eax
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke SendMessage,hGrd,GM_GETCURSEL,0,0
				invoke SendMessage,hGrd,GM_ENDEDIT,eax,FALSE
				invoke SaveResourceEdit,hWin
				.if fDialogChanged
					invoke SendMessage,hRes,PRO_SETMODIFY,TRUE,0
					mov		fDialogChanged,FALSE
				.endif
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,FALSE,NULL
				invoke PropertyList,0
			.elseif eax==IDC_BTNRESADD
				invoke SaveResourceEdit,hWin
				invoke SendMessage,hGrd,GM_ADDROW,0,NULL
				push	eax
				invoke SendMessage,hGrd,GM_SETCURSEL,0,eax
				invoke GetFreeProjectitemID,TPE_RESOURCE
				mov		val,eax
				pop		edx
				shl		edx,16
				or		edx,2
				invoke SendMessage,hGrd,GM_SETCELLDATA,edx,addr val
				invoke SetFocus,hGrd
				mov		fDialogChanged,TRUE
				xor		eax,eax
				jmp		Ex
			.elseif eax==IDC_BTNRESDEL
				invoke SendMessage,hGrd,GM_GETCURROW,0,0
				push	eax
				invoke SendMessage,hGrd,GM_DELROW,eax,0
				pop		eax
				invoke SendMessage,hGrd,GM_SETCURSEL,0,eax
				invoke SetFocus,hGrd
				mov		fDialogChanged,TRUE
				xor		eax,eax
				jmp		Ex
			.endif
		.endif
	.elseif eax==WM_NOTIFY
		invoke GetDlgItem,hWin,IDC_GRDRES
		mov		hGrd,eax
		mov		esi,lParam
		mov		eax,[esi].NMHDR.hwndFrom
		.if eax==hGrd
			mov		eax,[esi].NMHDR.code
			.if eax==GN_HEADERCLICK
				;Sort the grid by column, invert sorting order
				invoke SendMessage,hGrd,GM_COLUMNSORT,[esi].GRIDNOTIFY.col,SORT_INVERT
			.elseif eax==GN_BUTTONCLICK
				;Cell button clicked
				;Zero out the ofn struct
				invoke RtlZeroMemory,addr ofn,sizeof ofn
				;Type
				mov		ecx,[esi].GRIDNOTIFY.row
				shl		ecx,16
				invoke SendMessage,hGrd,GM_GETCELLDATA,ecx,addr buffer
				mov		eax,dword ptr buffer
				.if !eax
					;BITMAP
					mov		eax,offset szFilterBitmap
				.elseif eax==1
					;CURSOR
					mov		eax,offset szFilterCursor
				.elseif eax==2
					;ICON
					mov		eax,offset szFilterIcon
				.elseif eax==3
					;AVI
					mov		eax,offset szFilterAvi
				.elseif eax==4
					;RCDATA
					mov		eax,offset szFilterAny
				.elseif eax==5
					;WAVE
					mov		eax,offset szFilterWave
				.elseif eax==6
					;IMAGE
					mov		eax,offset szFilterImage
				.elseif eax==7
					;MANIFEST
					mov		eax,offset szFilterManifest
				.elseif eax==8
					;ANICURSOR
					mov		eax,offset szFilterAniCursor
				.elseif eax==9
					;FONT
					mov		eax,offset szFilterFont
				.elseif eax==10
					;MESSAGETABLE
					mov		eax,offset szFilterBin
				.else
					xor		eax,eax
				.endif
				mov		ofn.lpstrFilter,eax
				mov		eax,[esi].GRIDNOTIFY.lpdata
				.if byte ptr [eax]
					invoke strcpy,addr buffer,[esi].GRIDNOTIFY.lpdata
				.else
					mov		buffer,0
				.endif
				;Setup the ofn struct
				mov		ofn.lStructSize,sizeof ofn
				push	hWin
				pop		ofn.hwndOwner
				push	hInstance
				pop		ofn.hInstance
				mov		ofn.lpstrInitialDir,offset szProjectPath
				lea		eax,buffer
				mov		ofn.lpstrFile,eax
				mov		ofn.nMaxFile,sizeof buffer
				mov		ofn.lpstrDefExt,NULL
				mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
				;Show the Open dialog
				invoke GetOpenFileName,addr ofn
				.if eax
					invoke RemoveProjectPath,addr buffer
					mov		edx,[esi].GRIDNOTIFY.lpdata
					invoke strcpy,edx,eax
					mov		[esi].GRIDNOTIFY.fcancel,FALSE
					mov		fDialogChanged,TRUE
				.else
					mov		[esi].GRIDNOTIFY.fcancel,TRUE
				.endif
			.elseif eax==GN_AFTERUPDATE
				mov		fDialogChanged,TRUE
			.endif
		.endif
	.elseif eax==WM_CLOSE
		invoke DestroyWindow,hWin
		;invoke EndDialog,hWin,wParam
	.elseif eax==WM_SIZE
		invoke SendMessage,hDEd,WM_VSCROLL,SB_THUMBTRACK,0
		invoke SendMessage,hDEd,WM_HSCROLL,SB_THUMBTRACK,0
		invoke GetClientRect,hDEd,addr rect
		mov		rect.left,3
		mov		rect.top,3
		sub		rect.right,6
		sub		rect.bottom,6
		invoke MoveWindow,hWin,rect.left,rect.top,rect.right,rect.bottom,TRUE
		invoke GetClientRect,hWin,addr rect
		invoke GetDlgItem,hWin,IDC_GRDRES
		mov		hGrd,eax
		mov		rect.left,3
		mov		rect.top,3
		mov		rect.right,397
		sub		rect.bottom,6
		invoke MoveWindow,hGrd,rect.left,rect.top,rect.right,rect.bottom,TRUE
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
  Ex:
	ret

ResourceEditProc endp
