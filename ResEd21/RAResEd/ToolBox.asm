NoOfButtons		equ	33
ButtonSize		equ	26

.data

nButtons			dd NoOfButtons
szToolBoxTlt		db 'Pointer,EditText,Static,GroupBox,Button,CheckBox,RadioButton,ComboBox,ListBox,HScroll,VScroll,TabStrip,ProgressBar,TreeView,'
					db 'ListView,TrackBar,UpDown,Image,ToolBar,StatusBar,DatePicker,MonthView,RichEdit,UserDefinedControl,ImageCombo,Shape,IPAddress,Animate,HotKey,HPager,VPager,ReBar,Header',0
					db 512 dup(?)
.data?

hButtons			dd NoOfButtons+32 dup(?)
OldToolBoxBtnProc	dd ?
hToolTip			dd ?
hBoxIml				dd ?
ToolBoxID			dd ?

.code

ToolBoxReset proc uses ecx edi

	mov		ecx,nButtons
	dec		ecx
	mov		edi,offset hButtons+4
  @@:
	push	ecx
	push	edi
	mov		eax,[edi]
	invoke SendMessage,eax,BM_SETCHECK,BST_UNCHECKED,0
	pop		edi
	add		edi,4
	pop		ecx
	loop	@b
	invoke SendMessage,hButtons[0],BM_SETCHECK,BST_CHECKED,0
	mov		ToolBoxID,0
	ret

ToolBoxReset endp

ToolBoxSize	proc uses ecx esi,lParam:LPARAM
	LOCAL	wt:DWORD
	LOCAL	xP:DWORD
	LOCAL	yP:DWORD
	LOCAL	hBtn:DWORD

	mov		eax,lParam
	and		eax,0FFFFh
	mov		wt,eax
	mov		xP,0
	mov		yP,0
	mov		ecx,nButtons
	mov		esi,offset hButtons
  @@:
	push	ecx
	push	esi
	mov		eax,dword ptr [esi]
	mov		hBtn,eax
	invoke MoveWindow,hBtn,xP,yP,ButtonSize,ButtonSize,TRUE
	add		xP,ButtonSize
	mov		eax,xP
	add		eax,ButtonSize
	.if	eax>wt
		mov		xP,0
		add		yP,ButtonSize
	.endif
	pop		esi
	pop		ecx
	add		esi,4
	loop	@b
	ret

ToolBoxSize	endp

ToolBoxBtnProc proc	uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if	eax==WM_LBUTTONDOWN
		mov		eax,ToolBoxID
		shl		eax,2
		mov		ebx,offset hButtons
		add		ebx,eax
		invoke SendMessage,[ebx],BM_SETCHECK,BST_UNCHECKED,0
		invoke SendMessage,hWin,BM_SETCHECK,BST_CHECKED,0
		invoke GetWindowLong,hWin,GWL_ID
		mov		ToolBoxID,eax
		invoke GetParent,hWin
		invoke SetFocus,eax
		test	wParam,MK_CONTROL
		.if !ZERO?
			mov		fNoResetToolbox,TRUE
		.else
			mov		fNoResetToolbox,FALSE
		.endif
		xor		eax,eax
		ret
	.elseif eax==WM_MOUSEMOVE
		.if hStatus
			invoke SendMessage,hStatus,SB_SETTEXT,nStatus,offset szNULL
		.endif
	.endif
	invoke CallWindowProc,OldToolBoxBtnProc,hWin,uMsg,wParam,lParam
	ret

ToolBoxBtnProc endp

Do_ToolBoxButton proc hWin:HWND,CtlID:DWORD,hIml:DWORD
	LOCAL	hBtn:DWORD
	LOCAL	ti:TOOLINFO
	LOCAL	buffer[64]:BYTE

	invoke CreateWindowEx,0,addr szButtonClass,0,
			WS_VISIBLE or WS_CHILD or WS_CLIPCHILDREN or WS_CLIPSIBLINGS or	BS_PUSHLIKE	or BS_AUTORADIOBUTTON or BS_ICON,
			0,0,0,0,hWin,CtlID,hInstance,NULL
	mov		hBtn,eax
	mov		ecx,CtlID
	mov		hButtons[ecx*4],eax
	invoke ImageList_GetIcon,hIml,CtlID,ILD_NORMAL
	invoke SendMessage,hBtn,BM_SETIMAGE,IMAGE_ICON,eax
	invoke SetWindowLong,hBtn,GWL_WNDPROC,offset ToolBoxBtnProc
	mov		OldToolBoxBtnProc,eax
	invoke GetStrItem,addr szToolBoxTlt,addr buffer
	mov		ti.cbSize,sizeof TOOLINFO
	mov		ti.uFlags,TTF_IDISHWND or TTF_SUBCLASS
	mov		ti.hWnd,0
	mov		eax,hBtn
	mov		ti.uId,eax
	mov		ti.hInst,0
	lea		eax,buffer
	mov		ti.lpszText,eax
	invoke SendMessage,hToolTip,TTM_ADDTOOL,NULL,addr ti
	mov		eax,hBtn
	ret

Do_ToolBoxButton endp

AddCustomControl proc uses ebx esi edi,lpszDLL:DWORD
	LOCAL	mDC:HDC
	LOCAL	nColor:DWORD
	LOCAL	rect:RECT
	LOCAL	fEx:DWORD
	LOCAL	buffer[64]:BYTE
	LOCAL	lpszMask:DWORD

	mov		lpszMask,0
	mov		eax,lpszDLL
	.while byte ptr [eax]
		.if byte ptr [eax]==','
			mov		byte ptr [eax],0
			inc		eax
			mov		lpszMask,eax
			.break
		.endif
		inc		eax
	.endw
	invoke LoadLibrary,lpszDLL
	.if eax
		push	eax
		mov		ebx,eax
		invoke GetProcAddress,ebx,offset szGetDefEx
		mov		fEx,eax
		.if !eax
			invoke GetProcAddress,ebx,offset szGetDef
		.endif
		.if eax
			mov		ebx,eax
			xor		esi,esi
			.while eax
				push	edi
				mov		edi,esp
				push	esi
				call	ebx
				mov		esp,edi
				pop		edi
				.if eax
					call	InstallDLL
					xor		eax,eax
					inc		eax
				.endif
				inc		esi
			.endw
		.endif
		invoke GetClientRect,hTlb,addr rect
		mov		eax,rect.bottom
		shl		eax,16
		add		eax,rect.right
		invoke ToolBoxSize,eax
		pop		eax
	.endif
	ret

InstallDLL:
	push	ebx
	mov		edi,eax
	mov		ebx,offset ctltypes
	mov		eax,nButtons
	mov		ecx,sizeof TYPES
	mul		ecx
	lea		ebx,[ebx+eax]
	mov		eax,[edi].CCDEF.ID
	mov		[ebx].TYPES.ID,eax
	mov		eax,[edi].CCDEF.lpcaption
	mov		[ebx].TYPES.lpcaption,eax
	mov		eax,[edi].CCDEF.lpname
	mov		[ebx].TYPES.lpidname,eax
	mov		eax,[edi].CCDEF.lpclass
	mov		[ebx].TYPES.lpclass,eax
	mov		eax,[edi].CCDEF.style
	mov		[ebx].TYPES.style,eax
	mov		[ebx].TYPES.typemask,0
	mov		eax,[edi].CCDEF.exstyle
	mov		[ebx].TYPES.exstyle,eax
	mov		[ebx].TYPES.xsize,82
	mov		[ebx].TYPES.ysize,82
	mov		eax,[edi].CCDEF.flist1
	mov		[ebx].TYPES.flist,eax
	mov		eax,[edi].CCDEF.flist2
	mov		[ebx].TYPES.flist[4],eax
	.if fEx
		mov		eax,[edi].CCDEFEX.flist3
		mov		[ebx].TYPES.flist[8],eax
		mov		eax,[edi].CCDEFEX.flist4
		mov		[ebx].TYPES.flist[12],eax
		mov		eax,[edi].CCDEFEX.lpmethod
		.if eax
			mov		edx,nPr
			mov		[ebx].TYPES.nmethod,edx
			mov		[ebx].TYPES.methods,eax
		.endif
		mov		edx,[edi].CCDEFEX.lpproperty
		.while byte ptr [edx]
			push	edx
			mov		buffer,','
			invoke GetStrItem,edx,addr buffer[1]
			invoke strcat,offset PrAll,addr buffer
			mov		ecx,nPr
			inc		nPr
			mov		eax,80000000h
			.if ecx>=128
			.elseif ecx>=96
				sub		ecx,96
				shr		eax,cl
				or		[ebx].TYPES.flist[12],eax
			.elseif ecx>=64
				sub		ecx,64
				shr		eax,cl
				or		[ebx].TYPES.flist[8],eax
			.elseif ecx>=32
				sub		ecx,32
				shr		eax,cl
				or		[ebx].TYPES.flist[4],eax
			.else
				shr		eax,cl
				or		[ebx].TYPES.flist[0],eax
			.endif
			pop		edx
		.endw
	.endif
	mov		[ebx].TYPES.lprc,offset szCONTROL
	mov		ebx,[edi].CCDEF.hbmp
	.if !ebx
		invoke LoadBitmap,hInstance,IDB_CUSTCTL
	.endif
	invoke CreateCompatibleDC,NULL
	mov		mDC,eax
	invoke SelectObject,mDC,ebx
	push	eax
	invoke GetPixel,mDC,0,0
	mov		nColor,eax
	pop		eax
	invoke SelectObject,mDC,eax
	invoke DeleteDC,mDC
	invoke ImageList_AddMasked,hBoxIml,ebx,nColor  ; background colour
	invoke DeleteObject,ebx
	invoke strcat,offset szCtlText,offset szComma
	invoke strcat,offset szCtlText,[edi].CCDEF.lptooltip
	invoke strcpy,offset szToolBoxTlt,[edi].CCDEF.lptooltip
	invoke Do_ToolBoxButton,hTlb,nButtons,hBoxIml
	inc		nButtons
	pop		ebx
	retn

AddCustomControl endp

Do_ToolBox proc	hWin:HWND

	invoke ResEdDo_ImageList,hInstance,IDB_TOOLBOX,20,32,0,0C0C0C0h,0
	mov		hBoxIml,eax
	invoke CreateWindowEx,NULL,addr	szToolTipsClass,NULL,\
		   TTS_ALWAYSTIP,CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
		   NULL,NULL,hInstance,NULL
	mov		hToolTip,eax
	xor		ecx,ecx
	.while ecx<nButtons
		push	ecx
		invoke Do_ToolBoxButton,hWin,ecx,hBoxIml
		pop		ecx
		inc		ecx
	.endw
	invoke ToolBoxReset
	ret

Do_ToolBox endp

