
GRPROW struct
	nID			dd ?
	lpszName	dd ?
GRPROW ends

IDD_DLGPROJECTGROUPS			equ 4500
IDC_TRVGROUPS					equ 4501
IDC_GRDGROUPS					equ 4502
IDC_EDTGROUPS					equ 4503
IDC_BTNADDGROUP					equ 4504
IDC_BTNDELGROUP					equ 4505
IDC_EDTDEFGROUP					equ 4506

.data?

hGrpGrd				dd ?
hGrpTrv				dd ?
hGrpRoot			dd ?
szGroupGroupBuff	db 1024 dup(?)
groupgrp			PROGROUP 64 dup(<>)
groupexpand			dd 64 dup(?)
nFileGroup			dd 2048 dup(?)
fNoUpdate			dd ?
IsDragging			dd ?
TVDragItem			dd ?
hDragIml			dd ?
szFirstVisible		db 256 dup(?)

.code

GroupAddNode proc uses esi,lpFileName:DWORD,iNbr:DWORD,fModule:DWORD,fInitial:DWORD
	LOCAL	ftp:DWORD

	;Find filetype
	invoke GetFileImg,lpFileName
	.if fModule
		.if eax==9
			mov		eax,1
		.elseif eax==3
			mov		eax,10
		.endif
	.endif
	.if eax>=30
		mov		eax,7
	.endif
	mov		ftp,eax
	.if fInitial
		invoke ProGetGroup,iNbr,ftp
		mov		edx,iNbr
		shl		edx,2
		mov		nFileGroup[edx],eax
	.else
		mov		edx,iNbr
		shl		edx,2
		mov		eax,nFileGroup[edx]
	.endif
	mov		edx,sizeof PROGROUP
	dec		eax
	mul		edx
	lea		esi,groupgrp[eax]
	add		ftp,IML_START
	invoke Do_TreeViewAddNode,hGrpTrv,[esi].PROGROUP.hGrp,NULL,lpFileName,ftp,ftp,iNbr
	ret

GroupAddNode endp

GroupUpdateTrv proc uses ebx esi edi,fInitial:DWORD
	LOCAL	buffer1[8]:BYTE
	LOCAL	iNbr:DWORD
	LOCAL	row:GRPROW

	.if hGrpRoot
		invoke SendMessage,hGrpTrv,TVM_DELETEITEM,0,hGrpRoot
	.endif
	invoke Do_TreeViewAddNode,hGrpTrv,TVI_ROOT,NULL,addr ProjectDescr,IML_START+0,IML_START+0,0
	mov		hGrpRoot,eax
	mov		esi,offset szGroupGroupBuff
	mov		edi,offset groupgrp
	invoke RtlZeroMemory,edi,sizeof groupgrp
	mov		iNbr,0
	.while byte ptr [esi] && iNbr<64
		invoke Do_TreeViewAddNode,hGrpTrv,hGrpRoot,NULL,esi,IML_START+0,IML_START+0,0
		mov		[edi].PROGROUP.hGrp,eax
		mov		[edi].PROGROUP.lpszGrp,esi
		.if fInitial
			inc		iNbr
			mov		eax,iNbr
			mov		row.nID,eax
			mov		row.lpszName,esi
			invoke SendMessage,hGrpGrd,GM_ADDROW,0,addr row
		.endif
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		lea		edi,[edi+sizeof PROGROUP]
	.endw
	mov		esi,hMemPro
  Nxt:
	.if  byte ptr [esi]
		invoke DecToBin,esi
		.while byte ptr [esi] && byte ptr [esi]!='='
			inc		esi
		.endw
		inc		esi
		.if byte ptr [esi] && eax
			mov		iNbr,eax
			invoke BinToDec,iNbr,addr buffer1
			.if iNbr<PRO_START_OBJ
				invoke GroupAddNode,esi,iNbr,FALSE,fInitial
			.else
				invoke GroupAddNode,esi,iNbr,TRUE,fInitial
			.endif
		.endif
		invoke strlen,esi
		add		esi,eax
		inc		esi
		jmp		Nxt
	.endif
	xor		ebx,ebx
	mov		esi,offset groupgrp
	.while [esi].PROGROUP.lpszGrp
		mov		eax,[esi].PROGROUP.hGrp
		.if eax
			push	eax
			invoke SendMessage,hGrpTrv,TVM_SORTCHILDREN,0,eax
			pop		edx
			.if groupexpand[ebx*4] || fInitial
				invoke SendMessage,hGrpTrv,TVM_EXPAND,TVE_EXPAND,edx
			.endif
		.endif
		lea		esi,[esi+sizeof PROGROUP]
		inc		ebx
	.endw
	invoke SendMessage,hGrpTrv,TVM_SORTCHILDREN,0,hGrpRoot
	invoke SendMessage,hGrpTrv,TVM_EXPAND,TVE_EXPAND,hGrpRoot
	ret

GroupUpdateTrv endp

GroupGetExpand proc uses ebx esi edi
	LOCAL	tvi:TVITEM
	
	mov		edi,offset groupgrp
	.while [edi].PROGROUP.hGrp
		mov		tvi._mask,TVIF_STATE
		mov		tvi.stateMask,TVIS_EXPANDED
		mov		eax,[edi].PROGROUP.hGrp
		mov		tvi.hItem,eax
		invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
		mov		esi,offset szGroupGroupBuff
		xor		ebx,ebx
		.while byte ptr [esi]
			invoke strcmp,esi,[edi].PROGROUP.lpszGrp
			.if !eax
				mov		eax,tvi.state
				and		eax,TVIS_EXPANDED
				mov		groupexpand[ebx*4],eax
			.endif
			invoke strlen,esi
			lea		esi,[esi+eax+1]
			inc		ebx
		.endw
		lea		edi,[edi+sizeof PROGROUP]
	.endw
	ret

GroupGetExpand endp

GroupUpdateGroup proc uses ebx esi edi
	LOCAL	nRows:DWORD
	LOCAL	buffer[64]:BYTE

	mov		edi,offset szGroupGroupBuff
	invoke RtlZeroMemory,edi,sizeof szGroupGroupBuff
	invoke SendMessage,hGrpGrd,GM_GETROWCOUNT,0,0
	mov		nRows,eax
	xor		esi,esi
	inc		esi
	.while esi<=nRows
		xor		ebx,ebx
		.while ebx<nRows
			mov		ecx,ebx
			shl		ecx,16
			invoke SendMessage,hGrpGrd,GM_GETCELLDATA,ecx,addr buffer
			.if esi==dword ptr buffer
				mov		ecx,ebx
				shl		ecx,16
				inc		ecx
				invoke SendMessage,hGrpGrd,GM_GETCELLDATA,ecx,edi
				invoke strlen,edi
				lea		edi,[edi+eax+1]
				inc		esi
				.break
			.endif
			inc		ebx
		.endw
	.endw
	invoke GroupUpdateTrv,FALSE
	ret

GroupUpdateGroup endp

GroupGetFirstVisible proc
	LOCAL	tvi:TVITEM

	invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_FIRSTVISIBLE,0
	mov		tvi.hItem,eax
	mov		tvi._mask,TVIF_HANDLE or TVIF_TEXT
	mov		tvi.pszText,offset szFirstVisible
	mov		tvi.cchTextMax,sizeof szFirstVisible
	invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
	ret

GroupGetFirstVisible endp

GroupEnsureVisible proc
	LOCAL	tvi:TVITEM
	LOCAL	buffer[256]:BYTE
	LOCAL	hPar:DWORD
	LOCAL	hVis:DWORD
	LOCAL	hLast:DWORD

	invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_ROOT,0
	mov		hVis,eax
	.if eax
		call	Compare
		invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_CHILD,tvi.hItem
		.while eax
			mov		hPar,eax
			call	Compare
			invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_CHILD,tvi.hItem
			.while eax
				call	Compare
				invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
			.endw
			invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_NEXT,hPar
		.endw
		invoke SendMessage,hGrpTrv,TVM_ENSUREVISIBLE,0,hLast
		invoke SendMessage,hGrpTrv,TVM_ENSUREVISIBLE,0,hVis
	.endif
	ret

Compare:
	mov		hLast,eax
	mov		tvi.hItem,eax
	mov		tvi._mask,TVIF_HANDLE or TVIF_TEXT
	lea		eax,buffer
	mov		tvi.pszText,eax
	mov		tvi.cchTextMax,sizeof buffer
	invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
	invoke strcmp,addr buffer,addr szFirstVisible
	.if !eax
		mov		eax,tvi.hItem
		mov		hVis,eax
	.endif
	retn

GroupEnsureVisible endp

GroupTreeViewProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	lpht:TV_HITTESTINFO
	LOCAL	tvi:TV_ITEMEX
	LOCAL	hTvi:HWND
	LOCAL	val:DWORD
	LOCAL	buffer[64]:BYTE
	LOCAL	buffer1[64]:BYTE
	LOCAL	hChild:DWORD
	LOCAL	hItem:DWORD

	mov		eax,uMsg
	.if eax==WM_LBUTTONDBLCLK
		invoke CallWindowProc,OldTreeViewProc,hWin,uMsg,wParam,lParam
		push	eax
		mov		eax,lParam
		and		eax,0FFFFh
		mov		lpht.pt.x,eax
		mov		eax,lParam
		shr		eax,16
		mov		lpht.pt.y,eax
		invoke SendMessage,hWin,TVM_HITTEST,0,addr lpht
		.if eax
			mov		hTvi,eax
			mov		eax,lpht.flags
			and		eax,TVHT_ONITEM
			.if eax
				m2m		tvi.hItem,lpht.hItem
				mov		tvi.imask,TVIF_PARAM
				invoke SendMessage,hWin,TVM_GETITEM,0,addr tvi
				.if tvi.lParam
					invoke SendMessage,hGrpGrd,GM_GETCURROW,0,0
					.if sdword ptr eax>=0
						mov		ecx,eax
						shl		ecx,16
						invoke SendMessage,hGrpGrd,GM_GETCELLDATA,ecx,addr val
						mov		edx,tvi.lParam
						shl		edx,2
						mov		eax,val
						mov		nFileGroup[edx],eax
						invoke SendMessage,hWin,TVM_GETNEXTITEM,TVGN_FIRSTVISIBLE,0
						mov		tvi.hItem,eax
						mov		tvi.imask,TVIF_TEXT
						lea		eax,buffer
						mov		tvi.pszText,eax
						mov		tvi.cchTextMax,sizeof buffer
						invoke SendMessage,hWin,TVM_GETITEM,0,addr tvi
						invoke GroupGetExpand
						invoke GroupUpdateTrv,FALSE
						invoke SendMessage,hWin,TVM_GETNEXTITEM,TVGN_CHILD,hGrpRoot
						.while eax
							mov		hItem,eax
							invoke SendMessage,hWin,TVM_GETNEXTITEM,TVGN_CHILD,eax
							.while eax
								mov		hChild,eax
								mov		tvi.hItem,eax
								mov		tvi.imask,TVIF_TEXT
								lea		eax,buffer1
								mov		tvi.pszText,eax
								mov		tvi.cchTextMax,sizeof buffer1
								invoke SendMessage,hWin,TVM_GETITEM,0,addr tvi
								invoke strcmp,addr buffer,addr buffer1
								.if !eax
									invoke SendMessage,hWin,TVM_SELECTITEM,TVGN_FIRSTVISIBLE,tvi.hItem
								.endif
								invoke SendMessage,hWin,TVM_GETNEXTITEM,TVGN_NEXT,hChild
							.endw
							invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_NEXT,hItem
						.endw
					.endif
				.endif
			.endif
		.endif
		pop		eax
		ret
	.endif
	invoke CallWindowProc,OldTreeViewProc,hWin,uMsg,wParam,lParam
	ret

GroupTreeViewProc endp

SaveGroups proc uses esi
	LOCAL	nInx:DWORD
	LOCAL	buffer[8]:BYTE
	LOCAL	buffer1[8]:BYTE

	mov		esi,offset szGroupGroupBuff
	.while byte ptr [esi]
		invoke strlen,esi
		lea		esi,[esi+eax]
		.if byte ptr [esi+1]
			mov		byte ptr [esi],','
			inc		esi
		.endif
	.endw
	invoke WritePrivateProfileString,addr iniProjectGroup,addr iniProjectGroup,addr szGroupGroupBuff,addr ProjectFile
	mov		esi,offset nFileGroup
	mov		nInx,1
	.while nInx<2048
		add		esi,4
		.if dword ptr [esi]
			invoke BinToDec,nInx,addr buffer
			invoke BinToDec,[esi],addr buffer1
			invoke WritePrivateProfileString,addr iniProjectGroup,addr buffer,addr buffer1,addr ProjectFile
		.endif
		inc		nInx
	.endw
	invoke SendMessage,hPbrTrv,TVM_DELETEITEM,0,hRoot
	invoke GetProjectFiles,FALSE
	ret

SaveGroups endp

TVBeginDrag proc hWin:HWND,hParent:HWND,lParam:LPARAM
	LOCAL	DragStart:POINT
	LOCAL	tvi:TVITEM

	mov		edx,lParam
	mov		eax,[edx].NMTREEVIEW.itemNew.hItem
	mov		TVDragItem,eax
	mov		tvi.hItem,eax
	mov		tvi._mask,TVIF_IMAGE
	invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
	mov		eax,tvi.iImage
	cmp		eax,0
	je		Ex
	mov		tvi._mask,TVIF_STATE
	mov		tvi.state,TVIS_DROPHILITED
	invoke SendMessage,hGrpTrv,TVM_SETITEM,0,addr tvi
	invoke GetCursorPos,addr DragStart
	invoke SendMessage,hGrpTrv,TVM_SELECTITEM,TVGN_DROPHILITE,TVDragItem
	invoke SendMessage,hGrpTrv,TVM_CREATEDRAGIMAGE,0,TVDragItem
	mov		hDragIml,eax
	invoke ImageList_BeginDrag,hDragIml,0,-8,-8
	invoke GetDesktopWindow
	invoke ImageList_DragEnter,eax,DragStart.x,DragStart.y
	invoke SetCapture,hWin
	mov		IsDragging,TRUE
  Ex:
	ret

TVBeginDrag endp

TVEndDrag proc uses ebx esi,hWin:HWND
	LOCAL	pt:POINT
	LOCAL	hroot:DWORD
	LOCAL	tvi:TVITEM
	LOCAL	tvht:TV_HITTESTINFO
	LOCAL	buffer[MAX_PATH]:BYTE

	invoke SendMessage,hGrpTrv,TVM_SELECTITEM,TVGN_DROPHILITE,NULL
	invoke ReleaseCapture
	invoke GetDesktopWindow
	invoke ImageList_DragLeave,eax
	invoke ImageList_EndDrag
	invoke ImageList_Destroy,hDragIml
	invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_ROOT,NULL
	mov		hroot,eax
	invoke GetCursorPos,addr tvht.pt
	invoke ScreenToClient,hGrpTrv,addr tvht.pt
	invoke SendMessage,hGrpTrv,TVM_HITTEST,0,addr tvht
	.if !eax
		invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_LASTVISIBLE,NULL
	.endif
	.if eax!=hroot
		invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_PARENT,eax
		.if eax==hroot
			mov		eax,tvht.hItem
		.endif
		; The group item number is here
		mov		tvi.hItem,eax
		mov 	buffer,0
		lea		eax,buffer
		mov 	tvi.pszText,eax
		mov		tvi.cchTextMax,sizeof buffer
		mov		tvi._mask,TVIF_TEXT or TVIF_PARAM
		invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
		invoke lstrlen,addr buffer
		.if eax
			invoke GroupGetExpand
			mov		esi,offset szGroupGroupBuff
			xor		ebx,ebx
			.while byte ptr [esi]
				inc		ebx
				invoke strcmp,esi,addr buffer
				.if !eax
					.break
				.endif
				invoke strlen,esi
				lea		esi,[esi+eax+1]
			.endw
			mov		eax,TVDragItem
			mov		tvi.hItem,eax
			mov		tvi._mask,TVIF_PARAM
			invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
			mov		eax,tvi.lParam
			mov		nFileGroup[eax*4],ebx
			invoke GroupGetFirstVisible
			invoke GroupUpdateTrv,FALSE
			invoke GroupEnsureVisible
		.endif
	.endif
  Ex:
	ret

TVEndDrag endp

ProjectGroupsProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	col:COLUMN
	LOCAL	buffer[64]:BYTE
	LOCAL	row:GRPROW
	LOCAL	val:DWORD
	LOCAL	val1:DWORD
	LOCAL	pt:POINT
	LOCAL	nRow:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_GRDGROUPS
		mov		hGrpGrd,eax
		invoke GetDlgItem,hWin,IDC_TRVGROUPS
		mov		hGrpTrv,eax
		invoke SendMessage,hGrpGrd,GM_SETBACKCOLOR,radcol.project,0
		invoke SendMessage,hGrpGrd,GM_SETGRIDCOLOR,808080h,0
		invoke SendMessage,hGrpGrd,GM_SETTEXTCOLOR,radcol.projecttext,0
		invoke SendMessage,hGrpTrv,TVM_SETBKCOLOR,0,radcol.project
		invoke SendMessage,hGrpTrv,TVM_SETTEXTCOLOR,0,radcol.projecttext

		;Add ID column
		mov		col.colwt,0
		mov		col.lpszhdrtext,NULL
		mov		col.halign,ALIGN_RIGHT
		mov		col.calign,ALIGN_RIGHT
		mov		col.ctype,TYPE_EDITLONG
		mov		col.ctextmax,6
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrpGrd,GM_ADDCOL,0,addr col
		;Add Name column
		mov		col.colwt,150
		mov		col.lpszhdrtext,offset szHdrGroup
		mov		col.halign,ALIGN_LEFT
		mov		col.calign,ALIGN_LEFT
		mov		col.ctype,TYPE_EDITTEXT
		mov		col.ctextmax,63
		mov		col.lpszformat,0
		mov		col.himl,0
		mov		col.hdrflag,0
		invoke SendMessage,hGrpGrd,GM_ADDCOL,0,addr col
		invoke SendMessage,hGrpTrv,TVM_SETIMAGELIST,0,hTbrIml
		push	esi
		push	edi
		mov		edi,offset szGroupGroupBuff
		mov		esi,offset szGroupBuff
		mov		ecx,sizeof szGroupGroupBuff
		rep movsb
		pop		edi
		pop		esi
		invoke GroupUpdateTrv,TRUE
		invoke SetWindowLong,hGrpTrv,GWL_WNDPROC,offset GroupTreeViewProc
		invoke SendMessage,hGrpGrd,GM_SETCURSEL,1,0
		invoke SetDlgItemText,hWin,IDC_EDTDEFGROUP,addr szGroups
		invoke SetLanguage,hWin,IDD_DLGPROJECTGROUPS,FALSE
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke SaveGroups
				invoke GetDlgItemText,hWin,IDC_EDTDEFGROUP,offset szGroups,sizeof szGroups
				invoke WritePrivateProfileString,addr iniProjectGroup,addr iniProjectGroup,addr szGroups,addr iniAsmFile
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNDELGROUP
				invoke SendMessage,hGrpGrd,GM_GETROWCOUNT,0,0
				.if eax>1
					push	eax
					invoke SendMessage,hGrpGrd,GM_GETCURROW,0,0
					pop		edx
					.if sdword ptr eax>=0 && eax<edx
						mov		nRow,eax
						push	eax
						mov		ecx,eax
						shl		ecx,16
						invoke SendMessage,hGrpGrd,GM_GETCELLDATA,ecx,addr val
						invoke SendMessage,hGrpGrd,GM_GETROWCOUNT,0,0
						.if eax==val
							dec		val
						.endif
						dec		eax
						.if eax==nRow
							dec		nRow
						.endif
						mov		ecx,2048
						mov		edx,offset nFileGroup
						mov		eax,val
						.while ecx
							.if dword ptr [edx]>eax && dword ptr [edx]>1
								dec		dword ptr [edx]
							.endif
							add		edx,4
							dec		ecx
						.endw
						pop		eax
						invoke SendMessage,hGrpGrd,GM_DELROW,eax,0
						invoke SendMessage,hGrpGrd,GM_GETROWCOUNT,0,0
						mov		ecx,eax
						xor		eax,eax
						.while eax<ecx
							push	eax
							push	ecx
							mov		ecx,eax
							shl		ecx,16
							push	ecx
							invoke SendMessage,hGrpGrd,GM_GETCELLDATA,ecx,addr val1
							pop		ecx
							mov		eax,val1
							.if eax>val && eax>1
								dec		val1
								mov		fNoUpdate,TRUE
								invoke SendMessage,hGrpGrd,GM_SETCELLDATA,ecx,addr val1
								mov		fNoUpdate,FALSE
							.endif
							pop		ecx
							pop		eax
							inc		eax
						.endw
						invoke SendMessage,hGrpGrd,GM_SETCURSEL,0,nRow
						invoke GroupGetExpand
						invoke GroupUpdateGroup
					.endif
				.endif
			.elseif eax==IDC_BTNADDGROUP
				invoke GetDlgItemText,hWin,IDC_EDTGROUPS,addr buffer,sizeof buffer
				invoke SetDlgItemText,hWin,IDC_EDTGROUPS,addr szNULL
				invoke SendMessage,hGrpGrd,GM_GETROWCOUNT,0,0
				push	eax
				inc		eax
				mov		row.nID,eax
				lea		eax,buffer
				mov		row.lpszName,eax
				invoke SendMessage,hGrpGrd,GM_ADDROW,0,addr row
				pop		eax
				invoke SendMessage,hGrpGrd,GM_SETCURSEL,1,eax
				invoke GroupGetExpand
				invoke GroupUpdateGroup
			.endif
		.elseif edx==EN_CHANGE
			.if eax==IDC_EDTGROUPS
				invoke GetDlgItem,hWin,IDC_BTNADDGROUP
				push	eax
				invoke SendDlgItemMessage,hWin,IDC_EDTGROUPS,WM_GETTEXTLENGTH,0,0
				pop		edx
				invoke EnableWindow,edx,eax
			.endif
		.endif
	.elseif eax==WM_NOTIFY
		mov		edx,lParam
		mov		eax,[edx].NMHDR.hwndFrom
		.if eax==hGrpGrd
			mov		eax,[edx].NMHDR.code
			.if eax==GN_AFTERUPDATE && !fNoUpdate
				invoke GroupUpdateGroup
			.endif
		.elseif eax==hGrpTrv
			.if [edx].NMHDR.code==TVN_BEGINDRAGW
				invoke TVBeginDrag,hWin,[edx].NMHDR.hwndFrom,lParam
			.endif
		.endif
	.elseif eax==WM_LBUTTONUP
		.if IsDragging
			mov		IsDragging,FALSE
			invoke TVEndDrag,hWin
		.endif
	.elseif eax==WM_MOUSEMOVE
		.if IsDragging
			invoke GetCursorPos,addr pt
			invoke ImageList_DragMove,pt.x,pt.y
		.endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.else
		mov eax,FALSE
		ret
	.endif
	mov  eax,TRUE
	ret

ProjectGroupsProc endp