; Custom control containing listbox and tooltip designed
; to handle code complete (intellisense).
;
; Normal build to create the dll
; Debug build to create the lib
;
; KetilO (C) 2005

.386
.model flat,stdcall
option casemap:none
option proc:private

include windows.inc
include ..\RACodeComplete.inc
include Data.inc
include Sort.asm

IDB_TYPES		equ 101

.code

InstallRACodeComplete proc public hInst:HINSTANCE
	LOCAL	wc:WNDCLASSEX

	;Create a windowclass for the listbox control
	mov		wc.cbSize,sizeof WNDCLASSEX
IFDEF DLL
	mov		wc.style,CS_HREDRAW or CS_VREDRAW or CS_GLOBALCLASS or CS_PARENTDC or CS_DBLCLKS
ELSE
	mov		wc.style,CS_HREDRAW or CS_VREDRAW or CS_PARENTDC or CS_DBLCLKS
ENDIF
	mov		wc.lpfnWndProc,offset CodeCompleteProc
	mov		eax,NULL
	mov		wc.cbClsExtra,eax
	mov		wc.cbWndExtra,4
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,eax
	mov		wc.lpszMenuName,eax
	mov		wc.lpszClassName,offset szCCLBClassName
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc

	;Create a windowclass for the tooltip control
IFDEF DLL
	mov		wc.style,CS_HREDRAW or CS_VREDRAW or CS_GLOBALCLASS or CS_PARENTDC
ELSE
	mov		wc.style,CS_HREDRAW or CS_VREDRAW or CS_PARENTDC
ENDIF
	mov		wc.lpfnWndProc,offset ToolTipProc
	mov		wc.lpszClassName,offset szCCTTClassName
	mov		wc.hCursor,NULL
	invoke RegisterClassEx,addr wc
	ret

InstallRACodeComplete endp

;--------------------------------------------------------------------------------

CompareStr proc lpStr1:DWORD,lpStr2:DWORD

	mov		ecx,lpStr1
	mov		edx,lpStr2
  @@:
	mov		al,[ecx]
	.if al
		mov		ah,[edx]
		inc		ecx
		inc		edx
		.if al>='a' && al<='z'
			sub		al,20h
		.endif
		.if ah>='a' && ah<='z'
			sub		ah,20h
		.endif
		sub		al,ah
		je		@b
	.endif
	movsx	eax,al
	ret

CompareStr endp

CodeCompleteProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	pt:POINT
	LOCAL	rect:RECT
	LOCAL	sinf:SCROLLINFO
	LOCAL	ninx:DWORD

	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		call	SetScroll
		invoke BeginPaint,hWin,addr ps
		mov		eax,[ebx].RACC.backcolor
		.if sdword ptr eax<0
			and		eax,7FFFFFFFh
			invoke GetSysColor,eax
		.endif
		invoke CreateSolidBrush,eax
		push	eax
		invoke FillRect,ps.hdc,addr ps.rcPaint,eax
		pop		eax
		invoke DeleteObject,eax
		invoke SetBkMode,ps.hdc,TRANSPARENT
		invoke SelectObject,ps.hdc,[ebx].RACC.hfont
		push	eax
		mov		ecx,[ebx].RACC.topindex
		mov		pt.y,0
		mov		edx,[ebx].RACC.lpmem
		.while ecx<[ebx].RACC.count
			mov		eax,pt.y
			.break .if eax>ps.rcPaint.bottom
			add		eax,[ebx].RACC.itemheight
			.if eax>ps.rcPaint.top
				push	ecx
				push	edx
				mov		eax,[edx+ecx*8+4]
				mov		ninx,eax
				mov		edx,[edx+ecx*8]
				push	edx
				.if ecx==[ebx].RACC.cursel
					mov		eax,pt.y
					mov		rect.top,eax
					add		eax,[ebx].RACC.itemheight
					mov		rect.bottom,eax
					invoke GetSysColor,COLOR_HIGHLIGHT
					invoke CreateSolidBrush,eax
					push	eax
					invoke FillRect,ps.hdc,addr rect,eax
					pop		eax
					invoke DeleteObject,eax
					invoke GetFocus
					.if eax==hWin
						invoke SetTextColor,ps.hdc,0
						invoke DrawFocusRect,ps.hdc,addr rect
					.endif
					invoke GetSysColor,COLOR_HIGHLIGHTTEXT
					invoke SetTextColor,ps.hdc,eax
				.else
					mov		eax,[ebx].RACC.textcolor
					.if sdword ptr eax<0
						and		eax,7FFFFFFFh
						invoke GetSysColor,eax
					.endif
					invoke SetTextColor,ps.hdc,eax
				.endif
				pop		edx
				push	edx
				invoke lstrlen,edx
				pop		edx
				test	[ebx].RACC.style,STYLE_USEIMAGELIST
				.if ZERO?
					invoke TextOut,ps.hdc,1,pt.y,edx,eax
				.else
					invoke TextOut,ps.hdc,19,pt.y,edx,eax
					invoke ImageList_Draw,[ebx].RACC.himl,ninx,ps.hdc,1,pt.y,ILD_NORMAL
				.endif
				pop		edx
				pop		ecx
			.endif
			mov		eax,[ebx].RACC.itemheight
			add		pt.y,eax
			inc		ecx
		.endw
		pop		eax
		invoke SelectObject,ps.hdc,eax
		invoke EndPaint,hWin,addr ps
		xor		eax,eax
	.elseif eax==WM_CREATE
		invoke GetProcessHeap
		invoke HeapAlloc,eax,HEAP_ZERO_MEMORY,sizeof RACC
		mov		ebx,eax
		invoke SetWindowLong,hWin,0,ebx
		mov		[ebx].RACC.cbsize,1024*32
		invoke GlobalAlloc,GMEM_MOVEABLE,[ebx].RACC.cbsize
		mov		[ebx].RACC.hmem,eax
		invoke GlobalLock,[ebx].RACC.hmem
		mov		[ebx].RACC.lpmem,eax
		mov		[ebx].RACC.cursel,-1
		mov		[ebx].RACC.backcolor,80000000h or COLOR_WINDOW
		mov		[ebx].RACC.textcolor,80000000h or COLOR_WINDOWTEXT
		invoke GetWindowLong,hWin,GWL_STYLE
		mov		[ebx].RACC.style,eax
		mov		[ebx].RACC.fredraw,TRUE
		mov		[ebx].RACC.itemheight,16
		;Create imagelist for property types
		.if !hInstance
			invoke GetModuleHandle,NULL
			mov		hInstance,eax
		.endif
		invoke ImageList_Create,16,16,ILC_MASK or ILC_COLOR8,16,0
		mov		[ebx].RACC.himl,eax
		invoke LoadBitmap,hInstance,IDB_TYPES
		push	eax
		invoke ImageList_AddMasked,[ebx].RACC.himl,eax,0FF00FFh
		pop		eax
		invoke DeleteObject,eax
		xor		eax,eax
	.elseif eax==WM_DESTROY
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke GlobalUnlock,[ebx].RACC.hmem
		invoke GlobalFree,[ebx].RACC.hmem
		invoke ImageList_Destroy,[ebx].RACC.himl
		invoke GetProcessHeap
		invoke HeapFree,eax,0,ebx
		xor		eax,eax
	.elseif eax==CCM_ADDITEM
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		ecx,[ebx].RACC.count
		lea		eax,[ecx*8]
		.if eax>=[ebx].RACC.cbsize
			invoke GlobalUnlock,[ebx].RACC.hmem
			add		[ebx].RACC.cbsize,1024*32
			invoke GlobalReAlloc,[ebx].RACC.hmem,[ebx].RACC.cbsize,GMEM_MOVEABLE
			mov		[ebx].RACC.hmem,eax
			invoke GlobalLock,[ebx].RACC.hmem
			mov		[ebx].RACC.lpmem,eax
			mov		ecx,[ebx].RACC.count
		.endif
		mov		edx,[ebx].RACC.lpmem
		mov		eax,lParam
		mov		[edx+ecx*8],eax
		mov		eax,wParam
		mov		[edx+ecx*8+4],eax
		inc		ecx
		mov		[ebx].RACC.count,ecx
		.if [ebx].RACC.fredraw
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==CCM_ADDLIST
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		push	esi
		push	edi
		mov		edx,lParam
		mov		esi,[edx].CC_ADDLIST.lpszList
	  @@:
		mov		edi,esi
		.while byte ptr [esi]!=',' && byte ptr [esi]
			inc		esi
		.endw
		.if byte ptr [esi]==','
			mov		byte ptr [esi],0
			inc		esi
			mov		edx,lParam
			invoke CompareStr,[edx].CC_ADDLIST.lpszFilter,edi
			.if !eax
				mov		edx,lParam
				invoke SendMessage,hWin,CCM_ADDITEM,[edx].CC_ADDLIST.nType,edi
			.endif
			jmp		@b
		.endif
		invoke lstrlen,edi
		.if eax
			mov		edx,lParam
			invoke CompareStr,[edx].CC_ADDLIST.lpszFilter,edi
			.if !eax
				mov		edx,lParam
				invoke SendMessage,hWin,CCM_ADDITEM,[edx].CC_ADDLIST.nType,edi
			.endif
		.endif
		pop		edi
		pop		esi
		.if [ebx].RACC.fredraw
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==CCM_DELITEM
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		.if eax<[ebx].RACC.count
			mov		edx,[ebx].RACC.lpmem
			.while eax<[ebx].RACC.count
				mov		ecx,[edx+eax*8+8]
				mov		[edx+eax*8],ecx
				mov		ecx,[edx+eax*8+8+4]
				mov		[edx+eax*8+4],ecx
				inc		eax
			.endw
			dec		[ebx].RACC.count
			.if [ebx].RACC.fredraw
				invoke InvalidateRect,hWin,NULL,TRUE
			.endif
		.endif
		xor		eax,eax
	.elseif eax==CCM_GETITEM
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		.if eax<[ebx].RACC.count
			mov		edx,[ebx].RACC.lpmem
			mov		eax,[edx+eax*8]
		.else
			xor		eax,eax
		.endif
	.elseif eax==CCM_GETCOUNT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RACC.count
	.elseif eax==CCM_GETMAXWIDTH
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		push		esi
		push		edi
		xor		esi,esi
		xor		edi,edi
		.while esi<[ebx].RACC.count
			mov		edx,[ebx].RACC.lpmem
			mov		eax,[edx+esi*8]
			invoke		lstrlen,eax
			.if eax>edi
				mov		edi,eax
			.endif
			inc		esi
		.endw
		mov		eax,edi
		pop		edi
		pop		esi		
	.elseif eax==CCM_CLEAR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		mov		[ebx].RACC.count,eax
		mov		[ebx].RACC.topindex,eax
		dec		eax
		mov		[ebx].RACC.cursel,eax
		.if [ebx].RACC.fredraw
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==CCM_SETCURSEL
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		.if [ebx].RACC.fredraw
			invoke SendMessage,hWin,CCM_GETITEMRECT,[ebx].RACC.cursel,addr ps.rcPaint
			invoke InvalidateRect,hWin,addr ps.rcPaint,TRUE
		.endif
		mov		eax,wParam
		.if eax<[ebx].RACC.count
			mov		[ebx].RACC.cursel,eax
			.if [ebx].RACC.fredraw
				invoke SendMessage,hWin,CCM_GETITEMRECT,[ebx].RACC.cursel,addr ps.rcPaint
				invoke InvalidateRect,hWin,addr ps.rcPaint,TRUE
			.endif
		.else
			mov		[ebx].RACC.cursel,-1
		.endif
		xor		eax,eax
	.elseif eax==CCM_GETCURSEL
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RACC.cursel
	.elseif eax==CCM_GETTOPINDEX
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RACC.topindex
	.elseif eax==CCM_SETTOPINDEX
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		.if eax>=[ebx].RACC.count
			mov		eax,[ebx].RACC.count
			.if eax
				dec		eax
			.endif
		.endif
		mov		[ebx].RACC.topindex,eax
		.if [ebx].RACC.fredraw
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==CCM_GETITEMRECT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke GetClientRect,hWin,addr rect
		mov		edx,lParam
		mov		[edx].RECT.left,0
		mov		eax,rect.right
		mov		[edx].RECT.right,eax
		mov		eax,wParam
		sub		eax,[ebx].RACC.topindex
		mov		ecx,[ebx].RACC.itemheight
		mul		ecx
		mov		edx,lParam
		mov		[edx].RECT.top,eax
		add		eax,ecx
		mov		[edx].RECT.bottom,eax
		xor		eax,eax
	.elseif eax==CCM_SETVISIBLE
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke SendMessage,hWin,CCM_GETITEMRECT,[ebx].RACC.cursel,addr ps.rcPaint
		invoke GetClientRect,hWin,addr rect
		mov		eax,ps.rcPaint.top
		mov		edx,ps.rcPaint.bottom
		.if sdword ptr eax<0
			mov		eax,[ebx].RACC.cursel
			.if eax<[ebx].RACC.count
				mov		[ebx].RACC.topindex,eax
			.endif
		.elseif edx>rect.bottom
			mov		eax,rect.bottom
			mov		ecx,[ebx].RACC.itemheight
			xor		edx,edx
			div		ecx
			dec		eax
			mov		edx,[ebx].RACC.cursel
			sub		edx,eax
			.if CARRY?
				xor		edx,edx
			.endif
			mov		[ebx].RACC.topindex,edx
		.endif
		.if [ebx].RACC.fredraw
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==CCM_FINDSTRING
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		ecx,wParam
		inc		ecx
		.while ecx<[ebx].RACC.count
			push	ecx
			mov		edx,[ebx].RACC.lpmem
			mov		edx,[edx+ecx*8]
			invoke CompareStr,lParam,edx
			pop		ecx
			or		eax,eax
			je		@f
			inc		ecx
		.endw
		mov		ecx,-1
	  @@:
		mov		eax,ecx
	.elseif eax==CCM_SORT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,[ebx].RACC.count
		.if eax
			dec		eax
			invoke QuickSort,[ebx].RACC.lpmem,0,eax,wParam
			.if [ebx].RACC.fredraw
				invoke InvalidateRect,hWin,NULL,TRUE
			.endif
		.endif
		xor		eax,eax
	.elseif eax==CCM_GETCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,lParam
		mov		eax,[ebx].RACC.backcolor
		mov		[edx].CC_COLOR.back,eax
		mov		eax,[ebx].RACC.textcolor
		mov		[edx].CC_COLOR.text,eax
		xor		eax,eax
	.elseif eax==CCM_SETCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,lParam
		mov		eax,[edx].CC_COLOR.back
		mov		[ebx].RACC.backcolor,eax
		mov		eax,[edx].CC_COLOR.text
		mov		[ebx].RACC.textcolor,eax
		.if [ebx].RACC.fredraw
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_SETFONT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		mov		[ebx].RACC.hfont,eax
		invoke GetDC,hWin
		mov		ps.hdc,eax
		invoke SelectObject,ps.hdc,[ebx].RACC.hfont
		push	eax
		mov		pt.x,'a'
		invoke GetTextExtentPoint32,ps.hdc,addr pt,1,addr pt
		pop		eax
		invoke SelectObject,ps.hdc,eax
		invoke ReleaseDC,hWin,ps.hdc
		mov		eax,pt.y
		inc		eax
		mov		[ebx].RACC.itemheight,eax
		.if lParam
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_LBUTTONDOWN
		invoke SetFocus,hWin
		invoke SetCapture,hWin
		invoke PostMessage,hWin,WM_MOUSEMOVE,wParam,lParam
		xor		eax,eax
	.elseif eax==WM_MOUSEMOVE
		invoke GetCapture
		.if eax==hWin
			invoke GetWindowLong,hWin,0
			mov		ebx,eax
			invoke GetClientRect,hWin,addr rect
			mov		eax,rect.bottom
			mov		ecx,[ebx].RACC.itemheight
			xor		edx,edx
			div		ecx
			push	eax
			mul		ecx
			mov		rect.bottom,eax
			mov		eax,lParam
			shr		eax,16
			cwde
			pop		edx
			.if sdword ptr eax<0
				mov		eax,[ebx].RACC.topindex
				.if eax
					dec		eax
					mov		[ebx].RACC.topindex,eax
					mov		[ebx].RACC.cursel,eax
					invoke InvalidateRect,hWin,NULL,TRUE
				.endif
			.elseif eax>=rect.bottom
				mov		eax,[ebx].RACC.topindex
				add		eax,edx
				.if eax<[ebx].RACC.count
					inc		[ebx].RACC.topindex
					mov		[ebx].RACC.cursel,eax
					invoke InvalidateRect,hWin,NULL,TRUE
				.endif
			.else
				mov		ecx,[ebx].RACC.itemheight
				xor		edx,edx
				idiv	ecx
				add		eax,[ebx].RACC.topindex
				.if eax<[ebx].RACC.count && eax!=[ebx].RACC.cursel
					push	eax
					invoke SendMessage,hWin,CCM_GETITEMRECT,[ebx].RACC.cursel,addr rect
					pop		[ebx].RACC.cursel
					invoke InvalidateRect,hWin,addr rect,TRUE
					invoke SendMessage,hWin,CCM_GETITEMRECT,[ebx].RACC.cursel,addr rect
					invoke InvalidateRect,hWin,addr rect,TRUE
				.endif
			.endif
		.endif
		xor		eax,eax
	.elseif eax==WM_SETFOCUS
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,[ebx].RACC.cursel
		.if sdword ptr edx>=0
			invoke SendMessage,hWin,CCM_GETITEMRECT,edx,addr rect
			invoke InvalidateRect,hWin,addr rect,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_KILLFOCUS
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,[ebx].RACC.cursel
		.if sdword ptr edx>=0
			invoke SendMessage,hWin,CCM_GETITEMRECT,edx,addr rect
			invoke InvalidateRect,hWin,addr rect,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_LBUTTONUP
		invoke GetCapture
		.if eax==hWin
			invoke ReleaseCapture
		.endif
		xor		eax,eax
	.elseif eax==WM_KEYDOWN
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		.if [ebx].RACC.count
			invoke GetClientRect,hWin,addr rect
			mov		edx,wParam
			mov		eax,lParam
			shr		eax,16
			and		eax,3FFh
			mov		ecx,[ebx].RACC.cursel
			.if edx==28h && (eax==150h || eax==50h)
				;Down
				inc		ecx
				.if ecx<[ebx].RACC.count
					mov		[ebx].RACC.cursel,ecx
					invoke SendMessage,hWin,CCM_SETVISIBLE,0,0
				.endif
			.elseif edx==26h && (eax==148h || eax==48h)
				;Up
				.if ecx && ecx<[ebx].RACC.count
					dec		ecx
					mov		[ebx].RACC.cursel,ecx
					invoke SendMessage,hWin,CCM_SETVISIBLE,0,0
				.endif
			.elseif edx==21h && (eax==149h || eax==49h)
				;PgUp
				mov		eax,rect.bottom
				mov		ecx,[ebx].RACC.itemheight
				xor		edx,edx
				div		ecx
				mov		ecx,eax
				mov		eax,[ebx].RACC.cursel
				sub		eax,ecx
				.if CARRY?
					xor		eax,eax
				.endif
				mov		[ebx].RACC.cursel,eax
				invoke SendMessage,hWin,CCM_SETVISIBLE,0,0
			.elseif edx==22h && (eax==151h || eax==51h)
				;PgDn
				mov		eax,rect.bottom
				mov		ecx,[ebx].RACC.itemheight
				xor		edx,edx
				div		ecx
				add		eax,[ebx].RACC.cursel
				.if eax>=[ebx].RACC.count
					mov		eax,[ebx].RACC.count
					dec		eax
				.endif
				mov		[ebx].RACC.cursel,eax
				invoke SendMessage,hWin,CCM_SETVISIBLE,0,0
			.elseif edx==24h && (eax==147h || eax==47h)
				;Home
				mov		[ebx].RACC.cursel,0
				invoke SendMessage,hWin,CCM_SETVISIBLE,0,0
			.elseif edx==23h && (eax==14Fh || eax==4Fh)
				;End
				mov		eax,[ebx].RACC.count
				dec		eax
				mov		[ebx].RACC.cursel,eax
				invoke SendMessage,hWin,CCM_SETVISIBLE,0,0
			.endif
		.endif
		xor		eax,eax
	.elseif eax==WM_CHAR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke GetTickCount
		mov		edx,eax
		sub		eax,findtime
		mov		findtime,edx
		.if eax>1000
			xor		eax,eax
		.else
			invoke lstrlen,offset findbuff
		.endif
		mov		edx,wParam
		mov		word ptr findbuff[eax],dx
		invoke SendMessage,hWin,CCM_FINDSTRING,-1,offset findbuff
		.if eax!=-1
			invoke SendMessage,hWin,CCM_SETCURSEL,eax,0
			invoke SendMessage,hWin,CCM_SETVISIBLE,0,0
		.else
			invoke lstrlen,offset findbuff
			.if eax==2
				mov		ax,word ptr findbuff
				.if al==ah
					mov		findbuff[1],0
					invoke SendMessage,hWin,CCM_FINDSTRING,[ebx].RACC.cursel,offset findbuff
					.if eax!=-1
						invoke SendMessage,hWin,CCM_SETCURSEL,eax,0
						invoke SendMessage,hWin,CCM_SETVISIBLE,0,0
					.endif
				.endif
			.endif
		.endif
		xor		eax,eax
	.elseif eax==WM_VSCROLL
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		sinf.cbSize,sizeof sinf
		mov		sinf.fMask,SIF_ALL
		invoke GetScrollInfo,hWin,SB_VERT,addr sinf
		mov		eax,[ebx].RACC.topindex
		mov		edx,wParam
		movzx	edx,dx
		.if edx==SB_THUMBTRACK || edx==SB_THUMBPOSITION
			mov		eax,sinf.nTrackPos
		.elseif edx==SB_LINEDOWN
			inc		eax
			mov		edx,sinf.nMax
			sub		edx,sinf.nPage
			inc		edx
			.if eax>edx
				mov		eax,edx
			.endif
		.elseif edx==SB_LINEUP
			.if eax
				dec		eax
			.endif
		.elseif edx==SB_PAGEDOWN
			add		eax,sinf.nPage
			mov		edx,sinf.nMax
			sub		edx,sinf.nPage
			inc		edx
			.if eax>edx
				mov		eax,edx
			.endif
		.elseif edx==SB_PAGEUP
			sub		eax,sinf.nPage
			jnb		@f
			xor		eax,eax
		  @@:
		.elseif edx==SB_BOTTOM
			mov		eax,sinf.nMax
		.elseif edx==SB_TOP
			xor		eax,eax
		.endif
		.if eax!=sinf.nPos
			mov		sinf.nPos,eax
			mov		[ebx].RACC.topindex,eax
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.elseif eax==WM_GETDLGCODE
		mov		eax,DLGC_CODE
	.elseif eax==WM_SETREDRAW
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		mov		eax,wParam
		mov		[ebx].RACC.fredraw,eax
		.if eax
			call	SetScroll
			invoke InvalidateRect,hWin,NULL,TRUE
		.endif
		xor		eax,eax
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret

SetScroll:
	invoke GetClientRect,hWin,addr rect
	.if rect.right && rect.bottom
		mov		sinf.cbSize,sizeof sinf
		mov		sinf.fMask,SIF_ALL
		mov		eax,rect.bottom
		cdq
		mov		ecx,[ebx].RACC.itemheight
		div		ecx
		mov		sinf.nPage,eax
		mov		sinf.nMin,0
		mov		eax,[ebx].RACC.count
		.if eax
			dec		eax
		.endif
		mov		sinf.nMax,eax
		mov		eax,[ebx].RACC.topindex
		mov		sinf.nPos,eax
		invoke SetScrollInfo,hWin,SB_VERT,addr sinf,TRUE
	.endif
	retn

CodeCompleteProc endp

ToolTipProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ps:PAINTSTRUCT
	LOCAL	rect:RECT
	LOCAL	rgt:DWORD
	LOCAL	style:DWORD

	mov		eax,uMsg
	.if eax==WM_PAINT
		invoke BeginPaint,hWin,addr ps
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke GetWindowLong,hWin,GWL_STYLE
		mov		style,eax
		invoke SelectObject,ps.hdc,[ebx].RATT.hfont
		push	eax
		invoke CreateSolidBrush,[ebx].RATT.backcolor
		push	eax
		invoke FillRect,ps.hdc,addr ps.rcPaint,eax
		pop		eax
		invoke DeleteObject,eax
		invoke SetBkMode,ps.hdc,TRANSPARENT
		xor		eax,eax
		mov		rect.left,1
		mov		rect.top,eax
		mov		rect.right,eax
		mov		rect.bottom,eax
		.if [ebx].RATT.tti.lpszApi
			invoke SetTextColor,ps.hdc,[ebx].RATT.apicolor
			invoke DrawText,ps.hdc,[ebx].RATT.tti.lpszApi,-1,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
			invoke DrawText,ps.hdc,[ebx].RATT.tti.lpszApi,-1,addr rect,DT_SINGLELINE or DT_LEFT
			mov		eax,rect.right
			mov		rect.left,eax
			invoke SetTextColor,ps.hdc,[ebx].RATT.textcolor
			test	style,STYLE_USEPARANTESES
			.if ZERO?
				mov		rgt,','
			.else
				mov		rgt,'('
			.endif
			invoke DrawText,ps.hdc,addr rgt,1,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
			invoke DrawText,ps.hdc,addr rgt,1,addr rect,DT_SINGLELINE or DT_LEFT
			mov		eax,rect.right
			mov		rect.left,eax
			mov		rgt,eax
			.if [ebx].RATT.tti.lpszParam
				invoke SetTextColor,ps.hdc,[ebx].RATT.textcolor
				invoke DrawText,ps.hdc,[ebx].RATT.tti.lpszParam,-1,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
				invoke DrawText,ps.hdc,[ebx].RATT.tti.lpszParam,-1,addr rect,DT_SINGLELINE or DT_LEFT
				.if [ebx].RATT.nlen
					invoke SetTextColor,ps.hdc,[ebx].RATT.hilitecolor
					.if [ebx].RATT.nleft
						invoke DrawText,ps.hdc,[ebx].RATT.tti.lpszParam,[ebx].RATT.nleft,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
					.else
						mov		eax,rect.left
						mov		rect.right,eax
					.endif
					mov		edx,[ebx].RATT.tti.lpszParam
					add		edx,[ebx].RATT.nleft
					invoke TextOut,ps.hdc,rect.right,0,edx,[ebx].RATT.nlen
				.endif
			.endif
			test	style,STYLE_USEPARANTESES
			.if !ZERO?
				invoke SetTextColor,ps.hdc,[ebx].RATT.textcolor
				mov		eax,rgt
				mov		rect.left,eax
				invoke DrawText,ps.hdc,[ebx].RATT.tti.lpszParam,-1,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
				mov		eax,rect.right
				mov		rect.left,eax
				mov		rgt,')'
				invoke DrawText,ps.hdc,addr rgt,1,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
				invoke DrawText,ps.hdc,addr rgt,1,addr rect,DT_SINGLELINE or DT_LEFT
			.endif
		.endif
		pop		eax
		invoke SelectObject,ps.hdc,eax
		invoke EndPaint,hWin,addr ps
		xor		eax,eax
	.elseif eax==WM_CREATE
		invoke GetProcessHeap
		invoke HeapAlloc,eax,HEAP_ZERO_MEMORY,sizeof RATT
		mov		ebx,eax
		invoke SetWindowLong,hWin,0,ebx
		mov		[ebx].RATT.backcolor,0C0FFFFh
		mov		[ebx].RATT.textcolor,0
		mov		[ebx].RATT.apicolor,60h
		mov		[ebx].RATT.hilitecolor,0C00000h
		xor		eax,eax
	.elseif eax==WM_SETFONT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		eax,wParam
		mov		[ebx].RATT.hfont,eax
		xor		eax,eax
	.elseif eax==WM_ACTIVATE
		xor		eax,eax
	.elseif eax==WM_MOUSEACTIVATE
		mov		eax,MA_NOACTIVATE
	.elseif eax==WM_SETCURSOR
		xor		eax,eax
	.elseif eax==TTM_SETITEM
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke GetWindowLong,hWin,GWL_STYLE
		mov		style,eax
		mov		edx,lParam
		mov		eax,[edx].TTITEM.lpszApi
		mov		[ebx].RATT.tti.lpszApi,eax
		mov		eax,[edx].TTITEM.lpszParam
		mov		[ebx].RATT.tti.lpszParam,eax
		mov		eax,[edx].TTITEM.nitem
		mov		[ebx].RATT.tti.nitem,eax
		mov		edx,[ebx].RATT.tti.lpszParam
		mov		ecx,[ebx].RATT.tti.nitem
		.if !ecx
			.while byte ptr [edx]!=',' && byte ptr [edx]
				inc		edx
			.endw
			mov		[ebx].RATT.nleft,0
			mov		eax,edx
			sub		eax,[ebx].RATT.tti.lpszParam
			mov		[ebx].RATT.nlen,eax
		.else
			.while ecx
				.while byte ptr [edx]!=',' && byte ptr [edx]
					inc		edx
				.endw
				.if byte ptr [edx]==','
					inc		edx
				.endif
				dec		ecx
				.break .if !byte ptr [edx]
			.endw
			mov		eax,edx
			sub		eax,[ebx].RATT.tti.lpszParam
			mov		[ebx].RATT.nleft,eax
			.while byte ptr [edx]!=',' && byte ptr [edx]
				inc		edx
			.endw
			mov		eax,edx
			sub		eax,[ebx].RATT.tti.lpszParam
			sub		eax,[ebx].RATT.nleft
			mov		[ebx].RATT.nlen,eax
		.endif
		invoke GetDC,hWin
		mov		ps.hdc,eax
		invoke SelectObject,ps.hdc,[ebx].RATT.hfont
		push	eax
		xor		eax,eax
		mov		rect.left,eax
		mov		rect.top,eax
		mov		rect.right,eax
		mov		rect.bottom,eax
		.if [ebx].RATT.tti.lpszApi
			invoke DrawText,ps.hdc,[ebx].RATT.tti.lpszApi,-1,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
			mov		eax,rect.right
			mov		rect.left,eax
			test	style,STYLE_USEPARANTESES
			.if ZERO?
				mov		rgt,','
			.else
				mov		rgt,'('
			.endif
			invoke DrawText,ps.hdc,addr rgt,1,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
			mov		eax,rect.right
			mov		rect.left,eax
		.endif
		.if [ebx].RATT.tti.lpszParam && [ebx].RATT.nleft
			invoke DrawText,ps.hdc,[ebx].RATT.tti.lpszParam,[ebx].RATT.nleft,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
		.endif
		mov		eax,rect.right
		mov		rgt,eax
		.if [ebx].RATT.tti.lpszParam
			invoke DrawText,ps.hdc,[ebx].RATT.tti.lpszParam,-1,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
			test	style,STYLE_USEPARANTESES
			.if !ZERO?
				push	rgt
				mov		eax,rect.right
				mov		rect.left,eax
				mov		rgt,')'
				invoke DrawText,ps.hdc,addr rgt,1,addr rect,DT_CALCRECT or DT_SINGLELINE or DT_LEFT
				pop		rgt
			.endif
			add		rect.right,4
			add		rect.bottom,3
		.endif
		pop		eax
		invoke SelectObject,ps.hdc,eax
		invoke ReleaseDC,hWin,ps.hdc
		invoke SetWindowPos,hWin,0,0,0,rect.right,rect.bottom,SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOZORDER
		mov		eax,rgt
	.elseif eax==TTM_GETCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,lParam
		mov		eax,[ebx].RATT.backcolor
		mov		[edx].TT_COLOR.back,eax
		mov		eax,[ebx].RATT.textcolor
		mov		[edx].TT_COLOR.text,eax
		mov		eax,[ebx].RATT.apicolor
		mov		[edx].TT_COLOR.api,eax
		mov		eax,[ebx].RATT.hilitecolor
		mov		[edx].TT_COLOR.hilite,eax
		xor		eax,eax
	.elseif eax==TTM_SETCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		edx,lParam
		mov		eax,[edx].TT_COLOR.back
		mov		[ebx].RATT.backcolor,eax
		mov		eax,[edx].TT_COLOR.text
		mov		[ebx].RATT.textcolor,eax
		mov		eax,[edx].TT_COLOR.api
		mov		[ebx].RATT.apicolor,eax
		mov		eax,[edx].TT_COLOR.hilite
		mov		[ebx].RATT.hilitecolor,eax
		invoke InvalidateRect,hWin,NULL,TRUE
		xor		eax,eax
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
	.endif
	ret

ToolTipProc endp

IFDEF DLL
	include RACodeCompleteDll.asm
ENDIF

End
