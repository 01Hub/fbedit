;#########################################################################
;		Assembler directives

.486
.model flat,stdcall
option casemap:none

;#########################################################################
;		Include file

include CodeComplete.inc

.code

;ShowListBox proc hWin:HWND
;	LOCAL	pt:POINT
;	LOCAL	rect:RECT
;	LOCAL	MaxX:DWORD
;	LOCAL	MaxY:DWORD
;	LOCAL	lbwt:DWORD
;	LOCAL	lbht:DWORD
;	LOCAL	lnht:DWORD
;
;	;Get pointer to EDIT structure
;	invoke GetWindowLong,hWin,0
;	;Get line height
;	mov		edx,[eax].EDIT.fntinfo.fntht
;	add		edx,[eax].EDIT.fntinfo.linespace
;	mov		lnht,edx
;	;Get size of listbox
;	invoke GetWindowRect,hCC,addr rect
;	mov		eax,rect.right
;	sub		eax,rect.left
;	mov		lbwt,eax
;	mov		eax,rect.bottom
;	sub		eax,rect.top
;	mov		lbht,eax
;	;Get screen size
;	invoke GetSystemMetrics,SM_CXSCREEN
;	mov		MaxX,eax
;	invoke GetSystemMetrics,SM_CYSCREEN
;	mov		MaxY,eax
;	;Get caret position
;	invoke GetCaretPos,addr pt
;	invoke ClientToScreen,hWin,addr pt
;	;Position and show the LB
;	mov		edx,lbwt
;	mov		eax,pt.x
;	add		eax,edx
;	.if eax>MaxX
;		sub		eax,MaxX
;		sub		pt.x,eax
;	.endif
;	mov		edx,lbht
;	mov		eax,pt.y
;	add		eax,lnht
;	add		eax,edx
;	.if eax>MaxY
;		add		edx,3
;		sub		pt.y,edx
;	.else
;		mov		eax,lnht
;		add		eax,3
;		add		pt.y,eax
;	.endif
;	invoke MoveWindow,hCC,pt.x,pt.y,lbwt,lbht,TRUE
;	invoke ShowWindow,hCC,SW_SHOWNOACTIVATE
;	ret
;
;ShowListBox endp
;
;ShowToolTip proc hWin:HWND,lpszFun:DWORD,nComma:DWORD
;	LOCAL	hDC:HDC
;	LOCAL	pt:POINT
;	LOCAL	ptW:POINT
;	LOCAL	ptC:POINT
;
;	;Get caret position
;	invoke GetCaretPos,addr pt
;	invoke ClientToScreen,hWin,addr pt
;	;Get pointer to EDIT structure
;	invoke GetWindowLong,hWin,0
;	;Get line height
;	mov		edx,[eax].EDIT.fntinfo.fntht
;	add		edx,[eax].EDIT.fntinfo.linespace
;	add		edx,3
;	add		pt.y,edx
;	;Set the tooltip text
;	invoke SetWindowText,hTlt,lpszFun
;	invoke GetDC,hTlt
;	mov		hDC,eax
;	invoke SendMessage,hTlt,WM_GETFONT,0,0
;	invoke SelectObject,hDC,eax
;	push	eax
;	;Get size of all the text
;	invoke lstrlen,lpszFun
;	mov		edx,eax
;	invoke GetTextExtentPoint32,hDC,lpszFun,edx,addr ptW
;	add		ptW.x,4
;	add		ptW.y,3
;	;Get size of text up to the current comma
;	mov		edx,lpszFun
;	mov		ecx,nComma
;	.while TRUE
;		.if byte ptr [edx]==','
;			dec		ecx
;		.endif
;		.break .if !ecx || byte ptr [edx]==0
;		inc		edx
;	.endw
;	inc		edx
;	push	edx
;	sub		edx,lpszFun
;	invoke GetTextExtentPoint32,hDC,lpszFun,edx,addr ptC
;	;Adjust the tooltip position
;	mov		eax,ptC.x
;	sub		pt.x,eax
;	invoke MoveWindow,hTlt,pt.x,pt.y,ptW.x,ptW.y,TRUE
;	invoke ShowWindow,hTlt,SW_SHOWNA
;	invoke UpdateWindow,hTlt
;	;Draw the current parameter blue
;	invoke SetBkMode,hDC,TRANSPARENT
;	invoke SetTextColor,hDC,0D00000h
;	pop		edx
;	xor		ecx,ecx
;	.while byte ptr [edx+ecx] && byte ptr [edx+ecx]!=','
;		inc		ecx
;	.endw
;	invoke TextOut,hDC,ptC.x,0,edx,ecx
;	;Restore old font
;	pop		eax
;	invoke SelectObject,hDC,eax
;	invoke ReleaseDC,hTlt,hDC
;	ret
;
;ShowToolTip endp
;
;MdiChildProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
;	LOCAL	pt:POINT
;	LOCAL	buffer[256]:BYTE
;	LOCAL	nFilter:DWORD
;	LOCAL	lpFun:DWORD
;
;	.if uMsg==WM_NOTIFY
;		push	ebx
;		;Get pointer to RASELCHANGE structure
;		mov		ebx,lParam
;		;Check if it is SEL_TEXT notification
;		.if [ebx].RASELCHANGE.seltyp==SEL_TEXT
;			mov		eax,[ebx].RASELCHANGE.line
;			.if eax!=nLine || [ebx].RASELCHANGE.fchanged
;				mov		nLine,eax
;				.if fLB
;					;Hide the listbox
;					mov		fLB,FALSE
;					invoke ShowWindow,hLB,SW_HIDE
;				.endif
;				.if [ebx].RASELCHANGE.fchanged
;					;Get the line text
;					push	esi
;					push	edi
;					mov		esi,[ebx].RASELCHANGE.lpLine
;					mov		ecx,[esi].CHARS.len
;					lea		esi,[esi+sizeof CHARS]
;					mov		edi,offset linebuff
;					rep movsb
;					;Zero terminate line
;					mov		byte ptr [edi],0
;					.if byte ptr [edi-1]==VK_RETURN
;						;Dont want CR
;						mov		byte ptr [edi-1],0
;					.endif
;					mov		eax,[ebx].RASELCHANGE.chrg.cpMin
;					sub		eax,[ebx].RASELCHANGE.cpLine
;					invoke IsLineCoInvoke,eax
;					.if eax
;						mov		edi,eax
;						sub		eax,offset linebuff
;						mov		nPos,eax
;						invoke SendMessage,hLB,LB_RESETCONTENT,0,0
;						;put some text into listbox
;						mov		esi,offset szSomeText
;						.while byte ptr [esi]
;							lea		edx,buffer
;							push	esi
;							.while byte ptr [esi] && byte ptr [esi]!=','
;								mov		al,[esi]
;								mov		[edx],al
;								inc		esi
;								inc		edx
;							.endw
;							mov		byte ptr [edx],0
;							invoke Filter,addr buffer,edi
;							pop		edx
;							.if eax
;								mov		fLB,TRUE
;								mov		lpFun,edx
;								movzx	eax,byte ptr [eax-1]
;								mov		nFilter,eax
;								invoke SendMessage,hLB,LB_ADDSTRING,0,addr buffer
;								invoke SendMessage,hLB,LB_SETITEMDATA,eax,2
;							.endif
;							invoke lstrlen,esi
;							lea		esi,[esi+eax+1]
;						.endw
;						invoke SendMessage,hLB,LB_GETCOUNT,0,0
;						.if eax==1 && nFilter==','
;							;Count commas
;							mov		edx,[ebx].RASELCHANGE.chrg.cpMin
;							sub		edx,[ebx].RASELCHANGE.cpLine
;							xor		ecx,ecx
;							xor		eax,eax
;							.while ecx<edx
;								.if linebuff[ecx]==','
;									inc		eax
;								.endif
;								inc		ecx
;							.endw
;							push	eax
;							;Set tooltip position
;							invoke GetFocus
;							pop		edx
;							invoke ShowToolTip,eax,lpFun,edx
;							mov		fTlt,TRUE
;						.elseif eax
;							;Set listbox position
;							mov		fLB,TRUE
;							invoke GetFocus
;							invoke ShowListBox,eax
;							invoke SendMessage,hLB,LB_SETCURSEL,0,0
;							mov		fTlt,FALSE
;							invoke ShowWindow,hTlt,SW_HIDE
;						.endif
;					.endif
;					pop		edi
;					pop		esi
;				.endif
;			.endif
;		.endif
;		pop		ebx
;	.endif
;	invoke CallWindowProc,OldMdiChildProc,hWin,uMsg,wParam,lParam
;	ret
;
;MdiChildProc endp
;
;#########################################################################
;Common AddIn Procedures

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	mov		eax,hInst
	mov		hInstance,eax
	mov		eax,TRUE
	ret

DllEntry Endp

InstallAddin proc uses ebx hWin:DWORD

	mov		ebx,hWin
	;Get pointer to handles struct
	invoke SendMessage,ebx,AIM_GETHANDLES,0,0;	
	mov		lpHandles,eax
	mov		edx,[eax].ADDINHANDLES.hCC
	mov		hCC,edx
	mov		edx,[eax].ADDINHANDLES.hTT
	mov		hTT,edx
	mov		edx,[eax].ADDINHANDLES.hProperty
	mov		hProperty,edx
	;Get pointer to proc struct
	invoke SendMessage,ebx,AIM_GETPROCS,0,0
	mov		lpProc,eax
	;Get pointer to data struct
	invoke SendMessage,ebx,AIM_GETDATA,0,0	
	mov		lpData,eax
	mov		hook.hook1,HOOK_RASELCHANGE
	xor		eax,eax
	mov		hook.hook2,eax
	mov		hook.hook3,eax
	mov		hook.hook4,eax
	mov		eax,offset hook
	ret 

InstallAddin Endp

IsLineCoInvoke proc uses esi edi,npos:DWORD

	mov		esi,offset linebuff
	mov		edi,offset szCoInvoke
	dec		esi
	mov		ecx,npos
	inc		ecx
  @@:
	dec		ecx
	je		Ex
	inc		esi
	mov		al,[esi]
	cmp		al,VK_SPACE
	je		@b
	cmp		al,VK_TAB
	je		@b
	dec		esi
	dec		edi
	inc		ecx
  @@:
	dec		ecx
	je		Ex
	inc		esi
	inc		edi
	mov		al,[edi]
	mov		ah,[esi]
;	;Not case sensitive
;	.if al>='a' && al<='z'
;		and		al,5Fh
;	.endif
;	.if ah>='a' && ah<='z'
;		and		ah,5Fh
;	.endif
	sub		ah,al
	je		@b
	.if !al && (ah==VK_SPACE || ah==VK_TAB)
		.while byte ptr [esi]==VK_SPACE || byte ptr [esi]==VK_TAB
			inc		esi
		.endw
		mov		eax,esi
	.else
		jmp		Ex
	.endif
	ret
  Ex:
	;Not found
	xor		eax,eax
	ret

IsLineCoInvoke endp

Filter proc lpWord:DWORD,lpTyped:DWORD

	mov		ecx,lpWord
	mov		edx,lpTyped
  @@:
	mov		al,[ecx]
	mov		ah,[edx]
	inc		ecx
	inc		edx
	.if ah && al
		;Not case sensitive
		.if al>='a' && al<='z'
			and		al,5Fh
		.endif
		.if ah>='a' && ah<='z'
			and		ah,5Fh
		.endif
		sub		al,ah
		je		@b
		;Not found
		xor		eax,eax
	.else
		;Found
		mov		eax,edx
	.endif
	ret

Filter endp

AddinProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	pt:POINT
	LOCAL	buffer[256]:BYTE
	LOCAL	nFilter:DWORD
	LOCAL	lpFun:DWORD

	mov		eax,uMsg
	.if eax==AIM_RASELCHANGE
		push	ebx
		push	esi
		push	edi
		mov		ebx,lParam
		.if [ebx].RASELCHANGE.seltyp==SEL_TEXT && [ebx].RASELCHANGE.fchanged
			mov		eax,lpData
			.if [eax].ADDINDATA.cctype==CCTYPE_NONE || [eax].ADDINDATA.cctype==CCTYPE_USER
				;Get the line text
				mov		esi,[ebx].RASELCHANGE.lpLine
				mov		ecx,[esi].CHARS.len
				.if ecx>=sizeof linebuff
					mov		ecx,sizeof linebuff-1
				.endif
				lea		esi,[esi+sizeof CHARS]
				mov		edi,offset linebuff
				rep movsb
				;Zero terminate line
				mov		byte ptr [edi],0
				.if byte ptr [edi-1]==VK_RETURN
					;Dont want CR
					mov		byte ptr [edi-1],0
				.endif
				mov		eax,[ebx].RASELCHANGE.chrg.cpMin
				sub		eax,[ebx].RASELCHANGE.cpLine
				invoke IsLineCoInvoke,eax
				.if eax
					mov		edi,eax
					sub		eax,offset linebuff
					mov		nPos,eax
					invoke SendMessage,hCC,CCM_CLEAR,0,0
					;put some text into listbox
					mov		esi,offset szSomeText
					.while byte ptr [esi]
						invoke Filter,esi,edi
						.if eax
							mov		lpFun,edx
							movzx	eax,byte ptr [eax-1]
							mov		nFilter,eax
							invoke SendMessage,hCC,CCM_ADDITEM,1,esi
						.endif
						invoke lstrlen,esi
						lea		esi,[esi+eax+1]
						invoke lstrlen,esi
						lea		esi,[esi+eax+1]
					.endw
					invoke SendMessage,hCC,CCM_GETCOUNT,0,0
					.if eax==1 && nFilter==','
						;Count commas
						mov		edx,[ebx].RASELCHANGE.chrg.cpMin
						sub		edx,[ebx].RASELCHANGE.cpLine
						xor		ecx,ecx
						xor		eax,eax
						.while ecx<edx
							.if linebuff[ecx]==','
								inc		eax
							.endif
							inc		ecx
						.endw
						push	eax
						;Set tooltip position
						invoke GetFocus
						pop		edx
;						invoke ShowToolTip,eax,lpFun,edx
;						mov		fTlt,TRUE
					.elseif eax
						;Let RadASM show the listbox
						mov		eax,lpData
						mov		[eax].ADDINDATA.cctype,CCTYPE_USER
					.endif
				.endif
			.endif
		.endif
		pop		edi
		pop		esi
		pop		ebx
 	.endif
	xor		eax,eax
  Ex:
	ret

AddinProc Endp

;#########################################################################

End DllEntry

	CoInvoke abitemC,
