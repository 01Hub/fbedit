
'TabOptions.dlg
#Define IDD_TABOPTIONS						2000
#Define IDC_TABOPT							2001

'TabOpt1.dlg
#Define IDD_TABOPT1							2100
#Define IDC_RBNEXPOPT1						2101
#Define IDC_RBNEXPOPT2						2102
#Define IDC_EDTEXPOPT						2113
#Define IDC_RBNEXPOPT3						2103
#Define IDC_RBNEXPORTOUT					2112
#Define IDC_RBNEXPORTCLIP					2111
#Define IDC_RBNEXPORTFILE					2110
#Define IDC_CHKAUTOEXPORT					2114
#Define IDC_RBNEXPOPT4						2104

'TabOpt2.dlg
#Define IDD_TABOPT2							2200
#Define IDC_BTNCUST							2207
#Define IDC_EDTCUST							2206
#Define IDC_BTNCUSTDEL						2205
#Define IDC_BTNCUSTADD						2204
#Define IDC_BTNCUSTDN						2203
#Define IDC_BTNCUSTUP						2202
#Define IDC_LSTCUST							2201

'TabOpt3.dlg
#Define IDD_TABOPT3							2300
#Define IDC_EDTY								4005
#Define IDC_EDTX								4008
#Define IDC_CHKSNAPGRID						4002
#Define IDC_CHKSHOWGRID						4003
#Define IDC_UDNY								4004
#Define IDC_UDNX								4007
#Define IDC_CHKSHOWTIP						4001
#Define IDC_STCGRIDCOLOR					4006
#Define IDC_CHKGRIDLINE						4009
#Define IDC_CHKSTYLEHEX						4010
#Define IDC_CHKSIZETOFONT					4011

Dim Shared hTabOpt As HWND
Dim Shared hTabDlg(3) As HWND
Dim Shared SelTab As Integer
Dim Shared grdcol As Integer
Dim Shared hGrdBr As HBRUSH

Function TabOpt1Proc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer

	Select Case uMsg
		Case WM_INITDIALOG
			CheckRadioButton(hWin,IDC_RBNEXPOPT1,IDC_RBNEXPOPT4,IDC_RBNEXPOPT1+nmeexp.nType)
			CheckRadioButton(hWin,IDC_RBNEXPORTFILE,IDC_RBNEXPORTOUT,IDC_RBNEXPORTFILE+nmeexp.nOutput)
			SendDlgItemMessage(hWin,IDC_EDTEXPOPT,EM_LIMITTEXT,MAX_PATH,0)
			SetDlgItemText(hWin,IDC_EDTEXPOPT,nmeexp.szFileName)
			CheckDlgButton(hWin,IDC_CHKAUTOEXPORT,nmeexp.fAuto)
			'
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function

Function TabOpt2Proc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim As Long id,Event
	Dim nInx As Integer
	Dim ofn As OPENFILENAME

	Select Case uMsg
		Case WM_INITDIALOG
			SendDlgItemMessage(hWin,IDC_BTNCUSTUP,BM_SETIMAGE,IMAGE_ICON,Cast(Integer,ImageList_GetIcon(ah.hmnuiml,2,ILD_NORMAL)))
			SendDlgItemMessage(hWin,IDC_BTNCUSTDN,BM_SETIMAGE,IMAGE_ICON,Cast(Integer,ImageList_GetIcon(ah.hmnuiml,3,ILD_NORMAL)))
			SendDlgItemMessage(hWin,IDC_EDTCUST,EM_LIMITTEXT,MAX_PATH-1,0)
			nInx=1
			While nInx<=32
				GetPrivateProfileString(StrPtr("CustCtrl"),Str(nInx),@szNULL,@buff,260,@ad.IniFile)
				If Len(buff) Then
					SendDlgItemMessage(hWin,IDC_LSTCUST,LB_ADDSTRING,0,Cast(Integer,@buff))
				EndIf
				nInx=nInx+1
			Wend
			SendDlgItemMessage(hWin,IDC_LSTCUST,LB_SETCURSEL,0,0)
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Event=HiWord(wParam)
			Select Case Event
				Case BN_CLICKED
					Select Case id
						Case IDC_BTNCUSTADD
							GetDlgItemText(hWin,IDC_EDTCUST,@buff,260)
							nInx=SendDlgItemMessage(hWin,IDC_LSTCUST,LB_ADDSTRING,0,Cast(Integer,@buff))
							SendDlgItemMessage(hWin,IDC_LSTCUST,LB_SETCURSEL,nInx,0)
							SetDlgItemText(hWin,IDC_EDTCUST,StrPtr(""))
							'
						Case IDC_BTNCUSTDEL
							nInx=SendDlgItemMessage(hWin,IDC_LSTCUST,LB_GETCURSEL,0,0)
							If nInx<>LB_ERR Then
								SendDlgItemMessage(hWin,IDC_LSTCUST,LB_DELETESTRING,nInx,0)
								If SendDlgItemMessage(hWin,IDC_LSTCUST,LB_SETCURSEL,nInx,0)=LB_ERR Then
									SendDlgItemMessage(hWin,IDC_LSTCUST,LB_SETCURSEL,nInx-1,0)
								EndIf
							EndIf
							'
						Case IDC_BTNCUSTUP
							nInx=SendDlgItemMessage(hWin,IDC_LSTCUST,LB_GETCURSEL,0,0)
							If nInx Then
								SendDlgItemMessage(hWin,IDC_LSTCUST,LB_GETTEXT,nInx,Cast(Integer,@buff))
								SendDlgItemMessage(hWin,IDC_LSTCUST,LB_DELETESTRING,nInx,0)
								nInx=nInx-1
								SendDlgItemMessage(hWin,IDC_LSTCUST,LB_INSERTSTRING,nInx,Cast(Integer,@buff))
								SendDlgItemMessage(hWin,IDC_LSTCUST,LB_SETCURSEL,nInx,0)
							EndIf
							'
						Case IDC_BTNCUSTDN
							nInx=SendDlgItemMessage(hWin,IDC_LSTCUST,LB_GETCURSEL,0,0)
							id=SendDlgItemMessage(hWin,IDC_LSTCUST,LB_GETCOUNT,0,0)
							If id-1<>nInx Then
								SendDlgItemMessage(hWin,IDC_LSTCUST,LB_GETTEXT,nInx,Cast(Integer,@buff))
								SendDlgItemMessage(hWin,IDC_LSTCUST,LB_DELETESTRING,nInx,0)
								nInx=nInx+1
								SendDlgItemMessage(hWin,IDC_LSTCUST,LB_INSERTSTRING,nInx,Cast(Integer,@buff))
								SendDlgItemMessage(hWin,IDC_LSTCUST,LB_SETCURSEL,nInx,0)
							EndIf
							'
						Case IDC_BTNCUST
							ofn.lStructSize=SizeOf(ofn)
							ofn.hwndOwner=hWin
							ofn.hInstance=hInstance
							ofn.lpstrInitialDir=NULL
							ofn.lpstrFilter=@DLLFilterString
							ofn.lpstrDefExt=0
							ofn.lpstrTitle=0
							ofn.lpstrFile=@buff
							GetDlgItemText(hWin,IDC_EDTCUST,@buff,260)
							ofn.nMaxFile=260
							ofn.Flags=OFN_FILEMUSTEXIST Or OFN_HIDEREADONLY Or OFN_PATHMUSTEXIST
							If GetOpenFileName(@ofn) Then
								SetDlgItemText(hWin,IDC_EDTCUST,@buff)
							EndIf
							'
					End Select
					'
				Case EN_CHANGE
					If id=IDC_EDTCUST Then
						EnableWindow(GetDlgItem(hWin,IDC_BTNCUSTADD),SendDlgItemMessage(hWin,IDC_EDTCUST,WM_GETTEXTLENGTH,0,0))
					EndIf
					'
			End Select
			'
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function

Function TabOpt3Proc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim lpDRAWITEMSTRUCT As DRAWITEMSTRUCT ptr
	Dim cc As CHOOSECOLOR

	Select Case uMsg
		Case WM_INITDIALOG
			SendDlgItemMessage(hWin,IDC_UDNX,UDM_SETRANGE,0,&H00020014)	' Set range
			SendDlgItemMessage(hWin,IDC_UDNX,UDM_SETPOS,0,grdsize.x)		' Set default value
			SendDlgItemMessage(hWin,IDC_UDNY,UDM_SETRANGE,0,&H00020014)	' Set range
			SendDlgItemMessage(hWin,IDC_UDNY,UDM_SETPOS,0,grdsize.y)		' Set default value
			CheckDlgButton(hWin,IDC_CHKSHOWGRID,grdsize.show)
			CheckDlgButton(hWin,IDC_CHKSNAPGRID,grdsize.snap)
			CheckDlgButton(hWin,IDC_CHKSHOWTIP,grdsize.tips)
			CheckDlgButton(hWin,IDC_CHKGRIDLINE,grdsize.line)
			CheckDlgButton(hWin,IDC_CHKSTYLEHEX,grdsize.stylehex)
			CheckDlgButton(hWin,IDC_CHKSIZETOFONT,grdsize.sizetofont)
			'
		Case WM_DRAWITEM
			lpDRAWITEMSTRUCT=Cast(DRAWITEMSTRUCT ptr,lParam)
			FillRect(lpDRAWITEMSTRUCT->hDC,@lpDRAWITEMSTRUCT->rcItem,hGrdBr)
		Case WM_COMMAND
			If wParam=IDC_STCGRIDCOLOR Then
				cc.lStructSize=SizeOf(CHOOSECOLOR)
				cc.hwndOwner=hWin
				cc.hInstance=Cast(Any ptr,hInstance)
				cc.lpCustColors=Cast(Any ptr,@custcol)
				cc.Flags=CC_FULLOPEN Or CC_RGBINIT
				cc.lCustData=0
				cc.lpfnHook=0
				cc.lpTemplateName=0
				cc.rgbResult=grdcol
				If ChooseColor(@cc) Then
					DeleteObject(hGrdBr)
					grdcol=cc.rgbResult
					hGrdBr=CreateSolidBrush(grdcol)
					InvalidateRect(GetDlgItem(hWin,IDC_STCGRIDCOLOR),NULL,TRUE)
				EndIf
			EndIf
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function

Sub SetDialogOptions(ByVal hWin As HWND)
	Dim st As Integer
	Dim lpRESMEM As RESMEM ptr

	lpRESMEM=Cast(RESMEM ptr,GetWindowLong(hWin,0))
	lstrcpy(@buff,nmeexp.szFileName)
	SendMessage(lpRESMEM->hProject,PRO_SETEXPORT,(nmeexp.nOutput Shl 16)+nmeexp.nType,Cast(Integer,@buff))
	SendMessage(lpRESMEM->hProject,PRO_SETSTYLEPOS,0,Cast(Integer,@wpos.ptstyle))
	SendMessage(lpRESMEM->hResEd,DEM_SETGRIDSIZE,(grdsize.y Shl 16) +grdsize.x,(grdsize.line Shl 24)+grdsize.color)
	st=GetWindowLong(lpRESMEM->hResEd,GWL_STYLE)
	st=st And (-1 Xor (DES_GRID Or DES_SNAPTOGRID Or DES_TOOLTIP Or DES_STYLEHEX Or DES_SIZETOFONT))
	If grdsize.show Then
		st=st Or DES_GRID
	EndIf
	If grdsize.snap Then
		st=st Or DES_SNAPTOGRID
	EndIf
	If grdsize.tips Then
		st=st Or DES_TOOLTIP
	EndIf
	If grdsize.stylehex Then
		st=st Or DES_STYLEHEX
	EndIf
	If grdsize.sizetofont Then
		st=st Or DES_SIZETOFONT
	EndIf
	SetWindowLong(lpRESMEM->hResEd,GWL_STYLE,st)

End Sub

Function TabOptionsProc(ByVal hWin As HWND,ByVal uMsg As UINT,ByVal wParam As WPARAM,ByVal lParam As LPARAM) As Integer
	Dim As Long id, Event
	Dim ts As TCITEM
	Dim nInx As Integer
	Dim lpNMHDR As NMHDR ptr

	Select Case uMsg
		Case WM_INITDIALOG
			grdcol=grdsize.color
			hGrdBr=CreateSolidBrush(grdcol)
			' Create the tabs
			hTabOpt=GetDlgItem(hWin,IDC_TABOPT)
			ts.mask=TCIF_TEXT
			ts.iImage=-1
			ts.lParam=0
			ts.pszText=StrPtr("Exports")
			SendMessage(hTabOpt,TCM_INSERTITEM,0,Cast(Integer,@ts))
			ts.pszText=StrPtr("Custom controls")
			SendMessage(hTabOpt,TCM_INSERTITEM,1,Cast(Integer,@ts))
			ts.pszText=StrPtr("Behaviour")
			SendMessage(hTabOpt,TCM_INSERTITEM,2,Cast(Integer,@ts))
			' Create the tab dialogs
			hTabDlg(0)=CreateDialogParam(hInstance,Cast(ZString ptr,IDD_TABOPT1),hTabOpt,@TabOpt1Proc,0)
			hTabDlg(1)=CreateDialogParam(hInstance,Cast(ZString ptr,IDD_TABOPT2),hTabOpt,@TabOpt2Proc,0)
			hTabDlg(2)=CreateDialogParam(hInstance,Cast(ZString ptr,IDD_TABOPT3),hTabOpt,@TabOpt3Proc,0)
			SelTab=0
			'
		Case WM_NOTIFY
			lpNMHDR=Cast(NMHDR ptr,lParam)
			If lpNMHDR->code=TCN_SELCHANGE Then
				' Tab selection
				id=SendMessage(hTabOpt,TCM_GETCURSEL,0,0)
				If id<>SelTab Then
					ShowWindow(hTabDlg(SelTab),SW_HIDE)
					ShowWindow(hTabDlg(id),SW_SHOWDEFAULT)
					SelTab=id
				EndIf
			EndIf
		Case WM_CLOSE
			DeleteObject(hGrdBr)
			EndDialog(hWin,0)
			'
		Case WM_COMMAND
			id=LoWord(wParam)
			Event=HiWord(wParam)
			Select Case id
				Case IDOK
					Select Case TRUE
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPOPT1)
							nmeexp.nType=0
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPOPT2)
							nmeexp.nType=1
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPOPT3)
							nmeexp.nType=2
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPOPT4)
							nmeexp.nType=3
					End Select
					Select Case TRUE
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPORTFILE)
							nmeexp.nOutput=0
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPORTCLIP)
							nmeexp.nOutput=1
						Case IsDlgButtonChecked(hTabDlg(0),IDC_RBNEXPORTOUT)
							nmeexp.nOutput=2
					End Select
					GetDlgItemText(hTabDlg(0),IDC_EDTEXPOPT,@buff,260)
					lstrcpyn(nmeexp.szFileName,buff,32)
					nmeexp.fAuto=IsDlgButtonChecked(hTabDlg(0),IDC_CHKAUTOEXPORT)
					SaveToIni(StrPtr("Resource"),StrPtr("Export"),"4440",@nmeexp,FALSE)
					grdsize.x=GetDlgItemInt(hTabDlg(2),IDC_EDTX,NULL,FALSE)
					grdsize.y=GetDlgItemInt(hTabDlg(2),IDC_EDTY,NULL,FALSE)
					grdsize.show=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSHOWGRID)
					grdsize.snap=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSNAPGRID)
					grdsize.tips=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSHOWTIP)
					grdsize.line=IsDlgButtonChecked(hTabDlg(2),IDC_CHKGRIDLINE)
					grdsize.stylehex=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSTYLEHEX)
					grdsize.sizetofont=IsDlgButtonChecked(hTabDlg(2),IDC_CHKSIZETOFONT)
					grdsize.color=grdcol
					SaveToIni(StrPtr("Resource"),StrPtr("Grid"),"444444444",@grdsize,FALSE)
					SetDialogOptions(ah.hres)
					buff=String(32,0)
					WritePrivateProfileSection(StrPtr("CustCtrl"),@buff,@ad.IniFile)
					nInx=0
					While SendDlgItemMessage(hTabDlg(1),IDC_LSTCUST,LB_GETTEXT,nInx,Cast(Integer,@buff))<>LB_ERR
						nInx=nInx+1
						WritePrivateProfileString(StrPtr("CustCtrl"),Str(nInx),@buff,@ad.IniFile)
					Wend
					SendMessage(hWin,WM_CLOSE,0,0)
					'
				Case IDCANCEL
					SendMessage(hWin,WM_CLOSE,0,0)
					'
			End Select
		Case Else
			Return FALSE
			'
	End Select
	Return TRUE

End Function
