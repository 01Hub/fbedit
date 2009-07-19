.code

UpdateFileTime proc uses ebx,lpMem:DWORD
	LOCAL	hFile:DWORD

	mov		ebx,lpMem
	invoke CreateFile,addr [ebx].TABMEM.filename,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
	.if eax!=INVALID_HANDLE_VALUE
		mov		hFile,eax
		invoke GetFileTime,hFile,NULL,NULL,addr [ebx].TABMEM.ft
		invoke CloseHandle,hFile
	.endif
	ret

UpdateFileTime endp

ThreadProc proc uses ebx esi edi,Param:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	filet:FILETIME
	LOCAL	nInx:DWORD
	LOCAL	tci:TC_ITEM

	mov		esi,fn.lpPath
	mov		edi,fn.lpHandle
	mov		ebx,fn.lpPtrPth
	.while [esi].FILENOTIFYPATH.path
		.if [esi].FILENOTIFYPATH.nCount
			invoke FindFirstChangeNotification,addr [esi].FILENOTIFYPATH.path,FALSE,FILE_NOTIFY_CHANGE_LAST_WRITE 
			mov		[edi],eax
			lea		eax,[esi].FILENOTIFYPATH.path
			mov		[ebx],eax
			add		edi,4
			add		ebx,4
			inc		fn.nCount
		.endif
		add		esi,sizeof FILENOTIFYPATH
	.endw
	.while TRUE
		; Wait for notification.		
		invoke WaitForMultipleObjects,fn.nCount,fn.lpHandle,FALSE,INFINITE
		.if eax<MAXIMUM_WAIT_OBJECTS
			mov		esi,fn.lpPtrPth
			lea		esi,[esi+eax*4]
			mov		edi,fn.lpHandle
			lea		edi,[edi+eax*4]
			mov		nInx,-1
			mov		tci.imask,TCIF_PARAM
			.while TRUE
				inc		nInx
				invoke SendMessage,hTab,TCM_GETITEM,nInx,addr tci
				.break .if !eax
				mov		ebx,tci.lParam
				invoke lstrcpy,addr buffer,addr [ebx].TABMEM.filename
				invoke lstrlen,addr buffer
				.while eax
					.if byte ptr buffer[eax]=='\'
						mov		byte ptr buffer[eax],0
						.break
					.endif
					dec		eax
				.endw
				invoke lstrcmpi,addr buffer,[esi]
				.if !eax
					mov		eax,[ebx].TABMEM.ft.dwLowDateTime
					mov		filet.dwLowDateTime,eax
					mov		eax,[ebx].TABMEM.ft.dwHighDateTime
					mov		filet.dwHighDateTime,eax
					invoke UpdateFileTime,ebx
					invoke CompareFileTime,addr [ebx].TABMEM.ft,addr filet
					.if sdword ptr eax!=0
						inc		[ebx].TABMEM.nchange
					.endif
				.endif
			.endw
			invoke FindNextChangeNotification,[edi]
			.if eax==FALSE
				.break
			.endif
		.elseif eax==WAIT_ABANDONED || eax==WAIT_TIMEOUT || eax==WAIT_FAILED
			.break
		.endif
	.endw
	ret

ThreadProc ENDP

CloseNotify proc uses esi

	mov		esi,fn.lpHandle
	.while fn.nCount
		invoke FindCloseChangeNotification,[esi]
		mov		dword ptr [esi],0
		add		esi,4
		dec		fn.nCount
	.endw
	.if fn.hThread
		invoke CloseHandle,fn.hThread
		mov		fn.hThread,0
	.endif
	ret

CloseNotify endp

SetNotify proc uses esi
	LOCAL	ThreadID:DWORD

	invoke CloseNotify
	xor		eax,eax
	mov		esi,fn.lpPath
	.while [esi].FILENOTIFYPATH.path
		.if [esi].FILENOTIFYPATH.nCount
			inc		eax
		.endif
		add		esi,sizeof FILENOTIFYPATH
	.endw
	.if eax
		invoke CreateThread,NULL,NULL,addr ThreadProc,0,NORMAL_PRIORITY_CLASS,addr ThreadID
		mov		fn.hThread,eax
	.endif
	ret

SetNotify endp

AddPath proc uses esi edi,lpFileName:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke lstrcpy,addr buffer,lpFileName
	invoke lstrlen,addr buffer
	.while eax
		.if byte ptr buffer[eax]=='\'
			mov		byte ptr buffer[eax],0
			.break
		.endif
		dec		eax
	.endw
	invoke GetFileAttributes,addr buffer
	.if eax!=INVALID_HANDLE_VALUE
		xor		edi,edi
		mov		esi,fn.lpPath
		.while [esi].FILENOTIFYPATH.path
			.if [esi].FILENOTIFYPATH.nCount
				invoke lstrcmp,addr [esi].FILENOTIFYPATH.path,addr buffer
				or		eax,eax
				je		Found
			.elseif !edi
				mov		edi,esi
			.endif
			add		esi,sizeof FILENOTIFYPATH
		.endw
		.if edi
			mov		esi,edi
		.endif
		invoke lstrcpy,addr [esi].FILENOTIFYPATH.path,addr buffer
	  Found:
		inc		[esi].FILENOTIFYPATH.nCount
		.if [esi].FILENOTIFYPATH.nCount==1
			invoke SetNotify
		.endif
	.endif
	ret

AddPath endp

DelPath proc uses esi,lpFileName:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke lstrcpy,addr buffer,lpFileName
	invoke lstrlen,addr buffer
	.while eax
		.if byte ptr buffer[eax]=='\'
			mov		byte ptr buffer[eax],0
			.break
		.endif
		dec		eax
	.endw
	invoke GetFileAttributes,addr buffer
	.if eax!=INVALID_HANDLE_VALUE
		mov		esi,fn.lpPath
		.while [esi].FILENOTIFYPATH.path
			.if [esi].FILENOTIFYPATH.nCount
				invoke lstrcmp,addr [esi].FILENOTIFYPATH.path,addr buffer
				or		eax,eax
				je		Found
			.endif
			add		esi,sizeof FILENOTIFYPATH
		.endw
	.endif
	ret
  Found:
	dec		[esi].FILENOTIFYPATH.nCount
	.if ![esi].FILENOTIFYPATH.nCount
		invoke SetNotify
	.endif
	ret

DelPath endp

TabToolGetMem proc uses ebx,hWin:DWORD
	LOCAL	nInx:DWORD
	LOCAL	tci:TC_ITEM

	mov		nInx,-1
	mov		tci.imask,TCIF_PARAM
	mov		eax,TRUE
	.while eax
		inc		nInx
		invoke SendMessage,hTab,TCM_GETITEM,nInx,addr tci
		.if eax
			mov		ebx,tci.lParam
			mov		eax,[ebx].TABMEM.hwnd
			.break .if eax==hWin
		.endif
	.endw
	mov		eax,ebx
	ret

TabToolGetMem endp

TabToolGetInx proc uses ebx,hWin:DWORD
	LOCAL	nInx:DWORD
	LOCAL	tci:TC_ITEM

	mov		nInx,-1
	mov		tci.imask,TCIF_PARAM
	mov		eax,TRUE
	.while eax
		inc		nInx
		invoke SendMessage,hTab,TCM_GETITEM,nInx,addr tci
		.if eax
			mov		ebx,tci.lParam
			mov		eax,[ebx].TABMEM.hwnd
			.break .if eax==hWin
		.endif
	.endw
	mov		eax,nInx
	ret

TabToolGetInx endp

TabToolSetText proc nInx:DWORD,lpFileName:DWORD
	LOCAL	tci:TC_ITEM

	mov		tci.imask,TCIF_PARAM
	invoke SendMessage,hTab,TCM_GETITEM,nInx,addr tci
	mov		eax,tci.lParam
	invoke lstrcpy,addr [eax].TABMEM.filename,lpFileName
	invoke lstrlen,lpFileName
	mov		ecx,eax
	mov		edx,lpFileName
	.while ecx
		mov		al,[edx+ecx-1]
		.break .if al=='\'
		dec		ecx
	.endw
	lea		eax,[edx+ecx]
	mov		tci.pszText,eax
	mov		tci.imask,TCIF_TEXT
	invoke SendMessage,hTab,TCM_SETITEM,nInx,addr tci
	ret

TabToolSetText endp

TabToolSetChanged proc uses ebx,hWin:DWORD,fChanged:DWORD
	LOCAL	nInx:DWORD
	LOCAL	tci:TC_ITEM
	LOCAL buffer[256]:BYTE

	mov		nInx,-1
	mov		tci.imask,TCIF_PARAM or TCIF_TEXT
	lea		eax,buffer
	mov		tci.pszText,eax
	mov		tci.cchTextMax,sizeof buffer
	mov		eax,TRUE
	.while eax
		inc		nInx
		invoke SendMessage,hTab,TCM_GETITEM,nInx,addr tci
		.if eax
			mov		ebx,tci.lParam
			mov		eax,[ebx].TABMEM.hwnd
			.break .if eax==hWin
		.endif
	.endw
	invoke lstrlen,addr buffer
	.if fChanged
		.if buffer[eax-1]!='*'
			mov		word ptr buffer[eax],'*'
		.endif
		mov		[ebx].TABMEM.fchanged,TRUE
	.else
		.if buffer[eax-1]=='*'
			mov		byte ptr buffer[eax-1],0
		.endif
		mov		[ebx].TABMEM.fchanged,FALSE
	.endif
	mov		tci.imask,TCIF_TEXT
	invoke SendMessage,hTab,TCM_SETITEM,nInx,addr tci
	mov		eax,nInx
	ret

TabToolSetChanged endp

TabToolActivate proc uses ebx
	LOCAL	tci:TC_ITEM

	invoke SendMessage,hTab,TCM_GETCURSEL,0,0
	mov		tci.imask,TCIF_PARAM
	mov		edx,eax
	invoke SendMessage,hTab,TCM_GETITEM,edx,addr tci
	push	hREd
	mov		ebx,tci.lParam
	mov		eax,[ebx].TABMEM.hwnd
	mov		hREd,eax
	invoke lstrcpy,offset FileName,addr [ebx].TABMEM.filename
	invoke SetWinCaption,offset FileName
	invoke SendMessage,hWnd,WM_SIZE,0,0
	invoke ShowWindow,hREd,SW_SHOW
	mov		fTimer,1
	pop		eax
	.if eax!=hREd
		invoke ShowWindow,eax,SW_HIDE
	.endif
	invoke SendMessage,hBrowse,FBM_SETSELECTED,0,addr [ebx].TABMEM.filename
	ret

TabToolActivate endp

TabToolAdd proc uses ebx,hWin:HWND,lpFileName:DWORD
	LOCAL	tci:TC_ITEM
	LOCAL	ThreadID:DWORD
	LOCAL	msg:MSG
	LOCAL	buffer[32]:BYTE

	invoke GetProcessHeap
	invoke HeapAlloc,eax,HEAP_ZERO_MEMORY,sizeof TABMEM
	mov		ebx,eax
	mov		eax,hWin
	mov		[ebx].TABMEM.hwnd,eax
	invoke lstrcpy,addr [ebx].TABMEM.filename,lpFileName
	invoke lstrlen,lpFileName
	mov		ecx,eax
	mov		edx,lpFileName
	.while ecx
		mov		al,[edx+ecx-1]
		.break .if al=='\'
		dec		ecx
	.endw
	mov		tci.imask,TCIF_TEXT or TCIF_PARAM or TCIF_IMAGE
	lea		eax,[edx+ecx]
	mov		tci.pszText,eax
	mov		tci.cchTextMax,20
	invoke lstrlen,lpFileName
	add		eax,lpFileName
	sub		eax,4
	mov		eax,[eax]
	mov		dword ptr buffer,eax
	mov		byte ptr buffer[5],0
	invoke CharUpper,addr buffer
	mov		eax,dword ptr buffer
	mov		edx,5
	.if eax=='MSA.'
		mov		edx,2
	.elseif eax=='CNI.'
		mov		edx,3
	.else
		shr		eax,8
		.if eax=='CR.'
			mov		edx,4
		.endif
	.endif
	mov		tci.iImage,edx
	mov		tci.lParam,ebx
	invoke SendMessage,hTab,TCM_INSERTITEM,999,addr tci
	invoke SendMessage,hTab,TCM_SETCURSEL,eax,0
	invoke UpdateFileTime,ebx
	invoke AddPath,lpFileName
	invoke SendMessage,hBrowse,FBM_SETSELECTED,0,lpFileName
	invoke SetWindowLong,hWin,GWL_USERDATA,ebx
	ret

TabToolAdd endp

TabToolDel proc uses ebx,hWin:HWND
	LOCAL	nInx:DWORD
	LOCAL	tci:TC_ITEM

	mov		nInx,-1
	mov		tci.imask,TCIF_PARAM
	mov		eax,TRUE
	.while eax
		inc		nInx
		invoke SendMessage,hTab,TCM_GETITEM,nInx,addr tci
		.if eax
			mov		ebx,tci.lParam
			mov		eax,[ebx].TABMEM.hwnd
			.if eax==hWin
				invoke DelPath,addr [ebx].TABMEM.filename
				invoke SendMessage,hTab,TCM_DELETEITEM,nInx,0
				invoke GetProcessHeap
				invoke HeapFree,eax,NULL,ebx
				xor eax,eax
			.endif
		.endif
	.endw
	invoke SendMessage,hTab,TCM_GETITEMCOUNT,0,0
	.if eax
	  @@:
		invoke SendMessage,hTab,TCM_SETCURSEL,nInx,0
		invoke SendMessage,hTab,TCM_GETCURSEL,0,0
		.if eax==-1
			dec		nInx
			jmp		@b
		.endif
		invoke TabToolActivate
		invoke SetFocus,hREd
	.else
		mov		hREd,0
		invoke SendMessage,hWnd,WM_SIZE,0,0
	.endif
	ret

TabToolDel endp

TabProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ht:TC_HITTESTINFO
	LOCAL	tci:TC_ITEM
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==WM_RBUTTONDOWN
		mov		eax,lParam
		movzx	edx,ax
		shr		eax,16
		mov		ht.pt.x,edx
		mov		ht.pt.y,eax
		invoke SendMessage,hWin,TCM_HITTEST,0,addr ht
		.if eax!=-1
			invoke SendMessage,hWin,TCM_SETCURSEL,eax,0
			invoke TabToolActivate
			invoke SetFocus,hREd
			xor		eax,eax
			ret
		.endif
	.elseif eax==WM_MBUTTONDOWN
		mov		eax,lParam
		movzx	edx,ax
		shr		eax,16
		mov		ht.pt.x,edx
		mov		ht.pt.y,eax
		invoke SendMessage,hWin,TCM_HITTEST,0,addr ht
		.if eax!=-1
			mov		tabinx,eax
			invoke SendMessage,hWin,TCM_SETCURSEL,eax,0
			invoke TabToolActivate
			invoke SetFocus,hREd
			xor		eax,eax
			ret
		.endif
	.elseif eax==WM_MBUTTONUP
		mov		eax,lParam
		movzx	edx,ax
		shr		eax,16
		mov		ht.pt.x,edx
		mov		ht.pt.y,eax
		invoke SendMessage,hWin,TCM_HITTEST,0,addr ht
		.if eax==tabinx
			invoke SendMessage,hWnd,WM_COMMAND,IDM_FILE_CLOSE,0
		.endif
		mov		tabinx,-2
		xor		eax,eax
		ret
	.elseif eax==WM_LBUTTONDOWN
		mov		eax,lParam
		movzx	edx,ax
		shr		eax,16
		mov		ht.pt.x,edx
		mov		ht.pt.y,eax
		invoke SendMessage,hWin,TCM_HITTEST,0,addr ht
		.if eax!=-1
			mov		tabinx,eax
			invoke SendMessage,hWin,TCM_SETCURSEL,eax,0
			invoke TabToolActivate
			invoke SetFocus,hREd
			xor		eax,eax
			ret
		.endif
	.elseif eax==WM_MOUSEMOVE
		test	wParam,MK_LBUTTON
		.if !ZERO?
			mov		eax,lParam
			movzx	edx,ax
			shr		eax,16
			mov		ht.pt.x,edx
			mov		ht.pt.y,eax
			invoke SendMessage,hWin,TCM_HITTEST,0,addr ht
			.if eax!=tabinx && sdword ptr eax>=0 && sdword ptr tabinx>=0
				push	eax
				mov		tci.imask,TCIF_TEXT Or TCIF_IMAGE Or TCIF_PARAM
				lea		eax,buffer
				mov		tci.pszText,eax
				mov		tci.cchTextMax,MAX_PATH
				invoke SendMessage,hWin,TCM_GETITEM,tabinx,addr tci
				invoke SendMessage,hWin,TCM_DELETEITEM,tabinx,0
				pop		tabinx
				invoke SendMessage,hWin,TCM_INSERTITEM,tabinx,addr tci
			.endif
			xor		eax,eax
			ret
		.endif
	.endif
	invoke CallWindowProc,lpOldTabProc,hWin,uMsg,wParam,lParam
	ret

TabProc endp
