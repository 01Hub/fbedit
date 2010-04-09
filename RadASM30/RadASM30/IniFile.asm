.code

GetWinPos proc
	LOCAL	buffer[256]:BYTE

	invoke GetPrivateProfileString,addr szIniWin,addr szIniPos,NULL,addr buffer,sizeof buffer,addr da.szRadASMIni
	invoke GetItemInt,addr buffer,10
	mov		da.win.x,eax
	invoke GetItemInt,addr buffer,10
	mov		da.win.y,eax
	invoke GetItemInt,addr buffer,780
	mov		da.win.wt,eax
	invoke GetItemInt,addr buffer,580
	mov		da.win.ht,eax
	invoke GetItemInt,addr buffer,0
	mov		da.win.fmax,eax
	invoke GetItemInt,addr buffer,0
	mov		da.win.ftopmost,eax
	invoke GetItemInt,addr buffer,0
	mov		da.win.fcldmax,eax
	invoke GetItemInt,addr buffer,VIEW_STATUSBAR
	mov		da.win.fView,eax
	ret

GetWinPos endp

PutWinPos proc
	LOCAL	buffer[256]:BYTE
	LOCAL	rect:RECT

	mov		buffer,0
	invoke IsZoomed,ha.hWnd
	mov 	da.win.fmax,eax
	.if !eax
		invoke IsIconic,ha.hWnd
		.if !eax
			invoke GetWindowRect,ha.hWnd,addr rect
			mov		eax,rect.left
			mov		da.win.x,eax
			mov		eax,rect.top
			mov		da.win.y,eax
			mov		eax,rect.right
			sub		eax,rect.left
			mov		da.win.wt,eax
			mov		eax,rect.bottom
			sub		eax,rect.top
			mov		da.win.ht,eax
		.endif
	.endif
	invoke PutItemInt,addr buffer,da.win.x
	invoke PutItemInt,addr buffer,da.win.y
	invoke PutItemInt,addr buffer,da.win.wt
	invoke PutItemInt,addr buffer,da.win.ht
	invoke PutItemInt,addr buffer,da.win.fmax
	invoke PutItemInt,addr buffer,da.win.ftopmost
	invoke PutItemInt,addr buffer,da.win.fcldmax
	invoke PutItemInt,addr buffer,da.win.fView
	invoke WritePrivateProfileString,addr szIniWin,addr szIniPos,addr buffer[1],addr da.szRadASMIni
	ret

PutWinPos endp
