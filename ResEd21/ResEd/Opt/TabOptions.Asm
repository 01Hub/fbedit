
IDD_TABOPTIONS		equ 2410
IDC_TABOPT			equ 2001

IDD_TABOPT1			equ 2100
IDC_RBNEXPOPT1		equ 2101
IDC_RBNEXPOPT2		equ 2102
IDC_RBNEXPOPT3		equ 2103
IDC_RBNEXPOPT4		equ 2104
IDC_RBNEXPOPT5		equ 2105
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
IDC_STCGRIDCOLOR	equ 4006
IDC_STCBACKCOLOR	equ 4011
IDC_STCTEXTCOLOR	equ 4013
IDC_CHKSNAPGRID		equ 4002
IDC_CHKSHOWGRID		equ 4003
IDC_CHKSHOWTIP		equ 4001
IDC_CHKGRIDLINE		equ 4009
IDC_CHKSTYLEHEX		equ 4010
IDC_CHKSIZETOFONT	equ 4012
IDC_CHKNODEFINE		equ 4014
IDC_CHKSIMPLE		equ 4015
IDC_CHKIDC_STATIC	equ 4016
IDC_CHKSTANDARD		equ 4017
IDC_CHKBORLANDCOMP	equ 4018
IDC_BTNFONT			equ 4019
IDC_STCFONT			equ 4020

IDD_TABOPT4			equ 2400
IDC_EDTDLGSTART		equ 1001
IDC_EDTDLGINC		equ 1002
IDC_EDTMNUSTART		equ 1003
IDC_EDTMNUINC		equ 1004
IDC_EDTRCDSTART		equ 1006
IDC_EDTRCDINC		equ 1005
IDC_EDTRESSTART		equ 1008
IDC_EDTRESINC		equ 1007

.const

szNmeExp			db 'NmeExp',0
szCust				db 'Cust#',0
szFilterDLL			db 'Dll (*.dll)',0,'*.dll',0,0
szGrid				db 'Grid',0
szColor				db 'Color',0
szInitID			db 'InitID',0
szTextFont			db 'TextFont',0

TabTitle1			db 'Exports',0
TabTitle2			db 'Custom controls',0
TabTitle3			db 'Behaviour',0
TabTitle4			db "Resource ID's",0

.data?

hTab				dd ?
hTabDlg				dd 4 dup(?)
SelTab				dd ?
gridcolor			dd ?
backcolor			dd ?
textcolor			dd ?
hBrGrid				dd ?
hBrBack				dd ?
hBrText				dd ?
CustColors			dd 16 dup(?)
cflf				LOGFONT <>
hfnt				HFONT ?

.code

TabOpt1Proc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		mov		eax,nmeexp.nType
		add		eax,IDC_RBNEXPOPT1
		invoke CheckRadioButton,hWin,IDC_RBNEXPOPT1,IDC_RBNEXPOPT5,eax
		mov		eax,nmeexp.nOutput
		add		eax,IDC_RBNEXPORTFILE
		invoke CheckRadioButton,hWin,IDC_RBNEXPORTFILE,IDC_RBNEXPORTOUT,eax
		invoke SetDlgItemText,hWin,IDC_EDTEXPOPT,addr nmeexp.szFileName
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
		invoke ImageList_GetIcon,hIml,2,ILD_NORMAL
		invoke SendDlgItemMessage,hWin,IDC_BTNCUSTUP,BM_SETIMAGE,IMAGE_ICON,eax
		invoke ImageList_GetIcon,hIml,3,ILD_NORMAL
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
	LOCAL	cf:CHOOSEFONT

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SendDlgItemMessage,hWin,IDC_UDNX,UDM_SETRANGE,0,00020014h	; Set range
		invoke SendDlgItemMessage,hWin,IDC_UDNX,UDM_SETPOS,0,grdsize.x		; Set default value
		invoke SendDlgItemMessage,hWin,IDC_UDNY,UDM_SETRANGE,0,00020014h	; Set range
		invoke SendDlgItemMessage,hWin,IDC_UDNY,UDM_SETPOS,0,grdsize.y		; Set default value
		invoke SendDlgItemMessage,hWin,IDC_STCFONT,WM_SETFONT,hfnt,FALSE
		invoke CheckDlgButton,hWin,IDC_CHKSHOWGRID,grdsize.show
		invoke CheckDlgButton,hWin,IDC_CHKSNAPGRID,grdsize.snap
		invoke CheckDlgButton,hWin,IDC_CHKSHOWTIP,grdsize.tips
		invoke CheckDlgButton,hWin,IDC_CHKGRIDLINE,grdsize.line
		invoke CheckDlgButton,hWin,IDC_CHKSTYLEHEX,grdsize.stylehex
		invoke CheckDlgButton,hWin,IDC_CHKSIZETOFONT,grdsize.sizetofont
		invoke CheckDlgButton,hWin,IDC_CHKNODEFINE,grdsize.nodefines
		invoke CheckDlgButton,hWin,IDC_CHKSIMPLE,grdsize.simple
		invoke CheckDlgButton,hWin,IDC_CHKIDC_STATIC,grdsize.defstatic
		invoke CheckDlgButton,hWin,IDC_CHKSTANDARD,grdsize.standardmnu
		invoke CheckDlgButton,hWin,IDC_CHKBORLANDCOMP,grdsize.borlandcomp
	.elseif eax==WM_DRAWITEM
		mov		eax,wParam
		.if eax==IDC_STCGRIDCOLOR
			mov		eax,hBrGrid
		.elseif eax==IDC_STCBACKCOLOR
			mov		eax,hBrBack
		.elseif eax==IDC_STCTEXTCOLOR
			mov		eax,hBrText
		.endif
		mov		edx,lParam
		invoke FillRect,[edx].DRAWITEMSTRUCT.hdc,addr [edx].DRAWITEMSTRUCT.rcItem,eax
	.elseif eax==WM_COMMAND
		mov		eax,wParam
		mov		edx,eax
		shr		edx,16
		movzx	eax,ax
		.if edx==BN_CLICKED
			.if eax==IDC_STCGRIDCOLOR
				mov		eax,gridcolor
				call	GetColor
				.if eax
					invoke DeleteObject,hBrGrid
					mov		eax,cc.rgbResult
					mov		gridcolor,eax
					invoke CreateSolidBrush,eax
					mov		hBrGrid,eax
					invoke GetDlgItem,hWin,IDC_STCGRIDCOLOR
					invoke InvalidateRect,eax,NULL,TRUE
				.endif
			.elseif eax==IDC_STCBACKCOLOR
				mov		eax,backcolor
				call	GetColor
				.if eax
					invoke DeleteObject,hBrBack
					mov		eax,cc.rgbResult
					mov		backcolor,eax
					invoke CreateSolidBrush,eax
					mov		hBrBack,eax
					invoke GetDlgItem,hWin,IDC_STCBACKCOLOR
					invoke InvalidateRect,eax,NULL,TRUE
				.endif
			.elseif eax==IDC_STCTEXTCOLOR
				mov		eax,textcolor
				call	GetColor
				.if eax
					invoke DeleteObject,hBrText
					mov		eax,cc.rgbResult
					mov		textcolor,eax
					invoke CreateSolidBrush,eax
					mov		hBrText,eax
					invoke GetDlgItem,hWin,IDC_STCTEXTCOLOR
					invoke InvalidateRect,eax,NULL,TRUE
				.endif
			.elseif eax==IDC_BTNFONT
				mov		cf.lStructSize,sizeof CHOOSEFONT
				invoke GetDC,hWin
				mov		cf.hDC,eax
				push	hWin
				pop		cf.hWndOwner
				mov		cf.lpLogFont,offset cflf
				mov		cf.iPointSize,0
				mov		cf.Flags,CF_SCREENFONTS or CF_INITTOLOGFONTSTRUCT
				mov		cf.rgbColors,0
				mov		cf.lCustData,0
				mov		cf.lpfnHook,0
				mov		cf.lpTemplateName,0
				mov		cf.hInstance,0
				mov		cf.lpszStyle,0
				mov		cf.nFontType,0
				mov		cf.Alignment,0
				mov		cf.nSizeMin,0
				mov		cf.nSizeMax,0
				invoke ChooseFont,addr cf
				push	eax
				invoke ReleaseDC,hWin,cf.hDC
				pop		eax
				.if eax
					invoke DeleteObject,hfnt
					invoke CreateFontIndirect,addr cflf
					mov		hfnt,eax
					invoke SendDlgItemMessage,hWin,IDC_STCFONT,WM_SETFONT,hfnt,TRUE
				.endif
			.endif
		.endif
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

GetColor:
	mov		cc.lStructSize,sizeof CHOOSECOLOR
	mov		cc.rgbResult,eax
	mov		eax,hWin
	mov		cc.hwndOwner,eax
	mov		eax,hInstance
	mov		cc.hInstance,eax
	mov		cc.lpCustColors,offset CustColors
	mov		cc.Flags,CC_FULLOPEN or CC_RGBINIT
	mov		cc.lCustData,0
	mov		cc.lpfnHook,0
	mov		cc.lpTemplateName,0
	invoke ChooseColor,addr cc
	retn

TabOpt3Proc endp

TabOpt4Proc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
		invoke SetDlgItemInt,hWin,IDC_EDTDLGSTART,initid.dlg.startid,FALSE
		invoke SetDlgItemInt,hWin,IDC_EDTDLGINC,initid.dlg.incid,FALSE
		invoke SetDlgItemInt,hWin,IDC_EDTMNUSTART,initid.mnu.startid,FALSE
		invoke SetDlgItemInt,hWin,IDC_EDTMNUINC,initid.mnu.incid,FALSE
		invoke SetDlgItemInt,hWin,IDC_EDTRCDSTART,initid.rcd.startid,FALSE
		invoke SetDlgItemInt,hWin,IDC_EDTRCDINC,initid.rcd.incid,FALSE
		invoke SetDlgItemInt,hWin,IDC_EDTRESSTART,initid.res.startid,FALSE
		invoke SetDlgItemInt,hWin,IDC_EDTRESINC,initid.res.incid,FALSE
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabOpt4Proc endp

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
				invoke DeleteObject,hfnt
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
							invoke IsDlgButtonChecked,hTabDlg,IDC_RBNEXPOPT4
							.if eax
								mov		nmeexp.nType,3
							.else
								mov		nmeexp.nType,4
							.endif
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
				mov		eax,gridcolor
				mov		grdsize.color,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKSIZETOFONT
				mov		grdsize.sizetofont,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKNODEFINE
				mov		grdsize.nodefines,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKSIMPLE
				mov		grdsize.simple,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKIDC_STATIC
				mov		grdsize.defstatic,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKSTANDARD
				mov		grdsize.standardmnu,eax
				invoke IsDlgButtonChecked,hTabDlg[8],IDC_CHKBORLANDCOMP
				mov		grdsize.borlandcomp,eax
				invoke RegSetValueEx,hReg,addr szGrid,0,REG_BINARY,addr grdsize,sizeof grdsize
				mov		eax,grdsize.y
				shl		eax,16
				add		eax,grdsize.x
				mov		edx,grdsize.line
				shl		edx,24
				add		edx,grdsize.color
				invoke SendMessage,hResEd,DEM_SETGRIDSIZE,eax,edx
				mov		eax,backcolor
				mov		col.back,eax
				mov		eax,textcolor
				mov		col.text,eax
				invoke RegSetValueEx,hReg,addr szColor,0,REG_BINARY,addr col,sizeof col
				invoke SendMessage,hResEd,DEM_SETCOLOR,0,addr col
				invoke GetDlgItemInt,hTabDlg[12],IDC_EDTDLGSTART,NULL,FALSE
				mov		initid.dlg.startid,eax
				invoke GetDlgItemInt,hTabDlg[12],IDC_EDTDLGINC,NULL,FALSE
				mov		initid.dlg.incid,eax
				invoke GetDlgItemInt,hTabDlg[12],IDC_EDTMNUSTART,NULL,FALSE
				mov		initid.mnu.startid,eax
				invoke GetDlgItemInt,hTabDlg[12],IDC_EDTMNUINC,NULL,FALSE
				mov		initid.mnu.incid,eax
				invoke GetDlgItemInt,hTabDlg[12],IDC_EDTRCDSTART,NULL,FALSE
				mov		initid.rcd.startid,eax
				invoke GetDlgItemInt,hTabDlg[12],IDC_EDTRCDINC,NULL,FALSE
				mov		initid.rcd.incid,eax
				invoke GetDlgItemInt,hTabDlg[12],IDC_EDTRESSTART,NULL,FALSE
				mov		initid.res.startid,eax
				invoke GetDlgItemInt,hTabDlg[12],IDC_EDTRESINC,NULL,FALSE
				mov		initid.res.incid,eax
				invoke RegSetValueEx,hReg,addr szInitID,0,REG_BINARY,addr initid,sizeof initid
				invoke SendMessage,hResEd,PRO_SETINITID,0,addr initid
				invoke lstrcpy,addr textfont.lfFaceName,addr cflf.lfFaceName
				mov		eax,cflf.lfHeight
				mov		textfont.lfHeight,eax
				mov		eax,cflf.lfWeight
				mov		textfont.lfWeight,eax
				movzx	eax,cflf.lfItalic
				mov		textfont.lfItalic,eax
				movzx	eax,cflf.lfCharSet
				mov		textfont.lfCharSet,eax
				invoke RegSetValueEx,hReg,addr szTextFont,0,REG_BINARY,addr textfont,sizeof textfont
				invoke SendMessage,hResEd,PRO_SETTEXTFONT,hfnt,0
				invoke GetWindowLong,hResEd,GWL_STYLE
				and		eax,-1 xor (DES_GRID or DES_SNAPTOGRID or DES_TOOLTIP or DES_STYLEHEX or DES_SIZETOFONT or DES_NODEFINES or DES_SIMPLEPROPERTY or DES_DEFIDC_STATIC or DES_BORLAND)
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
				.if grdsize.sizetofont
					or		eax,DES_SIZETOFONT
				.endif
				.if grdsize.nodefines
					or		eax,DES_NODEFINES
				.endif
				.if grdsize.simple
					or		eax,DES_SIMPLEPROPERTY
				.endif
				.if grdsize.defstatic
					or		eax,DES_DEFIDC_STATIC
				.endif
				.if grdsize.borlandcomp
					or		eax,DES_BORLAND
				.endif
				invoke SetWindowLong,hResEd,GWL_STYLE,eax
				.if grdsize.standardmnu
					; Standard menu
					.if hMnuFont
						invoke DeleteObject,hMenuBrushA
						invoke DeleteObject,hMenuBrushB
						invoke DeleteObject,hMnuFont
						xor		eax,eax
						mov		hMenuBrushA,eax
						mov		hMenuBrushB,eax
						mov		hMnuFont,eax
						invoke LoadMenu,hInstance,IDR_MENU
						push	eax
						invoke SetMenu,hWnd,eax
						invoke DestroyMenu,hMnu
						pop		eax
						mov		hMnu,eax
						invoke DestroyMenu,hContextMenu
						invoke LoadMenu,hInstance,IDR_CONTEXT
						mov		hContextMenu,eax
					.endif
				.else
					; Cool menu
					.if !hMnuFont
						invoke CoolMenu
					.endif
				.endif
				invoke SendMessage,hWin,WM_CLOSE,0,0
			.endif
		.endif
	.elseif eax==WM_NOTIFY
		mov		eax,lParam
		mov		eax,[eax].NMHDR.code
		.if eax==TCN_SELCHANGE
			;Tab selection
			invoke SendMessage,hTab,TCM_GETCURSEL,0,0
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
		mov		gridcolor,eax
		invoke CreateSolidBrush,eax
		mov		hBrGrid,eax
		mov		eax,col.back
		mov		backcolor,eax
		invoke CreateSolidBrush,eax
		mov		hBrBack,eax
		mov		eax,col.text
		mov		textcolor,eax
		invoke CreateSolidBrush,eax
		mov		hBrText,eax
		invoke SendMessage,hResEd,PRO_GETTEXTFONT,0,0
		invoke GetObject,eax,sizeof cflf,addr cflf
		invoke CreateFontIndirect,addr cflf
		mov		hfnt,eax
		;Create the tabs
		invoke GetDlgItem,hWin,IDC_TABOPT
		mov		hTab,eax
		mov		ts.imask,TCIF_TEXT
;		mov		ts.lpReserved1,0
;		mov		ts.lpReserved2,0
		mov		ts.iImage,-1
		mov		ts.lParam,0
		mov		ts.pszText,offset TabTitle1
		mov		ts.cchTextMax,sizeof TabTitle1
		invoke SendMessage,hTab,TCM_INSERTITEM,0,addr ts
		mov		ts.pszText,offset TabTitle2
		mov		ts.cchTextMax,sizeof TabTitle2
		invoke SendMessage,hTab,TCM_INSERTITEM,1,addr ts
		mov		ts.pszText,offset TabTitle3
		mov		ts.cchTextMax,sizeof TabTitle3
		invoke SendMessage,hTab,TCM_INSERTITEM,2,addr ts
		mov		ts.pszText,offset TabTitle4
		mov		ts.cchTextMax,sizeof TabTitle4
		invoke SendMessage,hTab,TCM_INSERTITEM,3,addr ts
		;Create the tab dialogs
		invoke CreateDialogParam,hInstance,IDD_TABOPT1,hTab,addr TabOpt1Proc,0
		mov		hTabDlg,eax
		invoke CreateDialogParam,hInstance,IDD_TABOPT2,hTab,addr TabOpt2Proc,0
		mov		hTabDlg[4],eax
		invoke CreateDialogParam,hInstance,IDD_TABOPT3,hTab,addr TabOpt3Proc,0
		mov		hTabDlg[8],eax
		invoke CreateDialogParam,hInstance,IDD_TABOPT4,hTab,addr TabOpt4Proc,0
		mov		hTabDlg[12],eax
		mov		SelTab,0
	.elseif eax==WM_CLOSE
		invoke DeleteObject,hBrGrid
		invoke DeleteObject,hBrBack
		invoke DeleteObject,hBrText
		invoke DestroyWindow,hTabDlg
		invoke DestroyWindow,hTabDlg[4]
		invoke DestroyWindow,hTabDlg[8]
		invoke DestroyWindow,hTabDlg[12]
		invoke EndDialog,hWin,NULL
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

TabOptionsProc endp
