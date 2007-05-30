.386
.model flat,stdcall
option casemap:none

include Data.inc
include WordList.asm
include Parse.asm

.code

CreateClass proc
	LOCAL	wc:WNDCLASSEX

	;Create a windowclass for the user control
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW or CS_GLOBALCLASS or CS_PARENTDC or CS_DBLCLKS
	mov		wc.lpfnWndProc,offset ControlProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,4
	push	hInstance
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,NULL
	mov		wc.lpszClassName,offset szClassName
	mov		eax,NULL
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	ret

CreateClass endp

;--------------------------------------------------------------------------------

CreateToolTip proc hWin:HWND
	LOCAL	ti:TOOLINFO

	invoke CreateWindowEx,0,OFFSET szToolTipClass,OFFSET szToolTipClass,TTS_NOPREFIX,0,0,0,0,hWin,0,hInstance,0
	mov		[ebx].RAPROPERTY.htooltip,eax

	invoke SendMessage,[ebx].RAPROPERTY.htooltip,TTM_ACTIVATE,TRUE,0
	invoke SendMessage,[ebx].RAPROPERTY.htooltip,TTM_SETDELAYTIME,TTDT_AUTOMATIC,500
	invoke SendMessage,[ebx].RAPROPERTY.htooltip,TTM_SETMAXTIPWIDTH,0,800

	mov		ti.cbSize,SIZEOF TOOLINFO
	mov		ti.uFlags,TTF_IDISHWND or TTF_SUBCLASS
	mov		eax,hWin
	mov		ti.hWnd,eax
	mov		ti.uId,eax
	mov		eax,hInstance
	mov		ti.hInst,eax
	mov		ti.lpszText,LPSTR_TEXTCALLBACK
	invoke SendMessage,[ebx].RAPROPERTY.htooltip,TTM_ADDTOOL,0,addr ti
	ret

CreateToolTip endp

ListBoxProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	.if uMsg==WM_NOTIFY
		mov		ebx,lParam
		.if [ebx].NMHDR.code==TTN_NEEDTEXT
			mov		szname,0
			invoke SendMessage,hWin,LB_GETTEXT,OldItem,offset szname
			mov		[ebx].TOOLTIPTEXT.lpszText,OFFSET szname
		.endif
	.elseif uMsg==WM_MOUSEMOVE
		invoke SendMessage,hWin,LB_ITEMFROMPOINT,0,lParam
		.IF eax!=OldItem
			mov		OldItem,eax
			invoke GetParent,hWin
			invoke GetWindowLong,eax,0
			mov		ebx,eax
			invoke SendMessage,[ebx].RAPROPERTY.htooltip,TTM_ACTIVATE,FALSE,0
			invoke SendMessage,[ebx].RAPROPERTY.htooltip,TTM_ACTIVATE,TRUE,0
		.endif
	.endif
	invoke CallWindowProc,OldListBoxProc,hWin,uMsg,wParam,lParam
	RET

ListBoxProc endp

;--------------------------------------------------------------------------------

UpdateList proc uses esi,dwType:DWORD
	LOCAL	rapn:RAPNOTIFY

	invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_RESETCONTENT,0,0
	.if [ebx].RAPROPERTY.cbsize
		mov		esi,[ebx].RAPROPERTY.lpmem
		.while [esi].PROPERTIES.nSize
			mov		eax,dwType
			.if al==[esi].PROPERTIES.nType
				mov		edx,[ebx].RAPROPERTY.nOwner
				.if edx==[esi].PROPERTIES.nOwner || !edx
					call	AddItem
				.endif
			.endif
			mov		eax,[esi].PROPERTIES.nSize
			lea		esi,[esi+eax+sizeof PROPERTIES]
		.endw
	.endif
	invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_SETCURSEL,0,0
	xor		eax,eax
	dec		eax
	mov		rapn.nid,eax
	mov		rapn.nline,eax
	mov		eax,[ebx].RAPROPERTY.hwnd
	mov		rapn.nmhdr.hwndFrom,eax
	mov		edx,[ebx].RAPROPERTY.id
	mov		rapn.nmhdr.idFrom,edx
	mov		rapn.nmhdr.code,LBN_SELCHANGE
	invoke SendMessage,[ebx].RAPROPERTY.hpar,WM_NOTIFY,edx,addr rapn
	ret

AddItem:
	.if ah==1
		; Proc
		invoke lstrcpy,addr szname,addr [esi+sizeof PROPERTIES]
		invoke lstrcat,addr szname,addr szLpa
		push	esi
		lea		esi,[esi+sizeof PROPERTIES]
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
		invoke lstrcat,addr szname,esi
		invoke lstrcat,addr szname,addr szRpa
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
		.if byte ptr [esi]
			invoke lstrcat,addr szname,addr szSpc
			invoke lstrcat,addr szname,esi
		.endif
		pop		esi
		invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_ADDSTRING,0,addr szname
	.elseif ah==2
		; Data
		invoke lstrcpy,addr szname,addr [esi+sizeof PROPERTIES]
		invoke lstrcat,addr szname,addr szColon
		push	esi
		lea		esi,[esi+sizeof PROPERTIES]
		invoke lstrlen,esi
		lea		esi,[esi+eax+1]
		invoke lstrcat,addr szname,esi
		pop		esi
		invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_ADDSTRING,0,addr szname
	.else
		invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_ADDSTRING,0,addr [esi+sizeof PROPERTIES]
	.endif
	invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_SETITEMDATA,eax,esi
	retn

UpdateList endp

Find proc uses esi

	mov		esi,[ebx].RAPROPERTY.lpmem
	.if esi
		add		esi,[ebx].RAPROPERTY.rpFindPos
	  @@:
		.if [esi].PROPERTIES.nSize
			call	TestType
			.if eax
				call	TestText
				.if eax
					jmp		Ex
				.endif
			.endif
			mov		eax,[esi].PROPERTIES.nSize
			lea		esi,[esi+eax+sizeof PROPERTIES]
			jmp		@b
		.endif
	.endif
	xor		eax,eax
	ret
  Ex:
	movzx	eax,[esi].PROPERTIES.nType
	mov		[ebx].RAPROPERTY.nfindtype,eax
	mov		eax,[esi].PROPERTIES.nOwner
	mov		[ebx].RAPROPERTY.nfindowner,eax
	mov		eax,[esi].PROPERTIES.nLine
	mov		[ebx].RAPROPERTY.nfindline,eax
	mov		eax,[esi].PROPERTIES.nEnd
	mov		[ebx].RAPROPERTY.nfindendline,eax
	mov		eax,esi
	add		eax,[esi].PROPERTIES.nSize
	add		eax,sizeof PROPERTIES
	sub		eax,[ebx].RAPROPERTY.lpmem
	mov		[ebx].RAPROPERTY.rpFindPos,eax
	mov		eax,esi
	ret

TestType:
	lea		edx,[ebx].RAPROPERTY.szFindTypes
	mov		al,[esi].PROPERTIES.nType
	.while byte ptr [edx]
		.if al==byte ptr [edx]
			retn
		.endif
		inc		edx
	.endw
	xor		eax,eax
	retn

TestText:
	lea		edx,[ebx].RAPROPERTY.szFindText
	lea		ecx,[esi+sizeof PROPERTIES]
	.while byte ptr [edx]
		mov		al,[edx]
		mov		ah,[ecx]
		.if al>='a' && al<='z'
			and		al,5Fh
		.endif
		.if ah>='a' && ah<='z'
			and		ah,5Fh
		.endif
		sub		al,ah
		.if !ZERO?
			xor		eax,eax
			retn
		.endif
		inc		edx
		inc		ecx
	.endw
	mov		eax,TRUE
	retn

Find endp

IsType proc uses edx,lpszTypes:DWORD,nType:DWORD

	mov		edx,lpszTypes
	mov		eax,nType
	.while byte ptr [edx]
		.if al==byte ptr [edx]
			ret
		.endif
		inc		edx
	.endw
	xor		eax,eax
	ret

IsType endp

IsWordType proc uses esi,lpszTypes:DWORD,lpszWord:DWORD,fNoCase:DWORD

	mov		esi,[ebx].RAPROPERTY.lpmem
	.while [esi].PROPERTIES.nSize
		movzx	eax,[esi].PROPERTIES.nType
		invoke IsType,lpszTypes,eax
		.if eax
			call	TestWord
			.if eax
				mov		eax,esi
				jmp		Ex
			.endif
		.endif
		mov		eax,[esi].PROPERTIES.nSize
		lea		esi,[esi+eax+sizeof PROPERTIES]
	.endw
	xor		eax,eax
  Ex:
	ret

TestWord:
	lea		edx,[esi+sizeof PROPERTIES]
	mov		ecx,lpszWord
	.while byte ptr [edx]
		mov		al,[edx]
		mov		ah,[ecx]
		.if fNoCase
			.if al>='a' && al<='z'
				and		al,5Fh
			.endif
			.if ah>='a' && ah<='z'
				and		ah,5Fh
			.endif
		.endif
		sub		al,ah
		.if !ZERO?
			xor		eax,eax
			retn
		.endif
		inc		edx
		inc		ecx
	.endw
	movzx	eax,byte ptr [ecx]
	mov		ecx,[ebx].RAPROPERTY.lpchartab
	.if byte ptr [ecx+eax]==CT_CHAR
		xor		eax,eax
	.else
		mov		eax,TRUE
	.endif
	retn

IsWordType endp

GetToolTip proc uses esi edi,lParam:DWORD,fNoCase:DWORD
	LOCAL	npos:DWORD

	xor		edi,edi
	mov		esi,[ebx].RAPROPERTY.lpchartab
	mov		edx,lParam
	invoke PreParse,[edx].TOOLTIP.lpszLine
	test	fNoCase,TT_PARANTESES
	.if !ZERO?
		mov		edx,lParam
		invoke lstrlen,[edx].TOOLTIP.lpszLine
		mov		edx,lParam
		mov		edx,[edx].TOOLTIP.lpszLine
		dec		eax
		.while eax
			.if byte ptr [edx+eax]==')'
				call	SkipScopeBack
			.elseif byte ptr [edx+eax]=='('
				dec		eax
				.break
			.endif
			dec		eax
		.endw
		call	SkipSpcBack
		.while TRUE
			movzx	ecx,byte ptr [edx+eax]
			.if byte ptr [esi+ecx]!=CT_CHAR
				inc		eax
				.break
			.endif
			.break .if !eax
			dec		eax
		.endw
		lea		eax,[edx+eax]
		mov		edx,lParam
		mov		edx,[edx].TOOLTIP.lpszLine
		invoke lstrcpy,edx,eax
		mov		eax,lParam
		mov		edx,fNoCase
		and		edx,TT_NOMATCHCASE
		invoke IsWordType,[eax].TOOLTIP.lpszType,[eax].TOOLTIP.lpszLine,edx
		.if eax
			mov		edi,eax
			mov		edx,lParam
			mov		edx,[edx].TOOLTIP.lpszLine
			mov		npos,edx
		.endif
	.else
		mov		edx,lParam
		mov		edx,[edx].TOOLTIP.lpszLine
		.while byte ptr [edx]
			movzx	eax,byte ptr [edx]
			.if byte ptr [esi+eax]!=CT_CHAR
				inc		edx
			.else
				push	edx
				mov		ecx,edx
				.while byte ptr [edx]
					movzx	eax,byte ptr [edx]
					.if byte ptr [esi+eax]==CT_CHAR
						inc		edx
					.else
						.break
					.endif
				.endw
				mov		eax,edx
				call	SkipSpc
				mov		edx,eax
				.if byte ptr [edx]=='('
					push	ecx
					xor		ecx,ecx
					.while byte ptr [edx]
						.if byte ptr [edx]==')'
							dec		ecx
						.elseif byte ptr [edx]=='('
							inc		ecx
						.endif
						inc		edx
					.endw
					.if !ecx
						pop		ecx
						jmp		Nxt
					.endif
					pop		ecx
				.endif
				mov		eax,lParam
				push	ecx
				mov		edx,fNoCase
				and		edx,TT_NOMATCHCASE
				invoke IsWordType,[eax].TOOLTIP.lpszType,ecx,edx
				pop		ecx
				.if eax
					mov		edi,eax
					mov		npos,ecx
				.endif
			  Nxt:
				pop		edx
				.while byte ptr [edx]
					movzx	eax,byte ptr [edx]
					.if byte ptr [esi+eax]==CT_CHAR
						inc		edx
					.else
						.break
					.endif
				.endw
			.endif
		.endw
	.endif
	.if edi
		lea		edi,[edi+sizeof PROPERTIES]
		mov		edx,lParam
		mov		[edx].TOOLTIP.lpszApi,edi
		invoke lstrlen,edi
		lea		edi,[edi+eax+1]
		mov		edx,lParam
		mov		[edx].TOOLTIP.lpszParam,edi
		invoke lstrlen,edi
		lea		edi,[edi+eax+1]
		mov		edx,lParam
		mov		[edx].TOOLTIP.lpszRetType,edi
		xor		ecx,ecx
		mov		eax,npos
		.while byte ptr [eax]
			movzx	ecx,byte ptr [eax]
			.if byte ptr [esi+ecx]==CT_CHAR
				inc		eax
			.else
				.break
			.endif
		.endw
		call	SkipSpc
		.if byte ptr [eax]=='(' || byte ptr [eax]==','
			inc		eax
		.endif
		xor		ecx,ecx
		.while byte ptr [eax]
			.if byte ptr [eax]==','
				inc		ecx
			.elseif byte ptr [eax]=='('
				call	SkipScope
			.endif
			inc		eax
		.endw
		mov		edx,lParam
		mov		[edx].TOOLTIP.nPos,ecx
		xor		eax,eax
		inc		eax
	.else
		xor		eax,eax
		mov		edx,lParam
		mov		[edx].TOOLTIP.lpszApi,eax
		mov		[edx].TOOLTIP.lpszParam,eax
		mov		[edx].TOOLTIP.lpszRetType,eax
		mov		[edx].TOOLTIP.nPos,eax
	.endif
	ret

SkipSpc:
	.while byte ptr [eax]==VK_SPACE || byte ptr [eax]==VK_TAB
		inc		eax
	.endw
	retn

SkipScope:
	push	ecx
	xor		ecx,ecx
	.while byte ptr [eax]
		.if byte ptr [eax]=='('
			inc		ecx
		.elseif byte ptr [eax]==')'
			dec		ecx
			.break .if ZERO?
		.endif
		inc		eax
	.endw
	pop		ecx
	retn

SkipSpcBack:
	.while (byte ptr [edx+eax]==VK_SPACE || byte ptr [edx+eax]==VK_TAB) && eax
		dec		eax
	.endw
	retn

SkipScopeBack:
	push	ecx
	xor		ecx,ecx
	.while eax
		.if byte ptr [edx+eax]==')'
			inc		ecx
		.elseif byte ptr [edx+eax]=='('
			dec		ecx
			.break .if ZERO?
		.endif
		dec		eax
	.endw
	.if byte ptr [edx+eax]=='(' && eax
		dec		eax
	.endif
	pop		ecx
	retn

GetToolTip endp

ControlProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT
	LOCAL	rect1:RECT
	LOCAL	ninx:DWORD
	LOCAL	buffer[512]:BYTE
	LOCAL	len:DWORD
	LOCAL	rapn:RAPNOTIFY
	LOCAL	pt:POINT

	mov		eax,uMsg
	.if eax==WM_CREATE
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,sizeof RAPROPERTY
		mov		ebx,eax
		invoke SetWindowLong,hWin,0,ebx
		mov		eax,hWin
		mov		[ebx].RAPROPERTY.hwnd,eax
		invoke GetParent,hWin
		mov		[ebx].RAPROPERTY.hpar,eax
		invoke GetWindowLong,hWin,GWL_ID
		mov		[ebx].RAPROPERTY.id,eax
		invoke ImageList_Create,16,16,ILC_COLOR4 or ILC_MASK,10,0
		mov		[ebx].RAPROPERTY.himl,eax
		invoke LoadBitmap,hInstance,IDB_TRV
		push	eax
		invoke ImageList_AddMasked,[ebx].RAPROPERTY.himl,eax,0FF00FFh
		pop		eax
		invoke DeleteObject,eax
		;Create toolbar
		invoke GetWindowLong,hWin,GWL_STYLE
		push	eax
		mov		edx,WS_CHILD or WS_VISIBLE or TBSTYLE_TOOLTIPS or CCS_NORESIZE
		test	eax,PRSTYLE_FLATTOOLBAR
		.if !ZERO?
			or		edx,TBSTYLE_FLAT
		.endif
		test	eax,PRSTYLE_DIVIDERLINE
		.if ZERO?
			or		edx,CCS_NODIVIDER
		.endif
		invoke CreateWindowEx,0,addr szToolBar,NULL,edx,0,0,0,0,hWin,1001,hInstance,NULL
		mov		[ebx].RAPROPERTY.htbr,eax
		;Set toolbar struct size
		invoke SendMessage,[ebx].RAPROPERTY.htbr,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0
		;Set toolbar buttons
		mov		ecx,offset btnsnopro
		pop		eax
		test	eax,PRSTYLE_PROJECT
		mov		eax,4
		.if !ZERO?
			mov		ecx,offset btnspro
			mov		eax,6
		.endif
		invoke SendMessage,[ebx].RAPROPERTY.htbr,TB_ADDBUTTONS,eax,ecx
		;Set the imagelist
		invoke SendMessage,[ebx].RAPROPERTY.htbr,TB_SETIMAGELIST,0,[ebx].RAPROPERTY.himl
		;Create ComboBox
		invoke CreateWindowEx,0,addr szComboBox,NULL,WS_CHILD or WS_VISIBLE or CBS_DROPDOWNLIST or CBS_HASSTRINGS,0,0,0,0,hWin,1002,hInstance,NULL
		mov		[ebx].RAPROPERTY.hcbo,eax
		;Create ListBox
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,addr szListBox,NULL,WS_CHILD or WS_VISIBLE or WS_VSCROLL or LBS_SORT or LBS_NOINTEGRALHEIGHT or LBS_HASSTRINGS or LBS_NOTIFY or LBS_OWNERDRAWFIXED,0,0,0,0,hWin,1003,hInstance,NULL
		mov		[ebx].RAPROPERTY.hlst,eax
		invoke SetWindowLong,[ebx].RAPROPERTY.hlst,GWL_WNDPROC,offset ListBoxProc
		mov		OldListBoxProc,eax
		;Current open files
		mov		[ebx].RAPROPERTY.nButton,1
		mov		[ebx].RAPROPERTY.backcolor,0FFFFFFh
		mov		[ebx].RAPROPERTY.textcolor,0
		mov		[ebx].RAPROPERTY.oprcolor,0FFh
		invoke GetStockObject,WHITE_BRUSH
		mov		[ebx].RAPROPERTY.hbrback,eax
		invoke CreateToolTip,[ebx].RAPROPERTY.hlst
	.elseif eax==WM_DRAWITEM
		push	esi
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		esi,lParam
		assume esi:ptr DRAWITEMSTRUCT
		invoke SendMessage,[esi].hwndItem,LB_GETTEXT,[esi].itemID,addr szname
		.if eax!=LB_ERR
			invoke lstrlen,addr szname
			mov		len,eax
			test	[esi].itemState,ODS_SELECTED
			.if ZERO?
				push	1
				push	[ebx].RAPROPERTY.backcolor
				mov		eax,[ebx].RAPROPERTY.textcolor
			.else
				push	0
				invoke GetSysColor,COLOR_HIGHLIGHT
				push	eax
				invoke GetSysColor,COLOR_HIGHLIGHTTEXT
			.endif
			invoke SetTextColor,[esi].hdc,eax
			pop		eax
			invoke SetBkColor,[esi].hdc,eax
			invoke ExtTextOut,[esi].hdc,0,0,ETO_OPAQUE,addr [esi].rcItem,NULL,0,NULL
			pop		eax
			push	[esi].rcItem.left
			add		[esi].rcItem.left,3
			.if eax
				push	edi
				mov		edi,offset szname
				xor		ecx,ecx
				.while byte ptr [edi]
					xor		ecx,ecx
					.while byte ptr [edi+ecx]!='(' && byte ptr [edi+ecx]!=')' && byte ptr [edi+ecx]!=',' && byte ptr [edi+ecx]!=':' && byte ptr [edi+ecx]!=0
						inc		ecx
					.endw
					.if ecx
						push	ecx
						push	ecx
						mov		rect.left,0
						mov		rect.top,0
						invoke DrawText,[esi].hdc,edi,ecx,addr rect,DT_CALCRECT or DT_SINGLELINE
						pop		ecx
						invoke TextOut,[esi].hdc,[esi].rcItem.left,[esi].rcItem.top,edi,ecx
						mov		eax,rect.right
						add		[esi].rcItem.left,eax
						pop		ecx
						lea		edi,[edi+ecx]
					.elseif byte ptr [edi]
						mov		rect.left,0
						mov		rect.top,0
						invoke DrawText,[esi].hdc,edi,1,addr rect,DT_CALCRECT or DT_SINGLELINE
						invoke SetTextColor,[esi].hdc,[ebx].RAPROPERTY.oprcolor
						invoke TextOut,[esi].hdc,[esi].rcItem.left,[esi].rcItem.top,edi,1
						invoke SetTextColor,[esi].hdc,[ebx].RAPROPERTY.textcolor
						mov		eax,rect.right
						add		[esi].rcItem.left,eax
						inc		edi
					.endif
				.endw
				pop		edi
			.else
				invoke TextOut,[esi].hdc,[esi].rcItem.left,[esi].rcItem.top,offset szname,len
			.endif
			pop		[esi].rcItem.left
			assume esi:nothing
			pop		esi
		.else
			pop		esi
			xor		eax,eax
			jmp		Ex
		.endif
	.elseif eax==WM_COMMAND
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			;ToolBar button clicked
			;1 Current file
			;2 All open files
			;3 Selected project file
			;4 All project files
			;5 Refresh
			mov		rapn.nid,eax
			.if eax<5
				mov		[ebx].RAPROPERTY.nButton,eax
			.endif
			mov		rapn.nline,0
			mov		eax,hWin
			mov		rapn.nmhdr.hwndFrom,eax
			mov		edx,[ebx].RAPROPERTY.id
			mov		rapn.nmhdr.idFrom,edx
			mov		rapn.nmhdr.code,BN_CLICKED
			invoke SendMessage,[ebx].RAPROPERTY.hpar,WM_NOTIFY,edx,addr rapn
		.else
			.if edx==CBN_SELCHANGE && eax==1002
				invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_GETCURSEL,0,0
				invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_GETITEMDATA,eax,0
				invoke UpdateList,eax
			.elseif edx==LBN_SELCHANGE && eax==1003
				;Selchange
				invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_GETCURSEL,0,0
				.if eax!=LB_ERR
					invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_GETITEMDATA,eax,0
					mov		edx,[eax].PROPERTIES.nOwner
					mov		rapn.nid,edx
					mov		edx,[eax].PROPERTIES.nLine
					mov		rapn.nline,edx
				.else
					xor		eax,eax
					dec		eax
					mov		rapn.nid,eax
					mov		rapn.nline,eax
				.endif
				mov		eax,hWin
				mov		rapn.nmhdr.hwndFrom,eax
				mov		edx,[ebx].RAPROPERTY.id
				mov		rapn.nmhdr.idFrom,edx
				mov		rapn.nmhdr.code,LBN_SELCHANGE
				invoke SendMessage,[ebx].RAPROPERTY.hpar,WM_NOTIFY,edx,addr rapn
			.elseif edx==LBN_DBLCLK && eax==1003
				;Dblclick
				invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_GETCURSEL,0,0
				.if eax!=LB_ERR
					invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_GETITEMDATA,eax,0
					mov		edx,[eax].PROPERTIES.nOwner
					mov		rapn.nid,edx
					mov		edx,[eax].PROPERTIES.nLine
					mov		rapn.nline,edx
					mov		eax,hWin
					mov		rapn.nmhdr.hwndFrom,eax
					mov		edx,[ebx].RAPROPERTY.id
					mov		rapn.nmhdr.idFrom,edx
					mov		rapn.nmhdr.code,LBN_DBLCLK
					invoke SendMessage,[ebx].RAPROPERTY.hpar,WM_NOTIFY,edx,addr rapn
				.endif
			.endif
		.endif
	.elseif eax==WM_NOTIFY
		mov		edx,lParam
		.if [edx].NMHDR.code==TTN_NEEDTEXT
			mov		edx,[edx].NMHDR.idFrom
			invoke LoadString,hInstance,edx,addr buffer,sizeof buffer
			lea		eax,buffer
			mov		edx,lParam
			mov		[edx].TOOLTIPTEXT.lpszText,eax
		.endif
	.elseif eax==WM_SIZE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		push	edi
		invoke GetWindowLong,hWin,GWL_STYLE
		mov		edi,28
		test	eax,PRSTYLE_FLATTOOLBAR
		.if !ZERO?
			sub		edi,4
		.endif
		test	eax,PRSTYLE_DIVIDERLINE
		.if ZERO?
			sub		edi,2
		.endif
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,[ebx].RAPROPERTY.htbr,0,0,rect.right,edi,TRUE
		invoke MoveWindow,[ebx].RAPROPERTY.hcbo,0,edi,rect.right,200,TRUE
		invoke GetClientRect,[ebx].RAPROPERTY.hcbo,addr rect1
		add		edi,rect1.bottom
		mov		edx,rect.bottom
		sub		edx,edi
		invoke MoveWindow,[ebx].RAPROPERTY.hlst,0,edi,rect.right,edx,TRUE
		pop		edi
	.elseif eax==WM_DESTROY
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke DeleteObject,[ebx].RAPROPERTY.hbrback
		.if [ebx].RAPROPERTY.cbsize
			invoke GlobalUnlock,[ebx].RAPROPERTY.hmem
			invoke GlobalFree,[ebx].RAPROPERTY.hmem
		.endif
		.if [ebx].RAPROPERTY.lpignore
			invoke GlobalFree,[ebx].RAPROPERTY.lpignore
		.endif
		.if [ebx].RAPROPERTY.lpdeftype
			invoke GlobalFree,[ebx].RAPROPERTY.lpdeftype
		.endif
		invoke GlobalFree,ebx
	.elseif eax==WM_SETFONT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		mov		[ebx].RAPROPERTY.hfont,eax
		invoke SendMessage,[ebx].RAPROPERTY.hcbo,WM_SETFONT,[ebx].RAPROPERTY.hfont,FALSE
		invoke SendMessage,[ebx].RAPROPERTY.hlst,WM_SETFONT,[ebx].RAPROPERTY.hfont,FALSE
		.if lParam
			invoke InvalidateRect,hWin,NULL,TRUE
			invoke InvalidateRect,[ebx].RAPROPERTY.hcbo,NULL,TRUE
			invoke InvalidateRect,[ebx].RAPROPERTY.hlst,NULL,TRUE
		.endif
	.elseif eax==PRM_SELECTPROPERTY
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		ninx,0
		.while TRUE
			invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_GETITEMDATA,ninx,0
			.break .if eax==CB_ERR
			.if eax==wParam
				invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_SETCURSEL,ninx,0
				.break
			.endif
			inc		ninx
		.endw
		invoke UpdateList,wParam
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_ADDPROPERTYTYPE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_ADDSTRING,0,lParam
		invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_SETITEMDATA,eax,wParam
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_ADDPROPERTYFILE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		movzx	edx,al
		shr		eax,8
		.if !eax
			mov		eax,2
		.endif
		invoke AddFileToWordList,edx,lParam,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_SETGENDEF
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		push	esi
		mov		esi,lParam
		invoke lstrcpy,addr [ebx].RAPROPERTY.defgen.szCmntBlockSt,addr [esi].DEFGEN.szCmntBlockSt
		invoke lstrcpy,addr [ebx].RAPROPERTY.defgen.szCmntBlockEn,addr [esi].DEFGEN.szCmntBlockEn
		invoke lstrcpy,addr [ebx].RAPROPERTY.defgen.szCmntChar,addr [esi].DEFGEN.szCmntChar
		invoke lstrcpy,addr [ebx].RAPROPERTY.defgen.szString,addr [esi].DEFGEN.szString
		invoke lstrcpy,addr [ebx].RAPROPERTY.defgen.szLineCont,addr [esi].DEFGEN.szLineCont
;lea		eax,[ebx].RAPROPERTY.defgen.szCmntBlockSt
;PrintStringByAddr eax
;lea		eax,[ebx].RAPROPERTY.defgen.szCmntBlockEn
;PrintStringByAddr eax
;lea		eax,[ebx].RAPROPERTY.defgen.szCmntChar
;PrintStringByAddr eax
;lea		eax,[ebx].RAPROPERTY.defgen.szString
;PrintStringByAddr eax
;lea		eax,[ebx].RAPROPERTY.defgen.szLineCont
;PrintStringByAddr eax
		pop		esi
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_ADDIGNORE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		.if ![ebx].RAPROPERTY.lpignore
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4*1024
			mov		[ebx].RAPROPERTY.lpignore,eax
		.endif
		push	esi
		mov		esi,[ebx].RAPROPERTY.lpignore
		add		esi,[ebx].RAPROPERTY.rpignorefree
		mov		eax,wParam
		mov		[esi],al
		inc		esi
		invoke lstrlen,lParam
		push	eax
		mov		[esi],al
		inc		esi
		invoke lstrcpy,esi,lParam
		pop		eax
		add		eax,3
		add		[ebx].RAPROPERTY.rpignorefree,eax
		pop		esi
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_ADDDEFTYPE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		.if ![ebx].RAPROPERTY.lpdeftype
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,32*1024
			mov		[ebx].RAPROPERTY.lpdeftype,eax
		.endif
		mov		edx,[ebx].RAPROPERTY.lpdeftype
		add		edx,[ebx].RAPROPERTY.rpfreedeftype
		invoke RtlMoveMemory,edx,lParam,sizeof DEFTYPE
		add		[ebx].RAPROPERTY.rpfreedeftype,sizeof DEFTYPE
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_PARSEFILE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke PreParse,lParam
		invoke ParseFile,wParam,lParam
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_SETCHARTAB
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,lParam
		mov		[ebx].RAPROPERTY.lpchartab,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_DELPROPERTY
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke DeleteProperties,wParam
		invoke CompactProperties
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_REFRESHLIST
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_GETCURSEL,0,0
		invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_GETITEMDATA,eax,0
		invoke UpdateList,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_SELOWNER
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		mov		[ebx].RAPROPERTY.nOwner,eax
		invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_GETCURSEL,0,0
		invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_GETITEMDATA,eax,0
		invoke UpdateList,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_GETSELBUTTON
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RAPROPERTY.nButton
		jmp		Ex
	.elseif eax==PRM_SETSELBUTTON
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SendMessage,[ebx].RAPROPERTY.htbr,TB_CHECKBUTTON,[ebx].RAPROPERTY.nButton,FALSE
		mov		eax,wParam
		mov		[ebx].RAPROPERTY.nButton,eax
		invoke SendMessage,[ebx].RAPROPERTY.htbr,TB_CHECKBUTTON,[ebx].RAPROPERTY.nButton,TRUE
		invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_GETCURSEL,0,0
		invoke SendMessage,[ebx].RAPROPERTY.hcbo,CB_GETITEMDATA,eax,0
		invoke UpdateList,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_FINDFIRST
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke lstrcpyn,addr [ebx].RAPROPERTY.szFindTypes,wParam,sizeof RAPROPERTY.szFindTypes
		invoke lstrcpyn,addr [ebx].RAPROPERTY.szFindText,lParam,sizeof RAPROPERTY.szFindText
		mov		[ebx].RAPROPERTY.rpFindPos,0
		invoke Find
		.if eax
			lea		eax,[eax+sizeof PROPERTIES]
		.endif
		jmp		Ex
	.elseif eax==PRM_FINDNEXT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke Find
		.if eax
			lea		eax,[eax+sizeof PROPERTIES]
		.endif
		jmp		Ex
	.elseif eax==PRM_FINDGETTYPE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RAPROPERTY.nfindtype
		jmp		Ex
	.elseif eax==PRM_GETWORD
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,lParam
		mov		ecx,wParam
		push	esi
		mov		esi,[ebx].RAPROPERTY.lpchartab
		.while ecx
			dec		ecx
			movzx	eax,byte ptr [edx+ecx]
			.if byte ptr [esi+eax]!=CT_CHAR
				inc		ecx
				.break
			.endif
		.endw
		xor		esi,esi
		.while ecx<wParam
			mov		al,[edx+ecx]
			mov		[edx+esi],al
			inc		ecx
			inc		esi
		.endw
		mov		byte ptr [edx+esi],0
		pop		esi
		jmp		Ex
	.elseif eax==PRM_GETSTRUCTWORD
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke DestroyCommentsStrings,lParam
		mov		edx,lParam
		mov		ecx,wParam
		push	esi
		push	edi
		mov		esi,[ebx].RAPROPERTY.lpchartab
		xor		ebx,ebx
		.while ecx
			dec		ecx
			movzx	eax,byte ptr [edx+ecx]
			.if eax=='.'
				.if !ebx
					mov		ebx,ecx
				.endif
			.elseif word ptr [edx+ecx-1]=='>-'
				dec		ecx
				.if !ebx
					mov		ebx,ecx
				.endif
			.elseif byte ptr [edx+ecx]==')'
				xor		edi,edi
				.while ecx
					mov		al,[edx+ecx]
					dec		ecx
					.if al==')'
						inc		edi
					.elseif al=='('
						dec		edi
						.break .if ZERO?
					.endif
				.endw
			.elseif byte ptr [esi+eax]!=CT_CHAR
				inc		ecx
				.break
			.endif
		.endw
		xor		esi,esi
		.while ecx<ebx
		  @@:
			mov		ax,[edx+ecx]
			.if al=='.'
				xor		eax,eax
			.elseif ax=='>-'
				xor		eax,eax
				inc		ecx
			.elseif al=='('
				.while ecx<ebx
					mov		al,[edx+ecx]
					inc		ecx
					.if al=='('
						inc		edi
					.elseif al==')'
						dec		edi
						.break .if ZERO?
					.endif
				.endw
				jmp		@b
			.endif
			mov		[edx+esi],al
			inc		ecx
			inc		esi
		.endw
		mov		word ptr [edx+esi],0
		pop		edi
		pop		esi
		jmp		Ex
	.elseif eax==PRM_FINDITEMDATATYPE
		mov		edx,lParam
		.while byte ptr [edx]
			mov		ebx,edx
			mov		ecx,wParam
			.while byte ptr [ecx]
				mov		al,[ecx]
				cmp		al,[edx]
				jne		@f
				inc		ecx
				inc		edx
			.endw
			mov		ecx,wParam
			.if byte ptr [edx]==':'
				inc		edx
				.while byte ptr [edx] && byte ptr [edx]!=',' && byte ptr [edx]!=' '
					mov		al,[edx]
					mov		[ecx],al
					inc		ecx
					inc		edx
				.endw
				mov		byte ptr [ecx],0
				jmp		Ex
			.endif
		  @@:
			mov		edx,ebx
			call	SkipToComma
		.endw
		mov		ecx,wParam
		mov		byte ptr [ecx],0
		jmp		Ex
	.elseif eax==PRM_GETTOOLTIP
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke GetToolTip,lParam,wParam
		jmp		Ex
	.elseif eax==PRM_SETBACKCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke DeleteObject,[ebx].RAPROPERTY.hbrback
		mov		eax,lParam
		mov		[ebx].RAPROPERTY.backcolor,eax
		invoke CreateSolidBrush,eax
		mov		[ebx].RAPROPERTY.hbrback,eax
		invoke InvalidateRect,[ebx].RAPROPERTY.hcbo,NULL,TRUE
		invoke InvalidateRect,[ebx].RAPROPERTY.hlst,NULL,TRUE
		jmp		Ex
	.elseif eax==PRM_GETBACKCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RAPROPERTY.backcolor
		jmp		Ex
	.elseif eax==PRM_SETTEXTCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,lParam
		mov		[ebx].RAPROPERTY.textcolor,eax
		invoke InvalidateRect,[ebx].RAPROPERTY.hcbo,NULL,TRUE
		invoke InvalidateRect,[ebx].RAPROPERTY.hlst,NULL,TRUE
		jmp		Ex
	.elseif eax==PRM_GETTEXTCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RAPROPERTY.textcolor
		jmp		Ex
	.elseif eax==PRM_SETOPRCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,lParam
		mov		[ebx].RAPROPERTY.oprcolor,eax
		invoke InvalidateRect,[ebx].RAPROPERTY.hcbo,NULL,TRUE
		invoke InvalidateRect,[ebx].RAPROPERTY.hlst,NULL,TRUE
		jmp		Ex
	.elseif eax==PRM_GETOPRCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RAPROPERTY.oprcolor
		jmp		Ex
	.elseif eax==PRM_ISINPROC
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,[ebx].RAPROPERTY.lpmem
		add		edx,[ebx].RAPROPERTY.rpproject
		mov		ecx,lParam
		.while [edx].PROPERTIES.nSize
			mov		eax,[ecx].ISINPROC.nOwner
			.if eax==[edx].PROPERTIES.nOwner
				movzx	eax,[edx].PROPERTIES.nType
				invoke IsType,[ecx].ISINPROC.lpszType,eax
				.if eax
					mov		eax,[ecx].ISINPROC.nLine
					.if eax>=[edx].PROPERTIES.nLine && eax<=[edx].PROPERTIES.nEnd
						; Found
						lea		eax,[edx+sizeof PROPERTIES]
						jmp		Ex
					.endif
				.endif
			.endif
			mov		eax,[edx].PROPERTIES.nSize
			lea		edx,[edx+eax+sizeof PROPERTIES]
		.endw
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_MEMSEARCH
		mov		ebx,lParam
		xor		ecx,ecx
		xor		edx,edx
		mov		eax,[ebx].MEMSEARCH.fr
		test	eax,FR_MATCHCASE
		.if !ZERO?
			inc		ecx
		.endif
		test	eax,FR_WHOLEWORD
		.if !ZERO?
			inc		edx
		.endif
		test	eax,FR_DOWN
		.if !ZERO?
			invoke SearchMemDown,[ebx].MEMSEARCH.lpMem,[ebx].MEMSEARCH.lpFind,ecx,edx,[ebx].MEMSEARCH.lpCharTab
		.else
			invoke SearchMemUp,[ebx].MEMSEARCH.lpMem,[ebx].MEMSEARCH.lpFind,ecx,edx,[ebx].MEMSEARCH.lpCharTab
		.endif
		jmp		Ex
	.elseif eax==PRM_FINDGETOWNER
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RAPROPERTY.nfindowner
		jmp		Ex
	.elseif eax==PRM_FINDGETLINE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RAPROPERTY.nfindline
		jmp		Ex
	.elseif eax==PRM_FINDGETENDLINE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RAPROPERTY.nfindendline
		jmp		Ex
	.elseif eax==PRM_ISINWITHBLOCK
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,[ebx].RAPROPERTY.lpdeftype
		mov		ecx,[ebx].RAPROPERTY.rpfreedeftype
		lea		ecx,[ecx+edx]
		.while edx<ecx
			.if [edx].DEFTYPE.nDefType==DEFTYPE_WITHBLOCK
				movzx	eax,[edx].DEFTYPE.Def
				mov		edx,[ebx].RAPROPERTY.lpmem
				add		edx,[ebx].RAPROPERTY.rpproject
				.while [edx].PROPERTIES.nSize
					mov		ecx,wParam
					.if al==[edx].PROPERTIES.nType && ecx==[edx].PROPERTIES.nOwner
						mov		ecx,lParam
						.if ecx>=[edx].PROPERTIES.nLine && ecx<=[edx].PROPERTIES.nEnd
							; Found
							lea		eax,[edx+sizeof PROPERTIES]
							jmp		Ex
						.endif
					.endif
					mov		ecx,[edx].PROPERTIES.nSize
					lea		edx,[edx+ecx+sizeof PROPERTIES]
				.endw
				.break
			.endif
			add		edx,sizeof DEFTYPE
		.endw
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_ADDISWORD
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		.if ![ebx].RAPROPERTY.lpisword
			invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,4*1024
			mov		[ebx].RAPROPERTY.lpisword,eax
		.endif
		push	esi
		mov		esi,[ebx].RAPROPERTY.lpisword
		add		esi,[ebx].RAPROPERTY.rpiswordfree
		mov		eax,wParam
		mov		[esi],al
		inc		esi
		invoke lstrlen,lParam
		push	eax
		mov		[esi],al
		inc		esi
		invoke lstrcpy,esi,lParam
		pop		eax
		add		eax,3
		add		[ebx].RAPROPERTY.rpiswordfree,eax
		pop		esi
		xor		eax,eax
		jmp		Ex
	.elseif eax==PRM_CLEARWORDLIST
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		.if [ebx].RAPROPERTY.hmem
			invoke GlobalFree,[ebx].RAPROPERTY.hmem
		.endif
		xor		eax,eax
		mov		[ebx].RAPROPERTY.hmem,eax
		mov		[ebx].RAPROPERTY.lpmem,eax
		mov		[ebx].RAPROPERTY.cbsize,eax
		mov		[ebx].RAPROPERTY.rpproject,eax
		mov		[ebx].RAPROPERTY.rpfree,eax
		jmp		Ex
	.elseif eax==PRM_GETSTRUCTSTART
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke DestroyCommentsStrings,lParam
		mov		edx,lParam
		mov		ecx,wParam
		push	esi
		mov		esi,[ebx].RAPROPERTY.lpchartab
		.while ecx
			dec		ecx
			movzx	eax,byte ptr [edx+ecx]
			.if eax=='.'
			.elseif word ptr [edx+ecx-1]=='>-'
				dec		ecx
			.elseif byte ptr [edx+ecx]==')'
				xor		edi,edi
				.while ecx
					mov		al,[edx+ecx]
					dec		ecx
					.if al==')'
						inc		edi
					.elseif al=='('
						dec		edi
						.break .if ZERO?
					.endif
				.endw
			.elseif byte ptr [esi+eax]!=CT_CHAR
				inc		ecx
				.break
			.endif
		.endw
		xor		esi,esi
		.while byte ptr [edx+ecx]
			mov		al,[edx+ecx]
			mov		[edx+esi],al
			inc		ecx
			inc		esi
		.endw
		mov		word ptr [edx+esi],0
		pop		esi
		jmp		Ex
	.elseif eax==PRM_GETCURSEL
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_GETCURSEL,0,0
		jmp		Ex
	.elseif eax==PRM_GETSELTEXT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_GETCURSEL,0,0
		.if eax!=LB_ERR
			invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_GETTEXT,eax,lParam
		.endif
		jmp		Ex
	.elseif eax==WM_CTLCOLOREDIT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SetTextColor,wParam,[ebx].RAPROPERTY.textcolor
		invoke SetBkColor,wParam,[ebx].RAPROPERTY.backcolor
		mov		eax,[ebx].RAPROPERTY.hbrback
		ret
	.elseif eax==WM_CTLCOLORLISTBOX
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SetTextColor,wParam,[ebx].RAPROPERTY.textcolor
		invoke SetBkColor,wParam,[ebx].RAPROPERTY.backcolor
		mov		eax,[ebx].RAPROPERTY.hbrback
		ret
	.elseif eax==WM_SETREDRAW
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SendMessage,[ebx].RAPROPERTY.hlst,WM_SETREDRAW,wParam,lParam
		.if wParam==TRUE
			invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_SETTOPINDEX,[ebx].RAPROPERTY.topindex,0
			invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_SETCURSEL,[ebx].RAPROPERTY.selindex,0
			invoke InvalidateRect,[ebx].RAPROPERTY.hlst,NULL,TRUE
		.else
			invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_GETTOPINDEX,0,0
			mov		[ebx].RAPROPERTY.topindex,eax
			invoke SendMessage,[ebx].RAPROPERTY.hlst,LB_GETCURSEL,0,0
			mov		[ebx].RAPROPERTY.selindex,eax
		.endif
		jmp		Ex
	.elseif eax==WM_CONTEXTMENU
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke GetCursorPos,addr pt
;		invoke ScreenToClient,[ebx].RAPROPERTY.hpar,addr pt
		mov		eax,pt.x
		mov		edx,pt.y
		shl		edx,16
		or		edx,eax
		invoke SendMessage,[ebx].RAPROPERTY.hpar,WM_CONTEXTMENU,hWin,edx
		xor		eax,eax
		jmp		Ex
	.endif
	invoke DefWindowProc,hWin,uMsg,wParam,lParam
  Ex:
	ret

SkipToComma:
	.while byte ptr [edx] && byte ptr [edx]!=','
		inc		edx
	.endw
	.if byte ptr [edx]==','
		inc		edx
	.endif
	retn

ControlProc endp

include Dll.asm

