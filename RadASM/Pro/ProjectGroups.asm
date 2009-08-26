
GRPROW struct
	lpszName	dd ?
GRPROW ends

IDD_DLGPROJECTGROUPS			equ 4500
IDC_TRVPROJECT					equ 4501
IDC_TRVGROUPS					equ 4502
IDC_EDTGROUPS					equ 4503
IDC_BTNADDGROUP					equ 4504
IDC_BTNDELGROUP					equ 4505
IDC_EDTDEFGROUP					equ 4506

.data?

hGrpTrv				dd ?
hProTrv				dd ?
hProRoot			dd ?
hGrpRoot			dd ?
lpGroupGroupBuff	dd ?
szGroupGroupBuff	db 4096 dup(?)
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
	invoke Do_TreeViewAddNode,hProTrv,[esi].PROGROUP.hGrp,NULL,lpFileName,ftp,ftp,iNbr
	ret

GroupAddNode endp

ExpandSort proc hTrv:HWND,hItem:DWORD

  @@:
	invoke SendMessage,hTrv,TVM_SORTCHILDREN,0,hItem
	invoke SendMessage,hTrv,TVM_EXPAND,TVE_EXPAND,hItem
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_CHILD,hItem
	.if eax
		invoke ExpandSort,hTrv,eax
	.endif
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_NEXT,hItem
	.if eax
		mov		hItem,eax
		jmp		@b
	.endif
	ret

ExpandSort endp

GroupUpdateTrv proc uses ebx esi edi,fInitial:DWORD
	LOCAL	iNbr:DWORD
	LOCAL	iInx:DWORD
	LOCAL	hPrevGrp[32]:DWORD
	LOCAL	hPrevPro[32]:DWORD

	.if hProRoot
		invoke SendMessage,hProTrv,TVM_DELETEITEM,0,hProRoot
	.endif
	.if hGrpRoot
		invoke SendMessage,hGrpTrv,TVM_DELETEITEM,0,hGrpRoot
	.endif
	invoke Do_TreeViewAddNode,hProTrv,TVI_ROOT,NULL,addr ProjectDescr,IML_START+0,IML_START+0,0
	mov		hProRoot,eax
	mov		hPrevPro[0],eax
	invoke Do_TreeViewAddNode,hGrpTrv,TVI_ROOT,NULL,addr ProjectDescr,IML_START+0,IML_START+0,0
	mov		hGrpRoot,eax
	mov		hPrevGrp[0],eax

	mov		esi,offset szGroupGroupBuff
	mov		edi,offset groupgrp
	invoke RtlZeroMemory,edi,sizeof groupgrp
	mov		iNbr,0
	.while byte ptr [esi] && iNbr<64
		inc		iNbr
		mov		ebx,iNbr
		neg		ebx
		.if byte ptr [esi]=='.'
			push	esi
			xor		edx,edx
			.while byte ptr [esi]=='.'
				inc		esi
				inc		edx
			.endw
			shr		edx,1
			mov		iInx,edx
			invoke Do_TreeViewAddNode,hGrpTrv,hPrevGrp[edx*4],NULL,esi,IML_START+0,IML_START+0,ebx
			mov		edx,iInx
			inc		edx
			mov		hPrevGrp[edx*4],eax
			mov		edx,iInx
			invoke Do_TreeViewAddNode,hProTrv,hPrevPro[edx*4],NULL,esi,IML_START+0,IML_START+0,ebx
			mov		edx,iInx
			inc		edx
			mov		hPrevPro[edx*4],eax
			pop		esi
		.else
			invoke Do_TreeViewAddNode,hGrpTrv,hGrpRoot,NULL,esi,IML_START+0,IML_START+0,ebx
			mov		hPrevGrp[4],eax
			invoke Do_TreeViewAddNode,hProTrv,hProRoot,NULL,esi,IML_START+0,IML_START+0,ebx
			mov		hPrevPro[4],eax
		.endif
		mov		[edi].PROGROUP.hGrp,eax
		mov		[edi].PROGROUP.lpszGrp,esi
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
			invoke SendMessage,hProTrv,TVM_SORTCHILDREN,0,eax
			pop		edx
			.if groupexpand[ebx*4] || fInitial
				invoke SendMessage,hProTrv,TVM_EXPAND,TVE_EXPAND,edx
			.endif
		.endif
		lea		esi,[esi+sizeof PROGROUP]
		inc		ebx
	.endw
	invoke ExpandSort,hGrpTrv,hGrpRoot
	invoke SendMessage,hProTrv,TVM_SORTCHILDREN,0,hProRoot
	invoke SendMessage,hProTrv,TVM_EXPAND,TVE_EXPAND,hProRoot
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
		invoke SendMessage,hProTrv,TVM_GETITEM,0,addr tvi
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

GetItems proc uses edi,hTrv:HWND,hItem:DWORD,nInx:DWORD
	LOCAL	tvi:TV_ITEM

  @@:
	.if nInx
		mov		edi,lpGroupGroupBuff
		mov		edx,nInx
		.while edx>1
			mov		word ptr [edi],'..'
			add		edi,2
			dec		edx
		.endw
		mov		tvi._mask,TVIF_TEXT
		mov		tvi.pszText,edi
		mov		tvi.cchTextMax,64
		mov		eax,hItem
		mov		tvi.hItem,eax
		invoke SendMessage,hTrv,TVM_GETITEM,0,addr tvi
		invoke strlen,edi
		lea		edi,[edi+eax+1]
		mov		lpGroupGroupBuff,edi
	.endif
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_CHILD,hItem
	.if eax
		mov		edx,nInx
		inc		edx
		invoke GetItems,hTrv,eax,edx
	.endif
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_NEXT,hItem
	.if eax
		mov		hItem,eax
		jmp		@b
	.endif
	ret

GetItems endp

GroupUpdateGroup proc uses ebx esi edi

	mov		edi,offset szGroupGroupBuff
	mov		lpGroupGroupBuff,edi
	invoke RtlZeroMemory,edi,sizeof szGroupGroupBuff
	invoke GetItems,hGrpTrv,hGrpRoot,0
	invoke GroupUpdateTrv,FALSE
	ret

GroupUpdateGroup endp

GroupGetFirstVisible proc
	LOCAL	tvi:TVITEM

	invoke SendMessage,hProTrv,TVM_GETNEXTITEM,TVGN_FIRSTVISIBLE,0
	mov		tvi.hItem,eax
	mov		tvi._mask,TVIF_HANDLE or TVIF_TEXT
	mov		tvi.pszText,offset szFirstVisible
	mov		tvi.cchTextMax,sizeof szFirstVisible
	invoke SendMessage,hProTrv,TVM_GETITEM,0,addr tvi
	ret

GroupGetFirstVisible endp

GroupEnsureVisible proc
	LOCAL	tvi:TVITEM
	LOCAL	buffer[256]:BYTE
	LOCAL	hPar:DWORD
	LOCAL	hVis:DWORD
	LOCAL	hLast:DWORD

	invoke SendMessage,hProTrv,TVM_GETNEXTITEM,TVGN_ROOT,0
	mov		hVis,eax
	.if eax
		call	Compare
		invoke SendMessage,hProTrv,TVM_GETNEXTITEM,TVGN_CHILD,tvi.hItem
		.while eax
			mov		hPar,eax
			call	Compare
			invoke SendMessage,hProTrv,TVM_GETNEXTITEM,TVGN_CHILD,tvi.hItem
			.while eax
				call	Compare
				invoke SendMessage,hProTrv,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
			.endw
			invoke SendMessage,hProTrv,TVM_GETNEXTITEM,TVGN_NEXT,hPar
		.endw
		invoke SendMessage,hProTrv,TVM_ENSUREVISIBLE,0,hLast
		invoke SendMessage,hProTrv,TVM_ENSUREVISIBLE,0,hVis
	.endif
	ret

Compare:
	mov		hLast,eax
	mov		tvi.hItem,eax
	mov		tvi._mask,TVIF_HANDLE or TVIF_TEXT
	lea		eax,buffer
	mov		tvi.pszText,eax
	mov		tvi.cchTextMax,sizeof buffer
	invoke SendMessage,hProTrv,TVM_GETITEM,0,addr tvi
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
	LOCAL	buffer[64]:BYTE
	LOCAL	buffer1[64]:BYTE
	LOCAL	hChild:DWORD
	LOCAL	hItem:DWORD

	mov		eax,uMsg
	.if eax==WM_LBUTTONDBLCLK
		invoke CallWindowProc,OldTreeViewProc,hWin,uMsg,wParam,lParam
		push	eax
;		mov		eax,lParam
;		and		eax,0FFFFh
;		mov		lpht.pt.x,eax
;		mov		eax,lParam
;		shr		eax,16
;		mov		lpht.pt.y,eax
;		invoke SendMessage,hWin,TVM_HITTEST,0,addr lpht
;		.if eax
;			mov		hTvi,eax
;			mov		eax,lpht.flags
;			and		eax,TVHT_ONITEM
;			.if eax
;				m2m		tvi.hItem,lpht.hItem
;				mov		tvi.imask,TVIF_PARAM
;				invoke SendMessage,hWin,TVM_GETITEM,0,addr tvi
;				.if tvi.lParam
;					invoke SendMessage,hGrpGrd,GM_GETCURROW,0,0
;					.if sdword ptr eax>=0
;						mov		edx,tvi.lParam
;						shl		edx,2
;						inc		eax
;						mov		nFileGroup[edx],eax
;						invoke SendMessage,hWin,TVM_GETNEXTITEM,TVGN_FIRSTVISIBLE,0
;						mov		tvi.hItem,eax
;						mov		tvi.imask,TVIF_TEXT
;						lea		eax,buffer
;						mov		tvi.pszText,eax
;						mov		tvi.cchTextMax,sizeof buffer
;						invoke SendMessage,hWin,TVM_GETITEM,0,addr tvi
;						invoke GroupGetExpand
;						invoke GroupUpdateTrv,FALSE
;						invoke SendMessage,hWin,TVM_GETNEXTITEM,TVGN_CHILD,hGrpRoot
;						.while eax
;							mov		hItem,eax
;							invoke SendMessage,hWin,TVM_GETNEXTITEM,TVGN_CHILD,eax
;							.while eax
;								mov		hChild,eax
;								mov		tvi.hItem,eax
;								mov		tvi.imask,TVIF_TEXT
;								lea		eax,buffer1
;								mov		tvi.pszText,eax
;								mov		tvi.cchTextMax,sizeof buffer1
;								invoke SendMessage,hWin,TVM_GETITEM,0,addr tvi
;								invoke strcmp,addr buffer,addr buffer1
;								.if !eax
;									invoke SendMessage,hWin,TVM_SELECTITEM,TVGN_FIRSTVISIBLE,tvi.hItem
;								.endif
;								invoke SendMessage,hWin,TVM_GETNEXTITEM,TVGN_NEXT,hChild
;							.endw
;							invoke SendMessage,hProTrv,TVM_GETNEXTITEM,TVGN_NEXT,hItem
;						.endw
;					.endif
;				.endif
;			.endif
;		.endif
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
	invoke SendMessage,hProTrv,TVM_GETITEM,0,addr tvi
	mov		eax,tvi.iImage
	cmp		eax,0
	je		Ex
	mov		tvi._mask,TVIF_STATE
	mov		tvi.state,TVIS_DROPHILITED
	invoke SendMessage,hProTrv,TVM_SETITEM,0,addr tvi
	invoke GetCursorPos,addr DragStart
	invoke SendMessage,hProTrv,TVM_SELECTITEM,TVGN_DROPHILITE,TVDragItem
	invoke SendMessage,hProTrv,TVM_CREATEDRAGIMAGE,0,TVDragItem
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
	LOCAL	nGrp:DWORD

	invoke SendMessage,hProTrv,TVM_SELECTITEM,TVGN_DROPHILITE,NULL
	invoke ReleaseCapture
	invoke GetDesktopWindow
	invoke ImageList_DragLeave,eax
	invoke ImageList_EndDrag
	invoke ImageList_Destroy,hDragIml
	invoke SendMessage,hProTrv,TVM_GETNEXTITEM,TVGN_ROOT,NULL
	mov		hroot,eax
	invoke GetCursorPos,addr tvht.pt
	invoke ScreenToClient,hProTrv,addr tvht.pt
	invoke SendMessage,hProTrv,TVM_HITTEST,0,addr tvht
	.if !eax
		invoke SendMessage,hProTrv,TVM_GETNEXTITEM,TVGN_LASTVISIBLE,NULL
	.endif
	.if eax!=hroot
		mov		tvi._mask,TVIF_PARAM
		mov		tvi.hItem,eax
		invoke SendMessage,hProTrv,TVM_GETITEM,0,addr tvi
		mov		edx,tvi.lParam
		mov		eax,tvi.hItem
		.if sdword ptr edx>=0
			invoke SendMessage,hProTrv,TVM_GETNEXTITEM,TVGN_PARENT,eax
			.if eax==hroot
				mov		eax,tvht.hItem
			.endif
		.endif
		; The group item number is here
		mov		tvi.hItem,eax
		mov 	buffer,0
		lea		eax,buffer
		mov 	tvi.pszText,eax
		mov		tvi.cchTextMax,sizeof buffer
		mov		tvi._mask,TVIF_TEXT or TVIF_PARAM
		invoke SendMessage,hProTrv,TVM_GETITEM,0,addr tvi
		mov		ebx,tvi.lParam
		neg		ebx
		invoke lstrlen,addr buffer
		.if eax
			invoke GroupGetExpand
			mov		eax,TVDragItem
			mov		tvi.hItem,eax
			mov		tvi._mask,TVIF_PARAM
			invoke SendMessage,hProTrv,TVM_GETITEM,0,addr tvi
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

ProjectGroupsProc proc uses ebx,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[64]:BYTE
	LOCAL	pt:POINT
	LOCAL	tvis:TV_INSERTSTRUCT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_TRVGROUPS
		mov		hGrpTrv,eax
		invoke GetDlgItem,hWin,IDC_TRVPROJECT
		mov		hProTrv,eax
		invoke SendMessage,hGrpTrv,TVM_SETBKCOLOR,0,radcol.project
		invoke SendMessage,hGrpTrv,TVM_SETTEXTCOLOR,0,radcol.projecttext
		invoke SendMessage,hGrpTrv,TVM_SETIMAGELIST,0,hTbrIml
		invoke SendMessage,hProTrv,TVM_SETBKCOLOR,0,radcol.project
		invoke SendMessage,hProTrv,TVM_SETTEXTCOLOR,0,radcol.projecttext
		invoke SendMessage,hProTrv,TVM_SETIMAGELIST,0,hTbrIml
		push	esi
		push	edi
		mov		edi,offset szGroupGroupBuff
		mov		esi,offset szGroupBuff
		mov		ecx,sizeof szGroupGroupBuff
		rep movsb
		pop		edi
		pop		esi
		invoke GroupUpdateTrv,TRUE
		invoke SetWindowLong,hProTrv,GWL_WNDPROC,offset GroupTreeViewProc
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
				invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_CARET,0
				.if eax
					mov		tvis.item._mask,TVIF_PARAM
					mov		tvis.item.hItem,eax
					invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvis.item
					mov		eax,tvis.item.lParam
					neg		eax
					.if eax>1
						mov		ecx,2048
						mov		edx,offset nFileGroup
						.while ecx
							.if [edx]>=eax
								dec		dword ptr [edx]
							.endif
							add		edx,4
							dec		ecx
						.endw
						invoke SendMessage,hGrpTrv,TVM_DELETEITEM,0,tvis.item.hItem
						invoke GroupUpdateGroup
					.endif
				.endif
			.elseif eax==IDC_BTNADDGROUP
				invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_CARET,0
				.if eax
					mov		tvis.item._mask,TVIF_PARAM
					mov		tvis.item.hItem,eax
					mov		tvis.hParent,eax
					mov		tvis.hInsertAfter,TVI_FIRST
					invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvis.item
					mov		eax,tvis.item.lParam
					neg		eax
					.if eax
						mov		ecx,2048
						mov		edx,offset nFileGroup
						.while ecx
							.if [edx]>=eax
								inc		dword ptr [edx]
							.endif
							add		edx,4
							dec		ecx
						.endw
					.endif
					invoke GetDlgItemText,hWin,IDC_EDTGROUPS,addr buffer,sizeof buffer
					invoke SetDlgItemText,hWin,IDC_EDTGROUPS,addr szNULL
					mov		tvis.item._mask,TVIF_PARAM or TVIF_TEXT
					lea		eax,buffer
					mov		tvis.item.pszText,eax
					invoke SendMessage,hGrpTrv,TVM_INSERTITEM,0,addr tvis
					invoke GroupUpdateGroup
				.endif
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
		.if eax==hProTrv
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