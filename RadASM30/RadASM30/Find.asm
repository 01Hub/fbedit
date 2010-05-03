
;Find.dlg
IDD_DLGFIND						equ 2800
IDC_CBOFIND						equ 1002
IDC_BTNREPLACEALL				equ 1003
IDC_BTNREPLACE					equ 1004
IDC_STCREPLACE					equ 1007
IDC_EDTREPLACE					equ 1008
IDC_CHKMATCHCASE				equ 1009
IDC_CHKWHOLEWORD				equ 1010
IDC_CHKIGNOREWHITESPACE			equ 1011
IDC_CHKIGNORECOMMENTS			equ 1012
IDC_RBNDIRECTIONALL				equ 1014
IDC_RBNDIRECTIONUP				equ 1015
IDC_RBNDIRECTIONDOWN			equ 1016
IDC_RBNCURRENTSELECTION			equ 1018
IDC_RBNCURRENTPROCEDURE			equ 1019
IDC_RBNALLOPENFILES				equ 1020
IDC_RBNCURRENTMODULE			equ 1021
IDC_RBNALLPROJECTFILES			equ 1022

.data?

ntab			DWORD ?
findtabs		HWND 1024 dup(?)

.code

FindInit proc uses ebx esi edi,hWin:HWND,fallfiles:DWORD
	LOCAL	nInx:DWORD
	LOCAL	tci:TC_ITEM

	mov		da.find.fres,-1
	mov		da.find.nfound,0
	invoke SendMessage,hWin,EM_EXGETSEL,0,offset da.find.findchrg
	invoke SendMessage,hWin,EM_EXGETSEL,0,offset da.find.firstchrg
	mov		da.find.findchrg.cpMax,-2
	.if fallfiles==3
		invoke SendMessage,ha.hTab,TCM_GETCURSEL,0,0
		mov		esi,eax
		mov		nInx,eax
		mov		tci.imask,TCIF_PARAM
		mov		edi,offset findtabs
		mov		eax,TRUE
		.while TRUE
			invoke SendMessage,ha.hTab,TCM_GETITEM,esi,addr tci
			.break .if !eax
			call	AddCodeFile
			inc		esi
		.endw
		xor		esi,esi
		.while esi<nInx
			invoke SendMessage,ha.hTab,TCM_GETITEM,esi,addr tci
			.break .if !eax
			call	AddCodeFile
			inc		esi
		.endw
		xor		eax,eax
		mov		dword ptr [edi],eax
		mov		ntab,eax
	.endif
	ret

AddCodeFile:
	mov		ebx,tci.lParam
	invoke GetTheFileType,addr [ebx].TABMEM.filename
	.if eax==ID_EDITCODE
		mov		eax,[ebx].TABMEM.hedt
		mov		[edi],eax
		lea		edi,[edi+4]
	.endif
	retn

FindInit endp

FindSetup proc hWin:HWND

	;Get current selection
	invoke SendMessage,hWin,EM_EXGETSEL,0,offset da.find.ft.chrg
	;Setup find
	mov		eax,da.find.fdir
	.if eax==0
		;All
		.if da.find.fres!=-1
			mov		eax,da.find.ft.chrgText.cpMax
			mov		da.find.ft.chrg.cpMin,eax
		.else
			mov		eax,da.find.findchrg.cpMax
			.if eax!=-2
				mov		da.find.ft.chrg.cpMin,0
			.endif
		.endif
		mov		eax,da.find.findchrg.cpMax
		mov		da.find.ft.chrg.cpMax,eax
	.elseif eax==1
		;Down
		.if da.find.fres!=-1
			mov		eax,da.find.ft.chrgText.cpMax
			mov		da.find.ft.chrg.cpMin,eax
		.endif
		mov		da.find.ft.chrg.cpMax,-2
	.else
		;Up
		.if da.find.fres!=-1
			dec		da.find.ft.chrg.cpMin
		.endif
		mov		da.find.ft.chrg.cpMax,0
	.endif
	mov		da.find.ft.lpstrText,offset da.find.szfindbuff
	ret

FindSetup endp

Find proc hWin:HWND,frType:DWORD

FindNext:
	invoke FindSetup,hWin
	;Do the find
	invoke SendMessage,hWin,EM_FINDTEXTEX,da.find.fr,offset da.find.ft
	mov		da.find.fres,eax
	.if eax==-1
		mov		eax,da.find.findchrg.cpMin
		.if da.find.fdir==0 && eax
			dec		eax
			mov		da.find.findchrg.cpMax,eax
			mov		da.find.findchrg.cpMin,0
			jmp		FindNext
		.endif
		.if da.find.fscope==3
			inc		ntab
			mov		eax,ntab
			lea		edx,[offset findtabs+eax*4]
			mov		eax,[edx]
			.if eax
				mov		hWin,eax
				invoke FindInit,hWin,0
				jmp		FindNext
			.endif
		.endif
		;Region searched
		invoke SendMessage,hWin,EM_EXSETSEL,0,offset da.find.firstchrg
		invoke SendMessage,hWin,REM_VCENTER,0,0
		invoke SendMessage,hWin,EM_SCROLLCARET,0,0
		invoke MessageBox,ha.hFind,addr szRegionSearched,addr DisplayName,MB_OK or MB_ICONINFORMATION
	.else
		.if !da.find.nfound
			mov		eax,da.find.ft.chrgText.cpMin
			mov		da.find.firstchrg.cpMin,eax
			mov		eax,da.find.ft.chrgText.cpMax
			mov		da.find.firstchrg.cpMax,eax
		.endif
		mov		eax,hWin
		.if eax!=ha.hEdt
			invoke TabToolGetInx,hWin
			invoke SendMessage,ha.hTab,TCM_SETCURSEL,eax,0
			invoke TabToolActivate
		.endif
		;Mark the foud text
		invoke SendMessage,hWin,EM_EXSETSEL,0,offset da.find.ft.chrgText
		invoke SendMessage,hWin,REM_VCENTER,0,0
		invoke SendMessage,hWin,EM_SCROLLCARET,0,0
		inc		da.find.nfound
	.endif
	ret

Find endp

FindDialogProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	chrg:CHARRANGE

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		.if lParam
			call	ShowReplace
		.endif
		;Put text in edit boxes
		invoke SendDlgItemMessage,hWin,IDC_CBOFIND,EM_LIMITTEXT,255,0
		invoke SendDlgItemMessage,hWin,IDC_CBOFIND,WM_SETTEXT,0,offset da.find.szfindbuff
		invoke SendDlgItemMessage,hWin,IDC_EDTREPLACE,EM_LIMITTEXT,255,0
		invoke SendDlgItemMessage,hWin,IDC_EDTREPLACE,WM_SETTEXT,0,offset da.find.szreplacebuff
		;Set check boxes
		test	da.find.fr,FR_MATCHCASE
		.if !ZERO?
			invoke CheckDlgButton,hWin,IDC_CHKMATCHCASE,BST_CHECKED
		.endif
		test	da.find.fr,FR_WHOLEWORD
		.if !ZERO?
			invoke CheckDlgButton,hWin,IDC_CHKWHOLEWORD,BST_CHECKED
		.endif
		test	da.find.fr,FR_IGNOREWHITESPACE
		.if !ZERO?
			invoke CheckDlgButton,hWin,IDC_CHKIGNOREWHITESPACE,BST_CHECKED
		.endif
		test	da.find.fr,FR_IGNORECOMMENTS
		.if !ZERO?
			invoke CheckDlgButton,hWin,IDC_CHKIGNORECOMMENTS,BST_CHECKED
		.endif
		;Set find direction
		mov		eax,da.find.fdir
		.if eax==0
			or		da.find.fr,FR_DOWN
			mov		eax,IDC_RBNDIRECTIONALL
		.elseif eax==1
			or		da.find.fr,FR_DOWN
			mov		eax,IDC_RBNDIRECTIONDOWN
		.else
			and		da.find.fr,-1 xor FR_DOWN
			mov		eax,IDC_RBNDIRECTIONUP
		.endif
		invoke CheckDlgButton,hWin,eax,BST_CHECKED
		mov		chrg.cpMin,0
		mov		chrg.cpMax,0
		.if ha.hMdi
			invoke GetWindowLong,ha.hEdt,GWL_ID
			.if eax==ID_EDITCODE
				invoke SendMessage,ha.hEdt,EM_EXGETSEL,0,addr chrg
			.endif
		.endif
		;Set scope
		invoke GetDlgItem,hWin,IDC_RBNALLPROJECTFILES
		invoke EnableWindow,eax,da.fProject
		mov		edx,chrg.cpMax
		sub		edx,chrg.cpMin
		.if !edx
			invoke GetDlgItem,hWin,IDC_RBNCURRENTSELECTION
			invoke EnableWindow,eax,FALSE
			xor		edx,edx
		.endif
		mov		eax,da.find.fscope
		.if eax==0 && edx!=0
			;Current selection
			mov		eax,IDC_RBNCURRENTSELECTION
		.elseif eax==1
			;Current procedure
			mov		eax,IDC_RBNCURRENTPROCEDURE
		.elseif eax==2 || !eax
			;Current module
			mov		eax,IDC_RBNCURRENTMODULE
		.elseif eax==3 || (eax==4 && !da.fProject)
			;All open file
			mov		eax,IDC_RBNALLOPENFILES
		.elseif eax==4 && da.fProject
			;All project files
			mov		eax,IDC_RBNALLPROJECTFILES
		.endif
		invoke CheckDlgButton,hWin,eax,BST_CHECKED
;		invoke SetWindowPos,hWin,0,findpt.x,findpt.y,0,0,SWP_NOSIZE or SWP_NOZORDER
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDOK
				invoke Find,ha.hEdt,da.find.fr
			.elseif eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,NULL,NULL
			.elseif eax==IDC_BTNREPLACE
				invoke GetDlgItem,hWin,IDC_BTNREPLACEALL
				invoke IsWindowVisible,eax
				.if !eax
					call	ShowReplace
				.else
				.endif
			.elseif eax==IDC_RBNDIRECTIONALL
				;Set find direction to down
				or		da.find.fr,FR_DOWN
				mov		da.find.fdir,0
				invoke FindInit,ha.hEdt,da.find.fscope
			.elseif eax==IDC_RBNDIRECTIONDOWN
				;Set find direction to down
				or		da.find.fr,FR_DOWN
				mov		da.find.fdir,1
				invoke FindInit,ha.hEdt,da.find.fscope
			.elseif eax==IDC_RBNDIRECTIONUP
				;Set find direction to up
				and		da.find.fr,-1 xor FR_DOWN
				mov		da.find.fdir,2
				invoke FindInit,ha.hEdt,da.find.fscope
			.elseif eax==IDC_CHKMATCHCASE
				;Set match case mode
				invoke IsDlgButtonChecked,hWin,IDC_CHKMATCHCASE
				.if eax
					or		da.find.fr,FR_MATCHCASE
				.else
					and		da.find.fr,-1 xor FR_MATCHCASE
				.endif
				invoke FindInit,ha.hEdt,da.find.fscope
			.elseif eax==IDC_CHKWHOLEWORD
				;Set whole word mode
				invoke IsDlgButtonChecked,hWin,IDC_CHKWHOLEWORD
				.if eax
					or		da.find.fr,FR_WHOLEWORD
				.else
					and		da.find.fr,-1 xor FR_WHOLEWORD
				.endif
				invoke FindInit,ha.hEdt,da.find.fscope
			.elseif eax==IDC_CHKIGNOREWHITESPACE
				invoke IsDlgButtonChecked,hWin,IDC_CHKIGNOREWHITESPACE
				.if eax
					or		da.find.fr,FR_IGNOREWHITESPACE
				.else
					and		da.find.fr,-1 xor FR_IGNOREWHITESPACE
				.endif
				invoke FindInit,ha.hEdt,da.find.fscope
			.elseif eax==IDC_CHKIGNORECOMMENTS
				invoke IsDlgButtonChecked,hWin,IDC_CHKIGNORECOMMENTS
				.if eax
					or		da.find.fr,FR_IGNORECOMMENTS
				.else
					and		da.find.fr,-1 xor FR_IGNORECOMMENTS
				.endif
				invoke FindInit,ha.hEdt,da.find.fscope
			.endif
		.elseif edx==EN_CHANGE
			.if eax==IDC_EDTREPLACE
				invoke GetDlgItemText,hWin,IDC_EDTREPLACE,addr da.find.szreplacebuff,sizeof da.find.szreplacebuff
				invoke FindInit,ha.hEdt,da.find.fscope
			.endif
		.elseif edx==CBN_EDITCHANGE
			.if eax==IDC_CBOFIND
				invoke GetDlgItemText,hWin,IDC_CBOFIND,addr da.find.szfindbuff,sizeof da.find.szfindbuff
				invoke FindInit,ha.hEdt,da.find.fscope
			.endif
		.endif
	.elseif eax==WM_ACTIVATE
		mov		eax,wParam
		movzx	eax,ax
		.if eax==WA_INACTIVE
			mov		ha.hModeless,0
		.else
			mov		eax,hWin
			mov		ha.hModeless,eax
			mov		ha.hFind,eax
			invoke FindInit,ha.hEdt,da.find.fscope
		.endif
	.elseif eax==WM_CLOSE
		invoke SetFocus,ha.hEdt
		invoke DestroyWindow,hWin
		mov		ha.hFind,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

ShowReplace:
	invoke GetDlgItem,hWin,IDC_STCREPLACE
	invoke ShowWindow,eax,SW_SHOWNA
	invoke GetDlgItem,hWin,IDC_EDTREPLACE
	invoke ShowWindow,eax,SW_SHOWNA
	invoke GetDlgItem,hWin,IDC_BTNREPLACEALL
	invoke ShowWindow,eax,SW_SHOWNA
	retn

FindDialogProc endp

