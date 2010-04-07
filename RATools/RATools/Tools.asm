
ToolCldWndProc			PROTO :DWORD,:DWORD,:DWORD,:DWORD

.code

Do_ToolFloat proc uses esi,lpTool:DWORD
	LOCAL   tW:DWORD
	LOCAL   tH:DWORD

	mov     esi,lpTool
	mov     eax,[esi].TOOL.dck.fr.right
	sub     eax,[esi].TOOL.dck.fr.left
	mov     tW,eax
	mov     eax,[esi].TOOL.dck.fr.bottom
	sub     eax,[esi].TOOL.dck.fr.top
	mov     tH,eax
	invoke CreateWindowEx,WS_EX_TOOLWINDOW,addr szToolClass,[esi].TOOL.dck.Caption,
			WS_CAPTION or WS_SIZEBOX or WS_SYSMENU or WS_POPUP or WS_CLIPCHILDREN or WS_CLIPSIBLINGS,
			[esi].TOOL.dck.fr.left,[esi].TOOL.dck.fr.top,tW,tH,hWnd,0,hInstance,esi
	mov     [esi].TOOL.hWin,eax
	ret

Do_ToolFloat endp

ToolDrawRect proc uses esi edi,lpRect:DWORD,nFun:DWORD,nInx:DWORD
	LOCAL	ht:DWORD
	LOCAL	wt:DWORD
	LOCAL	rect:RECT

	invoke CopyRect,addr rect,lpRect
	lea		esi,rect
	sub		[esi].RECT.right,1
	mov		eax,[esi].RECT.right
	sub		eax,[esi].RECT.left
	jns		@f
	mov		eax,[esi].RECT.right
	xchg	eax,[esi].RECT.left
	mov		[esi].RECT.right,eax
	sub		eax,[esi].RECT.left
	dec		[esi].RECT.left
	inc		[esi].RECT.right
	inc		eax
  @@:
	mov		wt,eax
	sub		[esi].RECT.bottom,1
	mov		eax,[esi].RECT.bottom
	sub		eax,[esi].RECT.top
	jns		@f
	mov		eax,[esi].RECT.bottom
	xchg	eax,[esi].RECT.top
	mov		[esi].RECT.bottom,eax
	sub		eax,[esi].RECT.top
	dec		[esi].RECT.top
	inc		[esi].RECT.bottom
	inc		eax
  @@:
	mov		ht,eax
	dec		[esi].RECT.right
	dec		[esi].RECT.bottom
	mov		edi,nInx
	shl		edi,4
	add		edi,offset hRect
	.if nFun==0
		invoke CreateWindowEx,0,addr szStatic,0,WS_POPUP or SS_BLACKRECT,[esi].RECT.left,[esi].RECT.top,wt,2,hWnd,0,hInstance,0
		mov		[edi],eax
		invoke ShowWindow,eax,SW_SHOWNOACTIVATE
		invoke CreateWindowEx,0,addr szStatic,0,WS_POPUP or SS_BLACKRECT,[esi].RECT.right,[esi].RECT.top,2,ht,hWnd,0,hInstance,0
		mov		[edi+4],eax
		invoke ShowWindow,eax,SW_SHOWNOACTIVATE
		invoke CreateWindowEx,0,addr szStatic,0,WS_POPUP or SS_BLACKRECT,[esi].RECT.left,[esi].RECT.bottom,wt,2,hWnd,0,hInstance,0
		mov		[edi+8],eax
		invoke ShowWindow,eax,SW_SHOWNOACTIVATE
		invoke CreateWindowEx,0,addr szStatic,0,WS_POPUP or SS_BLACKRECT,[esi].RECT.left,[esi].RECT.top,2,ht,hWnd,0,hInstance,0
		mov		[edi+12],eax
		invoke ShowWindow,eax,SW_SHOWNOACTIVATE
	.elseif nFun==1
		invoke MoveWindow,[edi],[esi].RECT.left,[esi].RECT.top,wt,3,TRUE
		invoke MoveWindow,[edi+4],[esi].RECT.right,[esi].RECT.top,3,ht,TRUE
		invoke MoveWindow,[edi+8],[esi].RECT.left,[esi].RECT.bottom,wt,3,TRUE
		invoke MoveWindow,[edi+12],[esi].RECT.left,[esi].RECT.top,3,ht,TRUE
	.elseif nFun==2
		invoke DestroyWindow,[edi]
		mov		dword ptr [edi],0
		invoke DestroyWindow,[edi+4]
		mov		dword ptr [edi+4],0
		invoke DestroyWindow,[edi+8]
		mov		dword ptr [edi+8],0
		invoke DestroyWindow,[edi+12]
		mov		dword ptr [edi+12],0
	.endif
	ret

ToolDrawRect endp

Rotate proc uses esi edi,hBmpDest:DWORD,hBmpSrc:DWORD,x:DWORD,y:DWORD,nRotate:DWORD
	LOCAL	bmd:BITMAP
	LOCAL	nbitsd:DWORD
	LOCAL	hmemd:DWORD
	LOCAL	bms:BITMAP
	LOCAL	nbitss:DWORD
	LOCAL	hmems:DWORD

	;Get info on destination bitmap
	invoke GetObject,hBmpDest,sizeof BITMAP,addr bmd
	mov		eax,bmd.bmWidthBytes
	mov		edx,bmd.bmHeight
	mul		edx
	mov		nbitsd,eax
	;Allocate memory for destination bitmap bits
	invoke GlobalAlloc,GMEM_FIXED,nbitsd
	mov		hmemd,eax
	;Get the destination bitmap bits
	invoke GetBitmapBits,hBmpDest,nbitsd,hmemd
	;Get info on source bitmap
	invoke GetObject,hBmpSrc,sizeof BITMAP,addr bms
	mov		eax,bms.bmWidthBytes
	mov		edx,bms.bmHeight
	mul		edx
	mov		nbitss,eax
	;Allocate memory for source bitmap bits
	invoke GlobalAlloc,GMEM_FIXED,nbitss
	mov		hmems,eax
	;Get the source bitmap bits
	invoke GetBitmapBits,hBmpSrc,nbitss,hmems
	;Copy the pixels one by one
	xor		edx,edx
	.while edx<bms.bmHeight
		xor		ecx,ecx
		.while ecx<bms.bmWidth
			call	CopyPix
			inc		ecx
		.endw
		inc		edx
	.endw
	;Copy back the destination bitmap bits
	invoke SetBitmapBits,hBmpDest,nbitsd,hmemd
	;Free allocated memory
	invoke GlobalFree,hmems
	invoke GlobalFree,hmemd
	ret

CopyPix:
	push	ecx
	push	edx
	mov		esi,hmems
	push	edx
	mov		eax,bms.bmWidthBytes
	mul		edx
	add		esi,eax
	movzx	eax,bms.bmBitsPixel
	shr		eax,3
	mul		ecx
	add		esi,eax
	pop		edx
	mov		eax,nRotate
	.if eax==1
		;Rotate 90 degrees
		sub		edx,bms.bmHeight
		neg		edx
		xchg	ecx,edx
	.elseif eax==2
		;Rotate 180 degrees
		sub		edx,bms.bmHeight
		neg		edx
		sub		ecx,bms.bmWidth
		neg		ecx
	.elseif eax==3
		;Rotate 270 degrees
		sub		ecx,bms.bmWidth
		neg		ecx
		xchg	ecx,edx
	.endif
	;Add the destination offsets
	add		ecx,x
	add		edx,y
	.if  ecx<bmd.bmWidth && edx<bmd.bmHeight
		;Calculate destination adress
		mov		edi,hmemd
		mov		eax,bmd.bmWidthBytes
		mul		edx
		add		edi,eax
		movzx	eax,bmd.bmBitsPixel
		shr		eax,3
		xchg	eax,ecx
		mul		ecx
		add		edi,eax
		;And copy the byte(s)
		rep movsb
	.endif
	pop		edx
	pop		ecx
	retn

Rotate endp

GetToolPtr proc

	mov     edx,offset ToolPool-sizeof TOOLPOOL
  @@:
	add     edx,sizeof TOOLPOOL
	cmp     [edx].TOOLPOOL.hCld,0
	jz      @f
	cmp     eax,[edx].TOOLPOOL.hCld
	jnz     @b
	mov     edx,[edx].TOOLPOOL.lpTool
	ret
  @@:
	xor     edx,edx
	ret

GetToolPtr endp

ToolHitTest proc uses ebx,lpRect:DWORD,lpPoint:DWORD
	
	push    edx
	mov     edx,lpPoint
	mov     ebx,lpRect
	mov     eax,[edx].POINT.x
	mov		edx,[edx].POINT.y
	.if sdword ptr eax>=[ebx].RECT.left && sdword ptr eax<[ebx].RECT.right && sdword ptr edx>=[ebx].RECT.top && sdword ptr edx<[ebx].RECT.bottom
		mov     eax,TRUE
	.else
		xor		eax,eax
	.endif
	pop     edx
	ret

ToolHitTest endp

GetToolPtrID proc

	push	edx
	mov     edx,offset ToolPool-sizeof TOOLPOOL
  @@:
	add     edx,sizeof TOOLPOOL
	cmp     [edx].TOOLPOOL.hCld,0
	je      @f
	push	edx
	mov     edx,dword ptr [edx].TOOLPOOL.lpTool
	cmp     eax,[edx].TOOL.dck.ID
	pop		edx
	jne     @b
	mov     eax,dword ptr [edx].TOOLPOOL.lpTool
	pop		edx
	ret
  @@:
	xor     eax,eax
	pop		edx
	ret

GetToolPtrID endp

IsOnTool proc uses ebx,lpPt:DWORD

	push	ecx
	push	edx
	mov		ebx,lpPt
	mov		edx,offset ToolData
  @@:
	mov		eax,[edx].TOOL.dck.ID
	.if eax
		mov		eax,[edx].TOOL.dck.Visible
		and		eax,[edx].TOOL.dck.Docked
		.if eax
			mov		eax,[edx].TOOL.dck.IsChild
			.if !eax
				mov		eax,[ebx].POINT.x
				.if sdword ptr eax>[edx].TOOL.dr.left && sdword ptr eax<[edx].TOOL.dr.right
					mov		eax,[ebx].POINT.y
					.if sdword ptr eax>[edx].TOOL.dr.top && sdword ptr eax<[edx].TOOL.dr.bottom
						mov		eax,[edx].TOOL.dck.ID
						jmp		@f
					.endif
				.endif
			.endif
		.endif
		add		edx,sizeof TOOL
		jmp		@b
	.endif
  @@:
	pop		edx
	pop		ecx
	ret

IsOnTool endp

SetIsChildTo proc nID:DWORD,nToID:DWORD

	push	edx
	mov		edx,offset ToolData
  @@:
	mov		eax,[edx].TOOL.dck.ID
	.if eax
		mov		eax,[edx].TOOL.dck.IsChild
		.if eax==nID
			mov		eax,nToID
			mov		[edx].TOOL.dck.IsChild,eax
		.endif
		add		edx,sizeof TOOL
		jmp		@b
	.endif
	pop		edx
	ret

SetIsChildTo endp

ToolMsg proc uses ebx esi,hCld:DWORD,uMsg:UINT,lpRect:DWORD
	LOCAL   rect:RECT
	LOCAL   dWidth:DWORD
	LOCAL   dHeight:DWORD
	LOCAL   hWin:HWND
	LOCAL   hDC:HDC
	LOCAL   hCur:DWORD
	LOCAL   parPosition:DWORD
	LOCAL	pardWidth:DWORD
	LOCAL	pardHeight:DWORD
	LOCAL	parDocked:DWORD
	LOCAL	pt:POINT
	LOCAL	rect2:RECT
	LOCAL	sDC:HDC
	LOCAL	hBmp1:DWORD
	LOCAL	hBmp2:DWORD

	mov     eax,hCld
	call    GetToolPtr
	mov		esi,edx
	mov     ebx,lpRect
	mov		eax,uMsg
	.if eax==TLM_MOUSEMOVE
		mov     [esi].TOOL.dCurFlag,0
		mov     hCur,0
		.if [esi].TOOL.dck.Visible && [esi].TOOL.dck.Docked && !ToolResize
			;Check if mouse is on this tools caption, close button or sizeing boarder and set cursor
			mov     hCur,0
			invoke ToolHitTest,addr [esi].TOOL.rr,ebx
			.if eax
				;Cursor on resize bar
				mov     [esi].TOOL.dCurFlag,TL_ONRESIZE
				mov     eax,[esi].TOOL.dck.Position
				.if eax==TL_TOP || eax==TL_BOTTOM
					mov		eax,hSplitCurH
					mov     hCur,eax
				.else
					mov		eax,hSplitCurV
					mov     hCur,eax
				.endif
			.else
				invoke ToolHitTest,addr [esi].TOOL.cr,ebx
				.if eax
					;Cursor on caption
					mov     hCur,IDC_HAND
					mov     [esi].TOOL.dCurFlag,TL_ONCAPTION
					invoke ToolHitTest,addr [esi].TOOL.br,ebx
					.if eax
						;Cursor on close button
						mov     hCur,IDC_ARROW
						mov     [esi].TOOL.dCurFlag,TL_ONCLOSE
					.endif
					invoke LoadCursor,0,hCur
					mov		hCur,eax
				.endif
			.endif
			mov     eax,hCur
			.if eax
				mov     MoveCur,eax
				invoke SetCursor,eax
				mov     eax,TRUE
				ret
			.endif
		.endif
	.elseif eax==TLM_MOVETEST
		call ToolMov
	.elseif eax==TLM_SETTBR
		mov		eax,[esi].TOOL.dck.ID
		.if eax==1
;			mov		eax,IDM_VIEW_PROJECTBROWSER
;		.elseif eax==2
;			mov		eax,IDM_VIEW_OUTPUTWINDOW
;		.elseif eax==3
;			mov		eax,IDM_VIEW_TOOLBOX
;		.elseif eax==4
;			mov		eax,IDM_VIEW_PROPERTIES
;		.elseif eax==5
;			mov		eax,0
		.endif
		.if eax
;			invoke SendMessage,hToolBar,TB_CHECKBUTTON,eax,[esi].TOOL.Visible
		.endif
		mov     eax,TRUE
		ret
	.elseif eax==TLM_LBUTTONDOWN
		.if [esi].TOOL.dCurFlag
			.if [esi].TOOL.dCurFlag==TL_ONCLOSE
				mov     [esi].TOOL.dck.Visible,FALSE
				invoke ToolMsg,hCld,TLM_SETTBR,0
				invoke SendMessage,hWnd,WM_SIZE,0,0
				mov     eax,TRUE
				ret
			.else
				invoke SetFocus,hCld
				mov		pt.x,0
				mov		pt.y,0
				invoke ClientToScreen,hWnd,addr pt
				invoke CopyRect,addr DrawRect,addr [esi].TOOL.dr
				mov		eax,pt.x
				dec		eax
				add		DrawRect.left,eax
				inc		eax
				inc		eax
				add		DrawRect.right,eax
				mov		eax,pt.y
				add		DrawRect.top,eax
				inc		eax
				add		DrawRect.bottom,eax
				invoke CopyRect,addr MoveRect,addr DrawRect
				invoke SetCursor,MoveCur
				invoke SetCapture,hWnd
				.if [esi].TOOL.dCurFlag==TL_ONRESIZE
					mov     eax,hCld
					mov     ToolResize,eax
					invoke ShowWindow,hSize,SW_SHOWNOACTIVATE
					mov     eax,TRUE
					ret
				.elseif [esi].TOOL.dCurFlag==TL_ONCAPTION
					mov     eax,hCld
					mov     ToolMove,eax
					invoke ToolDrawRect,addr DrawRect,0,0
					mov     eax,TRUE
					ret
				.endif
			.endif
		.endif
	.elseif eax==TLM_LBUTTONUP
		invoke ReleaseCapture
		.if ToolResize
			mov     edx,[esi].TOOL.dck.Position
			.if edx==TL_BOTTOM || edx==TL_TOP
				mov     eax,DrawRect.bottom
				sub     eax,DrawRect.top
				sub		eax,1
				mov     [esi].TOOL.dck.dHeight,eax
			.elseif edx==TL_LEFT || edx==TL_RIGHT
				mov     eax,DrawRect.right
				sub     eax,DrawRect.left
				sub		eax,2
				.if edx==TL_RIGHT
					dec		eax
				.endif
				mov     [esi].TOOL.dck.dWidth,eax
			.endif
			invoke ShowWindow,hSize,SW_HIDE
		.elseif ToolMove
			invoke ToolDrawRect,addr DrawRect,2,0
			call ToolMov
			.if ![esi].TOOL.dck.Docked
				mov		eax,FloatRect.right
				sub		eax,FloatRect.left
				mov		edx,FloatRect.bottom
				sub		edx,FloatRect.top
				invoke MoveWindow,[esi].TOOL.hWin,FloatRect.left,FloatRect.top,eax,edx,TRUE
			.endif
		.endif
		invoke SendMessage,hWnd,WM_SIZE,0,0
		invoke SetFocus,hCld
	.elseif eax==TLM_DOCKING
		;Docked/floating
		xor     [esi].TOOL.dck.Docked,TRUE
		.if ![esi].TOOL.dck.Visible
			invoke ToolMsg,hCld,TLM_HIDE,lpRect
		.else
			invoke SendMessage,hWnd,WM_SIZE,0,0
		.endif
		mov     eax,TRUE
		ret
	.elseif eax==TLM_HIDE
		;Hide/show
		xor     [esi].TOOL.dck.Visible,TRUE
		invoke ToolMsg,hCld,TLM_SETTBR,0
		invoke SendMessage,hWnd,WM_SIZE,0,0
		invoke InvalidateRect,hClient,NULL,TRUE
		mov     eax,TRUE
		ret
	.elseif eax==TLM_CAPTION
		;Draw the tools caption
		.if [esi].TOOL.dck.Visible && [esi].TOOL.dck.Docked
			;Draw caption background
			invoke GetDC,hWnd
			mov     hDC,eax
			invoke GetStockObject,DEFAULT_GUI_FONT
			invoke SelectObject,hDC,eax
			push	eax
			invoke FillRect,hDC,addr [esi].TOOL.tr,COLOR_BTNFACE+1
			invoke SetBkMode,hDC,TRANSPARENT
			;Draw resizing bar
			invoke FillRect,hDC,addr [esi].TOOL.rr,COLOR_BTNFACE+1
			;Draw Caption
			.if [esi].TOOL.dFocus
				invoke SetTextColor,hDC,0FFFFFFh
				mov		eax,COLOR_ACTIVECAPTION+1
			.else
				invoke SetTextColor,hDC,0C0C0C0h
				mov		eax,COLOR_INACTIVECAPTION+1
			.endif
			mov		ebx,eax
			invoke FillRect,hDC,addr [esi].TOOL.cr,eax
			mov		eax,[esi].TOOL.dck.IsChild
			xor		ecx,ecx
			.if eax
				invoke GetToolPtrID
				mov		edx,eax
				mov		ecx,[edx].TOOL.dck.Visible
				and		ecx,[edx].TOOL.dck.Docked
			.endif
			mov		eax,[esi].TOOL.dck.Position
			.if fRightCaption
				.if ((eax==TL_TOP || eax==TL_BOTTOM) && !ecx) || (eax==TL_RIGHT && ecx)
					mov		eax,[esi].TOOL.dck.Caption
					mov		al,byte ptr [eax]
					.if al
						dec		ebx
						invoke GetSysColor,ebx
						mov		ebx,eax
						;Create a memory DC for the source
						invoke CreateCompatibleDC,hDC
						mov		sDC,eax
						invoke GetTextColor,hDC
						invoke SetTextColor,sDC,eax
						invoke GetStockObject,DEFAULT_GUI_FONT
						invoke SelectObject,sDC,eax
						push	eax
						;Get size of text to draw
						mov		rect2.left,0
						mov		rect2.top,0
						mov		rect2.right,0
						mov		rect2.bottom,0
						invoke DrawText,sDC,[esi].TOOL.dck.Caption,-1,addr rect2,DT_CALCRECT or DT_SINGLELINE or DT_LEFT or DT_TOP
						;Create a bitmap for the rotated text
						invoke CreateCompatibleBitmap,hDC,rect2.bottom,rect2.right
						mov		hBmp1,eax
						;Create a bitmap for the text
						invoke CreateCompatibleBitmap,hDC,rect2.right,rect2.bottom
						mov		hBmp2,eax
						;and select it into source DC
						invoke SelectObject,sDC,hBmp2
						push	eax
						invoke SetBkColor,sDC,ebx
						;Draw the text
						invoke DrawText,sDC,[esi].TOOL.dck.Caption,-1,addr rect2,DT_SINGLELINE or DT_LEFT or DT_TOP
						;Rotate the bitmap
						invoke Rotate,hBmp1,hBmp2,0,0,1
						pop		eax
						invoke SelectObject,sDC,eax
						;Delete created source bitmap
						invoke DeleteObject,eax
						invoke SelectObject,sDC,hBmp1
						push	eax
						;Blit the destination bitmap onto window bitmap
						mov		eax,[esi].TOOL.cr.top
						inc		eax
						mov		edx,[esi].TOOL.cr.left
						dec		edx
						invoke BitBlt,hDC,edx,eax,rect2.bottom,rect2.right,sDC,0,0,SRCCOPY
						pop		eax
						invoke SelectObject,sDC,eax
						;Delete created source bitmap
						invoke DeleteObject,eax
						pop		eax
						invoke SelectObject,sDC,eax
						invoke DeleteDC,sDC
					.endif
				.else
					dec		[esi].TOOL.cr.top
					inc		[esi].TOOL.cr.left
					invoke DrawText,hDC,[esi].TOOL.dck.Caption,-1,addr [esi].TOOL.cr,0
					inc		[esi].TOOL.cr.top
					dec		[esi].TOOL.cr.left
				.endif
			.else
				dec		[esi].TOOL.cr.top
				inc		[esi].TOOL.cr.left
				invoke DrawText,hDC,[esi].TOOL.dck.Caption,-1,addr [esi].TOOL.cr,0
				inc		[esi].TOOL.cr.top
				dec		[esi].TOOL.cr.left
			.endif
			;Draw close button
			invoke DrawFrameControl,hDC,addr [esi].TOOL.br,DFC_CAPTION,DFCS_CAPTIONCLOSE
			invoke ReleaseDC,hWnd,hDC
			pop		eax
			invoke SelectObject,hDC,eax
		.endif
	.elseif eax==TLM_REDRAW
		;Hide/Show floating/docked window
		.if [esi].TOOL.dck.Visible
			.if [esi].TOOL.dck.Docked
				;Hide the floating form
				invoke ShowWindow,[esi].TOOL.hWin,SW_HIDE
				;Make the mdi frame the parent
				invoke SetParent,[esi].TOOL.hCld,hWnd
				mov     eax,[esi].TOOL.wr.right
				sub     eax,[esi].TOOL.wr.left
				mov     dWidth,eax
				mov     eax,[esi].TOOL.wr.bottom
				sub     eax,[esi].TOOL.wr.top
				mov     dHeight,eax
				invoke MoveWindow,[esi].TOOL.hCld,[esi].TOOL.wr.left,[esi].TOOL.wr.top,dWidth,dHeight,TRUE
				invoke ShowWindow,[esi].TOOL.hCld,SW_SHOWNOACTIVATE
			.else
				;Show the floating window
				invoke SetParent,[esi].TOOL.hCld,[esi].TOOL.hWin
				invoke GetClientRect,[esi].TOOL.hWin,addr rect
				invoke MoveWindow,[esi].TOOL.hCld,rect.left,rect.top,rect.right,rect.bottom,FALSE
				invoke ShowWindow,[esi].TOOL.hWin,SW_SHOWNOACTIVATE
				invoke ShowWindow,[esi].TOOL.hCld,SW_SHOWNOACTIVATE
			.endif
		.else
			.if [esi].TOOL.dck.Docked
				;Hide the floating form
				invoke ShowWindow,[esi].TOOL.hWin,SW_HIDE
				;Hide docked window
				invoke ShowWindow,[esi].TOOL.hCld,SW_HIDE
			.else
				;Hide the floating window
				invoke ShowWindow,[esi].TOOL.hCld,SW_HIDE
				invoke ShowWindow,[esi].TOOL.hWin,SW_HIDE
			.endif
		.endif
	.elseif eax==TLM_ADJUSTRECT
		.if [esi].TOOL.dck.Visible && [esi].TOOL.dck.Docked
			mov		parPosition,-1
			mov		parDocked,0
			mov		eax,[esi].TOOL.dck.IsChild
			.if eax
				mov		eax,[esi].TOOL.dck.dWidth
				mov		dWidth,eax
				push	esi
				;Get parent from ID
				mov		eax,[esi].TOOL.dck.IsChild
				invoke GetToolPtrID
				mov		esi,eax
				mov		eax,[esi].TOOL.dck.Position
				mov		parPosition,eax
				mov		eax,[esi].TOOL.dck.dWidth
				mov		pardWidth,eax
				mov		eax,[esi].TOOL.dck.dHeight
				mov		pardHeight,eax
				;Is parent visible & docked
				mov		eax,[esi].TOOL.dck.Visible
				and		eax,[esi].TOOL.dck.Docked
				mov		parDocked,eax
				.if eax
					.if parPosition==TL_LEFT || parPosition==TL_RIGHT
						;Resize the tool's client rect instead
						lea		eax,[esi].TOOL.wr
						mov		lpRect,eax
						pop		eax
						push	eax
						mov		[eax].TOOL.dck.Position,TL_BOTTOM
					.else
						;Resize the tool's client, top, caption & button rect instead
						lea		eax,[esi].TOOL.wr
						mov		lpRect,eax
						mov		eax,dWidth
						.if fRightCaption
							add		[esi].TOOL.wr.right,TOTCAPHT-1
							inc		eax
							sub		[esi].TOOL.cr.left,eax
							sub		[esi].TOOL.tr.left,eax
							sub		[esi].TOOL.cr.right,eax
							sub		[esi].TOOL.tr.right,eax
							sub		[esi].TOOL.br.left,eax
							sub		[esi].TOOL.br.right,eax
						.else
							sub		[esi].TOOL.tr.right,eax
							sub		[esi].TOOL.cr.right,eax
							sub		[esi].TOOL.br.left,eax
							sub		[esi].TOOL.br.right,eax
						.endif
						pop		eax
						push	eax
						mov		[eax].TOOL.dck.Position,TL_RIGHT
					.endif
				.else
					pop		esi
					push	esi
					mov		eax,parPosition
					mov		[esi].TOOL.dck.Position,eax
					.if parPosition==TL_LEFT || parPosition==TL_RIGHT
						mov		eax,pardWidth
						mov		[esi].TOOL.dck.dWidth,eax
					.else
						mov		eax,pardHeight
						mov		[esi].TOOL.dck.dHeight,eax
					.endif
				.endif
				pop		esi
			.endif
			;Resize mdi client & calculate all the tools RECT's
			mov     ebx,lpRect
			invoke CopyRect,addr [esi].TOOL.dr,ebx
			mov     eax,[esi].TOOL.dck.Position
			.if eax==TL_LEFT
				mov     eax,[esi].TOOL.dck.dWidth
				add     [ebx].RECT.left,eax
				add		eax,[esi].TOOL.dr.left
				mov		[esi].TOOL.dr.right,eax
				call SizeRight
				call CaptionTop
			.elseif eax==TL_TOP
				mov		eax,[esi].TOOL.dck.dHeight
				add		[ebx].RECT.top,eax
				add		eax,[esi].TOOL.dr.top
				mov		[esi].TOOL.dr.bottom,eax
				call SizeBottom
				.if fRightCaption
					call CaptionRight
				.else
					call CaptionTop
				.endif
			.elseif eax==TL_RIGHT
				mov     eax,[esi].TOOL.dck.dWidth
				sub     [ebx].RECT.right,eax
				neg		eax
				add		eax,[esi].TOOL.dr.right
;				dec		eax
				mov		[esi].TOOL.dr.left,eax
				call SizeLeft
				.if [esi].TOOL.dck.IsChild && fRightCaption && parDocked
					sub     [ebx].RECT.right,TOTCAPHT
					call CaptionRight
				.else
					.if [esi].TOOL.dck.IsChild && parDocked
						sub     [esi].TOOL.dr.top,TOTCAPHT
						sub     [esi].TOOL.wr.top,TOTCAPHT
						sub     [esi].TOOL.rr.top,TOTCAPHT
					.endif
					call CaptionTop
				.endif
			.elseif eax==TL_BOTTOM
				mov     eax,[esi].TOOL.dck.dHeight
				sub     [ebx].RECT.bottom,eax
				neg		eax
				add		eax,[esi].TOOL.dr.bottom
				mov		[esi].TOOL.dr.top,eax
				call SizeTop
				.if ((parPosition==TL_LEFT || parPosition==TL_RIGHT) && parDocked) || !fRightCaption
					call CaptionTop
				.else
					call CaptionRight
				.endif
			.endif
		.endif
	.elseif eax==TLM_GETVISIBLE
		mov		eax,[esi].TOOL.dck.Visible
		ret
	.elseif eax==TLM_GETDOCKED
		mov		eax,[esi].TOOL.dck.Docked
		ret
	.elseif eax==TLM_GETSTRUCT
		mov		eax,esi
		ret
	.endif
	mov     eax,FALSE
	ret

SizeLeft:
	invoke CopyRect,addr [esi].TOOL.wr,addr [esi].TOOL.dr
	mov		eax,[esi].TOOL.wr.left
	mov		[esi].TOOL.rr.left,eax
	add		eax,RESIZEBAR
	mov		[esi].TOOL.wr.left,eax
	mov		[esi].TOOL.rr.right,eax
	mov		eax,[esi].TOOL.wr.top
	mov		[esi].TOOL.rr.top,eax
	mov		eax,[esi].TOOL.wr.bottom
	mov		[esi].TOOL.rr.bottom,eax
	retn

SizeTop:
	invoke CopyRect,addr [esi].TOOL.wr,addr [esi].TOOL.dr
	mov		eax,[esi].TOOL.wr.left
	mov		[esi].TOOL.rr.left,eax
	mov		eax,[esi].TOOL.wr.right
	mov		[esi].TOOL.rr.right,eax
	mov		eax,[esi].TOOL.wr.top
	mov		[esi].TOOL.rr.top,eax
	add		eax,RESIZEBAR
	mov		[esi].TOOL.wr.top,eax
	mov		[esi].TOOL.rr.bottom,eax
	retn

SizeRight:
	invoke CopyRect,addr [esi].TOOL.wr,addr [esi].TOOL.dr
	mov		eax,[esi].TOOL.wr.right
	mov		[esi].TOOL.rr.right,eax
	sub		eax,RESIZEBAR
	mov		[esi].TOOL.wr.right,eax
	mov		[esi].TOOL.rr.left,eax
	mov		eax,[esi].TOOL.wr.top
	mov		[esi].TOOL.rr.top,eax
	mov		eax,[esi].TOOL.wr.bottom
	mov		[esi].TOOL.rr.bottom,eax
	retn

SizeBottom:
	invoke CopyRect,addr [esi].TOOL.wr,addr [esi].TOOL.dr
	mov		eax,[esi].TOOL.wr.left
	mov		[esi].TOOL.rr.left,eax
	mov		eax,[esi].TOOL.wr.right
	mov		[esi].TOOL.rr.right,eax
	mov		eax,[esi].TOOL.wr.bottom
	mov		[esi].TOOL.rr.bottom,eax
	sub		eax,RESIZEBAR
	mov		[esi].TOOL.wr.bottom,eax
	mov		[esi].TOOL.rr.top,eax
	retn

CaptionTop:
	mov		eax,[esi].TOOL.wr.left
	mov		[esi].TOOL.tr.left,eax
	mov		[esi].TOOL.cr.left,eax
	mov		eax,[esi].TOOL.wr.right
	mov		[esi].TOOL.tr.right,eax
	mov		[esi].TOOL.cr.right,eax
	mov		eax,[esi].TOOL.wr.top
	mov		[esi].TOOL.tr.top,eax
	inc		eax
	mov		[esi].TOOL.cr.top,eax
	add		eax,TOTCAPHT-1
	mov		[esi].TOOL.wr.top,eax
	mov		[esi].TOOL.tr.bottom,eax
	dec		eax
	mov		[esi].TOOL.cr.bottom,eax

	mov		eax,[esi].TOOL.cr.top
	add		eax,BUTTONT
	mov		[esi].TOOL.br.top,eax
	add		eax,BUTTONHT
	mov		[esi].TOOL.br.bottom,eax
	mov		eax,[esi].TOOL.cr.right
	sub		eax,BUTTONR
	mov		[esi].TOOL.br.right,eax
	sub		eax,BUTTONWT
	mov		[esi].TOOL.br.left,eax
	retn

CaptionRight:
	mov		eax,[esi].TOOL.wr.right
	mov		[esi].TOOL.tr.right,eax
	dec		eax
	mov		[esi].TOOL.cr.right,eax
	sub		eax,TOTCAPHT-1
	mov		[esi].TOOL.tr.left,eax
	inc		eax
	mov		[esi].TOOL.cr.left,eax
	mov		[esi].TOOL.wr.right,eax
	mov		eax,[esi].TOOL.wr.top
	mov		[esi].TOOL.tr.top,eax
	mov		[esi].TOOL.cr.top,eax
	mov		eax,[esi].TOOL.wr.bottom
	mov		[esi].TOOL.tr.bottom,eax
	mov		[esi].TOOL.cr.bottom,eax

	mov		eax,[esi].TOOL.cr.right
	sub		eax,BUTTONT
	mov		[esi].TOOL.br.right,eax
	sub		eax,BUTTONHT
	mov		[esi].TOOL.br.left,eax
	mov		eax,[esi].TOOL.cr.bottom
	sub		eax,BUTTONR
	mov		[esi].TOOL.br.bottom,eax
	sub		eax,BUTTONWT
	mov		[esi].TOOL.br.top,eax
	retn

ToolMov:
	invoke IsOnTool,ebx
	.if eax!=0 && eax!=[esi].TOOL.dck.ID
		;If Tool has child
		mov     [esi].TOOL.dck.IsChild,eax
		invoke SetIsChildTo,[esi].TOOL.dck.ID,eax
	.else
		mov     eax,MoveRect.left
		sub     eax,DrawRect.left
		.if sdword ptr eax<50 && sdword ptr eax>-50
			mov     eax,MoveRect.top
			sub     eax,DrawRect.top
			.if sdword ptr eax<50 && sdword ptr eax>-50
				retn
			.endif
		.endif
		invoke GetWindowRect,hWnd,addr rect2
		sub		rect2.left,50
		sub		rect2.top,50
		add		rect2.right,50
		add		rect2.bottom,50
		mov     eax,MoveRect.left
		sub     eax,DrawRect.left
		mov     ebx,lpRect
		mov     eax,[ebx].POINT.x
		cwde
		mov     [ebx].POINT.x,eax
		.if sdword ptr eax<rect2.left && sdword ptr eax>rect2.right
			mov     [esi].TOOL.dck.Docked,FALSE
			retn
		.endif
		mov     eax,[ebx].POINT.y
		cwde
		mov     [ebx].POINT.y,eax
		.if sdword ptr eax<rect2.top && sdword ptr eax>rect2.bottom
			mov     [esi].TOOL.dck.Docked,FALSE
			retn
		.endif
		mov     eax,[ebx].POINT.x
		sub     eax,ClientRect.left
		.if sdword ptr eax<50 && sdword ptr eax>-50
			mov     [esi].TOOL.dck.Position,TL_LEFT
			mov     [esi].TOOL.dck.IsChild,0
		.else
			mov     eax,[ebx].POINT.y
			sub     eax,ClientRect.top
			.if sdword ptr eax<50 && sdword ptr eax>-50
				mov     [esi].TOOL.dck.Position,TL_TOP
				mov     [esi].TOOL.dck.IsChild,0
			.else
				mov     eax,[ebx].POINT.x
				sub     eax,ClientRect.right
				.if sdword ptr eax<50 && sdword ptr eax>-50
					mov     [esi].TOOL.dck.Position,TL_RIGHT
					mov     [esi].TOOL.dck.IsChild,0
				.else
					mov     eax,[ebx].POINT.y
					sub     eax,ClientRect.bottom
					.if sdword ptr eax<50 && sdword ptr eax>-50
						mov     [esi].TOOL.dck.Position,TL_BOTTOM
						mov     [esi].TOOL.dck.IsChild,0
					.else
						mov     [esi].TOOL.dck.Docked,FALSE
					.endif
				.endif
			.endif
		.endif
	.endif
	retn

ToolMsg endp

ToolMsgAll proc uses ecx esi,uMsg:UINT,lParam:LPARAM,fTpe:DWORD

	mov     ecx,10
	mov     esi,offset ToolPool
  Nxt:
	mov     eax,[esi].TOOLPOOL.hCld
	or      eax,eax
	je		Ex
	push    ecx
	mov		edx,[esi].TOOLPOOL.lpTool
	mov		eax,[edx].TOOL.dck.IsChild
	.if fTpe==0
		invoke ToolMsg,[esi].TOOLPOOL.hCld,uMsg,lParam
	.elseif fTpe==1 && !eax
		invoke ToolMsg,[esi].TOOLPOOL.hCld,uMsg,lParam
	.elseif fTpe==2 && eax
		invoke ToolMsg,[esi].TOOLPOOL.hCld,uMsg,lParam
	.elseif fTpe==3
		mov		ecx,lParam
		.if [edx].TOOL.dck.Docked && [ecx].TOOL.dck.Docked && eax==[ecx].TOOL.dck.ID
			mov		eax,[edx].TOOL.dck.Visible
			.if eax!=[ecx].TOOL.dck.Visible
				invoke ToolMsg,[esi].TOOLPOOL.hCld,uMsg,lParam
			.endif
		.endif
	.endif
	pop     ecx
	add     esi,sizeof TOOLPOOL
	dec		ecx
	jne		Nxt
  Ex:
	ret

ToolMsgAll endp

ToolMessage proc uses ebx esi edi,hWin:HWND,uMsg:UINT,lParam:LPARAM
	LOCAl   pt:POINT
	LOCAL   rect:RECT
	LOCAL   clW:DWORD
	LOCAL   clH:DWORD
	LOCAL	tls[10]:TOOL

	mov		eax,uMsg
	.if eax==TLM_INIT
		mov     ToolPtr,0
	.elseif eax==TLM_SIZE
		invoke ToolMsgAll,TLM_ADJUSTRECT,lParam,1
		invoke ToolMsgAll,TLM_ADJUSTRECT,lParam,2
		invoke CopyRect,addr ClientRect,lParam
		mov     edx,lParam
		mov     eax,[edx].RECT.right
		sub     eax,[edx].RECT.left
		mov     clW,eax
		mov     eax,[edx].RECT.bottom
		sub     eax,[edx].RECT.top
		mov     clH,eax
		invoke MoveWindow,hClient,[edx].RECT.left,[edx].RECT.top,clW,clH,TRUE
		invoke ToolMsgAll,TLM_REDRAW,0,1
		invoke ToolMsgAll,TLM_REDRAW,0,2
	.elseif eax==TLM_PAINT
		invoke ToolMsgAll,TLM_CAPTION,0,0
	.elseif eax==TLM_CREATE
		push    ecx
		mov     esi,offset ToolPool
		mov     eax,ToolPtr
		add     esi,eax
		add     ToolPtr,sizeof TOOLPOOL
		mov		ecx,sizeof TOOLPOOL
		xor		edx,edx
		div		ecx
		mov     ecx,sizeof TOOL
		mul     ecx
		mov     edi,offset ToolData
		add     edi,eax
		push    edi
		mov     eax,hWin
		mov     [esi].TOOLPOOL.hCld,eax
		mov     [esi].TOOLPOOL.lpTool,edi
		mov     esi,lParam
		mov     ecx,sizeof DOCKING
		cld
		rep movsb
		mov     ecx,sizeof TOOL - sizeof DOCKING
		xor     al,al
		rep stosb
		pop     edx
		push    edx
		invoke Do_ToolFloat,edx
		pop     edx
		push    eax
		mov     [edx].TOOL.hWin,eax
		mov		eax,hWin
		mov     [edx].TOOL.hCld,eax
		push    edx
		invoke SetWindowLong,[edx].TOOL.hCld,GWL_WNDPROC,addr ToolCldWndProc
		pop     edx
		mov     [edx].TOOL.lpfnOldCldWndProc,eax
		invoke ToolMsg,[edx].TOOL.hCld,TLM_SETTBR,0
		pop     eax
		pop     ecx
	.elseif eax==TLM_MOUSEMOVE
		mov     eax,lParam
		movsx	eax,ax
		mov     pt.x,eax
		mov     eax,lParam
		shr     eax,16
		movsx	eax,ax
		mov     pt.y,eax
		.if ToolResize
			invoke CopyRect,addr DrawRect,addr MoveRect
			mov     eax,pt.x
			cwde
			.if sdword ptr eax<0
				mov     pt.x,0
			.endif
			mov     eax,pt.y
			cwde
			.if sdword ptr eax<0
				mov     pt.y,0
			.endif
			mov     eax,ToolResize
			call GetToolPtr
			mov     eax,[edx].TOOL.dck.Position
			.if eax==TL_LEFT
				mov     eax,ClientRect.right
				sub     eax,RESIZEBAR
				.if eax<pt.x
					mov     pt.x,eax
				.endif
				mov     eax,[edx].TOOL.dr.left
				add     eax,RESIZEBAR+2
				.if eax>pt.x
					mov     pt.x,eax
				.endif
				mov     eax,pt.x
				sub     eax,MovePt.x
				add     DrawRect.right,eax
				mov		eax,DrawRect.bottom
				sub		eax,DrawRect.top
				invoke MoveWindow,hSize,DrawRect.right,DrawRect.top,2,eax,TRUE
			.elseif eax==TL_TOP
				mov     eax,ClientRect.bottom
				sub     eax,RESIZEBAR+1
				.if eax<pt.y
					mov     pt.y,eax
				.endif
				mov     eax,[edx].TOOL.dr.top
				add     eax,TOTCAPHT+RESIZEBAR+2
				.if eax>pt.y
					mov     pt.y,eax
				.endif
				mov     eax,pt.y
				sub     eax,MovePt.y
				add     DrawRect.bottom,eax
				mov		eax,DrawRect.right
				sub		eax,DrawRect.left
				invoke MoveWindow,hSize,DrawRect.left,DrawRect.bottom,eax,2,TRUE
			.elseif eax==TL_RIGHT
				mov     eax,ClientRect.left
				add     eax,RESIZEBAR
				.if eax>pt.x
					mov     pt.x,eax
				.endif
				mov     eax,[edx].TOOL.dr.right
				sub     eax,RESIZEBAR+2
				.if eax<pt.x
					mov     pt.x,eax
				.endif
				mov     eax,pt.x
				sub     eax,MovePt.x
				add     DrawRect.left,eax
				mov		eax,DrawRect.bottom
				sub		eax,DrawRect.top
				invoke MoveWindow,hSize,DrawRect.left,DrawRect.top,2,eax,TRUE
			.elseif eax==TL_BOTTOM
				mov     eax,ClientRect.top
				add     eax,RESIZEBAR+1
				.if eax>pt.y
					mov     pt.y,eax
				.endif
				mov     eax,[edx].TOOL.dr.bottom
				sub     eax,TOTCAPHT+RESIZEBAR+2
				.if eax<pt.y
					mov     pt.y,eax
				.endif
				mov     eax,pt.y
				sub     eax,MovePt.y
				add     DrawRect.top,eax
				mov		eax,DrawRect.right
				sub		eax,DrawRect.left
				invoke MoveWindow,hSize,DrawRect.left,DrawRect.top,eax,2,TRUE
			.endif
			invoke ShowWindow,hSize,SW_SHOWNOACTIVATE
		.elseif ToolMove
			lea		edi,tls
			mov		esi,offset ToolData
			mov		ecx,sizeof tls
			rep movsb
			invoke CopyRect,addr DrawRect,addr MoveRect
			mov     eax,pt.x
			sub     eax,MovePt.x
			add     DrawRect.left,eax
			add     DrawRect.right,eax
			mov     eax,pt.y
			sub     eax,MovePt.y
			add     DrawRect.top,eax
			add     DrawRect.bottom,eax
			invoke ToolMsg,ToolMove,TLM_MOVETEST,addr pt
			invoke CopyRect,addr rect,offset mdirect
			invoke ToolMsgAll,TLM_ADJUSTRECT,addr rect,1
			invoke ToolMsgAll,TLM_ADJUSTRECT,addr rect,2
			mov		eax,ToolMove
			invoke GetToolPtr
			.if [edx].TOOL.dck.Docked
				invoke CopyRect,addr rect,addr [edx].TOOL.dr
				invoke ClientToScreen,hWnd,addr rect
				invoke ClientToScreen,hWnd,addr rect.right
			.else
				invoke CopyRect,addr rect,addr [edx].TOOL.dck.fr
				invoke ClientToScreen,hWnd,addr pt
				mov		edx,rect.right
				sub		edx,rect.left
				mov		eax,pt.x
				mov		rect.left,eax
				add		eax,edx
				mov		rect.right,eax
				shr		edx,1
				sub		rect.left,edx
				sub		rect.right,edx
				mov		edx,rect.bottom
				sub		edx,rect.top
				mov		eax,pt.y
				sub		eax,10
				mov		rect.top,eax
				add		eax,edx
				mov		rect.bottom,eax
				invoke CopyRect,offset FloatRect,addr rect
			.endif
			lea		esi,tls
			mov		edi,offset ToolData
			mov		ecx,sizeof tls
			rep movsb
			invoke ToolDrawRect,addr rect,1,0
		.else
			invoke ToolMsgAll,uMsg,addr pt,0
		.endif
	.elseif eax==TLM_LBUTTONDOWN
		mov     eax,lParam
		movsx	eax,ax
		mov     MovePt.x,eax
		mov     eax,lParam
		shr     eax,16
		movsx	eax,ax
		mov     MovePt.y,eax
		invoke ToolMsgAll,uMsg,addr pt,0
	.elseif eax==TLM_LBUTTONUP
		mov     eax,lParam
		movsx	eax,ax
		mov     pt.x,eax
		mov     eax,lParam
		shr     eax,16
		movsx	eax,ax
		mov     pt.y,eax
		.if ToolResize
			invoke ToolMsg,ToolResize,uMsg,addr pt
			mov     ToolResize,0
		.elseif ToolMove
			invoke ToolMsg,ToolMove,uMsg,addr pt
			mov     ToolMove,0
		.endif
		invoke InvalidateRect,hClient,NULL,TRUE
	.elseif eax==TLM_HIDE
		invoke ToolMsg,hWin,uMsg,lParam
		mov		eax,hWin
		invoke GetToolPtr
		invoke ToolMsgAll,uMsg,edx,3
	.else
		invoke ToolMsg,hWin,uMsg,lParam
	.endif
	ret

ToolMessage endp

ToolWndProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL   rect:RECT
	LOCAL	pt:POINT
	LOCAL   tlW:DWORD
	LOCAL   tlH:DWORD

	mov		eax,uMsg
	.if eax==WM_CREATE
		mov     edx,lParam
		mov     eax,[edx].CREATESTRUCT.lpCreateParams
		invoke SetWindowLong,hWin,GWL_USERDATA,eax
	.elseif eax==WM_SIZE
		mov     eax,hWin
		call    GetToolStruct
		mov		ebx,edx
		.if [ebx].TOOL.dck.Visible
			invoke GetWindowRect,hWin,addr [ebx].TOOL.dck.fr
			invoke GetClientRect,hWin,addr rect
			mov     eax,rect.right
			sub     eax,rect.left
			mov     tlW,eax
			mov     eax,rect.bottom
			sub     eax,rect.top
			mov     tlH,eax
			invoke MoveWindow,[ebx].TOOL.hCld,rect.left,rect.top,tlW,tlH,TRUE
		.endif
	.elseif eax==WM_SHOWWINDOW
		mov     eax,hWin
		call    GetToolStruct
		.if ![edx].TOOL.dck.Visible || [edx].TOOL.dck.Docked
			xor		eax,eax
			ret
		.endif
	.elseif eax==WM_MOVE
		mov     eax,hWin
		call    GetToolStruct
		invoke GetWindowRect,hWin,addr [edx].TOOL.dck.fr
	.elseif eax==WM_NCLBUTTONDOWN
		.if wParam==HTCAPTION
			invoke LoadCursor,0,IDC_HAND
			mov		MoveCur,eax
			mov     eax,hWin
			call    GetToolStruct
			mov		ebx,edx
			mov		[ebx].TOOL.dCurFlag,TL_ONCAPTION
			mov		[ebx].TOOL.dck.Docked,TRUE
			mov		eax,[ebx].TOOL.dck.fr.top
			add		eax,10
			mov		pt.y,eax
			mov		eax,[ebx].TOOL.dck.fr.right
			sub		eax,[ebx].TOOL.dck.fr.left
			shr		eax,1
			add		eax,[ebx].TOOL.dck.fr.left
			mov		pt.x,eax
			invoke SetCursorPos,pt.x,pt.y
			invoke ToolMsg,[ebx].TOOL.hCld,TLM_LBUTTONDOWN,addr pt
			xor		eax,eax
			ret
		.endif
	.elseif eax==WM_NOTIFY
;		mov		ebx,lParam
;		mov		eax,[ebx].NMHDR.hwndFrom
;		.if eax==hTab && [ebx].NMHDR.code==TCN_SELCHANGE
;;			invoke TabToolSel,hClient
;		.endif
	.elseif eax==WM_CLOSE
		mov     eax,hWin
		call    GetToolStruct
		mov     eax,[edx].TOOL.hCld
		invoke ToolMessage,eax,TLM_HIDE,0
		invoke InvalidateRect,hClient,NULL,TRUE
		xor		eax,eax
		ret
	.endif
	invoke  DefWindowProc,hWin,uMsg,wParam,lParam
	ret

ToolWndProc endp

ToolCldProc proc uses ebx esi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
;	LOCAL	pt:POINT
;	LOCAL	rect:RECT
;	LOCAL	buffer[8]:BYTE
;	LOCAL	buffer1[8]:BYTE
;
;	mov		eax,uMsg
;	.if eax==WM_CTLCOLORSTATIC
;;		invoke SetBkMode,wParam,TRANSPARENT
;;		invoke SetTextColor,wParam,radcol.infotext
;;		mov		eax,hBrInfo
;		ret
;	.elseif eax==WM_NOTIFY
;;		mov		ebx,lParam
;;		mov		eax,(NMHDR ptr [ebx]).code
;;		.if eax==TVN_BEGINDRAG
;;			.if fGroup && sdword ptr [ebx].NM_TREEVIEW.itemNew.lParam>0
;;;				invoke GroupTVBeginDrag,[ebx].NMHDR.hwndFrom,hWin,lParam
;;			.else
;;				invoke SendMessage,[ebx].NMHDR.hwndFrom,TVM_SELECTITEM,TVGN_CARET,[ebx].NM_TREEVIEW.itemNew.hItem
;;			.endif
;;		.endif
;	.elseif eax==WM_LBUTTONUP
;;		.if IsDragging
;;			mov		IsDragging,FALSE
;;;			invoke GroupTVEndDrag,hPbrTrv
;;			mov		esi,offset profile
;;			.while [esi].PROFILE.lpszFile
;;;				invoke BinToDec,[esi].PROFILE.iNbr,addr buffer
;;;				invoke BinToDec,[esi].PROFILE.nGrp,addr buffer1
;;;				invoke WritePrivateProfileString,addr iniProjectGroup,addr buffer,addr buffer1,addr ProjectFile
;;				lea		esi,[esi+sizeof PROFILE]
;;			.endw
;;		.endif
;		xor		eax,eax
;		jmp		Ex
;	.elseif eax==WM_MOUSEMOVE
;;		.if IsDragging
;;			invoke GetCursorPos,addr pt
;;			invoke ImageList_DragMove,pt.x,pt.y
;;			invoke GetWindowRect,hPbrTrv,addr rect
;;			invoke GetScrollPos,hPbrTrv,SB_VERT
;;			mov		ebx,eax
;;			mov		edx,pt.y
;;			.if sdword ptr edx<rect.top
;;				dec		ebx
;;				mov		eax,ebx
;;				shl		eax,16
;;				or		eax,SB_LINEUP
;;				invoke SendMessage,hPbrTrv,WM_VSCROLL,eax,0
;;			.elseif sdword ptr edx>rect.bottom
;;				inc		ebx
;;				mov		eax,ebx
;;				shl		eax,16
;;				or		eax,SB_LINEDOWN
;;				invoke SendMessage,hPbrTrv,WM_VSCROLL,eax,0
;;			.endif
;;		.endif
;		xor		eax,eax
;		jmp		Ex
;	.endif
	invoke  DefWindowProc,hWin,uMsg,wParam,lParam
;  Ex:
	ret

ToolCldProc endp

GetToolStruct proc

	invoke GetWindowLong,eax,GWL_USERDATA
	mov     edx,eax
	ret

GetToolStruct endp

ToolCldWndProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	pt:POINT
	LOCAL	rect:RECT
	LOCAL	tvi:TV_ITEMEX
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[8]:BYTE
	LOCAL	tch:TC_HITTESTINFO

	mov		eax,uMsg
	.if eax==WM_SETFOCUS
		mov     eax,hWin
		call    GetToolPtr
		mov     [edx].TOOL.dFocus,TRUE
		invoke ToolMsg,hWin,TLM_CAPTION,0
;	.elseif eax==WM_DRAWITEM
;		push	esi
;		mov		esi,lParam
;		assume esi:ptr DRAWITEMSTRUCT
;		.if [esi].itemID!=LB_ERR
;			test	[esi].itemState,ODS_SELECTED
;			.if ZERO?
;;				invoke SetTextColor,[esi].hdc,radcol.propertiestext
;;				invoke SetBkColor,[esi].hdc,radcol.properties
;			.else
;				invoke GetSysColor,COLOR_HIGHLIGHTTEXT
;				invoke SetTextColor,[esi].hdc,eax
;				invoke GetSysColor,COLOR_HIGHLIGHT
;				invoke SetBkColor,[esi].hdc,eax
;			.endif
;			push	[esi].rcItem.right
;			mov		eax,[esi].hwndItem
;			.if eax==hPrpLstDlg
;				mov		eax,lbTp
;				mov		[esi].rcItem.right,eax
;			.endif
;			invoke ExtTextOut,[esi].hdc,0,0,ETO_OPAQUE,addr [esi].rcItem,NULL,0,NULL
;			pop		[esi].rcItem.right
;;			invoke SendMessage,[esi].hwndItem,LB_GETTEXT,[esi].itemID,addr tempbuff
;			mov		eax,offset tempbuff
;			.while byte ptr [eax] && byte ptr [eax]!=VK_TAB
;				inc		eax
;			.endw
;			sub		eax,offset tempbuff
;;			invoke TextOut,[esi].hdc,2,[esi].rcItem.top,addr tempbuff,eax
;			mov		eax,[esi].hwndItem
;;			.if eax==hPrpLstDlg
;;				invoke SetTextColor,[esi].hdc,radcol.propertiestext
;;				invoke SetBkColor,[esi].hdc,radcol.properties
;;				mov		edx,offset tempbuff
;;				.while byte ptr [edx] && byte ptr [edx]!=VK_TAB
;;					inc		edx
;;				.endw
;;				inc		edx
;;				mov		eax,edx
;;				.while byte ptr [eax] && byte ptr [eax]!=VK_TAB
;;					inc		eax
;;				.endw
;;				sub		eax,edx
;;				mov		ecx,lbTp
;;				add		ecx,2
;;				invoke TextOut,[esi].hdc,ecx,[esi].rcItem.top,edx,eax
;;			.endif
;			invoke CreatePen,PS_SOLID,0,0C0C0C0h
;			invoke SelectObject,[esi].hdc,eax
;			push	eax
;			mov		edx,[esi].rcItem.bottom
;			dec		edx
;			invoke MoveToEx,[esi].hdc,[esi].rcItem.left,edx,NULL
;			mov		edx,[esi].rcItem.bottom
;			dec		edx
;			invoke LineTo,[esi].hdc,[esi].rcItem.right,edx
;			mov		eax,[esi].hwndItem
;			.if eax==hPrpLstDlg
;				mov		edx,[esi].rcItem.left
;				add		edx,lbTp
;				invoke MoveToEx,[esi].hdc,edx,[esi].rcItem.top,NULL
;				mov		edx,[esi].rcItem.left
;				add		edx,lbTp
;				invoke LineTo,[esi].hdc,edx,[esi].rcItem.bottom
;			.endif
;			pop		eax
;			invoke SelectObject,[esi].hdc,eax
;			invoke DeleteObject,eax
;		.endif
;		assume esi:nothing
;		pop		esi
;		xor		eax,eax
;		ret
;	.elseif eax==WM_CONTEXTMENU
;;		invoke DllProc,hWin,AIM_CONTEXTMENU,wParam,lParam,RAM_CONTEXTMENU
;		.if eax
;			xor		eax,eax
;			ret
;		.endif
;		mov		eax,lParam
;		mov		edx,hWin
;		.if eax!=-1
;			cwde
;			mov		pt.x,eax
;			mov		eax,lParam
;			shr		eax,16
;			cwde
;			mov		pt.y,eax
;		.elseif edx==hOut
;			invoke GetCaretPos,addr pt
;			invoke ClientToScreen,hWin,addr pt
;		.else
;			invoke GetWindowRect,hWin,addr rect
;			mov		eax,rect.left
;			add		eax,10
;			mov		pt.x,eax
;			mov		eax,rect.top
;			add		eax,10
;			mov		pt.y,eax
;		.endif
;		mov		eax,hWin
;;		.if eax==hPbr
;;			invoke IsWindowVisible,hPbrTrv
;;			.if eax
;;				invoke EnableMenuItem,hToolMenu,IDM_PROJECT_ADDNEW,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_PROJECT_ADDEXISTING,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_PROJECT_ADDEXISTINGOPEN,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_PROMNU_FILEPROP,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_PROMNU_REMOVE,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_PROMNU_RENAME,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_PROMNU_LOCK,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_PROMNU_COPY,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_FILE_CLOSEPROJECT,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_FILE_DELETEPROJECT,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_PROJECT_REFRESH,MF_GRAYED
;;				invoke EnableMenuItem,hToolMenu,IDM_PROJECT_GROUPS,MF_GRAYED
;;				.if fProject
;;					;Project
;;					invoke EnableMenuItem,hToolMenu,IDM_PROJECT_ADDNEW,MF_ENABLED
;;					invoke EnableMenuItem,hToolMenu,IDM_PROJECT_ADDEXISTING,MF_ENABLED
;;					invoke EnableMenuItem,hToolMenu,IDM_FILE_CLOSEPROJECT,MF_ENABLED
;;					invoke EnableMenuItem,hToolMenu,IDM_FILE_DELETEPROJECT,MF_ENABLED
;;					invoke EnableMenuItem,hToolMenu,IDM_PROJECT_GROUPS,MF_ENABLED
;;					.if hDialog
;;						invoke EnableMenuItem,hToolMenu,IDM_PROJECT_REFRESH,MF_GRAYED
;;					.else
;;						invoke EnableMenuItem,hToolMenu,IDM_PROJECT_REFRESH,MF_ENABLED
;;					.endif
;;					invoke SendMessage,hPbrTrv,TVM_GETNEXTITEM,TVGN_CARET,hPbrTrv
;;					.if eax
;;						mov		tvi.hItem,eax
;;						mov		tvi.imask,TVIF_PARAM or TVIF_TEXT
;;						lea		eax,buffer
;;						mov		tvi.pszText,eax
;;						mov		tvi.cchTextMax,sizeof buffer
;;						invoke SendMessage,hPbrTrv,TVM_GETITEM,0,addr tvi
;;						.if sdword ptr tvi.lParam>0
;;							invoke GetFileImg,addr buffer
;;							.if eax==2 || eax==3
;;								invoke EnableMenuItem,hToolMenu,IDM_PROMNU_FILEPROP,MF_ENABLED
;;							.endif
;;							invoke EnableMenuItem,hToolMenu,IDM_PROMNU_REMOVE,MF_ENABLED
;;							invoke EnableMenuItem,hToolMenu,IDM_PROMNU_RENAME,MF_ENABLED
;;							invoke EnableMenuItem,hToolMenu,IDM_PROMNU_LOCK,MF_ENABLED
;;							.if hEdit
;;								invoke EnableMenuItem,hToolMenu,IDM_PROMNU_COPY,MF_ENABLED
;;							.endif
;;						.endif
;;					.endif
;;					.if hEdit || hDialog
;;						invoke GetWindowLong,hMdiCld,16
;;						.if !eax
;;							invoke EnableMenuItem,hToolMenu,IDM_PROJECT_ADDEXISTINGOPEN,MF_ENABLED
;;						.endif
;;					.endif
;;				.endif
;;				invoke GetSubMenu,hToolMenu,0
;;			.else
;;				invoke SendMessage,hFileTrv,TVM_GETNEXTITEM,TVGN_CARET,hFileTrv
;;				.if eax
;;					mov		tvi.hItem,eax
;;					mov		tvi.imask,TVIF_PARAM or TVIF_TEXT or TVIF_IMAGE
;;					lea		eax,buffer
;;					mov		tvi.pszText,eax
;;					mov		tvi.cchTextMax,sizeof buffer
;;					invoke SendMessage,hPbrTrv,TVM_GETITEM,0,addr tvi
;;				.endif
;;				invoke EnableMenuItem,hToolMenu,IDM_FILE_COPYNAME,MF_GRAYED
;;				mov		eax,tvi.iImage
;;				.if eax>IML_START+1 && eax<IML_START+11
;;					invoke EnableMenuItem,hToolMenu,IDM_FILE_CUT,MF_ENABLED
;;					invoke EnableMenuItem,hToolMenu,IDM_FILE_COPY,MF_ENABLED
;;					invoke EnableMenuItem,hToolMenu,IDM_FILE_DELETE,MF_ENABLED
;;					invoke EnableMenuItem,hToolMenu,IDM_FILE_RENAME,MF_ENABLED
;;					.if hEdit
;;						invoke EnableMenuItem,hToolMenu,IDM_FILE_COPYNAME,MF_ENABLED
;;					.endif
;;				.else
;;					invoke EnableMenuItem,hToolMenu,IDM_FILE_CUT,MF_GRAYED
;;					invoke EnableMenuItem,hToolMenu,IDM_FILE_COPY,MF_GRAYED
;;					invoke EnableMenuItem,hToolMenu,IDM_FILE_DELETE,MF_GRAYED
;;					invoke EnableMenuItem,hToolMenu,IDM_FILE_RENAME,MF_GRAYED
;;				.endif
;;				mov		al,FileToCopy
;;				.if al
;;					mov		eax,MF_ENABLED
;;				.else
;;					mov		eax,MF_GRAYED
;;				.endif
;;				invoke EnableMenuItem,hToolMenu,IDM_FILE_PASTE,eax
;;				invoke GetSubMenu,hToolMenu,3
;;			.endif
;;		.elseif eax==hOut
;;			invoke GetSubMenu,hToolMenu,1
;;		.elseif eax==hTab
;;			invoke GetCursorPos,addr tch.pt
;;			invoke GetClientRect,hTab,addr rect
;;			invoke ClientToScreen,hWin,addr rect
;;			mov		eax,rect.left
;;			sub		tch.pt.x,eax
;;			mov		eax,rect.top
;;			sub		tch.pt.y,eax
;;			invoke SendMessage,hTab,TCM_HITTEST,0,addr tch
;;			push	fMaximized
;;			.if eax!=-1
;;				invoke TabToolSetSel,eax
;;			.endif
;;			mov		eax,MENUWINDOW
;;			pop		edx
;;			.if edx
;;				inc		eax
;;			.endif
;;			invoke GetSubMenu,hMenu,eax
;;		.else
;;			mov		eax,0
;;		.endif
;;		.if eax
;;			invoke TrackPopupMenu,eax,TPM_LEFTALIGN or TPM_RIGHTBUTTON,pt.x,pt.y,0,hWnd,0
;;		.endif
;		xor		eax,eax
;		ret
;	.elseif eax==WM_COMMAND
;;		invoke DllProc,hWnd,AIM_COMMAND,wParam,lParam,RAM_COMMAND
;;		.if eax
;;			xor		eax,eax
;;			ret
;;		.endif
;;		mov		edx,wParam
;;		shr		edx,16
;;		.if edx==BN_CLICKED
;;			mov		eax,wParam
;;			.if eax==5
;;				.if !fProject
;;					invoke EnumChildWindows,hClient,addr SetOpenProperty,-2
;;				.endif
;;				invoke RefreshProperty
;;				invoke SendMessage,hPrpCbo,CB_GETCURSEL,0,0
;;				.if eax==CB_ERR
;;					xor		eax,eax
;;				.endif
;;				push	eax
;;				invoke SendMessage,hPrpCbo,CB_GETITEMDATA,eax,0
;;				pop		edx
;;				.if eax<=5 || (eax>=10 && eax<=13)
;;					invoke SetProperty,eax,edx
;;				.endif
;;			.elseif eax>=1 && eax<=4
;;				mov		fProperty,eax
;;				invoke SendMessage,hPrpCbo,CB_GETCURSEL,0,0
;;				.if eax==CB_ERR
;;					xor		eax,eax
;;				.endif
;;				push	eax
;;				invoke SendMessage,hPrpCbo,CB_GETITEMDATA,eax,0
;;				pop		edx
;;				.if eax<=5 || (eax>=10 && eax<=13)
;;					invoke SetProperty,eax,edx
;;				.endif
;;			.elseif eax==11
;;				invoke EnableProjectBrowser,TRUE
;;			.elseif eax==12
;;				xor		fGroup,1
;;				.if fProject
;;					invoke SendMessage,hPbrTrv,TVM_GETNEXTITEM,TVGN_ROOT,0
;;					invoke SendMessage,hPbrTrv,TVM_DELETEITEM,0,eax
;;					invoke GetProjectFiles,FALSE
;;					.if hMdiCld
;;						invoke ProSetTrv,hMdiCld
;;					.else
;;						invoke SendMessage,hPbrTrv,TVM_GETNEXTITEM,TVGN_ROOT,0
;;						invoke SendMessage,hPbrTrv,TVM_SELECTITEM,TVGN_CARET,eax
;;					.endif
;;				.endif
;;			.elseif eax==18
;;				.if fProject
;;					xor		fExpand,1
;;					.if fExpand
;;						invoke GroupExpandAll,hPbrTrv,0
;;					.else
;;						invoke GroupCollapseAll,hPbrTrv,0
;;					.endif
;;				.endif
;;			.elseif eax==13
;;				invoke EnableProjectBrowser,FALSE
;;			.elseif eax==14
;;				xor		fFileBrowser,1
;;				invoke FileDir,offset FilePath
;;			.elseif eax==15
;;				invoke iniRStripStr,offset FilePath,'\'
;;				invoke strlen,offset FilePath
;;				.if byte ptr FilePath[eax-1]==':'
;;					invoke strcat,offset FilePath,offset szBackSlash
;;				.endif
;;				invoke FileDir,offset FilePath
;;			.elseif eax==16
;;				movzx	eax,nFileBrowser
;;				and		al,0Fh
;;				mov		edx,MAX_PATH
;;				mul		edx
;;				add		eax,offset FilePaths
;;				invoke strcpy,eax,offset FilePath
;;				mov		ecx,10
;;				.while ecx
;;					push	ecx
;;					movzx	eax,nFileBrowser
;;					dec		al
;;					.if al<'0'
;;						mov		al,'9'
;;					.endif
;;					mov		nFileBrowser,al
;;					and		al,0Fh
;;					mov		edx,MAX_PATH
;;					mul		edx
;;					add		eax,offset FilePaths
;;					mov		edx,eax
;;					movzx	eax,byte ptr [edx]
;;					pop		ecx
;;				  .break .if eax
;;					dec		ecx
;;				.endw
;;				invoke strcpy,offset FilePath,edx
;;				invoke FileDir,offset FilePath
;;			.elseif eax==17
;;				movzx	eax,nFileBrowser
;;				and		al,0Fh
;;				mov		edx,MAX_PATH
;;				mul		edx
;;				add		eax,offset FilePaths
;;				invoke strcpy,eax,offset FilePath
;;				mov		ecx,10
;;				.while ecx
;;					push	ecx
;;					movzx	eax,nFileBrowser
;;					inc		al
;;					.if al>'9'
;;						mov		al,'0'
;;					.endif
;;					mov		nFileBrowser,al
;;					and		al,0Fh
;;					mov		edx,MAX_PATH
;;					mul		edx
;;					add		eax,offset FilePaths
;;					mov		edx,eax
;;					movzx	eax,byte ptr [edx]
;;					pop		ecx
;;				  .break .if eax
;;					dec		ecx
;;				.endw
;;				invoke strcpy,offset FilePath,edx
;;				invoke FileDir,offset FilePath
;;			.endif
;;		.elseif edx==LBN_SELCHANGE
;;			invoke SendMessage,lParam,LB_GETCURSEL,0,0
;;			.if eax!=LB_ERR
;;				mov		edx,eax
;;				mov		eax,lParam
;;				.if eax==hPrpLstCode
;;					invoke SendMessage,lParam,LB_GETITEMRECT,edx,addr rect
;;					mov		eax,lbHt
;;					sub		rect.right,eax
;;					sub		rect.top,1
;;					invoke SetWindowPos,hTxtBtn,HWND_TOP,rect.right,rect.top,eax,eax,0
;;					invoke ShowWindow,hTxtBtn,SW_SHOWNOACTIVATE
;;				.elseif eax==hPrpLstDlg
;;					invoke PropListSetPos
;;				.endif
;;			.endif
;;		.endif
;;		invoke DllProc,hWnd,AIM_COMMANDDONE,wParam,lParam,RAM_COMMANDDONE
;	.elseif eax==WM_NOTIFY
;		mov		ebx,lParam
;		mov		eax,(NMHDR ptr [ebx]).code
;		mov		ecx,(NMHDR ptr [ebx]).hwndFrom
;		.if eax==TTN_NEEDTEXTW || eax==TTN_NEEDTEXT
;			;Toolbar tooltip
;			invoke GetToolBarTooltip,hWin,(NMHDR ptr [ebx]).idFrom
;			mov		(TOOLTIPTEXT ptr [ebx]).lpszText,eax
;		.elseif eax==TVN_BEGINLABELEDIT
;			.if ecx==hPbrTrv
;				.if sdword ptr [ebx].NMTVDISPINFO.item.lParam>0
;					invoke strcpy,offset FileToCopy,[ebx].NMTVDISPINFO.item.pszText
;					xor		eax,eax
;				.else
;					mov		eax,TRUE
;				.endif
;			.elseif ecx==hFileTrv
;				invoke FileGetName
;				xor		eax,eax
;			.endif
;			jmp		Ex
;		.elseif eax==TVN_ENDLABELEDIT
;			xor		eax,eax
;			.if ecx==hPbrTrv
;				.if [ebx].NMTVDISPINFO.item.pszText
;					invoke strcpy,addr buffer,[ebx].NMTVDISPINFO.item.pszText
;					invoke strcmp,addr buffer,offset FileToCopy
;					.if eax
;						.if sdword ptr [ebx].NMTVDISPINFO.item.lParam>0
;							; File
;							invoke SetCurrentDirectory,offset ProjectPath
;							invoke MoveFile,offset FileToCopy,addr buffer
;							.if eax
;								mov		eax,[ebx].NMTVDISPINFO.item.lParam
;								mov		edx,eax
;								invoke BinToDec,edx,addr buffer1
;								invoke WritePrivateProfileString,addr iniProjectFiles,addr buffer1,addr buffer,addr ProjectFile
;								invoke GetPrivateProfileSection,addr iniProjectFiles,hMemPro,32*1024-1,addr	ProjectFile
;								mov		hFound,0
;								invoke strcpy,offset FileName,offset ProjectPath
;								invoke strcat,offset FileName,offset FileToCopy
;								invoke GetFullPathName,addr FileName,sizeof FileName,addr FileName,addr buffer1
;								invoke UpdateAll,FIND_OPEN_FILENAME
;								.if hFound
;									invoke DelPath,hFound
;									invoke strcpy,offset FileName,offset ProjectPath
;									invoke strcat,offset FileName,addr buffer
;									invoke GetFullPathName,addr FileName,sizeof FileName,addr FileName,addr buffer1
;									invoke SetWindowText,hFound,addr FileName
;									invoke strlen,addr buffer
;									.while eax
;										.break .if buffer[eax-1]=='\'
;										dec		eax
;									.endw
;									invoke TabToolUpdate,hFound,addr buffer[eax]
;									invoke AddPath,hFound
;								.endif
;								invoke DllProc,hWnd,AIM_PROJECTRENAME,offset FileToCopy,addr buffer,RAM_PROJECTRENAME
;								mov		eax,TRUE
;								jmp		Ex
;							.endif
;;						.elseif sdword ptr [ebx].NMTVDISPINFO.item.lParam<0
;;							; Group
;;							invoke SendMessage,hPbrTrv,TVM_SETITEM,0,addr [ebx].NMTVDISPINFO.item
;;;							invoke GroupGetExpand,hPbrTrv
;;;							invoke GroupUpdateGroup,hPbrTrv
;;							invoke GroupSaveGroups,hPbrTrv
;;							mov		eax,TRUE
;;							jmp		Ex
;						.endif
;					.endif
;				.endif
;			.elseif ecx==hFileTrv
;				.if [ebx].NMTVDISPINFO.item.pszText
;					invoke FileGetPath,addr buffer
;					invoke strcat,addr buffer,[ebx].NMTVDISPINFO.item.pszText
;					invoke lstrcmpi,addr buffer,offset FileToCopy
;					.if eax
;						invoke MoveFile,offset FileToCopy,addr buffer
;						mov		eax,TRUE
;					.endif
;				.endif
;				mov		FileToCopy,0
;			.endif
;			jmp		Ex
;		.endif
	.elseif eax==WM_LBUTTONDOWN
		invoke SetFocus,hWin
		invoke SendMessage,hWnd,WM_TOOLCLICK,hWin,lParam
	.elseif eax==WM_RBUTTONDOWN
		invoke SetFocus,hWin
		invoke SendMessage,hWnd,WM_TOOLRCLICK,hWin,lParam
		xor		eax,eax
		ret
	.elseif eax==WM_LBUTTONDBLCLK
		invoke SendMessage,hWnd,WM_TOOLDBLCLICK,hWin,lParam
;		mov		eax, hWin
;		.if eax==hTab
;			mov		tabinx,-1
;			invoke GetCursorPos,addr tch.pt
;			invoke GetClientRect,hTab,addr rect
;			invoke ClientToScreen,hWin,addr rect
;			mov		eax,rect.left
;			sub		tch.pt.x,eax
;			mov		eax,rect.top
;			sub		tch.pt.y,eax
;			invoke SendMessage,hTab,TCM_HITTEST,0,addr tch
;			; get tab that was dblclicked
;			.if eax != -1
;				push	eax
;				invoke SendMessage,hTab,TCM_GETCURSEL,0,0
;				pop		edx
;				; is tab that was dblclicked also selected?
;				.if eax == edx
;					invoke SendMessage,hMdiCld,WM_CLOSE,0,0
;				.endif
;			.endif
;		.else
;			invoke SendMessage,hWnd,WM_TOOLDBLCLICK,hWin,lParam
;		.endif	
;		xor		eax,eax
;		ret
	.elseif eax==WM_KILLFOCUS
		mov     eax, hWin
		call    GetToolPtr
		mov     [edx].TOOL.dFocus,FALSE
		invoke ToolMsg,hWin,TLM_CAPTION,0
;	.elseif eax==WM_SIZE
;		invoke SendMessage,hWnd,WM_TOOLSIZE,hWin,lParam
;	.elseif eax==WM_MOUSEWHEEL
;		.if !MouseWheel
;			xor		eax,eax
;			ret
;		.endif
;	.elseif eax==WM_CTLCOLORLISTBOX
;		invoke SetTextColor,wParam,radcol.propertiestext
;		invoke SetBkColor,wParam,radcol.properties
;		mov		eax,hBrPrp
;		ret
;	.elseif eax==WM_CTLCOLOREDIT
;		mov		eax,hWin
;		.if eax!=hPbr
;			invoke SetTextColor,wParam,radcol.propertiestext
;			invoke SetBkColor,wParam,radcol.properties
;			mov		eax,hBrPrp
;			ret
;		.endif
	.endif
	mov     eax,hWin
	call    GetToolPtr
	mov     eax,[edx].TOOL.lpfnOldCldWndProc
	invoke CallWindowProc,eax,hWin,uMsg,wParam,lParam
  Ex:
	ret

ToolCldWndProc endp

