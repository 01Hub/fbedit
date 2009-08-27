
IDD_DLGPROJECTGROUPS			equ 4500
IDC_TRVPROJECT					equ 4501
IDC_EDTGROUPS					equ 4503
IDC_BTNADDGROUP					equ 4504
IDC_BTNDELGROUP					equ 4505
IDC_EDTDEFGROUP					equ 4506

PROFILE struct
	lpszFile		dd ?
	iNbr			dd ?
	nGrp			dd ?
PROFILE ends

.data?

hGrpTrv				dd ?
hGrpRoot			dd ?
szGroupGroupBuff	db 4096 dup(?)
groupgrp			PROGROUP 64 dup(<>)
profile				PROFILE 2048 dup(<>)
groupexpand			dd 64 dup(?)
IsDragging			dd ?
TVDragItem			dd ?
hDragIml			dd ?
szFirstVisible		db 256 dup(?)

.code

GroupGetProjectFiles proc uses ebx esi edi

	mov		esi,hMemPro
	mov		edi,offset profile
	invoke RtlZeroMemory,edi,sizeof profile
  Nxt:
	.if  byte ptr [esi]
		invoke DecToBin,esi
		.while byte ptr [esi] && byte ptr [esi]!='='
			inc		esi
		.endw
		.if byte ptr [esi]=='='
			inc		esi
			.if byte ptr [esi] && eax
				mov		[edi].PROFILE.lpszFile,esi
				mov		[edi].PROFILE.iNbr,eax
				invoke GetFileImg,esi
				.if [edi].PROFILE.iNbr>=PRO_START_OBJ
					.if eax==9
						mov		eax,1
					.elseif eax==3
						mov		eax,10
					.endif
				.endif
				.if eax>=30
					mov		eax,7
				.endif
				invoke ProGetGroup,[edi].PROFILE.iNbr,eax
				mov		[edi].PROFILE.nGrp,eax
				lea		edi,[edi+sizeof PROFILE]
			.endif
			invoke strlen,esi
			lea		esi,[esi+eax+1]
			jmp		Nxt
		.endif
	.endif
	ret

GroupGetProjectFiles endp

GroupAddNode proc uses esi,hTrv:HWND,lpFileName:DWORD,iNbr:DWORD,nGrp:DWORD,fModule:DWORD
	LOCAL	ftp:DWORD

	; Get parent node
	mov		eax,nGrp
	mov		edx,sizeof PROGROUP
	dec		eax
	mul		edx
	lea		esi,groupgrp[eax]
	; Find filetype
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
	add		eax,IML_START
	invoke Do_TreeViewAddNode,hTrv,[esi].PROGROUP.hGrp,NULL,lpFileName,eax,eax,iNbr
	ret

GroupAddNode endp

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

GroupUpdateTrv proc uses ebx esi edi,hTrv:HWND
	LOCAL	iNbr:DWORD
	LOCAL	iInx:DWORD
	LOCAL	hPrevPro[32]:DWORD

	.if hGrpRoot
		invoke SendMessage,hTrv,TVM_DELETEITEM,0,hGrpRoot
	.endif
	; Add root
	invoke Do_TreeViewAddNode,hTrv,TVI_ROOT,NULL,addr ProjectDescr,IML_START+0,IML_START+0,0
	mov		hGrpRoot,eax
	mov		hPrevPro[0],eax
	; Add project groups
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
			mov		edx,iInx
			invoke Do_TreeViewAddNode,hTrv,hPrevPro[edx*4],NULL,esi,IML_START+0,IML_START+0,ebx
			mov		edx,iInx
			inc		edx
			mov		hPrevPro[edx*4],eax
			pop		esi
		.else
			invoke Do_TreeViewAddNode,hTrv,hGrpRoot,NULL,esi,IML_START+0,IML_START+0,ebx
			mov		hPrevPro[4],eax
		.endif
		mov		[edi].PROGROUP.hGrp,eax
		mov		[edi].PROGROUP.lpszGrp,esi
		invoke strlen,esi
		lea		esi,[esi+eax+1]
		lea		edi,[edi+sizeof PROGROUP]
	.endw
	; Sort groups
	invoke SendMessage,hTrv,TVM_SORTCHILDREN,0,hGrpRoot
	xor		ebx,ebx
	mov		esi,offset groupgrp
	.while [esi].PROGROUP.lpszGrp
		mov		eax,[esi].PROGROUP.hGrp
		.if eax
			push	eax
			invoke SendMessage,hTrv,TVM_SORTCHILDREN,0,eax
			pop		edx
			.if groupexpand[ebx*4]
				invoke SendMessage,hTrv,TVM_EXPAND,TVE_EXPAND,edx
			.endif
		.endif
		lea		esi,[esi+sizeof PROGROUP]
		inc		ebx
	.endw
	; Add files
	mov		esi,offset profile
	.while [esi].PROFILE.lpszFile
		.if [esi].PROFILE.iNbr<PRO_START_OBJ
			invoke GroupAddNode,hTrv,[esi].PROFILE.lpszFile,[esi].PROFILE.iNbr,[esi].PROFILE.nGrp,FALSE
		.else
			invoke GroupAddNode,hTrv,[esi].PROFILE.lpszFile,[esi].PROFILE.iNbr,[esi].PROFILE.nGrp,TRUE
		.endif
		lea		esi,[esi+sizeof PROFILE]
	.endw
	xor		ebx,ebx
	mov		esi,offset groupgrp
	.while [esi].PROGROUP.lpszGrp
		mov		eax,[esi].PROGROUP.hGrp
		.if eax
			.if groupexpand[ebx*4]
				invoke SendMessage,hTrv,TVM_EXPAND,TVE_EXPAND,eax
			.endif
		.endif
		lea		esi,[esi+sizeof PROGROUP]
		inc		ebx
	.endw
	; Expand root
	invoke SendMessage,hTrv,TVM_EXPAND,TVE_EXPAND,hGrpRoot
	ret

GroupUpdateTrv endp

GroupGetExpand proc uses ebx esi edi,hTrv:HWND
	LOCAL	tvi:TVITEM
	
	mov		edi,offset groupgrp
	.while [edi].PROGROUP.hGrp
		mov		tvi._mask,TVIF_STATE
		mov		tvi.stateMask,TVIS_EXPANDED
		mov		eax,[edi].PROGROUP.hGrp
		mov		tvi.hItem,eax
		invoke SendMessage,hTrv,TVM_GETITEM,0,addr tvi
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

HasGroupItem proc hTrv:HWND,hItem:DWORD
	LOCAL	tvi:TV_ITEM

	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_CHILD,hItem
	.while eax
		mov		tvi.hItem,eax
		mov		tvi._mask,TVIF_PARAM
		invoke SendMessage,hTrv,TVM_GETITEM,0,addr tvi
		.if sdword ptr tvi.lParam>0 && eax
			.break
		.endif
		invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
	.endw
	ret

HasGroupItem endp

FindItem proc hTrv:HWND,hItem:DWORD,nInx:DWORD,nGroup:DWORD
	LOCAL	tvi:TV_ITEM

  @@:
	.if nInx
		mov		tvi._mask,TVIF_PARAM
		mov		eax,hItem
		mov		tvi.hItem,eax
		invoke SendMessage,hTrv,TVM_GETITEM,0,addr tvi
		mov		edx,nGroup
		.if edx==tvi.lParam
			mov		eax,hItem
			mov		edx,nInx
			ret
		.endif
	.endif
	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_CHILD,hItem
	.if eax
		mov		edx,nInx
		inc		edx
		invoke FindItem,hTrv,eax,edx,nGroup
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
	xor		edx,edx
	ret

FindItem endp

GroupUpdateGroup proc uses ebx esi edi,hTrv:HWND
	LOCAL	tvi:TV_ITEM

	mov		edi,offset szGroupGroupBuff
	invoke RtlZeroMemory,edi,sizeof szGroupGroupBuff
	xor		ebx,ebx
	.while sdword ptr ebx>-32
		dec		ebx
		invoke FindItem,hTrv,hGrpRoot,0,ebx
		.if eax
			mov		tvi._mask,TVIF_TEXT
			mov		tvi.hItem,eax
			.while edx>1
				mov		word ptr [edi],'..'
				add		edi,2
				dec		edx
			.endw
			mov		tvi.cchTextMax,64
			mov		tvi.pszText,edi
			invoke SendMessage,hTrv,TVM_GETITEM,0,addr tvi
			invoke strlen,edi
			lea		edi,[edi+eax+1]
		.endif
	.endw
	invoke GroupUpdateTrv,hTrv
	ret

GroupUpdateGroup endp

GroupGetFirstVisible proc hTrv:HWND
	LOCAL	tvi:TVITEM

	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_FIRSTVISIBLE,0
	mov		tvi.hItem,eax
	mov		tvi._mask,TVIF_HANDLE or TVIF_TEXT
	mov		tvi.pszText,offset szFirstVisible
	mov		tvi.cchTextMax,sizeof szFirstVisible
	invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
	ret

GroupGetFirstVisible endp

GroupEnsureVisible proc hTrv:HWND
	LOCAL	tvi:TVITEM
	LOCAL	buffer[256]:BYTE
	LOCAL	hPar:DWORD
	LOCAL	hVis:DWORD
	LOCAL	hLast:DWORD

	invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_ROOT,0
	mov		hVis,eax
	.if eax
		call	Compare
		invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_CHILD,tvi.hItem
		.while eax
			mov		hPar,eax
			call	Compare
			invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_CHILD,tvi.hItem
			.while eax
				call	Compare
				invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_NEXT,tvi.hItem
			.endw
			invoke SendMessage,hTrv,TVM_GETNEXTITEM,TVGN_NEXT,hPar
		.endw
		invoke SendMessage,hTrv,TVM_ENSUREVISIBLE,0,hLast
		invoke SendMessage,hTrv,TVM_ENSUREVISIBLE,0,hVis
	.endif
	ret

Compare:
	mov		hLast,eax
	mov		tvi.hItem,eax
	mov		tvi._mask,TVIF_HANDLE or TVIF_TEXT
	lea		eax,buffer
	mov		tvi.pszText,eax
	mov		tvi.cchTextMax,sizeof buffer
	invoke SendMessage,hTrv,TVM_GETITEM,0,addr tvi
	invoke strcmp,addr buffer,addr szFirstVisible
	.if !eax
		mov		eax,tvi.hItem
		mov		hVis,eax
	.endif
	retn

GroupEnsureVisible endp

SaveGroups proc uses esi,hTrv:HWND
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
	mov		esi,offset profile
	.while [esi].PROFILE.lpszFile
		invoke BinToDec,[esi].PROFILE.iNbr,addr buffer
		invoke BinToDec,[esi].PROFILE.nGrp,addr buffer1
		invoke WritePrivateProfileString,addr iniProjectGroup,addr buffer,addr buffer1,addr ProjectFile
		lea		esi,[esi+sizeof PROFILE]
	.endw
	invoke SendMessage,hTrv,TVM_DELETEITEM,0,hRoot
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
	LOCAL	nGrp:DWORD

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
		mov		tvi._mask,TVIF_PARAM
		mov		tvi.hItem,eax
		invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
		mov		edx,tvi.lParam
		mov		eax,tvi.hItem
		.if sdword ptr edx>=0
			invoke SendMessage,hGrpTrv,TVM_GETNEXTITEM,TVGN_PARENT,eax
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
		invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
		mov		ebx,tvi.lParam
		neg		ebx
		invoke lstrlen,addr buffer
		.if eax
			invoke GroupGetExpand,hGrpTrv
			mov		eax,TVDragItem
			mov		tvi.hItem,eax
			mov		tvi._mask,TVIF_PARAM
			invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
			mov		eax,tvi.lParam
			mov		esi,offset profile
			.while [esi].PROFILE.lpszFile
				.if eax==[esi].PROFILE.iNbr
					mov		[esi].PROFILE.nGrp,ebx
					.break
				.endif
				lea		esi,[esi+sizeof PROFILE]
			.endw
			invoke GroupGetFirstVisible,hGrpTrv
			invoke GroupUpdateTrv,hGrpTrv
			invoke GroupEnsureVisible,hGrpTrv
		.endif
	.endif
  Ex:
	ret

TVEndDrag endp

ProjectGroupsProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	buffer[64]:BYTE
	LOCAL	pt:POINT
	LOCAL	tvis:TV_INSERTSTRUCT
	LOCAL	tvi:TV_ITEM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke GetDlgItem,hWin,IDC_TRVPROJECT
		mov		hGrpTrv,eax
		invoke SendMessage,hGrpTrv,TVM_SETBKCOLOR,0,radcol.project
		invoke SendMessage,hGrpTrv,TVM_SETTEXTCOLOR,0,radcol.projecttext
		invoke SendMessage,hGrpTrv,TVM_SETIMAGELIST,0,hTbrIml
		mov		edi,offset szGroupGroupBuff
		mov		esi,offset szGroupBuff
		mov		ecx,sizeof szGroupGroupBuff
		rep movsb
		invoke GroupGetProjectFiles
		invoke GroupUpdateTrv,hGrpTrv
		invoke ExpandAll,hGrpTrv,0
		invoke SetDlgItemText,hWin,IDC_EDTDEFGROUP,addr szGroups
		invoke SetLanguage,hWin,IDD_DLGPROJECTGROUPS,FALSE
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke SaveGroups,hGrpTrv
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
					mov		ebx,eax
					.if sdword ptr eax<0
						invoke SendMessage,hGrpTrv,TVM_GETCOUNT,0,0
						.if eax>1
							mov		eax,ebx
							neg		eax
							mov		edx,offset profile
							.while [edx].PROFILE.lpszFile
								.if [edx].PROFILE.nGrp>=eax
									dec		[edx].PROFILE.nGrp
								.endif
								lea		edx,[edx+sizeof PROFILE]
							.endw
							invoke SendMessage,hGrpTrv,TVM_DELETEITEM,0,tvis.item.hItem
							.while sdword ptr ebx>-32
								dec		ebx
								invoke FindItem,hGrpTrv,hGrpRoot,0,ebx
								.if eax
									mov		tvi._mask,TVIF_PARAM
									mov		tvi.hItem,eax
									invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
									inc		tvi.lParam
									invoke SendMessage,hGrpTrv,TVM_SETITEM,0,addr tvi
								.endif
							.endw
							invoke GroupGetExpand,hGrpTrv
							invoke GroupUpdateGroup,hGrpTrv
							invoke GetDlgItem,hWin,IDC_BTNDELGROUP
							invoke EnableWindow,eax,FALSE
							invoke GetDlgItem,hWin,IDC_BTNADDGROUP
							invoke EnableWindow,eax,FALSE
						.endif
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
					mov		ebx,eax
					mov		edi,eax
					.if sdword ptr eax<=0
						invoke HasGroupItem,hGrpTrv,tvis.item.hItem
						.if eax
							dec		edi
						.endif
						mov		eax,edi
						neg		eax
						mov		edx,offset profile
						.while [edx].PROFILE.lpszFile
							.if [edx].PROFILE.nGrp>=eax
								inc		[edx].PROFILE.nGrp
							.endif
							lea		edx,[edx+sizeof PROFILE]
						.endw
						mov		edi,-32
						.while edi!=ebx
							invoke FindItem,hGrpTrv,hGrpRoot,0,edi
							.if eax
								mov		tvi._mask,TVIF_PARAM
								mov		tvi.hItem,eax
								invoke SendMessage,hGrpTrv,TVM_GETITEM,0,addr tvi
								dec		tvi.lParam
								invoke SendMessage,hGrpTrv,TVM_SETITEM,0,addr tvi
							.endif
							inc		edi
						.endw
						invoke GetDlgItemText,hWin,IDC_EDTGROUPS,addr buffer,sizeof buffer
						invoke SetDlgItemText,hWin,IDC_EDTGROUPS,addr szNULL
						mov		tvis.item._mask,TVIF_PARAM or TVIF_TEXT or TVIF_IMAGE or TVIF_SELECTEDIMAGE
						lea		eax,buffer
						mov		tvis.item.pszText,eax
						mov		tvis.item.iImage,IML_START+0
						mov		tvis.item.iSelectedImage,IML_START+0
						dec		tvis.item.lParam
						invoke SendMessage,hGrpTrv,TVM_INSERTITEM,0,addr tvis
						invoke GroupGetExpand,hGrpTrv
						invoke GroupUpdateGroup,hGrpTrv
						invoke GetDlgItem,hWin,IDC_BTNDELGROUP
						invoke EnableWindow,eax,FALSE
					.endif
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
		.elseif edx==NM_CLICK
PrintHex eax
		.endif
	.elseif eax==WM_NOTIFY
		mov		edx,lParam
		mov		eax,[edx].NMHDR.hwndFrom
		.if eax==hGrpTrv
			.if [edx].NMHDR.code==TVN_BEGINDRAGW
				invoke TVBeginDrag,hWin,[edx].NMHDR.hwndFrom,lParam
			.elseif [edx].NMHDR.code==TVN_SELCHANGEDW
				mov		eax,[edx].NM_TREEVIEW.itemNew.lParam
				.if sdword ptr eax<=0
					invoke GetDlgItem,hWin,IDC_BTNDELGROUP
					invoke EnableWindow,eax,TRUE
					invoke GetDlgItem,hWin,IDC_BTNADDGROUP
					push	eax
					invoke SendDlgItemMessage,hWin,IDC_EDTGROUPS,WM_GETTEXTLENGTH,0,0
					pop		edx
					invoke EnableWindow,edx,eax
				.else
					invoke GetDlgItem,hWin,IDC_BTNDELGROUP
					invoke EnableWindow,eax,FALSE
					invoke GetDlgItem,hWin,IDC_BTNADDGROUP
					invoke EnableWindow,eax,FALSE
				.endif
			.elseif [edx].NMHDR.code==TVN_BEGINLABELEDITW
				.if sdword ptr [edx].TV_DISPINFO.item.lParam>=0
					invoke SendMessage,[edx].NMHDR.hwndFrom,TVM_ENDEDITLABELNOW,TRUE,0
;					invoke SendMessage,[edx].NMHDR.hwndFrom,WM_CHAR,VK_RETURN,0
				.endif
			.elseif [edx].NMHDR.code==TVN_ENDLABELEDITW
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
	.elseif eax==WM_GETDLGCODE
	.else
		mov eax,FALSE
		ret
	.endif
	mov  eax,TRUE
	ret

ProjectGroupsProc endp