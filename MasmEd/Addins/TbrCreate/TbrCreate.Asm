;#########################################################################
;		Assembler directives

.486
.model flat,stdcall
option casemap:none

;#########################################################################
;		Include file

include TbrCreate.inc

.code

UpdateMenu proc hMnu:HMENU
	LOCAL	mii:MENUITEMINFO

	mov		mii.cbSize,sizeof MENUITEMINFO
	mov		mii.fMask,MIIM_ID or MIIM_TYPE
	mov		mii.fType,MFT_STRING
	mov		eax,MenuIDAddin
	mov		mii.wID,eax
	mov		mii.dwTypeData,offset szMenuItem
	invoke InsertMenuItem,hMnu,IDM_FILE_NEW_RES,FALSE,addr mii
	ret

UpdateMenu endp

TbrCreateProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	hTbr:HWND
	LOCAL	tbb:TBBUTTON
	LOCAL	hFile:HANDLE
	LOCAL	nSize:DWORD

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SetWindowLong,hWin,GWL_ID,IDC_USER
		invoke GetDlgItem,hWin,IDC_HMEM
		invoke SetWindowLong,eax,GWL_USERDATA,lParam
		invoke SendDlgItemMessage,hWin,IDC_EDTTBRNAME,EM_LIMITTEXT,31,0
		invoke SendDlgItemMessage,hWin,IDC_EDTTBRID,EM_LIMITTEXT,5,0
		invoke SendDlgItemMessage,hWin,IDC_EDTBTNNAME,EM_LIMITTEXT,31,0
		invoke SendDlgItemMessage,hWin,IDC_EDTBTNID,EM_LIMITTEXT,5,0
		invoke SendDlgItemMessage,hWin,IDC_EDTBMPNAME,EM_LIMITTEXT,31,0
		invoke SendDlgItemMessage,hWin,IDC_EDTBMPNBR,EM_LIMITTEXT,2,0
		invoke GetDlgItem,hWin,IDC_TBR2
		mov		hTbr,eax
		invoke SendMessage,hTbr,TB_BUTTONSTRUCTSIZE,SizeOf TBBUTTON,0
		invoke GetDlgItem,hWin,IDC_STCBTN
		invoke SetParent,hTbr,eax
		xor		ebx,ebx
		.while ebx<80
			lea		eax,[ebx+3000]
			mov		tbb.idCommand,eax
			mov		tbb.iBitmap,ebx
			mov		tbb.fsState,TBSTATE_ENABLED
			invoke SendMessage,hTbr,TB_ADDBUTTONS,1,addr tbb
			inc		ebx
		.endw
		invoke SendMessage,hTbr,TB_AUTOSIZE,0,0
		mov		ebx,lParam

		invoke CreateFile,addr [ebx].TBRMEM.tbrdef.FileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL
		.if eax!=INVALID_HANDLE_VALUE
			mov		hFile,eax
			invoke ReadFile,hFile,addr [ebx+sizeof TBRDEF],sizeof TBRMEM-sizeof TBRDEF,addr nSize,NULL
			invoke CloseHandle,hFile
		.endif
		invoke SetDlgItemText,hWin,IDC_EDTTBRNAME,addr [ebx].TBRMEM.tbr.szTbrName
		invoke SetDlgItemInt,hWin,IDC_EDTTBRID,addr [ebx].TBRMEM.tbr.nTbrID,FALSE
		.If [ebx].TBRMEM.tbr.szBmpName
			invoke SetDlgItemText,hWin,IDC_EDTBMPNAME,addr [ebx].TBRMEM.tbr.szBmpName
			invoke SetDlgItemInt,hWin,IDC_EDTBMPNBR,[ebx].TBRMEM.tbr.nBmp,FALSE
		.Else
			invoke SetDlgItemText,hWin,IDC_EDTBMPNAME,addr szSTD
			invoke SetDlgItemInt,hWin,IDC_EDTBMPNBR,15,FALSE
		.EndIf
		.if [ebx].TBRMEM.tbr.nBtnSize<16
			mov		[ebx].TBRMEM.tbr.nBtnSize,16
		.endif
		invoke SendDlgItemMessage,hWin,IDC_UDNSIZE,UDM_SETRANGE,0,00100030h							; Set range
		invoke SendDlgItemMessage,hWin,IDC_UDNSIZE,UDM_SETPOS,0,[ebx].TBRMEM.tbr.nBtnSize			; Set default value
		invoke SetDlgItemText,hWin,IDC_EDTBMPFILE,addr [ebx].TBRMEM.tbr.szBmpFile
;			SetImageList(hWin)
;			if lpTBR->nStyle and 1 then
;				CheckDlgButton(hWin,IDC_CHKTBRFLAT,BST_CHECKED)
;			endif
;			if lpTBR->nStyle and 2 then
;				CheckDlgButton(hWin,IDC_CHKTBRWRAP,BST_CHECKED)
;			endif
;			if lpTBR->nStyle and 4 then
;				CheckDlgButton(hWin,IDC_CHKTBRDIVIDER,BST_CHECKED)
;			endif
;			if lpTBR->nStyle and 8 then
;				CheckDlgButton(hWin,IDC_CHKTBRTIP,BST_CHECKED)
;			endif
;			if lpTBR->nStyle and 16 then
;				CheckDlgButton(hWin,IDC_CHKTBRLIST,BST_CHECKED)
;			endif
;			x=Cast(integer,lpTBR)
;			x=x+SizeOf(TBR)
;			lpTBRBTN=Cast(TBRBTN ptr,x)
;			i=0
;			while i<lpTBR->nBtn
;				SendDlgItemMessage(hWin,IDC_LSTBTN,LB_ADDSTRING,0,Cast(LPARAM,@lpTBRBTN->szBtnName))
;				nval=lpTBRBTN->nBtnID+(lpTBRBTN->nBmp SHL 16)+(lpTBRBTN->nStyle SHL 24)
;				SendDlgItemMessage(hWin,IDC_LSTBTN,LB_SETITEMDATA,i,nval)
;				x=Cast(integer,lpTBRBTN)
;				x=x+SizeOf(TBRBTN)
;				lpTBRBTN=Cast(TBRBTN ptr,x)
;				i=i+1
;			wend
;			SendDlgItemMessage(hWin,IDC_LSTBTN,LB_SETCURSEL,0,0)
;			SendMessage(hWin,WM_COMMAND,(LBN_SELCHANGE shl 16) or IDC_LSTBTN,0)
;			hBmp=LoadBitmap(hInstance,Cast(zstring ptr,IDB_ARROW))
;			hIml=ImageList_Create(16,16,ILC_COLOR8,4,0)
;			ImageList_Add(hIml,hBmp,NULL)
;			DeleteObject(hBmp)
;			SendDlgItemMessage(hWin,IDC_BTNUP,BM_SETIMAGE,IMAGE_ICON,Cast(LPARAM,ImageList_GetIcon(lpHANDLES->hmnuiml,2,ILD_NORMAL)))
;			SendDlgItemMessage(hWin,IDC_BTNDN,BM_SETIMAGE,IMAGE_ICON,Cast(LPARAM,ImageList_GetIcon(lpHANDLES->hmnuiml,3,ILD_NORMAL)))
;			ImageList_Destroy(hIml)
;			NewToolbar(hWin)
;			lpTBMEM->fChanged=FALSE

	.elseif eax==WM_DESTROY
		invoke GetProcessHeap
		push	eax
		invoke GetDlgItem,hWin,IDC_HMEM
		invoke GetWindowLong,eax,GWL_USERDATA
		pop		edx
		invoke HeapFree,edx,NULL,eax
;PrintHex eax
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TbrCreateProc endp

;#########################################################################
;Common AddIn Procedures

DllEntry proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD

	mov		eax,hInst
	mov		hInstance,eax
	mov		eax,TRUE
	ret

DllEntry Endp

OutputString proc uses ebx,lpString:DWORD

	mov		ebx,lpProc
	push	0
	call	[ebx].ADDINPROCS.lpOutputSelect
	push	TRUE
	call	[ebx].ADDINPROCS.lpOutputShow
	push	lpString
	call	[ebx].ADDINPROCS.lpOutputString
	ret

OutputString endp

; Export this proc
InstallAddin proc uses ebx,hWin:DWORD
	LOCAL	hook:HOOK

	mov		ebx,hWin
	;Get pointer to handles struct
	invoke SendMessage,ebx,AIM_GETHANDLES,0,0
	mov		lpHandles,eax
	;Get pointer to proc struct
	invoke SendMessage,ebx,AIM_GETPROCS,0,0
	mov		lpProc,eax
	;Get pointer to data struct
	invoke SendMessage,ebx,AIM_GETDATA,0,0	
	mov		lpData,eax
	invoke SendMessage,ebx,AIM_GETMENUID,0,0	
	mov		MenuIDAddin,eax
	mov		hook.hook1,HOOK_COMMAND or HOOK_DESTROY or HOOK_MENUUPDATE or HOOK_FILEOPEN or HOOK_FILECLOSE or HOOK_FILECLOSED
	xor		eax,eax
	mov		hook.hook2,eax
	mov		hook.hook3,eax
	mov		hook.hook4,eax
	lea		eax,hook
	ret 

InstallAddin endp

; Export this proc
AddinProc proc uses ebx esi edi,hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	; This proc handles messages sent from MasmEd to our addin
	; Return TRUE to prevent MasmEd and other addins from executing the command.
	LOCAL	buffer[MAX_PATH]:BYTE

	mov		eax,uMsg
	.if eax==AIM_COMMAND
		mov		eax,wParam
		.if eax==MenuIDAddin
			invoke GetProcessHeap
			invoke HeapAlloc,eax,HEAP_ZERO_MEMORY,sizeof TBRMEM
			mov		ebx,eax
			invoke lstrcpy,addr [ebx].TBRMEM.tbrdef.FileName,offset szNewFile
			invoke CreateDialogParam,hInstance,IDD_TBRCREATE,hWin,offset TbrCreateProc,ebx
			push	offset szNewFile
			push	eax
			mov		ebx,lpProc
			call	[ebx].ADDINPROCS.lpTabToolAdd
			call	[ebx].ADDINPROCS.lpTabToolActivate
			mov		eax,TRUE
			jmp		ExRet
		.endif
	.elseif eax==AIM_DESTROY
	.elseif eax==AIM_MENUUPDATE
		invoke UpdateMenu,wParam
	.elseif eax==AIM_FILEOPEN
		invoke lstrlen,lParam
		mov		edx,lParam
		.while byte ptr [edx+eax]!='.' && eax
			dec		eax
		.endw
		invoke lstrcmpi,addr [edx+eax],addr szTbr
		.if !eax
			invoke GetProcessHeap
			invoke HeapAlloc,eax,HEAP_ZERO_MEMORY,sizeof TBRMEM
			mov		ebx,eax
			invoke lstrcpy,addr [ebx].TBRMEM.tbrdef.FileName,lParam
			invoke CreateDialogParam,hInstance,IDD_TBRCREATE,hWin,offset TbrCreateProc,ebx
			push	lParam
			push	eax
			mov		ebx,lpProc
			call	[ebx].ADDINPROCS.lpTabToolAdd
			call	[ebx].ADDINPROCS.lpTabToolActivate
			mov		eax,TRUE
			jmp		ExRet
		.endif
	.elseif eax==AIM_FILECLOSE
		.if wParam==IDC_USER
			invoke GetDlgItem,hWin,IDC_HMEM
			.if eax
				invoke GetDlgItemText,hWin,IDC_HMEM,addr buffer,sizeof buffer
				.if dword ptr buffer=='CRBT'
				.endif
			.endif
		.endif
	.elseif eax==AIM_FILECLOSED
		.if wParam==IDC_USER
			invoke GetDlgItem,hWin,IDC_HMEM
			.if eax
				invoke GetDlgItemText,hWin,IDC_HMEM,addr buffer,sizeof buffer
				.if dword ptr buffer=='CRBT'
					invoke DestroyWindow,hWin
				.endif
			.endif
		.endif
	.endif
	mov		eax,FALSE
  ExRet:
	ret

AddinProc endp

;#########################################################################

end DllEntry
