
IDD_TABOPTIONS		equ 2050
IDC_TABOPT			equ 2001

IDD_TABOPT1			equ 2100
IDC_RBNEXPOPT1		equ 2101
IDC_RBNEXPOPT2		equ 2102
IDC_RBNEXPOPT3		equ 2103
IDC_RBNEXPOPT4		equ 2104
IDC_RBNEXPORTFILE	equ 2110
IDC_RBNEXPORTCLIP	equ 2111
IDC_RBNEXPORTOUT	equ 2112
IDC_EDTEXPOPT		equ 2113
IDC_CHKAUTOEXPORT	equ 2114

IDD_TABOPT2			equ 2200
IDC_LSTCUST			equ 2201
IDC_BTNCUSTUP		equ 2202
IDC_BTNCUSTDN		equ 2203
IDC_BTNCUSTADD		equ 2204
IDC_BTNCUSTDEL		equ 2205
IDC_EDTCUST			equ 2206
IDC_BTNCUST			equ 2207

IDD_TABOPT3			equ 2300
IDC_EDTX			equ 4008
IDC_EDTY			equ 4005
IDC_UDNX			equ 4007
IDC_UDNY			equ 4004
IDC_STCCOLOR		equ 4006
IDC_CHKSNAPGRID		equ 4002
IDC_CHKSHOWGRID		equ 4003
IDC_CHKSHOWTIP		equ 4001
IDC_CHKGRIDLINE		equ 4009
IDC_CHKSTYLEHEX		equ 4010

.const

szCust				db 'Cust#',0
szFilterDLL			db 'Dll (*.dll)',0,'*.dll',0,0

TabTitle1			db 'Exports',0
TabTitle2			db 'Custom controls',0
TabTitle3			db 'Behaviour',0

.data?

hTabOpt				dd ?
hTabDlg				dd 3 dup(?)
SelTab				dd ?
color				dd ?
hBr					dd ?

.code

TabOpt1Proc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,nmeexp.nType
		add		eax,IDC_RBNEXPOPT1
		invoke CheckRadioButton,hWin,IDC_RBNEXPOPT1,IDC_RBNEXPOPT4,eax
		mov		eax,nmeexp.nOutput
		add		eax,IDC_RBNEXPORTFILE
		invoke CheckRadioButton,hWin,IDC_RBNEXPORTFILE,IDC_RBNEXPORTOUT,eax
		invoke SetDlgItemText,hWin,IDC_EDTEXPOPT,addr nmeexp.szFileName
		invoke SendDlgItemMessage,hWin,IDC_EDTEXPOPT,EM_LIMITTEXT,MAX_PATH,0
		invoke SendDlgItemMessage,hWin,IDC_EDTEXPOPT,EM_LIMITTEXT,MAX_PATH,0
		mov		eax,nmeexp.fAuto
		.if eax
			mov		eax,BST_CHECKED
		.else
			mov		eax,BST_UNCHECKED
		.endif
		invoke CheckDlgButton,hWin,IDC_CHKAUTOEXPORT,eax
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabOpt1Proc endp

TabOpt2Proc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	nInx:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[64]:BYTE
	LOCAL	ofn:OPENFILENAME

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke ImageList_GetIcon,hMnuIml,2,ILD_NORMAL
		invoke SendDlgItemMessage,hWin,IDC_BTNCUSTUP,BM_SETIMAGE,IMAGE_ICON,eax
		invoke ImageList_GetIcon,hMnuIml,3,ILD_NORMAL
		invoke SendDlgItemMessage,hWin,IDC_BTNCUSTDN,BM_SETIMAGE,IMAGE_ICON,eax
		invoke SendDlgItemMessage,hWin,IDC_EDTCUST,EM_LIMITTEXT,MAX_PATH-1,0
		mov		nInx,1
		.while nInx<=32
			invoke MakeKey,addr szCust,nInx,addr buffer1
			mov		lpcbData,MAX_PATH
			mov		buffer,0
			invoke RegQueryValueEx,hReg,addr buffer1,0,addr lpType,addr buffer,addr lpcbData
			.if buffer
				invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_ADDSTRING,0,addr buffer
			.endif
			inc		nInx
		.endw
		invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_SETCURSEL,0,0
	.elseif eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDC_BTNCUSTADD
				invoke GetDlgItemText,hWin,IDC_EDTCUST,addr buffer,sizeof buffer
				invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_ADDSTRING,0,addr buffer
				invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_SETCURSEL,eax,0
				mov		buffer,0
				invoke SetDlgItemText,hWin,IDC_EDTCUST,addr buffer
			.elseif eax==IDC_BTNCUSTDEL
				invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_GETCURSEL,0,0
				.if eax!=LB_ERR
					mov		nInx,eax
					invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_DELETESTRING,eax,0
					invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_SETCURSEL,nInx,0
					.if eax==LB_ERR
						dec		nInx
						invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_SETCURSEL,nInx,0
					.endif
				.endif
			.elseif eax==IDC_BTNCUSTUP
				invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_GETCURSEL,0,0
				.if eax
					mov		nInx,eax
					invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_GETTEXT,nInx,addr buffer
					invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_DELETESTRING,nInx,0
					dec		nInx
					invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_INSERTSTRING,nInx,addr buffer
					invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_SETCURSEL,nInx,0
				.endif
			.elseif eax==IDC_BTNCUSTDN
				invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_GETCURSEL,0,0
				mov		nInx,eax
				invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_GETCOUNT,0,0
				dec		eax
				.if eax!=nInx
					invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_GETTEXT,nInx,addr buffer
					invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_DELETESTRING,nInx,0
					inc		nInx
					invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_INSERTSTRING,nInx,addr buffer
					invoke SendDlgItemMessage,hWin,IDC_LSTCUST,LB_SETCURSEL,nInx,0
				.endif
			.elseif eax==IDC_BTNCUST
				invoke RtlZeroMemory,addr ofn,sizeof ofn
				mov		ofn.lStructSize,sizeof ofn
				push	hWin
				pop		ofn.hwndOwner
				push	hInstance
				pop		ofn.hInstance
				mov		ofn.lpstrInitialDir,NULL
				mov		ofn.lpstrFilter,offset szFilterDLL
				mov		ofn.lpstrDefExt,0
				mov		ofn.lpstrTitle,0
				lea		eax,buffer
				mov		ofn.lpstrFile,eax
				invoke GetDlgItemText,hWin,IDC_EDTCUST,addr buffer,sizeof buffer
				mov		ofn.nMaxFile,sizeof buffer
				mov		ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST
				invoke GetOpenFileName,addr ofn
				.if eax
					invoke SetDlgItemText,hWin,IDC_EDTCUST,addr buffer
				.endif
			.endif
		.elseif edx==EN_CHANGE
			.if eax==IDC_EDTCUST
				invoke GetDlgItem,hWin,IDC_BTNCUSTADD
				push	eax
				invoke SendDlgItemMessage,hWin,IDC_EDTCUST,WM_GETTEXTLENGTH,0,0
				pop		edx
				invoke EnableWindow,edx,eax
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabOpt2Proc endp

TabOpt3Proc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	cc:CHOOSECOLOR

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_UDNX,UDM_SETRANGE,0,00020014h	; Set range
		invoke SendDlgItemMessage,hWin,IDC_UDNX,UDM_SETPOS,0,grdsize.x		; Set default value
		invoke SendDlgItemMessage,hWin,IDC_UDNY,UDM_SETRANGE,0,00020014h	; Set range
		invoke SendDlgItemMessage,hWin,IDC_UDNY,UDM_SETPOS,0,grdsize.y		; Set default value
		invoke CheckDlgButton,hWin,IDC_CHKSHOWGRID,grdsize.show
		invoke CheckDlgButton,hWin,IDC_CHKSNAPGRID,grdsize.snap
		invoke CheckDlgButton,hWin,IDC_CHKSHOWTIP,grdsize.tips
		invoke CheckDlgButton,hWin,IDC_CHKGRIDLINE,grdsize.line
	.elseif eax==WM_DRAWITEM
		mov		edx,lParam
		invoke FillRect,[edx].DRAWITEMSTRUCT.hdc,addr [edx].DRAWITEMSTRUCT.rcItem,hBr
	.elseif eax==WM_COMMAND
		.if wParam==IDC_STCCOLOR
			mov		cc.lStructSize,sizeof CHOOSECOLOR
			mov		eax,hWin
			mov		cc.hwndOwner,eax
			mov		eax,hInstance
			mov		cc.hInstance,eax
			mov		cc.lpCustColors,offset CustColors
			mov		cc.Flags,CC_FULLOPEN or CC_RGBINIT
			mov		cc.lCustData,0
			mov		cc.lpfnHook,0
			mov		cc.lpTemplateName,0
			mov		eax,color
			mov		cc.rgbResult,eax
			invoke ChooseColor,addr cc
			.if eax
				invoke DeleteObject,hBr
				mov		eax,cc.rgbResult
				mov		color,eax
				invoke CreateSolidBrush,eax
				mov		hBr,eax
				invoke GetDlgItem,hWin,IDC_STCCOLOR
				invoke InvalidateRect,eax,NULL,TRUE
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabOpt3Proc endp

TabOptionsProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM
	LOCAL	ts:TCITEM
	LOCAL	nInx:DWORD
	LOCAL	buffer[MAX_PATH]:BYTE
	LOCAL	buffer1[64]:BYTE

	mov		eax,uMsg
	.if eax==WM_COMMAND
		mov		edx,wParam
		movzx	eax,dx
		shr		edx,16
		.if edx==BN_CLICKED
			.if eax==IDCANCEL
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.elseif eax==IDOK
				invoke IsDlgButtonChecked,hTabDlg,IDC_RBNEXPOPT1
				.if eax
					mov		nmeexp.nType,0
				.else
					invoke IsDlgButtonChecked,hTabDlg,IDC_RBNEXPOPT2
					.if eax
						mov		nmeexp.nType,1
					.else
						invoke IsDlgButtonChecked,hTabDlg,IDC_RBNEXPOPT3
						.if eax
							mov		nmeexp.nType,2
						.else
							mov		nmeexp.nType,3
						.endif
					.endif
				.endif
				invoke IsDlgButtonChecked,hTabDlg,IDC_RBNEXPORTFILE
				.if eax
					mov		nmeexp.nOutput,0
				.else
					invoke IsDlgButtonChecked,hTabDlg,IDC_RBNEXPORTCLIP
					.if eax
						mov		nmeexp.nOutput,1
					.else
						mov		nmeexp.nOutput,2
					.endif
				.endif
				invoke GetDlgItemText,hTabDlg,IDC_EDTEXPOPT,addr nmeexp.szFileName,sizeof nmeexp.szFileName
				invoke IsDlgButtonChecked,hTabDlg,IDC_CHKAUTOEXPORT
				.if eax
					mov		nmeexp.fAuto,1
				.else
					mov		nmeexp.fAuto,0
				.endif
				invoke RegSetValueEx,hReg,addr szNmeExp,0,REG_BINARY,addr nmeexp,sizeof nmeexp
				mov		edx,nmeexp.nOutput
				shl		edx,16
				add		edx,nmeexp.nType
				invoke SendMessage,hResEd,PRO_SETEXPORT,edx,addr nmeexp.szFileName
				mov		nInx,0
				.while nInx<=32
					mov		buffer,0
					invoke SendDlgItemMessage,hTabDlg[4],IDC_LSTCUST,LB_GETTEXT,nInx,addr buffer
					inc		nInx
					invoke MakeKey,addr szCust,nInx,addr buffer1
					invoke lstrlen,addr buffer
					inc		eax
					invoke RegSetValueEx,hReg,addr buffer1,0,REG_SZ,addr buffer,eax
				.endw
				invoke GetDlgItemInt,hTabDlg[8],IDC_EDTX,NULL,FALSE
				mov		grdsize.x,eax
				invoke GetDlgItemInt,hTabDlg[8],IDC_EDTY,NULL,FALSE
				mov		grdsize.y,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKSHOWGRID
				mov		grdsize.show,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKSNAPGRID
				mov		grdsize.snap,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKSHOWTIP
				mov		grdsize.tips,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKGRIDLINE
				mov		grdsize.line,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKSTYLEHEX
				mov		grdsize.stylehex,eax
				mov		eax,color
				mov		grdsize.color,eax
				invoke RegSetValueEx,hReg,addr szGrid,0,REG_BINARY,addr grdsize,sizeof grdsize
				mov		eax,grdsize.y
				shl		eax,16
				add		eax,grdsize.x
				mov		edx,grdsize.line
				shl		edx,24
				add		edx,grdsize.color
				invoke SendMessage,hResEd,DEM_SETGRIDSIZE,eax,edx
				invoke GetWindowLong,hResEd,GWL_STYLE
				and		eax,-1 xor (DES_GRID or DES_SNAPTOGRID or DES_TOOLTIP or DES_STYLEHEX)
				.if grdsize.show
					or		eax,DES_GRID
				.endif
				.if grdsize.snap
					or		eax,DES_SNAPTOGRID
				.endif
				.if grdsize.tips
					or		eax,DES_TOOLTIP
				.endif
				.if grdsize.stylehex
					or		eax,DES_STYLEHEX
				.endif
				invoke SetWindowLong,hResEd,GWL_STYLE,eax
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.endif
		.endif
	.elseif eax==WM_NOTIFY
		mov		eax,lParam
		mov		eax,[eax].NMHDR.code
		.if eax==TCN_SELCHANGE
			;Tab selection
			invoke SendMessage,hTabOpt,TCM_GETCURSEL,0,0
			.if eax!=SelTab
				push	eax
				mov		eax,SelTab
				invoke ShowWindow,[hTabDlg+eax*4],SW_HIDE
				pop		eax
				mov		SelTab,eax
				invoke ShowWindow,[hTabDlg+eax*4],SW_SHOWDEFAULT
			.endif
		.endif
	.elseif eax==WM_INITDIALOG
		mov		eax,grdsize.color
		mov		color,eax
		invoke CreateSolidBrush,eax
		mov		hBr,eax
		;Create the tabs
		invoke GetDlgItem,hWin,IDC_TABOPT
		mov		hTabOpt,eax
		mov		ts.imask,TCIF_TEXT
		mov		ts.iImage,-1
		mov		ts.lParam,0
		mov		ts.pszText,offset TabTitle1
		mov		ts.cchTextMax,sizeof TabTitle1
		invoke SendMessage,hTabOpt,TCM_INSERTITEM,0,addr ts
		mov		ts.pszText,offset TabTitle2
		mov		ts.cchTextMax,sizeof TabTitle2
		invoke SendMessage,hTabOpt,TCM_INSERTITEM,1,addr ts
		mov		ts.pszText,offset TabTitle3
		mov		ts.cchTextMax,sizeof TabTitle3
		invoke SendMessage,hTabOpt,TCM_INSERTITEM,2,addr ts
		;Create the tab dialogs
		invoke CreateDialogParam,hInstance,IDD_TABOPT1,hTabOpt,addr TabOpt1Proc,0
		mov		hTabDlg,eax
		invoke CreateDialogParam,hInstance,IDD_TABOPT2,hTabOpt,addr TabOpt2Proc,0
		mov		hTabDlg[4],eax
		invoke CreateDialogParam,hInstance,IDD_TABOPT3,hTabOpt,addr TabOpt3Proc,0
		mov		hTabDlg[8],eax
		mov		SelTab,0
	.elseif eax==WM_CLOSE
		invoke DeleteObject,hBr
		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabOptionsProc endp
