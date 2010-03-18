.386
.model flat,stdcall
option casemap:none

include Data.inc
include ..\RAProject.inc

.code

InstallProjectBrowser proc public hInst:HINSTANCE,fGlobal:DWORD
	LOCAL	wc:WNDCLASSEX

	;Create a windowclass for the user control
	mov		wc.cbSize,sizeof WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW or CS_DBLCLKS
	.if fGlobal
		mov		wc.style,CS_HREDRAW or CS_VREDRAW or CS_GLOBALCLASS or CS_DBLCLKS
	.endif
	mov		wc.lpfnWndProc,offset ControlProc
	mov		eax,hInst
	mov		hInstance,eax
	mov		wc.hInstance,eax
	mov		eax,NULL
	mov		wc.cbClsExtra,eax
	mov		wc.cbWndExtra,4
	mov		wc.hbrBackground,eax
	mov		wc.lpszMenuName,eax
	mov		wc.lpszClassName,offset szPBClassName
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	ret

InstallProjectBrowser endp

UnInstallProjectBrowser proc public

	ret

UnInstallProjectBrowser endp

;--------------------------------------------------------------------------------

ProjectTreeViewProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	FileName[MAX_PATH]:BYTE
	LOCAL	lpht:TV_HITTESTINFO
	LOCAL	lptvi:TV_ITEMEX
	LOCAL	hTvi:HWND
	LOCAL	rect:RECT

	mov		eax,uMsg
;	.if	eax==WM_LBUTTONDBLCLK
;		invoke GetParent,hWin
;		invoke GetWindowLong,eax,0
;		mov		ebx,eax
;		invoke GetWindowLong,hWin,GWL_USERDATA
;		invoke CallWindowProc,eax,hWin,uMsg,wParam,lParam
;		push	eax
;		mov		eax,lParam
;		and		eax,0FFFFh
;		mov		lpht.pt.x,eax
;		mov		eax,lParam
;		shr		eax,16
;		mov		lpht.pt.y,eax
;		invoke SendMessage,hWin,TVM_HITTEST,0,addr lpht
;		.if	eax
;			mov		hTvi,eax
;			mov		eax,lpht.flags
;			and		eax,TVHT_ONITEM
;			.if	eax
;				m2m		lptvi.hItem,lpht.hItem
;				mov		lptvi.imask,TVIF_PARAM or TVIF_TEXT	or TVIF_IMAGE
;				lea		eax,buffer
;				mov		lptvi.pszText,eax
;				mov		lptvi.cchTextMax,sizeof	buffer
;				invoke SendMessage,hWin,TVM_GETITEM,0,addr lptvi
;				.if	lptvi.lParam
;					mov		eax,lptvi.iImage
;					.if	eax==1
;						invoke lstrlen,addr [ebx].FILEBROWSER.filepath
;						.if byte ptr [ebx].FILEBROWSER.filepath[eax-1]!='\'
;							invoke lstrcat,addr [ebx].FILEBROWSER.filepath,offset szBackSlash
;						.endif
;						invoke lstrcat,addr [ebx].FILEBROWSER.filepath,addr	buffer
;						invoke FileDir,hWin,addr [ebx].FILEBROWSER.filepath,[ebx].FILEBROWSER.ffilter
;						invoke GetParent,hWin
;						mov		edx,eax
;						invoke Notify,edx,FBN_PATHCHANGE,addr [ebx].FILEBROWSER.filepath
;					.elseif	eax>=2 && eax<=7
;						invoke lstrcpy,addr FileName,addr [ebx].FILEBROWSER.filepath
;						invoke lstrlen,addr [ebx].FILEBROWSER.filepath
;						.if byte ptr FileName[eax-1]!='\'
;							invoke lstrcat,addr FileName,offset szBackSlash
;						.endif
;						invoke lstrcat,addr FileName,addr buffer
;						invoke GetParent,hWin
;						mov		edx,eax
;						invoke Notify,edx,FBN_DBLCLICK,addr FileName
;					.endif
;				.else
;					.if [ebx].FILEBROWSER.fdrives
;					  @@:
;						invoke SendMessage,hWin,TVM_GETNEXTITEM,TVGN_ROOT,0
;						.if eax
;							invoke SendMessage,hWin,TVM_DELETEITEM,0,eax
;							jmp	@b
;						.endif
;						invoke lstrcpy,addr [ebx].FILEBROWSER.filepath,addr	buffer
;						mov		[ebx].FILEBROWSER.fdrives,FALSE
;						invoke FileDir,hWin,addr [ebx].FILEBROWSER.filepath,[ebx].FILEBROWSER.ffilter
;						invoke GetParent,hWin
;						mov		edx,eax
;						invoke Notify,edx,FBN_PATHCHANGE,addr [ebx].FILEBROWSER.filepath
;					.endif
;				.endif
;			.endif
;		.endif
;		pop		eax
;		xor		eax,eax
;		jmp		Ex
	.if	eax==WM_RBUTTONDOWN
;		invoke GetParent,hWin
;		invoke GetWindowLong,eax,0
;		mov		ebx,eax
;		mov		eax,lParam
;		and		eax,0FFFFh
;		mov		lpht.pt.x,eax
;		mov		eax,lParam
;		shr		eax,16
;		mov		lpht.pt.y,eax
;		invoke SendMessage,hWin,TVM_HITTEST,0,addr lpht
;		.if	eax
;			mov		hTvi,eax
;			mov		eax,lpht.flags
;			and		eax,TVHT_ONITEM
;			.if	eax
;				invoke SendMessage,hWin,TVM_SELECTITEM,TVGN_CARET,hTvi
;			.endif
;		.endif
;		invoke SetFocus,hWin
		xor		eax,eax
		jmp		Ex
	.elseif	eax==WM_CHAR
;		mov		eax,wParam
;		.if	eax==VK_SPACE
;			invoke SendMessage,hWin,TVM_GETNEXTITEM,TVGN_CARET,0
;			mov		dword ptr rect,eax
;			invoke SendMessage,hWin,TVM_GETITEMRECT,TRUE,addr rect
;			mov		eax,rect.top
;			shl		eax,16
;			add		eax,rect.left
;			invoke SendMessage,hWin,WM_LBUTTONDBLCLK,0,eax
;			xor		eax,eax
;			jmp		Ex
;		.elseif	eax=='\'
;			invoke GetParent,hWin
;			invoke GetWindowLong,eax,0
;			mov		ebx,eax
;			invoke RStripString,addr [ebx].FILEBROWSER.filepath,'\'
;			invoke TestPath,addr [ebx].FILEBROWSER.filepath
;			invoke FileDir,hWin,addr [ebx].FILEBROWSER.filepath,[ebx].FILEBROWSER.ffilter
;			invoke GetParent,hWin
;			mov		edx,eax
;			invoke Notify,edx,FBN_PATHCHANGE,addr [ebx].FILEBROWSER.filepath
;			xor		eax,eax
;			jmp		Ex
;		.endif
	.endif
	invoke GetWindowLong,hWin,GWL_USERDATA
	invoke CallWindowProc,eax,hWin,uMsg,wParam,lParam
  Ex:
	ret

ProjectTreeViewProc endp

xInString proc lpStr:DWORD,lpSrc:DWORD
	LOCAL	buffer[256]:BYTE

	push	esi
	push	edi
	mov		esi,lpSrc
	lea		edi,buffer
InStr0:
	mov		al,[esi]
	cmp		al,'a'
	jl		@f
	cmp		al,'z'
	jg		@f
	and		al,5Fh
  @@:
	mov		[edi],al
	inc		esi
	inc		edi
	or		al,al
	jne		InStr0
	mov		edi,lpStr
	dec		edi
InStr1:
	inc		edi
	push	edi
	lea		esi,buffer
InStr2:
	mov		ah,[esi]
	or		ah,ah
	je		Found
	mov		al,[edi]
	or		al,al
	je		NotFound
	cmp		al,'a'
	jl		@f
	cmp		al,'z'
	jg		@f
	and		al,5Fh
  @@:
	inc		esi
	inc		edi
	cmp		al,ah
	jz		InStr2
	pop		edi
	jmp		InStr1
Found:
	pop		eax
	sub		eax,lpStr
	pop		edi
	pop		esi
	ret
NotFound:
	pop		edi
	mov		eax,-1
	pop		edi
	pop		esi
	ret

xInString endp

ExpandAll proc hTrv:HWND,hItem:DWORD

  @@:
	invoke SendMessage,hTrv,TVM_EXPAND,TVE_EXPAND,hItem
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_CHILD,hItem
	.if eax
		invoke ExpandAll,hTrv,eax
	.endif
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_NEXT,hItem
	.if eax
		mov		hItem,eax
		jmp		@b
	.endif
	ret

ExpandAll endp

CollapseAll proc hTrv:HWND,hItem:DWORD

  @@:
	invoke SendMessage,hTrv,TVM_EXPAND,TVE_COLLAPSE,hItem
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_CHILD,hItem
	.if eax
		invoke CollapseAll,hTrv,eax
	.endif
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_NEXT,hItem
	.if eax
		mov		hItem,eax
		jmp		@b
	.endif
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_ROOT,0
	invoke SendMessage,hTrv,TVM_EXPAND,TVE_EXPAND,eax
	ret

CollapseAll endp

FindParentGroup proc hTrv:HWND,hItem:DWORD,nGroup:DWORD
	LOCAL	tvi:TVITEM

  @@:
	mov		tvi._mask,TVIF_PARAM
	mov		eax,hItem
	mov		tvi.hItem,eax
	invoke SendMessage,hTrv,TVM_GETITEM,0,addr tvi
	mov		edx,nGroup
	mov		eax,tvi.lParam
	.if edx==[eax].PBITEM.id
		mov		eax,hItem
		ret
	.endif
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_CHILD,hItem
	.if eax
		invoke FindParentGroup,hTrv,eax,nGroup
		.if eax
			ret
		.endif
	.endif
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_NEXT,hItem
	.if eax
		mov		hItem,eax
		jmp		@b
	.endif
	xor		eax,eax
	ret

FindParentGroup endp

FindFileExt proc uses ebx esi edi,lpPROJECTBROWSER:DWORD,lpszFile:DWORD
	LOCAL	buffer[64]:BYTE

	mov		esi,lpszFile
	invoke lstrlen,esi
	.while eax
		dec		eax
	  .break .if byte ptr [esi+eax]=='.'
	.endw
	.if	eax
		invoke lstrcpyn,addr buffer,addr [esi+eax],sizeof buffer
		invoke lstrlen,addr buffer
		mov		word ptr buffer[eax],'.'
		mov		ebx,lpPROJECTBROWSER
		mov		edi,[ebx].PROJECTBROWSER.hmemfileext
		.while [edi].PBFILEEXT.id
			invoke xInString,addr [edi].PBFILEEXT.szfileext,addr buffer
			.if eax!=-1
				mov		eax,[edi].PBFILEEXT.id
				ret
			.endif
			lea		edi,[edi+sizeof PBFILEEXT]
		.endw
	.endif
	xor		eax,eax
	ret

FindFileExt endp

AddGroups proc uses ebx esi edi,lpPROJECTBROWSER:DWORD
	LOCAL	tvis:TV_INSERTSTRUCT
	LOCAL	tvi:TV_ITEM

	mov		ebx,lpPROJECTBROWSER
	mov		esi,[ebx].PROJECTBROWSER.hmemitems
	invoke RtlZeroMemory,addr tvis,sizeof TV_INSERTSTRUCT
	invoke SendMessage,[ebx].PROJECTBROWSER.htrv,TVM_DELETEITEM,0,TVI_ROOT
	.while [esi].PBITEM.id
		.if sdword ptr [esi].PBITEM.id<0
			invoke FindParentGroup,[ebx].PROJECTBROWSER.htrv,0,[esi].PBITEM.idparent
			mov		tvis.hParent,eax
			mov		tvis.hInsertAfter,TVI_SORT
			mov		tvis.item._mask,TVIF_IMAGE or TVIF_SELECTEDIMAGE or TVIF_PARAM or TVIF_TEXT
			lea		eax,[esi].PBITEM.szitem
			mov		tvis.item.pszText,eax
			mov		tvis.item.iImage,0
			mov		tvis.item.iSelectedImage,0
			mov		tvis.item.lParam,esi
			invoke SendMessage,[ebx].PROJECTBROWSER.htrv,TVM_INSERTITEM,0,addr tvis
		.endif
		lea		esi,[esi+sizeof PBITEM]
	.endw
	ret

AddGroups endp

AddFiles proc uses ebx esi edi,lpPROJECTBROWSER:DWORD
	LOCAL	tvis:TV_INSERTSTRUCT
	LOCAL	tvi:TV_ITEM

	mov		ebx,lpPROJECTBROWSER
	mov		esi,[ebx].PROJECTBROWSER.hmemitems
	invoke RtlZeroMemory,addr tvis,sizeof TV_INSERTSTRUCT
	.while [esi].PBITEM.id
		.if sdword ptr [esi].PBITEM.id>0
			invoke FindParentGroup,[ebx].PROJECTBROWSER.htrv,0,[esi].PBITEM.idparent
			mov		tvis.hParent,eax
			mov		tvis.hInsertAfter,TVI_SORT
			mov		tvis.item._mask,TVIF_IMAGE or TVIF_SELECTEDIMAGE or TVIF_PARAM or TVIF_TEXT
			lea		eax,[esi].PBITEM.szitem
			mov		tvis.item.pszText,eax
			invoke FindFileExt,ebx,eax
			mov		tvis.item.iImage,eax
			mov		tvis.item.iSelectedImage,eax
			mov		tvis.item.lParam,esi
			invoke SendMessage,[ebx].PROJECTBROWSER.htrv,TVM_INSERTITEM,0,addr tvis
		.endif
		lea		esi,[esi+sizeof PBITEM]
	.endw
	ret

AddFiles endp

ControlProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	rect:RECT

	mov		eax,uMsg
	.if eax==WM_CREATE
		invoke GetProcessHeap
		invoke HeapAlloc,eax,HEAP_ZERO_MEMORY,sizeof PROJECTBROWSER
		mov		ebx,eax
		invoke SetWindowLong,hWin,0,ebx
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,8*1024
		mov		[ebx].PROJECTBROWSER.hmemfileext,eax
		invoke GlobalAlloc,GMEM_FIXED or GMEM_ZEROINIT,64*1024
		mov		[ebx].PROJECTBROWSER.hmemitems,eax
		invoke CreateWindowEx,WS_EX_CLIENTEDGE,addr szTreeView,NULL,WS_CHILD or WS_VISIBLE or WS_CLIPSIBLINGS or WS_CLIPCHILDREN or TVS_HASLINES or TVS_HASBUTTONS or TVS_SHOWSELALWAYS or TVS_EDITLABELS,0,0,0,0,hWin,NULL,hInstance,NULL
		mov		[ebx].PROJECTBROWSER.htrv,eax
		invoke SetWindowLong,[ebx].PROJECTBROWSER.htrv,GWL_WNDPROC,offset ProjectTreeViewProc
		invoke SetWindowLong,[ebx].PROJECTBROWSER.htrv,GWL_USERDATA,eax
		invoke ImageList_Create,16,16,ILC_COLOR24 or ILC_MASK,10,0
		mov		[ebx].PROJECTBROWSER.himl,eax
		invoke LoadBitmap,hInstance,IDB_TRV
		push	eax
		invoke ImageList_AddMasked,[ebx].PROJECTBROWSER.himl,eax,0FF00FFh
		pop		eax
		invoke DeleteObject,eax
		invoke SendMessage,[ebx].PROJECTBROWSER.htrv,TVM_SETIMAGELIST,0,[ebx].PROJECTBROWSER.himl
		invoke GetWindowLong,hWin,GWL_STYLE
		mov		edx,WS_CHILD or WS_VISIBLE or TBSTYLE_TOOLTIPS or CCS_NORESIZE
		test	eax,PBSTYLE_FLATTOOLBAR
		.if !ZERO?
			or		edx,TBSTYLE_FLAT
		.endif
		test	eax,PBSTYLE_DIVIDERLINE
		.if ZERO?
			or		edx,CCS_NODIVIDER
		.endif
		invoke CreateWindowEx,0,addr szToolBar,NULL,edx,0,0,0,0,hWin,NULL,hInstance,NULL
		mov		[ebx].PROJECTBROWSER.htbr,eax
		;Set toolbar struct size
		invoke SendMessage,[ebx].PROJECTBROWSER.htbr,TB_BUTTONSTRUCTSIZE,sizeof TBBUTTON,0
		;Set toolbar buttons
		invoke SendMessage,[ebx].PROJECTBROWSER.htbr,TB_ADDBUTTONS,3,addr btns
		;Set the imagelist
		invoke SendMessage,[ebx].PROJECTBROWSER.htbr,TB_SETIMAGELIST,0,[ebx].PROJECTBROWSER.himl
		xor		eax,eax
		jmp		Ex
	.elseif eax==WM_COMMAND
PrintHex eax
	.elseif eax==WM_SIZE
		push	edi
		invoke GetWindowLong,hWin,GWL_STYLE
		mov		edi,28
		test	eax,PBSTYLE_FLATTOOLBAR
		.if !ZERO?
			sub		edi,4
		.endif
		test	eax,PBSTYLE_DIVIDERLINE
		.if ZERO?
			sub		edi,2
		.endif
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke GetClientRect,hWin,addr rect
		invoke MoveWindow,[ebx].PROJECTBROWSER.htbr,0,0,rect.right,edi,TRUE
		mov		edx,rect.bottom
		sub		edx,edi
		invoke MoveWindow,[ebx].PROJECTBROWSER.htrv,0,edi,rect.right,edx,TRUE
		pop		edi
	.elseif eax==WM_SETFONT
		invoke GetWindowLong,hWin,0
		invoke SendMessage,[eax].PROJECTBROWSER.htrv,WM_SETFONT,wParam,TRUE
		xor		eax,eax
		jmp		Ex
	.elseif eax==WM_DESTROY
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke ImageList_Destroy,[ebx].PROJECTBROWSER.himl
		invoke DestroyWindow,[ebx].PROJECTBROWSER.htrv
		invoke DestroyWindow,[ebx].PROJECTBROWSER.htbr
		invoke GlobalFree,[ebx].PROJECTBROWSER.hmemfileext
		invoke GlobalFree,[ebx].PROJECTBROWSER.hmemitems
		invoke GetProcessHeap
		invoke HeapFree,eax,0,ebx
	.elseif eax==RPBM_SETPATH
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke lstrcpyn,[ebx].PROJECTBROWSER.projectpath,lParam,MAX_PATH
		.if wParam
		.endif
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_GETPATH
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		invoke lstrcpyn,lParam,[ebx].PROJECTBROWSER.projectpath,wParam
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_SETFILEEXT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		esi,lParam
		mov		edi,[ebx].PROJECTBROWSER.hmemfileext
		invoke RtlZeroMemory,edi,8*1024
		.while [esi].PBFILEEXT.id
			invoke RtlMoveMemory,edi,esi,sizeof PBFILEEXT
			lea		esi,[esi+sizeof PBFILEEXT]
			lea		edi,[edi+sizeof PBFILEEXT]
		.endw
	.elseif eax==RPBM_GETFILEEXT
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_SETITEMS
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		mov		esi,lParam
		mov		edi,[ebx].PROJECTBROWSER.hmemitems
		invoke RtlZeroMemory,edi,64*1024
		.while [esi].PBITEM.id
			invoke RtlMoveMemory,edi,esi,sizeof PBITEM
			lea		esi,[esi+sizeof PBITEM]
			lea		edi,[edi+sizeof PBITEM]
		.endw
		invoke AddGroups,ebx
		invoke AddFiles,ebx
		invoke ExpandAll,[ebx].PROJECTBROWSER.htrv,0
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_GETITEMS
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_SETGROUPING
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_GETGROUPING
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_SETSELECTED
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_GETSELECTED
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_SETBACKCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_GETBACKCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_SETTEXTCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_GETTEXTCOLOR
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_GETIMAGELIST
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.elseif eax==RPBM_SETTOOLTIP
		invoke GetWindowLong,hWin,0
		mov		ebx,eax
		xor		eax,eax
		jmp		Ex
	.endif
	invoke DefWindowProc,hWin,uMsg,wParam,lParam
  Ex:
	ret

ControlProc endp

IFDEF DLL
	include RAProjectDll.asm
ENDIF

end
